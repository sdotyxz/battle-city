class_name EnemyTank
extends CharacterBody2D

# AI Types
enum AIType { RANDOM, SEEK_BASE, SEEK_PLAYER }
var ai_type: AIType = AIType.RANDOM

# Movement
var speed: float = 80.0
var direction: Vector2 = Vector2.DOWN
var can_move: bool = true

# Shooting
var bullet_speed: float = 250.0
var shoot_cooldown: float = 1.0
var can_shoot: bool = true
var shoot_timer: Timer = null

# Health
var max_health: int = 1
var current_health: int = 1

# State
var is_alive: bool = true
var is_frozen: bool = false

# AI timing
var decision_timer: Timer = null
var decision_interval: float = 1.5

# Difficulty settings cache
var can_track_player: bool = false
var can_predict: bool = false

# Signals
signal enemy_died(enemy: EnemyTank)
signal bullet_spawned(bullet: Bullet)

# Nodes
@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_point: Marker2D = $ShootPoint
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("enemies")
	
	# Create shoot timer
	shoot_timer = Timer.new()
	shoot_timer.wait_time = shoot_cooldown
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_cooldown_finished)
	shoot_timer.add_to_group("pausable_timers")
	add_child(shoot_timer)
	
	# Create decision timer for AI
	decision_timer = Timer.new()
	decision_timer.wait_time = decision_interval
	decision_timer.timeout.connect(_make_ai_decision)
	decision_timer.add_to_group("pausable_timers")
	add_child(decision_timer)
	
	# Apply difficulty settings
	_apply_difficulty_settings()
	
	# Start AI
	decision_timer.start()
	_make_ai_decision()

func _apply_difficulty_settings():
	var settings = GameManager.get_current_difficulty_settings()
	
	# Set AI type based on difficulty
	match settings.enemy_ai_type:
		"random":
			ai_type = AIType.RANDOM
		"seek_base":
			ai_type = AIType.SEEK_BASE
		"seek_player":
			ai_type = AIType.SEEK_PLAYER
	
	# Set stats
	speed = settings.enemy_speed
	shoot_cooldown = 1.0 / settings.enemy_fire_rate
	can_track_player = settings.enemy_can_track_player
	can_predict = settings.enemy_can_predict
	
	# Update timer
	if shoot_timer:
		shoot_timer.wait_time = shoot_cooldown
	
	# Adjust health based on difficulty
	match GameManager.current_difficulty:
		GameManager.Difficulty.EASY:
			max_health = 1
		GameManager.Difficulty.NORMAL:
			max_health = 1
		GameManager.Difficulty.HARD:
			max_health = 2
	
	current_health = max_health

func _physics_process(delta):
	if not is_alive or PauseManager.is_game_paused():
		return
	
	# Move
	if can_move:
		velocity = direction * speed
		move_and_slide()
		
		# Check if stuck (collision)
		if is_on_wall():
			_change_direction()
	
	# Random shooting
	if can_shoot and randf() < 0.02:
		shoot()

func _make_ai_decision():
	if not is_alive or PauseManager.is_game_paused():
		return
	
	match ai_type:
		AIType.RANDOM:
			_random_ai()
		AIType.SEEK_BASE:
			_seek_base_ai()
		AIType.SEEK_PLAYER:
			_seek_player_ai()

func _random_ai():
	# Random movement direction
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	direction = directions[randi() % directions.size()]
	_update_sprite_direction()

func _seek_base_ai():
	# Move towards base
	if GameManager.base_position == Vector2.ZERO:
		_random_ai()
		return
	
	var to_base = GameManager.base_position - global_position
	
	# Choose primary direction towards base
	if abs(to_base.x) > abs(to_base.y):
		direction = Vector2.RIGHT if to_base.x > 0 else Vector2.LEFT
	else:
		direction = Vector2.DOWN if to_base.y > 0 else Vector2.UP
	
	_update_sprite_direction()
	
	# Shoot more often when aligned with base
	if _is_aligned_with(GameManager.base_position):
		shoot()

func _seek_player_ai():
	# Move towards player
	if GameManager.player_tank == null or not GameManager.player_tank.is_alive:
		_seek_base_ai()
		return
	
	var player_pos = GameManager.player_tank.global_position
	var to_player = player_pos - global_position
	
	if can_track_player:
		# Direct tracking
		if can_predict:
			# Simple prediction based on player movement
			var player_vel = GameManager.player_tank.velocity
			to_player += player_vel * 0.3
		
		# Choose direction
		if abs(to_player.x) > abs(to_player.y):
			direction = Vector2.RIGHT if to_player.x > 0 else Vector2.LEFT
		else:
			direction = Vector2.DOWN if to_player.y > 0 else Vector2.UP
	else:
		# Simple approach
		if randf() < 0.5:
			direction = Vector2.RIGHT if to_player.x > 0 else Vector2.LEFT
		else:
			direction = Vector2.DOWN if to_player.y > 0 else Vector2.UP
	
	_update_sprite_direction()
	
	# Shoot when aligned with player
	if _is_aligned_with(player_pos):
		shoot()

func _is_aligned_with(target_pos: Vector2) -> bool:
	# Check if we're roughly aligned horizontally or vertically with target
	var threshold = 16.0  # Half tile size
	
	var aligned_x = abs(global_position.x - target_pos.x) < threshold
	var aligned_y = abs(global_position.y - target_pos.y) < threshold
	
	# Also check if facing towards target
	if aligned_x:
		var dy = target_pos.y - global_position.y
		return (dy > 0 and direction == Vector2.DOWN) or (dy < 0 and direction == Vector2.UP)
	
	if aligned_y:
		var dx = target_pos.x - global_position.x
		return (dx > 0 and direction == Vector2.RIGHT) or (dx < 0 and direction == Vector2.LEFT)
	
	return false

func _change_direction():
	# Pick a new random direction
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	# Prefer directions away from wall
	var valid_directions = []
	for d in directions:
		if d != -direction:  # Don't go back immediately
			valid_directions.append(d)
	
	if valid_directions.size() > 0:
		direction = valid_directions[randi() % valid_directions.size()]
	else:
		direction = directions[randi() % directions.size()]
	
	_update_sprite_direction()

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
	if not can_shoot:
		return
	
	can_shoot = false
	shoot_timer.start()
	
	# Spawn bullet
	var bullet = BulletPool.get_bullet()
	bullet.global_position = shoot_point.global_position
	bullet.direction = direction
	bullet.speed = bullet_speed
	bullet.owner_type = "enemy"
	
	# Hard mode: enemy bullets can penetrate bricks
	var settings = GameManager.get_current_difficulty_settings()
	bullet.can_penetrate_bricks = settings.get("enemy_bullet_penetrate_bricks", false)
	
	# Add to scene
	get_tree().current_scene.get_node("Bullets").add_child(bullet)
	
	# Play sound
	AudioManager.play_shoot()
	
	# Emit signal
	bullet_spawned.emit(bullet)

func _on_shoot_cooldown_finished():
	can_shoot = true

func take_damage(damage: int = 1):
	if not is_alive:
		return
	
	current_health -= damage
	
	# Visual feedback
	_flash_damage()
	
	if current_health <= 0:
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
	
	# Stop timers
	if decision_timer:
		decision_timer.stop()
	if shoot_timer:
		shoot_timer.stop()
	
	# Notify game manager
	GameManager.on_enemy_defeated()
	
	# Spawn explosion
	_explode()
	
	# Emit signal
	enemy_died.emit(self)
	
	# Queue free after explosion
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _explode():
	# Create explosion effect
	AudioManager.play_explosion(true)
	
	# TODO: Spawn explosion particles/animation
	# For now, simple visual feedback
	var explosion = ColorRect.new()
	explosion.color = Color.ORANGE
	explosion.size = Vector2(32, 32)
	explosion.position = Vector2(-16, -16)
	add_child(explosion)
	
	var tween = create_tween()
	tween.tween_property(explosion, "scale", Vector2(2, 2), 0.3)
	tween.tween_property(explosion, "modulate:a", 0, 0.2)
	tween.finished.connect(explosion.queue_free)

func _on_area_entered(area: Area2D):
	if area is Bullet and area.owner_type == "player":
		take_damage()
		area.destroy()
