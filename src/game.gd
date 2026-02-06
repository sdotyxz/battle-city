extends Node2D

# Game configuration
const TILE_SIZE: int = 16
const MAP_WIDTH: int = 26  # 416px / 16
const MAP_HEIGHT: int = 26  # 416px / 16

# Node references
@onready var bullets_container: Node2D = $Bullets
@onready var walls: Node2D = $Walls

# Systems
var spawn_manager: SpawnManager = null
var wall_system: WallSystem = null
var map_system: MapSystem = null
var demo_manager = null

# DemoManager class reference (loaded dynamically)
var DemoManagerClass = preload("res://src/managers/demo_manager.gd")

# Player reference
var player: PlayerTank = null
var base: Base = null

# Cached spawn positions
var player_spawn_pos: Vector2 = Vector2.ZERO
var enemy_spawn_positions: Array[Vector2] = []
var base_pos: Vector2 = Vector2.ZERO

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
	# Create wall system (new sprite-based system)
	wall_system = WallSystem.new()
	wall_system.walls_container = walls  # Use the existing Walls node from scene
	add_child(wall_system)
	
	# Create map system
	map_system = MapSystem.new()
	add_child(map_system)
	
	# Set WallSystem reference manually
	map_system.wall_system = wall_system
	
	# Load level from GameManager
	var level = GameManager.current_level
	var map_data = MapGenerator.generate_level(level)
	map_system.load_map(map_data)
	
	# Get spawn positions from map system
	player_spawn_pos = map_system.get_player_spawn()
	enemy_spawn_positions = map_system.get_enemy_spawns()
	base_pos = map_system.get_base_position()
	
	# Update GameManager with enemy count
	GameManager.total_enemies = map_data.enemy_count
	
	# Create spawn manager
	spawn_manager = SpawnManager.new()
	add_child(spawn_manager)
	
	# Setup spawn manager with map spawn points
	spawn_manager.setup_from_map(map_system)
	
	# Create demo manager (if in demo mode)
	if GameManager.is_demo_mode:
		_demo_mode_setup()

func _setup_level():
	# Create base
	_spawn_base()
	
	# Create player
	_spawn_player()

func _spawn_base():
	var base_scene = preload("res://src/entities/base.tscn")
	base = base_scene.instantiate()
	base.global_position = base_pos
	base.base_destroyed.connect(_on_base_destroyed)
	add_child(base)
	
	# Update GameManager
	GameManager.base_position = base_pos

func _spawn_player():
	var player_scene = preload("res://src/entities/player_tank.tscn")
	player = player_scene.instantiate()
	player.global_position = player_spawn_pos
	player.player_died.connect(_on_player_died)
	add_child(player)
	
	# Register with game manager
	GameManager.player_tank = player

func start_game():
	print("▶️ Starting game...")
	
	# Reset state
	_reset_game()
	
	# Start spawning enemies
	spawn_manager.start_spawning()

func _reset_game():
	# Reset player
	if player:
		player.global_position = player_spawn_pos
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
			player.global_position = player_spawn_pos

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
