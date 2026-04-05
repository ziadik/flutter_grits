// internal/physics/collision.go
package physics

const (
	CatPlayer         uint16 = 0x0001
	CatTeam0          uint16 = 0x0001 << 1
	CatTeam1          uint16 = 0x0001 << 2
	CatProjectile     uint16 = 0x0001 << 3
	CatPickupObject   uint16 = 0x0001 << 4
	CatMapObject      uint16 = 0x0001 << 5
	CatProjectileIgnore uint16 = 0x0001 << 6
	CatAll            uint16 = 0xFFFF
)

func (e *PhysicsEngine) RayCast(start, end utils.Vector2) *RayCastResult {
	direction := end.Sub(start)
	length := direction.Length()
	direction = direction.Normalized()

	var closestHit *RayCastResult
	closestDistance := length

	for _, body := range e.bodies {
		if !body.IsActive {
			continue
		}

		hit, distance := e.rayCastBody(start, direction, body)
		if hit && distance < closestDistance {
			closestHit = &RayCastResult{
				Body:     body,
				Point:    start.Add(direction.Mul(distance)),
				Distance: distance,
			}
			closestDistance = distance
		}
	}

	return closestHit
}

func (e *PhysicsEngine) rayCastBody(start, direction utils.Vector2, body *PhysicsBody) (bool, float64) {
	// AABB ray casting
	t1 := (body.Position.X - body.HalfSize.X - start.X) / direction.X
	t2 := (body.Position.X + body.HalfSize.X - start.X) / direction.X
	t3 := (body.Position.Y - body.HalfSize.Y - start.Y) / direction.Y
	t4 := (body.Position.Y + body.HalfSize.Y - start.Y) / direction.Y

	tmin := max(0, min(max(t1, t2), max(t3, t4)))
	tmax := min(1, max(min(t1, t2), min(t3, t4)))

	if tmax < tmin {
		return false, 0
	}

	return true, tmin
}

type RayCastResult struct {
	Body     *PhysicsBody
	Point    utils.Vector2
	Distance float64
}

func min(a, b float64) float64 {
	if a < b {
		return a
	}
	return b
}

func max(a, b float64) float64 {
	if a > b {
		return a
	}
	return b
}