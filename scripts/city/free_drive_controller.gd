extends Node3D
class_name FreeDriveController

var visual: CarVisual
var car_index: int = 0
var speed_mps: float = 0.0
var top_speed_mps: float = 40.0
var acceleration_mps2: float = 18.0
var handling: float = 1.0
var yaw: float = 0.0
var total_distance_m: float = 0.0
var collision_cooldown: float = 0.0

func _ready() -> void:
	visual = CarVisual.new()
	visual.name = "FreeDriveVehicleVisual"
	add_child(visual)

func configure(style: int, start_position: Vector3, start_yaw: float = 0.0) -> void:
	car_index = posmod(style, CarCatalog.count())
	var data := CarCatalog.get_car(car_index)
	top_speed_mps = minf(float(data["top_speed_kmh"]) / 3.6 * 0.48, 48.0)
	acceleration_mps2 = float(data["acceleration"]) * 0.66
	handling = float(data["handling"])
	yaw = start_yaw
	speed_mps = 0.0
	total_distance_m = 0.0
	collision_cooldown = 0.0
	global_position = start_position
	rotation.y = yaw
	if visual != null:
		visual.setup(car_index)

func drive_from_input(delta: float, controls: Dictionary, city: FreeDriveCity) -> void:
	var throttle := float(controls.get("throttle", 0.0))
	var brake := float(controls.get("brake", 0.0))
	var steering := float(controls.get("steering", 0.0))
	collision_cooldown = maxf(0.0, collision_cooldown - delta)
	var acceleration := throttle * acceleration_mps2 - brake * 40.0 - (1.2 + speed_mps * 0.025)
	speed_mps = clampf(speed_mps + acceleration * delta, 0.0, top_speed_mps)
	yaw += steering * (0.9 + speed_mps / maxf(top_speed_mps, 1.0) * 1.15) * handling * delta
	var forward := Vector3(sin(yaw), 0.0, -cos(yaw))
	var old_position := global_position
	global_position += forward * speed_mps * delta
	global_position.y = 0.12
	global_position.x = clampf(global_position.x, -CityConfig.CITY_HALF_EXTENT + 2.0, CityConfig.CITY_HALF_EXTENT - 2.0)
	global_position.z = clampf(global_position.z, -CityConfig.CITY_HALF_EXTENT + 2.0, CityConfig.CITY_HALF_EXTENT - 2.0)
	if city != null and not city.is_drivable_position(global_position):
		speed_mps = move_toward(speed_mps, minf(speed_mps, 7.0), delta * 13.0)
		if not city.is_drivable_position(global_position - forward * 0.65):
			global_position = old_position
	total_distance_m += old_position.distance_to(global_position)
	rotation.y = yaw

func speed_kmh() -> float:
	return speed_mps * 3.6

func register_collision() -> bool:
	if collision_cooldown > 0.0:
		return false
	collision_cooldown = 1.0
	speed_mps = maxf(2.0, speed_mps * 0.48)
	return true
