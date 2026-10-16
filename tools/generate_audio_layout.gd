extends SceneTree

func _initialize() -> void:
	# Keep the default master, then create sender buses and one gain stage per family.
	while AudioServer.bus_count > 1:
		AudioServer.remove_bus(AudioServer.bus_count - 1)
	AudioServer.set_bus_name(0, "Master")
	var names: Array[String] = ["Music", "SFX", "UI", "MusicBase", "SFXBase"]
	for bus_name in names:
		AudioServer.add_bus(-1)
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
		AudioServer.set_bus_volume_db(AudioServer.bus_count - 1, 0.0)
		AudioServer.set_bus_mute(AudioServer.bus_count - 1, false)
	AudioServer.set_bus_send(AudioServer.get_bus_index("Music"), "MusicBase")
	AudioServer.set_bus_send(AudioServer.get_bus_index("SFX"), "SFXBase")
	AudioServer.set_bus_send(AudioServer.get_bus_index("UI"), "SFXBase")
	AudioServer.set_bus_send(AudioServer.get_bus_index("MusicBase"), "Master")
	AudioServer.set_bus_send(AudioServer.get_bus_index("SFXBase"), "Master")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("MusicBase"), 9.5424)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFXBase"), 6.0206)
	var layout := AudioServer.generate_bus_layout()
	var error := ResourceSaver.save(layout, "res://default_bus_layout.tres")
	if error != OK:
		push_error("Could not save default_bus_layout.tres: %s" % error_string(error))
		quit(1)
		return
	print("Created Master, Music, SFX, UI, MusicBase (+9.5424 dB) and SFXBase (+6.0206 dB).")
	quit(0)
