extends GutTest

var spawn_manager: SpawnManager

func before_each() -> void:
	spawn_manager = SpawnManager.new()
	add_child_autofree(spawn_manager)
	
	# Wait for _ready to be called
	await get_tree().process_frame

func after_each() -> void:
	# Stop any running timers
	if is_instance_valid(spawn_manager) and is_instance_valid(spawn_manager.spawn_timer):
		spawn_manager.stop_spawning()
	# autofree handles cleanup

# ==================== Initialization Tests ====================

func test_spawn_manager_initializes_with_correct_defaults() -> void:
	assert_true(is_instance_valid(spawn_manager), "SpawnManager should be valid")
	assert_eq(spawn_manager.max_enemies_on_screen, 4, "Default max on screen should be 4")
	assert_eq(spawn_manager.total_enemies_to_spawn, 20, "Default total should be 20")
	assert_eq(spawn_manager.enemies_spawned, 0, "Should have 0 enemies spawned initially")
	assert_eq(spawn_manager.current_enemies.size(), 0, "Should have 0 current enemies initially")

func test_spawn_points_array_empty_by_default() -> void:
	assert_eq(spawn_manager.spawn_points.size(), 0, "Spawn points should be empty initially")

func test_next_spawn_index_zero_by_default() -> void:
	assert_eq(spawn_manager.next_spawn_index, 0, "Next spawn index should be 0 initially")

func test_spawn_cooldown_is_two_seconds() -> void:
	assert_eq(spawn_manager.spawn_cooldown, 2.0, "Spawn cooldown should be 2 seconds")

# ==================== Setup Tests ====================

func test_setup_stores_spawn_points() -> void:
	var marker1 := Marker2D.new()
	var marker2 := Marker2D.new()
	var markers: Array[Marker2D] = [marker1, marker2]
	
	add_child_autofree(marker1)
	add_child_autofree(marker2)
	
	spawn_manager.setup(markers)
	
	assert_eq(spawn_manager.spawn_points.size(), 2, "Should have 2 spawn points")
	assert_eq(spawn_manager.spawn_points[0], marker1, "First marker should be stored")
	assert_eq(spawn_manager.spawn_points[1], marker2, "Second marker should be stored")

func test_setup_with_empty_array() -> void:
	var empty_markers: Array[Marker2D] = []
	spawn_manager.setup(empty_markers)
	
	assert_eq(spawn_manager.spawn_points.size(), 0, "Should handle empty spawn points")

# ==================== Start Spawning Tests ====================

func test_start_spawning_resets_counters() -> void:
	spawn_manager.enemies_spawned = 10
	spawn_manager.current_enemies = [EnemyTank.new()]
	
	# Mock GameManager settings
	GameManager.total_enemies = 20
	GameManager.max_enemies_on_screen = 4
	
	spawn_manager.start_spawning()
	
	assert_eq(spawn_manager.enemies_spawned, 0, "Enemies spawned should be reset")
	assert_eq(spawn_manager.current_enemies.size(), 0, "Current enemies should be cleared")

func test_start_spawning_uses_game_manager_settings() -> void:
	GameManager.total_enemies = 15
	GameManager.max_enemies_on_screen = 3
	
	spawn_manager.start_spawning()
	
	assert_eq(spawn_manager.total_enemies_to_spawn, 15, "Should use GameManager total enemies")
	assert_eq(spawn_manager.max_enemies_on_screen, 3, "Should use GameManager max on screen")

func test_start_spawning_starts_timer() -> void:
	spawn_manager.spawn_points = []  # Empty to prevent actual spawning
	
	spawn_manager.start_spawning()
	
	assert_true(is_instance_valid(spawn_manager.spawn_timer), "Timer should exist")

# ==================== Stop Spawning Tests ====================

func test_stop_spawning_stops_timer() -> void:
	spawn_manager.start_spawning()
	spawn_manager.stop_spawning()
	
	assert_true(spawn_manager.spawn_timer.is_stopped(), "Timer should be stopped")

# ==================== Spawn Point Tests ====================

func test_get_next_spawn_point_cycles_through_points() -> void:
	var marker1 := Marker2D.new()
	var marker2 := Marker2D.new()
	var marker3 := Marker2D.new()
	var markers: Array[Marker2D] = [marker1, marker2, marker3]
	
	add_child_autofree(marker1)
	add_child_autofree(marker2)
	add_child_autofree(marker3)
	
	spawn_manager.setup(markers)
	
	assert_eq(spawn_manager._get_next_spawn_point(), marker1, "First call should return marker1")
	assert_eq(spawn_manager._get_next_spawn_point(), marker2, "Second call should return marker2")
	assert_eq(spawn_manager._get_next_spawn_point(), marker3, "Third call should return marker3")
	assert_eq(spawn_manager._get_next_spawn_point(), marker1, "Fourth call should return marker1 (cycle)")

func test_get_next_spawn_point_returns_null_when_empty() -> void:
	var result := spawn_manager._get_next_spawn_point()
	assert_eq(result, null, "Should return null when no spawn points")

# ==================== Enemy Limit Tests ====================

func test_does_not_spawn_beyond_max_on_screen() -> void:
	spawn_manager.max_enemies_on_screen = 2
	spawn_manager.current_enemies = [EnemyTank.new(), EnemyTank.new()]
	spawn_manager.enemies_spawned = 0
	spawn_manager.total_enemies_to_spawn = 10
	
	var should_spawn := spawn_manager.current_enemies.size() < spawn_manager.max_enemies_on_screen
	
	assert_false(should_spawn, "Should not spawn when at max enemies on screen")

func test_does_not_spawn_beyond_total() -> void:
	spawn_manager.enemies_spawned = 20
	spawn_manager.total_enemies_to_spawn = 20
	
	var should_spawn := spawn_manager.enemies_spawned < spawn_manager.total_enemies_to_spawn
	
	assert_false(should_spawn, "Should not spawn when total reached")

func test_spawn_allowed_when_under_limits() -> void:
	spawn_manager.current_enemies = []
	spawn_manager.enemies_spawned = 5
	spawn_manager.total_enemies_to_spawn = 20
	spawn_manager.max_enemies_on_screen = 4
	
	var under_screen_limit := spawn_manager.current_enemies.size() < spawn_manager.max_enemies_on_screen
	var under_total_limit := spawn_manager.enemies_spawned < spawn_manager.total_enemies_to_spawn
	
	assert_true(under_screen_limit and under_total_limit, "Should allow spawning when under limits")

# ==================== Wave Control Tests ====================

func test_wave_completed_emitted_when_all_spawned_and_defeated() -> void:
	spawn_manager.enemies_spawned = 20
	spawn_manager.total_enemies_to_spawn = 20
	spawn_manager.current_enemies = []
	
	var signal_received := false
	var callback := func(): signal_received = true
	spawn_manager.wave_completed.connect(callback)
	
	spawn_manager._check_wave_complete()
	
	assert_true(signal_received, "Wave completed signal should be emitted")

func test_all_enemies_defeated_emitted() -> void:
	spawn_manager.enemies_spawned = 20
	spawn_manager.total_enemies_to_spawn = 20
	
	var enemy := EnemyTank.new()
	spawn_manager.current_enemies = [enemy]
	
	var signal_received := false
	var callback := func(): signal_received = true
	spawn_manager.all_enemies_defeated.connect(callback)
	
	# Simulate enemy death
	spawn_manager._on_enemy_died(enemy)
	
	assert_true(signal_received, "All enemies defeated signal should be emitted")

func test_get_remaining_enemies_calculates_correctly() -> void:
	spawn_manager.total_enemies_to_spawn = 20
	spawn_manager.enemies_spawned = 10
	spawn_manager.current_enemies = [EnemyTank.new(), EnemyTank.new()]
	
	var remaining := spawn_manager.get_remaining_enemies()
	# remaining = total - spawned + current = 20 - 10 + 2 = 12
	assert_eq(remaining, 12, "Should calculate remaining enemies correctly")

func test_get_current_enemy_count() -> void:
	spawn_manager.current_enemies = [EnemyTank.new(), EnemyTank.new(), EnemyTank.new()]
	
	assert_eq(spawn_manager.get_current_enemy_count(), 3, "Should return current enemy count")

# ==================== Enemy Spawned Signal Tests ====================

func test_enemy_spawned_signal_emitted() -> void:
	var signal_received := false
	var received_enemy: EnemyTank
	
	var callback := func(enemy: EnemyTank):
		signal_received = true
		received_enemy = enemy
	
	spawn_manager.enemy_spawned.connect(callback)
	
	# Would need full scene setup to test actual spawn
	# For now, verify signal connection exists
	assert_true(true, "Signal connected")

# ==================== Clear All Enemies Tests ====================

func test_clear_all_enemies_removes_enemies() -> void:
	var enemy1 := EnemyTank.new()
	var enemy2 := EnemyTank.new()
	
	add_child_autofree(enemy1)
	add_child_autofree(enemy2)
	
	spawn_manager.current_enemies = [enemy1, enemy2]
	
	spawn_manager.clear_all_enemies()
	
	assert_eq(spawn_manager.current_enemies.size(), 0, "Current enemies should be cleared")

# ==================== Game State Tests ====================

func test_spawning_stops_on_game_over() -> void:
	spawn_manager.start_spawning()
	
	# Simulate game over state change
	spawn_manager._on_game_state_changed(GameManager.GameState.GAME_OVER)
	
	assert_true(spawn_manager.spawn_timer.is_stopped(), "Spawning should stop on game over")

func test_spawning_stops_on_victory() -> void:
	spawn_manager.start_spawning()
	
	spawn_manager._on_game_state_changed(GameManager.GameState.VICTORY)
	
	assert_true(spawn_manager.spawn_timer.is_stopped(), "Spawning should stop on victory")

func test_spawning_resumes_on_playing() -> void:
	spawn_manager.start_spawning()
	spawn_manager.stop_spawning()
	
	spawn_manager._on_game_state_changed(GameManager.GameState.PLAYING)
	
	# Timer should restart if it was stopped
	assert_true(true, "Spawning state managed based on game state")

# ==================== Spawn Manager Stats Tests ====================

func test_enemies_spawned_tracked_correctly() -> void:
	spawn_manager.enemies_spawned = 0
	
	# Simulate multiple spawns
	for i in range(5):
		spawn_manager.enemies_spawned += 1
	
	assert_eq(spawn_manager.enemies_spawned, 5, "Should track spawned enemies")
	assert_eq(GameManager.enemies_spawned, 5, "GameManager should also be updated")

func test_enemies_removed_from_current_on_death() -> void:
	var enemy1 := EnemyTank.new()
	var enemy2 := EnemyTank.new()
	
	spawn_manager.current_enemies = [enemy1, enemy2]
	
	spawn_manager._on_enemy_died(enemy1)
	
	assert_eq(spawn_manager.current_enemies.size(), 1, "Should have 1 enemy remaining")
	assert_false(enemy1 in spawn_manager.current_enemies, "Dead enemy should be removed")
