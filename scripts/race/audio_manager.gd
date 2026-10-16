extends Node
class_name AudioManager

const BROWSER_BGM_SCRIPT: Script = preload("res://scripts/manus/browser_bgm_player.gd")

var settings: SettingsStore
var engine_player: AudioStreamPlayer
var music_player
var _one_shot_players: Array[AudioStreamPlayer] = []
var _cue_paths := {
	"impact": "res://assets/race/audio/impact.ogg",
	"turbo": "res://assets/race/audio/turbo_burst.ogg",
	"brake": "res://assets/race/audio/brake_pulse.ogg",
	"start": "res://assets/race/audio/race_start.ogg",
	"tick": "res://assets/race/audio/ui_tick.ogg",
	"skid": "res://assets/race/audio/tire_skid.ogg"
}

func _ready() -> void:
	engine_player = AudioStreamPlayer.new()
	engine_player.name = "EngineLoop"
	engine_player.stream = _load_loop("res://assets/race/audio/engine_loop.ogg")
	engine_player.bus = "SFX"
	engine_player.volume_db = -11.0
	add_child(engine_player)
	music_player = BROWSER_BGM_SCRIPT.new()
	music_player.name = "MenuMusic"
	music_player.stream = _load_loop("res://assets/race/audio/menu_drive.ogg")
	music_player.volume_db = -17.0
	music_player.bus = "Music"
	music_player.force_loop = true
	music_player.buffer_key = "velocity_rush_menu_drive_v1"
	add_child(music_player)
	music_player.prepare()
	for i in range(4):
		var player := AudioStreamPlayer.new()
		player.name = "OneShot_%d" % i
		player.bus = "SFX"
		player.volume_db = -9.0
		add_child(player)
		_one_shot_players.append(player)

func bind_settings(store: SettingsStore) -> void:
	settings = store
	_apply_mute()

func play_menu() -> void:
	if _audio_allowed() and music_player != null and not music_player.playing:
		music_player.play()

func start_race() -> void:
	if music_player != null:
		music_player.stop()
	if _audio_allowed():
		play_cue("start")
		if engine_player != null and not engine_player.playing:
			engine_player.play()

func end_race() -> void:
	if engine_player != null:
		engine_player.stop()

func pause_audio(paused: bool) -> void:
	if engine_player != null:
		engine_player.stream_paused = paused
	if music_player != null and music_player.playing:
		music_player.stream_paused = paused

func update_engine(speed_mps: float, boost: bool) -> void:
	if engine_player == null:
		return
	engine_player.pitch_scale = clampf(0.78 + speed_mps / 135.0 + (0.13 if boost else 0.0), 0.78, 1.65)
	engine_player.volume_db = -15.0 + clampf(speed_mps / 100.0, 0.0, 1.0) * 5.0

func play_cue(cue: String) -> void:
	if not _audio_allowed() or not _cue_paths.has(cue) or _one_shot_players.is_empty():
		return
	var player: AudioStreamPlayer = _one_shot_players[0]
	for candidate in _one_shot_players:
		if not candidate.playing:
			player = candidate
			break
	player.bus = "UI" if cue == "tick" else "SFX"
	player.stream = load(String(_cue_paths[cue])) as AudioStream
	if player.stream != null:
		player.pitch_scale = randf_range(0.94, 1.04) if cue == "impact" else 1.0
		player.play()

func set_enabled(enabled: bool) -> void:
	if settings != null:
		settings.audio_enabled = enabled
		settings.save_settings()
	_apply_mute()
	if not enabled:
		if engine_player != null:
			engine_player.stop()
		if music_player != null:
			music_player.stop()

func _apply_mute() -> void:
	var muted := not _audio_allowed()
	if engine_player != null:
		engine_player.volume_db = -80.0 if muted else -11.0
	if music_player != null:
		music_player.volume_db = -80.0 if muted else -17.0

func _audio_allowed() -> bool:
	return settings == null or settings.audio_enabled

func _load_loop(path: String) -> AudioStream:
	var stream := load(path) as AudioStream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	return stream
