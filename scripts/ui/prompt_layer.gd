class_name PromptLayer
extends Control

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiLayoutSpec := preload("res://scripts/ui/ui_layout_spec.gd")

const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const LINE := Color("#495569")
const INK := Color("#090704")
const SHADOW := Color("#050403")

var label_layer: Control
var action_bar: HBoxContainer
var banner_text: String = ""
var banner_alpha: float = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_update_rects()

	label_layer = Control.new()
	label_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	label_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label_layer)

	action_bar = HBoxContainer.new()
	action_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	action_bar.add_theme_constant_override("separation", 14)
	action_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	action_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	_layout_action_bar()
	add_child(action_bar)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_rects()
		_layout_action_bar()

func _update_rects() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	size = viewport_size
	position = Vector2.ZERO

func _layout_action_bar() -> void:
	if action_bar == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var row := UiLayoutSpec.PRIMARY_ACTION_ROW
	action_bar.position = Vector2(row.position.x, viewport_size.y - (UiLayoutSpec.CANVAS_SIZE.y - row.position.y))
	action_bar.size = Vector2(max(1.0, viewport_size.x - row.position.x * 2.0), row.size.y)

func clear() -> void:
	_clear_children_now(label_layer)
	_clear_children_now(action_bar)

func _clear_children_now(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func set_banner(text: String, alpha: float) -> void:
	banner_text = text
	banner_alpha = alpha
	queue_redraw()

func _draw() -> void:
	if banner_alpha > 0.0:
		var alpha: float = min(0.68, banner_alpha)
		var rect := Rect2(948, 104, 136, 32)
		UiSkin.draw_prompt_strip(self, rect, Color(1, 1, 1, 0.30 * alpha))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(14, 22), banner_text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 28.0, 13, Color(INK, alpha))
	var viewport_size: Vector2 = get_viewport_rect().size
	var zone := UiLayoutSpec.BOTTOM_ACTION_ZONE
	var strip := Rect2(Vector2(zone.position.x, viewport_size.y - (UiLayoutSpec.CANVAS_SIZE.y - zone.position.y)), Vector2(max(1.0, viewport_size.x - zone.position.x * 2.0), zone.size.y))
	UiSkin.draw_prompt_strip(self, strip, Color(1, 1, 1, 0.30))

func add_label(text: String, pos: Vector2, box: Vector2, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var label: Label = Label.new()
	label.text = text
	label.position = pos
	label.size = box
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label_layer.add_child(label)

func add_button(text: String, callback: Callable, enabled: bool = true, primary: bool = false) -> void:
	_layout_action_bar()
	var button: Button = Button.new()
	button.text = text
	button.disabled = not enabled
	button.custom_minimum_size = UiLayoutSpec.COMBAT_BUTTON_SIZE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_action_button(button, primary)
	button.pressed.connect(callback)
	action_bar.add_child(button)

func _apply_action_button(button: Button, primary: bool) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18 if primary else 16)
	button.add_theme_color_override("font_color", Color("#f8efe1"))
	button.add_theme_color_override("font_hover_color", Color("#fff6dc"))
	button.add_theme_color_override("font_pressed_color", Color("#f2be4b"))
	button.add_theme_color_override("font_disabled_color", Color("#8c8579", 0.62))
	button.add_theme_stylebox_override("normal", _action_button_style(primary, "normal"))
	button.add_theme_stylebox_override("hover", _action_button_style(primary, "hover"))
	button.add_theme_stylebox_override("pressed", _action_button_style(primary, "pressed"))
	button.add_theme_stylebox_override("disabled", _action_button_style(primary, "disabled"))

func _action_button_style(primary: bool, state: String) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	var fill := Color("#3b2714") if primary else Color("#251a10")
	var edge := GOLD if primary else Color("#a88956")
	var border_width := 2 if primary else 1
	if state == "hover":
		fill = Color("#4b3219") if primary else Color("#322416")
		edge = Color("#ffe08a") if primary else Color("#d0a461")
	elif state == "pressed":
		fill = Color("#1f1309") if primary else Color("#18100a")
		edge = Color("#ffd36a") if primary else Color("#b98b4a")
		border_width = 3 if primary else 2
	elif state == "disabled":
		fill = Color("#11161e", 0.82)
		edge = Color(LINE, 0.42)
		border_width = 1
	style.bg_color = fill
	style.border_color = edge
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(SHADOW, 0.48 if state != "pressed" and state != "disabled" else 0.22)
	style.shadow_size = 4 if state != "pressed" else 1
	style.shadow_offset = Vector2(0.0, 3.0 if state != "pressed" else 1.0)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0 if state != "pressed" else 12.0
	style.content_margin_bottom = 10.0 if state != "pressed" else 8.0
	return style
