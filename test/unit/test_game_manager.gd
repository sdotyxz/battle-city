extends GutTest

var game_manager: Node

func before_each() -> void:
	game_manager = GameManager
	game_manager.reset_game()

func after_each() -> void:
	# Reset to normal state
	game_manager.change_state(game_manager.GameState.MENU)
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)

# ==================== Difficulty Tests ====================

func test_default_difficulty_is_normal() -> void:
	assert_eq(game_manager.current_difficulty, game_manager.Difficulty.NORMAL, "Default difficulty should be NORMAL")

func test_set_difficulty_to_easy() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.EASY)
	assert_eq(game_manager.current_difficulty, game_manager.Difficulty.EASY, "Difficulty should be set to EASY")

func test_set_difficulty_to_hard() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.HARD)
	assert_eq(game_manager.current_difficulty, game_manager.Difficulty.HARD, "Difficulty should be set to HARD")

func test_easy_difficulty_settings() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.EASY)
	var settings = game_manager.get_current_difficulty_settings()
	
	assert_eq(settings.enemy_ai_type, "random", "Easy mode should have random AI")
	assert_eq(settings.player_can_pass_walls, true, "Easy mode should allow passing walls")
	assert_eq(settings.player_invincible, true, "Easy mode should make player invincible")
	assert_eq(settings.enemy_count, 10, "Easy mode should have 10 enemies")
	assert_eq(settings.player_lives, 999, "Easy mode should have infinite lives")
	assert_eq(settings.enemy_speed, 60, "Easy mode enemy speed should be 60")

func test_normal_difficulty_settings() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	var settings = game_manager.get_current_difficulty_settings()
	
	assert_eq(settings.enemy_ai_type, "seek_base", "Normal mode should have seek_base AI")
	assert_eq(settings.player_can_pass_walls, false, "Normal mode should not allow passing walls")
	assert_eq(settings.player_invincible, false, "Normal mode should not make player invincible")
	assert_eq(settings.enemy_count, 20, "Normal mode should have 20 enemies")
	assert_eq(settings.player_lives, 3, "Normal mode should have 3 lives")
	assert_eq(settings.enemy_speed, 80, "Normal mode enemy speed should be 80")

func test_hard_difficulty_settings() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.HARD)
	var settings = game_manager.get_current_difficulty_settings()
	
	assert_eq(settings.enemy_ai_type, "seek_player", "Hard mode should have seek_player AI")
	assert_eq(settings.player_can_pass_walls, false, "Hard mode should not allow passing walls")
	assert_eq(settings.player_invincible, false, "Hard mode should not make player invincible")
	assert_eq(settings.enemy_bullet_penetrate_bricks, true, "Hard mode enemy bullets should penetrate bricks")
	assert_eq(settings.enemy_count, 25, "Hard mode should have 25 enemies")
	assert_eq(settings.player_lives, 2, "Hard mode should have 2 lives")
	assert_eq(settings.enemy_speed, 100, "Hard mode enemy speed should be 100")

func test_difficulty_affects_enemy_count() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.EASY)
	assert_eq(game_manager.total_enemies, 10, "Total enemies should be 10 in easy mode")
	
	game_manager.set_difficulty(game_manager.Difficulty.HARD)
	assert_eq(game_manager.total_enemies, 25, "Total enemies should be 25 in hard mode")

func test_difficulty_affects_player_lives() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.EASY)
	assert_eq(game_manager.player_lives, 999, "Player lives should be 999 in easy mode")
	
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	assert_eq(game_manager.player_lives, 3, "Player lives should be 3 in normal mode")

# ==================== Game State Tests ====================

func test_default_state_is_menu() -> void:
	assert_eq(game_manager.current_state, game_manager.GameState.MENU, "Default state should be MENU")

func test_change_state_to_playing() -> void:
	game_manager.change_state(game_manager.GameState.PLAYING)
	assert_eq(game_manager.current_state, game_manager.GameState.PLAYING, "State should be PLAYING")

func test_change_state_to_paused() -> void:
	game_manager.change_state(game_manager.GameState.PAUSED)
	assert_eq(game_manager.current_state, game_manager.GameState.PAUSED, "State should be PAUSED")

func test_change_state_to_game_over() -> void:
	game_manager.change_state(game_manager.GameState.GAME_OVER)
	assert_eq(game_manager.current_state, game_manager.GameState.GAME_OVER, "State should be GAME_OVER")

func test_change_state_to_victory() -> void:
	game_manager.change_state(game_manager.GameState.VICTORY)
	assert_eq(game_manager.current_state, game_manager.GameState.VICTORY, "State should be VICTORY")

func test_get_state_name_returns_correct_names() -> void:
	assert_eq(game_manager.get_state_name(game_manager.GameState.MENU), "MENU")
	assert_eq(game_manager.get_state_name(game_manager.GameState.PLAYING), "PLAYING")
	assert_eq(game_manager.get_state_name(game_manager.GameState.PAUSED), "PAUSED")
	assert_eq(game_manager.get_state_name(game_manager.GameState.GAME_OVER), "GAME_OVER")
	assert_eq(game_manager.get_state_name(game_manager.GameState.VICTORY), "VICTORY")

func test_get_difficulty_name_returns_correct_names() -> void:
	assert_eq(game_manager.get_difficulty_name(game_manager.Difficulty.EASY), "EASY")
	assert_eq(game_manager.get_difficulty_name(game_manager.Difficulty.NORMAL), "NORMAL")
	assert_eq(game_manager.get_difficulty_name(game_manager.Difficulty.HARD), "HARD")

func test_state_changed_signal_emitted() -> void:
	var signal_received := false
	var received_state: GameManager.GameState
	
	var callback := func(state: GameManager.GameState):
		signal_received = true
		received_state = state
	
	game_manager.state_changed.connect(callback)
	game_manager.change_state(game_manager.GameState.PLAYING)
	
	assert_true(signal_received, "State changed signal should be emitted")
	assert_eq(received_state, game_manager.GameState.PLAYING, "Signal should contain correct state")

func test_difficulty_changed_signal_emitted() -> void:
	var signal_received := false
	var received_difficulty: GameManager.Difficulty
	
	var callback := func(difficulty: GameManager.Difficulty):
		signal_received = true
		received_difficulty = difficulty
	
	game_manager.difficulty_changed.connect(callback)
	game_manager.set_difficulty(game_manager.Difficulty.HARD)
	
	assert_true(signal_received, "Difficulty changed signal should be emitted")
	assert_eq(received_difficulty, game_manager.Difficulty.HARD, "Signal should contain correct difficulty")

# ==================== Score and Lives Tests ====================

func test_default_score_is_zero() -> void:
	assert_eq(game_manager.score, 0, "Default score should be 0")

func test_add_score_increases_score() -> void:
	game_manager.add_score(100)
	assert_eq(game_manager.score, 100, "Score should be 100")
	
	game_manager.add_score(50)
	assert_eq(game_manager.score, 150, "Score should be 150")

func test_score_changed_signal_emitted() -> void:
	var signal_received := false
	var received_score: int
	
	var callback := func(score: int):
		signal_received = true
		received_score = score
	
	game_manager.score_changed.connect(callback)
	game_manager.add_score(100)
	
	assert_true(signal_received, "Score changed signal should be emitted")
	assert_eq(received_score, 100, "Signal should contain correct score")

func test_lives_changed_signal_emitted() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	var signal_received := false
	var received_lives: int
	
	var callback := func(lives: int):
		signal_received = true
		received_lives = lives
	
	game_manager.lives_changed.connect(callback)
	game_manager.take_life()
	
	assert_true(signal_received, "Lives changed signal should be emitted")
	assert_eq(received_lives, 2, "Signal should contain correct lives")

func test_take_life_decreases_lives() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	var initial_lives := game_manager.player_lives
	game_manager.take_life()
	assert_eq(game_manager.player_lives, initial_lives - 1, "Lives should decrease by 1")

func test_take_life_does_not_decrease_in_easy_mode() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.EASY)
	var initial_lives := game_manager.player_lives
	game_manager.take_life()
	assert_eq(game_manager.player_lives, initial_lives, "Lives should not decrease in easy mode")

# ==================== Game Flow Tests ====================

func test_reset_game_clears_score() -> void:
	game_manager.add_score(500)
	game_manager.reset_game()
	assert_eq(game_manager.score, 0, "Score should be reset to 0")

func test_reset_game_resets_enemy_counters() -> void:
	game_manager.enemies_spawned = 10
	game_manager.enemies_defeated = 5
	game_manager.reset_game()
	assert_eq(game_manager.enemies_spawned, 0, "Enemies spawned should be reset")
	assert_eq(game_manager.enemies_defeated, 0, "Enemies defeated should be reset")

func test_start_game_changes_state_to_playing() -> void:
	game_manager.start_game()
	assert_eq(game_manager.current_state, game_manager.GameState.PLAYING, "State should be PLAYING after start")

func test_start_game_resets_score() -> void:
	game_manager.add_score(100)
	game_manager.start_game()
	assert_eq(game_manager.score, 0, "Score should be reset on game start")

func test_game_over_changes_state() -> void:
	game_manager.change_state(game_manager.GameState.PLAYING)
	game_manager.game_over()
	assert_eq(game_manager.current_state, game_manager.GameState.GAME_OVER, "State should be GAME_OVER")

func test_victory_changes_state() -> void:
	game_manager.change_state(game_manager.GameState.PLAYING)
	game_manager.victory()
	assert_eq(game_manager.current_state, game_manager.GameState.VICTORY, "State should be VICTORY")

# ==================== Enemy Defeat Tests ====================

func test_on_enemy_defeated_increases_defeated_count() -> void:
	game_manager.reset_game()
	game_manager.on_enemy_defeated()
	assert_eq(game_manager.enemies_defeated, 1, "Enemies defeated should be 1")

func test_on_enemy_defeated_adds_score() -> void:
	game_manager.reset_game()
	var initial_score := game_manager.score
	game_manager.on_enemy_defeated()
	assert_eq(game_manager.score, initial_score + 100, "Score should increase by 100")

func test_on_enemy_defeated_emits_enemy_destroyed_signal() -> void:
	game_manager.reset_game()
	var signal_received := false
	
	var callback := func():
		signal_received = true
	
	game_manager.enemy_destroyed.connect(callback)
	game_manager.on_enemy_defeated()
	
	assert_true(signal_received, "Enemy destroyed signal should be emitted")

func test_check_victory_when_all_enemies_defeated() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	game_manager.change_state(game_manager.GameState.PLAYING)
	
	# Simulate defeating all enemies
	for i in range(game_manager.total_enemies):
		game_manager.on_enemy_defeated()
	
	assert_eq(game_manager.current_state, game_manager.GameState.VICTORY, "Should trigger victory")

func test_no_victory_when_not_all_enemies_defeated() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	game_manager.change_state(game_manager.GameState.PLAYING)
	game_manager.reset_game()
	
	game_manager.on_enemy_defeated()
	assert_eq(game_manager.current_state, game_manager.GameState.PLAYING, "Should not trigger victory yet")

# ==================== Lives and Game Over Tests ====================

func test_game_over_triggered_when_lives_zero() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	game_manager.change_state(game_manager.GameState.PLAYING)
	
	# Take all lives
	for i in range(3):
		game_manager.take_life()
	
	assert_eq(game_manager.current_state, game_manager.GameState.GAME_OVER, "Should trigger game over")

func test_no_game_over_when_lives_remaining() -> void:
	game_manager.set_difficulty(game_manager.Difficulty.NORMAL)
	game_manager.change_state(game_manager.GameState.PLAYING)
	
	game_manager.take_life()
	assert_eq(game_manager.current_state, game_manager.GameState.PLAYING, "Should not trigger game over")
