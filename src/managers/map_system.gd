class_name MapSystem
extends Node

signal map_loaded()
signal map_cleared()

# Current map data
var current_map: MapData = null
var grid_size: Vector2i = Vector2i(26, 26)
var tile_size: int = 16

# References
var wall_system: WallSystem = null
var walls_container: Node2D = null

# Spawn markers
var player_spawn: Marker2D = null
var enemy_spawns: Array[Marker2D] = []
var base_marker: Marker2D = null

func _ready():
	# Get WallSystem reference from parent
	wall_system = get_parent().get_node_or_null("WallSystem")
	if wall_system == null:
		# Try to find it in the scene
		wall_system = get_tree().current_scene.get_node_or_null("WallSystem")
	
	print("🗺️ MapSystem initialized")

func load_map(map_data: MapData) -> void:
	current_map = map_data
	grid_size = map_data.grid_size
	tile_size = map_data.tile_size
	
	print("🗺️ MapSystem: Loading map '", map_data.level_name, "'")
	
	# Clear existing map
	clear_map()
	
	# Generate new map
	generate_map()
	
	map_loaded.emit()

func generate_map() -> void:
	if current_map == null:
		push_error("MapSystem: Cannot generate map - no map data loaded")
		return
	
	print("🗺️ MapSystem: Generating map...")
	
	# Generate walls
	_generate_walls()
	
	# Place spawn markers
	_place_markers()
	
	print("🗺️ MapSystem: Map generation complete")

func clear_map() -> void:
	if wall_system:
		wall_system.clear_all_walls()
	
	# Clear spawn markers
	for marker in enemy_spawns:
		if is_instance_valid(marker):
			marker.queue_free()
	enemy_spawns.clear()
	
	if player_spawn and is_instance_valid(player_spawn):
		player_spawn.queue_free()		player_spawn = null
	
	if base_marker and is_instance_valid(base_marker):
		base_marker.queue_free()
		base_marker = null
	
	map_cleared.emit()

func _generate_walls() -> void:
	if wall_system == null:
		push_error("MapSystem: WallSystem reference is null")
		return
	
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var wall_type = current_map.wall_layout[y][x]
			match wall_type:
				1: wall_system.create_wall(Vector2i(x, y), WallSystem.WallType.BRICK)
				2: wall_system.create_wall(Vector2i(x, y), WallSystem.WallType.STEEL)

func _place_markers() -> void:
	# Create player spawn marker
	player_spawn = Marker2D.new()
	player_spawn.name = "PlayerSpawn"
	player_spawn.position = grid_to_world(current_map.player_spawn_pos)
	add_child(player_spawn)
	
	# Create enemy spawn markers
	for i in range(current_map.enemy_spawn_positions.size()):
		var spawn_pos = current_map.enemy_spawn_positions[i]
		var marker = Marker2D.new()
		marker.name = "EnemySpawn_" + str(i)
		marker.position = grid_to_world(spawn_pos)
		add_child(marker)
		enemy_spawns.append(marker)
	
	# Create base marker
	base_marker = Marker2D.new()
	base_marker.name = "BasePosition"
	base_marker.position = grid_to_world(current_map.base_position)
	add_child(base_marker)
	
	print("🗺️ MapSystem: Placed ", enemy_spawns.size(), " enemy spawn points")

func world_to_grid(world_pos: Vector2) -> Vector2i:
	# Account for walls_container offset (32, 32)
	var offset = Vector2(32, 32)
	var adjusted_pos = world_pos - offset
	return Vector2i(int(adjusted_pos.x / tile_size), int(adjusted_pos.y / tile_size))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	# Account for walls_container offset (32, 32)
	var offset = Vector2(32, 32)
	return Vector2(grid_pos.x * tile_size + offset.x + tile_size / 2.0, 
				   grid_pos.y * tile_size + offset.y + tile_size / 2.0)

func get_player_spawn() -> Vector2:
	if player_spawn:
		return player_spawn.global_position
	return grid_to_world(current_map.player_spawn_pos if current_map else Vector2i(10, 24))

func get_enemy_spawns() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for marker in enemy_spawns:
		if is_instance_valid(marker):
			positions.append(marker.global_position)
	return positions

func get_base_position() -> Vector2:
	if base_marker:
		return base_marker.global_position
	return grid_to_world(current_map.base_position if current_map else Vector2i(12, 24))

func get_wall_at(grid_pos: Vector2i) -> int:
	if current_map:
		return current_map.get_wall_at(grid_pos)
	return 0

func is_valid_position(grid_pos: Vector2i) -> bool:
	if current_map:
		return current_map.is_valid_position(grid_pos)
	return grid_pos.x >= 0 and grid_pos.x < grid_size.x and grid_pos.y >= 0 and grid_pos.y < grid_size.y
