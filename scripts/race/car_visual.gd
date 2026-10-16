extends Node3D
class_name CarVisual

var style_index: int = 0
var _model_root: Node3D

func setup(index: int) -> void:
	style_index = posmod(index, CarCatalog.count())
	for child in get_children():
		child.queue_free()
	_model_root = null
	var data := CarCatalog.get_car(style_index)
	var packed := load(String(data["model"])) as PackedScene
	if packed != null:
		_model_root = packed.instantiate() as Node3D
	if _model_root != null:
		add_child(_model_root)
		_normalize_model(_model_root, float(data.get("scale", 1.0)))
		_model_root.rotation_degrees.y += float(data.get("yaw_degrees", 0.0))
	else:
		_build_fallback(Color(String(data["paint"])))

func _normalize_model(model: Node3D, scale_multiplier: float) -> void:
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	var combined := AABB()
	var has_bounds := false
	var inverse := model.global_transform.affine_inverse()
	for item in meshes:
		var mesh_instance := item as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var bounds := mesh_instance.get_aabb()
		var relative := inverse * mesh_instance.global_transform
		var corners: Array[Vector3] = [
			bounds.position,
			bounds.position + Vector3(bounds.size.x, 0.0, 0.0),
			bounds.position + Vector3(0.0, bounds.size.y, 0.0),
			bounds.position + Vector3(0.0, 0.0, bounds.size.z),
			bounds.position + Vector3(bounds.size.x, bounds.size.y, 0.0),
			bounds.position + Vector3(bounds.size.x, 0.0, bounds.size.z),
			bounds.position + Vector3(0.0, bounds.size.y, bounds.size.z),
			bounds.position + bounds.size
		]
		for corner in corners:
			var point := relative * corner
			if has_bounds:
				combined = combined.expand(point)
			else:
				combined = AABB(point, Vector3.ZERO)
				has_bounds = true
	if not has_bounds:
		model.scale = Vector3.ONE * scale_multiplier
		return
	var horizontal_size := maxf(combined.size.x, combined.size.z)
	var fit_scale := 4.4 / maxf(horizontal_size, 0.01)
	model.scale = Vector3.ONE * fit_scale * scale_multiplier
	model.position.y = -combined.position.y * fit_scale * scale_multiplier + 0.04

func _build_fallback(paint: Color) -> void:
	var body := MeshInstance3D.new()
	body.name = "FallbackBody"
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(2.05, 0.70, 4.35)
	body.mesh = body_mesh
	body.position.y = 0.62
	var paint_material := RaceMaterials.surface(paint, 0.23, 0.72)
	paint_material.clearcoat_enabled = true
	body.material_override = paint_material
	add_child(body)
	var cabin := MeshInstance3D.new()
	cabin.name = "Cabin"
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.42, 0.62, 1.85)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0.0, 1.23, 0.12)
	cabin.material_override = RaceMaterials.surface(Color("#122436"), 0.15, 0.32)
	add_child(cabin)
	for x in [-0.98, 0.98]:
		for z in [-1.34, 1.34]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.39
			wheel_mesh.bottom_radius = 0.39
			wheel_mesh.height = 0.22
			wheel.mesh = wheel_mesh
			wheel.rotation.z = PI * 0.5
			wheel.position = Vector3(x, 0.38, z)
			wheel.material_override = RaceMaterials.surface(Color("#11161c"), 0.85)
			add_child(wheel)
	var front_light := MeshInstance3D.new()
	front_light.name = "FrontLightStrip"
	var light_mesh := BoxMesh.new()
	light_mesh.size = Vector3(1.30, 0.08, 0.04)
	front_light.mesh = light_mesh
	front_light.position = Vector3(0.0, 0.78, -2.18)
	front_light.material_override = RaceMaterials.glow(Color("#a8eaff"), 1.5)
	add_child(front_light)
