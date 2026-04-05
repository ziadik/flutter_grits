// internal/game/player.go
package game

import (
	"grits-backend/internal/utils"
	"math"
)

type Player struct {
	BaseEntity

	WalkSpeed   float64
	Weapons     [3]Weapon
	Health      float64
	MaxHealth   float64
	Energy      float64
	MaxEnergy   float64
	Team        int
	NumKills    int
	PowerUpTime float64
	IsDead      bool
	UserID      string
	DisplayName string

	// Input state
	InputVelocity       utils.Vector2
	FaceAngleRadians    float64
	Walking             bool
	Fire0, Fire1, Fire2 bool

	PhysicsBody          *PhysicsBody
	lastCloseTeleportPos *utils.Vector2
	Fire2Off             bool
	GetGameTimeFn        func() float64
}

func (p *Player) GetGameTime() float64 {
	if p.GetGameTimeFn != nil {
		return p.GetGameTimeFn()
	}
	return GetGameTime()
}

func NewPlayer(name string, pos utils.Vector2, team int, userID, displayName string) *Player {
	p := &Player{
		BaseEntity: BaseEntity{
			Name:     name,
			Position: pos,
			Size:     utils.NewVector2(52, 52),
			ZIndex:   1,
		},
		WalkSpeed:   DefaultWalkSpeed,
		Health:      DefaultHealth,
		MaxHealth:   DefaultMaxHealth,
		Energy:      DefaultEnergy,
		MaxEnergy:   DefaultMaxEnergy,
		Team:        team,
		UserID:      userID,
		DisplayName: displayName,
	}

	// Initialize weapons
	p.Weapons[0] = NewMachineGun()
	p.Weapons[1] = NewShield()
	p.Weapons[2] = NewThrusters()

	for i := range p.Weapons {
		if p.Weapons[i] != nil {
			p.Weapons[i].OnInit(p)
		}
	}

	return p
}

func (p *Player) Update(deltaTime float64) {
	if p.PowerUpTime > 0 {
		p.PowerUpTime -= deltaTime
		if p.PowerUpTime < 0 {
			p.PowerUpTime = 0
		}
	}

	// Update weapons
	for i := range p.Weapons {
		if p.Weapons[i] != nil {
			p.Weapons[i].OnUpdate(p, deltaTime)
		}
	}

	if p.Health <= 0 && !p.IsDead {
		p.IsDead = true
		if p.PhysicsBody != nil {
			p.PhysicsBody.SetActive(false)
		}
	} else if p.IsDead && p.Health > 0 {
		p.IsDead = false
		if p.PhysicsBody != nil {
			p.PhysicsBody.SetActive(true)
		}
	}
}

func (p *Player) ApplyInputs() {
	if p.IsDead {
		return
	}

	// Apply movement
	if p.InputVelocity.X != 0 || p.InputVelocity.Y != 0 {
		p.Walking = true
		p.FaceAngleRadians = math.Atan2(p.InputVelocity.Y, p.InputVelocity.X)

		newPos := p.Position.Add(p.InputVelocity.Mul(p.WalkSpeed * PhysicsLoopHz))
		// Apply boundary constraints
		newPos.X = math.Max(0, math.Min(newPos.X, 10000)) // Use actual map bounds
		newPos.Y = math.Max(0, math.Min(newPos.Y, 10000))
		p.Position = newPos

		if p.PhysicsBody != nil {
			p.PhysicsBody.SetLinearVelocity(utils.NewVector2(
				p.InputVelocity.X*p.WalkSpeed,
				p.InputVelocity.Y*p.WalkSpeed,
			))
		}
	} else {
		p.Walking = false
	}

	// Handle firing
	if !p.IsDead {
		if p.Fire0 && p.Weapons[0] != nil && p.Energy >= p.Weapons[0].GetEnergyCost() {
			p.Weapons[0].OnFire(p)
			p.Fire0 = false
		}
		if p.Fire1 && p.Weapons[1] != nil && p.Energy >= p.Weapons[1].GetEnergyCost() {
			p.Weapons[1].OnFire(p)
			p.Fire1 = false
		}
		if p.Fire2 && p.Weapons[2] != nil && p.Energy >= p.Weapons[2].GetEnergyCost() {
			p.Weapons[2].OnFire(p)
			p.Fire2 = false
		}
	}
}

func (p *Player) TakeDamage(amount float64) {
	p.Health -= amount
	if p.Health < 0 {
		p.Health = 0
	}
}

func (p *Player) Heal(amount float64) {
	p.Health += amount
	if p.Health > p.MaxHealth {
		p.Health = p.MaxHealth
	}
}

func (p *Player) AddEnergy(amount float64) {
	p.Energy += amount
	if p.Energy > p.MaxEnergy {
		p.Energy = p.MaxEnergy
	}
}

func (p *Player) ResetStats() {
	p.Health = p.MaxHealth
	p.Energy = p.MaxEnergy
	p.IsDead = false
	p.PowerUpTime = 0
	if p.PhysicsBody != nil {
		p.PhysicsBody.SetActive(true)
	}
}

func (p *Player) AddKill() {
	p.NumKills++
}

func (p *Player) GetDisplayName() string {
	return p.DisplayName
}

func (p *Player) SetPhysicsBody(body *PhysicsBody) {
	p.PhysicsBody = body
}

func (p *Player) GetPhysicsBody() *PhysicsBody {
	return p.PhysicsBody
}
