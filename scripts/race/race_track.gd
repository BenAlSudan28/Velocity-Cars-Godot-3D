extends Node3D
class_name RaceTrack

@export var road_width: float = RaceConfig.TRACK_WIDTH
@export var samples_per_curve: int = 14

var points: Array[Vector3] = []
var cumulative: PackedFloat32Array = PackedFloat32Array()
var track_length: float = 0.0

func _ready() -> void:
	build_track()

func build_track() -> void:
	_generate_route()
	_build_ground()
	_build_road()
	_build_markings()
	_build_start_grid()
	_build_barriers()
	var decorator := TrackDecorator.new()
	decorator.name = "TracksideEnvironment"
	decorator.setup(self)
	add_child(decorator)
	_build_lighting()

func _generate_route() -> void:
	var controls: Array[Vector3] = [
		Vector3(-34.0, 0.0, -112.0), Vector3(32.0, 0.0, -118.0),
		Vector3(93.0, 0.0, -91.0), Vector3(119.0, 0.0, -38.0),
		Vector3(119.0, 0.0, 29.0), Vector3(92.0, 0.0, 91.0),
		Vector3(37.0, 0.0, 116.0), Vector3(-31.0, 0.0, 113.0),
		Vector3(-91.0, 0.0, 86.0), Vector3(-118.0, 0.0, 34.0),
		Vector3(-114.0, 0.0, -34.0), Vector3(-86.0, 0.0, -87.0)
	]
	points.clear()
	for i in range(controls.size()):
		var p0: Vector3 = controls[posmod(i - 1, controls.size())]
		var p1: Vector3 = controls[i]
		var p2: Vector3 = controls[(i + 1) % controls.size()]
		var p3: Vector3 = controls[(i + 2) % controls.size()]
		for sample in range(samples_per_curve):
			points.append(RouteMath.catmull_rom(p0, p1, p2, p3, float(sample) / float(samples_per_curve)))
	cumulative.resize(points.size())
	track_length = 0.0
	for i in range(points.size()):
		cumulative[i] = track_length
		track_length += points[i].distance_to(points[(i + 1) % points.size()])

func point_at(distance_m: float) -> Vector3:
	var sample := _sample_index(distance_m)
	return points[int(sample.x)].lerp(points[int(sample.y)], sample.z)

func direction_at(distance_m: float) -> Vector3:
	var before := point_at(distance_m - 0.8)
	var after := point_at(distance_m + 0.8)
	return (after - before).normalized()

func right_at(distance_m: float) -> Vector3:
	return direction_at(distance_m).cross(Vector3.UP).normalized()

func world_at(distance_m: float, lateral_m: float = 0.0, height_m: float = 0.0) -> Vector3:
	return point_at(distance_m) + right_at(distance_m) * lateral_m + Vector3.UP * height_m

func _sample_index(distance_m: float) -> Vector3:
	if points.is_empty():
		return Vector3.ZERO
	var wrapped := RouteMath.wrap_distance(distance_m, track_length)
	var index := 0
	while index < cumulative.size() - 1 and cumulative[index + 1] <= wrapped:
		index += 1
	var next_index := (index + 1) % points.size()
	var end_distance := track_length if next_index == 0 else cumulative[next_index]
	var segment_length := maxf(0.001, end_distance - cumulative[index])
	return Vector3(float(index), float(next_index), clampf((wrapped - cumulative[index]) / segment_length, 0.0, 1.0))

func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "Infield"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(360.0, 0.5, 360.0)
	ground.mesh = mesh
	ground.position = Vector3(0.0, -0.48, 0.0)
	ground.material_override = RaceMaterials.surface(Color("#16452f"), 0.96)
	add_child(ground)
	var pad := MeshInstance3D.new()
	pad.name = "TrackApron"
	var pad_mesh := BoxMesh.new()
	pad_mesh.size = Vector3(300.0, 0.10, 300.0)
	pad.mesh = pad_mesh
	pad.position.y = -0.16
	pad.material_override = RaceMaterials.surface(Color("#234438"), 0.94)
	add_child(pad)

func _build_road() -> void:
	_create_ribbon("Asphalt", -road_width * 0.5, road_width * 0.5, 0.08, RaceMaterials.painted_road(Color("#252b33")))
	_create_ribbon("LeftRoadShoulder", -road_width * 0.5 - 1.4, -road_width * 0.5, 0.055, RaceMaterials.painted_road(Color("#38444a")))
	_create_ribbon("RightRoadShoulder", road_width * 0.5, road_width * 0.5 + 1.4, 0.055, RaceMaterials.painted_road(Color("#38444a")))

func _build_markings() -> void:
	_create_ribbon("EdgeLineL", -road_width * 0.5 + 0.48, -road_width * 0.5 + 0.67, 0.13, RaceMaterials.glow(Color("#e5eef0"), 0.22))
	_create_ribbon("EdgeLineR", road_width * 0.5 - 0.67, road_width * 0.5 - 0.48, 0.13, RaceMaterials.glow(Color("#e5eef0"), 0.22))
	_add_dashed_lane(0.0)
	_add_kerbs()

func _create_ribbon(node_name: String, offset_a: float, offset_b: float, height: float, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size()):
		var start_m: float = cumulative[i]
		var end_m: float = track_length if i == points.size() - 1 else cumulative[i + 1]
		var c0 := point_at(start_m)
		var c1 := point_at(end_m)
		var r0 := right_at(start_m)
		var r1 := right_at(end_m)
		var a := c0 + r0 * offset_a + Vector3.UP * height
		var b := c0 + r0 * offset_b + Vector3.UP * height
		var c := c1 + r1 * offset_b + Vector3.UP * height
		var d := c1 + r1 * offset_a + Vector3.UP * height
		_add_quad(surface, a, b, c, d)
	surface.generate_normals()
	var mesh := surface.commit()
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)

func _add_dashed_lane(lateral: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var distance_m := 0.0
	while distance_m < track_length:
		var end_m := minf(distance_m + 8.0, track_length)
		var half_line := 0.11
		var c0 := world_at(distance_m, lateral, 0.15)
		var c1 := world_at(end_m, lateral, 0.15)
		var s0 := right_at(distance_m) * half_line
		var s1 := right_at(end_m) * half_line
		_add_quad(surface, c0 - s0, c0 + s0, c1 + s1, c1 - s1)
		distance_m += 20.0
	surface.generate_normals()
	var line := MeshInstance3D.new()
	line.name = "LaneDashes_%s" % str(lateral).replace(".", "_")
	line.mesh = surface.commit()
	line.material_override = RaceMaterials.glow(Color("#f1f4f1"), 0.18)
	add_child(line)

func _add_kerbs() -> void:
	var red_surface := SurfaceTool.new()
	var white_surface := SurfaceTool.new()
	red_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	white_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var distance_m := 0.0
	var segment_index := 0
	while distance_m < track_length:
		var end_m := minf(distance_m + 4.2, track_length)
		var target_surface := red_surface if segment_index % 2 == 0 else white_surface
		for side in [-1.0, 1.0]:
			var side_value: float = float(side)
			var inner: float = side_value * (road_width * 0.5 + 0.05)
			var outer: float = side_value * (road_width * 0.5 + 1.15)
			var c0 := point_at(distance_m)
			var c1 := point_at(end_m)
			var r0 := right_at(distance_m)
			var r1 := right_at(end_m)
			var a := c0 + r0 * inner + Vector3.UP * 0.11
			var b := c0 + r0 * outer + Vector3.UP * 0.11
			var c := c1 + r1 * outer + Vector3.UP * 0.11
			var d := c1 + r1 * inner + Vector3.UP * 0.11
			if side_value < 0.0:
				_add_quad(target_surface, a, d, c, b)
			else:
				_add_quad(target_surface, a, b, c, d)
		distance_m = end_m
		segment_index += 1
	red_surface.generate_normals()
	white_surface.generate_normals()
	_add_surface_instance("KerbRed", red_surface.commit(), RaceMaterials.surface(Color("#e34b55"), 0.76))
	_add_surface_instance("KerbWhite", white_surface.commit(), RaceMaterials.surface(Color("#ecece7"), 0.78))

func _build_start_grid() -> void:
	var dark_surface := SurfaceTool.new()
	var light_surface := SurfaceTool.new()
	dark_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	light_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var column_count := 18
	var row_count := 2
	var stripe_length := 0.82
	for row in range(row_count):
		var start_m := 11.0 + float(row) * stripe_length
		var end_m := start_m + stripe_length
		for column in range(column_count):
			var left := -road_width * 0.5 + road_width * float(column) / float(column_count)
			var right := -road_width * 0.5 + road_width * float(column + 1) / float(column_count)
			var target := dark_surface if (row + column) % 2 == 0 else light_surface
			var c0 := world_at(start_m, left, 0.16)
			var c1 := world_at(start_m, right, 0.16)
			var c2 := world_at(end_m, right, 0.16)
			var c3 := world_at(end_m, left, 0.16)
			_add_quad(target, c0, c1, c2, c3)
	dark_surface.generate_normals()
	light_surface.generate_normals()
	_add_surface_instance("StartGridDark", dark_surface.commit(), RaceMaterials.surface(Color("#151a20"), 0.9))
	_add_surface_instance("StartGridLight", light_surface.commit(), RaceMaterials.surface(Color("#f1f1ec"), 0.84))

func _add_surface_instance(node_name: String, mesh: ArrayMesh, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)

func _build_barriers() -> void:
	var lateral_offset: float = road_width * 0.5 + 1.85
	var rail_heights: Array[float] = [0.38, 0.78]
	var rail_material := RaceMaterials.surface(Color("#58717c"), 0.62, 0.36) as StandardMaterial3D
	rail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side in [-1.0, 1.0]:
		var lateral: float = float(side) * lateral_offset
		for rail_height in rail_heights:
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in range(points.size()):
				var start_m: float = cumulative[i]
				var end_m: float = track_length if i == points.size() - 1 else cumulative[i + 1]
				var a := world_at(start_m, lateral, rail_height - 0.055)
				var b := world_at(start_m, lateral, rail_height + 0.055)
				var c := world_at(end_m, lateral, rail_height + 0.055)
				var d := world_at(end_m, lateral, rail_height - 0.055)
				if side < 0.0:
					_add_quad(surface, a, d, c, b)
				else:
					_add_quad(surface, a, b, c, d)
			surface.generate_normals()
			_add_surface_instance("GuardRail_%s_%02d" % [str(side), roundi(rail_height * 100.0)], surface.commit(), rail_material)
	var post_spacing: int = 16
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3.ONE
	var posts := MultiMesh.new()
	posts.transform_format = MultiMesh.TRANSFORM_3D
	posts.mesh = post_mesh
	posts.instance_count = int(ceil(track_length / float(post_spacing))) * 2
	var post_index := 0
	for d in range(0, int(track_length), post_spacing):
		for side in [-1.0, 1.0]:
			var lateral: float = float(side) * lateral_offset
			var position := world_at(float(d), lateral, 0.54)
			var transform := Transform3D(Basis.IDENTITY, position)
			transform.basis = transform.basis.scaled(Vector3(0.14, 1.08, 0.14))
			posts.set_instance_transform(post_index, transform)
			post_index += 1
	var post_instance := MultiMeshInstance3D.new()
	post_instance.name = "GuardRailPosts"
	post_instance.multimesh = posts
	post_instance.material_override = RaceMaterials.surface(Color("#344b59"), 0.62, 0.34)
	add_child(post_instance)

func _build_lighting() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#22394f")
	sky_material.sky_horizon_color = Color("#5a7e8d")
	sky_material.ground_bottom_color = Color("#17261f")
	sky_material.ground_horizon_color = Color("#536953")
	sky_material.use_debanding = true
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#8299a5")
	environment.ambient_light_energy = 0.68
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("#6f8589")
	environment.fog_density = 0.0015
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "SunKeyLight"
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_color = Color("#ffd5a0")
	sun.light_energy = 1.12
	sun.shadow_enabled = true
	add_child(sun)

func _add_quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(d)
