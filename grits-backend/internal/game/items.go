// internal/game/items.go
package game

import (
	"grits-backend/internal/physics"
	"grits-backend/internal/utils"
)

type HealthCanister struct {
	BaseEntity
	PhysicsBody *physics.PhysicsBody
	HealAmount  float64
}

func NewHealthCanister(pos utils.Vector2) *HealthCanister {
	h := &HealthCanister{
		BaseEntity: BaseEntity{
			Position: pos,
			Size:     utils.NewVector2(19, 18),
			ZIndex:   2,
		},
		HealAmount: 10,
	}
	
	// Create physics body
	bodyDef := &physics.BodyDef{
		ID:       "HealthCanister_" + h.ID,
		Position: pos,
		HalfSize: utils.NewVector2(9.5, 9),
		Type:     "static",
		Categories: physics.CatProjectile,
		CollidesWith: physics.CatPlayer,
		UserData: map[string]interface{}{"entity": h},
	}
	
	// h.PhysicsBody = physicsEngine.AddBody(bodyDef)
	return h
}

func (h *HealthCanister) OnTouch(other Entity, impulse float64) {
	if player, ok := other.(*Player); ok {
		if player.Health < player.MaxHealth {
			player.Heal(h.HealAmount)
			h.Killed = true
		}
	}
}

type EnergyCanister struct {
	BaseEntity
	PhysicsBody *physics.PhysicsBody
	EnergyAmount float64
}

func NewEnergyCanister(pos utils.Vector2) *EnergyCanister {
	e := &EnergyCanister{
		BaseEntity: BaseEntity{
			Position: pos,
			Size:     utils.NewVector2(19, 18),
			ZIndex:   2,
		},
		EnergyAmount: 10,
	}
	return e
}

func (e *EnergyCanister) OnTouch(other Entity, impulse float64) {
	if player, ok := other.(*Player); ok {
		if player.Energy < player.MaxEnergy {
			player.AddEnergy(e.EnergyAmount)
			e.Killed = true
		}
	}
}

type QuadDamage struct {
	BaseEntity
	PhysicsBody *physics.PhysicsBody
	Duration    float64
}

func NewQuadDamage(pos utils.Vector2) *QuadDamage {
	q := &QuadDamage{
		BaseEntity: BaseEntity{
			Position: pos,
			Size:     utils.NewVector2(32, 32),
			ZIndex:   2,
		},
		Duration: QuadDamageDuration,
	}
	return q
}

func (q *QuadDamage) OnTouch(other Entity, impulse float64) {
	if player, ok := other.(*Player); ok {
		player.PowerUpTime = q.Duration
		q.Killed = true
	}
}