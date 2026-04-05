// internal/game/weapon.go
package game

import (
	"grits-backend/internal/utils"
	"math"
)

type Weapon interface {
	GetEnergyCost() float64
	GetFireDelay() float64
	OnInit(owner *Player)
	OnUpdate(owner *Player, deltaTime float64)
	OnFire(owner *Player)
}

type BaseWeapon struct {
	EnergyCost   float64
	FireDelay    float64
	NextFireTime float64
	Firing       bool
}

func (w *BaseWeapon) GetEnergyCost() float64 { return w.EnergyCost }
func (w *BaseWeapon) GetFireDelay() float64  { return w.FireDelay }

func (w *BaseWeapon) CanFire(currentTime float64) bool {
	return currentTime >= w.NextFireTime
}

func (w *BaseWeapon) OnFire(owner *Player) {
	currentTime := owner.GetGameTime()
	if !w.CanFire(currentTime) {
		return
	}

	owner.Energy -= w.EnergyCost
	w.Firing = true
	w.NextFireTime = currentTime + w.FireDelay
}

type MachineGun struct {
	BaseWeapon
}

func NewMachineGun() *MachineGun {
	return &MachineGun{
		BaseWeapon: BaseWeapon{
			EnergyCost: MachineGunEnergyCost,
			FireDelay:  MachineGunFireDelay,
		},
	}
}

func (w *MachineGun) OnInit(owner *Player) {}

func (w *MachineGun) OnUpdate(owner *Player, deltaTime float64) {}

func (w *MachineGun) OnFire(owner *Player) {
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
		DefaultProjectileSpeed,
		5.0, // damage
		2.0, // lifetime
	)

	// Get game engine and spawn projectile
	// engine.SpawnEntity(projectile)
}

type ShotGun struct {
	BaseWeapon
}

func NewShotGun() *ShotGun {
	return &ShotGun{
		BaseWeapon: BaseWeapon{
			EnergyCost: ShotgunEnergyCost,
			FireDelay:  ShotgunFireDelay,
		},
	}
}

func (w *ShotGun) OnFire(owner *Player) {
	w.BaseWeapon.OnFire(owner)
	if !w.Firing {
		return
	}

	numBullets := 5
	spread := 2.0

	for i := 0; i < numBullets; i++ {
		sprayOffset := (float64(i)/float64(numBullets))*spread - spread/2
		dir := utils.NewVector2(
			math.Cos(owner.FaceAngleRadians+sprayOffset),
			math.Sin(owner.FaceAngleRadians+sprayOffset),
		)

		startPos := owner.Position.Add(dir.Mul(20))

		projectile := NewSimpleProjectile(
			startPos,
			dir,
			owner.Team,
			owner.Name,
			700.0,
			10.0,
			2.0,
		)
		_ = projectile
	}
}

type RocketLauncher struct {
	BaseWeapon
}

func NewRocketLauncher() *RocketLauncher {
	return &RocketLauncher{
		BaseWeapon: BaseWeapon{
			EnergyCost: RocketLauncherEnergyCost,
			FireDelay:  RocketLauncherFireDelay,
		},
	}
}

func (w *RocketLauncher) OnFire(owner *Player) {
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
		900.0,
		15.0,
		3.0,
	)
	_ = projectile
}

// Additional weapons: ChainGun, Landmine, Shield, Sword, Thrusters, BounceBallGun
