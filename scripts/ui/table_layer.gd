class_name TableLayer
extends Control

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const RouletteSlotCatalog := preload("res://scripts/systems/roulette_slot_catalog.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const LINE := Color("#495569")
const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const BG := Color("#07090f")
const YELLOW := Color("#f4da63")
const GREEN := Color("#65d48e")
const PURPLE := Color("#a879ef")

var table_pulse: float = 0.0
var table_hit_flash: float = 0.0
var wheel_angle: float = -90.0
var wheel_tick_flash: float = 0.0
var wheel_pointer_kick: float = 0.0
var placed_slots: Dictionary = {}
var pending_slot: String = ""
var slot_feedback_id: String = ""
var slot_feedback_alpha: float = 0.0
var spin_ready_flash: float = 0.0
var marble_setup_ready: bool = false
var hovered_slot_id: String = ""
var hovered_spin_wheel: bool = false
var coin_particles: Array = []
var active_phase: String = "dice"
var numeric_roulette_cells: Array = []
var numeric_roulette_index: int = -1
var numeric_roulette_multiplier: float = 0.0
var wager_marbles_available: int = 0
var wager_marbles_committed: int = 0

func _ready() -> void:
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_state(next_state: Dictionary) -> void:
	table_pulse = float(next_state.get("table_pulse", table_pulse))
	table_hit_flash = float(next_state.get("table_hit_flash", table_hit_flash))
	wheel_angle = float(next_state.get("wheel_angle", wheel_angle))
	wheel_tick_flash = float(next_state.get("wheel_tick_flash", wheel_tick_flash))
	wheel_pointer_kick = float(next_state.get("wheel_pointer_kick", wheel_pointer_kick))
	placed_slots = next_state.get("placed_slots", placed_slots).duplicate(true)
	pending_slot = str(next_state.get("pending_slot", pending_slot))
	slot_feedback_id = str(next_state.get("slot_feedback_id", slot_feedback_id))
	slot_feedback_alpha = float(next_state.get("slot_feedback_alpha", slot_feedback_alpha))
	spin_ready_flash = float(next_state.get("spin_ready_flash", spin_ready_flash))
	marble_setup_ready = bool(next_state.get("marble_setup_ready", marble_setup_ready))
	hovered_slot_id = str(next_state.get("hovered_slot_id", hovered_slot_id))
	hovered_spin_wheel = bool(next_state.get("hovered_spin_wheel", hovered_spin_wheel))
	coin_particles = next_state.get("coin_particles", coin_particles).duplicate(true)
	active_phase = str(next_state.get("active_phase", active_phase))
	numeric_roulette_cells = next_state.get("numeric_roulette_cells", numeric_roulette_cells).duplicate(true)
	numeric_roulette_index = int(next_state.get("numeric_roulette_index", numeric_roulette_index))
	numeric_roulette_multiplier = float(next_state.get("numeric_roulette_multiplier", numeric_roulette_multiplier))
	wager_marbles_available = int(next_state.get("wager_marbles_available", wager_marbles_available))
	wager_marbles_committed = int(next_state.get("wager_marbles_committed", wager_marbles_committed))
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-1600, -1200), Vector2(4480, 3120)), BG, true)
	_draw_backdrop()
	_draw_roulette_area()
	_draw_coin_particles()

func _draw_backdrop() -> void:
	var texture: Texture2D = AssetCatalog.art_pack_texture("battle_table_bg")
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, Vector2(1280, 720)), false)
		if table_hit_flash > 0.0:
			draw_rect(Rect2(0, 0, 1280, 720), Color(GOLD, 0.055 * table_hit_flash), true)
		return
	var table_center := Vector2(640, 390)
	draw_circle(table_center, 560.0 + table_pulse * 12.0 + table_hit_flash * 18.0, Color("#24140d", 0.94))
	draw_circle(table_center + Vector2(0, 18), 494.0, Color("#4a2f1b", 0.48))
	draw_circle(table_center + Vector2(0, 18), 418.0, Color("#111b16", 0.86))
	draw_circle(table_center + Vector2(0, 18), 420.0, Color("#865b2d", 0.44), false, 7.0)
	for i in range(10):
		var angle: float = -0.9 + float(i) * 0.2
		var start: Vector2 = table_center + Vector2(cos(angle), sin(angle)) * 120.0
		var end: Vector2 = table_center + Vector2(cos(angle), sin(angle)) * 510.0
		draw_line(start, end, Color("#8a5a2d", 0.08), 24.0)
	draw_rect(Rect2(0, 636, 1280, 84), Color("#030407", 0.94), true)
	if table_hit_flash > 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(GOLD, 0.055 * table_hit_flash), true)

func _draw_panels() -> void:
	pass

func _draw_roulette_area() -> void:
	var center: Vector2 = Vector2(640, 360)
	var radius: float = 154.0
	var has_numeric_roulette := not numeric_roulette_cells.is_empty()
	if has_numeric_roulette:
		_draw_numeric_roulette(center, radius)
	elif not _draw_runtime_roulette(center) and not _draw_art_pack_roulette(center):
		draw_circle(center + Vector2(18, 28), 242.0, Color("#020304", 0.35))
		draw_circle(center, 226.0, Color("#2a1810"))
		draw_circle(center, 214.0, Color("#c08a39", 0.18), false, 7.0)
		draw_circle(center, 188.0, Color("#0d1412", 0.18), false, 2.0)
		var slot_ids: Array[String] = RouletteSlotCatalog.slot_ids()
		for i in range(slot_ids.size()):
			var start_angle: float = deg_to_rad(wheel_angle + float(i) * 72.0 - 126.0)
			var end_angle: float = deg_to_rad(wheel_angle + float(i + 1) * 72.0 - 126.0)
			_sector(center, radius, start_angle, end_angle, RouletteSlotCatalog.color(slot_ids[i]))
			var pocket_angle: float = lerp(start_angle, end_angle, 0.5)
			var pocket_pos: Vector2 = center + Vector2(cos(pocket_angle), sin(pocket_angle)) * 166.0
			draw_circle(pocket_pos, 12.0, Color("#06080d", 0.9))
			draw_circle(pocket_pos, 12.0, Color("#e8c16a", 0.44), false, 2.0)
		draw_circle(center, 62.0, Color("#090c12"))
		draw_circle(center, 40.0, GOLD)
		_draw_center_prop_icon(center)
		_label_draw(UiText.t("battle.layer.multiplier"), center + Vector2(-16, 7), 14, Color("#171009"))
	var pointer_y: float = -204.0 - wheel_pointer_kick * 10.0
	if not _draw_runtime_roulette_pointer(center, pointer_y):
		draw_line(center, center + Vector2(0, pointer_y), TEXT, 3.0 + wheel_tick_flash * 2.0)
		draw_polygon(PackedVector2Array([center + Vector2(0, pointer_y - 4.0), center + Vector2(-16, pointer_y - 32.0), center + Vector2(16, pointer_y - 32.0)]), PackedColorArray([TEXT, TEXT, TEXT]))
	if wheel_tick_flash > 0.0:
		draw_circle(center + Vector2(0, pointer_y - 31.0), 24.0 + wheel_tick_flash * 14.0, Color(GOLD, 0.18 * wheel_tick_flash))

	if not has_numeric_roulette:
		for id in RouletteSlotCatalog.slot_ids():
			_draw_drop_slot(id)

	if not has_numeric_roulette and pending_slot != "":
		var p: Vector2 = _slot_center(pending_slot)
		var pulse := _focus_pulse()
		draw_circle(p, 58.0 + 6.0 * pulse, Color(GOLD, 0.08 + 0.10 * pulse))
		draw_circle(p, 48.0, Color(TEXT, 0.18))
		draw_circle(p, 42.0, Color(GOLD, 0.2))
	if marble_setup_ready:
		var pulse: float = 0.4 + 0.6 * sin(float(Time.get_ticks_msec()) * 0.008) * spin_ready_flash
		var hover_alpha := 0.08 if hovered_spin_wheel else 0.0
		draw_circle(center, 216.0, Color(GOLD, 0.08 + 0.08 * pulse + hover_alpha), false, 4.0 if not hovered_spin_wheel else 6.0)
		draw_circle(center, 92.0, Color(GOLD, 0.12 if hovered_spin_wheel else 0.045), true)
		_label_draw(UiText.t("battle.layer.click_roulette") if hovered_spin_wheel else UiText.t("battle.layer.setup_done"), center + Vector2(-34, -222), 16, GOLD)
	if has_numeric_roulette and (active_phase == "wager" or active_phase == "intervene"):
		_draw_numeric_wager_status(center)

func _draw_numeric_roulette(center: Vector2, radius: float) -> void:
	draw_circle(center + Vector2(18, 28), 242.0, Color("#020304", 0.35))
	draw_circle(center, 226.0, Color("#21170f"))
	draw_circle(center, 214.0, Color(GOLD, 0.12), false, 7.0)
	var count := numeric_roulette_cells.size()
	var step := TAU / float(count)
	var base_angle := deg_to_rad(wheel_angle - 90.0)
	var show_result_highlight := active_phase == "intervene" and numeric_roulette_index >= 0
	for i in range(count):
		var highlighted := show_result_highlight and i == numeric_roulette_index
		var start_angle := base_angle + float(i) * step - step * 0.5
		var end_angle := start_angle + step
		var sector_color := Color("#26313a", 0.92) if i % 2 == 0 else Color("#171f28", 0.92)
		if highlighted:
			sector_color = Color(GOLD, 0.70)
		_sector(center, radius, start_angle, end_angle, sector_color)
		draw_arc(center, radius + 6.0, start_angle, end_angle, 12, Color(GOLD, 0.82 if highlighted else 0.20), 3.0 if highlighted else 1.5)
		var label_angle := start_angle + step * 0.5
		var label_pos := center + Vector2(cos(label_angle), sin(label_angle)) * 130.0
		var label := _numeric_roulette_cell_label(numeric_roulette_cells[i])
		var label_size := _label_size(label, 18)
		var text_color := Color("#171009") if highlighted else TEXT
		draw_circle(label_pos, 30.0 if highlighted else 24.0, Color("#07090f", 0.74 if highlighted else 0.54))
		if highlighted:
			draw_circle(label_pos, 33.0 + 4.0 * _focus_pulse(), Color(GOLD, 0.24), false, 3.0)
		_label_draw(label, label_pos - Vector2(label_size.x * 0.5, -label_size.y * 0.30), 18, text_color)
	_draw_numeric_read_axis(center, radius)
	draw_circle(center, 62.0, Color("#090c12"))
	draw_circle(center, 40.0, GOLD)
	_label_draw(UiText.t("battle.layer.multiplier"), center + Vector2(-16, 7), 14, Color("#171009"))

func _draw_numeric_read_axis(center: Vector2, radius: float) -> void:
	var top := center + Vector2(0, -radius - 8.0)
	var inner := center + Vector2(0, -70.0)
	draw_line(inner, top, Color(TEXT, 0.46), 3.0 + wheel_tick_flash * 1.4)
	draw_arc(center, radius + 13.0, deg_to_rad(-95.0), deg_to_rad(-85.0), 10, Color(GOLD, 0.72), 5.0)
	if active_phase == "spinning":
		draw_circle(top, 17.0 + wheel_tick_flash * 8.0, Color(GOLD, 0.13 + wheel_tick_flash * 0.08), false, 3.0)
	elif active_phase == "intervene" and numeric_roulette_index >= 0:
		draw_circle(top, 20.0 + 5.0 * _focus_pulse(), Color(GOLD, 0.20), false, 4.0)

func _draw_numeric_wager_status(center: Vector2) -> void:
	var committed := "Committed %d" % wager_marbles_committed
	var available := "available %d" % wager_marbles_available
	var multiplier := "x%s" % _format_multiplier(numeric_roulette_multiplier)
	var line := "%s / %s / %s" % [committed, available, multiplier]
	var label_size := _label_size(line, 13)
	_label_draw(line, center + Vector2(-label_size.x * 0.5, 236.0), 13, Color(MUTED, 0.92))

func _draw_runtime_roulette(center: Vector2) -> bool:
	var texture: Texture2D = AssetCatalog.combat_runtime_texture("roulette_wheel")
	if texture == null:
		return false
	var target := Vector2(360, 360)
	var shadow := Rect2(center - target * 0.5 + Vector2(18, 28), target)
	draw_texture_rect(texture, shadow, false, Color(0, 0, 0, 0.36))
	draw_set_transform(center, deg_to_rad(wheel_angle), Vector2.ONE)
	draw_texture_rect(texture, Rect2(-target * 0.5, target), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

func _draw_runtime_roulette_pointer(center: Vector2, pointer_y: float) -> bool:
	var texture: Texture2D = AssetCatalog.combat_runtime_texture("roulette_pointer")
	if texture == null:
		return false
	var target := Vector2(46, 126)
	var top_center := center + Vector2(0.0, pointer_y - 8.0 - wheel_pointer_kick * 5.0)
	draw_texture_rect(texture, Rect2(top_center - Vector2(target.x * 0.5, target.y * 0.12), target), false, Color(1, 1, 1, 0.96 + min(0.04, wheel_tick_flash * 0.02)))
	return true

func _draw_art_pack_roulette(center: Vector2) -> bool:
	var texture: Texture2D = AssetCatalog.art_pack_texture("roulette_wheel")
	if texture == null:
		return false
	var target := Vector2(330, 330)
	var shadow := Rect2(center - target * 0.5 + Vector2(18, 28), target)
	draw_texture_rect(texture, shadow, false, Color(0, 0, 0, 0.34))
	draw_set_transform(center, deg_to_rad(wheel_angle), Vector2.ONE)
	draw_texture_rect(texture, Rect2(-target * 0.5, target), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

func _draw_center_prop_icon(center: Vector2) -> void:
	var texture: Texture2D = AssetCatalog.prop_icon("roulette")
	if texture == null:
		return
	draw_texture_rect(texture, Rect2(center - Vector2(22, 22), Vector2(44, 44)), false, Color(1, 1, 1, 0.72))

func _draw_drop_slot(id: String) -> void:
	var center: Vector2 = _slot_center(id)
	var color: Color = RouletteSlotCatalog.color(id)
	var arr: Array = placed_slots.get(id, [])
	var plate_rect: Rect2 = Rect2(center - Vector2(43, 28), Vector2(86, 56))
	draw_rect(plate_rect, Color("#070807", 0.78), true)
	draw_rect(plate_rect, Color(color, 0.66), false, 2.0)
	draw_rect(plate_rect.grow(-5), Color(color, 0.1), true)
	_label_draw(RouletteSlotCatalog.label(id), center + Vector2(-25, -6), 17, TEXT)
	_label_draw(RouletteSlotCatalog.reward_text(id), center + Vector2(-14, 17), 12, GOLD)
	if arr.size() > 0:
		_label_draw(UiText.t("battle.layer.boosted"), center + Vector2(-15, 35), 10, Color(GOLD, 0.92))
	for i in range(min(arr.size(), 4)):
		draw_circle(center + Vector2(-21 + float(i) * 14.0, -24), 6.0, _marble_color(str(arr[i])))
	if active_phase == "marble" and arr.is_empty():
		var pulse := _focus_pulse()
		var hovered := hovered_slot_id == id
		var grow := 8.0 + pulse * 5.0 if hovered else 4.0 + pulse * 4.0
		var alpha := 0.48 + pulse * 0.22 if hovered else 0.30 + pulse * 0.18
		draw_rect(plate_rect.grow(grow), Color(color, alpha), false, 3.0 if hovered else 2.0)
		if hovered:
			draw_rect(plate_rect.grow(-4.0), Color(color, 0.16), true)
	elif active_phase == "intervene" and pending_slot == id:
		var pulse := _focus_pulse()
		draw_rect(plate_rect.grow(8.0 + pulse * 6.0), Color(GOLD, 0.48 + pulse * 0.22), false, 4.0)
	if slot_feedback_id == id and slot_feedback_alpha > 0.0:
		draw_rect(plate_rect.grow(7.0 + (1.0 - slot_feedback_alpha) * 10.0), Color(TEXT, 0.52 * slot_feedback_alpha), false, 3.0)

func _draw_coin_particles() -> void:
	for particle in coin_particles:
		var life: float = float(particle["life"])
		var max_life: float = float(particle["max_life"])
		var alpha: float = clamp(life / max_life, 0.0, 1.0)
		var pos: Vector2 = particle["pos"]
		var radius: float = float(particle["radius"])
		draw_circle(pos + Vector2(2, 3), radius, Color("#020304", 0.25 * alpha))
		draw_circle(pos, radius, Color(GOLD, 0.92 * alpha))
		draw_circle(pos + Vector2(-1.5, -1.5), radius * 0.28, Color("#fff2aa", 0.8 * alpha))

func _slot_center(id: String) -> Vector2:
	var index: int = RouletteSlotCatalog.index(id)
	var angle: float = deg_to_rad(-90.0 + float(index) * 72.0)
	return Vector2(640, 360) + Vector2(cos(angle), sin(angle)) * 196.0

func _marble_color(color: String) -> Color:
	if color == "yellow":
		return YELLOW
	if color == "green":
		return GREEN
	if color == "plain":
		return Color("#e8e0cf")
	return PURPLE

func _panel(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color, true)
	draw_rect(rect, Color(LINE, 0.72), false, 2.0)
	draw_rect(rect.grow(-8), Color("#ffffff", 0.025), false, 1.0)

func _sector(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	points.append(center)
	colors.append(color)
	for i in range(19):
		var t: float = float(i) / 18.0
		var angle: float = lerp(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		colors.append(color)
	draw_polygon(points, colors)

func _label_draw(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _label_size(text: String, font_size: int) -> Vector2:
	return ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)

func _numeric_roulette_cell_label(cell: Variant) -> String:
	if cell is Dictionary:
		var data: Dictionary = cell
		if data.has("label"):
			return str(data["label"])
		if data.has("multiplier"):
			return "x%s" % _format_multiplier(float(data["multiplier"]))
	if typeof(cell) == TYPE_FLOAT or typeof(cell) == TYPE_INT:
		return "x%s" % _format_multiplier(float(cell))
	return str(cell)

func _format_multiplier(value: float) -> String:
	return str(snapped(value, 0.01))

func _focus_pulse() -> float:
	return 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.008)
