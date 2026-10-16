extends Racer
class_name PlayerDriver

func _ready() -> void:
	super._ready()
	is_player = true

func drive_from_input(delta: float, input_state: Dictionary) -> void:
	var throttle := clampf(float(input_state.get("throttle", 0.0)), 0.0, 1.0)
	var brake := clampf(float(input_state.get("brake", 0.0)), 0.0, 1.0)
	var steering := clampf(float(input_state.get("steering", 0.0)), -1.0, 1.0)
	var boost := bool(input_state.get("boost", false))
	apply_player_drive(delta, throttle, brake, steering, boost)
