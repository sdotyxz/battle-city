# Map System - Implementation Tasks

## Phase 1: Core Architecture

### 1.1 Create MapData Resource Class
**File**: `src/resources/map_data.gd`
- [ ] Define MapData class extending Resource
- [ ] Add exported properties:
  - [ ] level_name: String
  - [ ] grid_size: Vector2i (default 26x26)
  - [ ] tile_size: int (default 16)
  - [ ] wall_layout: Array (2D array: 0=empty, 1=brick, 2=steel)
  - [ ] player_spawn_pos: Vector2i
  - [ ] enemy_spawn_positions: Array[Vector2i]
  - [ ] base_position: Vector2i
  - [ ] enemy_count: int
  - [ ] enemy_speed_multiplier: float

### 1.2 Create MapSystem Manager
**File**: `src/managers/map_system.gd`
- [ ] Define MapSystem class extending Node
- [ ] Add signals: map_loaded(), map_cleared()
- [ ] Add properties:
  - [ ] current_map: MapData
  - [ ] grid_size, tile_size
  - [ ] wall_system reference
  - [ ] player_spawn, enemy_spawns[], base_marker
- [ ] Implement methods:
  - [ ] _ready() - get WallSystem reference
  - [ ] load_map(map_data) - load configuration
  - [ ] generate_map() - create walls and markers
  - [ ] clear_map() - remove all walls
  - [ ] _generate_walls() - create wall entities
  - [ ] _place_markers() - position spawn points
  - [ ] world_to_grid(pos) - coordinate conversion
  - [ ] grid_to_world(pos) - coordinate conversion
  - [ ] get_player_spawn() - return Vector2
  - [ ] get_enemy_spawns() - return Array[Vector2]
  - [ ] get_base_position() - return Vector2
  - [ ] get_wall_at(pos) - return int
  - [ ] is_valid_position(pos) - return bool

### 1.3 Create MapGenerator
**File**: `src/generators/map_generator.gd`
- [ ] Define MapGenerator class extending RefCounted
- [ ] Implement generate_level_1():
  - [ ] Create MapData instance
  - [ ] Generate border steel walls
  - [ ] Add brick obstacles
  - [ ] Set player spawn at (10, 24)
  - [ ] Set enemy spawns at (6,1), (13,1), (20,1)
  - [ ] Set base at (12, 24) with steel protection
  - [ ] enemy_count = 20
- [ ] Implement generate_level_2() - maze layout
- [ ] Implement generate_level_3() - fortress layout
- [ ] Implement generate_level_4() - challenge layout

## Phase 2: System Integration

### 2.1 Modify Game Scene
**File**: `src/game.gd`
- [ ] Add map_system property
- [ ] In _setup_systems():
  - [ ] Create MapSystem instance
  - [ ] Add as child
  - [ ] Load level data: MapGenerator.generate_level_1()
  - [ ] Call map_system.load_map()
- [ ] In _spawn_player():
  - [ ] Use map_system.get_player_spawn() for position
- [ ] In _spawn_base():
  - [ ] Use map_system.get_base_position() for position
- [ ] Remove hard-coded wall generation code

### 2.2 Modify SpawnManager
**File**: `src/managers/spawn_manager.gd`
- [ ] Add setup_from_map(map_system) method
- [ ] Use map_system.get_enemy_spawns() for spawn points

### 2.3 Create Level Save Tool
**File**: `tools/save_levels.gd` (EditorScript)
- [ ] Generate all 4 levels
- [ ] Save to assets/maps/level_01.tres - level_04.tres

## Phase 3: Level Switching

### 3.1 Modify GameManager
**File**: `src/managers/game_manager.gd`
- [ ] Add map_system property
- [ ] Add current_level, max_levels properties
- [ ] Implement start_level(level) method
- [ ] Implement next_level() method
- [ ] Add level completion detection

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

- [ ] MapData resource class created
- [ ] MapSystem manager created with all methods
- [ ] MapGenerator creates 4 distinct levels
- [ ] Game scene integrated with MapSystem
- [ ] SpawnManager uses map spawn points
- [ ] Level switching implemented
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
