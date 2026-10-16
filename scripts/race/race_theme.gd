extends RefCounted
class_name RaceTheme

static func regular_font() -> Font:
	return load("res://assets/fonts/NotoSansArabic-Regular.ttf") as Font

static func bold_font() -> Font:
	return load("res://assets/fonts/NotoSansArabic-Bold.ttf") as Font

static func panel_style(color: Color = Color(0.035, 0.065, 0.095, 0.86)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.28, 0.66, 0.79, 0.62)
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(14.0)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 8
	return style

static func button_style(color: Color, hovered: bool = false, pressed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.lightened(0.12) if hovered else color
	if pressed:
		style.bg_color = color.darkened(0.10)
	style.border_color = Color(0.52, 0.88, 0.97, 0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(10.0)
	return style

static func apply_to(control: Control) -> void:
	var theme := Theme.new()
	theme.default_font = regular_font()
	theme.default_font_size = 18
	control.theme = theme
