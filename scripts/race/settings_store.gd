extends Node
class_name SettingsStore

const SETTINGS_PATH := "user://velocity_rush_settings.cfg"
var audio_enabled: bool = true

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		audio_enabled = true
		return
	audio_enabled = bool(config.get_value("audio", "enabled", true))

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "enabled", audio_enabled)
	config.save(SETTINGS_PATH)

func toggle_audio() -> bool:
	audio_enabled = not audio_enabled
	save_settings()
	return audio_enabled
