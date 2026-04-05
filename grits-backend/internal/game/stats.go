// internal/game/stats.go
package game

import "../../../server/internal/game/sync"

type GameStats struct {
	mu     sync.RWMutex
	counts map[string]int64
	logs   map[string][]interface{}
}

func NewGameStats() *GameStats {
	return &GameStats{
		counts: make(map[string]int64),
		logs:   make(map[string][]interface{}),
	}
}

func (s *GameStats) Inc(name string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.counts[name]++
}

func (s *GameStats) Add(name string, count int64) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.counts[name] += count
}

func (s *GameStats) Log(name string, data interface{}) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.logs[name] = append(s.logs[name], data)

	// Trim logs if too large
	if len(s.logs[name]) > 100000 {
		s.logs[name] = s.logs[name][50000:]
	}
}

func (s *GameStats) GetCounts() map[string]int64 {
	s.mu.RLock()
	defer s.mu.RUnlock()

	result := make(map[string]int64)
	for k, v := range s.counts {
		result[k] = v
	}
	return result
}
