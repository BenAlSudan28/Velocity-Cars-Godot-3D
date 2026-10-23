extends Control
class_name TouchControls

signal hold_changed(action: String, pressed: bool)
signal pause_pressed

var _held: Dictionary = {}
var nitro_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_create_hold_button("◀", "left", Rect2(0.035, 0.755, 0.10, 0.19), Color("#18384b"))
	_create_hold_button("▶", "right", Rect2(0.145, 0.755, 0.10, 0.19), Color("#18384b"))
	_create_hold_button("فرامل", "brake", Rect2(0.715, 0.775, 0.105, 0.17), Color("#56313b"))
	_create_hold_button("تسارع", "accelerate", Rect2(0.835, 0.705, 0.13, 0.24), Color("#087d9b"))
	nitro_button = _create_hold_button("نيترو", "nitro", Rect2(0.815, 0.535, 0.15, 0.105), Color("#07566b"))
	var pause_button := _make_button("Ⅱ", Rect2(0.46, 0.80, 0.08, 0.10), Color("#1c2a3a"))
	pause_button.pressed.connect(func(): pause_pressed.emit())

func _create_hold_button(label: String, action: String, rect: Rect2, color: Color) -> Button:
	var button := _make_button(label, rect, color)
	button.button_down.connect(func(): _set_held(action, true))
	button.button_up.connect(func(): _set_held(action, false))
	button.mouse_exited.connect(func():
		if bool(_held.get(action, false)):
			_set_held(action, false)
	)
	return button

func _make_button(label: String, rect: Rect2, color: Color) -> Button:
	var button := Button.new()
	button.text = label
	button.anchor_left = rect.position.x
	button.anchor_top = rect.position.y
	button.anchor_right = rect.position.x + rect.size.x
	button.anchor_bottom = rect.position.y + rect.size.y
	button.offset_left = 0.0
	button.offset_top = 0.0
	button.offset_right = 0.0
	button.offset_bottom = 0.0
	button.custom_minimum_size = Vector2(72.0, 54.0)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("#f1f7fb"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", RaceTheme.button_style(Color(color.r, color.g, color.b, 0.78)))
	button.add_theme_stylebox_override("hover", RaceTheme.button_style(Color(color.r, color.g, color.b, 0.91), true))
	button.add_theme_stylebox_override("pressed", RaceTheme.button_style(color, false, true))
	button.focus_mode = Control.FOCUS_NONE
	add_child(button)
	return button

func set_nitro_visible(visible_now: bool) -> void:
	if is_instance_valid(nitro_button):
		nitro_button.visible = visible_now

func _set_held(action: String, pressed: bool) -> void:
	_held[action] = pressed
	hold_changed.emit(action, pressed)

func release_all() -> void:
	for action in _held.keys():
		if bool(_held[action]):
			_set_held(String(action), false)
