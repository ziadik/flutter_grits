// internal/utils/vector.go
package utils

import "../../../server/internal/utils/math"

type Vector2 struct {
	X float64
	Y float64
}

func NewVector2(x, y float64) Vector2 {
	return Vector2{X: x, Y: y}
}

func ZeroVector() Vector2 {
	return Vector2{X: 0, Y: 0}
}

func (v Vector2) Add(other Vector2) Vector2 {
	return Vector2{X: v.X + other.X, Y: v.Y + other.Y}
}

func (v Vector2) Sub(other Vector2) Vector2 {
	return Vector2{X: v.X - other.X, Y: v.Y - other.Y}
}

func (v Vector2) Mul(scalar float64) Vector2 {
	return Vector2{X: v.X * scalar, Y: v.Y * scalar}
}

func (v Vector2) Div(scalar float64) Vector2 {
	return Vector2{X: v.X / scalar, Y: v.Y / scalar}
}

func (v Vector2) Dot(other Vector2) float64 {
	return v.X*other.X + v.Y*other.Y
}

func (v Vector2) Length() float64 {
	return math.Sqrt(v.X*v.X + v.Y*v.Y)
}

func (v Vector2) LengthSq() float64 {
	return v.X*v.X + v.Y*v.Y
}

func (v Vector2) Normalized() Vector2 {
	len := v.Length()
	if len == 0 {
		return ZeroVector()
	}
	return Vector2{X: v.X / len, Y: v.Y / len}
}

func (v Vector2) DistanceTo(other Vector2) float64 {
	dx := v.X - other.X
	dy := v.Y - other.Y
	return math.Sqrt(dx*dx + dy*dy)
}
