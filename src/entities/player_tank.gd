class_name PlayerTank
extends CharacterBody2D

# Movement
@export var speed: float = 100.0
var direction: Vector2 = Vector2.UP

# Shooting
@export var bullet_speed: float = 300.0
@export var shoot_cooldown: float = 0.5
var can_shoot: bool = true
var current_bullets: int = 0
const MAX_BULLETS: int = 1

# State
var is_alive: bool = true
var lives: int = 3

# Difficulty settings cache
var can_pass_walls: bool = false
var is_invincible: bool = false

# AI Control
var is_ai_controlled: bool = false
var ai_direction: Vector2 = Vector2.ZERO

# Signals
signal player_died()
signal bullet_spawned(bullet: Bullet)

# Nodes
@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_point: Marker2D = $ShootPoint
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("player")
	
	# Setup cooldown timer
	cooldown_timer.wait_time = shoot_cooldown
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_finished)
	cooldown_timer.add_to_group("pausable_timers")
	
	# Apply difficulty settings
	_apply_difficulty_settings()
	
	# Connect to difficulty changes
	GameManager.difficulty_changed.connect(_on_difficulty_changed)

func _apply_difficulty_settings():
	var settings = GameManager.get_current_difficulty_settings()
	can_pass_walls = settings.player_can_pass_walls
	is_invincible = settings.player_invincible
	
	# Adjust collision based on difficulty
	if can_pass_walls:
		# Disable collision with walls (layer 5)
		set_collision_mask_value(5, false)
	else:
		set_collision_mask_value(5, true)

func _on_difficulty_changed(_new_difficulty: int):
	_apply_difficulty_settings()

func _physics_process(delta):
	if not is_alive or PauseManager.is_game_paused():
		return
	
	if is_ai_controlled:
		# AI 控制模式 - 由 DemoManager 控制
		_handle_ai_movement()
	else:
		# 玩家控制模式
		_handle_movement()
		
		# Handle shooting (仅玩家控制)
		if Input.is_action_just_pressed("shoot"):
			shoot()
	
	# Move
	move_and_slide()

func set_ai_controlled(enabled: bool) -> void:
	is_ai_controlled = enabled
	if enabled:
		velocity = Vector2.ZERO

func set_direction(dir: Vector2) -> void:
	if not is_ai_controlled:
		return
	
	ai_direction = dir
	if dir != Vector2.ZERO:
		direction = dir
		_update_sprite_direction()

func _handle_ai_movement():
	if ai_direction != Vector2.ZERO:
		velocity = ai_direction * speed
	else:
		velocity = Vector2.ZERO

func _handle_movement():
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		input_dir = Vector2.UP
	elif Input.is_action_pressed("move_down"):
		input_dir = Vector2.DOWN
	elif Input.is_action_pressed("move_left"):
		input_dir = Vector2.LEFT
	elif Input.is_action_pressed("move_right"):
		input_dir = Vector2.RIGHT
	
	if input_dir != Vector2.ZERO:
		direction = input_dir
		velocity = direction * speed
		_update_sprite_direction()
	else:
		velocity = Vector2.ZERO

func _update_sprite_direction():
	# Rotate sprite based on direction
	match direction:
		Vector2.UP:
			sprite.rotation_degrees = 0
		Vector2.DOWN:
			sprite.rotation_degrees = 180
		Vector2.LEFT:
			sprite.rotation_degrees = -90
		Vector2.RIGHT:
			sprite.rotation_degrees = 90

func shoot():
	if not can_shoot or current_bullets >= MAX_BULLETS:
		return
	
	can_shoot = false
	cooldown_timer.start()
	
	# Spawn bullet
	var bullet = BulletPool.get_bullet()
	bullet.global_position = shoot_point.global_position
	bullet.direction = direction
	bullet.speed = bullet_speed
	bullet.owner_type = "player"
	
	# Add to scene
	get_tree().current_scene.get_node("Bullets").add_child(bullet)
	
	current_bullets += 1
	bullet.tree_exited.connect(_on_bullet_destroyed)
	
	# Play sound
	AudioManager.play_shoot()
	
	# Emit signal
	bullet_spawned.emit(bullet)

func _on_cooldown_finished():
	can_shoot = true

func _on_bullet_destroyed():
	current_bullets -= 1

func take_damage():
	if is_invincible or not is_alive:
		return
	
	lives -= 1
	GameManager.take_life()
	
	# Visual feedback
	_flash_damage()
	
	if lives <= 0:
		die()

func _flash_damage():
	# Simple flash effect
	var tween = create_tween()
	sprite.modulate = Color.RED
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func die():
	is_alive = false
	visible = false
	collision_shape.disabled = true
	
	player_died.emit()
	
	# Spawn explosion effect
	_explode()
	
	# Check game over
	if GameManager.player_lives <= 0:
		GameManager.game_over()

func _explode():
	# Create explosion effect
	AudioManager.play_explosion(true)
	
	# TODO: Spawn explosion particles/animation

func respawn():
	if GameManager.player_lives > 0:
		is_alive = true
		visible = true
		collision_shape.disabled = false
		
		# Reset position
		if GameManager.player_tank == self:
			# Return to spawn point
			global_position = GameManager.base_position + Vector2(0, 64)

func _on_area_entered(area: Area2D):
	if area is Bullet and area.owner_type == "enemy":
		take_damage()
		area.destroy()