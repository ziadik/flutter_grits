// internal/physics/engine.go
package physics

import (
	"grits-backend/internal/utils"
	"math"
	"sync"
)

type PhysicsBody struct {
	ID           string
	Position     utils.Vector2
	Velocity     utils.Vector2
	HalfSize     utils.Vector2
	Radius       float64
	Angle        float64
	IsStatic     bool
	IsActive     bool
	UserData     interface{}
	Categories   uint16
	CollidesWith uint16
}

type Contact struct {
	BodyA   *PhysicsBody
	BodyB   *PhysicsBody
	Impulse float64
	Point   utils.Vector2
}

type ContactListener interface {
	OnContact(bodyA, bodyB *PhysicsBody, impulse float64)
}

type PhysicsEngine struct {
	mu       sync.RWMutex
	bodies   []*PhysicsBody
	listener ContactListener
}

func NewPhysicsEngine() *PhysicsEngine {
	return &PhysicsEngine{
		bodies: make([]*PhysicsBody, 0),
	}
}

func (e *PhysicsEngine) AddBody(def *BodyDef) *PhysicsBody {
	e.mu.Lock()
	defer e.mu.Unlock()

	body := &PhysicsBody{
		ID:           def.ID,
		Position:     def.Position,
		HalfSize:     def.HalfSize,
		Radius:       def.Radius,
		Angle:        def.Angle,
		IsStatic:     def.Type == "static",
		IsActive:     true,
		UserData:     def.UserData,
		Categories:   def.Categories,
		CollidesWith: def.CollidesWith,
	}

	e.bodies = append(e.bodies, body)
	return body
}

func (e *PhysicsEngine) RemoveBody(body *PhysicsBody) {
	e.mu.Lock()
	defer e.mu.Unlock()

	for i, b := range e.bodies {
		if b == body {
			e.bodies = append(e.bodies[:i], e.bodies[i+1:]...)
			break
		}
	}
}

func (e *PhysicsEngine) Update(deltaTime float64) {
	e.mu.RLock()
	defer e.mu.RUnlock()

	// Update positions
	for _, body := range e.bodies {
		if !body.IsStatic && body.IsActive {
			body.Position = body.Position.Add(body.Velocity.Mul(deltaTime))
		}
	}

	// Check collisions
	e.checkCollisions()
}

func (e *PhysicsEngine) checkCollisions() {
	for i := 0; i < len(e.bodies); i++ {
		for j := i + 1; j < len(e.bodies); j++ {
			if e.shouldCollide(e.bodies[i], e.bodies[j]) {
				if impulse, point := e.checkCollision(e.bodies[i], e.bodies[j]); impulse > 0 {
					if e.listener != nil {
						e.listener.OnContact(e.bodies[i], e.bodies[j], impulse)
					}
				}
			}
		}
	}
}

func (e *PhysicsEngine) shouldCollide(a, b *PhysicsBody) bool {
	if !a.IsActive || !b.IsActive {
		return false
	}
	return (a.Categories&b.CollidesWith) != 0 || (b.Categories&a.CollidesWith) != 0
}

func (e *PhysicsEngine) checkCollision(a, b *PhysicsBody) (float64, utils.Vector2) {
	// AABB collision detection
	dx := a.Position.X - b.Position.X
	dy := a.Position.Y - b.Position.Y

	halfWidthSum := a.HalfSize.X + b.HalfSize.X
	halfHeightSum := a.HalfSize.Y + b.HalfSize.Y

	if math.Abs(dx) < halfWidthSum && math.Abs(dy) < halfHeightSum {
		// Calculate impulse (simplified)
		impulse := 0.5
		return impulse, utils.NewVector2(dx, dy)
	}

	return 0, utils.ZeroVector()
}

func (e *PhysicsEngine) SetContactListener(listener ContactListener) {
	e.listener = listener
}

type BodyDef struct {
	ID           string
	Position     utils.Vector2
	HalfSize     utils.Vector2
	Radius       float64
	Angle        float64
	Type         string // "static" or "dynamic"
	Damping      float64
	Categories   uint16
	CollidesWith uint16
	UserData     interface{}
}

func (b *PhysicsBody) GetPosition() utils.Vector2 {
	return b.Position
}

func (b *PhysicsBody) SetPosition(pos utils.Vector2) {
	b.Position = pos
}

func (b *PhysicsBody) GetLinearVelocity() utils.Vector2 {
	return b.Velocity
}

func (b *PhysicsBody) SetLinearVelocity(vel utils.Vector2) {
	b.Velocity = vel
}

func (b *PhysicsBody) SetActive(active bool) {
	b.IsActive = active
}
