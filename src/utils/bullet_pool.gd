extends Node

# BulletPool - Object pooling for bullets to improve performance
# Prevents frequent instantiation/destruction of bullets

var bullet_scene: PackedScene = preload("res://src/entities/bullet.tscn")
var pool: Array = []  # Use generic Array to avoid circular dependency
var active_bullets: Array = []
var pool_size: int = 20

func _ready():
	print("🔄 BulletPool initialized")
	
	# Pre-create bullet objects
	for i in range(pool_size):
		var bullet = bullet_scene.instantiate()
		bullet.visible = false
		bullet.process_mode = Node.PROCESS_MODE_DISABLED
		pool.append(bullet)
		add_child(bullet)

func get_bullet() -> Node:
	if pool.size() > 0:
		var bullet = pool.pop_back()
		bullet.visible = true
		bullet.process_mode = Node.PROCESS_MODE_INHERIT
		bullet.reset()
		active_bullets.append(bullet)
		return bullet
	else:
		# Pool exhausted - create new one (performance hit)
		push_warning("Bullet pool exhausted! Creating new bullet.")
		var bullet = bullet_scene.instantiate()
		add_child(bullet)
		active_bullets.append(bullet)
		return bullet

func return_bullet(bullet: Node) -> void:
	if bullet in active_bullets:
		active_bullets.erase(bullet)
	
	bullet.reset()
	bullet.visible = false
	bullet.process_mode = Node.PROCESS_MODE_DISABLED
	bullet.position = Vector2.ZERO
	
	# Only return to pool if not full
	if pool.size() < pool_size:
		pool.append(bullet)
	else:
		# Pool full, destroy extra
		bullet.queue_free()

func clear_all_bullets() -> void:
	for bullet in active_bullets.duplicate():
		return_bullet(bullet)