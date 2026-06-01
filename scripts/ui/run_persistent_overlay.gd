class_name RunPersistentOverlay
extends Control

signal proceed_requested

const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const MarbleCatalog := preload("res://scripts/systems/marble_catalog.gd")
const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const GREEN := Color("#65d48e")
const INK := Color("#090704")

const TOP_BAR_RECT := Rect2(Vector2(22, 14), Vector2(1236, 62))
const HP_RECT := Rect2(Vector2(44, 24), Vector2(126, 42))
const GOLD_RECT := Rect2(Vector2(184, 24), Vector2(122, 42))
const TICKET_RECT := Rect2(Vector2(320, 24), Vector2(142, 42))
const POTION_RECT := Rect2(Vector2(476, 24), Vector2(138, 42))
const MARBLE_DECK_RECT := Rect2(Vector2(628, 24), Vector2(148, 42))
const FLOOR_RECT := Rect2(Vector2(998, 24), Vector2(108, 42))
const SETTINGS_RECT := Rect2(Vector2(1120, 24), Vector2(116, 42))
const RELIC_ROW_RECT := Rect2(Vector2(44, 82), Vector2(760, 46))
const DETAIL_RECT := Rect2(Vector2(44, 132), Vector2(360, 72))
const COMBAT_DETAIL_RECT := Rect2(Vector2(44, 132), Vector2(330, 70))
const PROCEED_RECT := Rect2(Vector2(1104, 636), Vector2(126, 56))
const MARBLE_GALLERY_RECT := Rect2(Vector2(134, 86), Vector2(1012, 570))
const MARBLE_GALLERY_CLOSE_RECT := Rect2(Vector2(994, 590), Vector2(112, 44))
const MARBLE_GALLERY_COLUMNS := 4
const MARBLE_GALLERY_SLOT_SIZE := Vector2(88, 88)
const MARBLE_GALLERY_GAP := Vector2(30, 28)

var run_payload: Dictionary = {}
var phase := ""
var selected_relic_id := ""
var marble_gallery_open := false
var hovered_marble_gallery_index := -1
var proceed_button: Button
var marble_gallery_button: Button
var marble_gallery_close_button: Button
var relic_buttons: Array[Button] = []
var relic_pulse_timers: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_proceed_button()
	_build_marble_gallery_buttons()
	_refresh_relic_buttons()
	queue_redraw()

func _has_point(point: Vector2) -> bool:
	if marble_gallery_open:
		return true
	if proceed_button != null and proceed_button.visible and PROCEED_RECT.has_point(point):
		return true
	if marble_gallery_button != null and marble_gallery_button.visible and MARBLE_DECK_RECT.has_point(point):
		return true
	if _relic_at_position(point) != "":
		return true
	return selected_relic_id != "" and _detail_rect().has_point(point)

func _gui_input(event: InputEvent) -> void:
	if marble_gallery_open and event is InputEventMouseMotion:
		_update_hovered_marble((event as InputEventMouseMotion).position)
		accept_event()
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	if marble_gallery_open:
		if MARBLE_GALLERY_CLOSE_RECT.has_point(mouse_event.position):
			_set_marble_gallery_open(false)
			accept_event()
			return
		if not MARBLE_GALLERY_RECT.has_point(mouse_event.position):
			_set_marble_gallery_open(false)
		accept_event()
		return
	if proceed_button != null and proceed_button.visible and not proceed_button.disabled and PROCEED_RECT.has_point(mouse_event.position):
		proceed_requested.emit()
		accept_event()
		return
	var relic_id := _relic_at_position(mouse_event.position)
	if relic_id != "":
		_toggle_relic_detail(relic_id)
		accept_event()

func _process(delta: float) -> void:
	if relic_pulse_timers.is_empty():
		return
	var changed := false
	for relic_id in relic_pulse_timers.keys():
		var remaining: float = max(0.0, float(relic_pulse_timers.get(relic_id, 0.0)) - delta)
		if remaining <= 0.0:
			relic_pulse_timers.erase(relic_id)
		else:
			relic_pulse_timers[relic_id] = remaining
		changed = true
	if changed:
		queue_redraw()

func configure(payload: Dictionary, phase_name: String, proceed_visible: bool = false, proceed_enabled: bool = false, proceed_label: String = "") -> void:
	run_payload = payload.duplicate(true)
	phase = phase_name
	if proceed_button != null:
		proceed_button.visible = proceed_visible
		proceed_button.disabled = not proceed_enabled
		proceed_button.text = proceed_label if proceed_label != "" else UiText.t("overlay.exit")
	if marble_gallery_button != null:
		marble_gallery_button.visible = not run_payload.is_empty()
	if marble_gallery_close_button != null:
		marble_gallery_close_button.visible = marble_gallery_open
	_refresh_relic_buttons()
	queue_redraw()

func pulse_relics(relic_ids: Array) -> void:
	for relic_id_value in relic_ids:
		var relic_id := str(relic_id_value)
		if relic_id == "":
			continue
		relic_pulse_timers[relic_id] = 0.42
	if not relic_ids.is_empty():
		queue_redraw()

func _draw() -> void:
	if run_payload.is_empty():
		return
	_draw_top_bar()
	_draw_resource_chips()
	_draw_relic_row()
	_draw_selected_relic_detail()
	_draw_marble_gallery()

func _build_proceed_button() -> void:
	proceed_button = Button.new()
	proceed_button.name = "RunOverlayProceed"
	proceed_button.position = PROCEED_RECT.position
	proceed_button.size = PROCEED_RECT.size
	proceed_button.text = UiText.t("overlay.exit")
	proceed_button.visible = false
	proceed_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiSkin.apply_button(proceed_button, true)
	proceed_button.pressed.connect(func() -> void: proceed_requested.emit())
	add_child(proceed_button)

func _build_marble_gallery_buttons() -> void:
	marble_gallery_button = Button.new()
	marble_gallery_button.name = "RunOverlayMarbleDeckButton"
	marble_gallery_button.position = MARBLE_DECK_RECT.position
	marble_gallery_button.size = MARBLE_DECK_RECT.size
	marble_gallery_button.text = ""
	marble_gallery_button.visible = false
	marble_gallery_button.tooltip_text = UiText.t("overlay.marble_gallery.title")
	marble_gallery_button.focus_mode = Control.FOCUS_NONE
	marble_gallery_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_transparent_button(marble_gallery_button)
	marble_gallery_button.pressed.connect(func() -> void: _set_marble_gallery_open(true))
	add_child(marble_gallery_button)

	marble_gallery_close_button = Button.new()
	marble_gallery_close_button.name = "RunOverlayMarbleGalleryClose"
	marble_gallery_close_button.position = MARBLE_GALLERY_CLOSE_RECT.position
	marble_gallery_close_button.size = MARBLE_GALLERY_CLOSE_RECT.size
	marble_gallery_close_button.text = UiText.t("overlay.marble_gallery.close")
	marble_gallery_close_button.visible = false
	marble_gallery_close_button.focus_mode = Control.FOCUS_NONE
	UiSkin.apply_button(marble_gallery_close_button, false)
	marble_gallery_close_button.pressed.connect(func() -> void: _set_marble_gallery_open(false))
	add_child(marble_gallery_close_button)

func _refresh_relic_buttons() -> void:
	for button in relic_buttons:
		button.queue_free()
	relic_buttons.clear()
	for entry in _relic_icon_rects():
		if bool(entry.get("overflow", false)):
			continue
		var relic_id := str(entry.get("id", ""))
		if relic_id == "":
			continue
		var rect: Rect2 = entry.get("rect", Rect2())
		var button := Button.new()
		button.name = "RunOverlayRelic_" + relic_id
		button.position = rect.position
		button.size = rect.size
		button.text = ""
		button.tooltip_text = RelicCatalog.display_name(relic_id)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_transparent_button(button)
		button.pressed.connect(func() -> void: _toggle_relic_detail(relic_id))
		add_child(button)
		relic_buttons.append(button)

func _toggle_relic_detail(relic_id: String) -> void:
	selected_relic_id = "" if selected_relic_id == relic_id else relic_id
	queue_redraw()

func _set_marble_gallery_open(open: bool) -> void:
	marble_gallery_open = open
	hovered_marble_gallery_index = -1
	mouse_filter = Control.MOUSE_FILTER_STOP if marble_gallery_open else Control.MOUSE_FILTER_PASS
	if marble_gallery_close_button != null:
		marble_gallery_close_button.visible = marble_gallery_open
	queue_redraw()

func _update_hovered_marble(pos: Vector2) -> void:
	var next_index := _marble_gallery_index_at(pos)
	if next_index == hovered_marble_gallery_index:
		return
	hovered_marble_gallery_index = next_index
	queue_redraw()

func _apply_transparent_button(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("disabled", empty)
	button.add_theme_color_override("font_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_disabled_color", Color.TRANSPARENT)

func _draw_top_bar() -> void:
	var rect := Rect2(TOP_BAR_RECT.position, Vector2(_top_bar_width(), TOP_BAR_RECT.size.y))
	draw_rect(rect, Color("#08090c", 0.72), true)
	draw_rect(rect, Color("#5a3b22", 0.62), false, 2.0)
	draw_line(rect.position + Vector2(14, rect.size.y - 8.0), rect.end - Vector2(14, 8), Color("#d1a36a", 0.18), 1.0)

func _top_bar_width() -> float:
	return TOP_BAR_RECT.size.x

func _draw_resource_chips() -> void:
	_draw_chip(HP_RECT, UiText.t("overlay.hp"), str(run_payload.get("player_hp", 42)) + "/" + str(run_payload.get("player_max_hp", 42)), Color("#1e6b3b"))
	_draw_chip(GOLD_RECT, UiText.t("overlay.gold"), str(run_payload.get("gold", 0)), Color("#8a5f12"))
	_draw_chip(TICKET_RECT, UiText.t("overlay.tickets"), str(run_payload.get("contract_tickets", 0)), Color("#7a311f"))
	_draw_chip(POTION_RECT, UiText.t("overlay.potions"), _potion_slot_text(), Color("#6f1d2b"))
	_draw_marble_deck_chip()
	_draw_chip(FLOOR_RECT, UiText.t("overlay.floor"), _floor_text(), Color("#294861"))
	_draw_chip(SETTINGS_RECT, UiText.t("overlay.settings"), "ESC", Color("#3e4655"))

func _draw_chip(rect: Rect2, label: String, value: String, value_color: Color) -> void:
	UiSkin.draw_ledger_slip(self, rect, Color(1, 1, 1, 0.84))
	_draw_text(label, rect.position + Vector2(12, 26), 12, Color(INK, 0.54))
	_draw_text(value, rect.position + Vector2(max(42.0, min(72.0, label.length() * 8.0 + 18.0)), 29), 18, value_color)

func _draw_marble_deck_chip() -> void:
	UiSkin.draw_ledger_slip(self, MARBLE_DECK_RECT, Color(1, 1, 1, 0.84))
	var icon_rect := Rect2(MARBLE_DECK_RECT.position + Vector2(10, 8), Vector2(26, 26))
	var texture := AssetCatalog.marble_texture("marble_plain_v2")
	if texture != null:
		draw_texture_rect(texture, icon_rect, false, Color(1, 1, 1, 0.94))
	else:
		draw_circle(icon_rect.get_center(), 12.0, Color("#e8e0cf"))
	_draw_text(UiText.t("overlay.marbles"), MARBLE_DECK_RECT.position + Vector2(42, 24), 12, Color(INK, 0.54))
	_draw_text(str(_marble_deck_items().size()), MARBLE_DECK_RECT.position + Vector2(102, 29), 18, Color("#5f4630"))

func _potion_slot_text() -> String:
	var used := int(run_payload.get("potion_slots_used", (run_payload.get("potion_ids", []) as Array).size()))
	var max_slots := int(run_payload.get("potion_slots_max", 2))
	return str(used) + "/" + str(max_slots)

func _floor_text() -> String:
	return str(run_payload.get("floor_index", 1)) + "-" + str(int(run_payload.get("map_step", 0)) + 1)

func _draw_relic_row() -> void:
	var relic_ids: Array = run_payload.get("relic_ids", [])
	_draw_text(UiText.t("overlay.relics"), RELIC_ROW_RECT.position + Vector2(0, 29), 12, Color(TEXT, 0.62))
	var rects := _relic_icon_rects()
	if rects.is_empty():
		_draw_text(UiText.t("overlay.empty"), RELIC_ROW_RECT.position + Vector2(42, 29), 13, Color(TEXT, 0.42))
		return
	for entry in rects:
		var icon_rect: Rect2 = entry.get("rect", Rect2())
		if bool(entry.get("overflow", false)):
			draw_rect(icon_rect, Color("#c2ad82", 0.68), true)
			draw_rect(icon_rect, Color("#5a4128", 0.68), false, 1.0)
			_draw_text("+" + str(entry.get("count", 0)), icon_rect.position + Vector2(7, 19), 11, INK)
			continue
		var relic_id := str(entry.get("id", ""))
		var selected := relic_id != "" and relic_id == selected_relic_id
		var pulse := _relic_pulse_amount(relic_id)
		var draw_rect_target := _pulse_rect(icon_rect, pulse)
		draw_rect(draw_rect_target, Color("#c2ad82", 0.72 + 0.16 * pulse), true)
		draw_rect(draw_rect_target, GOLD if selected or pulse > 0.0 else Color("#5a4128", 0.72), false, 2.0 if selected or pulse > 0.0 else 1.0)
		var texture := AssetCatalog.relic_icon(RelicCatalog.icon_id(relic_id))
		if texture != null:
			draw_texture_rect(texture, draw_rect_target.grow(-3.0), false, Color(1, 1, 1, 0.92 + 0.08 * pulse))
		if pulse > 0.0:
			draw_rect(draw_rect_target.grow(3.0 + 5.0 * pulse), Color(GOLD, 0.62 * pulse), false, 2.0)

func _relic_pulse_amount(relic_id: String) -> float:
	if not relic_pulse_timers.has(relic_id):
		return 0.0
	var elapsed := 0.42 - float(relic_pulse_timers.get(relic_id, 0.0))
	var t: float = clamp(elapsed / 0.42, 0.0, 1.0)
	var rise: float = sin(t * PI)
	return clamp(rise, 0.0, 1.0)

func _pulse_rect(rect: Rect2, pulse: float) -> Rect2:
	if pulse <= 0.0:
		return rect
	var grow := 3.5 * pulse
	return rect.grow(grow)

func _draw_selected_relic_detail() -> void:
	if selected_relic_id == "":
		return
	var detail_rect := _detail_rect()
	UiSkin.draw_ledger_slip(self, detail_rect, Color(1, 1, 1, 0.92))
	var texture := AssetCatalog.relic_icon(RelicCatalog.icon_id(selected_relic_id))
	if texture != null:
		draw_texture_rect(texture, Rect2(detail_rect.position + Vector2(12, 16), Vector2(36, 36)), false, Color(1, 1, 1, 0.94))
	_draw_text(RelicCatalog.display_name(selected_relic_id), detail_rect.position + Vector2(58, 28), 15, INK)
	_draw_text(_clip(RelicCatalog.short_description(selected_relic_id), 39 if phase == "combat" else 43), detail_rect.position + Vector2(58, 50), 11, Color(INK, 0.62))

func _detail_rect() -> Rect2:
	if phase == "combat":
		return COMBAT_DETAIL_RECT
	return DETAIL_RECT

func _draw_marble_gallery() -> void:
	if not marble_gallery_open:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#020306", 0.54), true)
	var board_texture := AssetCatalog.combat_runtime_texture("marble_bag_overlay_board")
	if board_texture != null:
		draw_texture_rect(board_texture, MARBLE_GALLERY_RECT, false, Color(1, 1, 1, 0.96))
	else:
		draw_rect(MARBLE_GALLERY_RECT, Color("#090b0f", 0.94), true)
		draw_rect(MARBLE_GALLERY_RECT, Color("#8a6a3a", 0.72), false, 2.0)
	var marbles := _marble_deck_items()
	_draw_text(UiText.t("overlay.marble_gallery.title"), MARBLE_GALLERY_RECT.position + Vector2(182, 72), 24, TEXT)
	_draw_text(UiText.t("overlay.marble_gallery.count", {"count": marbles.size(), "max": MarbleCatalog.MAX_DECK_SIZE}), MARBLE_GALLERY_RECT.position + Vector2(184, 96), 13, Color(TEXT, 0.68))
	if marbles.is_empty():
		_draw_text(UiText.t("overlay.marble_gallery.empty"), MARBLE_GALLERY_RECT.position + Vector2(42, 146), 18, Color(TEXT, 0.62))
		return
	for i in range(min(marbles.size(), MarbleCatalog.MAX_DECK_SIZE)):
		_draw_marble_gallery_slot(_marble_gallery_slot_rect(i), marbles[i] as Dictionary, i == hovered_marble_gallery_index)
	_draw_marble_gallery_detail(_hovered_marble(marbles))

func _draw_marble_gallery_slot(rect: Rect2, marble: Dictionary, hovered: bool) -> void:
	var center := rect.get_center()
	draw_circle(center + Vector2(0, 3), 38.0, Color("#020304", 0.42))
	draw_circle(center, 37.0, Color("#140f0a", 0.46))
	draw_circle(center, 39.0, Color(GOLD, 0.55 if hovered else 0.20), false, 2.5 if hovered else 1.4)
	if hovered:
		draw_circle(center, 48.0, Color(GOLD, 0.15), false, 4.0)
	var marble_id := str(marble.get("marble_id", MarbleCatalog.PLAIN))
	var texture := AssetCatalog.marble_texture(str(marble.get("asset_key", MarbleCatalog.asset_key(marble_id))))
	var icon_rect := Rect2(center - Vector2(35, 35), Vector2(70, 70))
	if texture != null:
		draw_texture_rect(texture, icon_rect, false, Color(1, 1, 1, 1.0))
	else:
		draw_circle(icon_rect.get_center(), 32.0, Color("#e8e0cf"))

func _draw_marble_gallery_detail(marble: Dictionary) -> void:
	var rect := _marble_gallery_detail_rect()
	draw_rect(rect, Color("#090b0f", 0.30), true)
	draw_rect(rect, Color(GOLD, 0.20), false, 1.3)
	if marble.is_empty():
		return
	var marble_id := str(marble.get("marble_id", MarbleCatalog.PLAIN))
	var texture := AssetCatalog.marble_texture(str(marble.get("asset_key", MarbleCatalog.asset_key(marble_id))))
	var icon_rect := Rect2(rect.position + Vector2(20, 24), Vector2(86, 86))
	if texture != null:
		draw_texture_rect(texture, icon_rect, false, Color(1, 1, 1, 1.0))
	else:
		draw_circle(icon_rect.get_center(), 40.0, Color("#e8e0cf"))
	_fit_text_draw(str(marble.get("short_name", MarbleCatalog.short_name(marble_id))), rect.position + Vector2(126, 52), 24, TEXT, rect.size.x - 150.0)
	_fit_text_draw(str(marble.get("role", MarbleCatalog.role_text(marble_id))), rect.position + Vector2(126, 82), 13, Color(TEXT, 0.62), rect.size.x - 150.0)
	_fit_text_draw(str(marble.get("effect", MarbleCatalog.effect_text(marble_id))), rect.position + Vector2(22, 152), 17, GOLD, rect.size.x - 44.0)

func _relic_icon_rects() -> Array[Dictionary]:
	var relic_ids: Array = run_payload.get("relic_ids", [])
	var result: Array[Dictionary] = []
	var icon_size := 30.0
	var gap := 7.0
	var start := RELIC_ROW_RECT.position + Vector2(42, 4)
	var usable_width := RELIC_ROW_RECT.size.x - 48.0
	var max_slots: int = max(1, int(floor((usable_width + gap) / (icon_size + gap))))
	var visible_count := relic_ids.size()
	var overflow_count := 0
	if relic_ids.size() > max_slots:
		visible_count = max(0, max_slots - 1)
		overflow_count = relic_ids.size() - visible_count
	for i in range(visible_count):
		result.append({
			"id": str(relic_ids[i]),
			"rect": Rect2(start + Vector2(float(i) * (icon_size + gap), 0), Vector2(icon_size, icon_size)),
			"overflow": false
		})
	if overflow_count > 0:
		result.append({
			"rect": Rect2(start + Vector2(float(visible_count) * (icon_size + gap), 0), Vector2(40, icon_size)),
			"count": overflow_count,
			"overflow": true
		})
	return result

func _relic_at_position(pos: Vector2) -> String:
	for entry in _relic_icon_rects():
		if bool(entry.get("overflow", false)):
			continue
		var rect: Rect2 = entry.get("rect", Rect2())
		if rect.has_point(pos):
			return str(entry.get("id", ""))
	return ""

func _marble_deck_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var value: Variant = run_payload.get("marble_deck", [])
	if value is Array:
		for item in value:
			if item is Dictionary:
				result.append((item as Dictionary).duplicate(true))
	return result

func _hovered_marble(marbles: Array[Dictionary]) -> Dictionary:
	if hovered_marble_gallery_index < 0 or hovered_marble_gallery_index >= marbles.size():
		return {}
	return marbles[hovered_marble_gallery_index].duplicate(true)

func _marble_gallery_grid_rect() -> Rect2:
	return Rect2(MARBLE_GALLERY_RECT.position + Vector2(104, 154), Vector2(442, 324))

func _marble_gallery_detail_rect() -> Rect2:
	return Rect2(MARBLE_GALLERY_RECT.position + Vector2(626, 156), Vector2(286, 286))

func _marble_gallery_slot_rect(index: int) -> Rect2:
	var grid_rect := _marble_gallery_grid_rect()
	var col := index % MARBLE_GALLERY_COLUMNS
	var row := int(floor(float(index) / float(MARBLE_GALLERY_COLUMNS)))
	var offset := Vector2(float(col) * (MARBLE_GALLERY_SLOT_SIZE.x + MARBLE_GALLERY_GAP.x), float(row) * (MARBLE_GALLERY_SLOT_SIZE.y + MARBLE_GALLERY_GAP.y))
	return Rect2(grid_rect.position + offset, MARBLE_GALLERY_SLOT_SIZE)

func _marble_gallery_index_at(pos: Vector2) -> int:
	var marbles := _marble_deck_items()
	for i in range(min(marbles.size(), MarbleCatalog.MAX_DECK_SIZE)):
		if _marble_gallery_slot_rect(i).has_point(pos):
			return i
	return -1

func _fit_text_draw(text: String, pos: Vector2, font_size: int, color: Color, max_width: float) -> void:
	draw_string(ThemeDB.fallback_font, pos, _fit_text(text, font_size, max_width), HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, color)

func _fit_text(text: String, font_size: int, max_width: float) -> String:
	if _text_width(text, font_size) <= max_width:
		return text
	var suffix: String = "..."
	var available: int = max(0, text.length() - suffix.length())
	while available > 0:
		var candidate: String = text.substr(0, available).strip_edges() + suffix
		if _text_width(candidate, font_size) <= max_width:
			return candidate
		available -= 1
	return suffix

func _text_width(text: String, font_size: int) -> float:
	return ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x

func _clip(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, max_chars - 1) + "."

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
