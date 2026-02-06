#!/bin/bash
# copy_battle_city_assets.sh
# 从本地 Game Assets 库复制资源到 Battle City 项目

ASSET_ROOT="/mnt/d/GameAssets/Kenney/extracted"
PROJECT_ROOT="/mnt/f/GodotProjects/BattleCity"

echo "🎨 Battle City Asset Copier"
echo "============================"
echo ""

# 创建目录
echo "📁 Creating directories..."
mkdir -p "$PROJECT_ROOT/assets/sprites"
mkdir -p "$PROJECT_ROOT/assets/tilesets"
mkdir -p "$PROJECT_ROOT/assets/ui"
mkdir -p "$PROJECT_ROOT/assets/audio"
mkdir -p "$PROJECT_ROOT/assets/audio/ui"
mkdir -p "$PROJECT_ROOT/assets/audio/game"

# ==================== 美术资源 ====================
echo ""
echo "🎨 Copying art assets..."

# 坦克资源
if [ -f "$ASSET_ROOT/2D/top-down-tanks-redux/PNG/Default size/topdown_tanksredux.png" ]; then
    cp "$ASSET_ROOT/2D/top-down-tanks-redux/PNG/Default size/topdown_tanksredux.png" \
       "$PROJECT_ROOT/assets/sprites/tanks.png"
    echo "✅ Copied: tanks.png"
else
    echo "⚠️  Missing: top-down-tanks-redux (will use generated sprites)"
fi

# UI 资源 (如果存在)
if [ -d "$ASSET_ROOT/2D/ui-pack" ]; then
    cp "$ASSET_ROOT/2D/ui-pack/"*.png "$PROJECT_ROOT/assets/ui/" 2>/dev/null || true
    echo "✅ Copied: UI assets"
fi

# ==================== 音效资源 ====================
echo ""
echo "🎵 Copying audio assets..."

# P0: 射击音效
if [ -f "$ASSET_ROOT/Audio/digital-audio/Audio/laser_small_001.wav" ]; then
    cp "$ASSET_ROOT/Audio/digital-audio/Audio/laser_small_001.wav" \
       "$PROJECT_ROOT/assets/audio/shoot_player.wav"
    echo "✅ Copied: shoot_player.wav"
else
    echo "⚠️  Missing: laser_small_001.wav"
fi

# P0: 爆炸音效 - 坦克
if [ -f "$ASSET_ROOT/Audio/digital-audio/Audio/explosion_001.wav" ]; then
    cp "$ASSET_ROOT/Audio/digital-audio/Audio/explosion_001.wav" \
       "$PROJECT_ROOT/assets/audio/explosion_tank.wav"
    echo "✅ Copied: explosion_tank.wav"
else
    echo "⚠️  Missing: explosion_001.wav"
fi

# P1: 爆炸音效 - 墙体
if [ -f "$ASSET_ROOT/Audio/digital-audio/Audio/explosion_008.wav" ]; then
    cp "$ASSET_ROOT/Audio/digital-audio/Audio/explosion_008.wav" \
       "$PROJECT_ROOT/assets/audio/explosion_wall.wav"
    echo "✅ Copied: explosion_wall.wav"
else
    echo "⚠️  Missing: explosion_008.wav"
fi

# P1: UI 音效
if [ -f "$ASSET_ROOT/Audio/interface-sounds/click_001.wav" ]; then
    cp "$ASSET_ROOT/Audio/interface-sounds/click_001.wav" \
       "$PROJECT_ROOT/assets/audio/ui/"
    echo "✅ Copied: ui/click_001.wav"
fi

# P2: 游戏状态音效 (可选)
if [ -f "$ASSET_ROOT/Audio/music-jingles/jingles_SAX16.ogg" ]; then
    cp "$ASSET_ROOT/Audio/music-jingles/jingles_SAX16.ogg" \
       "$PROJECT_ROOT/assets/audio/game/victory.ogg" 2>/dev/null || true
    echo "✅ Copied: game/victory.ogg"
fi

if [ -f "$ASSET_ROOT/Audio/music-jingles/jingles_SAX02.ogg" ]; then
    cp "$ASSET_ROOT/Audio/music-jingles/jingles_SAX02.ogg" \
       "$PROJECT_ROOT/assets/audio/game/game_over.ogg" 2>/dev/null || true
    echo "✅ Copied: game/game_over.ogg"
fi

# ==================== 完成 ====================
echo ""
echo "✅ Asset copy complete!"
echo ""
echo "📁 Project assets:"
echo "=================="
ls -la "$PROJECT_ROOT/assets/sprites/" 2>/dev/null || echo "  (sprites directory empty)"
echo ""
ls -la "$PROJECT_ROOT/assets/audio/" 2>/dev/null || echo "  (audio directory empty)"
echo ""
ls -la "$PROJECT_ROOT/assets/ui/" 2>/dev/null || echo "  (ui directory empty)"
echo ""
echo "🎮 Next steps:"
echo "1. Open Godot 4.6"
echo "2. Import assets (Filter: Nearest)"
echo "3. Run the game!"
