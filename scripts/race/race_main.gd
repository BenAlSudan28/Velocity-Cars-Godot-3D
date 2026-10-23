extends Node3D
class_name RaceMain

enum GameMode { RACE, FREE_DRIVE }

const TRACK_SCENE: PackedScene = preload("res://scenes/race/race_track.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/race/player_car.tscn")
const RIVAL_SCENE: PackedScene = preload("res://scenes/race/rival_car.tscn")
const PICKUP_SCENE: PackedScene = preload("res://scenes/race/energy_pickup.tscn")
const OBSTACLE_SCENE: PackedScene = preload("res://scenes/race/race_obstacle.tscn")
const GATE_SCENE: PackedScene = preload("res://scenes/race/start_gate.tscn")
const CITY_SCENE: PackedScene = preload("res://scenes/city/free_drive_city.tscn")

var track: RaceTrack
var gate: StartGate
var player: PlayerDriver
var city_world: FreeDriveCity
var free_driver: FreeDriveController
var rivals: Array[RivalDriver] = []
var pickups: Array[EnergyPickup] = []
var obstacles: Array[RaceObstacle] = []
var camera_rig: RaceCamera
var hud: RaceHUD
var settings: SettingsStore
var audio: AudioManager
var score_system := ScoreSystem.new()
var difficulty := DifficultyManager.new()
var mode: RaceState.Mode = RaceState.Mode.MENU
var game_mode: int = GameMode.RACE
var selected_car: int = 0
var race_time: float = 0.0
var touch_state: Dictionary = {}

func _ready() -> void:
	RaceInput.ensure_actions()
	settings = SettingsStore.new()
	settings.name = "SettingsStore"
	add_child(settings)
	audio = AudioManager.new()
	audio.name = "AudioManager"
	add_child(audio)
	audio.bind_settings(settings)
	track = TRACK_SCENE.instantiate() as RaceTrack
	add_child(track)
	gate = GATE_SCENE.instantiate() as StartGate
	gate.setup(track)
	add_child(gate)
	gate.visible = false
	player = PLAYER_SCENE.instantiate() as PlayerDriver
	add_child(player)
	player.configure(track, selected_car, 0.0, 0.0)
	camera_rig = RaceCamera.new()
	camera_rig.name = "RaceCamera"
	add_child(camera_rig)
	camera_rig.bind_target(player)
	hud = RaceHUD.new()
	hud.name = "RaceHUD"
	add_child(hud)
	hud.action_requested.connect(_on_hud_action)
	hud.touch_changed.connect(set_touch_input)
	hud.show_menu(selected_car, settings.audio_enabled)
	audio.play_menu()

func _physics_process(delta: float) -> void:
	if mode != RaceState.Mode.RACING:
		return
	if Input.is_action_just_pressed("race_pause"):
		pause_race()
		return
	race_time += delta
	var controls := _read_controls()
	if game_mode == GameMode.FREE_DRIVE:
		if free_driver == null or city_world == null:
			return
		free_driver.drive_from_input(delta, controls, city_world)
		if city_world.resolve_traffic_collision(free_driver):
			audio.play_cue("impact")
		audio.update_engine(free_driver.speed_mps, false)
		hud.update_free_drive(free_driver.speed_kmh(), free_driver.total_distance_m, race_time)
		return
	difficulty.update(race_time)
	player.drive_from_input(delta, controls)
	for rival in rivals:
		if is_instance_valid(rival):
			rival.tick_ai(delta, race_time, difficulty.difficulty)
	if CollisionManager.resolve_racer_contacts(player, rivals, track.track_length):
		score_system.add_collision()
		audio.play_cue("impact")
	_check_track_items()
	score_system.update_distance(player.total_distance_m)
	audio.update_engine(player.speed_mps, bool(controls["boost"]))
	_update_hud()
	if player.total_distance_m >= track.track_length * float(RaceConfig.LAP_COUNT):
		finish_race()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("race_pause"):
		if mode == RaceState.Mode.RACING:
			pause_race()
		elif mode == RaceState.Mode.PAUSED:
			resume_race()
	elif event.is_action_pressed("race_confirm") and mode == RaceState.Mode.MENU:
		start_race()

func _read_controls() -> Dictionary:
	var steering := float(Input.is_action_pressed("race_right")) - float(Input.is_action_pressed("race_left"))
	if bool(touch_state.get("right", false)):
		steering += 1.0
	if bool(touch_state.get("left", false)):
		steering -= 1.0
	return {
		"throttle": maxf(float(Input.is_action_pressed("race_accelerate")), float(touch_state.get("accelerate", false))),
		"brake": maxf(float(Input.is_action_pressed("race_brake")), float(touch_state.get("brake", false))),
		"steering": clampf(steering, -1.0, 1.0),
		"boost": Input.is_action_pressed("race_nitro") or bool(touch_state.get("nitro", false))
	}

func start_race() -> void:
	_exit_free_drive()
	_set_race_world_visible(true)
	gate.visible = true
	game_mode = GameMode.RACE
	_clear_race_objects()
	score_system.reset()
	difficulty.reset()
	race_time = 0.0
	touch_state.clear()
	player.configure(track, selected_car, 0.0, 0.0, 0.0)
	camera_rig.bind_target(player)
	_spawn_rivals()
	_spawn_track_items()
	mode = RaceState.Mode.RACING
	hud.show_race()
	audio.start_race()

func start_free_drive() -> void:
	_clear_race_objects()
	_exit_free_drive()
	score_system.reset()
	difficulty.reset()
	race_time = 0.0
	touch_state.clear()
	game_mode = GameMode.FREE_DRIVE
	_set_race_world_visible(false)
	city_world = CITY_SCENE.instantiate() as FreeDriveCity
	city_world.name = "FreeDriveCity"
	add_child(city_world)
	free_driver = FreeDriveController.new()
	free_driver.name = "FreeDrivePlayer"
	add_child(free_driver)
	free_driver.configure(selected_car, Vector3(0.0, 0.12, 12.0), 0.0)
	camera_rig.bind_target(free_driver)
	city_world.set_simulation_enabled(true)
	mode = RaceState.Mode.RACING
	hud.show_free_drive()
	audio.start_race()

func _exit_free_drive() -> void:
	if is_instance_valid(city_world):
		remove_child(city_world)
		city_world.free()
	city_world = null
	if is_instance_valid(free_driver):
		remove_child(free_driver)
		free_driver.free()
	free_driver = null

func _set_race_world_visible(is_visible: bool) -> void:
	if is_instance_valid(track):
		track.visible = is_visible
	if is_instance_valid(player):
		player.visible = is_visible
	if is_instance_valid(gate):
		gate.visible = is_visible and mode == RaceState.Mode.RACING

func pause_race() -> void:
	if mode != RaceState.Mode.RACING:
		return
	mode = RaceState.Mode.PAUSED
	touch_state.clear()
	if game_mode == GameMode.FREE_DRIVE and is_instance_valid(city_world):
		city_world.set_simulation_enabled(false)
	audio.pause_audio(true)
	hud.show_pause(game_mode == GameMode.FREE_DRIVE)

func resume_race() -> void:
	if mode != RaceState.Mode.PAUSED:
		return
	mode = RaceState.Mode.RACING
	if game_mode == GameMode.FREE_DRIVE and is_instance_valid(city_world):
		city_world.set_simulation_enabled(true)
	audio.pause_audio(false)
	if game_mode == GameMode.FREE_DRIVE:
		hud.show_free_drive()
	else:
		hud.show_race()

func finish_race() -> void:
	if mode != RaceState.Mode.RACING or game_mode != GameMode.RACE:
		return
	mode = RaceState.Mode.RESULTS
	touch_state.clear()
	audio.end_race()
	var position := _player_position()
	hud.show_results(position == 1, score_system.score, player.total_distance_m, score_system.collision_count, position)

func return_to_menu() -> void:
	_clear_race_objects()
	_exit_free_drive()
	_set_race_world_visible(true)
	gate.visible = false
	game_mode = GameMode.RACE
	mode = RaceState.Mode.MENU
	race_time = 0.0
	touch_state.clear()
	player.configure(track, selected_car, 0.0, 0.0, 0.0)
	camera_rig.bind_target(player)
	audio.end_race()
	audio.pause_audio(false)
	audio.play_menu()
	hud.show_menu(selected_car, settings.audio_enabled)

func change_car(direction: int) -> void:
	if mode != RaceState.Mode.MENU:
		return
	selected_car = posmod(selected_car + direction, CarCatalog.count())
	player.configure(track, selected_car, 0.0, 0.0, 0.0)
	camera_rig.bind_target(player)
	hud.show_menu(selected_car, settings.audio_enabled)
	audio.play_cue("tick")

func set_touch_input(action: String, pressed: bool) -> void:
	touch_state[action] = pressed

func _on_hud_action(action: String) -> void:
	match action:
		"start", "start_race":
			start_race()
		"start_free_drive":
			start_free_drive()
		"retry":
			if game_mode == GameMode.FREE_DRIVE:
				start_free_drive()
			else:
				start_race()
		"pause":
			pause_race()
		"resume":
			resume_race()
		"menu":
			return_to_menu()
		"car_previous":
			change_car(-1)
		"car_next":
			change_car(1)
		"audio_toggle":
			var enabled := settings.toggle_audio()
			audio.set_enabled(enabled)
			hud.show_menu(selected_car, settings.audio_enabled)
			if enabled:
				audio.play_menu()

func _spawn_rivals() -> void:
	var grid_lanes: Array[float] = [-6.0, -3.0, 3.0, 6.0]
	for i in range(RaceConfig.RACE_RIVAL_COUNT):
		var rival := RIVAL_SCENE.instantiate() as RivalDriver
		add_child(rival)
		var grid_progress := 45.0 + float(i) * 14.0
		rival.configure_rival(track, (i + 1) % CarCatalog.count(), i, grid_lanes[i], 0.0, grid_progress)
		rivals.append(rival)

func _spawn_track_items() -> void:
	for i in range(8):
		var distance_m := 55.0 + float(i) * track.track_length / 8.0
		var lane: float = float([-5.1, 0.0, 5.1][i % 3])
		var pickup := PICKUP_SCENE.instantiate() as EnergyPickup
		add_child(pickup)
		pickup.setup(track, distance_m, lane)
		pickups.append(pickup)
	for i in range(11):
		var distance_m := 28.0 + float(i) * track.track_length / 11.0
		var lane: float = float([-4.8, 0.0, 4.8][(i * 2) % 3])
		var kind: int = 1 if i % 4 == 3 else 0
		var obstacle := OBSTACLE_SCENE.instantiate() as RaceObstacle
		add_child(obstacle)
		obstacle.setup(track, distance_m, lane, kind)
		obstacles.append(obstacle)

func _check_track_items() -> void:
	for pickup in pickups.duplicate():
		if not is_instance_valid(pickup):
			pickups.erase(pickup)
			continue
		if CollisionManager.overlaps_track_object(player.progress_m, player.lane_offset, pickup.progress_m, pickup.lane_offset, track.track_length, 3.0, 2.0):
			score_system.add_pickup()
			player.nitro = minf(RaceConfig.NITRO_CAPACITY, player.nitro + 38.0)
			pickup.collect()
			pickups.erase(pickup)
			audio.play_cue("turbo")
	for obstacle in obstacles:
		if is_instance_valid(obstacle) and CollisionManager.overlaps_track_object(player.progress_m, player.lane_offset, obstacle.progress_m, obstacle.lane_offset, track.track_length):
			if player.register_collision():
				score_system.add_collision()
				audio.play_cue("impact")

func _clear_race_objects() -> void:
	for item in rivals + pickups + obstacles:
		if is_instance_valid(item):
			item.queue_free()
	rivals.clear()
	pickups.clear()
	obstacles.clear()

func _player_position() -> int:
	var position := 1
	for rival in rivals:
		if is_instance_valid(rival) and rival.total_distance_m > player.total_distance_m:
			position += 1
	return position

func _update_hud() -> void:
	if hud == null or player == null:
		return
	var lap := mini(RaceConfig.LAP_COUNT, int(floor(player.total_distance_m / track.track_length)) + 1)
	var lap_progress := fposmod(player.total_distance_m, track.track_length) / track.track_length
	if player.total_distance_m >= track.track_length * float(RaceConfig.LAP_COUNT):
		lap_progress = 1.0
	hud.update_race(player.speed_kmh(), player.total_distance_m, score_system.score, lap, _player_position(), player.nitro, lap_progress, race_time)
