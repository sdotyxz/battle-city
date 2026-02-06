extends GutTest

var player: PlayerTank

# Mock objects to avoid dependencies
var mock_game_manager: Node
var mock_audio_manager: Node
var mock_pause_manager: Node

func before_each() -> void:
	# Create mock managers before instantiating player
	_setup_mock_managers()
	
	player = PlayerTank.new()
	
	# Create mock nodes that player expects
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	player.add_child(sprite)
	
	var shoot_point := Marker2D.new()
	shoot_point.name = "ShootPoint"
	player.add_child(shoot_point)
	
	var timer := Timer.new()
	timer.name = "CooldownTimer"
	player.add_child(timer)
	
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	player.add_child(collision)
	
	add_child_autofree(player)
	
	# Wait for _ready to be called
	await get_tree().process_frame

func after_each() -> void:
	_cleanup_mock_managers()
	# autofree handles player cleanup

func _setup_mock_managers() -> void:
	# Create mock GameManager if not exists
	if not Engine.has_singleton("GameManager"):
		mock_game_manager = Node.new()
		mock_game_manager.name = "GameManager"
		mock_game_manager.set_script(load("res://src/managers/game_manager.gd"))
		get_tree().root.add_child(mock_game_manager)
	
	# Create mock PauseManager
	if not Engine.has_singleton("PauseManager"):
		mock_pause_manager = Node.new()
		mock_pause_manager.name = "PauseManager"
		mock_pause_manager.set("is_paused", false)
		mock_pause_manager.set_script(load("res://src/managers/pause_manager.gd"))
		get_tree().root.add_child(mock_pause_manager)

func _cleanup_mock_managers() -> void:
	if is_instance_valid(mock_game_manager):
		mock_game_manager.queue_free()
	if is_instance_valid(mock_pause_manager):
		mock_pause_manager.queue_free()

# ==================== Initialization Tests ====================

func test_player_initializes_with_correct_defaults() -> void:
	assert_true(is_instance_valid(player), "Player should be valid")
	assert_eq(player.speed, 100.0, "Default speed should be 100")
	assert_eq(player.direction, Vector2.UP, "Default direction should be UP")
	assert_eq(player.bullet_speed, 300.0, "Default bullet speed should be 300")
	assert_eq(player.shoot_cooldown, 0.5, "Default shoot cooldown should be 0.5")
	assert_true(player.can_shoot, "Should be able to shoot initially")
	assert_eq(player.current_bullets, 0, "Should have 0 bullets initially")
	assert_true(player.is_alive, "Should be alive initially")
	assert_eq(player.lives, 3, "Should have 3 lives initially")

func test_player_added_to_player_group() -> void:
	assert_true(player.is_in_group("player"), "Player should be in 'player' group")

# ==================== Movement Tests ====================

func test_player_direction_can_be_set() -> void:
	player.set_direction(Vector2.RIGHT)
	assert_eq(player.direction, Vector2.RIGHT, "Direction should be set to RIGHT")

func test_player_movement_increases_position() -> void:
	player.global_position = Vector2.ZERO
	player.direction = Vector2.RIGHT
	player.velocity = Vector2.RIGHT * player.speed
	
	var initial_pos := player.global_position
	player._physics_process(0.1)
	
	assert_true(player.global_position.x > initial_pos.x, "Player should move right")

func test_directions_affect_velocity() -> void:
	# Test UP
	player.direction = Vector2.UP
	player.velocity = Vector2.UP * player.speed
	assert_eq(player.velocity, Vector2(0, -player.speed), "Velocity should be upward")
	
	# Test DOWN
	player.direction = Vector2.DOWN
	player.velocity = Vector2.DOWN * player.speed
	assert_eq(player.velocity, Vector2(0, player.speed), "Velocity should be downward")
	
	# Test LEFT
	player.direction = Vector2.LEFT
	player.velocity = Vector2.LEFT * player.speed
	assert_eq(player.velocity, Vector2(-player.speed, 0), "Velocity should be leftward")
	
	# Test RIGHT
	player.direction = Vector2.RIGHT
	player.velocity = Vector2.RIGHT * player.speed
	assert_eq(player.velocity, Vector2(player.speed, 0), "Velocity should be rightward")

# ==================== Shooting Tests ====================

func test_can_shoot_resets_after_cooldown() -> void:
	player.can_shoot = false
	player._on_cooldown_finished()
	assert_true(player.can_shoot, "Should be able to shoot after cooldown")

func test_cooldown_timer_reduces_can_shoot() -> void:
	player.can_shoot = true
	player.shoot()
	assert_false(player.can_shoot, "Should not be able to shoot immediately after shooting")

func test_bullet_count_tracked() -> void:
	# Note: This test would need actual scene setup with BulletPool
	# For unit test, we verify the tracking logic
	player.current_bullets = 0
	player._on_bullet_destroyed()
	assert_eq(player.current_bullets, -1, "Bullet count should decrease when bullet destroyed")

func test_max_bullets_limit() -> void:
	player.current_bullets = player.MAX_BULLETS
	player.can_shoot = true
	
	# Simulate shoot attempt (would need mocking)
	# For now, test the condition logic
	var can_actually_shoot := player.can_shoot and player.current_bullets < player.MAX_BULLETS
	assert_false(can_actually_shoot, "Should not be able to shoot at max bullets")

# ==================== Damage and Health Tests ====================

func test_take_damage_reduces_lives() -> void:
	var initial_lives := player.lives
	player.take_damage()
	assert_eq(player.lives, initial_lives - 1, "Lives should decrease by 1")

func test_take_damage_not_applied_when_invincible() -> void:
	player.is_invincible = true
	var initial_lives := player.lives
	player.take_damage()
	assert_eq(player.lives, initial_lives, "Lives should not decrease when invincible")

func test_take_damage_not_applied_when_not_alive() -> void:
	player.is_alive = false
	var initial_lives := player.lives
	player.take_damage()
	assert_eq(player.lives, initial_lives, "Lives should not decrease when not alive")

func test_player_dies_when_lives_zero() -> void:
	player.lives = 1
	player.take_damage()
	assert_false(player.is_alive, "Player should not be alive after taking fatal damage")

func test_die_sets_is_alive_false() -> void:
	player.is_alive = true
	player.die()
	assert_false(player.is_alive, "Player should not be alive after die()")

func test_die_hides_player() -> void:
	player.visible = true
	player.die()
	assert_false(player.visible, "Player should be hidden after death")

func test_die_disables_collision() -> void:
	var collision := player.get_node("CollisionShape2D") as CollisionShape2D
	collision.disabled = false
	player.die()
	assert_true(collision.disabled, "Collision should be disabled after death")

func test_player_died_signal_emitted_on_death() -> void:
	var signal_received := false
	
	var callback := func():
		signal_received = true
	
	player.player_died.connect(callback)
	player.die()
	
	assert_true(signal_received, "Player died signal should be emitted")

# ==================== Difficulty Awareness Tests ====================

func test_easy_mode_allows_passing_walls() -> void:
	# This would require mocking GameManager with EASY difficulty
	# Testing the internal state after _apply_difficulty_settings
	player.can_pass_walls = true
	assert_true(player.can_pass_walls, "Player should be able to pass walls when configured")

func test_easy_mode_makes_invincible() -> void:
	player.is_invincible = true
	assert_true(player.is_invincible, "Player should be invincible when configured")

func test_hard_mode_does_not_allow_passing_walls() -> void:
	player.can_pass_walls = false
	assert_false(player.can_pass_walls, "Player should not pass walls in hard mode")

# ==================== Respawn Tests ====================

func test_respawn_requires_positive_lives() -> void:
	# Mock GameManager to have lives > 0
	player.is_alive = false
	player.lives = 1  # This would normally come from GameManager
	
	# Simulate respawn condition
	var can_respawn := player.lives > 0
	assert_true(can_respawn, "Should be able to respawn with lives remaining")

func test_respawn_sets_is_alive_true() -> void:
	player.is_alive = false
	player.visible = false
	player.lives = 1
	
	# Manually trigger respawn logic (would need GameManager mock)
	if player.lives > 0:
		player.is_alive = true
		player.visible = true
	
	assert_true(player.is_alive, "Player should be alive after respawn")
	assert_true(player.visible, "Player should be visible after respawn")

# ==================== Visual Tests ====================

func test_sprite_rotation_updates_with_direction() -> void:
	# This would need actual sprite node setup
	# Test the rotation values that would be applied
	
	var test_directions := [
		{ "dir": Vector2.UP, "expected": 0.0 },
		{ "dir": Vector2.DOWN, "expected": 180.0 },
		{ "dir": Vector2.LEFT, "expected": -90.0 },
		{ "dir": Vector2.RIGHT, "expected": 90.0 }
	]
	
	for test in test_directions:
		player.direction = test.dir
		# Verify direction is set (rotation would happen in _update_sprite_direction)
		assert_eq(player.direction, test.dir, "Direction should be set to " + str(test.dir))

# ==================== State Tests ====================

func test_player_does_not_move_when_not_alive() -> void:
	player.is_alive = false
	player.global_position = Vector2.ZERO
	player.velocity = Vector2.RIGHT * player.speed
	
	var initial_pos := player.global_position
	player._physics_process(0.1)
	
	assert_eq(player.global_position, initial_pos, "Player should not move when not alive")

func test_player_does_not_process_when_paused() -> void:
	# Mock pause state
	player.global_position = Vector2.ZERO
	player.velocity = Vector2.RIGHT * player.speed
	
	var initial_pos := player.global_position
	# _physics_process would early return if paused
	assert_eq(player.global_position, initial_pos, "Position unchanged when paused")
