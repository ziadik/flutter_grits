// internal/game/map.go
package game

import (
	"encoding/json"
	"log"
	"os"
	"grits-backend/internal/physics"
	"grits-backend/internal/utils"
)

type TileMap struct {
	Width       int     `json:"width"`
	Height      int     `json:"height"`
	TileWidth   int     `json:"tilewidth"`
	TileHeight  int     `json:"tileheight"`
	Layers      []Layer `json:"layers"`
	Tilesets    []Tileset `json:"tilesets"`
	ViewRect    utils.Rect
	
	NumXTiles   int
	NumYTiles   int
	PixelSize   utils.Vector2
}

type Layer struct {
	Name     string   `json:"name"`
	Type     string   `json:"type"`
	Visible  bool     `json:"visible"`
	Opacity  float64  `json:"opacity"`
	Data     []int    `json:"data,omitempty"`
	Objects  []Object `json:"objects,omitempty"`
}

type Object struct {
	ID         int                `json:"id"`
	Name       string             `json:"name"`
	Type       string             `json:"type"`
	X          float64            `json:"x"`
	Y          float64            `json:"y"`
	Width      float64            `json:"width"`
	Height     float64            `json:"height"`
	Properties map[string]string  `json:"properties"`
	Polygon    []utils.Vector2    `json:"polygon,omitempty"`
}

type Tileset struct {
	FirstGID     int    `json:"firstgid"`
	Image        string `json:"image"`
	ImageWidth   int    `json:"imagewidth"`
	ImageHeight  int    `json:"imageheight"`
	Name         string `json:"name"`
	TileWidth    int    `json:"tilewidth"`
	TileHeight   int    `json:"tileheight"`
}

func NewTileMap() *TileMap {
	return &TileMap{
		ViewRect: utils.NewRect(0, 0, 1024, 768),
	}
}

func (m *TileMap) Load(path string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}

	var mapData map[string]interface{}
	if err := json.Unmarshal(data, &mapData); err != nil {
		return err
	}

	m.Width = int(mapData["width"].(float64))
	m.Height = int(mapData["height"].(float64))
	m.TileWidth = int(mapData["tilewidth"].(float64))
	m.TileHeight = int(mapData["tileheight"].(float64))
	
	m.NumXTiles = m.Width
	m.NumYTiles = m.Height
	m.PixelSize = utils.NewVector2(
		float64(m.Width*m.TileWidth),
		float64(m.Height*m.TileHeight),
	)

	// Load layers
	layersData := mapData["layers"].([]interface{})
	for _, layerData := range layersData {
		layer := m.parseLayer(layerData.(map[string]interface{}))
		m.Layers = append(m.Layers, layer)
	}

	// Load tilesets
	tilesetsData := mapData["tilesets"].([]interface{})
	for _, tsData := range tilesetsData {
		tileset := m.parseTileset(tsData.(map[string]interface{}))
		m.Tilesets = append(m.Tilesets, tileset)
	}

	return nil
}

func (m *TileMap) parseLayer(data map[string]interface{}) Layer {
	layer := Layer{
		Name:    data["name"].(string),
		Type:    data["type"].(string),
		Visible: data["visible"].(bool),
		Opacity: data["opacity"].(float64),
	}

	if layer.Type == "tilelayer" {
		dataArray := data["data"].([]interface{})
		layer.Data = make([]int, len(dataArray))
		for i, v := range dataArray {
			layer.Data[i] = int(v.(float64))
		}
	} else if layer.Type == "objectgroup" {
		objectsData := data["objects"].([]interface{})
		for _, objData := range objectsData {
			obj := m.parseObject(objData.(map[string]interface{}))
			layer.Objects = append(layer.Objects, obj)
		}
	}

	return layer
}

func (m *TileMap) parseObject(data map[string]interface{}) Object {
	obj := Object{
		ID:    int(data["id"].(float64)),
		Name:  data["name"].(string),
		Type:  data["type"].(string),
		X:     data["x"].(float64),
		Y:     data["y"].(float64),
		Width: data["width"].(float64),
		Height: data["height"].(float64),
	}

	// Parse properties
	if props, ok := data["properties"].(map[string]interface{}); ok {
		obj.Properties = make(map[string]string)
		for k, v := range props {
			obj.Properties[k] = v.(string)
		}
	}

	// Parse polygon
	if polygon, ok := data["polygon"].([]interface{}); ok {
		obj.Polygon = make([]utils.Vector2, len(polygon))
		for i, p := range polygon {
			point := p.(map[string]interface{})
			obj.Polygon[i] = utils.NewVector2(
				point["x"].(float64),
				point["y"].(float64),
			)
		}
	}

	return obj
}

func (m *TileMap) parseTileset(data map[string]interface{}) Tileset {
	return Tileset{
		FirstGID:    int(data["firstgid"].(float64)),
		Image:       data["image"].(string),
		ImageWidth:  int(data["imagewidth"].(float64)),
		ImageHeight: int(data["imageheight"].(float64)),
		Name:        data["name"].(string),
		TileWidth:   int(data["tilewidth"].(float64)),
		TileHeight:  int(data["tileheight"].(float64)),
	}
}

func (m *TileMap) LoadCollisionAndEnvironment(physicsEngine *physics.PhysicsEngine, gameEngine *GameEngine) {
	for _, layer := range m.Layers {
		if layer.Type != "objectgroup" {
			continue
		}

		switch layer.Name {
		case "collision":
			m.loadCollisionLayer(layer, physicsEngine)
		case "environment":
			m.loadEnvironmentLayer(layer, gameEngine)
		}
	}
}

func (m *TileMap) loadCollisionLayer(layer Layer, physicsEngine *physics.PhysicsEngine) {
	for _, obj := range layer.Objects {
		collisionType := "mapobject"
		collidesWith := []string{"all"}
		
		// Check collision properties
		if flags, ok := obj.Properties["collisionFlags"]; ok {
			// Parse flags
			_ = flags
		}

		bodyDef := &physics.BodyDef{
			ID:       obj.Name,
			Position: utils.NewVector2(obj.X+obj.Width/2, obj.Y+obj.Height/2),
			HalfSize: utils.NewVector2(obj.Width/2, obj.Height/2),
			Type:     "static",
			UserData: map[string]interface{}{"id": obj.Name},
		}

		if len(obj.Polygon) > 0 {
			bodyDef.PolyPoints = obj.Polygon
		}

		physicsEngine.AddBody(bodyDef)
	}
}

func (m *TileMap) loadEnvironmentLayer(layer Layer, gameEngine *GameEngine) {
	for _, obj := range layer.Objects {
		switch obj.Type {
		case "teleporter":
			m.createTeleporter(obj, gameEngine)
		case "spawnpoint":
			m.createSpawnPoint(obj, gameEngine)
		case "spawner":
			m.createSpawner(obj, gameEngine)
		}
	}
}

func (m *TileMap) createTeleporter(obj Object, gameEngine *GameEngine) {
	destStr := obj.Properties["destination"]
	var destPos utils.Vector2
	// Parse destination from "x,y" format
	// ...

	teleporter := NewTeleporter(
		obj.Name,
		utils.NewVector2(obj.X, obj.Y),
		utils.NewVector2(obj.Width, obj.Height),
		destPos,
	)
	gameEngine.SpawnEntity(teleporter)
}

func (m *TileMap) createSpawnPoint(obj Object, gameEngine *GameEngine) {
	team := 0
	if teamStr, ok := obj.Properties["team"]; ok {
		// Parse team
		_ = teamStr
	}

	spawnPoint := NewSpawnPoint(
		obj.Name,
		utils.NewVector2(obj.X+obj.Width/2, obj.Y+obj.Height/2),
		utils.NewVector2(obj.Width, obj.Height),
		team,
	)
	gameEngine.SpawnEntity(spawnPoint)
}

func (m *TileMap) createSpawner(obj Object, gameEngine *GameEngine) {
	spawnItem := obj.Properties["SpawnItem"]
	
	spawner := NewSpawner(
		obj.Name,
		utils.NewVector2(obj.X+obj.Width/2, obj.Y+obj.Height/2),
		utils.NewVector2(obj.Width, obj.Height),
		spawnItem,
	)
	gameEngine.SpawnEntity(spawner)
}

func (m *TileMap) GetTilePacket(tileIndex int) TilePacket {
	// Find which tileset contains this tile
	for i := len(m.Tilesets) - 1; i >= 0; i-- {
		if m.Tilesets[i].FirstGID <= tileIndex {
			ts := m.Tilesets[i]
			localIdx := tileIndex - ts.FirstGID
			tileX := localIdx % (ts.ImageWidth / m.TileWidth)
			tileY := localIdx / (ts.ImageWidth / m.TileWidth)
			
			return TilePacket{
				ImagePath: ts.Image,
				SrcX:      tileX * m.TileWidth,
				SrcY:      tileY * m.TileHeight,
			}
		}
	}
	return TilePacket{}
}

type TilePacket struct {
	ImagePath string
	SrcX      int
	SrcY      int
}