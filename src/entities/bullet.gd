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
	
	# Check collision with walls (TileMap)
	if body is TileMapLayer:
		_handle_wall_collision(body)
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

func _on_area_entered(area: Area2D):
	if not is_alive:
		return
	
	# Bullet vs bullet collision
	if area is Bullet:
		destroy()
		area.destroy()

func _handle_wall_collision(wall: TileMapLayer):
	var tile_pos = wall.local_to_map(to_local(wall.global_position))
	var tile_data = wall.get_cell_tile_data(tile_pos)
	
	if tile_data == null:
		return
	
	var is_destructible = tile_data.get_custom_data("destructible")
	var is_steel = tile_data.get_custom_data("steel")
	
	if is_steel:
		# Steel walls always block
		destroy()
	elif is_destructible:
		# Brick walls
		if can_penetrate_bricks and owner_type == "enemy":
			# Hard mode: enemy bullets penetrate bricks
			wall.set_cells_terrain_connect([tile_pos], 0, -1)
			AudioManager.play_explosion(false)
			# Don't destroy bullet, let it continue
		else:
			# Normal: destroy wall and bullet
			wall.set_cells_terrain_connect([tile_pos], 0, -1)
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