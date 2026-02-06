extends Node

# PauseManager - Singleton for handling game pause
# Ensures COMPLETE state freeze as required by the jam

var pause_menu: Control = null
var is_paused: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # Keep processing when paused
	print("⏸️ PauseManager initialized")

func _input(event):
	if event.is_action_pressed("pause"):
		if GameManager.current_state == GameManager.GameState.PLAYING or \
		   GameManager.current_state == GameManager.GameState.PAUSED:
			toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	
	if is_paused:
		_on_pause()
	else:
		_on_resume()

func _on_pause() -> void:
	print("⏸️ Game paused")
	
	# 1. Pause the entire scene tree
	get_tree().paused = true
	
	# 2. Show pause menu
	if pause_menu:
		pause_menu.visible = true
		pause_menu.resume_button.grab_focus()
	
	# 3. Pause all timers in pausable_timers group
	for timer in get_tree().get_nodes_in_group("pausable_timers"):
		if timer is Timer:
			timer.paused = true
	
	# 4. Pause all animations in pausable_animations group
	for anim in get_tree().get_nodes_in_group("pausable_animations"):
		if anim is AnimationPlayer:
			anim.pause()
		elif anim is AnimatedSprite2D:
			anim.pause()
	
	# 5. Pause all particle effects in pausable_particles group
	for particles in get_tree().get_nodes_in_group("pausable_particles"):
		if particles is CPUParticles2D or particles is GPUParticles2D:
			particles.emitting = false
	
	# 6. Update game state
	GameManager.change_state(GameManager.GameState.PAUSED)

func _on_resume() -> void:
	print("▶️ Game resumed")
	
	# 1. Unpause the scene tree
	get_tree().paused = false
	
	# 2. Hide pause menu
	if pause_menu:
		pause_menu.visible = false
	
	# 3. Resume all timers
	for timer in get_tree().get_nodes_in_group("pausable_timers"):
		if timer is Timer:
			timer.paused = false
	
	# 4. Resume all animations
	for anim in get_tree().get_nodes_in_group("pausable_animations"):
		if anim is AnimationPlayer:
			anim.play()
		elif anim is AnimatedSprite2D:
			anim.play()
	
	# 5. Resume all particle effects
	for particles in get_tree().get_nodes_in_group("pausable_particles"):
		if particles is CPUParticles2D or particles is GPUParticles2D:
			particles.emitting = true
	
	# 6. Update game state
	GameManager.change_state(GameManager.GameState.PLAYING)

func is_game_paused() -> bool:
	return is_paused

func set_pause_menu(menu: Control) -> void:
	pause_menu = menu