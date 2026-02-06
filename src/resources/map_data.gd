class_name MapData
extends Resource

@export var level_name: String = "Level 1"
@export var grid_size: Vector2i = Vector2i(26, 26)
@export var tile_size: int = 16
@export var wall_layout: Array = []  # 0=empty, 1=brick, 2=steel
@export var player_spawn_pos: Vector2i = Vector2i(10, 24)
@export var enemy_spawn_positions: Array = []  # Array of Vector2i
@export var base_position: Vector2i = Vector2i(12, 24)
@export var enemy_count: int = 20
@export var enemy_speed_multiplier: float = 1.0

func _init():
	# Initialize enemy spawn positions with defaults if empty
	if enemy_spawn_positions.is_empty():
		enemy_spawn_positions = [
			Vector2i(6, 1),
			Vector2i(13, 1),
			Vector2i(20, 1)
		]
	# Initialize wall layout with empty grid if empty
	if wall_layout.is_empty():
		_initialize_empty_layout()

func _initialize_empty_layout():
	wall_layout = []
	for y in range(grid_size.y):
		var row = []
		for x in range(grid_size.x):
			row.append(0)
		wall_layout.append(row)

func get_wall_at(grid_pos: Vector2i) -> int:
	if not is_valid_position(grid_pos):
		return 0
	return wall_layout[grid_pos.y][grid_pos.x]

func set_wall_at(grid_pos: Vector2i, wall_type: int):
	if is_valid_position(grid_pos):
		wall_layout[grid_pos.y][grid_pos.x] = wall_type

func is_valid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_size.x and grid_pos.y >= 0 and grid_pos.y < grid_size.y
