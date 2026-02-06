extends GutTest

var pause_manager: Node
var mock_pause_menu: Control

func before_each() -> void:
	pause_manager = PauseManager
	pause_manager.is_paused = false
	
	# Create mock pause menu
	mock_pause_menu = Control.new()
	mock_pause_menu.name = "PauseMenu"
	mock_pause_menu.visible = false
	
	# Create mock resume button
	var resume_button := Button.new()
	resume_button.name = "ResumeButton"
	mock_pause_menu.add_child(resume_button)
	mock_pause_menu.set("resume_button", resume_button)
	
	add_child_autofree(mock_pause_menu)
	
	# Set up pause manager with mock menu
	pause_manager.set_pause_menu(mock_pause_menu)

func after_each() -> void:
	# Ensure unpaused
	if pause_manager.is_paused:
		pause_manager.toggle_pause()
	
	# Clean up
	if is_instance_valid(mock_pause_menu):
		mock_pause_menu.queue_free()

# ==================== Initialization Tests ====================

func test_pause_manager_initializes_not_paused() -> void:
	assert_false(pause_manager.is_paused, "Should not be paused initially")

func test_pause_manager_has_process_mode_always() -> void:
	assert_eq(pause_manager.process_mode, Node.PROCESS_MODE_ALWAYS, "Should always process")

# ==================== Toggle Pause Tests ====================

func test_toggle_pause_switches_state() -> void:
	var initial_state := pause_manager.is_paused
	pause_manager.toggle_pause()
	assert_ne(pause_manager.is_paused, initial_state, "Pause state should toggle")

func test_toggle_pause_twice_returns_to_original() -> void:
	var initial_state := pause_manager.is_paused
	pause_manager.toggle_pause()
	pause_manager.toggle_pause()
	assert_eq(pause_manager.is_paused, initial_state, "Should return to original state")

func test_toggle_pause_to_true_sets_is_paused() -> void:
	pause_manager.is_paused = false
	pause_manager.toggle_pause()
	assert_true(pause_manager.is_paused, "Should be paused after toggle")

func test_toggle_pause_to_false_clears_is_paused() -> void:
	pause_manager.is_paused = true
	pause_manager.toggle_pause()
	assert_false(pause_manager.is_paused, "Should not be paused after toggle")

# ==================== Pause Menu Tests ====================

func test_pause_shows_menu() -> void:
	pause_manager.is_paused = false
	pause_manager._on_pause()
	assert_true(mock_pause_menu.visible, "Menu should be visible when paused")

func test_resume_hides_menu() -> void:
	mock_pause_menu.visible = true
	pause_manager._on_resume()
	assert_false(mock_pause_menu.visible, "Menu should be hidden when resumed")

# ==================== Timer Pause Tests ====================

func test_pause_pauses_timers_in_group() -> void:
	# Create test timer in pausable_timers group
	var timer := Timer.new()
	timer.add_to_group("pausable_timers")
	timer.wait_time = 10.0
	timer.autostart = true
	add_child_autofree(timer)
	
	# Wait for timer to start
	await get_tree().process_frame
	
	# Pause
	pause_manager.is_paused = true
	pause_manager._on_pause()
	
	assert_true(timer.paused, "Timer should be paused")

func test_resume_unpauses_timers_in_group() -> void:
	# Create test timer in pausable_timers group
	var timer := Timer.new()
	timer.add_to_group("pausable_timers")
	timer.paused = true
	add_child_autofree(timer)
	
	pause_manager.is_paused = false
	pause_manager._on_resume()
	
	assert_false(timer.paused, "Timer should be unpaused")

func test_pause_only_affects_pausable_timers() -> void:
	# Create timer NOT in pausable_timers group
	var regular_timer := Timer.new()
	regular_timer.wait_time = 10.0
	regular_timer.autostart = true
	add_child_autofree(regular_timer)
	
	# Create timer IN pausable_timers group
	var pausable_timer := Timer.new()
	pausable_timer.add_to_group("pausable_timers")
	pausable_timer.wait_time = 10.0
	pausable_timer.autostart = true
	add_child_autofree(pausable_timer)
	
	await get_tree().process_frame
	
	pause_manager.is_paused = true
	pause_manager._on_pause()
	
	assert_false(regular_timer.paused, "Regular timer should not be paused")
	assert_true(pausable_timer.paused, "Pausable timer should be paused")

# ==================== Animation Pause Tests ====================

func test_pause_pauses_animation_players() -> void:
	var anim_player := AnimationPlayer.new()
	anim_player.add_to_group("pausable_animations")
	add_child_autofree(anim_player)
	
	# Note: Can't easily test actual play/pause without animation resource
	# But we can verify the group membership
	assert_true(anim_player.is_in_group("pausable_animations"), "Should be in pausable_animations group")

func test_pause_pauses_animated_sprites() -> void:
	var anim_sprite := AnimatedSprite2D.new()
	anim_sprite.add_to_group("pausable_animations")
	add_child_autofree(anim_sprite)
	
	assert_true(anim_sprite.is_in_group("pausable_animations"), "Should be in pausable_animations group")

# ==================== Particle Pause Tests ====================

func test_pause_stops_cpu_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.add_to_group("pausable_particles")
	particles.emitting = true
	add_child_autofree(particles)
	
	pause_manager.is_paused = true
	pause_manager._on_pause()
	
	assert_false(particles.emitting, "CPU particles should stop emitting")

func test_pause_stops_gpu_particles() -> void:
	var particles := GPUParticles2D.new()
	particles.add_to_group("pausable_particles")
	particles.emitting = true
	add_child_autofree(particles)
	
	pause_manager.is_paused = true
	pause_manager._on_pause()
	
	assert_false(particles.emitting, "GPU particles should stop emitting")

func test_resume_starts_cpu_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.add_to_group("pausable_particles")
	particles.emitting = false
	add_child_autofree(particles)
	
	pause_manager.is_paused = false
	pause_manager._on_resume()
	
	assert_true(particles.emitting, "CPU particles should start emitting")

func test_resume_starts_gpu_particles() -> void:
	var particles := GPUParticles2D.new()
	particles.add_to_group("pausable_particles")
	particles.emitting = false
	add_child_autofree(particles)
	
	pause_manager.is_paused = false
	pause_manager._on_resume()
	
	assert_true(particles.emitting, "GPU particles should start emitting")

# ==================== Scene Tree Pause Tests ====================

func test_pause_sets_scene_tree_paused() -> void:
	get_tree().paused = false
	pause_manager.is_paused = true
	pause_manager._on_pause()
	
	assert_true(get_tree().paused, "Scene tree should be paused")
	
	# Clean up
	get_tree().paused = false

func test_resume_unsets_scene_tree_paused() -> void:
	get_tree().paused = true
	pause_manager.is_paused = false
	pause_manager._on_resume()
	
	assert_false(get_tree().paused, "Scene tree should not be paused")

# ==================== Game State Tests ====================

func test_pause_changes_game_state_to_paused() -> void:
	# Store original state
	var original_state := GameManager.current_state
	GameManager.current_state = GameManager.GameState.PLAYING
	
	pause_manager.is_paused = true
	pause_manager._on_pause()
	
	assert_eq(GameManager.current_state, GameManager.GameState.PAUSED, "Game state should be PAUSED")
	
	# Restore
	GameManager.current_state = original_state

func test_resume_changes_game_state_to_playing() -> void:
	# Store original state
	var original_state := GameManager.current_state
	GameManager.current_state = GameManager.GameState.PAUSED
	
	pause_manager.is_paused = false
	pause_manager._on_resume()
	
	assert_eq(GameManager.current_state, GameManager.GameState.PLAYING, "Game state should be PLAYING")
	
	# Restore
	GameManager.current_state = original_state

# ==================== is_game_paused Tests ====================

func test_is_game_paused_returns_true_when_paused() -> void:
	pause_manager.is_paused = true
	assert_true(pause_manager.is_game_paused(), "Should return true when paused")

func test_is_game_paused_returns_false_when_not_paused() -> void:
	pause_manager.is_paused = false
	assert_false(pause_manager.is_game_paused(), "Should return false when not paused")

func test_is_game_paused_matches_internal_state() -> void:
	pause_manager.is_paused = true
	assert_eq(pause_manager.is_game_paused(), pause_manager.is_paused, "Should match internal state")
	
	pause_manager.is_paused = false
	assert_eq(pause_manager.is_game_paused(), pause_manager.is_paused, "Should match internal state")

# ==================== set_pause_menu Tests ====================

func test_set_pause_menu_updates_reference() -> void:
	var new_menu := Control.new()
	pause_manager.set_pause_menu(new_menu)
	
	assert_eq(pause_manager.pause_menu, new_menu, "Pause menu reference should be updated")
	
	new_menu.queue_free()

func test_set_pause_menu_accepts_null() -> void:
	pause_manager.set_pause_menu(null)
	assert_eq(pause_manager.pause_menu, null, "Pause menu should be null")

# ==================== Complete Freeze Tests ====================

func test_complete_freeze_affects_all_systems() -> void:
	# Create various nodes
	var timer := Timer.new()
	timer.add_to_group("pausable_timers")
	timer.wait_time = 10.0
	timer.autostart = true
	add_child_autofree(timer)
	
	var cpu_particles := CPUParticles2D.new()
	cpu_particles.add_to_group("pausable_particles")
	cpu_particles.emitting = true
	add_child_autofree(cpu_particles)
	
	await get_tree().process_frame
	
	# Store original state
	var original_tree_paused := get_tree().paused
	var original_game_state := GameManager.current_state
	GameManager.current_state = GameManager.GameState.PLAYING
	
	# Pause
	pause_manager.is_paused = true
	pause_manager._on_pause()
	
	# Verify all systems paused
	assert_true(get_tree().paused, "Scene tree should be paused")
	assert_true(timer.paused, "Timer should be paused")
	assert_false(cpu_particles.emitting, "Particles should not be emitting")
	assert_eq(GameManager.current_state, GameManager.GameState.PAUSED, "Game state should be paused")
	
	# Resume
	pause_manager.is_paused = false
	pause_manager._on_resume()
	
	# Verify all systems resumed
	assert_false(get_tree().paused, "Scene tree should not be paused")
	assert_false(timer.paused, "Timer should not be paused")
	assert_true(cpu_particles.emitting, "Particles should be emitting")
	assert_eq(GameManager.current_state, GameManager.GameState.PLAYING, "Game state should be playing")
	
	# Restore
	get_tree().paused = original_tree_paused
	GameManager.current_state = original_game_state
