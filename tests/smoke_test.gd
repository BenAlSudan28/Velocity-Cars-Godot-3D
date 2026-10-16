extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/race/race_main.tscn") as PackedScene
	var exit_code := 0
	var game: Node = null
	if packed == null:
		push_error("Could not load the main race scene.")
		exit_code = 1
	else:
		game = packed.instantiate()
		get_root().add_child(game)
		await process_frame
	if exit_code == 0 and (not game.has_method("start_race") or not game.has_method("set_touch_input")):
		push_error("Race controller is missing required testable actions.")
		exit_code = 1
	var music_base := AudioServer.get_bus_index("MusicBase")
	var sfx_base := AudioServer.get_bus_index("SFXBase")
	if exit_code == 0 and (music_base < 0 or sfx_base < 0 or not is_equal_approx(AudioServer.get_bus_volume_db(music_base), 9.5424) or not is_equal_approx(AudioServer.get_bus_volume_db(sfx_base), 6.0206)):
		push_error("Audio base buses are missing or have unexpected gains.")
		exit_code = 1
	if exit_code == 0:
		game.start_race()
		game.set_touch_input("accelerate", true)
		for frame in range(150):
			await physics_frame
	if exit_code == 0 and (game.track == null or game.track.track_length < 100.0):
		push_error("Track geometry did not initialize.")
		exit_code = 1
	if exit_code == 0 and (game.player == null or game.player.speed_mps < 5.0):
		push_error("Player vehicle did not accelerate in the smoke test.")
		exit_code = 1
	if exit_code == 0 and (game.hud == null or game.rivals.size() != 4):
		push_error("Race HUD or expected rival grid did not initialize.")
		exit_code = 1
	if exit_code == 0:
		print("SMOKE PASS: track=%0.1fm speed=%0.1fkm/h rivals=%d" % [game.track.track_length, game.player.speed_kmh(), game.rivals.size()])
	if is_instance_valid(game):
		get_root().remove_child(game)
		game.free()
	await process_frame
	await process_frame
	quit(exit_code)
