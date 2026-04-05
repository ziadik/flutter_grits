// internal/game/projectile.go
package game

import (
	"grits-backend/internal/utils"
)

type SimpleProjectile struct {
	BaseEntity

	Direction   utils.Vector2
	Speed       float64
	Damage      float64
	Lifetime    float64
	Age         float64
	Team        int
	OwnerName   string
}

func NewSimpleProjectile(pos, dir utils.Vector2, team int, ownerName string, speed, damage, lifetime float64) *SimpleProjectile {
	return &SimpleProjectile{
		BaseEntity: BaseEntity{
			Position: pos,
			Size:     utils.NewVector2(10, 10),
			ZIndex:   2,
		},
		Direction: dir.Normalized(),
		Speed:     speed,
		Damage:    damage,
		Lifetime:  lifetime,
		Team:      team,
		OwnerName: ownerName,
	}
}

func (p *SimpleProjectile) Update(deltaTime float64) {
	p.Age += deltaTime

	if p.Age >= p.Lifetime {
		p.Killed = true
		return
	}

	p.Position = p.Position.Add(p.Direction.Mul(p.Speed * deltaTime))
}

func (p *SimpleProjectile) OnTouch(other Entity, impulse float64) {
	if player, ok := other.(*Player); ok {
		if player.Name != p.OwnerName && player.Team != p.Team {
			// Deal damage
			player.TakeDamage(p.Damage)
			p.Killed = true
		}
	} else {
		// Hit wall or other object
		p.Killed = true
	}
}