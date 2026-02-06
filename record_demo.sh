#!/bin/bash
# Windows 路径
PROJECT_WIN="F:\\GodotProjects\\BattleCity"
PROJECT="/mnt/f/GodotProjects/BattleCity"
GODOT="/mnt/f/ProgramFiles/Godot/Godot_v4.6-stable_win64_console.exe"
OUTPUT="$PROJECT/demo"

# 默认录制时长（秒）
DURATION=35

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -d, --duration SECONDS  Recording duration (default: 35)"
            echo "  -h, --help              Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "🎬 Recording Battle City Demo..."
echo "⏱️  Duration: $DURATION seconds"

# 计算退出时间（帧数，假设60fps）
QUIT_AFTER=$((DURATION * 60))

# 清理旧文件
rm -f "$OUTPUT.avi" "$OUTPUT.mp4"

# 录制 AVI - 使用 --demo 参数启动演示模式
cd "$PROJECT"
"$GODOT" --path "$PROJECT_WIN" \
  --demo \
  --write-movie "$OUTPUT.avi" \
  --fixed-fps 60 \
  --quit-after $QUIT_AFTER \
  2>&1

# 检查录制结果 (使用 WSL 路径)
OUTPUT_AVI="/mnt/f/GodotProjects/BattleCity/demo.avi"
OUTPUT_MP4="/mnt/f/GodotProjects/BattleCity/demo.mp4"

if [ -f "$OUTPUT_AVI" ]; then
    echo "✅ AVI recorded: $OUTPUT_AVI"
    ls -lh "$OUTPUT_AVI"
    
    # 转换为 MP4
    echo "🎬 Converting to MP4..."
    ffmpeg -y -i "$OUTPUT_AVI" \
      -c:v libx264 -preset fast -crf 23 \
      -c:a aac -b:a 128k \
      -movflags +faststart \
      -pix_fmt yuv420p \
      "$OUTPUT_MP4" 2>&1
    
    if [ -f "$OUTPUT_MP4" ]; then
        echo "✅ MP4 created: $OUTPUT_MP4"
        ls -lh "$OUTPUT_MP4"
        
        # 获取视频时长
        DURATION_CHECK=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT_MP4" 2>/dev/null | awk '{printf "%.1f", $1}')
        echo "⏱️  Actual duration: $DURATION_CHECK seconds"
        echo ""
        echo "🎉 Demo recording complete!"
        echo "   AVI: $OUTPUT_AVI"
        echo "   MP4: $OUTPUT_MP4"
    else
        echo "❌ MP4 conversion failed"
    fi
else
    echo "❌ Recording failed - AVI file not found"
    exit 1
fi
