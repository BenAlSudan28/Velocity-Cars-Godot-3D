extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var packed := load("res://scenes/race/race_main.tscn") as PackedScene
	if packed == null:
		push_error("Could not load the race scene for visual capture.")
		quit(1)
		return
	var game := packed.instantiate()
	get_root().add_child(game)
	await create_timer(1.0).timeout
	var menu_error := get_root().get_texture().get_image().save_png("/tmp/velocity-rush-menu.png")
	if menu_error != OK:
		push_error("Could not capture the menu.")
		quit(1)
		return
	game.start_race()
	game.set_touch_input("accelerate", true)
	for frame in range(90):
		await physics_frame
	await create_timer(0.5).timeout
	var race_error := get_root().get_texture().get_image().save_png("/tmp/velocity-rush-race.png")
	if race_error != OK:
		push_error("Could not capture the race.")
		quit(1)
		return
	for rival in game.rivals:
		print("RIVAL progress=%0.1fm lane=%0.1fm position=%s speed=%0.1fkm/h meshes=%d" % [rival.progress_m, rival.lane_offset, str(rival.global_position), rival.speed_kmh(), rival.visual.get_child_count()])
	print("VISUAL CAPTURE PASS: /tmp/velocity-rush-menu.png and /tmp/velocity-rush-race.png; speed=%0.1f/%0.1f km/h" % [game.player.speed_kmh(), game.player.top_speed_mps * 3.6])
	get_root().remove_child(game)
	game.free()
	await process_frame
	quit(0)
