class_name MapGenerator
extends RefCounted

const GRID_WIDTH: int = 26
const GRID_HEIGHT: int = 26
const TILE_SIZE: int = 16

# Generate Level 1 - Basic Training (对称布局, 20敌人)
static func generate_level_1() -> MapData:
	var map_data = MapData.new()
	map_data.level_name = "Level 1 - Basic Training"
	map_data.grid_size = Vector2i(GRID_WIDTH, GRID_HEIGHT)
	map_data.tile_size = TILE_SIZE
	map_data.enemy_count = 20
	map_data.enemy_speed_multiplier = 1.0
	
	# Initialize empty layout
	_initialize_layout(map_data)
	
	# Border steel walls (except enemy spawn area at top)
	_create_border(map_data, true)
	
	# Simple symmetric brick obstacles
	_create_symmetric_bricks_level1(map_data)
	
	# Base protection (steel walls)
	_create_base_protection(map_data, true)
	
	# Set spawn positions
	map_data.player_spawn_pos = Vector2i(10, 24)
	map_data.enemy_spawn_positions = [Vector2i(6, 1), Vector2i(13, 1), Vector2i(20, 1)]
	map_data.base_position = Vector2i(12, 24)
	
	print("🗺️ Generated Level 1 - Basic Training")
	return map_data

# Generate Level 2 - Maze Challenge (迷宫布局, 25敌人)
static func generate_level_2() -> MapData:
	var map_data = MapData.new()
	map_data.level_name = "Level 2 - Maze Challenge"
	map_data.grid_size = Vector2i(GRID_WIDTH, GRID_HEIGHT)
	map_data.tile_size = TILE_SIZE
	map_data.enemy_count = 25
	map_data.enemy_speed_multiplier = 1.1
	
	_initialize_layout(map_data)
	_create_border(map_data, true)
	_create_maze_layout(map_data)
	_create_base_protection(map_data, true)
	
	map_data.player_spawn_pos = Vector2i(10, 24)
	map_data.enemy_spawn_positions = [Vector2i(6, 1), Vector2i(13, 1), Vector2i(20, 1)]
	map_data.base_position = Vector2i(12, 24)
	
	print("🗺️ Generated Level 2 - Maze Challenge")
	return map_data

# Generate Level 3 - Fortress Defense (多层保护, 30敌人)
static func generate_level_3() -> MapData:
	var map_data = MapData.new()
	map_data.level_name = "Level 3 - Fortress Defense"
	map_data.grid_size = Vector2i(GRID_WIDTH, GRID_HEIGHT)
	map_data.tile_size = TILE_SIZE
	map_data.enemy_count = 30
	map_data.enemy_speed_multiplier = 1.2
	
	_initialize_layout(map_data)
	_create_border(map_data, true)
	_create_fortress_layout(map_data)
	_create_base_protection(map_data, true)
	_create_base_brick_walls(map_data)  # Extra brick protection
	
	map_data.player_spawn_pos = Vector2i(10, 24)
	map_data.enemy_spawn_positions = [Vector2i(6, 1), Vector2i(13, 1), Vector2i(20, 1)]
	map_data.base_position = Vector2i(12, 24)
	
	print("🗺️ Generated Level 3 - Fortress Defense")
	return map_data

# Generate Level 4 - Ultimate Challenge (混合布局, 35敌人)
static func generate_level_4() -> MapData:
	var map_data = MapData.new()
	map_data.level_name = "Level 4 - Ultimate Challenge"
	map_data.grid_size = Vector2i(GRID_WIDTH, GRID_HEIGHT)
	map_data.tile_size = TILE_SIZE
	map_data.enemy_count = 35
	map_data.enemy_speed_multiplier = 1.3
	
	_initialize_layout(map_data)
	_create_border(map_data, true)
	_create_ultimate_layout(map_data)
	_create_base_protection(map_data, true)
	_create_base_brick_walls(map_data)
	
	map_data.player_spawn_pos = Vector2i(10, 24)
	map_data.enemy_spawn_positions = [Vector2i(6, 1), Vector2i(13, 1), Vector2i(20, 1)]
	map_data.base_position = Vector2i(12, 24)
	
	print("🗺️ Generated Level 4 - Ultimate Challenge")
	return map_data

# Helper functions
static func _initialize_layout(map_data: MapData):
	map_data.wall_layout = []
	for y in range(map_data.grid_size.y):
		var row = []
		for x in range(map_data.grid_size.x):
			row.append(0)
		map_data.wall_layout.append(row)

static func _create_border(map_data: MapData, is_steel: bool = true):
	var wall_type = 2 if is_steel else 1
	for x in range(map_data.grid_size.x):
		for y in range(map_data.grid_size.y):
			# Outer border
			if x == 0 or x == map_data.grid_size.x - 1 or y == 0 or y == map_data.grid_size.y - 1:
				# Leave space for enemy spawn at top
				if y == 0 and (x < 6 or x > map_data.grid_size.x - 7 or (x > 10 and x < 15)):
					continue
				map_data.wall_layout[y][x] = wall_type

static func _create_base_protection(map_data: MapData, is_steel: bool = true):
	var wall_type = 2 if is_steel else 1
	var base_pos = map_data.base_position
	var offsets = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]
	
	for offset in offsets:
		var pos = base_pos + offset
		if map_data.is_valid_position(pos):
			map_data.wall_layout[pos.y][pos.x] = wall_type

static func _create_base_brick_walls(map_data: MapData):
	# Additional brick layer around base
	var base_pos = map_data.base_position
	var brick_offsets = [
		Vector2i(-2, -2), Vector2i(-1, -2), Vector2i(0, -2), Vector2i(1, -2), Vector2i(2, -2),
		Vector2i(-2, -1), Vector2i(2, -1),
		Vector2i(-2, 0), Vector2i(2, 0),
		Vector2i(-2, 1), Vector2i(2, 1),
		Vector2i(-2, 2), Vector2i(-1, 2), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
	]
	
	for offset in brick_offsets:
		var pos = base_pos + offset
		if map_data.is_valid_position(pos) and map_data.wall_layout[pos.y][pos.x] == 0:
			map_data.wall_layout[pos.y][pos.x] = 1  # Brick

# Level 1: Simple symmetric layout
static func _create_symmetric_bricks_level1(map_data: MapData):
	var brick_positions = [
		# Left side cover
		Vector2i(3, 5), Vector2i(4, 5), Vector2i(3, 6), Vector2i(4, 6),
		Vector2i(3, 10), Vector2i(4, 10), Vector2i(3, 11), Vector2i(4, 11),
		
		# Right side cover (symmetric)
		Vector2i(22, 5), Vector2i(21, 5), Vector2i(22, 6), Vector2i(21, 6),
		Vector2i(22, 10), Vector2i(21, 10), Vector2i(22, 11), Vector2i(21, 11),
		
		# Middle obstacles
		Vector2i(8, 8), Vector2i(9, 8), Vector2i(10, 8),
		Vector2i(16, 8), Vector2i(17, 8), Vector2i(18, 8),
		
		Vector2i(8, 15), Vector2i(9, 15), Vector2i(10, 15),
		Vector2i(16, 15), Vector2i(17, 15), Vector2i(18, 15),
		
		# Near base
		Vector2i(10, 20), Vector2i(11, 20),
		Vector2i(14, 20), Vector2i(15, 20),
	]
	
	for pos in brick_positions:
		if map_data.is_valid_position(pos):
			map_data.wall_layout[pos.y][pos.x] = 1

# Level 2: Maze layout
static func _create_maze_layout(map_data: MapData):
	# Horizontal corridors
	for x in range(3, 23):
		if x % 4 != 0:  # Leave gaps
			map_data.wall_layout[5][x] = 1
			map_data.wall_layout[10][x] = 1
			map_data.wall_layout[15][x] = 1
			map_data.wall_layout[20][x] = 1
	
	# Vertical corridors
	for y in range(3, 23):
		if y % 5 != 0:
			map_data.wall_layout[y][5] = 2  # Steel
			map_data.wall_layout[y][10] = 1  # Brick
			map_data.wall_layout[y][15] = 1  # Brick
			map_data.wall_layout[y][20] = 2  # Steel
	
	# Some open areas
	for x in range(11, 15):
		for y in range(11, 15):
			map_data.wall_layout[y][x] = 0

# Level 3: Fortress layout with heavy protection
static func _create_fortress_layout(map_data: MapData):
	# Create defensive lines
	for x in range(2, 24):
		# Multiple defensive rows
		if x < 10 or x > 14:
			map_data.wall_layout[8][x] = 1
			map_data.wall_layout[12][x] = 1
			map_data.wall_layout[16][x] = 1
	
	# Vertical barriers
	for y in range(3, 22):
		map_data.wall_layout[y][6] = 2  # Steel barriers
		map_data.wall_layout[y][19] = 2
		
		if y % 3 == 0:
			map_data.wall_layout[y][3] = 1
			map_data.wall_layout[y][22] = 1
	
	# Fortress around base
	for x in range(9, 16):
		map_data.wall_layout[18][x] = 2
	for y in range(18, 23):
		map_data.wall_layout[y][9] = 2
		map_data.wall_layout[y][15] = 2

# Level 4: Ultimate challenge - mixed layout
static func _create_ultimate_layout(map_data: MapData):
	# Steel maze sections
	for i in range(4):
		var start_x = 4 + i * 5
		for y in range(4, 20):
			if y % 3 != 0:
				map_data.wall_layout[y][start_x] = 2
	
	# Brick clusters
	var brick_clusters = [
		[Vector2i(6, 6), Vector2i(7, 6), Vector2i(6, 7), Vector2i(7, 7)],
		[Vector2i(18, 6), Vector2i(19, 6), Vector2i(18, 7), Vector2i(19, 7)],
		[Vector2i(6, 14), Vector2i(7, 14), Vector2i(6, 15), Vector2i(7, 15)],
		[Vector2i(18, 14), Vector2i(19, 14), Vector2i(18, 15), Vector2i(19, 15)],
	]
	
	for cluster in brick_clusters:
		for pos in cluster:
			if map_data.is_valid_position(pos):
				map_data.wall_layout[pos.y][pos.x] = 1
	
	# Central open area with obstacles
	for x in range(10, 16):
		for y in range(10, 14):
			if (x + y) % 2 == 0:
				map_data.wall_layout[y][x] = 1
	
	# Choke points
	map_data.wall_layout[10][8] = 2
	map_data.wall_layout[10][17] = 2
	map_data.wall_layout[14][8] = 2
	map_data.wall_layout[14][17] = 2

# Get level by number
static func generate_level(level_num: int) -> MapData:
	match level_num:
		1: return generate_level_1()
		2: return generate_level_2()
		3: return generate_level_3()
		4: return generate_level_4()
		_: return generate_level_1()
