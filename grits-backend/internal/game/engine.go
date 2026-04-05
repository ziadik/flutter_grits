// internal/game/engine.go
package game

import (
	"log"
	"sync"
	"time"

	"grits-backend/internal/utils"
)

type GameEngine struct {
	mu sync.RWMutex

	Entities      map[string]Entity
	Players       map[string]*Player
	NamedEntities map[string]Entity

	Map           *TileMap
	PhysicsEngine *PhysicsEngine

	TimeSinceGameUpdate    float64
	TimeSincePhysicsUpdate float64
	CurrentTick            int64

	SpawnCounter    int
	DeferredKill    []string
	DeferredRespawn []RespawnRequest

	Broadcaster MessageBroadcaster
	Stats       *GameStats
}

type RespawnRequest struct {
	From string
	Wep0 string
	Wep1 string
	Wep2 string
}

type MessageBroadcaster interface {
	Broadcast(msg string, flags int, exclude string)
}

func NewGameEngine(broadcaster MessageBroadcaster, stats *GameStats) *GameEngine {
	return &GameEngine{
		Entities:      make(map[string]Entity),
		Players:       make(map[string]*Player),
		NamedEntities: make(map[string]Entity),
		Broadcaster:   broadcaster,
		Stats:         stats,
	}
}

func (e *GameEngine) Setup() {
	e.PhysicsEngine = NewPhysicsEngine()
	e.PhysicsEngine.SetContactListener(e.onCollision)

	// Load map
	e.Map = NewTileMap()
}

func (e *GameEngine) GetTime() float64 {
	return float64(e.CurrentTick) * PhysicsLoopHz
}

func (e *GameEngine) GetEntityByName(name string) Entity {
	e.mu.RLock()
	defer e.mu.RUnlock()
	return e.NamedEntities[name]
}

func (e *GameEngine) GetEntityByID(id string) Entity {
	e.mu.RLock()
	defer e.mu.RUnlock()
	return e.Entities[id]
}

func (e *GameEngine) SpawnEntity(entity Entity) {
	e.mu.Lock()
	defer e.mu.Unlock()

	entity.SetID(e.nextSpawnID())
	e.Entities[entity.GetID()] = entity

	if name := entity.GetName(); name != "" {
		e.NamedEntities[name] = entity
	}

	if player, ok := entity.(*Player); ok {
		e.Players[player.GetName()] = player
	}

	if e.Stats != nil {
		e.Stats.Inc("entities_spawned")
	}

	// Broadcast spawn to all clients
	if e.Broadcaster != nil && entity.GetName() != "" {
		e.Broadcaster.Broadcast(e.encodeSpawn(entity), 0, "")
	}
}

func (e *GameEngine) RemoveEntity(entity Entity) {
	e.mu.Lock()
	defer e.mu.Unlock()

	if name := entity.GetName(); name != "" {
		delete(e.NamedEntities, name)
		delete(e.Players, name)
	}

	entity.SetKilled(true)
	e.DeferredKill = append(e.DeferredKill, entity.GetID())
}

func (e *GameEngine) Update(deltaTime float64) {
	e.mu.Lock()

	// Update all entities
	for _, entity := range e.Entities {
		if !entity.IsKilled() {
			entity.Update(deltaTime)
		}
	}

	// Remove killed entities
	for _, id := range e.DeferredKill {
		delete(e.Entities, id)
	}
	e.DeferredKill = nil

	// Process respawns
	for _, req := range e.DeferredRespawn {
		e.processRespawn(req)
	}
	e.DeferredRespawn = nil

	e.mu.Unlock()

	// Update players
	for _, player := range e.Players {
		player.ApplyInputs()
	}

	e.CurrentTick++
}

func (e *GameEngine) UpdatePhysics(deltaTime float64) {
	e.PhysicsEngine.Update(deltaTime)

	// Sync player positions from physics
	for _, player := range e.Players {
		if body := player.GetPhysicsBody(); body != nil {
			pos := body.GetPosition()
			player.SetPosition(pos)
		}
	}
}

func (e *GameEngine) Run(deltaTime float64) {
	e.TimeSinceGameUpdate += deltaTime
	e.TimeSincePhysicsUpdate += deltaTime

	for e.TimeSinceGameUpdate >= GameLoopHz &&
		e.TimeSincePhysicsUpdate >= PhysicsLoopHz {
		e.Update(GameLoopHz)
		e.UpdatePhysics(PhysicsLoopHz)
		e.TimeSinceGameUpdate -= GameLoopHz
		e.TimeSincePhysicsUpdate -= PhysicsLoopHz
	}

	for e.TimeSincePhysicsUpdate >= PhysicsLoopHz {
		e.UpdatePhysics(PhysicsLoopHz)
		e.TimeSincePhysicsUpdate -= PhysicsLoopHz
	}
}

func (e *GameEngine) SpawnPlayer(id string, teamID int, spawnPointName string, playerType string, userID string, displayName string) *Player {
	spawnPoint := e.GetEntityByName(spawnPointName)
	if spawnPoint == nil {
		log.Printf("Could not find spawn point: %s", spawnPointName)
		return nil
	}

	player := NewPlayer(
		"!"+id,
		spawnPoint.GetPosition(),
		teamID,
		userID,
		displayName,
	)

	e.SpawnEntity(player)

	if e.Broadcaster != nil {
		e.Broadcaster.Broadcast(e.encodeWelcome(id, teamID), 0, "")
	}

	return player
}

func (e *GameEngine) UnspawnPlayer(id string) {
	if player, ok := e.Players["!"+id]; ok {
		e.RemoveEntity(player)
	}
}

func (e *GameEngine) DealDamage(source Entity, target *Player, amount float64) {
	if target.IsKilled() {
		return
	}

	target.TakeDamage(amount)

	if target.GetHealth() <= 0 {
		var killerName string
		if source != nil {
			if player, ok := source.(*Player); ok {
				killerName = player.GetDisplayName()
				player.AddKill()
			}
		}

		msg := target.GetDisplayName() + " was killed"
		if killerName != "" {
			msg += " by " + killerName
		}

		if e.Broadcaster != nil {
			e.Broadcaster.Broadcast(e.encodeStatusMsg(msg), 0, "")
		}
	}
}

func (e *GameEngine) onCollision(bodyA, bodyB interface{}, impulse float64) {
	// Handle collision between entities
	// This would be called from physics engine
}

func (e *GameEngine) nextSpawnID() string {
	e.SpawnCounter++
	return string(rune(e.SpawnCounter))
}

// Protocol encoding methods (simplified)
func (e *GameEngine) encodeSpawn(entity Entity) string {
	// In real implementation, use proper serialization (JSON/Protobuf)
	return ""
}

func (e *GameEngine) encodeWelcome(id string, team int) string {
	return ""
}

func (e *GameEngine) encodeStatusMsg(msg string) string {
	return ""
}

func (e *GameEngine) processRespawn(req RespawnRequest) {
	player := e.GetEntityByName(req.From)
	if player == nil {
		return
	}

	p, ok := player.(*Player)
	if !ok {
		return
	}

	spawnPoint := e.GetEntityByName("Team0Spawn0") // Get appropriate spawn
	if spawnPoint == nil {
		return
	}

	p.ResetStats()
	p.SetPosition(spawnPoint.GetPosition())
}
