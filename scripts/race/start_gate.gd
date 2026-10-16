extends Node3D
class_name StartGate

var track: RaceTrack

func setup(track_ref: RaceTrack) -> void:
	track = track_ref

func _ready() -> void:
	if track == null:
		return
	_build_gate()

func _build_gate() -> void:
	var center := track.world_at(0.0, 0.0, 0.0)
	var right := track.right_at(0.0)
	var forward := track.direction_at(0.0)
	var gate_basis := Basis.looking_at(forward, Vector3.UP)
	var frame_material := RaceMaterials.surface(Color("#344b5d"), 0.42, 0.46)
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.name = "GatePost"
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.68, 5.4, 0.68)
		post.mesh = post_mesh
		post.position = center + right * side * 7.0 + Vector3.UP * 2.7
		post.material_override = frame_material
		add_child(post)
	var header := MeshInstance3D.new()
	header.name = "LightBar"
	var header_mesh := BoxMesh.new()
	header_mesh.size = Vector3(14.4, 0.72, 0.78)
	header.mesh = header_mesh
	header.position = center + Vector3.UP * 5.5
	header.basis = gate_basis
	header.material_override = RaceMaterials.glow(Color("#0d8499"), 0.18)
	add_child(header)
	var marker := MeshInstance3D.new()
	marker.name = "StartLine"
	var line_mesh := BoxMesh.new()
	line_mesh.size = Vector3(track.road_width - 1.2, 0.07, 0.32)
	marker.mesh = line_mesh
	marker.position = center + Vector3.UP * 0.16
	marker.basis = gate_basis
	marker.material_override = RaceMaterials.glow(Color("#f1f5ee"), 0.28)
	add_child(marker)
