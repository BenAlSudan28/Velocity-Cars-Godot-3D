extends Node3D
class_name CityTrafficCar

var route: Array[Vector3] = []
var route_length: float = 0.0
var progress_m: float = 0.0
var speed_mps: float = 13.0
var visual: CarVisual

func _ready() -> void:
	visual = CarVisual.new()
	visual.name = "TrafficCarVisual"
	add_child(visual)

func configure(route_points: Array[Vector3], phase_m: float, car_index: int, speed_kmh: float) -> void:
	route = route_points.duplicate()
	route_length = 0.0
	for i in range(route.size()):
		route_length += route[i].distance_to(route[(i + 1) % route.size()])
	progress_m = fposmod(phase_m, maxf(route_length, 1.0))
	speed_mps = speed_kmh / 3.6
	if visual != null:
		visual.setup(car_index)
	_place_on_route()

func advance(delta: float) -> void:
	if route.size() < 3 or route_length <= 0.0:
		return
	progress_m = fposmod(progress_m + speed_mps * delta, route_length)
	_place_on_route()

func _place_on_route() -> void:
	if route.size() < 3 or route_length <= 0.0:
		return
	var remaining := progress_m
	var segment := 0
	var segment_length := 1.0
	for i in range(route.size()):
		segment_length = route[i].distance_to(route[(i + 1) % route.size()])
		if remaining <= segment_length:
			segment = i
			break
		remaining -= segment_length
	var t := clampf(remaining / maxf(segment_length, 0.001), 0.0, 1.0)
	var p0 := route[posmod(segment - 1, route.size())]
	var p1 := route[segment]
	var p2 := route[(segment + 1) % route.size()]
	var p3 := route[(segment + 2) % route.size()]
	global_position = _catmull_rom(p0, p1, p2, p3, t) + Vector3.UP * 0.12
	var ahead := _catmull_rom(p0, p1, p2, p3, minf(t + 0.015, 1.0))
	var tangent := ahead - global_position
	if tangent.length_squared() < 0.001:
		tangent = p2 - p1
	global_basis = Basis.looking_at(tangent.normalized(), Vector3.UP)

func _catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)
