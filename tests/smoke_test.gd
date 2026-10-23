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
	if exit_code == 0 and (not game.has_method("start_race") or not game.has_method("start_free_drive") or not game.has_method("set_touch_input")):
		push_error("Main controller is missing a required game-mode action.")
		exit_code = 1
	var music_base := AudioServer.get_bus_index("MusicBase")
	var sfx_base := AudioServer.get_bus_index("SFXBase")
	if exit_code == 0 and (music_base < 0 or sfx_base < 0 or not is_equal_approx(AudioServer.get_bus_volume_db(music_base), 9.5424) or not is_equal_approx(AudioServer.get_bus_volume_db(sfx_base), 6.0206)):
		push_error("Audio base buses are missing or have unexpected gains.")
		exit_code = 1
	if exit_code == 0:
		var mode_buttons: Array = game.hud.root.find_children("*", "Button", true, false)
		var has_race_choice := false
		var has_city_choice := false
		for item in mode_buttons:
			var button := item as Button
			has_race_choice = has_race_choice or button.text.contains("سباق الحلبة")
			has_city_choice = has_city_choice or button.text.contains("قيادة حرة")
		if not has_race_choice or not has_city_choice:
			push_error("The title menu must offer both the circuit race and free-drive city modes.")
			exit_code = 1
	if exit_code == 0:
		game.start_free_drive()
		await process_frame
		await process_frame
		if game.city_world == null or game.free_driver == null or game.city_world.traffic_cars.size() != CityConfig.TRAFFIC_COUNT:
			push_error("Free-drive city or two-way traffic did not initialize.")
			exit_code = 1
		if exit_code == 0 and (game.city_world.get_node_or_null("CrossStreetNetwork") == null or game.city_world.get_node_or_null("CityBuildingMasses") == null or game.city_world.get_node_or_null("TrafficSignalHousings") == null):
			push_error("The city needs a street network, 3D buildings and traffic signals.")
			exit_code = 1
		game.set_touch_input("accelerate", true)
		for frame in range(100):
			await physics_frame
		if exit_code == 0 and (game.free_driver.speed_mps < 4.0 or game.free_driver.total_distance_m < 1.0):
			push_error("Free-drive player did not accelerate along the city streets.")
			exit_code = 1
		game.set_touch_input("accelerate", false)
		game.pause_race()
		if exit_code == 0 and (game.mode != RaceState.Mode.PAUSED or game.city_world.simulation_enabled):
			push_error("City pause must stop traffic and enter the paused state.")
			exit_code = 1
		game.resume_race()
		if exit_code == 0 and (game.mode != RaceState.Mode.RACING or not game.city_world.simulation_enabled):
			push_error("City resume must restore driving and traffic.")
			exit_code = 1
		game.return_to_menu()
		if exit_code == 0 and (game.mode != RaceState.Mode.MENU or game.city_world != null):
			push_error("Returning to the menu must release the city session.")
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
		push_error("Player vehicle did not accelerate in the race smoke test.")
		exit_code = 1
	if exit_code == 0 and (game.hud == null or game.rivals.size() != 4):
		push_error("Race HUD or expected rival grid did not initialize.")
		exit_code = 1
	if exit_code == 0:
		print("SMOKE PASS: city streets/buildings/traffic and race track/rivals initialized; city controls and pause/resume work.")
	if is_instance_valid(game):
		get_root().remove_child(game)
		game.free()
	await process_frame
	await process_frame
	quit(exit_code)
