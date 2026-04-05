// internal/network/server.go
package network

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

type Server struct {
	port          int
	gamePort      int
	roomManager   *RoomManager
	matchmaker    *matchmaker.Client
	rooms         map[string]*GameRoom
	roomsMu       sync.RWMutex
	httpServer    *http.Server
	wsServer      *http.Server
}

func NewServer(port, gamePort int, roomManager *RoomManager, matchmaker *matchmaker.Client) *Server {
	return &Server{
		port:        port,
		gamePort:    gamePort,
		roomManager: roomManager,
		matchmaker:  matchmaker,
		rooms:       make(map[string]*GameRoom),
	}
}

func (s *Server) Start() error {
	// HTTP controller server
	mux := http.NewServeMux()
	mux.HandleFunc("/start-game", s.handleStartGame)
	mux.HandleFunc("/add-players", s.handleAddPlayers)
	mux.HandleFunc("/ping", s.handlePing)
	mux.HandleFunc("/log", s.handleLog)

	s.httpServer = &http.Server{
		Addr:    fmt.Sprintf(":%d", s.port),
		Handler: mux,
	}

	// WebSocket game server
	wsMux := http.NewServeMux()
	wsMux.HandleFunc("/socket.io/", s.handleWebSocket)

	s.wsServer = &http.Server{
		Addr:    fmt.Sprintf(":%d", s.gamePort),
		Handler: wsMux,
	}

	// Start servers
	go func() {
		log.Printf("HTTP controller listening on port %d", s.port)
		if err := s.httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Printf("HTTP server error: %v", err)
		}
	}()

	go func() {
		log.Printf("WebSocket server listening on port %d", s.gamePort)
		if err := s.wsServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Printf("WebSocket server error: %v", err)
		}
	}()

	return nil
}

func (s *Server) Shutdown(ctx context.Context) {
	s.httpServer.Shutdown(ctx)
	s.wsServer.Shutdown(ctx)
}

func (s *Server) handleStartGame(w http.ResponseWriter, r *http.Request) {
	// Create new game room
	roomID := generateRoomID()
	room := NewGameRoom(roomID, s.matchmaker)
	s.roomsMu.Lock()
	s.rooms[roomID] = room
	s.roomsMu.Unlock()

	go room.Run()

	response := map[string]interface{}{
		"success": true,
		"port":    s.gamePort,
		"name":    roomID,
		"game_state": map[string]interface{}{
			"name":        roomID,
			"min_players": 1,
			"max_players": 8,
			"players":     map[string]string{},
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (s *Server) handleAddPlayers(w http.ResponseWriter, r *http.Request) {
	var req struct {
		PlayerGameKey string `json:"player_game_key"`
		UserID        string `json:"userID"`
		DisplayName   string `json:"displayName"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Store player for later assignment
	s.roomManager.AddPlayer(req.PlayerGameKey, req.UserID, req.DisplayName)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]bool{"success": true})
}

func (s *Server) handlePing(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"games":   len(s.rooms),
		"uptime":  time.Since(startTime).Seconds(),
		"serverid": serverID,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (s *Server) handleLog(w http.ResponseWriter, r *http.Request) {
	// Return recent logs
	w.Header().Set("Content-Type", "text/plain")
	w.Write([]byte("Logs would go here"))
}

func (s *Server) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}

	// Extract room ID from path
	path := r.URL.Path
	roomID := extractRoomID(path)

	s.roomsMu.RLock()
	room, exists := s.rooms[roomID]
	s.roomsMu.RUnlock()

	if !exists {
		conn.Close()
		return
	}

	client := NewClient(conn, room)
	room.AddClient(client)
	client.Run()
}

func generateRoomID() string {
	b := make([]byte, 3)
	rand.Read(b)
	return base64.URLEncoding.EncodeToString(b)
}

func extractRoomID(path string) string {
	// Extract from /game/ROOM_ID pattern
	parts := strings.Split(path, "/")
	if len(parts) > 2 {
		return parts[2]
	}
	return ""
}

var (
	serverID  = generateServerID()
	startTime = time.Now()
)