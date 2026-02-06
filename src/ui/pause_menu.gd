class_name PauseMenu
extends Control

@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var main_menu_button: Button = $Panel/VBoxContainer/MainMenuButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

func _ready():
	print("⏸️ PauseMenu ready")
	
	# Connect buttons
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Register with pause manager
	PauseManager.set_pause_menu(self)
	
	# Hide initially
	visible = false

func _on_resume_pressed():
	AudioManager.play_ui_click()
	PauseManager.toggle_pause()

func _on_restart_pressed():
	AudioManager.play_ui_click()
	PauseManager.toggle_pause()
	GameManager.reset_game()
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	AudioManager.play_ui_click()
	PauseManager.toggle_pause()
	GameManager.change_state(GameManager.GameState.MENU)

func _on_quit_pressed():
	AudioManager.play_ui_click()
	get_tree().quit()
