extends Node

# Game State
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, VICTORY }
var current_state: GameState = GameState.MENU

# Difficulty
enum Difficulty { EASY, NORMAL, HARD }
var current_difficulty: Difficulty = Difficulty.NORMAL

# Game Data
var player_lives: int = 3
var score: int = 0
var current_level: int = 1
var max_levels: int = 4

# Enemy tracking
var total_enemies: int = 20
var enemies_spawned: int = 0
var enemies_defeated: int = 0
var max_enemies_on_screen: int = 4

# Demo Mode
var is_demo_mode: bool = false
var demo_difficulty: Difficulty = Difficulty.NORMAL

# Map System Reference
var map_system: Node = null  # MapSystem reference (set by game scene)

# Level completion tracking
var is_level_completed: bool = false

# References
var player_tank: Node2D = null
var base_position: Vector2 = Vector2.ZERO

# Signals
signal state_changed(new_state: GameState)
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal enemy_destroyed()
signal difficulty_changed(new_difficulty: Difficulty)
signal demo_started()
signal demo_ended()
signal level_changed(new_level: int)
signal level_completed(level: int)
signal all_levels_completed()

# Difficulty settings with MECHANIC CHANGES (not just numbers)
var difficulty_settings = {
	Difficulty.EASY: {
		# Mechanic change 1: Simple random AI
		"enemy_ai_type": "random",
		"enemy_can_track_player": false,
		"enemy_can_predict": false,
		# Mechanic change 2: Player can pass through walls (training mode)
		"player_can_pass_walls": true,
		"player_invincible": true,
		# Numbers
		"enemy_speed": 60,
		"enemy_fire_rate": 0.2,
		"enemy_count": 10,
		"player_lives": 999
	},
	Difficulty.NORMAL: {
		# Mechanic change 1: Enemies seek base
		"enemy_ai_type": "seek_base",
		"enemy_can_track_player": false,
		"enemy_can_predict": false,
		# Mechanic change 2: Normal collision rules
		"player_can_pass_walls": false,
		"player_invincible": false,
		# Numbers
		"enemy_speed": 80,
		"enemy_fire_rate": 0.5,
		"enemy_count": 20,
		"player_lives": 3
	},
	Difficulty.HARD: {
		# Mechanic change 1: Enemies actively track player with prediction
		"enemy_ai_type": "seek_player",
		"enemy_can_track_player": true,
		"enemy_can_predict": true,
		# Mechanic change 2: Enemy bullets penetrate bricks (steel still blocks)
		"enemy_bullet_penetrate_bricks": true,
		"player_can_pass_walls": false,
		"player_invincible": false,
		# Numbers
		"enemy_speed": 100,
		"enemy_fire_rate": 0.8,
		"enemy_count": 25,
		"player_lives": 2
	}
}

func _ready():
	print("🎮 GameManager initialized")

func change_state(new_state: GameState) -> void:
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(new_state)
		print("🔄 Game state changed to: ", get_state_name(new_state))

func get_state_name(state: GameState) -> String:
	match state:
		GameState.MENU: return "MENU"
		GameState.PLAYING: return "PLAYING"
		GameState.PAUSED: return "PAUSED"
		GameState.GAME_OVER: return "GAME_OVER"
		GameState.VICTORY: return "VICTORY"
	return "UNKNOWN"

func set_difficulty(difficulty: Difficulty) -> void:
	current_difficulty = difficulty
	var settings = difficulty_settings[difficulty]
	
	# Apply settings
	total_enemies = settings.enemy_count
	player_lives = settings.player_lives
	
	difficulty_changed.emit(difficulty)
	print("🎯 Difficulty set to: ", get_difficulty_name(difficulty))

func get_difficulty_name(difficulty: Difficulty) -> String:
	match difficulty:
		Difficulty.EASY: return "EASY"
		Difficulty.NORMAL: return "NORMAL"
		Difficulty.HARD: return "HARD"
	return "UNKNOWN"

func get_current_difficulty_settings() -> Dictionary:
	return difficulty_settings[current_difficulty]

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

func take_life() -> void:
	if current_difficulty == Difficulty.EASY:
		return  # Infinite lives in easy mode
	
	player_lives -= 1
	lives_changed.emit(player_lives)
	
	if player_lives <= 0:
		game_over()

func on_enemy_defeated() -> void:
	enemies_defeated += 1
	add_score(100)
	enemy_destroyed.emit()
	
	check_victory()

func check_victory() -> void:
	if enemies_defeated >= total_enemies:
		victory()

func game_over() -> void:
	change_state(GameState.GAME_OVER)
	print("💀 Game Over! Final score: ", score)

func victory() -> void:
	change_state(GameState.VICTORY)
	print("🏆 Victory! Final score: ", score)
	
	# Check if there are more levels
	if current_level < max_levels:
		is_level_completed = true
		level_completed.emit(current_level)
	else:
		all_levels_completed.emit()
		print("🎉 All levels completed! Congratulations!")

# Level Management
func start_level(level: int) -> void:
	if level < 1 or level > max_levels:
		push_error("GameManager: Invalid level number " + str(level))
		return
	
	current_level = level
	level_changed.emit(current_level)
	
	print("🎮 Starting level ", current_level)
	
	# Reset game state for new level
	reset_game()
	
	# Change to game scene
	change_scene("res://scenes/game.tscn")
	
	# Start playing
	change_state(GameState.PLAYING)

func next_level() -> void:
	if current_level < max_levels:
		start_level(current_level + 1)
	else:
		print("🎉 All levels completed!")
		all_levels_completed.emit()

func restart_level() -> void:
	start_level(current_level)

func set_level(level: int) -> void:
	if level >= 1 and level <= max_levels:
		current_level = level
		level_changed.emit(current_level)

func reset_game() -> void:
	score = 0
	enemies_spawned = 0
	enemies_defeated = 0
	var settings = get_current_difficulty_settings()
	player_lives = settings.player_lives
	
	score_changed.emit(0)
	lives_changed.emit(player_lives)

func start_game() -> void:
	# Start from level 1
	current_level = 1
	reset_game()
	change_state(GameState.PLAYING)
	print("🎮 Game started!")

func start_demo() -> void:
	print("🎬 Starting Demo Mode...")
	is_demo_mode = true
	
	# 保存当前难度
	demo_difficulty = current_difficulty
	
	# 设置 EASY 难度演示（玩家无敌，不会死亡）
	set_difficulty(Difficulty.EASY)
	
	# 重置游戏状态
	reset_game()
	
	# 切换到游戏场景
	change_scene("res://scenes/game.tscn")
	
	# 切换到 PLAYING 状态
	change_state(GameState.PLAYING)
	
	demo_started.emit()

func stop_demo() -> void:
	print("🛑 Stopping Demo Mode...")
	is_demo_mode = false
	
	# 恢复之前的难度
	set_difficulty(demo_difficulty)
	
	# 重置游戏状态
	change_state(GameState.MENU)
	
	# 返回主菜单
	change_scene("res://scenes/main_menu.tscn")
	
	demo_ended.emit()

func change_scene(scene_path: String) -> void:
	# 延迟一帧执行场景切换，避免在物理处理中切换
	call_deferred("_deferred_change_scene", scene_path)

func _deferred_change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)