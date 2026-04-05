// internal/game/time.go
package game

var globalGameTime float64

func SetGameTime(time float64) {
	globalGameTime = time
}

func GetGameTime() float64 {
	return globalGameTime
}