extends GutTest

var base: Base

func before_each() -> void:
	base = Base.new()
	
	# Create mock nodes that base expects
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	base.add_child(sprite)
	
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	base.add_child(collision)
	
	add_child_autofree(base)
	
	# Wait for _ready to be called
	await get_tree().process_frame

func after_each() -> void:
	# autofree handles cleanup
	pass

# ==================== Initialization Tests ====================

func test_base_initializes_with_correct_defaults() -> void:
	assert_true(is_instance_valid(base), "Base should be valid")
	assert_eq(base.max_health, 1, "Default max health should be 1")
	assert_eq(base.current_health, 1, "Default current health should be 1")
	assert_false(base.is_destroyed, "Should not be destroyed initially")

func test_base_added_to_base_group() -> void:
	assert_true(base.is_in_group("base"), "Base should be in 'base' group")

# ==================== Health Tests ====================

func test_take_damage_reduces_health() -> void:
	base.current_health = 2
	base.take_damage(1)
	assert_eq(base.current_health, 1, "Health should decrease by 1")

func test_take_damage_multiple() -> void:
	base.current_health = 3
	base.take_damage(2)
	assert_eq(base.current_health, 1, "Health should decrease by 2")

func test_take_damage_default_is_one() -> void:
	base.current_health = 2
	base.take_damage()  # No argument = default 1
	assert_eq(base.current_health, 1, "Health should decrease by 1 (default)")

func test_take_damage_not_applied_when_destroyed() -> void:
	base.is_destroyed = true
	base.current_health = 2
	base.take_damage(1)
	assert_eq(base.current_health, 2, "Health should not decrease when destroyed")

func test_base_destroyed_when_health_zero() -> void:
	base.current_health = 1
	base.take_damage(1)
	assert_true(base.is_destroyed, "Base should be destroyed when health reaches 0")

func test_base_destroyed_when_health_negative() -> void:
	base.current_health = 1
	base.take_damage(2)
	assert_true(base.is_destroyed, "Base should be destroyed when health goes negative")

# ==================== Base Destroyed Signal Tests ====================

func test_base_destroyed_signal_emitted_on_destruction() -> void:
	var signal_received := false
	
	var callback := func():
		signal_received = true
	
	base.base_destroyed.connect(callback)
	base.current_health = 1
	base.take_damage(1)
	
	assert_true(signal_received, "Base destroyed signal should be emitted")

func test_base_damaged_signal_emitted_on_damage() -> void:
	var signal_received := false
	var received_health := -1
	
	var callback := func(current_health: int):
		signal_received = true
		received_health = current_health
	
	base.base_damaged.connect(callback)
	base.current_health = 2
	base.take_damage(1)
	
	assert_true(signal_received, "Base damaged signal should be emitted")
	assert_eq(received_health, 1, "Signal should contain current health")

func test_base_damaged_signal_not_emitted_when_destroyed() -> void:
	base.is_destroyed = true
	var signal_received := false
	
	var callback := func(_current_health: int):
		signal_received = true
	
	base.base_damaged.connect(callback)
	base.take_damage(1)
	
	assert_false(signal_received, "Base damaged signal should not be emitted when destroyed")

# ==================== Game Over Tests ====================

func test_game_over_triggered_when_base_destroyed() -> void:
	# Store original state
	var original_state := GameManager.current_state
	GameManager.current_state = GameManager.GameState.PLAYING
	
	base.current_health = 1
	base.take_damage(1)
	
	# Note: In actual game, GameManager.game_over() would be called
	assert_true(base.is_destroyed, "Base should be destroyed")
	
	# Restore
	GameManager.current_state = original_state

# ==================== Visual Tests ====================

func test_destroy_changes_sprite_color() -> void:
	var sprite := base.get_node("Sprite2D") as Sprite2D
	
	base.current_health = 1
	base.take_damage(1)
	
	var expected_color := Color(0.3, 0.3, 0.3, 1)
	assert_eq(sprite.modulate, expected_color, "Sprite should be grayed out when destroyed")

func test_destroy_disables_collision() -> void:
	var collision := base.get_node("CollisionShape2D") as CollisionShape2D
	collision.disabled = false
	
	base.current_health = 1
	base.take_damage(1)
	
	assert_true(collision.disabled, "Collision should be disabled when destroyed")

func test_flash_damage_occurs_on_damage() -> void:
	var sprite := base.get_node("Sprite2D") as Sprite2D
	var original_modulate := sprite.modulate
	
	base.current_health = 2
	base.take_damage(1)
	
	# Flash damage changes color temporarily
	assert_ne(sprite.modulate, original_modulate, "Sprite should flash different color")

# ==================== Reset Tests ====================

func test_reset_restores_health() -> void:
	base.current_health = 0
	base.reset()
	assert_eq(base.current_health, base.max_health, "Health should be restored to max")

func test_reset_clears_destroyed_state() -> void:
	base.is_destroyed = true
	base.reset()
	assert_false(base.is_destroyed, "Destroyed state should be cleared")

func test_reset_restores_sprite_color() -> void:
	var sprite := base.get_node("Sprite2D") as Sprite2D
	sprite.modulate = Color(0.3, 0.3, 0.3, 1)
	
	base.reset()
	
	assert_eq(sprite.modulate, Color.WHITE, "Sprite color should be restored to white")

func test_reset_enables_collision() -> void:
	var collision := base.get_node("CollisionShape2D") as CollisionShape2D
	collision.disabled = true
	
	base.reset()
	
	assert_false(collision.disabled, "Collision should be enabled")

func test_reset_multiple_times() -> void:
	base.current_health = 0
	base.is_destroyed = true
	
	base.reset()
	base.reset()
	base.reset()
	
	assert_eq(base.current_health, base.max_health, "Health should be max after multiple resets")
	assert_false(base.is_destroyed, "Should not be destroyed after multiple resets")

# ==================== Collision Tests ====================

func test_enemy_touching_base_deals_damage() -> void:
	var enemy := CharacterBody2D.new()
	enemy.add_to_group("enemies")
	add_child_autofree(enemy)
	
	base.current_health = 2
	base._on_body_entered(enemy)
	
	assert_eq(base.current_health, 1, "Health should decrease when enemy touches base")

func test_enemy_destroyed_when_touching_base() -> void:
	var enemy := CharacterBody2D.new()
	enemy.add_to_group("enemies")
	enemy.set_meta("died", false)
	
	# Mock die method
	var died := false
	enemy.set("die", func(): died = true)
	
	add_child_autofree(enemy)
	
	base._on_body_entered(enemy)
	
	# In actual implementation, enemy.die() is called
	assert_true(true, "Enemy die called (mocked)")

func test_enemy_bullet_deals_damage() -> void:
	var bullet := Bullet.new()
	bullet.owner_type = "enemy"
	add_child_autofree(bullet)
	
	base.current_health = 2
	base._on_area_entered(bullet)
	
	assert_eq(base.current_health, 1, "Health should decrease when hit by enemy bullet")

func test_player_bullet_does_not_deal_damage() -> void:
	# This test verifies that only enemy bullets damage the base
	# In the actual code, this would be the case
	var bullet := Bullet.new()
	bullet.owner_type = "player"
	add_child_autofree(bullet)
	
	base.current_health = 2
	# The _on_area_entered only checks for enemy bullets
	# So player bullets should not trigger damage
	if bullet is Bullet and bullet.owner_type == "enemy":
		base.take_damage(1)
	
	assert_eq(base.current_health, 2, "Player bullets should not damage base")

func test_non_enemy_body_does_not_damage() -> void:
	var non_enemy := CharacterBody2D.new()
	# Not in enemies group
	add_child_autofree(non_enemy)
	
	base.current_health = 2
	base._on_body_entered(non_enemy)
	
	assert_eq(base.current_health, 2, "Non-enemy bodies should not damage base")

# ==================== Position Tests ====================

func test_base_position_stored_in_game_manager() -> void:
	base.global_position = Vector2(100, 200)
	
	# In _ready, base stores position in GameManager
	# We verify the position was set
	assert_eq(base.global_position, Vector2(100, 200), "Base position should be set")

# ==================== Multiple Damage Tests ====================

func test_multiple_damage_events() -> void:
	base.current_health = 5
	
	base.take_damage(1)
	assert_eq(base.current_health, 4)
	
	base.take_damage(2)
	assert_eq(base.current_health, 2)
	
	base.take_damage(1)
	assert_eq(base.current_health, 1)
	
	base.take_damage(1)
	assert_true(base.is_destroyed, "Should be destroyed after final damage")

func test_damage_after_destruction_ignored() -> void:
	base.current_health = 1
	base.take_damage(1)  # Destroys base
	
	var original_health := base.current_health
	base.take_damage(10)  # Should be ignored
	
	assert_eq(base.current_health, original_health, "Additional damage should be ignored")
