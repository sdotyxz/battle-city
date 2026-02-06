@echo off
set PROJECT=F:\GodotProjects\BattleCity
set GODOT=F:\ProgramFiles\Godot\Godot_v4.6-stable_win64_console.exe
set OUTPUT=%PROJECT%\demo

echo Recording Battle City demo...

:: 清理旧文件
if exist "%OUTPUT%.avi" del "%OUTPUT%.avi"
if exist "%OUTPUT%.mp4" del "%OUTPUT%.mp4"

:: 录制 AVI
cd /d %PROJECT%
%GODOT% --write-movie "%OUTPUT%.avi" --fixed-fps 60 --quit-after 4000 2>nul

:: 检查录制结果
if exist "%OUTPUT%.avi" (
    echo AVI recorded: %OUTPUT%.avi
    
    :: 转换为 MP4
    ffmpeg -y -i "%OUTPUT%.avi" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k -movflags +faststart -pix_fmt yuv420p "%OUTPUT%.mp4" 2>nul
    
    if exist "%OUTPUT%.mp4" (
        echo MP4 created: %OUTPUT%.mp4
        dir "%OUTPUT%.mp4"
    ) else (
        echo MP4 conversion failed
    )
) else (
    echo Recording failed - AVI file not found
)
