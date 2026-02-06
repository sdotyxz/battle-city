extends Control

@onready var easy_button: Button = $MarginContainer/VBoxContainer/DifficultyContainer/EasyButton
@onready var normal_button: Button = $MarginContainer/VBoxContainer/DifficultyContainer/NormalButton
@onready var hard_button: Button = $MarginContainer/VBoxContainer/DifficultyContainer/HardButton
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var demo_button: Button = $MarginContainer/VBoxContainer/DemoButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/QuitButton
@onready var difficulty_label: Label = $MarginContainer/VBoxContainer/DifficultyLabel

var selected_difficulty: GameManager.Difficulty = GameManager.Difficulty.NORMAL

func _ready():
	print("🎮 MainMenu ready")
	
	# Connect difficulty buttons
	easy_button.pressed.connect(_on_easy_pressed)
	normal_button.pressed.connect(_on_normal_pressed)
	hard_button.pressed.connect(_on_hard_pressed)
	
	# Connect action buttons
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect demo button
	if demo_button:
		demo_button.pressed.connect(_on_demo_pressed)
	
	# Update UI
	_update_difficulty_ui()
	
	# Make sure game state is MENU
	GameManager.change_state(GameManager.GameState.MENU)
	
	# Check for command line arguments (--demo)
	_check_command_line_args()

func _on_easy_pressed():
	AudioManager.play_ui_click()
	selected_difficulty = GameManager.Difficulty.EASY
	_update_difficulty_ui()

func _on_normal_pressed():
	AudioManager.play_ui_click()
	selected_difficulty = GameManager.Difficulty.NORMAL
	_update_difficulty_ui()

func _on_hard_pressed():
	AudioManager.play_ui_click()
	selected_difficulty = GameManager.Difficulty.HARD
	_update_difficulty_ui()

func _update_difficulty_ui():
	# Update label
	match selected_difficulty:
		GameManager.Difficulty.EASY:
			difficulty_label.text = "Difficulty: EASY (Training Mode)"
			difficulty_label.add_theme_color_override("font_color", Color.GREEN)
		GameManager.Difficulty.NORMAL:
			difficulty_label.text = "Difficulty: NORMAL"
			difficulty_label.add_theme_color_override("font_color", Color.YELLOW)
		GameManager.Difficulty.HARD:
			difficulty_label.text = "Difficulty: HARD"
			difficulty_label.add_theme_color_override("font_color", Color.RED)
	
	# Update button styles
	easy_button.disabled = (selected_difficulty == GameManager.Difficulty.EASY)
	normal_button.disabled = (selected_difficulty == GameManager.Difficulty.NORMAL)
	hard_button.disabled = (selected_difficulty == GameManager.Difficulty.HARD)

func _on_start_pressed():
	AudioManager.play_ui_click()
	
	# Set difficulty
	GameManager.set_difficulty(selected_difficulty)
	
	# Start game
	GameManager.start_game()
	
	# Change to game scene
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_pressed():
	AudioManager.play_ui_click()
	get_tree().quit()

func _on_demo_pressed():
	AudioManager.play_ui_click()
	print("🎬 Starting demo from menu...")
	
	# Start demo mode
	GameManager.start_demo()

func _check_command_line_args():
	var args = OS.get_cmdline_args()
	print("📋 Command line args: ", args)
	
	if args.has("--demo") or args.has("-demo"):
		print("🎬 Auto-starting demo mode from command line...")
		# 延迟一点确保场景完全加载
		await get_tree().create_timer(0.5).timeout
		GameManager.start_demo()
