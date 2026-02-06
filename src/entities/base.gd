class_name Base
extends Area2D

# Health
var max_health: int = 1
var current_health: int = 1
var is_destroyed: bool = false

# Visual
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Signals
signal base_destroyed()
signal base_damaged(current_health: int)

func _ready():
	add_to_group("base")
	
	# Setup collision
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Store position in GameManager for enemy AI
	GameManager.base_position = global_position
	
	# Initialize health
	current_health = max_health

func take_damage(damage: int = 1):
	if is_destroyed:
		return
	
	current_health -= damage
	
	# Visual feedback
	_flash_damage()
	
	# Emit signal
	base_damaged.emit(current_health)
	
	if current_health <= 0:
		_destroy()

func _flash_damage():
	# Flash red
	var tween = create_tween()
	sprite.modulate = Color.RED
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _destroy():
	is_destroyed = true
	
	print("💥 Base destroyed! Game Over!")
	
	# Create explosion effect
	_explode()
	
	# Change sprite to destroyed state
	sprite.modulate = Color(0.3, 0.3, 0.3, 1)
	
	# Emit signal
	base_destroyed.emit()
	
	# Trigger game over
	GameManager.game_over()

func _explode():
	# Play explosion sound
	AudioManager.play_explosion(true)
	
	# Create visual explosion effect
	var explosion = ColorRect.new()
	explosion.color = Color.ORANGE
	explosion.size = Vector2(48, 48)
	explosion.position = Vector2(-24, -24)
	add_child(explosion)
	
	var tween = create_tween()
	explosion.scale = Vector2(0.5, 0.5)
	tween.tween_property(explosion, "scale", Vector2(3, 3), 0.5)
	tween.parallel().tween_property(explosion, "modulate:a", 0, 0.5)
	tween.finished.connect(explosion.queue_free)
	
	# Shake effect
	var shake_tween = create_tween()
	for i in range(10):
		var offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		shake_tween.tween_property(sprite, "position", offset, 0.05)
	shake_tween.tween_property(sprite, "position", Vector2.ZERO, 0.05)

func _on_body_entered(body: Node2D):
	# Check if enemy tank touched the base
	if body.is_in_group("enemies"):
		take_damage(1)
		# Destroy the enemy too
		if body.has_method("die"):
			body.die()

func _on_area_entered(area: Area2D):
	# Check if enemy bullet hit the base
	if area is Bullet and area.owner_type == "enemy":
		take_damage(1)
		area.destroy()

func reset():
	is_destroyed = false
	current_health = max_health
	sprite.modulate = Color.WHITE
	collision_shape.disabled = false
