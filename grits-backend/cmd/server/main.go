// cmd/server/main.go
package main

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"flag"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"grits-backend/internal/game"
	"grits-backend/internal/network"
	"grits-backend/internal/matchmaker"
)

var (
	port     = flag.Int("port", 8080, "WebSocket port")
	gamePort = flag.Int("game-port", 8081, "Game server port")
	devMode  = flag.Bool("dev", false, "Development mode")
)

func main() {
	flag.Parse()

	log.Printf("Starting GRITS Game Server (dev=%v)", *devMode)

	// Generate server ID
	serverID := generateServerID()
	log.Printf("Server ID: %s", serverID)

	// Create game room manager
	roomManager := network.NewRoomManager()

	// Create matchmaker client
	matchmakerClient := matchmaker.NewClient(serverID)

	// Create WebSocket server
	wsServer := network.NewServer(*port, *gamePort, roomManager, matchmakerClient)

	// Start matchmaker connection
	if !*devMode {
		go matchmakerClient.Connect("matcher.gritsgame.appspot.com", 80)
	}

	// Start server
	go func() {
		if err := wsServer.Start(); err != nil {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	wsServer.Shutdown(ctx)
	matchmakerClient.Close()
}

func generateServerID() string {
	b := make([]byte, 18)
	rand.Read(b)
	return base64.StdEncoding.EncodeToString(b)
}