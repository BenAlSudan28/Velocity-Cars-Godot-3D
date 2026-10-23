extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var packed := load("res://scenes/race/race_main.tscn") as PackedScene
	if packed == null:
		push_error("Could not load the game scene for visual capture.")
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
	game.set_touch_input("accelerate", false)
	game.start_free_drive()
	game.set_touch_input("accelerate", true)
	for frame in range(45):
		await physics_frame
	await create_timer(0.5).timeout
	var city_error := get_root().get_texture().get_image().save_png("/tmp/velocity-rush-city.png")
	if city_error != OK:
		push_error("Could not capture the free-drive city.")
		quit(1)
		return
	print("VISUAL CAPTURE PASS: menu, race and free-drive city captured at 1280x720.")
	get_root().remove_child(game)
	game.free()
	await process_frame
	quit(0)
