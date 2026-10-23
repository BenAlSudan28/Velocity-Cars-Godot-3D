extends RefCounted
class_name CityBuildingFactory

static func populate(parent: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 702615
	var body_transforms: Array[Transform3D] = []
	var body_colors: Array[Color] = []
	var window_transforms: Array[Transform3D] = []
	var window_colors: Array[Color] = []
	var roof_transforms: Array[Transform3D] = []
	var roof_colors: Array[Color] = []
	var businesses: Array[Dictionary] = []
	var palette: Array[Color] = [Color("#294052"), Color("#354d5b"), Color("#4d5960"), Color("#465263"), Color("#59636a"), Color("#3d555b")]
	for block_z in range(CityConfig.ROAD_CENTERS.size() - 1):
		var z0 := float(CityConfig.ROAD_CENTERS[block_z])
		var z1 := float(CityConfig.ROAD_CENTERS[block_z + 1])
		var block_center_z := (z0 + z1) * 0.5
		for block_x in range(CityConfig.ROAD_CENTERS.size() - 1):
			var x0 := float(CityConfig.ROAD_CENTERS[block_x])
			var x1 := float(CityConfig.ROAD_CENTERS[block_x + 1])
			var block_center_x := (x0 + x1) * 0.5
			for lot in range(4):
				var side_x := -1.0 if lot % 2 == 0 else 1.0
				var side_z := -1.0 if lot < 2 else 1.0
				var x := block_center_x + side_x * 13.1
				var z := block_center_z + side_z * 13.1
				var width := rng.randf_range(17.2, 19.6)
				var depth := rng.randf_range(17.2, 19.6)
				var identity := block_x * 19 + block_z * 7 + lot * 11
				var is_hotel := identity % 17 == 0 or identity % 23 == 5
				var is_restaurant := not is_hotel and (identity % 9 == 2 or identity % 13 == 7)
				var height := rng.randf_range(30.0, 43.0) if is_hotel else (rng.randf_range(7.5, 10.5) if is_restaurant else rng.randf_range(15.0, 28.0))
				var building_color := palette[rng.randi_range(0, palette.size() - 1)]
				body_transforms.append(_box_transform(Vector3(x, height * 0.5, z), Vector3(width, height, depth)))
				body_colors.append(building_color)
				var floors := maxi(2, floori((height - 2.2) / 3.25))
				var columns := maxi(3, floori((width - 4.0) / 3.15))
				for floor_index in range(floors):
					var y := 1.9 + float(floor_index) * 3.15
					for column in range(columns):
						var x_offset := -width * 0.5 + 2.0 + float(column) * (width - 4.0) / float(maxi(1, columns - 1))
						var z_offset := -depth * 0.5 + 2.0 + float(column) * (depth - 4.0) / float(maxi(1, columns - 1))
						var glass := Color("#c6aa77") if rng.randf() < 0.12 else Color("#182d3b")
						window_transforms.append(_box_transform(Vector3(x + x_offset, y, z - depth * 0.5 - 0.08), Vector3(1.42, 1.18, 0.16)))
						window_colors.append(glass)
						window_transforms.append(_box_transform(Vector3(x + x_offset, y, z + depth * 0.5 + 0.08), Vector3(1.42, 1.18, 0.16)))
						window_colors.append(glass)
						window_transforms.append(_box_transform(Vector3(x - width * 0.5 - 0.08, y, z + z_offset), Vector3(1.42, 1.18, 0.16), PI * 0.5))
						window_colors.append(glass)
						window_transforms.append(_box_transform(Vector3(x + width * 0.5 + 0.08, y, z + z_offset), Vector3(1.42, 1.18, 0.16), PI * 0.5))
						window_colors.append(glass)
				var roof_height := height + 0.5
				roof_transforms.append(_box_transform(Vector3(x, roof_height, z), Vector3(width * 0.77, 0.55, depth * 0.77)))
				roof_colors.append(building_color.darkened(0.24))
				if is_hotel or is_restaurant:
					var face_normal := Vector3(side_x, 0.0, 0.0) if lot % 2 == 0 else Vector3(0.0, 0.0, side_z)
					var front := Vector3(x, 3.1, z)
					if absf(face_normal.x) > 0.5:
						front.x += face_normal.x * (width * 0.5 + 0.12)
					else:
						front.z += face_normal.z * (depth * 0.5 + 0.12)
					businesses.append({"position": front, "normal": face_normal, "text": "فندق • HOTEL" if is_hotel else "مطعم • RESTAURANT", "color": Color("#e5b957") if is_hotel else Color("#f07845"), "awning": is_restaurant})
	_add_colored_multimesh(parent, "CityBuildingMasses", body_transforms, body_colors, RaceMaterials.surface(Color.WHITE, 0.83, 0.04))
	_add_colored_multimesh(parent, "CityFacadeWindows", window_transforms, window_colors, RaceMaterials.surface(Color.WHITE, 0.31, 0.18))
	_add_colored_multimesh(parent, "CityRoofDetails", roof_transforms, roof_colors, RaceMaterials.surface(Color.WHITE, 0.76, 0.12))
	for business in businesses:
		_add_business_sign(parent, business)

static func _box_transform(position: Vector3, size: Vector3, yaw: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(size), position)

static func _add_colored_multimesh(parent: Node3D, node_name: String, transforms: Array[Transform3D], colors: Array[Color], material: StandardMaterial3D) -> void:
	if transforms.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i, transforms[i])
		multi.set_instance_color(i, colors[i])
	material.vertex_color_use_as_albedo = true
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multi
	instance.material_override = material
	parent.add_child(instance)

static func _add_business_sign(parent: Node3D, data: Dictionary) -> void:
	var position: Vector3 = data["position"]
	var normal: Vector3 = data["normal"]
	var yaw := atan2(-normal.x, -normal.z)
	var sign_panel := MeshInstance3D.new()
	sign_panel.name = "HotelSign" if String(data["text"]).contains("HOTEL") else "RestaurantSign"
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(7.4, 1.35, 0.24)
	sign_panel.mesh = sign_mesh
	sign_panel.position = position
	sign_panel.rotation.y = yaw
	sign_panel.material_override = RaceMaterials.surface(Color("#152330"), 0.42, 0.22)
	parent.add_child(sign_panel)
	var label := Label3D.new()
	label.name = "BusinessName"
	label.text = String(data["text"])
	label.font = RaceTheme.bold_font()
	label.font_size = 48
	label.pixel_size = 0.009
	label.modulate = data["color"]
	label.outline_size = 8
	label.outline_modulate = Color("#101820")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = position + normal * 0.15
	label.rotation.y = yaw + PI
	parent.add_child(label)
	if bool(data["awning"]):
		var canopy := MeshInstance3D.new()
		canopy.name = "RestaurantCanopy"
		var canopy_mesh := BoxMesh.new()
		canopy_mesh.size = Vector3(8.2, 0.42, 1.55)
		canopy.mesh = canopy_mesh
		canopy.position = position + normal * 0.85 - Vector3.UP * 1.08
		canopy.rotation.y = yaw
		canopy.material_override = RaceMaterials.surface(Color("#d6583e"), 0.56, 0.08)
		parent.add_child(canopy)
