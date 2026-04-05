// internal/game/weapons_ext.go
package game

import (
	"math"
	"grits-backend/internal/utils"
)

type ChainGun struct {
	BaseWeapon
}

func NewChainGun() *ChainGun {
	return &ChainGun{
		BaseWeapon: BaseWeapon{
			EnergyCost: ChainGunEnergyCost,
			FireDelay:  ChainGunFireDelay,
		},
	}
}

func (w *ChainGun) OnFire(owner *Player) {
	w.BaseWeapon.OnFire(owner)
	if !w.Firing {
		return
	}

	dir := utils.NewVector2(
		math.Cos(owner.FaceAngleRadians),
		math.Sin(owner.FaceAngleRadians),
	)

	startPos := owner.Position.Add(dir.Mul(20))

	projectile := NewSimpleProjectile(
		startPos,
		dir,
		owner.Team,
		owner.Name,
		800.0,
		3.0, // Less damage but faster fire rate
		1.5,
	)
	_ = projectile
}

type Landmine struct {
	BaseWeapon
}

func NewLandmine() *Landmine {
	return &Landmine{
		BaseWeapon: BaseWeapon{
			EnergyCost: LandmineEnergyCost,
			FireDelay:  LandmineFireDelay,
		},
	}
}

func (w *Landmine) OnFire(owner *Player) {
	w.BaseWeapon.OnFire(owner)
	if !w.Firing {
		return
	}

	dir := utils.NewVector2(
		math.Cos(owner.FaceAngleRadians),
		math.Sin(owner.FaceAngleRadians),
	)

	// Place mine behind player
	startPos := owner.Position.Sub(dir.Mul(25))

	mine := NewLandmineDisk(startPos, owner.Team, owner.Name)
	_ = mine
}

type LandmineDisk struct {
	BaseEntity
	Team      int
	OwnerName string
	Lifetime  float64
	Age       float64
	PhysicsBody *physics.PhysicsBody
}

func NewLandmineDisk(pos utils.Vector2, team int, ownerName string) *LandmineDisk {
	return &LandmineDisk{
		BaseEntity: BaseEntity{
			Position: pos,
			Size:     utils.NewVector2(19, 18),
			ZIndex:   2,
		},
		Team:      team,
		OwnerName: ownerName,
		Lifetime:  5.0, // 5 seconds
	}
}

func (m *LandmineDisk) Update(deltaTime float64) {
	m.Age += deltaTime
	if m.Age >= m.Lifetime {
		m.Killed = true
	}
}

func (m *LandmineDisk) OnTouch(other Entity, impulse float64) {
	if player, ok := other.(*Player); ok {
		if player.Team != m.Team {
			player.TakeDamage(50) // Big damage
			m.Killed = true
		}
	}
}

type Shield struct {
	BaseWeapon
	ShieldInstance *ShieldInstance
}

func NewShield() *Shield {
	return &Shield{
		BaseWeapon: BaseWeapon{
			EnergyCost: 0.05,
			FireDelay:  0,
		},
	}
}

func (w *Shield) OnUpdate(owner *Player, deltaTime float64) {
	if w.ShieldInstance != nil && (w.ShieldInstance.IsKilled() || owner.Energy <= 0) {
		w.ShieldInstance = nil
	}
}

func (w *Shield) OnFire(owner *Player) {
	if w.ShieldInstance != nil {
		return
	}
	
	w.BaseWeapon.OnFire(owner)
	w.ShieldInstance = NewShieldInstance(owner.Position, owner)
}

type ShieldInstance struct {
	BaseEntity
	Owner *Player
	PhysicsBody *physics.PhysicsBody
}

func NewShieldInstance(pos utils.Vector2, owner *Player) *ShieldInstance {
	s := &ShieldInstance{
		BaseEntity: BaseEntity{
			Position: pos,
			Size:     utils.NewVector2(30, 30),
			ZIndex:   20,
		},
		Owner: owner,
	}
	return s
}

func (s *ShieldInstance) Update(deltaTime float64) {
	if s.Owner != nil {
		s.Position = s.Owner.Position
	}
}

type Sword struct {
	BaseWeapon
	SwordInstance *SwordInstance
}

func NewSword() *Sword {
	return &Sword{
		BaseWeapon: BaseWeapon{
			EnergyCost: 0.05,
			FireDelay:  0,
		},
	}
}

func (w *Sword) OnFire(owner *Player) {
	if w.SwordInstance != nil {
		return
	}
	
	w.BaseWeapon.OnFire(owner)
	w.SwordInstance = NewSwordInstance(owner.Position, owner)
}

type SwordInstance struct {
	BaseEntity
	Owner *Player
	Rotation float64
	PhysicsBody *physics.PhysicsBody
}

func NewSwordInstance(pos utils.Vector2, owner *Player) *SwordInstance {
	s := &SwordInstance{
		BaseEntity: BaseEntity{
			Position: pos,
			Size:     utils.NewVector2(64, 64),
			ZIndex:   20,
		},
		Owner:    owner,
		Rotation: 0,
	}
	return s
}

func (s *SwordInstance) Update(deltaTime float64) {
	if s.Owner != nil {
		s.Position = s.Owner.Position
		s.Rotation += 8 * math.Pi / 180
	}
}

func (s *SwordInstance) OnTouch(other Entity, impulse float64) {
	if player, ok := other.(*Player); ok {
		if player.Team != s.Owner.Team {
			player.TakeDamage(15)
		}
	}
}

type Thrusters struct {
	BaseWeapon
	StoredSpeed float64
}

func NewThrusters() *Thrusters {
	return &Thrusters{
		BaseWeapon: BaseWeapon{
			EnergyCost: 0,
			FireDelay:  0,
		},
		StoredSpeed: -1,
	}
}

func (w *Thrusters) OnUpdate(owner *Player, deltaTime float64) {
	if owner.Fire2Off && w.StoredSpeed != -1 {
		owner.WalkSpeed = w.StoredSpeed
		w.StoredSpeed = -1
	}
}

func (w *Thrusters) OnFire(owner *Player) {
	if w.StoredSpeed != -1 {
		return
	}
	
	w.StoredSpeed = owner.WalkSpeed
	owner.WalkSpeed += owner.WalkSpeed * 0.3 // 30% speed boost
}

type BounceBallGun struct {
	BaseWeapon
}

func NewBounceBallGun() *BounceBallGun {
	return &BounceBallGun{
		BaseWeapon: BaseWeapon{
			EnergyCost: 8,
			FireDelay:  0.5,
		},
	}
}

func (w *BounceBallGun) OnFire(owner *Player) {
	w.BaseWeapon.OnFire(owner)
	if !w.Firing {
		return
	}

	dir := utils.NewVector2(
		math.Cos(owner.FaceAngleRadians),
		math.Sin(owner.FaceAngleRadians),
	)

	startPos := owner.Position.Add(dir.Mul(20))

	bullet := NewBounceBallBullet(startPos, dir, owner.Team, owner.Name)
	_ = bullet
}

type BounceBallBullet struct {
	SimpleProjectile
	Bounces int
}

func NewBounceBallBullet(pos, dir utils.Vector2, team int, ownerName string) *BounceBallBullet {
	b := &BounceBallBullet{
		SimpleProjectile: SimpleProjectile{
			Direction: dir,
			Speed:     800,
			Damage:    5,
			Lifetime:  2,
			Team:      team,
			OwnerName: ownerName,
		},
		Bounces: 3,
	}
	b.Position = pos
	b.Size = utils.NewVector2(11, 5)
	return b
}

func (b *BounceBallBullet) OnTouch(other Entity, impulse float64) {
	if player, ok := other.(*Player); ok {
		if player.Team != b.Team {
			player.TakeDamage(b.Damage)
			b.Killed = true
		}
	} else {
		// Bounce off walls
		b.Bounces--
		if b.Bounces <= 0 {
			b.Killed = true
		} else {
			// Reverse direction on bounce (simplified)
			b.Direction = b.Direction.Mul(-1)
		}
	}
}