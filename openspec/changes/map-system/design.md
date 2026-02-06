# Map System - Design Document

## Architecture

### Core Components

```
MapSystem (Node)
├── map_data: MapData (Resource)
├── current_level: int
├── walls_container: Node2D
├── enemy_spawns: Array[Marker2D]
├── player_spawn: Marker2D
└── base_position: Marker2D
```

### Data Flow

```
1. GameManager requests level load
2. MapSystem reads MapData configuration
3. MapSystem generates wall layout
4. MapSystem places entity marker points
5. Game starts, enemy spawner uses markers
```

## Data Structures

### MapData (Resource)

```gdscript
class_name MapData
extends Resource

@export var level_name: String = "Level 1"
@export var grid_size: Vector2i = Vector2i(26, 26)
@export var tile_size: int = 16

# Wall layout (0=empty, 1=brick, 2=steel)
@export var wall_layout: Array[Array] = []

# Spawn points (grid coordinates relative to top-left)
@export var player_spawn_pos: Vector2i = Vector2i(10, 24)
@export var enemy_spawn_positions: Array[Vector2i] = []
@export var base_position: Vector2i = Vector2i(12, 24)

# Level configuration
@export var enemy_count: int = 20
@export var enemy_speed_multiplier: float = 1.0
```

## API Design

### MapSystem

```gdscript
class_name MapSystem
extends Node

signal map_loaded()
signal map_cleared()

func load_map(map_data: MapData) -> void
func generate_map() -> void
func clear_map() -> void
func world_to_grid(world_pos: Vector2) -> Vector2i
func grid_to_world(grid_pos: Vector2i) -> Vector2
func get_player_spawn() -> Vector2
func get_enemy_spawns() -> Array[Vector2]
func get_base_position() -> Vector2
func get_wall_at(grid_pos: Vector2i) -> int
func is_valid_position(grid_pos: Vector2i) -> bool
```

### MapGenerator

```gdscript
class_name MapGenerator

static func generate_level_1() -> MapData
static func generate_level_2() -> MapData
static func generate_level_3() -> MapData
static func generate_level_4() -> MapData
```

## Level Designs

### Level 1 - Basic Training
- Simple symmetrical layout
- Few brick obstacles
- 20 enemies
- No special enemy types

### Level 2 - Maze Challenge
- Complex maze-style layout
- More bricks and steel walls
- 25 enemies
- Fast enemies introduced

### Level 3 - Fortress Defense
- Multi-layer base protection
- Many brick walls
- 30 enemies
- Heavy armor enemies introduced

### Level 4 - Ultimate Challenge
- Mixed layout
- Steel maze + open areas
- 35 enemies
- All enemy types

## Integration Points

### With GameManager
```gdscript
var map_system: MapSystem
var current_level: int = 1
var max_levels: int = 4

func start_level(level: int) -> void:
    current_level = level
    var map_data = MapGenerator.generate_level_1()
    map_system.load_map(map_data)
    change_scene("res://scenes/game.tscn")
```

### With WallSystem
```gdscript
func generate_map() -> void:
    wall_system.clear_all_walls()
    for y in range(grid_size.y):
        for x in range(grid_size.x):
            var wall_type = current_map.wall_layout[y][x]
            match wall_type:
                1: wall_system.create_wall(Vector2i(x, y), WallSystem.WallType.BRICK)
                2: wall_system.create_wall(Vector2i(x, y), WallSystem.WallType.STEEL)
```

### With SpawnManager
```gdscript
func setup_from_map(map_system: MapSystem) -> void:
    enemy_spawn_points = map_system.get_enemy_spawns()
    player_spawn_point = map_system.get_player_spawn()
```

## File Structure

```
src/
├── managers/
│   └── map_system.gd          # Main map system class
├── resources/
│   └── map_data.gd            # Map data resource class
├── generators/
│   └── map_generator.gd       # Procedural map generator
└── game.gd                    # Modified: integrate MapSystem

assets/
└── maps/
    ├── level_01.tres          # Level 1 config
    ├── level_02.tres          # Level 2 config
    ├── level_03.tres          # Level 3 config
    └── level_04.tres          # Level 4 config
```

## Performance Considerations

1. **Object Pooling**: Reuse wall objects to avoid frequent create/destroy
2. **Lazy Loading**: Load level data on demand
3. **Spatial Partitioning**: Use quadtree or grid for collision optimization
4. **Serialization**: Use binary format for map data storage
