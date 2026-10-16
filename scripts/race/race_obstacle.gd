extends Node3D
class_name RaceObstacle

var track: RaceTrack
var progress_m: float = 0.0
var lane_offset: float = 0.0
var obstacle_kind: int = 0

func _ready() -> void:
	_build_visual()

func setup(track_ref: RaceTrack, distance_m: float, lane: float, kind: int = 0) -> void:
	track = track_ref
	progress_m = RouteMath.wrap_distance(distance_m, track.track_length)
	lane_offset = lane
	obstacle_kind = kind
	if is_inside_tree():
		_place()

func _build_visual() -> void:
	if obstacle_kind == 1:
		_build_low_barrier()
	else:
		_build_cone_pair()
	_place()

func _build_cone_pair() -> void:
	for offset in [-0.62, 0.62]:
		var cone := MeshInstance3D.new()
		cone.name = "SafetyCone"
		var cone_mesh := CylinderMesh.new()
		cone_mesh.top_radius = 0.03
		cone_mesh.bottom_radius = 0.36
		cone_mesh.height = 0.82
		cone.mesh = cone_mesh
		cone.position = Vector3(offset, 0.43, 0.0)
		cone.material_override = RaceMaterials.surface(Color("#f27c31"), 0.78)
		add_child(cone)
		var stripe := MeshInstance3D.new()
		stripe.name = "ReflectiveStripe"
		var stripe_mesh := CylinderMesh.new()
		stripe_mesh.top_radius = 0.18
		stripe_mesh.bottom_radius = 0.23
		stripe_mesh.height = 0.12
		stripe.mesh = stripe_mesh
		stripe.position = Vector3(offset, 0.46, 0.0)
		stripe.material_override = RaceMaterials.surface(Color("#f5eee0"), 0.56)
		add_child(stripe)

func _build_low_barrier() -> void:
	var block := MeshInstance3D.new()
	block.name = "TrackBlock"
	var box := BoxMesh.new()
	box.size = Vector3(2.3, 0.82, 1.0)
	block.mesh = box
	block.position.y = 0.43
	block.material_override = RaceMaterials.surface(Color("#c84d59"), 0.48, 0.08)
	add_child(block)
	var stripe := MeshInstance3D.new()
	stripe.name = "BarrierStripe"
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(2.31, 0.18, 1.02)
	stripe.mesh = stripe_mesh
	stripe.position.y = 0.48
	stripe.material_override = RaceMaterials.surface(Color("#eef0e9"), 0.48)
	add_child(stripe)

func _place() -> void:
	if track == null:
		return
	global_position = track.world_at(progress_m, lane_offset, 0.08)
	var tangent := track.direction_at(progress_m)
	global_basis = Basis.looking_at(tangent, Vector3.UP)
