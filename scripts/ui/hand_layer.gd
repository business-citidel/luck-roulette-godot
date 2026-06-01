class_name HandLayer
extends Control

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const YELLOW := Color("#f4da63")
const GREEN := Color("#65d48e")
const PURPLE := Color("#a879ef")
const BLUE := Color("#9bc7e8")

var dice: Array[int] = [1, 1]
var dice_locked: Array[bool] = [false, false]
var dice_rolled: bool = false
var rerolls_left: int = 2
var attack_base: int = 0
var selected_attack_die_index: int = -1
var guard_value: int = 0
var player_block: int = 0
var hovered_attack_die_index: int = -1
var dice_roll_fx: float = 0.0
var dice_roll_in_progress: bool = false
var marbles: Array[String] = []
var stored: Array[String] = []
var throwing_hand: bool = false
var hand_start_pos: Vector2 = Vector2.ZERO
var hand_pos: Vector2 = Vector2.ZERO
var hand_shake: float = 0.0
var hand_velocity: Vector2 = Vector2.ZERO
var hand_marble_preview: Array[String] = []
var thrown_marbles: Array = []
var marble_feedback_pos: Vector2 = Vector2.ZERO
var marble_feedback_color: Color = Color.WHITE
var marble_feedback_alpha: float = 0.0
var active_phase: String = "dice"

func _ready() -> void:
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_state(next_state: Dictionary) -> void:
	dice = next_state.get("dice", dice).duplicate()
	dice_locked = next_state.get("dice_locked", dice_locked).duplicate()
	dice_rolled = bool(next_state.get("dice_rolled", dice_rolled))
	rerolls_left = int(next_state.get("rerolls_left", rerolls_left))
	attack_base = int(next_state.get("attack_base", attack_base))
	selected_attack_die_index = int(next_state.get("selected_attack_die_index", selected_attack_die_index))
	guard_value = int(next_state.get("guard_value", guard_value))
	player_block = int(next_state.get("player_block", player_block))
	hovered_attack_die_index = int(next_state.get("hovered_attack_die_index", hovered_attack_die_index))
	dice_roll_fx = float(next_state.get("dice_roll_fx", dice_roll_fx))
	dice_roll_in_progress = bool(next_state.get("dice_roll_in_progress", dice_roll_in_progress))
	marbles = next_state.get("marbles", marbles).duplicate()
	stored = next_state.get("stored", stored).duplicate()
	throwing_hand = bool(next_state.get("throwing_hand", throwing_hand))
	hand_start_pos = next_state.get("hand_start_pos", hand_start_pos)
	hand_pos = next_state.get("hand_pos", hand_pos)
	hand_shake = float(next_state.get("hand_shake", hand_shake))
	hand_velocity = next_state.get("hand_velocity", hand_velocity)
	hand_marble_preview = next_state.get("hand_marble_preview", hand_marble_preview).duplicate()
	thrown_marbles = next_state.get("thrown_marbles", thrown_marbles).duplicate(true)
	marble_feedback_pos = next_state.get("marble_feedback_pos", marble_feedback_pos)
	marble_feedback_color = next_state.get("marble_feedback_color", marble_feedback_color)
	marble_feedback_alpha = float(next_state.get("marble_feedback_alpha", marble_feedback_alpha))
	active_phase = str(next_state.get("active_phase", active_phase))
	queue_redraw()

func _draw() -> void:
	_draw_dice_area()
	_draw_thrown_marbles()
	_draw_hand_throw_preview()

func _draw_dice_area() -> void:
	var dice_panel := Rect2(190, 516, 316, 118)
	if not _draw_runtime_combat_prop("dice_tray", dice_panel.grow(22.0), Color(1, 1, 1, 0.78)):
		draw_rect(dice_panel, Color("#080604", 0.62), true)
		draw_rect(dice_panel, Color(GOLD, 0.30), false, 2.0)
	if active_phase == "dice":
		var pulse := _focus_pulse()
		draw_rect(dice_panel.grow(5.0 + 3.0 * pulse), Color(GOLD, 0.24 + 0.18 * pulse), false, 3.0)
		draw_rect(dice_panel.grow(-5.0), Color("#fff3bd", 0.06 + 0.04 * pulse), true)
	if dice_roll_in_progress:
		_label_draw(UiText.t("battle.layer.rolling_in_cup"), Vector2(306, 570), 16, GOLD)
		_label_draw(UiText.t("battle.layer.roll_lands_here"), Vector2(286, 594), 12, MUTED)
		_draw_marble_tray()
		return
	for i in range(dice.size()):
		_draw_die(i)
	_label_draw(UiText.t("battle.layer.dice_contract"), Vector2(364, 548), 15, TEXT)
	_label_draw(UiText.t("battle.layer.attack_value", {"amount": attack_base}), Vector2(364, 572), 13, GOLD if attack_base > 0 else MUTED)
	_label_draw(UiText.t("battle.layer.guard_value", {"amount": player_block}), Vector2(364, 592), 12, BLUE if player_block > 0 else MUTED)
	_label_draw(UiText.t("battle.layer.rerolls", {"amount": rerolls_left}), Vector2(424, 592), 12, MUTED)
	_draw_prop_icon("dice", Rect2(458, 548, 34, 34), Color(1, 1, 1, 0.74))
	_draw_marble_tray()

func _draw_die(index: int) -> void:
	var rect: Rect2 = _die_rect(index)
	var center: Vector2 = rect.get_center()
	var wobble: float = dice_roll_fx * (0.35 if dice_locked[index] else 1.0)
	var angle: float = sin(float(Time.get_ticks_msec()) * 0.026 + float(index) * 1.7) * 0.16 * wobble
	var lift: float = sin(float(Time.get_ticks_msec()) * 0.041 + float(index)) * 5.0 * wobble
	var fill: Color = Color("#f4eadc")
	if dice_locked[index]:
		fill = Color("#f8d979")
	var is_attack := selected_attack_die_index == index
	var is_guard := selected_attack_die_index >= 0 and selected_attack_die_index != index
	var is_attack_choice_ready := active_phase == "dice" and dice_rolled and selected_attack_die_index < 0
	var is_hovered := is_attack_choice_ready and hovered_attack_die_index == index
	if is_hovered:
		draw_rect(Rect2(rect.position + Vector2(2, 5), rect.size + Vector2(8, 8)), Color(GOLD, 0.18), true)
	draw_rect(Rect2(rect.position + Vector2(5, 8), rect.size), Color("#05070a", 0.42), true)
	var hover_lift := -6.0 if is_hovered else 0.0
	var hover_scale := 0.06 if is_hovered else 0.0
	draw_set_transform(center + Vector2(0, lift + hover_lift), angle, Vector2(1.0 + wobble * 0.04 + hover_scale, 1.0 - wobble * 0.025 + hover_scale))
	var motion_texture: Texture2D = AssetCatalog.dice_motion_texture()
	if dice_roll_fx > 0.08 and not dice_locked[index] and motion_texture != null:
		var frame: int = int(Time.get_ticks_msec() / 38 + index * 37)
		var skew_scale := Vector2(1.0 + sin(float(Time.get_ticks_msec()) * 0.018 + float(index)) * 0.18, 0.88 + cos(float(Time.get_ticks_msec()) * 0.021) * 0.10)
		draw_set_transform(center + Vector2(0, lift), angle * 1.8, skew_scale)
		draw_texture_rect_region(motion_texture, Rect2(Vector2(-43, -43), Vector2(86, 86)), AssetCatalog.dice_motion_region(frame))
		draw_rect(Rect2(Vector2(-40, -40), Vector2(80, 80)), Color(GOLD, 0.34), false, 2.0)
	else:
		var texture: Texture2D = AssetCatalog.dice_face(dice[index])
		if texture != null:
			draw_texture_rect(texture, Rect2(Vector2(-41, -41), Vector2(82, 82)), false)
			var edge := GOLD if is_attack or is_hovered or dice_locked[index] else (BLUE if is_guard else Color("#2a303b", 0.42))
			draw_rect(Rect2(Vector2(-40, -40), Vector2(80, 80)), edge, false, 3.0 if is_attack or is_guard or is_hovered else 2.0)
		else:
			draw_rect(Rect2(Vector2(-38, -38), Vector2(76, 76)), fill, true)
			var fallback_edge := GOLD if is_attack or is_hovered or dice_locked[index] else (BLUE if is_guard else Color("#2a303b"))
			draw_rect(Rect2(Vector2(-38, -38), Vector2(76, 76)), fallback_edge, false, 3.0)
			draw_rect(Rect2(Vector2(-30, -30), Vector2(60, 60)), Color("#6f5940", 0.08), false, 2.0)
			_draw_die_pips(dice[index])
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if dice_locked[index]:
		_label_draw("LOCK", rect.position + Vector2(17, -8), 13, GOLD)
	elif is_attack or is_hovered:
		_label_draw(UiText.t("battle.die.attack"), rect.position + Vector2(17, -8), 13, GOLD)
	elif is_guard:
		_label_draw(UiText.t("battle.layer.guard_value", {"amount": ""}).strip_edges(), rect.position + Vector2(17, -8), 13, BLUE)

func _draw_die_pips(value: int) -> void:
	var pip_sets: Dictionary = {
		1: [Vector2(0, 0)],
		2: [Vector2(-18, -18), Vector2(18, 18)],
		3: [Vector2(-18, -18), Vector2(0, 0), Vector2(18, 18)],
		4: [Vector2(-18, -18), Vector2(18, -18), Vector2(-18, 18), Vector2(18, 18)],
		5: [Vector2(-18, -18), Vector2(18, -18), Vector2(0, 0), Vector2(-18, 18), Vector2(18, 18)],
		6: [Vector2(-18, -20), Vector2(18, -20), Vector2(-18, 0), Vector2(18, 0), Vector2(-18, 20), Vector2(18, 20)]
	}
	var points: Array = pip_sets.get(value, [Vector2.ZERO])
	for point in points:
		draw_circle(point, 5.0, Color("#111111", 0.9))
		draw_circle(point + Vector2(-1.4, -1.4), 1.6, Color("#6c5641", 0.55))

func _draw_marble_tray() -> void:
	var rect: Rect2 = _hand_rect()
	draw_rect(rect, Color("#090705", 0.64), true)
	draw_rect(rect, Color(GOLD, 0.72 if marbles.size() > 0 else 0.24), false, 2.0)
	if active_phase == "marble":
		var pulse := _focus_pulse()
		draw_rect(rect.grow(5.0 + 3.0 * pulse), Color(GOLD, 0.22 + 0.18 * pulse), false, 3.0)
		draw_rect(rect.grow(-5.0), Color("#fff3bd", 0.05 + 0.04 * pulse), true)
	if not _draw_runtime_combat_prop("marble_pouch", Rect2(rect.position + Vector2(4, -20), Vector2(84, 54)), Color(1, 1, 1, 0.78)):
		_draw_prop_icon("pouch", Rect2(rect.position + Vector2(12, 14), Vector2(38, 38)), Color(1, 1, 1, 0.68))
	_label_draw(UiText.t("battle.layer.marble_pouch"), rect.position + Vector2(58, 24), 15, TEXT if marbles.size() > 0 else Color(MUTED, 0.6))
	_label_draw(UiText.t("battle.layer.slot_boost_count", {"count": marbles.size()}), rect.position + Vector2(58, 47), 12, MUTED)
	var shake_offset: Vector2 = Vector2.ZERO
	if throwing_hand:
		shake_offset = Vector2(sin(float(Time.get_ticks_msec()) * 0.06) * min(10.0, hand_shake / 18.0), cos(float(Time.get_ticks_msec()) * 0.047) * min(7.0, hand_shake / 26.0))
	for i in range(marbles.size()):
		var pos: Vector2 = _hand_marble_pos(i) + shake_offset
		draw_circle(pos + Vector2(3, 5), 10.0, Color("#020304", 0.35))
		_draw_marble_sprite(marbles[i], pos, 32.0)
	if throwing_hand:
		var power: float = clamp(hand_shake / 160.0 + hand_velocity.length() / 90.0, 0.45, 1.65)
		_meter(Rect2(rect.position + Vector2(18, 82), Vector2(188, 8)), power / 1.65, GOLD)
		_label_draw(UiText.t("battle.layer.shake_power"), rect.position + Vector2(82, 106), 12, GOLD)
	if marble_feedback_alpha > 0.0:
		var radius: float = 14.0 + (1.0 - marble_feedback_alpha) * 24.0
		draw_arc(marble_feedback_pos, radius, 0.0, TAU, 36, Color(marble_feedback_color, marble_feedback_alpha), 3.0)

func _draw_thrown_marbles() -> void:
	for marble in thrown_marbles:
		var pos: Vector2 = marble["pos"]
		var color: String = str(marble["color"])
		draw_circle(pos + Vector2(4, 7), 13.0, Color("#020304", 0.28))
		_draw_marble_sprite(color, pos, 38.0)

func _draw_hand_throw_preview() -> void:
	if not throwing_hand:
		return
	var start: Vector2 = _hand_rect().get_center()
	var target: Vector2 = Vector2(640, 340)
	var pull: Vector2 = (hand_pos - hand_start_pos).limit_length(130.0)
	var preview_end: Vector2 = target + pull * 0.35
	draw_line(start, preview_end, Color(GOLD, 0.28), 3.0)
	draw_circle(preview_end, 44.0 + min(22.0, hand_shake / 12.0), Color(GOLD, 0.08))
	for i in range(min(hand_marble_preview.size(), 8)):
		var angle: float = float(i) / 8.0 * TAU + float(Time.get_ticks_msec()) * 0.006
		var pos: Vector2 = hand_pos + Vector2(cos(angle), sin(angle)) * (18.0 + min(24.0, hand_shake / 10.0))
		draw_circle(pos + Vector2(3, 5), 10.0, Color("#020304", 0.26))
		_draw_marble_sprite(hand_marble_preview[i], pos, 32.0)

func _die_rect(index: int) -> Rect2:
	var gap: float = 14.0
	var die_size: float = 58.0
	var count: int = max(1, dice.size())
	var total_width: float = float(count) * die_size + float(count - 1) * gap
	var start_x: float = 281.0 - total_width * 0.5
	return Rect2(Vector2(start_x + float(index) * (die_size + gap), 542), Vector2(die_size, die_size))

func _hand_rect() -> Rect2:
	return Rect2(Vector2(790, 526), Vector2(220, 78))

func _hand_marble_pos(index: int) -> Vector2:
	return Vector2(970 + float(index % 3) * 18.0, 556 + floor(float(index) / 3.0) * 18.0)

func _marble_color(color: String) -> Color:
	if color == "yellow":
		return YELLOW
	if color == "green":
		return GREEN
	if color == "plain":
		return Color("#e8e0cf")
	return PURPLE

func _draw_marble_sprite(color: String, center: Vector2, size_px: float) -> void:
	var texture: Texture2D = AssetCatalog.marble_texture(color)
	if texture == null:
		draw_circle(center, size_px * 0.42, _marble_color(color))
		draw_circle(center + Vector2(-size_px * 0.12, -size_px * 0.12), size_px * 0.12, Color("#ffffff", 0.65))
		return
	draw_texture_rect(texture, Rect2(center - Vector2(size_px, size_px) * 0.5, Vector2(size_px, size_px)), false)

func _meter(rect: Rect2, ratio: float, color: Color) -> void:
	var clamped: float = clamp(ratio, 0.0, 1.0)
	draw_rect(rect, Color("#07090d"), true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clamped, rect.size.y)), color, true)
	draw_rect(rect, Color(TEXT, 0.18), false, 1.0)

func _label_draw(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _draw_prop_icon(prop_id: String, rect: Rect2, modulate: Color) -> void:
	var texture: Texture2D = AssetCatalog.prop_icon(prop_id)
	if texture != null:
		draw_texture_rect(texture, rect, false, modulate)

func _draw_runtime_combat_prop(texture_id: String, rect: Rect2, modulate: Color) -> bool:
	var texture: Texture2D = AssetCatalog.combat_runtime_texture(texture_id)
	if texture == null:
		return false
	draw_texture_rect(texture, rect, false, modulate)
	return true

func _focus_pulse() -> float:
	return 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.008)
