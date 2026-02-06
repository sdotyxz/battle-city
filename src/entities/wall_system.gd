class_name WallSystem
extends Node

# Wall types
enum WallType { BRICK, STEEL }

# Scene references
@export var walls_container: Node2D = null

# Wall scenes (will be created programmatically)
var brick_wall_scene: PackedScene = null
var steel_wall_scene: PackedScene = null

# Wall tracking
var walls: Array[StaticBody2D] = []
var wall_grid: Dictionary = {}  # tile_pos -> wall_node

const TILE_SIZE: int = 16

func _ready():
	if walls_container == null:
		# Try to find existing Walls node in parent
		walls_container = get_parent().get_node_or_null("Walls")
		if walls_container == null:
			# Create container at origin
			walls_container = Node2D.new()
			walls_container.name = "WallsContainer"
			walls_container.position = Vector2(32, 32)  # Match the offset in game.tscn
			get_parent().add_child.call_deferred(walls_container)
		else:
			print("🧱 Using existing Walls container at: ", walls_container.position)
	
	# Create wall scenes
	_create_wall_scenes()
	
	print("🧱 WallSystem initialized")

func _create_wall_scenes():
	# Create brick wall scene - use StaticBody2D for physics collision
	var brick_root = StaticBody2D.new()
	brick_root.name = "BrickWall"
	brick_root.set_collision_layer_value(5, true)  # Wall layer - blocks tanks
	brick_root.set_collision_mask_value(1, true)   # Detects bullets
	
	var brick_sprite = Sprite2D.new()
	brick_sprite.name = "Sprite"
	brick_sprite.scale = Vector2(1, 1)
	# Create brick texture - make it more visible
	var brick_img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	brick_img.fill(Color(0.8, 0.4, 0.2))  # Brighter brown/orange
	# Add brick pattern
	for i in range(4):
		for j in range(4):
			if (i + j) % 2 == 0:
				brick_img.fill_rect(Rect2i(i * 4, j * 4, 4, 4), Color(0.7, 0.35, 0.15))
	# Add border
	for i in range(16):
		brick_img.set_pixel(i, 0, Color(0.5, 0.25, 0.1))
		brick_img.set_pixel(i, 15, Color(0.5, 0.25, 0.1))
		brick_img.set_pixel(0, i, Color(0.5, 0.25, 0.1))
		brick_img.set_pixel(15, i, Color(0.5, 0.25, 0.1))
	brick_sprite.texture = ImageTexture.create_from_image(brick_img)
	brick_root.add_child(brick_sprite)
	brick_sprite.owner = brick_root
	
	var brick_collision = CollisionShape2D.new()
	brick_collision.name = "Collision"
	var brick_shape = RectangleShape2D.new()
	brick_shape.size = Vector2(16, 16)
	brick_collision.shape = brick_shape
	brick_root.add_child(brick_collision)
	brick_collision.owner = brick_root
	
	# Add metadata
	brick_root.set_meta("wall_type", "brick")
	brick_root.set_meta("destructible", true)
	brick_root.set_meta("steel", false)
	
	# Pack scene
	brick_wall_scene = PackedScene.new()
	brick_wall_scene.pack(brick_root)
	
	# Create steel wall scene - use StaticBody2D for physics collision
	var steel_root = StaticBody2D.new()
	steel_root.name = "SteelWall"
	steel_root.set_collision_layer_value(5, true)  # Wall layer - blocks tanks
	steel_root.set_collision_mask_value(1, true)   # Detects bullets
	
	var steel_sprite = Sprite2D.new()
	steel_sprite.name = "Sprite"
	steel_sprite.scale = Vector2(1, 1)
	# Create steel texture - brighter and more visible
	var steel_img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	steel_img.fill(Color(0.7, 0.7, 0.75))  # Brighter gray/blue-ish
	# Add steel pattern
	for i in range(2):
		for j in range(2):
			steel_img.fill_rect(Rect2i(i * 8, j * 8, 8, 8), Color(0.6, 0.6, 0.65))
	# Add border for visibility
	for i in range(16):
		steel_img.set_pixel(i, 0, Color(0.4, 0.4, 0.45))
		steel_img.set_pixel(i, 15, Color(0.4, 0.4, 0.45))
		steel_img.set_pixel(0, i, Color(0.4, 0.4, 0.45))
		steel_img.set_pixel(15, i, Color(0.4, 0.4, 0.45))
	steel_sprite.texture = ImageTexture.create_from_image(steel_img)
	steel_root.add_child(steel_sprite)
	steel_sprite.owner = steel_root
	
	var steel_collision = CollisionShape2D.new()
	steel_collision.name = "Collision"
	var steel_shape = RectangleShape2D.new()
	steel_shape.size = Vector2(16, 16)
	steel_collision.shape = steel_shape
	steel_root.add_child(steel_collision)
	steel_collision.owner = steel_root
	
	# Add metadata
	steel_root.set_meta("wall_type", "steel")
	steel_root.set_meta("destructible", false)
	steel_root.set_meta("steel", true)
	
	# Pack scene
	steel_wall_scene = PackedScene.new()
	steel_wall_scene.pack(steel_root)

func create_wall(grid_pos: Vector2i, wall_type: WallType) -> StaticBody2D:
	var wall: StaticBody2D = null
	var type_name = ""
	
	match wall_type:
		WallType.BRICK:
			wall = brick_wall_scene.instantiate()
			type_name = "brick"
		WallType.STEEL:
			wall = steel_wall_scene.instantiate()
			type_name = "steel"
	
	if wall:
		wall.global_position = Vector2(grid_pos.x * TILE_SIZE + 8, grid_pos.y * TILE_SIZE + 8)
		walls_container.add_child(wall)
		walls.append(wall)
		wall_grid[grid_pos] = wall
		
		print("🧱 Created ", type_name, " wall at ", grid_pos)
	
	return wall

func destroy_wall(wall: StaticBody2D):
	# Find grid position
	var grid_pos = _world_to_grid(wall.global_position)
	wall_grid.erase(grid_pos)
	walls.erase(wall)
	
	# Spawn debris effect
	_spawn_debris(wall.global_position)
	
	# Remove wall
	wall.queue_free()

func destroy_wall_at(pos: Vector2):
	var grid_pos = _world_to_grid(pos)
	if wall_grid.has(grid_pos):
		destroy_wall(wall_grid[grid_pos])

func _world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))

func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0, grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0)

func is_wall_at(pos: Vector2) -> bool:
	var grid_pos = _world_to_grid(pos)
	return wall_grid.has(grid_pos)

func is_destructible_at(pos: Vector2) -> bool:
	var grid_pos = _world_to_grid(pos)
	if wall_grid.has(grid_pos):
		var wall = wall_grid[grid_pos]
		return wall.get_meta("destructible", false)
	return false

func is_steel_at(pos: Vector2) -> bool:
	var grid_pos = _world_to_grid(pos)
	if wall_grid.has(grid_pos):
		var wall = wall_grid[grid_pos]
		return wall.get_meta("steel", false)
	return false

func _spawn_debris(pos: Vector2):
	var debris = CPUParticles2D.new()
	debris.global_position = pos
	debris.amount = 8
	debris.lifetime = 0.5
	debris.explosiveness = 1.0
	debris.direction = Vector2.UP
	debris.spread = 180.0
	debris.gravity = Vector2(0, 200)
	debris.initial_velocity_min = 50
	debris.initial_velocity_max = 100
	debris.scale_amount_min = 2
	debris.scale_amount_max = 4
	debris.color = Color(0.6, 0.3, 0.1)
	
	get_parent().add_child(debris)
	debris.emitting = true
	
	await get_tree().create_timer(1.0).timeout
	debris.queue_free()

func clear_all_walls():
	for wall in walls:
		if is_instance_valid(wall):
			wall.queue_free()
	walls.clear()
	wall_grid.clear()

func load_level_layout(layout_data: Dictionary):
	# Clear existing
	clear_all_walls()
	
	# Load bricks
	if layout_data.has("bricks"):
		for pos in layout_data.bricks:
			create_wall(pos, WallType.BRICK)
	
	# Load steel
	if layout_data.has("steel"):
		for pos in layout_data.steel:
			create_wall(pos, WallType.STEEL)
