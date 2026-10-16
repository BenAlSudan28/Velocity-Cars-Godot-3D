extends Node3D
class_name Racer

var track: RaceTrack
var visual: CarVisual
var car_index: int = 0
var progress_m: float = 0.0
var total_distance_m: float = 0.0
var lane_offset: float = 0.0
var speed_mps: float = 0.0
var nitro: float = RaceConfig.NITRO_CAPACITY
var top_speed_mps: float = 82.0
var acceleration_mps2: float = 27.0
var handling: float = 1.0
var collision_cooldown: float = 0.0
var is_player: bool = false
var display_name: String = ""

func _ready() -> void:
	visual = CarVisual.new()
	visual.name = "VehicleVisual"
	add_child(visual)

func configure(track_ref: RaceTrack, style: int, start_progress: float, start_lane: float, initial_speed_kmh: float = 0.0) -> void:
	track = track_ref
	car_index = posmod(style, CarCatalog.count())
	var data := CarCatalog.get_car(car_index)
	display_name = String(data["name"])
	top_speed_mps = float(data["top_speed_kmh"]) / 3.6
	acceleration_mps2 = float(data["acceleration"])
	handling = float(data["handling"])
	progress_m = RouteMath.wrap_distance(start_progress, track.track_length)
	lane_offset = clampf(start_lane, -RaceConfig.PLAYER_LATERAL_LIMIT, RaceConfig.PLAYER_LATERAL_LIMIT)
	speed_mps = initial_speed_kmh / 3.6
	total_distance_m = 0.0
	if visual != null:
		visual.setup(car_index)
	_place_on_track()

func apply_player_drive(delta: float, throttle: float, brake: float, steering: float, boost: bool) -> void:
	if track == null:
		return
	collision_cooldown = maxf(0.0, collision_cooldown - delta)
	var use_boost := boost and nitro > 0.1 and throttle > 0.0
	var acceleration := throttle * acceleration_mps2
	if use_boost:
		acceleration *= 1.62
		acceleration += 7.0
		nitro = maxf(0.0, nitro - RaceConfig.NITRO_DRAIN_PER_SECOND * delta)
	else:
		nitro = minf(RaceConfig.NITRO_CAPACITY, nitro + RaceConfig.NITRO_RECHARGE_PER_SECOND * delta)
	acceleration -= brake * 40.0
	acceleration -= 1.05 + speed_mps * 0.018
	speed_mps = clampf(speed_mps + acceleration * delta, 0.0, top_speed_mps * (1.12 if use_boost else 1.0))
	var lateral_rate := (2.8 + speed_mps * 0.075) * handling
	lane_offset += steering * lateral_rate * delta
	lane_offset = clampf(lane_offset, -RaceConfig.PLAYER_LATERAL_LIMIT, RaceConfig.PLAYER_LATERAL_LIMIT)
	_apply_offroad_drag(delta)
	_advance(delta)

func advance_ai(delta: float, target_speed_mps: float, target_lane: float) -> void:
	if track == null:
		return
	collision_cooldown = maxf(0.0, collision_cooldown - delta)
	lane_offset = move_toward(lane_offset, clampf(target_lane, -6.0, 6.0), delta * 2.6)
	speed_mps = move_toward(speed_mps, target_speed_mps, delta * 8.0)
	_advance(delta)

func _apply_offroad_drag(delta: float) -> void:
	var edge := track.road_width * 0.5 - 1.0
	if absf(lane_offset) > edge:
		speed_mps = move_toward(speed_mps, minf(speed_mps, 22.0), delta * 16.0)
		lane_offset = clampf(lane_offset, -track.road_width * 0.5 + 0.25, track.road_width * 0.5 - 0.25)

func _advance(delta: float) -> void:
	var travel := speed_mps * delta
	progress_m = RouteMath.wrap_distance(progress_m + travel, track.track_length)
	total_distance_m += travel
	_place_on_track()

func _place_on_track() -> void:
	if track == null or track.track_length <= 0.0:
		return
	global_position = track.world_at(progress_m, lane_offset, 0.12)
	var tangent := track.direction_at(progress_m)
	if tangent.length_squared() > 0.001:
		global_basis = Basis.looking_at(tangent, Vector3.UP)

func can_collide() -> bool:
	return collision_cooldown <= 0.0

func register_collision() -> bool:
	if not can_collide():
		return false
	collision_cooldown = 1.1
	speed_mps = maxf(4.0, speed_mps * 0.55 - 8.0)
	return true

func speed_kmh() -> float:
	return speed_mps * 3.6
