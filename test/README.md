# Battle City GUT 单元测试

本目录包含 Battle City 游戏的所有 GUT (Godot Unit Test) 测试文件。

## 目录结构

```
test/
├── unit/                          # 单元测试
│   ├── test_game_manager.gd       # GameManager 测试 (P0)
│   ├── test_player_tank.gd        # PlayerTank 测试 (P0)
│   ├── test_bullet.gd             # Bullet 测试 (P0)
│   ├── test_enemy_tank.gd         # EnemyTank 测试 (P1)
│   ├── test_pause_manager.gd      # PauseManager 测试 (P1)
│   ├── test_base.gd               # Base 测试 (P1)
│   ├── test_spawn_manager.gd      # SpawnManager 测试 (P2)
│   └── test_bullet_pool.gd        # BulletPool 测试 (P2)
└── integration/                   # 集成测试
    └── test_battle_flow.gd        # 战斗流程集成测试 (P2)
```

## 优先级说明

### P0 (必须)
- **GameManager**: 难度设置、游戏状态、分数、生命值、游戏结束/胜利条件
- **PlayerTank**: 移动、射击、伤害、难度感知
- **Bullet**: 移动、碰撞检测、穿透逻辑

### P1 (应该)
- **EnemyTank**: AI 状态切换、移动、射击、难度感知
- **PauseManager**: 暂停/恢复、状态冻结
- **Base**: 血量、被摧毁触发游戏结束

### P2 (可选)
- **SpawnManager**: 敌人生成、最大敌人限制、波次控制
- **BulletPool**: 对象池获取/归还、容量限制
- **Integration**: 完整战斗流程测试

## 运行测试

### 在 Godot 编辑器中运行

1. 确保已安装 GUT 插件 (Godot Asset Library 搜索 "GUT")
2. 打开 GUT 面板: `Project > Tools > GUT`
3. 点击 "Run All" 运行所有测试

### 使用命令行运行

```bash
# 使用 Godot 命令行运行测试
/mnt/f/ProgramFiles/Godot/Godot_v4.6-stable_win64_console.exe --path /mnt/f/GodotProjects/BattleCity -s addons/gut/gut_cmdln.gd
```

### 使用 GUT 配置运行

测试配置已保存在 `.gutconfig.json` 中。

## 测试统计

| 测试文件 | 测试数量 | 优先级 |
|---------|---------|--------|
| test_game_manager.gd | 30+ | P0 |
| test_player_tank.gd | 20+ | P0 |
| test_bullet.gd | 20+ | P0 |
| test_enemy_tank.gd | 25+ | P1 |
| test_pause_manager.gd | 20+ | P1 |
| test_base.gd | 20+ | P1 |
| test_spawn_manager.gd | 15+ | P2 |
| test_bullet_pool.gd | 15+ | P2 |
| test_battle_flow.gd | 15+ | P2 |

**总计: 约 180+ 个测试用例**

## 测试规范

所有测试文件遵循以下规范:

1. 继承 `GutTest`
2. 测试函数以 `test_` 开头
3. 使用 `before_each()` 和 `after_each()` 进行清理
4. 使用 `assert_eq`, `assert_true`, `assert_false` 等断言
5. 使用 Godot 4.6 语法 (`await` 而非 `yield`, 类型标注等)

### 示例测试

```gdscript
extends GutTest

var player: PlayerTank

func before_each() -> void:
    player = PlayerTank.new()
    add_child_autofree(player)

func after_each() -> void:
    # autofree handles cleanup
    pass

func test_player_can_move_up() -> void:
    var initial_pos := player.global_position
    player.set_direction(Vector2.UP)
    player._physics_process(0.1)
    assert_true(player.global_position.y < initial_pos.y, "Player should move up")
```

## 注意事项

1. 部分测试使用了 mock 对象来避免复杂的依赖关系
2. 需要 Godot 4.6 或更高版本
3. 需要 GUT 9.x 版本
4. 运行测试前确保游戏项目可以正常编译
