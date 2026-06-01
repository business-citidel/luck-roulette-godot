extends Control

signal completed(result: Dictionary)

const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const RunTableState := preload("res://scripts/run/run_table_state.gd")
const RunTableWidgets := preload("res://scripts/ui/run_table_widgets.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiLayoutSpec := preload("res://scripts/ui/ui_layout_spec.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const BG := Color("#07090f")
const PANEL := Color("#101720")
const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const GREEN := Color("#65d48e")
const RED := Color("#ee5b5b")
const INK := Color("#090704")
const CARD := Color("#19130d")
const CARD_DARK := Color("#0d0b08")
const ROPE := Color("#9c7a45")

var run_state: Dictionary = {}
var nodes: Array[Dictionary] = []
var buttons: Array[Button] = []
var manual_scroll_offset_y := 0.0
var has_manual_scroll_offset := false

func configure(payload: Dictionary) -> void:
	run_state = payload.duplicate(true)
	has_manual_scroll_offset = run_state.has("map_scroll_y")
	if has_manual_scroll_offset:
		manual_scroll_offset_y = _clamp_scroll_offset(float(run_state.get("map_scroll_y", 0.0)))
	_build_nodes()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if nodes.is_empty():
		_build_nodes()
	_build_buttons()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	_draw_table_route_backdrop()
	_draw_route_header()
	_draw_route_connections()
	for node in nodes:
		if _is_token_map():
			_draw_map_token_node(node)
		else:
			_draw_map_card(node)
	_draw_map_legend_panel()

func _gui_input(event: InputEvent) -> void:
	if not _is_scroll_map():
		return
	var mouse_button := event as InputEventMouseButton
	if mouse_button == null or not mouse_button.pressed:
		return
	if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
		_adjust_scroll(90.0)
	elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_adjust_scroll(-90.0)

func _build_nodes() -> void:
	nodes = EncounterCatalog.map_nodes(_map_variant(), _seed_text())

func _build_buttons() -> void:
	for button in buttons:
		button.queue_free()
	buttons.clear()
	for node in nodes:
		var button := Button.new()
		button.text = ""
		var rect := _node_rect(node)
		button.position = rect.position
		button.size = rect.size
		button.disabled = int(node["node_index"]) != int(run_state.get("map_step", 0))
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_map_hit_area(button)
		var node_id: String = str(node["node_id"])
		button.pressed.connect(func() -> void: _select_node_by_id(node_id))
		add_child(button)
		buttons.append(button)

func _reposition_buttons() -> void:
	for i in range(min(buttons.size(), nodes.size())):
		var button := buttons[i] as Button
		if button == null:
			continue
		var node: Dictionary = nodes[i]
		var rect := _node_rect(node)
		button.position = rect.position
		button.size = rect.size
		button.disabled = int(node["node_index"]) != int(run_state.get("map_step", 0))

func _select_node(index: int) -> void:
	for node in nodes:
		if int(node["node_index"]) == index:
			_emit_node(node)
			return

func _select_node_by_id(node_id: String) -> void:
	for node in nodes:
		if str(node["node_id"]) == node_id:
			_emit_node(node)
			return

func _emit_node(node: Dictionary) -> void:
	var result := {
		"accepted": true,
		"encounter_id": str(node.get("encounter_id", "")),
		"node_id": str(node["node_id"]),
		"node_type": str(node["node_type"]),
		"node_index": int(node["node_index"]),
		"monster_id": str(node.get("monster_id", "")),
		"reward_tier": str(node.get("reward_tier", "")),
		"is_final": bool(node.get("is_final", false)),
		"on_victory": str(node.get("on_victory", "reward"))
	}
	if node.has("event_pool"):
		result["event_pool"] = str(node.get("event_pool", ""))
	if node.has("event_id"):
		result["event_id"] = str(node.get("event_id", ""))
	if node.has("node_subtype"):
		result["node_subtype"] = str(node.get("node_subtype", ""))
	if node.has("node_token_id"):
		result["node_token_id"] = str(node.get("node_token_id", ""))
	completed.emit(result)

func _select_current_node() -> void:
	_select_node(int(run_state.get("map_step", 0)))

func _select_current_node_of_type(node_type: String) -> void:
	var current_index: int = int(run_state.get("map_step", 0))
	for node in nodes:
		if int(node["node_index"]) == current_index and str(node["node_type"]) == node_type:
			_emit_node(node)
			return
	_select_current_node()

func _available_node_types() -> Array[String]:
	var current_index: int = int(run_state.get("map_step", 0))
	var result: Array[String] = []
	for node in nodes:
		if int(node["node_index"]) == current_index:
			result.append(str(node["node_type"]))
	return result

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _draw_node_icon(node_type: String, center: Vector2, tint: Color = Color.WHITE) -> void:
	var texture: Texture2D = AssetCatalog.node_icon(node_type)
	if texture == null:
		return
	var rect := Rect2(center - Vector2(19, 19), Vector2(38, 38))
	draw_texture_rect(texture, rect, false, tint)

func _draw_table_route_backdrop() -> void:
	var background := AssetCatalog.map_node_kit_texture(_map_background_id())
	if background != null:
		draw_texture_rect(background, Rect2(Vector2.ZERO, size), false, Color.WHITE)
		draw_rect(Rect2(Vector2.ZERO, size), Color("#020100", 0.16), true)
		return
	UiSkin.draw_table_stage(self, UiLayoutSpec.TABLE_STAGE, UiLayoutSpec.INNER_TABLE, Color(1, 1, 1, 0.98))
	draw_rect(UiLayoutSpec.INNER_TABLE.grow(-8.0), Color("#111512", 0.42), true)
	for i in range(8):
		var y := 106.0 + float(i) * 66.0
		draw_line(Vector2(82, y), Vector2(1190, y + 28.0), Color("#5d371f", 0.18), 18.0)
	draw_circle(Vector2(638, 356), 312.0, Color("#a56a34", 0.09))
	draw_circle(Vector2(638, 356), 236.0, Color("#0c0906", 0.18), false, 16.0)
	_draw_corner_pin(Vector2(94, 98))
	_draw_corner_pin(Vector2(1162, 98))
	_draw_corner_pin(Vector2(94, 588))
	_draw_corner_pin(Vector2(1162, 588))

func _draw_route_header() -> void:
	if _is_scroll_map():
		_draw_text(UiText.t("map.title"), Vector2(94, 106), 30, TEXT)
		_draw_text(_floor_subtitle(), Vector2(98, 136), 14, Color(MUTED, 0.82))
		return
	_draw_text(UiText.t("map.title"), Vector2(108, 126), 38, TEXT)
	_draw_text(UiText.t("map.subtitle"), Vector2(112, 160), 16, MUTED)

func _draw_route_connections() -> void:
	for from_node in nodes:
		for to_node in nodes:
			if not _nodes_are_connected(from_node, to_node):
				continue
			_draw_connection(from_node, to_node)

func _draw_map_legend_panel() -> void:
	if not _is_scroll_map():
		return
	var texture := AssetCatalog.map_node_kit_texture("legend_panel_003")
	if texture == null:
		return
	var panel_height: float = min(326.0, size.y - 142.0)
	var panel_width: float = panel_height * 0.6666667
	var rect := Rect2(Vector2(size.x - panel_width - 66.0, 74.0), Vector2(panel_width, panel_height))
	draw_rect(Rect2(rect.position + Vector2(10.0, 14.0), rect.size), Color("#020100", 0.42), true)
	draw_texture_rect(texture, rect, false, Color(1, 1, 1, 0.92))

func _nodes_are_connected(from_node: Dictionary, to_node: Dictionary) -> bool:
	var links: Array = from_node.get("next_node_ids", [])
	if not links.is_empty():
		return links.has(str(to_node.get("node_id", "")))
	return int(to_node["node_index"]) == int(from_node["node_index"]) + 1

func _draw_connection(from_node: Dictionary, to_node: Dictionary) -> void:
	var a: Vector2 = _node_center(from_node)
	var b: Vector2 = _node_center(to_node)
	var from_done: bool = _is_completed(from_node)
	var to_available: bool = int(to_node["node_index"]) == int(run_state.get("map_step", 0))
	var active: bool = from_done or to_available or int(from_node["node_index"]) == int(run_state.get("map_step", 0))
	var color := Color(ROPE, 0.86 if active else 0.24)
	var active_width := 6.0 if _uses_compact_map_layout() else 10.0
	var future_width := 4.0 if _uses_compact_map_layout() else 7.0
	_draw_map_route_cord(a, b, color, active_width if active else future_width)
	if not _is_token_map():
		_draw_map_route_pin(a, Color(color, 0.92 if active else 0.42))
		_draw_map_route_pin(b, Color(color, 0.92 if active else 0.42))

func _draw_map_card(node: Dictionary) -> void:
	var rect := _node_rect(node)
	var accent := _node_accent(node)
	var state := _node_state(node)
	var completed := _is_completed(node)
	var available: bool = int(node["node_index"]) == int(run_state.get("map_step", 0))
	var card_tint := Color(1, 1, 1, 1.0 if available or completed else 0.58)
	draw_rect(Rect2(rect.position + Vector2(8, 12), rect.size), Color("#020202", 0.52), true)
	if _draw_premium_map_card(node, rect, state, card_tint, accent):
		_draw_premium_map_card_label(node, rect, accent)
		return
	else:
		UiSkin.draw_offer_card(self, rect, state, card_tint)
		_draw_node_icon(str(node["node_type"]), rect.position + Vector2(38, 36), Color(accent, 0.9 if available or completed else 0.52))
	draw_rect(rect.grow(-7.0), Color(accent, 0.86 if available else 0.42), false, 2.0 if available else 1.0)
	_draw_text(_node_title(node), rect.position + Vector2(18, 34), 17, INK if available or completed else Color(INK, 0.48))
	_draw_text(UiText.t("map.step", {"step": node["node_index"]}), rect.position + Vector2(20, 54), 11, Color(INK, 0.58 if available or completed else 0.36))
	if completed:
		_draw_stamp(UiText.t("map.state.cleared"), rect.position + Vector2(20, 102), GREEN)
	elif available:
		_draw_stamp(UiText.t("map.state.current"), rect.position + Vector2(18, 102), GOLD)
	elif bool(node.get("is_final", false)):
		_draw_stamp(UiText.t("map.state.house"), rect.position + Vector2(30, 102), RED)
	else:
		_draw_stamp(UiText.t("map.state.future"), rect.position + Vector2(24, 102), Color("#667083"))
	_draw_node_action_plaque(node, rect)

func _draw_map_token_node(node: Dictionary) -> void:
	var rect := _node_rect(node)
	var center := _node_center(node)
	var node_type := str(node["node_type"])
	var token_id := _node_token_id(node)
	var available: bool = int(node["node_index"]) == int(run_state.get("map_step", 0))
	var completed := _is_completed(node)
	var covered := _is_covered(node)
	var boss := bool(node.get("is_final", false))
	var token_size := 92.0 if boss else (82.0 if node_type == "elite" else 74.0)
	var radius := token_size * 0.43
	draw_circle(center + Vector2(7.0, 10.0), token_size * 0.44, Color("#020202", 0.44))
	if covered:
		draw_circle(center, radius, Color("#100c09", 0.72))
		draw_circle(center, radius, Color("#6a5748", 0.26), false, 3.0)
		draw_string(ThemeDB.fallback_font, center + Vector2(-7.0, 11.0), "?", HORIZONTAL_ALIGNMENT_CENTER, 14.0, 22, Color(TEXT, 0.34))
		return
	if available:
		draw_circle(center, radius + 10.0, Color(GOLD, 0.18))
		draw_circle(center, radius + 4.0, Color(GOLD, 0.28), false, 4.0)
	var texture := AssetCatalog.map_node_token_texture(token_id)
	if texture != null:
		var alpha := 1.0 if available or completed else 0.62
		draw_texture_rect(texture, Rect2(center - Vector2.ONE * token_size * 0.5, Vector2.ONE * token_size), false, Color(1, 1, 1, alpha))
	else:
		draw_circle(center, radius, Color("#120b06", 0.94))
		_draw_token_icon(node_type, center, 42.0 if node_type == "elite" else 36.0, Color(TEXT, 0.9 if available or completed else 0.72))
	if completed:
		draw_circle(center, radius + 1.5, GREEN, false, 2.0)
	elif available:
		draw_circle(center, radius + 2.0, GOLD, false, 2.4)
	if completed:
		_draw_map_wax("wax_completed", center + Vector2(radius * 0.7, radius * 0.62), 23.0, Color(1, 1, 1, 0.85))
	elif available:
		_draw_map_wax("wax_current", center + Vector2(radius * 0.7, radius * 0.62), 25.0, Color(1, 1, 1, 0.92))
	if available:
		_draw_token_label(node, center, radius)

func _draw_token_boss_node(node: Dictionary, rect: Rect2, available: bool, completed: bool, accent: Color) -> void:
	var tint := Color(1, 1, 1, 1.0 if available or completed else 0.64)
	var boss_endpoint := AssetCatalog.map_node_kit_texture("boss_endpoint_02")
	if boss_endpoint != null:
		draw_texture_rect(boss_endpoint, rect, false, tint)
	else:
		draw_circle(rect.get_center(), rect.size.x * 0.38, Color("#25100b", 0.94))
		draw_circle(rect.get_center(), rect.size.x * 0.38, Color(RED, 0.72), false, 4.0)
		_draw_token_icon("boss", rect.get_center(), 54.0, Color(TEXT, 0.88))
	if available:
		draw_rect(rect.grow(4.0), Color(GOLD, 0.8), false, 2.0)
		var plaque_rect := _node_button_rect(rect)
		UiSkin.draw_plaque(self, plaque_rect, true, false, Color(1, 1, 1, 0.92))
		draw_string(ThemeDB.fallback_font, plaque_rect.position + Vector2(8.0, 18.0), "SELECT", HORIZONTAL_ALIGNMENT_CENTER, plaque_rect.size.x - 16.0, 11, TEXT)
	elif completed:
		_draw_map_wax("wax_completed", rect.position + Vector2(rect.size.x - 16.0, 24.0), 25.0, Color(1, 1, 1, 0.86))
	else:
		_draw_map_wax("wax_boss", rect.position + Vector2(rect.size.x - 16.0, 24.0), 25.0, Color(1, 1, 1, 0.76))

func _draw_token_icon(node_type: String, center: Vector2, icon_size: float, tint: Color) -> void:
	var texture := AssetCatalog.map_node_kit_texture("emblem_" + node_type)
	if texture == null:
		texture = AssetCatalog.node_icon(node_type)
	if texture == null:
		return
	var rect := Rect2(center - Vector2.ONE * icon_size * 0.5, Vector2.ONE * icon_size)
	draw_texture_rect(texture, rect, false, tint)

func _draw_token_label(node: Dictionary, center: Vector2, radius: float) -> void:
	var title := _node_title(node)
	var label_rect := Rect2(center + Vector2(-48.0, radius + 8.0), Vector2(96.0, 26.0))
	if _is_scroll_map():
		var x_offset := 44.0
		if center.x > size.x * 0.64:
			x_offset = -140.0
		label_rect = Rect2(center + Vector2(x_offset, -13.0), Vector2(96.0, 26.0))
	draw_rect(label_rect, Color("#120b06", 0.62), true)
	draw_rect(label_rect, Color(GOLD, 0.55), false, 1.0)
	draw_string(ThemeDB.fallback_font, label_rect.position + Vector2(6.0, 18.0), title, HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x - 12.0, 11, Color(TEXT, 0.94))

func _draw_premium_map_card(node: Dictionary, rect: Rect2, state: String, tint: Color, accent: Color) -> bool:
	if bool(node.get("is_final", false)):
		var boss_endpoint := AssetCatalog.map_node_kit_texture("boss_endpoint_02")
		if boss_endpoint != null:
			draw_texture_rect(boss_endpoint, rect, false, tint)
			return true
	var use_back := _is_covered(node)
	var base_texture := AssetCatalog.map_node_kit_texture("card_back_covered" if use_back else "card_front_base")
	if base_texture == null:
		return false
	draw_texture_rect(base_texture, rect, false, tint)
	if not use_back:
		var node_type := str(node["node_type"])
		var emblem_id := "emblem_" + node_type
		var emblem_texture := AssetCatalog.map_node_kit_texture(emblem_id)
		var emblem_size := Vector2(56, 56) if _is_dense_map() else Vector2(72, 72)
		var emblem_y := 34.0 if _is_dense_map() else 42.0
		if emblem_texture == null:
			var icon_y := 62.0 if _is_dense_map() else 74.0
			_draw_node_icon(node_type, rect.position + Vector2(rect.size.x * 0.5, icon_y), Color(accent, 0.9 if tint.a >= 0.9 else 0.52))
		else:
			var emblem_rect := Rect2(rect.position + Vector2((rect.size.x - emblem_size.x) * 0.5, emblem_y), emblem_size)
			draw_texture_rect(emblem_texture, emblem_rect, false, Color(1, 1, 1, 0.96 if tint.a >= 0.9 else 0.66))
	_draw_map_card_overlay(state, rect, tint)
	return true

func _draw_premium_map_card_label(node: Dictionary, rect: Rect2, accent: Color) -> void:
	var available: bool = int(node["node_index"]) == int(run_state.get("map_step", 0))
	var completed := _is_completed(node)
	var state := _node_state(node)
	if _is_covered(node):
		_draw_text("?", rect.position + Vector2(rect.size.x * 0.5 - 5.0, rect.size.y * 0.55), 18 if _is_dense_map() else 20, Color(TEXT, 0.28))
		return
	var title_margin := 10.0 if _is_dense_map() else 14.0
	var title_rect := Rect2(rect.position + Vector2(title_margin, title_margin), Vector2(rect.size.x - title_margin * 2.0, 18.0 if _is_dense_map() else 20.0))
	draw_rect(title_rect, Color("#1a0d08", 0.42), true)
	draw_string(ThemeDB.fallback_font, title_rect.position + Vector2(3.0, 14.0 if _is_dense_map() else 15.0), _node_title(node), HORIZONTAL_ALIGNMENT_CENTER, title_rect.size.x - 6.0, 10 if _is_dense_map() else 12, Color(TEXT, 0.95 if available or completed else 0.58))
	_draw_text(UiText.t("map.step", {"step": node["node_index"]}), rect.position + Vector2(14.0 if _is_dense_map() else 18.0, 37.0 if _is_dense_map() else 45.0), 8 if _is_dense_map() else 9, Color(TEXT, 0.52 if available or completed else 0.32))
	var token_center := rect.position + Vector2(rect.size.x - (15.0 if _is_dense_map() else 20.0), 32.0 if _is_dense_map() else 40.0)
	var token_size := 19.0 if _is_dense_map() else 24.0
	if completed:
		_draw_map_wax("wax_completed", token_center, token_size, Color(1, 1, 1, 0.92))
	elif available:
		_draw_map_wax("wax_current", token_center, token_size, Color(1, 1, 1, 0.96))
	elif state == "boss":
		_draw_map_wax("wax_boss", token_center, token_size, Color(1, 1, 1, 0.92))
	else:
		_draw_map_route_pin(token_center, Color("#667083", 0.46), 14.0 if _is_dense_map() else 18.0)
	if available:
		var plaque_rect := _node_button_rect(rect)
		UiSkin.draw_plaque(self, plaque_rect, true, false, Color(1, 1, 1, 0.92))
		draw_string(ThemeDB.fallback_font, plaque_rect.position + Vector2(8.0, 17.0 if _is_dense_map() else 20.0), "SELECT", HORIZONTAL_ALIGNMENT_CENTER, plaque_rect.size.x - 16.0, 10 if _is_dense_map() else 12, TEXT)

func _draw_map_card_overlay(state: String, rect: Rect2, tint: Color) -> void:
	var overlay_id := ""
	match state:
		"current":
			overlay_id = "overlay_current"
		"cleared":
			overlay_id = "overlay_completed"
		"boss":
			overlay_id = "overlay_boss"
		"future":
			overlay_id = "overlay_future"
	if overlay_id == "":
		return
	var overlay := AssetCatalog.map_node_kit_texture(overlay_id)
	if overlay == null:
		return
	draw_texture_rect(overlay, rect, false, Color(1, 1, 1, min(1.0, tint.a + 0.08)))

func _draw_map_route_cord(start_pos: Vector2, end_pos: Vector2, tint: Color, width: float) -> void:
	var texture := AssetCatalog.map_node_kit_texture("route_cord")
	if texture == null:
		UiSkin.draw_route_cord(self, start_pos, end_pos, tint, width)
		return
	var delta := end_pos - start_pos
	var length := delta.length()
	if length <= 1.0:
		return
	var angle := delta.angle()
	var rect := Rect2(Vector2.ZERO, Vector2(length, width))
	var transform := Transform2D(angle, start_pos - Vector2(0.0, width * 0.5).rotated(angle))
	draw_set_transform_matrix(transform)
	draw_line(Vector2(0.0, width * 0.5), Vector2(length, width * 0.5), Color("#c49354", 0.34) * tint, width * 0.82)
	draw_line(Vector2(0.0, width * 0.5), Vector2(length, width * 0.5), Color("#2b170b", 0.54) * tint, max(1.0, width * 0.24))
	draw_texture_rect(texture, rect, true, Color(tint, min(tint.a, 0.82)))
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _draw_map_route_pin(center: Vector2, tint: Color, height: float = 26.0) -> void:
	var texture := AssetCatalog.map_node_kit_texture("route_pin")
	if texture == null:
		UiSkin.draw_pin(self, center, height, tint)
		return
	var size := Vector2(height * 0.43, height)
	draw_texture_rect(texture, Rect2(center - Vector2(size.x * 0.5, size.y * 0.66), size), false, tint)

func _draw_map_wax(texture_id: String, center: Vector2, size: float, tint: Color) -> void:
	var texture := AssetCatalog.map_node_kit_texture(texture_id)
	if texture == null:
		UiSkin.draw_wax_stamp(self, center, size * 0.5, tint)
		return
	draw_texture_rect(texture, Rect2(center - Vector2.ONE * size * 0.5, Vector2.ONE * size), false, tint)

func _draw_node_action_plaque(node: Dictionary, rect: Rect2) -> void:
	var available: bool = int(node["node_index"]) == int(run_state.get("map_step", 0))
	var plaque_rect := _node_button_rect(rect)
	UiSkin.draw_plaque(self, plaque_rect, bool(node.get("is_final", false)) or available, not available, Color(1, 1, 1, 0.92 if available else 0.42))
	var color := TEXT if available else Color(TEXT, 0.42)
	draw_string(ThemeDB.fallback_font, plaque_rect.position + Vector2(10.0, 21.0), _node_button_text(node), HORIZONTAL_ALIGNMENT_CENTER, plaque_rect.size.x - 20.0, 12, color)

func _draw_stamp(text: String, pos: Vector2, color: Color) -> void:
	var rect := Rect2(pos - Vector2(8, 14), Vector2(78, 21))
	draw_rect(rect, Color("#1a0d08", 0.52), true)
	draw_rect(rect, Color(color, 0.72), false, 1.0)
	_draw_text(text, pos, 10, Color(color, 0.92))

func _draw_corner_pin(pos: Vector2) -> void:
	draw_circle(pos, 14.0, Color("#080604"))
	draw_circle(pos, 11.0, Color("#5d3a1e"))
	draw_circle(pos, 5.0, Color(GOLD, 0.7))

func _node_rect(node: Dictionary) -> Rect2:
	if bool(node.get("is_final", false)):
		if _is_token_map():
			return Rect2(_node_center(node) - Vector2(55, 55), Vector2(110, 110))
		var boss_size := Vector2(126, 180) if _is_scroll_map() else (Vector2(122, 174) if _is_token_map() else (Vector2(112, 168) if _is_dense_map() else Vector2(148, 222)))
		return Rect2(_node_center(node) - boss_size * 0.5, boss_size)
	if _is_token_map():
		return Rect2(_node_center(node) - Vector2(46, 46), Vector2(92, 92))
	var card_size := Vector2(94, 122) if _is_dense_map() else UiLayoutSpec.MAP_CARD_SIZE
	return Rect2(_node_center(node) - card_size * 0.5, card_size)

func _node_button_rect(rect: Rect2) -> Rect2:
	if _is_token_map():
		return Rect2(rect.position + Vector2(10.0, rect.size.y - 32.0), Vector2(rect.size.x - 20.0, 25.0))
	if _is_dense_map():
		return Rect2(rect.position + Vector2(10.0, rect.size.y - 29.0), Vector2(rect.size.x - 20.0, 24.0))
	return Rect2(rect.position + Vector2(12.0, 114.0), Vector2(rect.size.x - 24.0, 30.0))

func _apply_map_hit_area(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _transparent_button_style())
	button.add_theme_stylebox_override("hover", _transparent_button_style())
	button.add_theme_stylebox_override("pressed", _transparent_button_style())
	button.add_theme_stylebox_override("disabled", _transparent_button_style())
	button.add_theme_stylebox_override("focus", _transparent_button_style())

func _transparent_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	return style

func _node_center(node: Dictionary) -> Vector2:
	var node_id := str(node.get("node_id", ""))
	if node_id == "n5" and not _uses_compact_map_layout():
		return Vector2(1110, 354)
	var pos := node["pos"] as Vector2
	if _is_scroll_map():
		pos.y += _scroll_offset_y()
	return pos

func _node_world_center(node: Dictionary) -> Vector2:
	return node["pos"] as Vector2

func _map_variant() -> String:
	return str(run_state.get("map_variant", ""))

func _seed_text() -> String:
	var seed := str(run_state.get("seed_text", ""))
	if _map_variant() == "scroll_20_random":
		seed += ":floor:" + str(int(run_state.get("floor_index", 1)))
	return seed

func _map_background_id() -> String:
	var theme_id := str(run_state.get("map_theme_id", ""))
	if theme_id != "":
		var theme_texture_id := "map_theme_" + theme_id
		if AssetCatalog.map_node_kit_texture(theme_texture_id) != null:
			return theme_texture_id
	var floor := int(run_state.get("floor_index", 1))
	if floor <= 1:
		return "room_background_floor_1"
	if floor == 2:
		return "room_background_floor_2"
	return "room_background_floor_3"

func _floor_subtitle() -> String:
	var floor := int(run_state.get("floor_index", 1))
	var max_floor := int(run_state.get("max_floor", 3))
	return "floor " + str(floor) + "/" + str(max_floor) + " - wheel to inspect"

func _is_dense_map() -> bool:
	return _map_variant() == "dense_10"

func _is_token_map() -> bool:
	return _map_variant() == "token_10" or _is_scroll_map()

func _is_scroll_map() -> bool:
	return _map_variant() == "scroll_20" or _map_variant() == "scroll_20_random"

func _uses_compact_map_layout() -> bool:
	return _is_dense_map() or _is_token_map()

func _adjust_scroll(delta: float) -> void:
	has_manual_scroll_offset = true
	manual_scroll_offset_y = _clamp_scroll_offset(_scroll_offset_y() + delta)
	_reposition_buttons()
	queue_redraw()

func _scroll_offset_y() -> float:
	if not _is_scroll_map():
		return 0.0
	if has_manual_scroll_offset:
		return _clamp_scroll_offset(manual_scroll_offset_y)
	return _auto_scroll_offset_y()

func _auto_scroll_offset_y() -> float:
	var current_index := int(run_state.get("map_step", 0))
	var total_y := 0.0
	var count := 0
	for node in nodes:
		if int(node.get("node_index", -1)) == current_index:
			total_y += _node_world_center(node).y
			count += 1
	if count <= 0:
		return 0.0
	var average_y := total_y / float(count)
	var target_y := 390.0
	if current_index <= 1:
		target_y = 450.0
	elif current_index >= EncounterCatalog.final_step(_map_variant(), _seed_text()):
		target_y = 350.0
	return _clamp_scroll_offset(target_y - average_y)

func _clamp_scroll_offset(offset_y: float) -> float:
	if not _is_scroll_map():
		return 0.0
	return clamp(offset_y, -1220.0, 180.0)

func _node_accent(node: Dictionary) -> Color:
	if bool(node.get("is_final", false)):
		return RED
	if _is_completed(node):
		return GREEN
	if int(node["node_index"]) == int(run_state.get("map_step", 0)):
		return GOLD
	return Color("#667083")

func _node_state(node: Dictionary) -> String:
	if _is_completed(node):
		return "cleared"
	if int(node["node_index"]) == int(run_state.get("map_step", 0)):
		return "current"
	if bool(node.get("is_final", false)):
		return "boss"
	return "future"

func _is_completed(node: Dictionary) -> bool:
	return (run_state.get("completed_nodes", []) as Array).has(str(node["node_id"]))

func _is_covered(node: Dictionary) -> bool:
	return int(node["node_index"]) > int(run_state.get("map_step", 0)) + 1 and not bool(node.get("is_final", false))

func _node_title(node: Dictionary) -> String:
	var node_type := str(node["node_type"])
	var token_id := _node_token_id(node)
	if node_type == "combat":
		return UiText.t("map.node.combat")
	if node_type == "elite":
		return UiText.t("map.node.elite")
	if node_type == "event":
		match token_id:
			"event_chest":
				return UiText.t("map.node.event.chest")
			"event_quest":
				return UiText.t("map.node.event.quest")
			"event_gamble":
				return UiText.t("map.node.event.gamble")
			_:
				return UiText.t("map.node.event.mystery")
		return UiText.t("map.node.event")
	if node_type == "shop":
		return UiText.t("map.node.shop")
	if node_type == "rest":
		return UiText.t("map.node.rest")
	if node_type == "boss":
		return UiText.t("map.node.boss")
	return node_type.to_upper()

func _node_token_id(node: Dictionary) -> String:
	var token_id := str(node.get("node_token_id", ""))
	if token_id != "":
		return token_id
	var node_type := str(node.get("node_type", "event"))
	if node_type == "event":
		var subtype := str(node.get("node_subtype", "mystery")).replace("event_", "")
		if ["mystery", "chest", "quest", "gamble"].has(subtype):
			return "event_" + subtype
		return "event_mystery"
	return node_type

func _node_button_text(node: Dictionary) -> String:
	if int(node["node_index"]) != int(run_state.get("map_step", 0)):
		return _node_title(node)
	return UiText.t("map.choose", {"label": _node_title(node)})
