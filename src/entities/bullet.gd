class_name Bullet
extends Area2D

@export var speed: float = 300.0
@export var damage: int = 1

var direction: Vector2 = Vector2.ZERO
var owner_type: String = ""  # "player" or "enemy"
var is_alive: bool = true
var can_penetrate_bricks: bool = false  # For hard mode enemy bullets

@onready var sprite: Sprite2D = $Sprite2D
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("pausable_timers")
	
	# Setup lifetime timer
	lifetime_timer.wait_time = 3.0
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	lifetime_timer.start()
	
	# Connect collision
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	if PauseManager.is_game_paused():
		return
	
	if not is_alive:
		return
	
	# Move bullet
	position += direction * speed * delta

func _on_body_entered(body: Node2D):
	if not is_alive:
		return
	
	# Check collision with walls (StaticBody2D)
	if body.get_meta("wall_type", "") != "":
		_handle_wall_collision_body(body)
		return
	
	# Check collision with base
	if body.is_in_group("base"):
		body.take_damage(damage)
		destroy()
		return
	
	# Check collision with tanks
	if body.is_in_group("player") and owner_type == "enemy":
		body.take_damage()
		destroy()
		return
	
	if body.is_in_group("enemies") and owner_type == "player":
		body.take_damage(damage)
		destroy()
		return

func _handle_wall_collision_body(wall: Node2D):
	var is_destructible = wall.get_meta("destructible", false)
	var is_steel = wall.get_meta("steel", false)
	
	if is_steel:
		# Steel walls always block
		destroy()
	elif is_destructible:
		# Brick walls
		if can_penetrate_bricks and owner_type == "enemy":
			# Hard mode: enemy bullets penetrate bricks
			AudioManager.play_explosion(false)
			# Destroy wall but keep bullet
			if wall.has_method("queue_free"):
				wall.queue_free()
		else:
			# Normal: destroy wall and bullet
			AudioManager.play_explosion(false)
			if wall.has_method("queue_free"):
				wall.queue_free()
			destroy()

func _on_area_entered(area: Area2D):
	if not is_alive:
		return
	
	# Check collision with walls (new Area2D-based walls)
	if area.get_meta("wall_type", "") != "":
		_handle_wall_collision_area(area)
		return
	
	# Bullet vs bullet collision
	if area is Bullet:
		destroy()
		area.destroy()

func _handle_wall_collision(wall: TileMapLayer):
	# Deprecated: Now using Area2D-based walls
	pass

func _handle_wall_collision_area(wall: Area2D):
	var is_destructible = wall.get_meta("destructible", false)
	var is_steel = wall.get_meta("steel", false)
	
	if is_steel:
		# Steel walls always block
		destroy()
	elif is_destructible:
		# Brick walls
		if can_penetrate_bricks and owner_type == "enemy":
			# Hard mode: enemy bullets penetrate bricks
			# The wall will be destroyed by WallSystem
			AudioManager.play_explosion(false)
			# Don't destroy bullet, let it continue
		else:
			# Normal: destroy wall and bullet
			# The wall will be destroyed by WallSystem
			AudioManager.play_explosion(false)
			destroy()

func _on_lifetime_timeout():
	destroy()

func destroy():
	if not is_alive:
		return
	
	is_alive = false
	
	# Return to pool instead of freeing
	BulletPool.return_bullet(self)

func reset():
	is_alive = true
	can_penetrate_bricks = false
	direction = Vector2.ZERO
	position = Vector2.ZERO
	
	if lifetime_timer:
		lifetime_timer.stop()
		lifetime_timer.start()