# Map System - Implementation Tasks

## Phase 1: Core Architecture

### 1.1 Create MapData Resource Class
**File**: `src/resources/map_data.gd`
- [x] Define MapData class extending Resource
- [x] Add exported properties:
  - [x] level_name: String
  - [x] grid_size: Vector2i (default 26x26)
  - [x] tile_size: int (default 16)
  - [x] wall_layout: Array (2D array: 0=empty, 1=brick, 2=steel)
  - [x] player_spawn_pos: Vector2i
  - [x] enemy_spawn_positions: Array[Vector2i]
  - [x] base_position: Vector2i
  - [x] enemy_count: int
  - [x] enemy_speed_multiplier: float

### 1.2 Create MapSystem Manager
**File**: `src/managers/map_system.gd`
- [x] Define MapSystem class extending Node
- [x] Add signals: map_loaded(), map_cleared()
- [x] Add properties:
  - [x] current_map: MapData
  - [x] grid_size, tile_size
  - [x] wall_system reference
  - [x] player_spawn, enemy_spawns[], base_marker
- [x] Implement methods:
  - [x] _ready() - get WallSystem reference
  - [x] load_map(map_data) - load configuration
  - [x] generate_map() - create walls and markers
  - [x] clear_map() - remove all walls
  - [x] _generate_walls() - create wall entities
  - [x] _place_markers() - position spawn points
  - [x] world_to_grid(pos) - coordinate conversion
  - [x] grid_to_world(pos) - coordinate conversion
  - [x] get_player_spawn() - return Vector2
  - [x] get_enemy_spawns() - return Array[Vector2]
  - [x] get_base_position() - return Vector2
  - [x] get_wall_at(pos) - return int
  - [x] is_valid_position(pos) - return bool

### 1.3 Create MapGenerator
**File**: `src/generators/map_generator.gd`
- [x] Define MapGenerator class extending RefCounted
- [x] Implement generate_level_1():
  - [x] Create MapData instance
  - [x] Generate border steel walls
  - [x] Add brick obstacles
  - [x] Set player spawn at (10, 24)
  - [x] Set enemy spawns at (6,1), (13,1), (20,1)
  - [x] Set base at (12, 24) with steel protection
  - [x] enemy_count = 20
- [x] Implement generate_level_2() - maze layout
- [x] Implement generate_level_3() - fortress layout
- [x] Implement generate_level_4() - challenge layout

## Phase 2: System Integration

### 2.1 Modify Game Scene
**File**: `src/game.gd`
- [x] Add map_system property
- [x] In _setup_systems():
  - [x] Create MapSystem instance
  - [x] Add as child
  - [x] Load level data: MapGenerator.generate_level_1()
  - [x] Call map_system.load_map()
- [x] In _spawn_player():
  - [x] Use map_system.get_player_spawn() for position
- [x] In _spawn_base():
  - [x] Use map_system.get_base_position() for position
- [x] Remove hard-coded wall generation code

### 2.2 Modify SpawnManager
**File**: `src/managers/spawn_manager.gd`
- [x] Add setup_from_map(map_system) method
- [x] Use map_system.get_enemy_spawns() for spawn points

### 2.3 Create Level Save Tool
**File**: `tools/save_levels.gd` (EditorScript)
- [ ] Generate all 4 levels
- [ ] Save to assets/maps/level_01.tres - level_04.tres

## Phase 3: Level Switching

### 3.1 Modify GameManager
**File**: `src/managers/game_manager.gd`
- [x] Add map_system property
- [x] Add current_level, max_levels properties
- [x] Implement start_level(level) method
- [x] Implement next_level() method
- [x] Add level completion detection

### 3.2 Add Level Transition
- [ ] Create level transition UI/effect
- [ ] Add delay between levels

## Phase 4: Testing

### 4.1 Unit Tests
**File**: `test/unit/test_map_system.gd`
- [ ] Test map loading
- [ ] Test wall generation
- [ ] Test coordinate conversion
- [ ] Test marker positions

### 4.2 Integration Tests
**File**: `test/integration/test_level_flow.gd`
- [ ] Test full level load
- [ ] Test level switching
- [ ] Test save/load

### 4.3 Validation
- [ ] Test all 4 levels display correctly
- [ ] Test player spawns at correct position
- [ ] Test enemies spawn correctly
- [ ] Test base has protection walls
- [ ] Test level switching works
- [ ] Verify 60 FPS performance

## Acceptance Criteria

- [x] MapData resource class created
- [x] MapSystem manager created with all methods
- [x] MapGenerator creates 4 distinct levels
- [x] Game scene integrated with MapSystem
- [x] SpawnManager uses map spawn points
- [x] Level switching implemented
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Performance maintained at 60 FPS

## API Reference

### MapData
| Property | Type | Default | Description |
|----------|------|---------|-------------|
| level_name | String | "Level 1" | Display name |
| grid_size | Vector2i | (26, 26) | Map dimensions in tiles |
| tile_size | int | 16 | Pixels per tile |
| wall_layout | Array | [] | 2D array: 0=empty, 1=brick, 2=steel |
| player_spawn_pos | Vector2i | (10, 24) | Player start position |
| enemy_spawn_positions | Array[Vector2i] | [(6,1), (13,1), (20,1)] | Enemy spawn points |
| base_position | Vector2i | (12, 24) | Base location |
| enemy_count | int | 20 | Total enemies in level |
| enemy_speed_multiplier | float | 1.0 | Speed adjustment |

### MapSystem
| Method | Returns | Description |
|--------|---------|-------------|
| load_map(map_data) | void | Load map configuration |
| generate_map() | void | Create wall entities and markers |
| clear_map() | void | Remove all walls |
| world_to_grid(pos) | Vector2i | World to grid coordinates |
| grid_to_world(pos) | Vector2 | Grid to world coordinates |
| get_player_spawn() | Vector2 | Get player spawn world position |
| get_enemy_spawns() | Array[Vector2] | Get enemy spawn world positions |
| get_base_position() | Vector2 | Get base world position |
| get_wall_at(pos) | int | Get wall type at grid position |
| is_valid_position(pos) | bool | Check if grid position is valid |

## Timeline

- **Day 1**: Phase 1 (Core Architecture)
- **Day 2**: Phase 2-3 (Integration and Level Switching)
- **Day 3**: Phase 4 (Testing and Optimization)
