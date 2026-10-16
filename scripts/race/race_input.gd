extends RefCounted
class_name RaceInput

static func ensure_actions() -> void:
	_add_action("race_accelerate", [KEY_W, KEY_UP])
	_add_action("race_brake", [KEY_S, KEY_DOWN, KEY_SPACE])
	_add_action("race_left", [KEY_A, KEY_LEFT])
	_add_action("race_right", [KEY_D, KEY_RIGHT])
	_add_action("race_nitro", [KEY_SHIFT])
	_add_action("race_pause", [KEY_ESCAPE, KEY_P])
	_add_action("race_confirm", [KEY_ENTER, KEY_KP_ENTER])

static func _add_action(action_name: String, key_codes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.18)
	for key_code: int in key_codes:
		var event := InputEventKey.new()
		event.physical_keycode = key_code
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)
