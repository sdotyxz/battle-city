extends Node

# AudioManager - Singleton for handling game audio
# Uses object pooling for sound effects

# Audio players pool
var sfx_players: Array[AudioStreamPlayer] = []
var max_players: int = 8

# Pre-loaded sounds
var sounds = {}

func _ready():
	print("🔊 AudioManager initialized")
	
	# Create audio player pool
	for i in range(max_players):
		var player = AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)
	
	# Load sounds
	load_sounds()

func load_sounds():
	# P0 sounds (required)
	_safely_load("shoot", "res://assets/audio/shoot_player.ogg")
	_safely_load("explosion", "res://assets/audio/explosion_tank.ogg")
	
	# P1 sounds (should have)
	_safely_load("explosion_small", "res://assets/audio/explosion_wall.ogg")
	_safely_load("ui_click", "res://assets/audio/ui/click_001.ogg")
	
	# P2 sounds (nice to have)
	_safely_load("victory", "res://assets/audio/game/victory.ogg")
	_safely_load("game_over", "res://assets/audio/game/game_over.ogg")

func _safely_load(name: String, path: String):
	if not FileAccess.file_exists(path):
		print("⚠️ Sound not found: ", path)
		return
	
	# Try to load, but catch errors
	var resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
	if resource:
		sounds[name] = resource
	else:
		print("⚠️ Failed to load sound: ", path, " (needs import in Godot Editor)")

func play_sound(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not sounds.has(sound_name):
		return
	
	# Find a free player
	for player in sfx_players:
		if not player.playing:
			player.stream = sounds[sound_name]
			player.volume_db = volume_db
			player.pitch_scale = pitch
			player.play()
			return
	
	# If all are playing, reuse the oldest one
	sfx_players[0].stop()
	play_sound(sound_name, volume_db, pitch)

func play_shoot() -> void:
	# Random pitch variation for variety
	var pitch = randf_range(0.95, 1.05)
	play_sound("shoot", -6.0, pitch)

func play_explosion(is_big: bool = true) -> void:
	var sound_name = "explosion" if is_big else "explosion_small"
	var vol = -3.0 if is_big else -8.0
	var pitch = randf_range(0.9, 1.1)
	play_sound(sound_name, vol, pitch)

func play_ui_click() -> void:
	play_sound("ui_click", -8.0)

func play_victory() -> void:
	if sounds.has("victory"):
		play_sound("victory", -4.0)

func play_game_over() -> void:
	if sounds.has("game_over"):
		play_sound("game_over", -4.0)
