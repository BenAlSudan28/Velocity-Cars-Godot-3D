extends Node3D
class_name EnergyPickup

var track: RaceTrack
var progress_m: float = 0.0
var lane_offset: float = 0.0
var active: bool = true
var _orb: MeshInstance3D

func _ready() -> void:
	_build_visual()

func setup(track_ref: RaceTrack, distance_m: float, lane: float) -> void:
	track = track_ref
	progress_m = RouteMath.wrap_distance(distance_m, track.track_length)
	lane_offset = lane
	if is_inside_tree():
		_place()

func _process(delta: float) -> void:
	if not active:
		return
	rotate_y(delta * 1.6)
	if _orb != null:
		_orb.position.y = 1.15 + sin(Time.get_ticks_msec() * 0.003 + progress_m) * 0.12

func _build_visual() -> void:
	var orb := MeshInstance3D.new()
	orb.name = "EnergyCore"
	var sphere := SphereMesh.new()
	sphere.radius = 0.42
	sphere.height = 0.84
	orb.mesh = sphere
	orb.material_override = RaceMaterials.glow(Color("#54dcff"), 2.2)
	orb.position.y = 1.15
	add_child(orb)
	_orb = orb
	var ring := MeshInstance3D.new()
	ring.name = "EnergyHalo"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.48
	torus.outer_radius = 0.59
	torus.rings = 24
	torus.ring_segments = 8
	ring.mesh = torus
	ring.rotation.x = PI * 0.5
	ring.position.y = 1.15
	ring.material_override = RaceMaterials.glow(Color("#70e5ff"), 1.3)
	add_child(ring)
	_place()

func _place() -> void:
	if track == null:
		return
	global_position = track.world_at(progress_m, lane_offset, 0.0)

func collect() -> void:
	if not active:
		return
	active = false
	queue_free()
