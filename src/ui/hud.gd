class_name HUD
extends CanvasLayer

# UI References
@onready var score_label: Label = $MarginContainer/VBoxContainer/TopBar/ScoreContainer/ScoreLabel
@onready var lives_label: Label = $MarginContainer/VBoxContainer/TopBar/LivesContainer/LivesLabel
@onready var enemies_label: Label = $MarginContainer/VBoxContainer/TopBar/EnemiesContainer/EnemiesLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var victory_panel: Panel = $VictoryPanel

func _ready():
	print("🎯 HUD ready")
	
	# Connect to game manager signals
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.state_changed.connect(_on_state_changed)
	
	# Hide game over / victory panels
	game_over_panel.visible = false
	victory_panel.visible = false
	
	# Initial update
	_update_all()

func _update_all():
	_on_score_changed(GameManager.score)
	_on_lives_changed(GameManager.player_lives)
	_update_enemies_remaining()

func _on_score_changed(new_score: int):
	score_label.text = "SCORE: %06d" % new_score

func _on_lives_changed(new_lives: int):
	lives_label.text = "LIVES: %d" % new_lives

func _update_enemies_remaining():
	var remaining = GameManager.total_enemies - GameManager.enemies_defeated
	enemies_label.text = "ENEMIES: %d" % remaining

func _on_state_changed(new_state: GameManager.GameState):
	match new_state:
		GameManager.GameState.PLAYING:
			game_over_panel.visible = false
			victory_panel.visible = false
		GameManager.GameState.GAME_OVER:
			_show_game_over()
		GameManager.GameState.VICTORY:
			_show_victory()

func _show_game_over():
	game_over_panel.visible = true
	var final_score = game_over_panel.get_node("VBoxContainer/FinalScoreLabel")
	if final_score:
		final_score.text = "Final Score: %d" % GameManager.score

func _show_victory():
	victory_panel.visible = true
	var final_score = victory_panel.get_node("VBoxContainer/FinalScoreLabel")
	if final_score:
		final_score.text = "Final Score: %d" % GameManager.score

func _on_restart_button_pressed():
	GameManager.reset_game()
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed():
	GameManager.change_state(GameManager.GameState.MENU)

func _process(_delta):
	# Update enemies remaining every frame (since it depends on spawn manager)
	if GameManager.current_state == GameManager.GameState.PLAYING:
		_update_enemies_remaining()
