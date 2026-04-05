// internal/utils/rect.go
package utils

type Rect struct {
	X      float64
	Y      float64
	Width  float64
	Height float64
}

func NewRect(x, y, width, height float64) Rect {
	return Rect{
		X:      x,
		Y:      y,
		Width:  width,
		Height: height,
	}
}

func (r Rect) Left() float64   { return r.X }
func (r Rect) Right() float64  { return r.X + r.Width }
func (r Rect) Top() float64    { return r.Y }
func (r Rect) Bottom() float64 { return r.Y + r.Height }

func (r Rect) Contains(point Vector2) bool {
	return point.X >= r.Left() && point.X <= r.Right() &&
		point.Y >= r.Top() && point.Y <= r.Bottom()
}

func (r Rect) Intersects(other Rect) bool {
	return !(other.Left() > r.Right() ||
		other.Right() < r.Left() ||
		other.Top() > r.Bottom() ||
		other.Bottom() < r.Top())
}