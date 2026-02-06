extends Node2D

# Game configuration
const TILE_SIZE: int = 16
const MAP_WIDTH: int = 26  # 416px / 16
const MAP_HEIGHT: int = 26  # 416px / 16

# Node references
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var enemy_spawns: Node2D = $EnemySpawns
@onready var base_position: Marker2D = $BasePosition
@onready var bullets_container: Node2D = $Bullets
@onready var walls: Node2D = $Walls

# Systems
var spawn_manager: SpawnManager = null
var wall_system: WallSystem = null
var demo_manager = null

# DemoManager class reference (loaded dynamically)
var DemoManagerClass = preload("res://src/managers/demo_manager.gd")

# Player reference
var player: PlayerTank = null
var base: Base = null

func _ready():
	print("🎮 Game scene ready")
	
	# Initialize systems
	_setup_systems()
	
	# Setup level
	_setup_level()
	
	# Connect to game manager
	GameManager.state_changed.connect(_on_game_state_changed)
	
	# Check if we're already in PLAYING state (e.g., from demo mode)
	if GameManager.current_state == GameManager.GameState.PLAYING:
		start_game()

func _setup_systems():
	# Create spawn manager
	spawn_manager = SpawnManager.new()
	add_child(spawn_manager)
	
	# Get enemy spawn markers
	var spawn_markers: Array[Marker2D] = []
	for child in enemy_spawns.get_children():
		if child is Marker2D:
			spawn_markers.append(child)
	
	spawn_manager.setup(spawn_markers)
	
	# Create wall system (new sprite-based system)
	wall_system = WallSystem.new()
	wall_system.walls_container = walls  # Use the existing Walls node from scene
	add_child(wall_system)
	
	# Create demo manager (if in demo mode)
	if GameManager.is_demo_mode:
		_demo_mode_setup()

func _setup_level():
	# Create base
	_spawn_base()
	
	# Create player
	_spawn_player()
	
	# Setup walls
	_setup_walls()

func _spawn_base():
	var base_scene = preload("res://src/entities/base.tscn")
	base = base_scene.instantiate()
	base.global_position = base_position.global_position
	base.base_destroyed.connect(_on_base_destroyed)
	add_child(base)

func _spawn_player():
	var player_scene = preload("res://src/entities/player_tank.tscn")
	player = player_scene.instantiate()
	player.global_position = player_spawn.global_position
	player.player_died.connect(_on_player_died)
	add_child(player)
	
	# Register with game manager
	GameManager.player_tank = player

func _setup_walls():
	# Build a simple level layout
	# Border walls
	_create_border_walls()
	
	# Some inner walls for cover
	_create_inner_walls()
	
	# Protect base with steel walls
	_create_base_protection()

func _create_border_walls():
	# Steel walls on border (except spawn areas)
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			# Outer border
			if x == 0 or x == MAP_WIDTH - 1 or y == 0 or y == MAP_HEIGHT - 1:
				# Leave space for enemy spawn at top
				if y == 0 and (x < 6 or x > MAP_WIDTH - 7 or (x > 10 and x < 15)):
					continue
				wall_system.create_wall(Vector2i(x, y), WallSystem.WallType.STEEL)

func _create_inner_walls():
	# Add some brick walls for cover
	var brick_positions = [
		# Left side cover
		Vector2i(3, 5), Vector2i(4, 5), Vector2i(3, 6), Vector2i(4, 6),
		Vector2i(3, 10), Vector2i(4, 10), Vector2i(3, 11), Vector2i(4, 11),
		
		# Right side cover
		Vector2i(MAP_WIDTH - 4, 5), Vector2i(MAP_WIDTH - 5, 5),
		Vector2i(MAP_WIDTH - 4, 6), Vector2i(MAP_WIDTH - 5, 6),
		Vector2i(MAP_WIDTH - 4, 10), Vector2i(MAP_WIDTH - 5, 10),
		Vector2i(MAP_WIDTH - 4, 11), Vector2i(MAP_WIDTH - 5, 11),
		
		# Middle obstacles
		Vector2i(8, 8), Vector2i(9, 8), Vector2i(10, 8),
		Vector2i(MAP_WIDTH - 9, 8), Vector2i(MAP_WIDTH - 10, 8), Vector2i(MAP_WIDTH - 11, 8),
		
		Vector2i(8, 15), Vector2i(9, 15), Vector2i(10, 15),
		Vector2i(MAP_WIDTH - 9, 15), Vector2i(MAP_WIDTH - 10, 15), Vector2i(MAP_WIDTH - 11, 15),
		
		# Near base
		Vector2i(10, 20), Vector2i(11, 20),
		Vector2i(MAP_WIDTH - 11, 20), Vector2i(MAP_WIDTH - 12, 20),
	]
	
	for pos in brick_positions:
		wall_system.create_wall(pos, WallSystem.WallType.BRICK)

func _create_base_protection():
	# Steel walls around base
	var base_tile = Vector2i(int(base_position.position.x / 16), int(base_position.position.y / 16))
	var protection_offsets = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]
	
	for offset in protection_offsets:
		var pos = base_tile + offset
		wall_system.create_wall(pos, WallSystem.WallType.STEEL)

func start_game():
	print("▶️ Starting game...")
	
	# Reset state
	_reset_game()
	
	# Start spawning enemies
	spawn_manager.start_spawning()

func _reset_game():
	# Reset player
	if player:
		player.global_position = player_spawn.global_position
		player.is_alive = true
		player.visible = true
		player.lives = GameManager.player_lives
	
	# Reset base
	if base:
		base.reset()
	
	# Clear bullets
	BulletPool.clear_all_bullets()
	
	# Clear any remaining enemies
	spawn_manager.clear_all_enemies()

func _on_player_died():
	print("💀 Player died!")
	
	# Respawn after delay if lives remain
	if GameManager.player_lives > 0:
		await get_tree().create_timer(2.0).timeout
		if player:
			player.respawn()
			player.global_position = player_spawn.global_position

func _on_base_destroyed():
	print("💥 Base destroyed!")
	# Game over is handled by Base class

func _demo_mode_setup():
	print("🎬 Setting up Demo Mode...")
	
	if DemoManagerClass:
		demo_manager = DemoManagerClass.new()
		add_child(demo_manager)
	
	# 延迟设置 player，因为此时 player 还未创建
	call_deferred("_setup_demo_manager")

func _setup_demo_manager():
	if demo_manager and player:
		demo_manager.setup(player, self)
		print("🤖 Demo Manager ready")

func _on_game_state_changed(new_state: GameManager.GameState):
	match new_state:
		GameManager.GameState.PLAYING:
			if spawn_manager.enemies_spawned == 0:
				start_game()
		GameManager.GameState.GAME_OVER:
			if GameManager.is_demo_mode:
				# Demo 模式下不显示游戏结束，直接返回主菜单
				await get_tree().create_timer(2.0).timeout
				GameManager.stop_demo()
			else:
				_show_game_over()
		GameManager.GameState.VICTORY:
			if GameManager.is_demo_mode:
				# Demo 模式下胜利也返回主菜单
				await get_tree().create_timer(2.0).timeout
				GameManager.stop_demo()
			else:
				_show_victory()
		GameManager.GameState.MENU:
			# Return to main menu
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _show_game_over():
	AudioManager.play_game_over()
	print("💀 GAME OVER")
	# Show game over UI (handled by HUD)

func _show_victory():
	AudioManager.play_victory()
	print("🏆 VICTORY!")
	# Show victory UI (handled by HUD)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if GameManager.current_state == GameManager.GameState.PLAYING:
			PauseManager.toggle_pause()
