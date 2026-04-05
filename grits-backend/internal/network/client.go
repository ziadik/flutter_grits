// internal/network/client.go
package network

import (
	"log"
	"strings"
	"sync"

	"github.com/gorilla/websocket"
)

type Client struct {
	conn     *websocket.Conn
	room     *GameRoom
	name     string
	send     chan []byte
	quit     chan struct{}
	mu       sync.Mutex
	buffer   strings.Builder
}

func NewClient(conn *websocket.Conn, room *GameRoom) *Client {
	return &Client{
		conn: conn,
		room: room,
		send: make(chan []byte, 256),
		quit: make(chan struct{}),
	}
}

func (c *Client) Run() {
	go c.writePump()
	c.readPump()
}

func (c *Client) readPump() {
	defer func() {
		c.conn.Close()
		close(c.quit)
		c.room.RemoveClient(c)
	}()

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			break
		}

		c.handleMessage(string(message))
	}
}

func (c *Client) writePump() {
	for {
		select {
		case message := <-c.send:
			if err := c.conn.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}
		case <-c.quit:
			return
		}
	}
}

func (c *Client) Send(data string) {
	select {
	case c.send <- []byte(data):
	default:
	}
}

func (c *Client) handleMessage(msg string) {
	// Parse protocol message
	parts := strings.Split(msg, "/")
	for _, part := range parts {
		fields := strings.SplitN(part, ":", 2)
		if len(fields) < 2 {
			continue
		}

		msgID := fields[0]
		data := fields[1]

		switch msgID {
		case "0": // hello
			c.handleHello(data)
		case "1": // ping
			c.handlePing(data)
		case "2": // respawn
			c.handleRespawn(data)
		default:
			// Handle game messages
			c.handleGameMessage(msgID, data)
		}
	}
}

func (c *Client) handleHello(data string) {
	// Parse hello message and register player
	// Format: player_game_key
	c.name = "!" + data // Simplified

	// Spawn player in game
	player := c.room.engine.SpawnPlayer(c.name, 0, "Team0Spawn0", "Player", c.name, "Player")
	if player != nil {
		c.Send("0:" + c.name + ":" + string(rune(player.Team)))
	}
}

func (c *Client) handlePing(data string) {
	// Respond with pong
	c.Send("1:" + data)
}

func (c *Client) handleRespawn(data string) {
	// Process respawn request
	c.room.engine.HandleRespawn(data)
}

func (c *Client) handleGameMessage(msgID, data string) {
	// Route to appropriate entity handler
	// Format: from:data
	parts := strings.SplitN(data, ":", 2)
	if len(parts) < 2 {
		return
	}

	from := parts[0]
	msgData := parts[1]

	entity := c.room.engine.GetEntityByName(from)
	if entity == nil {
		return
	}

	// Call appropriate handler
	// entity.OnMessage(msgID, msgData)
}

func (c *Client) GetName() string {
	return c.name
}

func (c *Client) AddToBuffer(data string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.buffer.WriteString(data)
}

func (c *Client) FlushBuffer() {
	c.mu.Lock()
	data := c.buffer.String()
	c.buffer.Reset()
	c.mu.Unlock()

	if data != "" {
		c.Send(data)
	}
}