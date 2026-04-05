// internal/network/room.go
package network

import (
	"log"
	"sync"
	"time"

	"grits-backend/internal/game"
)

type GameRoom struct {
	ID       string
	clients  map[*Client]bool
	clientsMu sync.RWMutex
	engine   *game.GameEngine
	broadcast chan Message
	quit     chan struct{}
	stats    *game.GameStats
}

type Message struct {
	Data  string
	Flags int
	Exclude *Client
}

func NewGameRoom(id string, matchmaker *matchmaker.Client) *GameRoom {
	room := &GameRoom{
		ID:        id,
		clients:   make(map[*Client]bool),
		broadcast: make(chan Message, 256),
		quit:      make(chan struct{}),
		stats:     game.NewGameStats(),
	}

	room.engine = game.NewGameEngine(room, room.stats)
	room.engine.Setup()

	return room
}

func (r *GameRoom) Run() {
	log.Printf("Game room %s started", r.ID)

	ticker := time.NewTicker(time.Duration(1000/game.GameUpdatesPerSec) * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			r.engine.Run(1.0 / float64(game.GameUpdatesPerSec))
			r.broadcastUpdates()

		case msg := <-r.broadcast:
			r.clientsMu.RLock()
			for client := range r.clients {
				if msg.Exclude == client {
					continue
				}
				client.Send(msg.Data)
			}
			r.clientsMu.RUnlock()

		case <-r.quit:
			r.cleanup()
			return
		}
	}
}

func (r *GameRoom) AddClient(client *Client) {
	r.clientsMu.Lock()
	r.clients[client] = true
	r.clientsMu.Unlock()

	// Send initial game state
	client.Send(r.getInitialState())
}

func (r *GameRoom) RemoveClient(client *Client) {
	r.clientsMu.Lock()
	delete(r.clients, client)
	r.clientsMu.Unlock()

	if len(r.clients) == 0 {
		// Schedule room for deletion
		go r.scheduleDeletion()
	}
}

func (r *GameRoom) Broadcast(msg string, flags int, exclude string) {
	r.broadcast <- Message{
		Data:  msg,
		Flags: flags,
		Exclude: r.findClient(exclude),
	}
}

func (r *GameRoom) broadcastUpdates() {
	// Send physics updates, player stats, etc.
}

func (r *GameRoom) getInitialState() string {
	// Encode initial game state
	return ""
}

func (r *GameRoom) scheduleDeletion() {
	time.Sleep(10 * time.Minute)
	if len(r.clients) == 0 {
		close(r.quit)
	}
}

func (r *GameRoom) cleanup() {
	log.Printf("Game room %s stopped", r.ID)
	// Report game over to matchmaker
	if r.stats != nil {
		// r.matchmaker.ReportGameOver(r.ID, r.stats)
	}
}

func (r *GameRoom) findClient(name string) *Client {
	r.clientsMu.RLock()
	defer r.clientsMu.RUnlock()

	for client := range r.clients {
		if client.GetName() == name {
			return client
		}
	}
	return nil
}