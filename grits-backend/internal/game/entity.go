// internal/game/entity.go
package game

import (
	"grits-backend/internal/utils"
)

type Entity interface {
	GetID() string
	SetID(id string)
	GetName() string
	SetName(name string)
	GetPosition() utils.Vector2
	SetPosition(pos utils.Vector2)
	GetSize() utils.Vector2
	IsKilled() bool
	SetKilled(killed bool)
	GetZIndex() int
	Update(deltaTime float64)
	OnTouch(other Entity, impulse float64)
}

type BaseEntity struct {
	ID       string
	Name     string
	Position utils.Vector2
	Size     utils.Vector2
	Killed   bool
	ZIndex   int
}

func (e *BaseEntity) GetID() string           { return e.ID }
func (e *BaseEntity) SetID(id string)         { e.ID = id }
func (e *BaseEntity) GetName() string         { return e.Name }
func (e *BaseEntity) SetName(name string)     { e.Name = name }
func (e *BaseEntity) GetPosition() utils.Vector2 { return e.Position }
func (e *BaseEntity) SetPosition(pos utils.Vector2) { e.Position = pos }
func (e *BaseEntity) GetSize() utils.Vector2  { return e.Size }
func (e *BaseEntity) IsKilled() bool          { return e.Killed }
func (e *BaseEntity) SetKilled(killed bool)   { e.Killed = killed }
func (e *BaseEntity) GetZIndex() int          { return e.ZIndex }
func (e *BaseEntity) Update(deltaTime float64) {}
func (e *BaseEntity) OnTouch(other Entity, impulse float64) {}