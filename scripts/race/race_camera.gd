extends Camera3D
class_name RaceCamera

var target: Node3D
var follow_smoothing: float = 5.5

func _ready() -> void:
	current = true
	fov = 72.0
	near = 0.08
	far = 420.0

func bind_target(target_node: Node3D) -> void:
	target = target_node
	if target != null:
		var forward := -target.global_basis.z
		global_position = target.global_position - forward * 10.2 + Vector3.UP * 3.8
		look_at(target.global_position + Vector3.UP * 0.95, Vector3.UP)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var forward := -target.global_basis.z
	var desired := target.global_position - forward * 10.2 + Vector3.UP * 3.8
	global_position = global_position.lerp(desired, clampf(delta * follow_smoothing, 0.0, 1.0))
	var focus := target.global_position + forward * 4.6 + Vector3.UP * 0.95
	look_at(focus, Vector3.UP)
	var target_fov := 71.0 + clampf(float(target.get("speed_mps")) / 90.0, 0.0, 1.0) * 6.0
	fov = lerpf(fov, target_fov, delta * 2.8)
