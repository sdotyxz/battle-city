extends GutTest

# Integration tests for Battle City game flow
# Tests interaction between multiple systems

var game_manager: Node
var player: PlayerTank
var enemy: EnemyTank
var base_node: Base
var bullet: Bullet

func before_each() -> void:
	game_manager = GameManager
	game_manager.reset_game()
	game_manager.change_state(game_manager.GameState.MENU)
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)

func after_each() -> void:
	# Clean up
	if is_instance_valid(player):
		player.queue_free()
	if is_instance_valid(enemy):
		enemy.queue_free()
	if is_instance_valid(base_node):
		base_node.queue_free()
	if is_instance_valid(bullet):
		bullet.queue_free()
	
	game_manager.reset_game()
	game_manager.change_state(game_manager.GameState.MENU)

# ==================== Player-Enemy Combat Flow ====================

func test_player_shoots_enemy() -> void:
	# Setup
	game_manager.start_game()
	
	# Create player
	player = _create_player()
	player.global_position = Vector2(100, 100)
	
	# Create enemy
	enemy = _create_enemy()
	enemy.global_position = Vector2(200, 100)  # In line with player
	
	# Player shoots at enemy
	bullet = _create_bullet()
	bullet.owner_type = "player"
	bullet.global_position = player.global_position
	bullet.direction = Vector2.RIGHT
	
	# Simulate bullet hitting enemy
	bullet._on_body_entered(enemy)
	
	assert_eq(enemy.current_health, 0, "Enemy should take damage from player bullet")
	assert_false(enemy.is_alive, "Enemy should die from player bullet")

func test_enemy_shoots_player() -> void:
	game_manager.start_game()
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	
	# Create player
	player = _create_player()
	player.global_position = Vector2(100, 100)
	player.lives = 3
	
	# Create enemy bullet
	bullet = _create_bullet()
	bullet.owner_type = "enemy"
	bullet.global_position = Vector2(100, 150)
	bullet.direction = Vector2.UP
	
	# Simulate bullet hitting player
	player._on_area_entered(bullet)
	
	assert_eq(player.lives, 2, "Player should lose a life")
	assert_eq(game_manager.player_lives, 2, "GameManager should track lost life")

func test_player_becomes_invincible_in_easy_mode() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.EASY)
	game_manager.start_game()
	
	# Create player
	player = _create_player()
	player.is_invincible = true  # Set by difficulty
	player.lives = 999
	
	var initial_lives := player.lives
	
	# Create enemy bullet
	bullet = _create_bullet()
	bullet.owner_type = "enemy"
	
	# Simulate bullet hitting player
	player._on_area_entered(bullet)
	player.take_damage()
	
	assert_eq(player.lives, initial_lives, "Player should not lose life in easy mode")

# ==================== Base Destruction Flow ====================

func test_enemy_destroys_base_triggers_game_over() -> void:
	game_manager.start_game()
	
	# Create base
	base_node = _create_base()
	base_node.global_position = Vector2(300, 300)
	
	# Create enemy bullet
	bullet = _create_bullet()
	bullet.owner_type = "enemy"
	
	# Bullet hits base
	base_node._on_area_entered(bullet)
	
	assert_true(base_node.is_destroyed, "Base should be destroyed")
	assert_eq(game_manager.current_state, game_manager.GameState.GAME_OVER, "Game should be over")

func test_player_defends_base() -> void:
	game_manager.start_game()
	
	# Create base
	base_node = _create_base()
	
	# Create enemy approaching
	enemy = _create_enemy()
	enemy.global_position = base_node.global_position + Vector2(50, 0)
	
	# Player shoots enemy before it reaches base
	bullet = _create_bullet()
	bullet.owner_type = "player"
	bullet._on_body_entered(enemy)
	
	assert_false(enemy.is_alive, "Enemy should be destroyed")
	assert_false(base_node.is_destroyed, "Base should be safe")

# ==================== Victory Flow ====================

func test_defeat_all_enemies_triggers_victory() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	game_manager.start_game()
	
	# Defeat all enemies
	for i in range(game_manager.total_enemies):
		game_manager.on_enemy_defeated()
	
	assert_eq(game_manager.current_state, game_manager.GameState.VICTORY, "Should trigger victory")

func test_partial_enemy_defeat_no_victory() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	game_manager.start_game()
	
	# Defeat only some enemies
	for i in range(game_manager.total_enemies - 1):
		game_manager.on_enemy_defeated()
	
	assert_eq(game_manager.current_state, game_manager.GameState.PLAYING, "Should not trigger victory yet")

# ==================== Difficulty Integration ====================

func test_easy_mode_player_can_pass_walls() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.EASY)
	game_manager.start_game()
	
	var settings := game_manager.get_current_difficulty_settings()
	assert_eq(settings.player_can_pass_walls, true, "Easy mode allows wall passing")

func test_hard_mode_enemy_bullets_penetrate() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.HARD)
	game_manager.start_game()
	
	# Create enemy bullet
	bullet = _create_bullet()
	bullet.owner_type = "enemy"
	
	var settings := game_manager.get_current_difficulty_settings()
	bullet.can_penetrate_bricks = settings.get("enemy_bullet_penetrate_bricks", false)
	
	assert_true(bullet.can_penetrate_bricks, "Hard mode enemy bullets should penetrate")

func test_hard_mode_enemy_has_more_health() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.HARD)
	game_manager.start_game()
	
	enemy = _create_enemy()
	enemy._apply_difficulty_settings()
	
	assert_eq(enemy.max_health, 2, "Hard mode enemies should have 2 health")

# ==================== Lives and Game Over Flow ====================

func test_player_loses_all_lives_triggers_game_over() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	game_manager.start_game()
	
	player = _create_player()
	player.lives = 1
	game_manager.player_lives = 1
	
	# Player takes fatal damage
	player.take_damage()
	
	assert_eq(game_manager.current_state, game_manager.GameState.GAME_OVER, "Should trigger game over")

func test_player_respawn_with_remaining_lives() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	game_manager.start_game()
	game_manager.player_lives = 2
	
	player = _create_player()
	player.die()
	
	# Player should respawn since lives remain
	if game_manager.player_lives > 0:
		player.respawn()
	
	assert_true(player.is_alive, "Player should respawn with remaining lives")

# ==================== Pause Integration ====================

func test_pause_stops_combat() -> void:
	game_manager.start_game()
	
	# Create entities
	player = _create_player()
	enemy = _create_enemy()
	
	var initial_player_pos := player.global_position
	var initial_enemy_pos := enemy.global_position
	
	# Pause game
	PauseManager.is_paused = true
	
	# Entities should not process while paused
	assert_true(PauseManager.is_game_paused(), "Game should be paused")

func test_resume_allows_combat() -> void:
	game_manager.start_game()
	
	# Pause then resume
	PauseManager.is_paused = true
	PauseManager.toggle_pause()
	PauseManager.toggle_pause()
	
	assert_false(PauseManager.is_game_paused(), "Game should not be paused")
	assert_eq(game_manager.current_state, game_manager.GameState.PLAYING, "Game should be playing")

# ==================== Score Integration ====================

func test_defeating_enemy_increases_score() -> void:
	game_manager.reset_game()
	game_manager.start_game()
	
	var initial_score := game_manager.score
	
	game_manager.on_enemy_defeated()
	
	assert_eq(game_manager.score, initial_score + 100, "Score should increase by 100")

func test_multiple_enemies_multiple_score() -> void:
	game_manager.reset_game()
	game_manager.start_game()
	
	for i in range(5):
		game_manager.on_enemy_defeated()
	
	assert_eq(game_manager.score, 500, "Score should be 500 after 5 enemies")

# ==================== Complete Game Flow ====================

func test_full_game_flow_normal_mode() -> void:
	# Start game
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	game_manager.start_game()
	
	assert_eq(game_manager.current_state, game_manager.GameState.PLAYING)
	assert_eq(game_manager.player_lives, 3)
	assert_eq(game_manager.total_enemies, 20)
	
	# Defeat some enemies
	for i in range(10):
		game_manager.on_enemy_defeated()
	
	assert_eq(game_manager.score, 1000)
	assert_eq(game_manager.enemies_defeated, 10)
	
	# Defeat remaining enemies
	for i in range(10):
		game_manager.on_enemy_defeated()
	
	assert_eq(game_manager.current_state, game_manager.GameState.VICTORY)

func test_full_game_flow_game_over() -> void:
	# Start game
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	game_manager.start_game()
	
	# Lose all lives
	game_manager.take_life()  # 2 lives
	game_manager.take_life()  # 1 life
	game_manager.take_life()  # 0 lives - game over
	
	assert_eq(game_manager.current_state, game_manager.GameState.GAME_OVER)

# ==================== Helper Functions ====================

func _create_player() -> PlayerTank:
	var p := PlayerTank.new()
	
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	p.add_child(sprite)
	
	var shoot_point := Marker2D.new()
	shoot_point.name = "ShootPoint"
	p.add_child(shoot_point)
	
	var timer := Timer.new()
	timer.name = "CooldownTimer"
	p.add_child(timer)
	
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	p.add_child(collision)
	
	add_child_autofree(p)
	return p

func _create_enemy() -> EnemyTank:
	var e := EnemyTank.new()
	
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	e.add_child(sprite)
	
	var shoot_point := Marker2D.new()
	shoot_point.name = "ShootPoint"
	e.add_child(shoot_point)
	
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	e.add_child(collision)
	
	add_child_autofree(e)
	return e

func _create_bullet() -> Bullet:
	var b := Bullet.new()
	
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	b.add_child(sprite)
	
	var timer := Timer.new()
	timer.name = "LifetimeTimer"
	b.add_child(timer)
	
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	b.add_child(collision)
	
	add_child_autofree(b)
	return b

func _create_base() -> Base:
	var b := Base.new()
	
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	b.add_child(sprite)
	
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	b.add_child(collision)
	
	add_child_autofree(b)
	return b
