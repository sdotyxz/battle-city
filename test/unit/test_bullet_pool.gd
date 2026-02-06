extends GutTest

var bullet_pool: Node

func before_each() -> void:
	# Create a fresh BulletPool instance
	bullet_pool = Node.new()
	bullet_pool.set_script(load("res://src/utils/bullet_pool.gd"))
	
	# Replace bullet_scene with a simple mock to avoid dependencies
	var mock_scene := Node2D.new()
	mock_scene.set_script(GDScript.new())
	mock_scene.get_script().source_code = """
	extends Node2D
	var is_alive: bool = true
	var can_penetrate_bricks: bool = false
	var direction: Vector2 = Vector2.ZERO
	var position: Vector2 = Vector2.ZERO
	
	func reset():
		is_alive = true
		can_penetrate_bricks = false
		direction = Vector2.ZERO
		position = Vector2.ZERO
	"""
	mock_scene.get_script().reload()
	
	bullet_pool.add_child(mock_scene)
	bullet_pool.bullet_scene = mock_scene
	bullet_pool.pool_size = 5
	
	add_child_autofree(bullet_pool)
	
	# Wait for _ready to be called
	await get_tree().process_frame

func after_each() -> void:
	# Clean up any remaining bullets
	if is_instance_valid(bullet_pool):
		bullet_pool.clear_all_bullets()
	# autofree handles cleanup

# ==================== Initialization Tests ====================

func test_bullet_pool_initializes_with_correct_defaults() -> void:
	assert_true(is_instance_valid(bullet_pool), "BulletPool should be valid")
	assert_eq(bullet_pool.pool_size, 5, "Pool size should be 5 (as set)")
	assert_eq(bullet_pool.pool.size(), 5, "Pool should contain 5 bullets")
	assert_eq(bullet_pool.active_bullets.size(), 0, "Should have 0 active bullets initially")

func test_pre_created_bullets_are_in_pool() -> void:
	assert_eq(bullet_pool.pool.size(), bullet_pool.pool_size, "All bullets should be in pool")

func test_pre_created_bullets_are_inactive() -> void:
	for bullet in bullet_pool.pool:
		assert_false(bullet.visible, "Pre-created bullet should not be visible")
		assert_eq(bullet.process_mode, Node.PROCESS_MODE_DISABLED, "Pre-created bullet should be disabled")

# ==================== Get Bullet Tests ====================

func test_get_bullet_returns_bullet_from_pool() -> void:
	var bullet := bullet_pool.get_bullet()
	
	assert_true(is_instance_valid(bullet), "Should return a valid bullet")
	assert_true(bullet.visible, "Bullet should be visible")
	assert_eq(bullet.process_mode, Node.PROCESS_MODE_INHERIT, "Bullet should be enabled")

func test_get_bullet_removes_from_pool() -> void:
	var initial_pool_size := bullet_pool.pool.size()
	bullet_pool.get_bullet()
	
	assert_eq(bullet_pool.pool.size(), initial_pool_size - 1, "Pool size should decrease")

func test_get_bullet_adds_to_active() -> void:
	var bullet := bullet_pool.get_bullet()
	
	assert_true(bullet in bullet_pool.active_bullets, "Bullet should be in active list")
	assert_eq(bullet_pool.active_bullets.size(), 1, "Should have 1 active bullet")

func test_get_bullet_calls_reset() -> void:
	var bullet := bullet_pool.get_bullet()
	
	assert_true(bullet.is_alive, "Bullet should be alive after reset")
	assert_false(bullet.can_penetrate_bricks, "Penetration should be reset")
	assert_eq(bullet.direction, Vector2.ZERO, "Direction should be reset")
	assert_eq(bullet.position, Vector2.ZERO, "Position should be reset")

func test_get_multiple_bullets() -> void:
	var bullet1 := bullet_pool.get_bullet()
	var bullet2 := bullet_pool.get_bullet()
	var bullet3 := bullet_pool.get_bullet()
	
	assert_ne(bullet1, bullet2, "Bullets should be different instances")
	assert_ne(bullet2, bullet3, "Bullets should be different instances")
	assert_eq(bullet_pool.active_bullets.size(), 3, "Should have 3 active bullets")
	assert_eq(bullet_pool.pool.size(), 2, "Should have 2 bullets remaining in pool")

func test_get_bullet_creates_new_when_pool_empty() -> void:
	# Empty the pool
	for i in range(bullet_pool.pool_size):
		bullet_pool.get_bullet()
	
	assert_eq(bullet_pool.pool.size(), 0, "Pool should be empty")
	
	# Get one more - should create new
	var bullet := bullet_pool.get_bullet()
	
	assert_true(is_instance_valid(bullet), "Should create new bullet when pool empty")
	assert_eq(bullet_pool.active_bullets.size(), bullet_pool.pool_size + 1, "Should have extra active bullet")

# ==================== Return Bullet Tests ====================

func test_return_bullet_removes_from_active() -> void:
	var bullet := bullet_pool.get_bullet()
	assert_true(bullet in bullet_pool.active_bullets, "Bullet should be active")
	
	bullet_pool.return_bullet(bullet)
	
	assert_false(bullet in bullet_pool.active_bullets, "Bullet should not be in active list")

func test_return_bullet_disables_bullet() -> void:
	var bullet := bullet_pool.get_bullet()
	bullet.visible = true
	bullet.process_mode = Node.PROCESS_MODE_INHERIT
	
	bullet_pool.return_bullet(bullet)
	
	assert_false(bullet.visible, "Bullet should not be visible")
	assert_eq(bullet.process_mode, Node.PROCESS_MODE_DISABLED, "Bullet should be disabled")

func test_return_bullet_resets_bullet() -> void:
	var bullet := bullet_pool.get_bullet()
	bullet.direction = Vector2.RIGHT
	bullet.position = Vector2(100, 100)
	
	bullet_pool.return_bullet(bullet)
	
	assert_eq(bullet.direction, Vector2.ZERO, "Direction should be reset")
	assert_eq(bullet.position, Vector2.ZERO, "Position should be reset")

func test_return_bullet_adds_back_to_pool() -> void:
	var bullet := bullet_pool.get_bullet()
	var initial_pool_size := bullet_pool.pool.size()
	
	bullet_pool.return_bullet(bullet)
	
	assert_eq(bullet_pool.pool.size(), initial_pool_size + 1, "Pool should increase")
	assert_true(bullet in bullet_pool.pool, "Bullet should be back in pool")

func test_return_bullet_not_in_pool_if_full() -> void:
	# Fill pool to capacity
	while bullet_pool.pool.size() < bullet_pool.pool_size:
		var temp = Node2D.new()
		bullet_pool.pool.append(temp)
		bullet_pool.add_child(temp)
	
	var bullet := bullet_pool.get_bullet()
	bullet_pool.return_bullet(bullet)
	
	# Pool was already full, bullet should be freed
	assert_eq(bullet_pool.pool.size(), bullet_pool.pool_size, "Pool should not exceed capacity")

func test_return_bullet_not_in_active_skips_removal() -> void:
	var bullet := Node2D.new()
	add_child_autofree(bullet)
	
	# Bullet was never active
	bullet_pool.return_bullet(bullet)
	
	# Should not throw error
	assert_true(true, "Return bullet should handle non-active bullet gracefully")

# ==================== Pool Capacity Tests ====================

func test_pool_respects_capacity() -> void:
	# The pool should never exceed pool_size when returning bullets
	var capacity := bullet_pool.pool_size
	
	# Get and return bullets multiple times
	for i in range(capacity * 2):
		var bullet := bullet_pool.get_bullet()
		bullet_pool.return_bullet(bullet)
	
	assert_true(bullet_pool.pool.size() <= capacity, "Pool should not exceed capacity")

func test_active_bullets_can_exceed_pool_size() -> void:
	# Get more bullets than pool size (creates new ones)
	for i in range(bullet_pool.pool_size + 5):
		bullet_pool.get_bullet()
	
	assert_eq(bullet_pool.active_bullets.size(), bullet_pool.pool_size + 5, "Active bullets can exceed pool size")

# ==================== Clear All Bullets Tests ====================

func test_clear_all_bullets_returns_all_to_pool() -> void:
	# Get some bullets
	for i in range(3):
		bullet_pool.get_bullet()
	
	assert_eq(bullet_pool.active_bullets.size(), 3, "Should have 3 active bullets")
	
	bullet_pool.clear_all_bullets()
	
	assert_eq(bullet_pool.active_bullets.size(), 0, "Should have 0 active bullets after clear")
	assert_eq(bullet_pool.pool.size(), bullet_pool.pool_size, "Pool should be restored")

func test_clear_all_bullets_resets_bullets() -> void:
	var bullet := bullet_pool.get_bullet()
	bullet.direction = Vector2.RIGHT
	bullet.visible = true
	
	bullet_pool.clear_all_bullets()
	
	assert_false(bullet.visible, "Bullet should be hidden after clear")
	assert_eq(bullet.direction, Vector2.ZERO, "Bullet should be reset after clear")

func test_clear_all_bullets_on_empty_pool() -> void:
	# Clear when nothing is active
	bullet_pool.clear_all_bullets()
	
	assert_eq(bullet_pool.active_bullets.size(), 0, "Should handle clearing empty active list")
	assert_eq(bullet_pool.pool.size(), bullet_pool.pool_size, "Pool should be full")

# ==================== Pool Efficiency Tests ====================

func test_get_return_cycle_maintains_pool() -> void:
	var initial_pool_size := bullet_pool.pool.size()
	
	# Get and return bullets in a cycle
	for i in range(10):
		var bullet := bullet_pool.get_bullet()
		bullet_pool.return_bullet(bullet)
	
	assert_eq(bullet_pool.pool.size(), initial_pool_size, "Pool size should remain constant")
	assert_eq(bullet_pool.active_bullets.size(), 0, "No active bullets after all returned")

func test_bullets_reused_from_pool() -> void:
	var bullet1 := bullet_pool.get_bullet()
	var bullet1_id := bullet1.get_instance_id()
	
	bullet_pool.return_bullet(bullet1)
	
	var bullet2 := bullet_pool.get_bullet()
	var bullet2_id := bullet2.get_instance_id()
	
	assert_eq(bullet1_id, bullet2_id, "Same bullet instance should be reused from pool")

# ==================== Performance Tests ====================

func test_pool_performance_many_operations() -> void:
	# Simulate heavy usage
	for cycle in range(5):
		# Get all bullets
		var bullets := []
		for i in range(bullet_pool.pool_size):
			bullets.append(bullet_pool.get_bullet())
		
		# Return all bullets
		for bullet in bullets:
			bullet_pool.return_bullet(bullet)
	
	assert_eq(bullet_pool.active_bullets.size(), 0, "All bullets should be returned")
	assert_eq(bullet_pool.pool.size(), bullet_pool.pool_size, "Pool should be full")
