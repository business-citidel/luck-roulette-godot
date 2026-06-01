class_name UiSkin
extends RefCounted

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const UiLayoutSpec := preload("res://scripts/ui/ui_layout_spec.gd")

const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const LINE := Color("#6f6047")
const PANEL := Color("#121923")
const PANEL_DARK := Color("#090d13")
const TABLE_BROWN := Color("#2b1a11")
const RED := Color("#ee5b5b")
const GREEN := Color("#65d48e")

static func button_style(primary: bool = false, disabled: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#3b2a16") if primary else Color("#2a2015")
	if disabled:
		style.bg_color = Color("#11161e")
	style.border_color = GOLD if primary else Color("#a88956")
	if disabled:
		style.border_color = Color(LINE, 0.42)
	var width := 2 if primary else 1
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

static func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PANEL, 0.94)
	style.border_color = Color(LINE, 0.85)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

static func apply_button(button: Button, primary: bool = false) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_disabled_color", Color(MUTED, 0.42))
	button.add_theme_stylebox_override("normal", button_style(primary, false))
	button.add_theme_stylebox_override("hover", button_style(true if primary else false, false))
	button.add_theme_stylebox_override("pressed", button_style(primary, false))
	button.add_theme_stylebox_override("disabled", button_style(primary, true))

static func draw_panel(target: CanvasItem, rect: Rect2, accent: Color = GOLD, fill_alpha: float = 0.94) -> void:
	target.draw_rect(rect, Color(PANEL, fill_alpha), true)
	target.draw_rect(rect, Color("#070a10", 0.72), false, 6.0)
	target.draw_rect(rect.grow(-3.0), Color(accent, 0.82), false, 2.0)
	_draw_corner_marks(target, rect, accent)

static func draw_title_panel(target: CanvasItem, rect: Rect2, accent: Color = GOLD) -> void:
	draw_panel(target, rect, accent, 0.88)

static func draw_parchment_card(target: CanvasItem, rect: Rect2, variant: String = "small", tint: Color = Color.WHITE) -> void:
	var texture_id := "parchment_card_large" if variant == "large" else "parchment_card_small"
	if _draw_physical_texture(target, texture_id, rect, tint):
		return
	target.draw_rect(rect, Color("#d4b879", 0.96) * tint, true)
	target.draw_rect(rect, Color("#1a1209", 0.78), false, 3.0)
	target.draw_rect(rect.grow(-5.0), Color("#6f4a1e", 0.42), false, 1.0)

static func draw_table_stage(target: CanvasItem, rect: Rect2 = UiLayoutSpec.TABLE_STAGE, inner_rect: Rect2 = UiLayoutSpec.INNER_TABLE, tint: Color = Color.WHITE) -> void:
	target.draw_rect(rect, Color("#130b08", 0.98) * tint, true)
	target.draw_rect(rect, Color("#5a3b22", 0.42) * tint, false, 4.0)
	target.draw_rect(inner_rect, Color("#25170e", 0.98) * tint, true)
	target.draw_rect(inner_rect, Color("#8a642f", 0.5) * tint, false, 3.0)
	for i in range(7):
		var y := inner_rect.position.y + 24.0 + float(i) * 72.0
		target.draw_line(inner_rect.position + Vector2(18.0, y - inner_rect.position.y), Vector2(inner_rect.end.x - 18.0, y), Color("#5a3b22", 0.13) * tint, 1.0)

static func draw_offer_card(target: CanvasItem, rect: Rect2, state: String = "normal", tint: Color = Color.WHITE) -> void:
	var final_tint := tint
	if state == "disabled" or state == "locked" or state == "unaffordable" or state == "sold" or state == "resolved":
		final_tint = Color(tint, 0.48)
	elif state == "chosen" or state == "current" or state == "available" or state == "selected" or state == "hover":
		final_tint = Color(tint, min(1.0, tint.a + 0.08))
	draw_parchment_card(target, rect, "small", final_tint)
	target.draw_rect(rect.grow(-18.0), Color("#f1d79c", 0.34) * final_tint, true)
	target.draw_rect(rect.grow(-18.0), Color("#5a3418", 0.18) * final_tint, false, 1.0)
	if state == "hover":
		target.draw_rect(rect.grow(-9.0), Color(GOLD, 0.5) * tint, false, 2.0)
	elif state == "selected":
		target.draw_rect(rect.grow(-8.0), Color("#ffe08a", 0.62) * tint, false, 3.0)
	var marker_pos := rect.position + Vector2(rect.size.x - 30.0, 30.0)
	if state != "" and state != "normal":
		draw_state_token(target, marker_pos, state, 18.0, final_tint)

static func draw_resource_ledger(target: CanvasItem, rect: Rect2, tint: Color = Color.WHITE) -> void:
	draw_ledger_slip(target, rect, tint)
	var line_y := rect.position.y + rect.size.y * 0.5
	target.draw_line(rect.position + Vector2(18.0, line_y - rect.position.y), rect.end - Vector2(18.0, rect.size.y - line_y), Color("#5a4128", 0.25) * tint, 1.0)

static func draw_result_tray(target: CanvasItem, rect: Rect2 = UiLayoutSpec.RESULT_TRAY, tint: Color = Color.WHITE) -> void:
	draw_prompt_strip(target, rect, Color(tint, min(tint.a, 0.84)))
	target.draw_rect(rect.grow(-5.0), Color(GOLD, 0.28) * tint, false, 1.0)

static func draw_state_token(target: CanvasItem, center: Vector2, state: String = "current", radius: float = 18.0, tint: Color = Color.WHITE) -> void:
	match state:
		"current", "available", "reward", "chosen", "hover", "selected":
			draw_coin_marker(target, center, radius, tint)
		"cleared", "complete", "sold", "locked", "disabled", "unaffordable", "resolved", "skipped", "failed", "sealed", "boss":
			var wax_tint := tint
			if state == "cleared" or state == "complete" or state == "sold":
				wax_tint = Color(GREEN, tint.a)
			elif state == "disabled" or state == "skipped" or state == "locked" or state == "unaffordable" or state == "resolved":
				wax_tint = Color(LINE, tint.a * 0.72)
			elif state == "boss" or state == "failed":
				wax_tint = Color(RED, tint.a)
			draw_wax_stamp(target, center, radius, wax_tint)
		"anchor", "pin", "future":
			draw_pin(target, center, radius * 1.45, tint)
		_:
			draw_coin_marker(target, center, radius, Color(tint, tint.a * 0.72))

static func draw_ledger_slip(target: CanvasItem, rect: Rect2, tint: Color = Color.WHITE) -> void:
	if _draw_physical_texture(target, "ledger_slip", rect, tint):
		return
	target.draw_rect(rect, Color("#c2ad82", 0.92) * tint, true)
	target.draw_rect(rect, Color("#1c130c", 0.76), false, 2.0)
	target.draw_line(rect.position + Vector2(12.0, rect.size.y * 0.55), rect.end - Vector2(12.0, rect.size.y * 0.45), Color("#5a4128", 0.42), 1.0)

static func draw_prompt_strip(target: CanvasItem, rect: Rect2, tint: Color = Color.WHITE) -> void:
	if _draw_physical_texture(target, "prompt_strip", rect, tint):
		return
	target.draw_rect(rect, Color("#22160d", 0.88) * tint, true)
	target.draw_rect(rect, Color(GOLD, 0.46), false, 2.0)

static func draw_plaque(target: CanvasItem, rect: Rect2, primary: bool = true, disabled: bool = false, tint: Color = Color.WHITE) -> void:
	var final_tint := tint
	if disabled:
		final_tint = Color(tint, 0.42)
	var texture_id := "plaque_primary" if primary else "plaque_secondary"
	if _draw_physical_texture(target, texture_id, rect, final_tint):
		return
	var fill := Color("#3b2a16", 0.96) if primary else Color("#2a2015", 0.94)
	var line := GOLD if primary else Color("#a88956")
	if disabled:
		fill = Color("#11161e", 0.78)
		line = Color(LINE, 0.42)
	target.draw_rect(rect, fill * final_tint, true)
	target.draw_rect(rect, Color("#070a10", 0.74), false, 4.0)
	target.draw_rect(rect.grow(-3.0), Color(line, 0.82), false, 2.0)

static func draw_coin_marker(target: CanvasItem, center: Vector2, radius: float = 18.0, tint: Color = Color.WHITE) -> void:
	var rect := Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	if _draw_physical_texture(target, "marker_coin", rect, tint):
		return
	target.draw_circle(center, radius, Color("#b9862d", 0.94) * tint)
	target.draw_arc(center, radius - 3.0, 0.0, TAU, 32, Color("#ffe08a", 0.72), 2.0)

static func draw_wax_stamp(target: CanvasItem, center: Vector2, radius: float = 18.0, tint: Color = Color.WHITE) -> void:
	var rect := Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	if _draw_physical_texture(target, "marker_wax", rect, tint):
		return
	target.draw_circle(center, radius, Color("#8c2430", 0.96) * tint)
	target.draw_circle(center + Vector2(-radius * 0.18, -radius * 0.18), radius * 0.42, Color("#b94646", 0.58) * tint)

static func draw_pin(target: CanvasItem, center: Vector2, size_or_tint: Variant = 28.0, tint: Color = Color.WHITE) -> void:
	var size := 28.0
	var final_tint := tint
	if typeof(size_or_tint) == TYPE_COLOR:
		final_tint = size_or_tint
	else:
		size = float(size_or_tint)
	var rect := Rect2(center - Vector2(size * 0.5, size * 0.68), Vector2(size, size * 1.38))
	if _draw_physical_texture(target, "route_pin", rect, final_tint):
		return
	target.draw_circle(center - Vector2(0.0, size * 0.16), size * 0.34, Color("#6b1f25", 0.96) * final_tint)
	target.draw_line(center + Vector2(0.0, size * 0.12), center + Vector2(0.0, size * 0.66), Color("#d9b36d", 0.88) * final_tint, 2.0)

static func draw_route_cord(target: CanvasItem, start_pos: Vector2, end_pos: Vector2, tint: Color = Color.WHITE, width: float = 10.0) -> void:
	var delta := end_pos - start_pos
	var length := delta.length()
	if length <= 1.0:
		return
	var angle := delta.angle()
	var rect := Rect2(Vector2.ZERO, Vector2(length, width))
	var transform := Transform2D(angle, start_pos - Vector2(0.0, width * 0.5).rotated(angle))
	target.draw_set_transform_matrix(transform)
	target.draw_line(Vector2(0.0, width * 0.5), Vector2(length, width * 0.5), Color("#8a6541", 0.64) * tint, width)
	target.draw_line(Vector2(0.0, width * 0.5), Vector2(length, width * 0.5), Color("#25170e", 0.42) * tint, max(1.0, width * 0.24))
	var texture := AssetCatalog.physical_ui_texture("route_cord")
	if texture != null:
		target.draw_texture_rect(texture, rect, true, Color(tint, min(tint.a, 0.82)))
	else:
		target.draw_line(Vector2(0.0, width * 0.5), Vector2(length, width * 0.5), Color("#d1a36a", 0.3) * tint, max(1.0, width * 0.16))
	target.draw_set_transform_matrix(Transform2D.IDENTITY)

static func draw_divider(target: CanvasItem, center: Vector2, width: float, color: Color = GOLD) -> void:
	var texture: Texture2D = AssetCatalog.ui_texture("divider")
	if texture == null:
		target.draw_line(center - Vector2(width * 0.5, 0), center + Vector2(width * 0.5, 0), Color(color, 0.72), 2.0)
		return
	var rect := Rect2(center - Vector2(width * 0.5, 10.0), Vector2(width, 20.0))
	target.draw_texture_rect(texture, rect, false, Color(color, 0.74))

static func draw_small_divider(target: CanvasItem, center: Vector2, width: float, color: Color = MUTED) -> void:
	var texture: Texture2D = AssetCatalog.ui_texture("divider_thin")
	if texture == null:
		target.draw_line(center - Vector2(width * 0.5, 0), center + Vector2(width * 0.5, 0), Color(color, 0.44), 1.0)
		return
	var rect := Rect2(center - Vector2(width * 0.5, 8.0), Vector2(width, 16.0))
	target.draw_texture_rect(texture, rect, false, Color(color, 0.46))

static func _draw_corner_marks(target: CanvasItem, rect: Rect2, accent: Color) -> void:
	var texture: Texture2D = AssetCatalog.ui_texture("panel_frame_round")
	if texture == null:
		return
	var size := Vector2(34, 34)
	var points := [
		rect.position + Vector2(8, 8),
		Vector2(rect.end.x - size.x - 8.0, rect.position.y + 8.0),
		Vector2(rect.position.x + 8.0, rect.end.y - size.y - 8.0),
		rect.end - size - Vector2(8, 8)
	]
	for point in points:
		target.draw_texture_rect(texture, Rect2(point, size), false, Color(accent, 0.58))

static func _draw_physical_texture(target: CanvasItem, texture_id: String, rect: Rect2, tint: Color = Color.WHITE) -> bool:
	var texture: Texture2D = AssetCatalog.physical_ui_texture(texture_id)
	if texture == null:
		return false
	target.draw_texture_rect(texture, rect, false, tint)
	return true
