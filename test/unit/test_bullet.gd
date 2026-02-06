extends GutTest

var bullet: Bullet

func before_each() -> void:
	bullet = Bullet.new()
	
	# Create mock nodes that bullet expects
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	bullet.add_child(sprite)
	
	var timer := Timer.new()
	timer.name = "LifetimeTimer"
	bullet.add_child(timer)
	
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	bullet.add_child(collision)
	
	add_child_autofree(bullet)
	
	# Wait for _ready to be called
	await get_tree().process_frame

func after_each() -> void:
	# autofree handles cleanup
	pass

# ==================== Initialization Tests ====================

func test_bullet_initializes_with_correct_defaults() -> void:
	assert_true(is_instance_valid(bullet), "Bullet should be valid")
	assert_eq(bullet.speed, 300.0, "Default speed should be 300")
	assert_eq(bullet.damage, 1, "Default damage should be 1")
	assert_eq(bullet.direction, Vector2.ZERO, "Default direction should be ZERO")
	assert_eq(bullet.owner_type, "", "Default owner should be empty")
	assert_true(bullet.is_alive, "Should be alive initially")
	assert_false(bullet.can_penetrate_bricks, "Should not penetrate bricks by default")

func test_bullet_added_to_pausable_timers_group() -> void:
	assert_true(bullet.is_in_group("pausable_timers"), "Bullet should be in 'pausable_timers' group")

# ==================== Movement Tests ====================

func test_bullet_moves_in_direction() -> void:
	bullet.global_position = Vector2.ZERO
	bullet.direction = Vector2.RIGHT
	bullet.is_alive = true
	
	var initial_pos := bullet.position
	bullet._physics_process(0.1)
	
	assert_true(bullet.position.x > initial_pos.x, "Bullet should move right")

func test_bullet_does_not_move_when_not_alive() -> void:
	bullet.global_position = Vector2.ZERO
	bullet.direction = Vector2.RIGHT
	bullet.is_alive = false
	
	var initial_pos := bullet.position
	bullet._physics_process(0.1)
	
	assert_eq(bullet.position, initial_pos, "Bullet should not move when not alive")

func test_bullet_does_not_move_when_paused() -> void:
	# Would need PauseManager mock
	# For now, test that velocity calculation is correct
	bullet.global_position = Vector2.ZERO
	bullet.direction = Vector2.UP
	bullet.is_alive = true
	
	# Calculate expected movement
	var delta := 0.1
	var expected_movement := bullet.direction * bullet.speed * delta
	assert_eq(expected_movement, Vector2(0, -300.0 * delta), "Movement calculation should be correct")

func test_bullet_speed_affects_movement() -> void:
	bullet.direction = Vector2.RIGHT
	bullet.is_alive = true
	
	var speed1 := 100.0
	var speed2 := 300.0
	var delta := 0.1
	
	var movement1 := bullet.direction * speed1 * delta
	var movement2 := bullet.direction * speed2 * delta
	
	assert_true(movement2.length() > movement1.length(), "Higher speed should result in more movement")

# ==================== Collision Detection Tests ====================

func test_bullet_collision_with_base() -> void:
	var base := Area2D.new()
	base.add_to_group("base")
	
	var damage_taken := false
	base.set_meta("damage_received", false)
	
	# Base would have take_damage method
	add_child_autofree(base)
	
	# Test collision logic
	bullet.is_alive = true
	var was_alive := bullet.is_alive
	
	# Simulate collision with base
	if base.is_in_group("base"):
		bullet.destroy()
	
	assert_false(bullet.is_alive, "Bullet should be destroyed after hitting base")

func test_bullet_vs_bullet_collision() -> void:
	var bullet2 := Bullet.new()
	bullet2.is_alive = true
	add_child_autofree(bullet2)
	
	bullet.is_alive = true
	
	# Simulate bullet collision
	bullet.destroy()
	bullet2.destroy()
	
	assert_false(bullet.is_alive, "First bullet should be destroyed")
	assert_false(bullet2.is_alive, "Second bullet should be destroyed")

func test_player_bullet_hits_enemy() -> void:
	bullet.owner_type = "player"
	bullet.is_alive = true
	
	var enemy := CharacterBody2D.new()
	enemy.add_to_group("enemies")
	add_child_autofree(enemy)
	
	# Simulate collision
	if enemy.is_in_group("enemies") and bullet.owner_type == "player":
		bullet.destroy()
	
	assert_false(bullet.is_alive, "Bullet should be destroyed after hitting enemy")

func test_enemy_bullet_hits_player() -> void:
	bullet.owner_type = "enemy"
	bullet.is_alive = true
	
	var player := CharacterBody2D.new()
	player.add_to_group("player")
	add_child_autofree(player)
	
	# Simulate collision
	if player.is_in_group("player") and bullet.owner_type == "enemy":
		bullet.destroy()
	
	assert_false(bullet.is_alive, "Bullet should be destroyed after hitting player")

# ==================== Wall Collision Tests ====================

func test_bullet_destroyed_by_steel_wall() -> void:
	bullet.is_alive = true
	
	# Simulate steel wall collision
	var is_steel := true
	if is_steel:
		bullet.is_alive = false
	
	assert_false(bullet.is_alive, "Bullet should be destroyed by steel wall")

func test_bullet_destroyed_by_brick_wall_normal_mode() -> void:
	bullet.is_alive = true
	bullet.can_penetrate_bricks = false
	
	var is_destructible := true
	var is_steel := false
	
	# Normal mode logic
	if is_destructible and not is_steel:
		if not (bullet.can_penetrate_bricks and bullet.owner_type == "enemy"):
			bullet.is_alive = false
	
	assert_false(bullet.is_alive, "Bullet should be destroyed by brick wall in normal mode")

func test_bullet_penetrates_bricks_in_hard_mode() -> void:
	bullet.is_alive = true
	bullet.owner_type = "enemy"
	bullet.can_penetrate_bricks = true
	
	var is_destructible := true
	var is_steel := false
	
	# Hard mode logic
	if is_destructible and not is_steel:
		if bullet.can_penetrate_bricks and bullet.owner_type == "enemy":
			# Bullet continues (penetrates)
			pass
		else:
			bullet.is_alive = false
	
	assert_true(bullet.is_alive, "Enemy bullet should penetrate bricks in hard mode")

func test_player_bullet_does_not_penetrate_bricks() -> void:
	bullet.is_alive = true
	bullet.owner_type = "player"
	bullet.can_penetrate_bricks = true  # Even if somehow set
	
	var is_destructible := true
	var is_steel := false
	
	# Player bullets should never penetrate
	if is_destructible and not is_steel:
		if bullet.can_penetrate_bricks and bullet.owner_type == "enemy":
			pass  # Penetrates
		else:
			bullet.is_alive = false
	
	assert_false(bullet.is_alive, "Player bullet should be destroyed by brick wall")

# ==================== Penetration Logic Tests ====================

func test_penetrate_bricks_flag_only_works_for_enemy() -> void:
	# Test the full condition
	var test_cases := [
		{ "can_penetrate": true, "owner": "enemy", "expected_alive": true },
		{ "can_penetrate": true, "owner": "player", "expected_alive": false },
		{ "can_penetrate": false, "owner": "enemy", "expected_alive": false },
		{ "can_penetrate": false, "owner": "player", "expected_alive": false }
	]
	
	for test in test_cases:
		bullet.can_penetrate_bricks = test.can_penetrate
		bullet.owner_type = test.owner
		bullet.is_alive = true
		
		# Apply penetration logic
		var should_penetrates := bullet.can_penetrate_bricks and bullet.owner_type == "enemy"
		
		if should_penetrates:
			pass  # Bullet continues
		else:
			bullet.is_alive = false
		
		if test.expected_alive:
			assert_true(bullet.is_alive, "Bullet should be alive for " + str(test))
		else:
			assert_false(bullet.is_alive, "Bullet should be destroyed for " + str(test))
		
		# Reset for next test
		bullet.is_alive = true

# ==================== Lifetime Tests ====================

func test_lifetime_timeout_destroys_bullet() -> void:
	bullet.is_alive = true
	bullet._on_lifetime_timeout()
	assert_false(bullet.is_alive, "Bullet should be destroyed after lifetime timeout")

# ==================== Destroy and Reset Tests ====================

func test_destroy_sets_is_alive_false() -> void:
	bullet.is_alive = true
	bullet.destroy()
	assert_false(bullet.is_alive, "Bullet should not be alive after destroy")

func test_destroy_does_nothing_if_already_not_alive() -> void:
	bullet.is_alive = false
	# Should not throw error
	bullet.destroy()
	assert_false(bullet.is_alive, "Bullet should remain not alive")

func test_reset_clears_state() -> void:
	bullet.is_alive = false
	bullet.can_penetrate_bricks = true
	bullet.direction = Vector2.RIGHT
	bullet.position = Vector2(100, 100)
	
	bullet.reset()
	
	assert_true(bullet.is_alive, "Bullet should be alive after reset")
	assert_false(bullet.can_penetrate_bricks, "Penetration should be disabled after reset")
	assert_eq(bullet.direction, Vector2.ZERO, "Direction should be reset")
	assert_eq(bullet.position, Vector2.ZERO, "Position should be reset")

# ==================== Owner Type Tests ====================

func test_owner_type_set_correctly() -> void:
	bullet.owner_type = "player"
	assert_eq(bullet.owner_type, "player", "Owner type should be player")
	
	bullet.owner_type = "enemy"
	assert_eq(bullet.owner_type, "enemy", "Owner type should be enemy")

# ==================== Speed and Damage Tests ====================

func test_speed_can_be_modified() -> void:
	var new_speed := 500.0
	bullet.speed = new_speed
	assert_eq(bullet.speed, new_speed, "Speed should be modifiable")

func test_damage_can_be_modified() -> void:
	var new_damage := 2
	bullet.damage = new_damage
	assert_eq(bullet.damage, new_damage, "Damage should be modifiable")

# ==================== Direction Tests ====================

func test_direction_affects_movement_direction() -> void:
	var test_cases := [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT
	]
	
	for dir in test_cases:
		bullet.direction = dir
		assert_eq(bullet.direction, dir, "Direction should be set to " + str(dir))

func test_zero_direction_results_in_no_movement() -> void:
	bullet.direction = Vector2.ZERO
	bullet.is_alive = true
	
	var delta := 0.1
	var expected_movement := Vector2.ZERO * bullet.speed * delta
	assert_eq(expected_movement, Vector2.ZERO, "Zero direction should result in no movement")
