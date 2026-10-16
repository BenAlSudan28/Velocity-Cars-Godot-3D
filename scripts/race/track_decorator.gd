extends Node3D
class_name TrackDecorator

var track: RaceTrack

func setup(track_ref: RaceTrack) -> void:
	track = track_ref

func _ready() -> void:
	if track == null:
		return
	_build_city_blocks()
	_build_lighting_towers()
	_build_grandstand()

func _build_city_blocks() -> void:
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var seed := 8127
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var distance_m := 0.0
	while distance_m < track.track_length:
		for side in [-1.0, 1.0]:
			var row_count := 1
			for row in range(row_count):
				var width := rng.randf_range(2.8, 4.0)
				var depth := rng.randf_range(3.5, 5.0)
				var height := rng.randf_range(3.0, 5.5)
				var lateral: float = float(side) * (track.road_width * 0.5 + 32.0 + float(row) * 18.0)
				var pos := track.world_at(distance_m + float(row) * 5.0, lateral, height * 0.5 - 0.3)
				var yaw := rng.randf_range(-0.18, 0.18)
				var basis := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(width, height, depth))
				transforms.append(Transform3D(basis, pos))
				var palette := [Color("#25384b"), Color("#304455"), Color("#3a4d5a"), Color("#1e3443")]
				colors.append(palette[rng.randi_range(0, palette.size() - 1)])
		distance_m += 58.0
	_add_box_multimesh("CityBuildings", transforms, colors, RaceMaterials.surface(Color.WHITE, 0.86, 0.05))

func _build_lighting_towers() -> void:
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.22, 7.2, 0.22)
	var post_material := RaceMaterials.surface(Color("#5d7381"), 0.34, 0.58)
	for side in [-1.0, 1.0]:
		var d := 28.0
		while d < track.track_length:
			var post := MeshInstance3D.new()
			post.name = "LampPost"
			post.mesh = post_mesh
			post.material_override = post_material
			post.position = track.world_at(d, side * (track.road_width * 0.5 + 5.4), 3.4)
			add_child(post)
			var arm := MeshInstance3D.new()
			arm.name = "LampArm"
			var arm_mesh := BoxMesh.new()
			arm_mesh.size = Vector3(2.3, 0.16, 0.20)
			arm.mesh = arm_mesh
			arm.position = post.position + track.right_at(d) * (-side * 0.95) + Vector3.UP * 3.25
			arm.material_override = post_material
			add_child(arm)
			var lamp := OmniLight3D.new()
			lamp.name = "TrackLamp"
			lamp.position = arm.position + Vector3.UP * 0.18
			lamp.light_color = Color("#9bdcff")
			lamp.light_energy = 0.72
			lamp.omni_range = 22.0
			lamp.shadow_enabled = false
			add_child(lamp)
			d += 115.0

func _build_grandstand() -> void:
	for side in [-1.0, 1.0]:
		var distance_m := 92.0 if side < 0.0 else 390.0
		var stand := MeshInstance3D.new()
		stand.name = "SpectatorStand"
		var mesh := BoxMesh.new()
		mesh.size = Vector3(23.0, 5.2, 5.0)
		stand.mesh = mesh
		stand.position = track.world_at(distance_m, side * (track.road_width * 0.5 + 12.0), 2.3)
		stand.rotation.y = atan2(track.direction_at(distance_m).x, track.direction_at(distance_m).z)
		stand.material_override = RaceMaterials.surface(Color("#354859"), 0.84)
		add_child(stand)
		var roof := MeshInstance3D.new()
		roof.name = "StandCanopy"
		var roof_mesh := BoxMesh.new()
		roof_mesh.size = Vector3(24.0, 0.45, 5.8)
		roof.mesh = roof_mesh
		roof.position = stand.position + Vector3.UP * 3.0
		roof.rotation = stand.rotation
		roof.material_override = RaceMaterials.surface(Color("#cf4851"), 0.55, 0.12)
		add_child(roof)

func _add_box_multimesh(node_name: String, transforms: Array[Transform3D], colors: Array[Color], material: Material) -> void:
	var mesh := BoxMesh.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for i in range(transforms.size()):
		multimesh.set_instance_transform(i, transforms[i])
		multimesh.set_instance_color(i, colors[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	var colored := material as StandardMaterial3D
	colored.vertex_color_use_as_albedo = true
	instance.material_override = colored
	add_child(instance)
