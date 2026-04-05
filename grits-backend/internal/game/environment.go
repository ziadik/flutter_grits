// internal/game/environment.go
package game

import (
	"grits-backend/internal/utils"
)

type Teleporter struct {
	BaseEntity
	Destination utils.Vector2
	PhysicsBody *physics.PhysicsBody
}

func NewTeleporter(name string, pos, size, dest utils.Vector2) *Teleporter {
	t := &Teleporter{
		BaseEntity: BaseEntity{
			ID:       name,
			Name:     name,
			Position: pos,
			Size:     size,
			ZIndex:   0,
		},
		Destination: dest,
	}
	return t
}

func (t *Teleporter) OnTouch(other Entity, impulse float64) {
	if player, ok := other.(*Player); ok {
		if player.lastCloseTeleportPos == nil {
			player.SetPosition(t.Destination)
			player.lastCloseTeleportPos = &t.Destination
		}
	}
}

type SpawnPoint struct {
	BaseEntity
	Team int
}

func NewSpawnPoint(name string, pos, size utils.Vector2, team int) *SpawnPoint {
	return &SpawnPoint{
		BaseEntity: BaseEntity{
			ID:       name,
			Name:     name,
			Position: pos,
			Size:     size,
			ZIndex:   0,
		},
		Team: team,
	}
}

type Spawner struct {
	BaseEntity
	SpawnItem     string
	LastSpawned   Entity
	NextSpawnTime float64
}

func NewSpawner(name string, pos, size utils.Vector2, spawnItem string) *Spawner {
	return &Spawner{
		BaseEntity: BaseEntity{
			ID:       name,
			Name:     name,
			Position: pos,
			Size:     size,
			ZIndex:   0,
		},
		SpawnItem: spawnItem,
	}
}

func (s *Spawner) Update(deltaTime float64) {
	if s.LastSpawned == nil || s.LastSpawned.IsKilled() {
		currentTime := GetGameTime()
		if currentTime >= s.NextSpawnTime {
			s.spawnItem()
			s.NextSpawnTime = currentTime + 20.0 // Respawn after 20 seconds
		}
	}
}

func (s *Spawner) spawnItem() {
	var entity Entity
	
	switch s.SpawnItem {
	case "QuadDamage":
		entity = NewQuadDamage(s.Position)
	case "HealthCanister":
		entity = NewHealthCanister(s.Position)
	case "EnergyCanister":
		entity = NewEnergyCanister(s.Position)
	default:
		return
	}
	
	// Get game engine and spawn
	// gameEngine.SpawnEntity(entity)
	s.LastSpawned = entity
}