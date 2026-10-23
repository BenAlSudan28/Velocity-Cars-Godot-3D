extends CanvasLayer
class_name RaceHUD

signal action_requested(action: String)
signal touch_changed(action: String, pressed: bool)

var root: Control
var speed_label: Label
var telemetry_label: Label
var lap_label: Label
var score_label: Label
var free_distance_label: Label
var nitro_bar: ProgressBar
var lap_bar: ProgressBar
var touch_controls: TouchControls

func _ready() -> void:
	root = Control.new()
	root.name = "HUDRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RaceTheme.apply_to(root)
	add_child(root)

func show_menu(car_index: int, audio_enabled: bool) -> void:
	_clear()
	var panel := PanelContainer.new()
	panel.name = "MenuCard"
	_set_rect(panel, Rect2(0.035, 0.045, 0.36, 0.91))
	panel.add_theme_stylebox_override("panel", RaceTheme.panel_style(Color(0.025, 0.055, 0.085, 0.93)))
	root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	panel.add_child(column)
	column.add_child(_make_label("VELOCITY RUSH", 31, Color("#ecf6fb"), HORIZONTAL_ALIGNMENT_CENTER, true))
	column.add_child(_make_label("مدينة مفتوحة • حلبة سباق ثلاثية الأبعاد", 16, Color("#66d8ed"), HORIZONTAL_ALIGNMENT_CENTER))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 9.0
	column.add_child(spacer)
	var car := CarCatalog.get_car(car_index)
	column.add_child(_make_label("سيارتك المختارة", 14, Color("#93aebb"), HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_make_label(String(car["name"]), 25, Color(String(car["paint"])), HORIZONTAL_ALIGNMENT_CENTER, true))
	column.add_child(_make_label(String(car["subtitle"]), 15, Color("#d4e3e9"), HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_make_label("تصميم خيالي أصلي • بلا شعارات تجارية", 11, Color("#87a0ae"), HORIZONTAL_ALIGNMENT_CENTER))
	var chooser := HBoxContainer.new()
	chooser.add_theme_constant_override("separation", 12)
	var previous := _make_button("السابق", "car_previous", false)
	var next := _make_button("التالي", "car_next", false)
	previous.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chooser.add_child(previous)
	chooser.add_child(next)
	column.add_child(chooser)
	column.add_child(_make_label("اختر نمط اللعب", 17, Color("#ecf6fb"), HORIZONTAL_ALIGNMENT_CENTER, true))
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 10)
	var race_button := _make_button("سباق الحلبة\n3 لفات", "start_race", true)
	race_button.custom_minimum_size.y = 61.0
	var city_button := _make_button("قيادة حرة\nمدينة 3D", "start_free_drive", false)
	city_button.custom_minimum_size.y = 61.0
	modes.add_child(race_button)
	modes.add_child(city_button)
	column.add_child(modes)
	column.add_child(_make_label("القيادة الحرة: شوارع متقاطعة، مرور باتجاهين، فنادق ومطاعم.", 12, Color("#b7ccd5"), HORIZONTAL_ALIGNMENT_CENTER))
	var audio_text := "الصوت: تشغيل" if audio_enabled else "الصوت: مكتوم"
	column.add_child(_make_button(audio_text, "audio_toggle", false))
	column.add_child(_make_label("WASD / الأسهم للقيادة • Shift للنيترو في السباق\nEsc للإيقاف المؤقت • تعمل اللعبة دون إنترنت", 12, Color("#a8bdc7"), HORIZONTAL_ALIGNMENT_CENTER))
	_add_label("اختر السيارة ثم ابدأ سباق الحلبة أو تجوّل بحرية في المدينة", Rect2(0.42, 0.90, 0.54, 0.055), 14, Color("#d3e4eb"), HORIZONTAL_ALIGNMENT_CENTER)

func show_race() -> void:
	_clear()
	var top_left := _panel(Rect2(0.022, 0.028, 0.255, 0.15))
	var left_column := VBoxContainer.new()
	left_column.add_theme_constant_override("separation", 0)
	top_left.add_child(left_column)
	speed_label = _make_label("000\nكم/س", 25, Color("#f1f8fb"), HORIZONTAL_ALIGNMENT_LEFT, true)
	left_column.add_child(speed_label)
	telemetry_label = _make_label("المسافة 0 م", 14, Color("#97b9c8"), HORIZONTAL_ALIGNMENT_LEFT)
	left_column.add_child(telemetry_label)
	var center := _panel(Rect2(0.37, 0.028, 0.28, 0.15))
	var center_column := VBoxContainer.new()
	center_column.add_theme_constant_override("separation", 4)
	center.add_child(center_column)
	lap_label = _make_label("اللفة 1 من 3 • المركز 1", 18, Color("#f1f8fb"), HORIZONTAL_ALIGNMENT_CENTER, true)
	center_column.add_child(lap_label)
	lap_bar = _make_progress_bar(Color("#31bed9"))
	center_column.add_child(lap_bar)
	var right := _panel(Rect2(0.725, 0.028, 0.25, 0.15))
	var right_column := VBoxContainer.new()
	right.add_child(right_column)
	right_column.add_child(_make_label("النقاط", 13, Color("#94b4c2"), HORIZONTAL_ALIGNMENT_RIGHT))
	score_label = _make_label("0", 24, Color("#f4c76a"), HORIZONTAL_ALIGNMENT_RIGHT, true)
	right_column.add_child(score_label)
	right_column.add_child(_make_label("نيترو", 12, Color("#6ce3f5"), HORIZONTAL_ALIGNMENT_RIGHT))
	nitro_bar = _make_progress_bar(Color("#48d8ef"))
	right_column.add_child(nitro_bar)
	_add_label("تجاوز المنافسين واجمع طاقة النيترو", Rect2(0.34, 0.91, 0.33, 0.045), 13, Color("#d3e4eb"), HORIZONTAL_ALIGNMENT_CENTER)
	_create_touch_controls(true)

func show_free_drive() -> void:
	_clear()
	var top_left := _panel(Rect2(0.022, 0.028, 0.255, 0.15))
	var left_column := VBoxContainer.new()
	left_column.add_theme_constant_override("separation", 0)
	top_left.add_child(left_column)
	speed_label = _make_label("000\nكم/س", 25, Color("#f1f8fb"), HORIZONTAL_ALIGNMENT_LEFT, true)
	left_column.add_child(speed_label)
	telemetry_label = _make_label("المسافة 0 م", 14, Color("#97b9c8"), HORIZONTAL_ALIGNMENT_LEFT)
	left_column.add_child(telemetry_label)
	var city_panel := _panel(Rect2(0.68, 0.028, 0.30, 0.15))
	var city_column := VBoxContainer.new()
	city_column.add_theme_constant_override("separation", 3)
	city_panel.add_child(city_column)
	city_column.add_child(_make_label("قيادة حرة • المدينة", 18, Color("#f1f8fb"), HORIZONTAL_ALIGNMENT_CENTER, true))
	free_distance_label = _make_label("تقاطع طرق • مرور حي", 14, Color("#73d8ea"), HORIZONTAL_ALIGNMENT_CENTER)
	city_column.add_child(free_distance_label)
	_add_label("اختر أي شارع عند التقاطعات وتفادَ حركة المرور", Rect2(0.30, 0.91, 0.40, 0.045), 13, Color("#d3e4eb"), HORIZONTAL_ALIGNMENT_CENTER)
	_create_touch_controls(false)

func _create_touch_controls(show_nitro: bool) -> void:
	touch_controls = TouchControls.new()
	touch_controls.name = "TouchControls"
	touch_controls.hold_changed.connect(func(action: String, pressed: bool): touch_changed.emit(action, pressed))
	touch_controls.pause_pressed.connect(func(): action_requested.emit("pause"))
	root.add_child(touch_controls)
	touch_controls.set_nitro_visible(show_nitro)

func show_pause(free_drive: bool = false) -> void:
	_clear()
	_add_overlay()
	var panel := _panel(Rect2(0.31, 0.23, 0.38, 0.54))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	column.add_child(_make_label("توقف مؤقت", 30, Color("#f0f7fa"), HORIZONTAL_ALIGNMENT_CENTER, true))
	var context := "يمكنك استئناف التجوّل أو إعادة القيادة الحرة." if free_drive else "يمكنك استئناف السباق أو البدء من جديد."
	column.add_child(_make_label(context, 15, Color("#a9c1cc"), HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_make_button("استئناف القيادة", "resume", true))
	column.add_child(_make_button("إعادة الوضع الحالي", "retry", false))
	column.add_child(_make_button("القائمة الرئيسية", "menu", false))

func show_results(won: bool, score: int, distance_m: float, collisions: int, position: int) -> void:
	_clear()
	_add_overlay()
	var panel := _panel(Rect2(0.27, 0.18, 0.46, 0.64))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	panel.add_child(column)
	var title := "فوز رائع!" if won else "انتهى السباق"
	column.add_child(_make_label(title, 34, Color("#f1c96d") if won else Color("#f0f7fa"), HORIZONTAL_ALIGNMENT_CENTER, true))
	column.add_child(_make_label("المركز %d  •  النقاط %d" % [position, score], 22, Color("#66d8ed"), HORIZONTAL_ALIGNMENT_CENTER, true))
	column.add_child(_make_label("المسافة: %s" % RaceConfig.format_distance(distance_m), 17, Color("#d5e2e8"), HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_make_label("الاصطدامات: %d" % collisions, 15, Color("#afc2cb"), HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_make_button("إعادة السباق", "retry", true))
	column.add_child(_make_button("العودة إلى القائمة", "menu", false))

func update_race(speed_kmh: float, distance_m: float, score: int, lap: int, position: int, nitro: float, lap_progress: float, elapsed_seconds: float) -> void:
	if is_instance_valid(speed_label):
		speed_label.text = "%03d\nكم/س" % maxi(0, roundi(speed_kmh))
	if is_instance_valid(telemetry_label):
		telemetry_label.text = "المسافة %s  •  %02d:%02d" % [RaceConfig.format_distance(distance_m), int(elapsed_seconds / 60.0), int(fmod(elapsed_seconds, 60.0))]
	if is_instance_valid(lap_label):
		lap_label.text = "اللفة %d من %d  •  المركز %d" % [lap, RaceConfig.LAP_COUNT, position]
	if is_instance_valid(score_label):
		score_label.text = "%07d" % score
	if is_instance_valid(nitro_bar):
		nitro_bar.value = clampf(nitro, 0.0, 100.0)
	if is_instance_valid(lap_bar):
		lap_bar.value = clampf(lap_progress * 100.0, 0.0, 100.0)

func update_free_drive(speed_kmh: float, distance_m: float, elapsed_seconds: float) -> void:
	if is_instance_valid(speed_label):
		speed_label.text = "%03d\nكم/س" % maxi(0, roundi(speed_kmh))
	if is_instance_valid(telemetry_label):
		telemetry_label.text = "المسافة %s  •  %02d:%02d" % [RaceConfig.format_distance(distance_m), int(elapsed_seconds / 60.0), int(fmod(elapsed_seconds, 60.0))]
	if is_instance_valid(free_distance_label):
		free_distance_label.text = "تجوّلت %s • مرور باتجاهين" % RaceConfig.format_distance(distance_m)

func show_countdown(text: String) -> void:
	_add_label(text, Rect2(0.42, 0.36, 0.16, 0.16), 54, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER, true)

func _clear() -> void:
	if touch_controls != null and is_instance_valid(touch_controls):
		touch_controls.release_all()
	touch_controls = null
	speed_label = null
	telemetry_label = null
	lap_label = null
	score_label = null
	free_distance_label = null
	nitro_bar = null
	lap_bar = null
	for child in root.get_children():
		child.queue_free()

func _panel(rect: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	_set_rect(panel, rect)
	panel.add_theme_stylebox_override("panel", RaceTheme.panel_style())
	root.add_child(panel)
	return panel

func _add_overlay() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.008, 0.018, 0.032, 0.76)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)

func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_override("font", RaceTheme.bold_font() if bold else RaceTheme.regular_font())
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _add_label(text: String, rect: Rect2, font_size: int, color: Color, alignment: HorizontalAlignment, bold: bool = false) -> Label:
	var label := _make_label(text, font_size, color, alignment, bold)
	_set_rect(label, rect)
	root.add_child(label)
	return label

func _make_button(text: String, action: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 46.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_font_override("font", RaceTheme.bold_font())
	button.add_theme_color_override("font_color", Color("#f1f7fb"))
	button.add_theme_stylebox_override("normal", RaceTheme.button_style(Color("#067c97") if primary else Color("#183347")))
	button.add_theme_stylebox_override("hover", RaceTheme.button_style(Color("#078aa8") if primary else Color("#24485c"), true))
	button.add_theme_stylebox_override("pressed", RaceTheme.button_style(Color("#05647b") if primary else Color("#122a3a"), false, true))
	button.pressed.connect(func(): action_requested.emit(action))
	return button

func _make_progress_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 13.0
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.show_percentage = false
	var background := RaceTheme.panel_style(Color("#0d1b29"))
	background.set_corner_radius_all(7)
	var fill := RaceTheme.button_style(fill_color)
	fill.set_corner_radius_all(7)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _set_rect(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.position.x + rect.size.x
	control.anchor_bottom = rect.position.y + rect.size.y
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
