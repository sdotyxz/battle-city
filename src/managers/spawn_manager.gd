class_name SpawnManager
extends Node2D

# Spawn configuration
var max_enemies_on_screen: int = 4
var total_enemies_to_spawn: int = 20
var enemies_spawned: int = 0
var current_enemies: Array[EnemyTank] = []

# Spawn points (Marker2D positions)
var spawn_points: Array[Marker2D] = []
var next_spawn_index: int = 0

# Timing
var spawn_cooldown: float = 2.0
var spawn_timer: Timer = null

# References
var enemy_scene: PackedScene = preload("res://src/entities/enemy_tank.tscn")

# Signals
signal enemy_spawned(enemy: EnemyTank)
signal wave_completed()
signal all_enemies_defeated()

func _ready():
	# Create spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_cooldown
	spawn_timer.timeout.connect(_on_spawn_timer)
	spawn_timer.add_to_group("pausable_timers")
	add_child(spawn_timer)
	
	# Connect to game manager
	GameManager.state_changed.connect(_on_game_state_changed)
	GameManager.enemy_destroyed.connect(_on_enemy_destroyed)

func setup(spawn_markers: Array[Marker2D]):
	# Store spawn point references
	spawn_points = spawn_markers
	print("📍 SpawnManager: Setup with ", spawn_points.size(), " spawn points")

func setup_from_map(map_system: MapSystem) -> void:
	# Get enemy spawn positions from map system
	var spawn_positions = map_system.get_enemy_spawns()
	
	# Create Marker2D nodes for each position
	spawn_points.clear()
	for i in range(spawn_positions.size()):
		var marker = Marker2D.new()
		marker.name = "EnemySpawn_" + str(i)
		marker.global_position = spawn_positions[i]
		spawn_points.append(marker)
	
	print("📍 SpawnManager: Setup from map with ", spawn_points.size(), " spawn points")

func start_spawning():
	# Get settings from game manager
	max_enemies_on_screen = GameManager.max_enemies_on_screen
	total_enemies_to_spawn = GameManager.total_enemies
	
	enemies_spawned = 0
	current_enemies.clear()
	
	print("🚀 SpawnManager: Starting to spawn ", total_enemies_to_spawn, " enemies")
	
	# Start spawning
	spawn_timer.start()
	
	# Initial spawn (up to max on screen)
	for i in range(min(max_enemies_on_screen, total_enemies_to_spawn)):
		_call_spawn()

func stop_spawning():
	spawn_timer.stop()

func _on_spawn_timer():
	_call_spawn()

func _call_spawn():
	# Check limits
	if enemies_spawned >= total_enemies_to_spawn:
		spawn_timer.stop()
		_check_wave_complete()
		return
	
	if current_enemies.size() >= max_enemies_on_screen:
		return
	
	# Check if any spawn point is available (not blocked)
	var spawn_point = _get_next_spawn_point()
	if spawn_point == null:
		return
	
	# Check if spawn point is clear
	if _is_spawn_blocked(spawn_point.global_position):
		# Try next spawn point
		for i in range(spawn_points.size()):
			spawn_point = _get_next_spawn_point()
			if spawn_point and not _is_spawn_blocked(spawn_point.global_position):
				break
			spawn_point = null
	
	if spawn_point == null:
		# All spawn points blocked, retry later
		return
	
	# Spawn enemy
	_spawn_enemy(spawn_point.global_position)

func _get_next_spawn_point() -> Marker2D:
	if spawn_points.size() == 0:
		return null
	
	var point = spawn_points[next_spawn_index]
	next_spawn_index = (next_spawn_index + 1) % spawn_points.size()
	return point

func _is_spawn_blocked(pos: Vector2) -> bool:
	# Check if something is already at this position
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16  # Half tile size
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collision_mask = (1 << 1) | (1 << 4) | (1 << 5)  # Enemy, Wall, Base layers
	
	var results = space_state.intersect_shape(query, 1)
	return results.size() > 0

func _spawn_enemy(pos: Vector2):
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos
	
	# Connect to enemy death
	enemy.enemy_died.connect(_on_enemy_died)
	
	# Add to scene
	get_tree().current_scene.add_child(enemy)
	
	# Track
	current_enemies.append(enemy)
	enemies_spawned += 1
	GameManager.enemies_spawned = enemies_spawned
	
	# Update UI
	_update_enemy_count_ui()
	
	# Emit signal
	enemy_spawned.emit(enemy)
	
	print("👾 Enemy spawned! (", enemies_spawned, "/", total_enemies_to_spawn, ")")

func _on_enemy_died(enemy: EnemyTank):
	if enemy in current_enemies:
		current_enemies.erase(enemy)
	
	_update_enemy_count_ui()
	
	# Check if all enemies defeated
	if enemies_spawned >= total_enemies_to_spawn and current_enemies.size() == 0:
		all_enemies_defeated.emit()

func _on_enemy_destroyed():
	# Called when any enemy is destroyed (via GameManager signal)
	# This is a backup in case the direct connection fails
	pass

func _check_wave_complete():
	if current_enemies.size() == 0:
		wave_completed.emit()

func _update_enemy_count_ui():
	# Update HUD with remaining enemy count
	var remaining = total_enemies_to_spawn - GameManager.enemies_defeated
	# TODO: Update HUD (will be done in HUD system)

func _on_game_state_changed(new_state: GameManager.GameState):
	match new_state:
		GameManager.GameState.PLAYING:
			if not spawn_timer.is_stopped():
				spawn_timer.start()
		GameManager.GameState.PAUSED:
			# Timer is handled by pausable_timers group
			pass
		GameManager.GameState.GAME_OVER, GameManager.GameState.VICTORY:
			stop_spawning()

func get_remaining_enemies() -> int:
	return total_enemies_to_spawn - enemies_spawned + current_enemies.size()

func get_current_enemy_count() -> int:
	return current_enemies.size()

func get_active_enemies() -> Array:
	# Return a copy of the current enemies array (filtered for valid instances)
	var active = []
	for enemy in current_enemies:
		if is_instance_valid(enemy):
			active.append(enemy)
	return active

func clear_all_enemies():
	# Remove all current enemies (for game reset)
	for enemy in current_enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	current_enemies.clear()
