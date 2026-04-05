// internal/game/constants.go
package game

const (
	// Game loop timing
	GameUpdatesPerSec   = 10
	GameLoopHz          = 1.0 / 10.0
	PhysicsUpdatesPerSec = 60
	PhysicsLoopHz       = 1.0 / 60.0

	// Player constants
	DefaultWalkSpeed    = 260.0 // 52 * 5
	DefaultHealth       = 100.0
	DefaultMaxHealth    = 100.0
	DefaultEnergy       = 100.0
	DefaultMaxEnergy    = 100.0

	// World constants
	CellSize            = 64.0
	MaxTranslation      = 99999.0

	// Weapon constants
	MachineGunEnergyCost    = 2.0
	MachineGunFireDelay     = 0.1
	ShotgunEnergyCost       = 4.0
	ShotgunFireDelay        = 0.25
	RocketLauncherEnergyCost = 10.0
	RocketLauncherFireDelay  = 0.5
	ChainGunEnergyCost      = 1.0
	ChainGunFireDelay       = 0.05
	LandmineEnergyCost      = 10.0
	LandmineFireDelay       = 0.5

	// Projectile constants
	DefaultProjectileSpeed  = 800.0
	DefaultProjectileDamage = 10.0
	DefaultProjectileLifetime = 2.0

	// Power-up constants
	QuadDamageDuration = 30.0 // seconds
)