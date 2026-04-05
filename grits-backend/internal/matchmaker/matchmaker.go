// internal/matchmaker/matchmaker.go
package matchmaker

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
)

type Client struct {
	serverID   string
	host       string
	port       int
	httpClient *http.Client
}

type GameState struct {
	Name        string            `json:"name"`
	MinPlayers  int               `json:"min_players"`
	MaxPlayers  int               `json:"max_players"`
	Players     map[string]string `json:"players"`
}

func NewClient(serverID string) *Client {
	return &Client{
		serverID:   serverID,
		httpClient: &http.Client{Timeout: 10 * time.Second},
	}
}

func (c *Client) Connect(host string, port int) {
	c.host = host
	c.port = port

	// Start periodic registration
	ticker := time.NewTicker(30 * time.Second)
	go func() {
		for range ticker.C {
			c.register()
		}
	}()

	// Initial registration
	c.register()
}

func (c *Client) register() {
	url := fmt.Sprintf("http://%s:%d/register-controller", c.host, c.port)
	
	data := map[string]interface{}{
		"controller_port": 12345, // Your controller port
		"serverid":        c.serverID,
		"pairing_key":     "your-pairing-key",
	}

	jsonData, _ := json.Marshal(data)
	
	resp, err := c.httpClient.Post(url, "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		log.Printf("Failed to register with matchmaker: %v", err)
		return
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		log.Printf("Failed to decode matchmaker response: %v", err)
		return
	}

	if success, ok := result["success"].(bool); ok && success {
		log.Printf("Successfully registered with matchmaker")
	}
}

func (c *Client) UpdateGameState(gameState *GameState) {
	url := fmt.Sprintf("http://%s:%d/update-game-state", c.host, c.port)
	
	data := map[string]interface{}{
		"controller_port": 12345,
		"serverid":        c.serverID,
		"game_state":      gameState,
	}

	jsonData, _ := json.Marshal(data)
	c.httpClient.Post(url, "application/json", bytes.NewBuffer(jsonData))
}

func (c *Client) ReportGameOver(instanceID string, stats interface{}) {
	url := fmt.Sprintf("http://%s:%d/game-over", c.host, c.port)
	
	data := map[string]interface{}{
		"name":     instanceID,
		"serverid": c.serverID,
		"counts":   stats,
	}

	jsonData, _ := json.Marshal(data)
	c.httpClient.Post(url, "application/json", bytes.NewBuffer(jsonData))
}

func (c *Client) Close() {
	// Cleanup
}