extends Node3D
class_name FreeDriveCity

var traffic_cars: Array[CityTrafficCar] = []
var simulation_enabled: bool = true

func _ready() -> void:
	_build_environment()
	_build_ground()
	_build_road_grid()
	_build_sidewalks_and_curbs()
	_build_lane_markings()
	_build_crosswalks()
	CityBuildingFactory.populate(self)
	_build_street_lighting()
	_build_traffic_signals()
	_spawn_traffic()

func _physics_process(delta: float) -> void:
	if not simulation_enabled:
		return
	for car in traffic_cars:
		if is_instance_valid(car):
			car.advance(delta)

func set_simulation_enabled(enabled: bool) -> void:
	simulation_enabled = enabled
	set_physics_process(enabled)

func is_drivable_position(position: Vector3) -> bool:
	return CityConfig.is_drivable_position(position)

func resolve_traffic_collision(player: FreeDriveController) -> bool:
	if player == null:
		return false
	for car in traffic_cars:
		if is_instance_valid(car) and player.global_position.distance_squared_to(car.global_position) < 13.0:
			if player.register_collision():
				return true
	return false

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "CityEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#91aaad")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#b5c5bc")
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "CitySun"
	sun.rotation_degrees = Vector3(-48.0, -29.0, 0.0)
	sun.light_color = Color("#ffe0b9")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)

func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "CityGround"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(CityConfig.CITY_SPAN, 0.6, CityConfig.CITY_SPAN)
	ground.mesh = mesh
	ground.position = Vector3(0.0, -0.34, 0.0)
	ground.material_override = RaceMaterials.surface(Color("#465b49"), 0.96)
	add_child(ground)

func _build_road_grid() -> void:
	var transforms: Array[Transform3D] = []
	for center_value in CityConfig.ROAD_CENTERS:
		var center := float(center_value)
		transforms.append(_box_transform(Vector3(0.0, 0.015, center), Vector3(CityConfig.CITY_SPAN, 0.14, CityConfig.ROAD_WIDTH)))
		transforms.append(_box_transform(Vector3(center, 0.015, 0.0), Vector3(CityConfig.ROAD_WIDTH, 0.14, CityConfig.CITY_SPAN)))
	_add_multimesh("CrossStreetNetwork", BoxMesh.new(), transforms, RaceMaterials.painted_road(Color("#30363c")))

func _build_sidewalks_and_curbs() -> void:
	var sidewalks: Array[Transform3D] = []
	var curbs: Array[Transform3D] = []
	var offset := CityConfig.ROAD_HALF_WIDTH + CityConfig.SIDEWALK_WIDTH * 0.5
	for center_value in CityConfig.ROAD_CENTERS:
		var center := float(center_value)
		for side in [-1.0, 1.0]:
			var edge := float(side) * offset
			sidewalks.append(_box_transform(Vector3(0.0, 0.08, center + edge), Vector3(CityConfig.CITY_SPAN, 0.30, CityConfig.SIDEWALK_WIDTH)))
			sidewalks.append(_box_transform(Vector3(center + edge, 0.08, 0.0), Vector3(CityConfig.SIDEWALK_WIDTH, 0.30, CityConfig.CITY_SPAN)))
			var curb := float(side) * (CityConfig.ROAD_HALF_WIDTH + 0.15)
			curbs.append(_box_transform(Vector3(0.0, 0.12, center + curb), Vector3(CityConfig.CITY_SPAN, 0.32, 0.30)))
			curbs.append(_box_transform(Vector3(center + curb, 0.12, 0.0), Vector3(0.30, 0.32, CityConfig.CITY_SPAN)))
	_add_multimesh("ConcreteSidewalks", BoxMesh.new(), sidewalks, RaceMaterials.surface(Color("#aaa99f"), 0.88, 0.02))
	_add_multimesh("RoadCurbs", BoxMesh.new(), curbs, RaceMaterials.surface(Color("#d2cfc3"), 0.8, 0.02))

func _build_lane_markings() -> void:
	var white_marks: Array[Transform3D] = []
	var yellow_marks: Array[Transform3D] = []
	for center_value in CityConfig.ROAD_CENTERS:
		var center := float(center_value)
		for distance in range(-170, 171, 16):
			if _near_intersection(float(distance)):
				continue
			for lane_offset in [-6.0, 6.0]:
				var lateral := float(lane_offset)
				white_marks.append(_box_transform(Vector3(float(distance), 0.092, center + lateral), Vector3(3.6, 0.035, 0.14)))
				white_marks.append(_box_transform(Vector3(center + lateral, 0.092, float(distance)), Vector3(0.14, 0.035, 3.6)))
		for distance in range(-170, 171, 15):
			if _near_intersection(float(distance)):
				continue
			for center_offset in [-0.34, 0.34]:
				var lateral_center := center + float(center_offset)
				yellow_marks.append(_box_transform(Vector3(float(distance), 0.095, lateral_center), Vector3(7.0, 0.04, 0.14)))
				yellow_marks.append(_box_transform(Vector3(lateral_center, 0.095, float(distance)), Vector3(0.14, 0.04, 7.0)))
	_add_multimesh("BrokenWhiteLaneLines", BoxMesh.new(), white_marks, RaceMaterials.surface(Color("#e5e3d8"), 0.66, 0.02))
	_add_multimesh("DoubleYellowCenterLines", BoxMesh.new(), yellow_marks, RaceMaterials.surface(Color("#f0bf55"), 0.58, 0.02))

func _build_crosswalks() -> void:
	var stripes: Array[Transform3D] = []
	var stop_lines: Array[Transform3D] = []
	for x_value in CityConfig.ROAD_CENTERS:
		var x_center := float(x_value)
		for z_value in CityConfig.ROAD_CENTERS:
			var z_center := float(z_value)
			for side in [-1.0, 1.0]:
				for stripe in range(5):
					var offset := CityConfig.ROAD_HALF_WIDTH + 0.65 + float(stripe) * 0.52
					var x := x_center + float(side) * offset
					stripes.append(_box_transform(Vector3(x, 0.098, z_center), Vector3(0.22, 0.035, CityConfig.ROAD_WIDTH - 5.0)))
					var z := z_center + float(side) * offset
					stripes.append(_box_transform(Vector3(x_center, 0.098, z), Vector3(CityConfig.ROAD_WIDTH - 5.0, 0.035, 0.22)))
				stop_lines.append(_box_transform(Vector3(x_center + float(side) * (CityConfig.ROAD_HALF_WIDTH - 1.2), 0.10, z_center), Vector3(0.13, 0.04, CityConfig.ROAD_WIDTH - 4.0)))
				stop_lines.append(_box_transform(Vector3(x_center, 0.10, z_center + float(side) * (CityConfig.ROAD_HALF_WIDTH - 1.2)), Vector3(CityConfig.ROAD_WIDTH - 4.0, 0.04, 0.13)))
	_add_multimesh("ZebraCrosswalks", BoxMesh.new(), stripes, RaceMaterials.surface(Color("#f3f0e6"), 0.7, 0.01))
	_add_multimesh("IntersectionStopLines", BoxMesh.new(), stop_lines, RaceMaterials.surface(Color("#ede9dc"), 0.68, 0.01))

func _build_street_lighting() -> void:
	var poles: Array[Transform3D] = []
	var arms: Array[Transform3D] = []
	var lamps: Array[Transform3D] = []
	for center_value in CityConfig.ROAD_CENTERS:
		var center := float(center_value)
		for distance in range(-140, 141, 70):
			if _near_intersection(float(distance)):
				continue
			for side in [-1.0, 1.0]:
				var offset := float(side) * (CityConfig.ROAD_HALF_WIDTH + 3.4)
				var h := Vector3(float(distance), 3.4, center + offset)
				var v := Vector3(center + offset, 3.4, float(distance))
				poles.append(_box_transform(h, Vector3(0.22, 6.8, 0.22)))
				poles.append(_box_transform(v, Vector3(0.22, 6.8, 0.22)))
				arms.append(_box_transform(h + Vector3(0.0, 3.15, -float(side) * 0.9), Vector3(2.4, 0.16, 0.18)))
				arms.append(_box_transform(v + Vector3(float(side) * 0.9, 3.15, 0.0), Vector3(0.18, 0.16, 2.4)))
				lamps.append(_box_transform(h + Vector3(0.0, 3.28, -float(side) * 1.6), Vector3(0.6, 0.12, 0.55)))
				lamps.append(_box_transform(v + Vector3(float(side) * 1.6, 3.28, 0.0), Vector3(0.55, 0.12, 0.6)))
	_add_multimesh("StreetlightPoles", BoxMesh.new(), poles, RaceMaterials.surface(Color("#53636b"), 0.42, 0.56))
	_add_multimesh("StreetlightArms", BoxMesh.new(), arms, RaceMaterials.surface(Color("#637781"), 0.4, 0.5))
	_add_multimesh("StreetlightLamps", BoxMesh.new(), lamps, RaceMaterials.glow(Color("#ffe5aa"), 0.55))

func _build_traffic_signals() -> void:
	var poles: Array[Transform3D] = []
	var housings: Array[Transform3D] = []
	var red_lights: Array[Transform3D] = []
	var amber_lights: Array[Transform3D] = []
	var green_lights: Array[Transform3D] = []
	for center_x in [-75.0, 0.0, 75.0]:
		for center_z in [-75.0, 0.0, 75.0]:
			var x := float(center_x) + 13.6
			var z := float(center_z) + 13.6
			poles.append(_box_transform(Vector3(x, 2.65, z), Vector3(0.20, 5.3, 0.20)))
			housings.append(_box_transform(Vector3(x, 4.95, z - 0.12), Vector3(0.78, 1.82, 0.50)))
			red_lights.append(_box_transform(Vector3(x, 5.48, z - 0.40), Vector3(0.34, 0.34, 0.12)))
			amber_lights.append(_box_transform(Vector3(x, 4.96, z - 0.40), Vector3(0.34, 0.34, 0.12)))
			green_lights.append(_box_transform(Vector3(x, 4.44, z - 0.40), Vector3(0.34, 0.34, 0.12)))
	_add_multimesh("TrafficSignalPoles", BoxMesh.new(), poles, RaceMaterials.surface(Color("#475963"), 0.42, 0.42))
	_add_multimesh("TrafficSignalHousings", BoxMesh.new(), housings, RaceMaterials.surface(Color("#101a21"), 0.3, 0.18))
	_add_multimesh("TrafficSignalRed", BoxMesh.new(), red_lights, RaceMaterials.glow(Color("#f14c4c"), 0.85))
	_add_multimesh("TrafficSignalAmber", BoxMesh.new(), amber_lights, RaceMaterials.glow(Color("#f4bc4e"), 0.55))
	_add_multimesh("TrafficSignalGreen", BoxMesh.new(), green_lights, RaceMaterials.glow(Color("#46d286"), 0.45))

func _spawn_traffic() -> void:
	var routes: Array = [
		[Vector3(-150.0, 0.0, -3.8), Vector3(150.0, 0.0, -3.8), Vector3(150.0, 0.0, 71.2), Vector3(-150.0, 0.0, 71.2)],
		[Vector3(150.0, 0.0, 3.8), Vector3(-150.0, 0.0, 3.8), Vector3(-150.0, 0.0, -71.2), Vector3(150.0, 0.0, -71.2)],
		[Vector3(-3.8, 0.0, 150.0), Vector3(-3.8, 0.0, -150.0), Vector3(71.2, 0.0, -150.0), Vector3(71.2, 0.0, 150.0)],
		[Vector3(3.8, 0.0, -150.0), Vector3(3.8, 0.0, 150.0), Vector3(-71.2, 0.0, 150.0), Vector3(-71.2, 0.0, -150.0)]
	]
	var phases: Array[float] = [108.0, 470.0, 265.0, 590.0, 135.0, 530.0, 295.0, 625.0]
	for i in range(CityConfig.TRAFFIC_COUNT):
		var car := CityTrafficCar.new()
		car.name = "CityTraffic_%02d" % i
		add_child(car)
		var route: Array[Vector3] = []
		for point_value in routes[i % routes.size()]:
			route.append(point_value as Vector3)
		car.configure(route, phases[i], i % CarCatalog.count(), 43.0 + float((i * 7) % 28))
		traffic_cars.append(car)

func _near_intersection(distance: float) -> bool:
	for center_value in CityConfig.ROAD_CENTERS:
		if absf(distance - float(center_value)) < CityConfig.ROAD_HALF_WIDTH + 4.0:
			return true
	return false

func _box_transform(position: Vector3, size: Vector3, yaw: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(size), position)

func _add_multimesh(node_name: String, mesh: Mesh, transforms: Array[Transform3D], material: Material) -> void:
	if transforms.is_empty():
		return
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = Vector3.ONE
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multi
	instance.material_override = material
	add_child(instance)
