class_name DemoManager
extends Node

# AI 控制状态
enum DemoState { MOVING, SHOOTING, IDLE, AIMING }
var current_state: DemoState = DemoState.IDLE

# 控制对象
var player: PlayerTank
var game: Node2D

# 计时器
var change_action_timer: Timer
var demo_timer: Timer

# 演示持续时间
var demo_duration: float = 30.0

# AI 行为参数
var move_timer: float = 0.0
var move_duration: float = 2.0
var shoot_cooldown: float = 0.0
var target_enemy: Node2D = null

func _ready():
	print("🎮 DemoManager initialized")
	
	# 创建动作切换计时器
	change_action_timer = Timer.new()
	change_action_timer.timeout.connect(_change_action)
	add_child(change_action_timer)
	change_action_timer.start(randf_range(1.0, 3.0))
	
	# 创建演示结束计时器
	demo_timer = Timer.new()
	demo_timer.wait_time = demo_duration
	demo_timer.one_shot = true
	demo_timer.timeout.connect(_on_demo_finished)
	add_child(demo_timer)
	demo_timer.start()
	
	print("⏱️ Demo will run for ", demo_duration, " seconds")

func setup(p_player: PlayerTank, p_game: Node2D) -> void:
	player = p_player
	game = p_game
	
	if player:
		# 启用 AI 控制
		player.set_ai_controlled(true)
		print("🤖 AI control enabled for player")

func _change_action():
	# 智能 AI 行为选择
	var enemies = _get_enemies()
	
	if enemies.size() > 0 and randf() < 0.6:  # 60% 概率瞄准敌人
		target_enemy = _get_nearest_enemy(enemies)
		current_state = DemoState.AIMING
	elif randf() < 0.3:  # 30% 概率移动
		current_state = DemoState.MOVING
	elif randf() < 0.5:  # 50% 概率射击
		current_state = DemoState.SHOOTING
	else:
		current_state = DemoState.IDLE
	
	# 根据状态执行动作
	match current_state:
		DemoState.MOVING:
			_pick_random_direction()
		DemoState.SHOOTING:
			_try_shoot()
		DemoState.IDLE:
			_set_player_direction(Vector2.ZERO)
		DemoState.AIMING:
			if target_enemy:
				_aim_at_target(target_enemy)
	
	# 设置下一次动作切换时间
	change_action_timer.start(randf_range(0.8, 2.5))

func _physics_process(delta):
	if not player or not is_instance_valid(player):
		return
	
	# 更新射击冷却
	if shoot_cooldown > 0:
		shoot_cooldown -= delta
	
	# 根据状态执行持续行为
	match current_state:
		DemoState.MOVING:
			_move_player(delta)
			# 随机切换方向
			move_timer += delta
			if move_timer >= move_duration:
				_pick_random_direction()
				move_timer = 0.0
				move_duration = randf_range(1.0, 3.0)
			
			# 移动时偶尔射击
			if randf() < 0.02:
				_try_shoot()
			
		DemoState.AIMING:
			if target_enemy and is_instance_valid(target_enemy):
				_aim_at_target(target_enemy)
				if randf() < 0.1:  # 持续瞄准时射击
					_try_shoot()
			else:
				# 目标丢失，重新选择动作
				_change_action()

func _get_enemies() -> Array:
	if not game or not is_instance_valid(game):
		return []
	
	var enemies = []
	var spawn_manager = game.get_node_or_null("SpawnManager")
	if spawn_manager:
		enemies = spawn_manager.get_active_enemies()
	
	# 如果 spawn_manager 没有，尝试从场景树获取
	if enemies.is_empty():
		enemies = get_tree().get_nodes_in_group("enemies")
	
	return enemies

func _get_nearest_enemy(enemies: Array) -> Node2D:
	if enemies.is_empty():
		return null
	
	var nearest = enemies[0]
	var nearest_dist = player.global_position.distance_to(nearest.global_position)
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = player.global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist
	
	return nearest

func _aim_at_target(target: Node2D) -> void:
	if not player or not is_instance_valid(player):
		return
	
	var dir = (target.global_position - player.global_position).normalized()
	
	# 将方向限制为 4 个主要方向
	var cardinal_dir = _get_cardinal_direction(dir)
	_set_player_direction(cardinal_dir)

func _get_cardinal_direction(dir: Vector2) -> Vector2:
	# 选择最接近的主要方向
	if abs(dir.x) > abs(dir.y):
		return Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if dir.y > 0 else Vector2.UP

func _pick_random_direction():
	var dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	_set_player_direction(dirs[randi() % dirs.size()])

func _set_player_direction(dir: Vector2) -> void:
	if player and is_instance_valid(player):
		player.set_direction(dir)

func _move_player(delta: float) -> void:
	if player and is_instance_valid(player):
		player.velocity = player.direction * player.speed
		player.move_and_slide()

func _try_shoot() -> void:
	if shoot_cooldown <= 0 and player and is_instance_valid(player):
		player.shoot()
		shoot_cooldown = 0.3  # 射击冷却

func _on_demo_finished():
	print("⏱️ Demo finished!")
	GameManager.stop_demo()

func cleanup() -> void:
	if player and is_instance_valid(player):
		player.set_ai_controlled(false)
		print("🤖 AI control disabled")
