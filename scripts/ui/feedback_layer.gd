extends Control

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiLayoutSpec := preload("res://scripts/ui/ui_layout_spec.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const PANEL := Color("#05070dcc")
const TEXT := Color("#f6efe2")
const GOLD := Color("#f2be4b")
const RED := Color("#ee5b5b")
const GREEN := Color("#65d48e")
const MUTED := Color("#aab4c3")

class ResultTrayBackplate:
	extends Control

	const UiSkin := preload("res://scripts/ui/ui_skin.gd")

	var tint: Color = Color.WHITE

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		UiSkin.draw_result_tray(self, Rect2(Vector2.ZERO, size), tint)

var target_positions := {
	"dice": Vector2(515, 286),
	"roulette": Vector2(1000, 270),
	"cash": Vector2(128, 166),
	"bust": Vector2(890, 490),
	"enemy": Vector2(972, 126),
	"table": Vector2(640, 520)
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 100

func show_events(events: Array) -> void:
	var lane_offsets := {}
	for event in events:
		if not event is Dictionary:
			continue
		var target: String = str(event.get("target", "table"))
		var lane: int = int(lane_offsets.get(target, 0))
		lane_offsets[target] = lane + 1
		_spawn_event(event, lane)

func show_combat_result(outcome: Dictionary) -> void:
	var damage: int = int(outcome.get("damage", 0))
	var attack_base: int = int(outcome.get("attack_base", 0))
	var multiplier: float = float(outcome.get("damage_multiplier", outcome.get("payout_multiplier", 1.0)))
	var cash_delta: int = int(outcome.get("cash_delta", 0))
	var bust_delta: int = int(outcome.get("bust_delta", 0))
	var banner: String = str(outcome.get("banner", "RESULT"))
	var boosted: bool = bool(outcome.get("boosted", false))
	var stamp_color: Color = RED if bust_delta > 0 else (GOLD if boosted else TEXT)

	_spawn_result_tray(stamp_color)
	_spawn_result_stamp(banner, stamp_color)
	if damage > 0:
		_spawn_calc_plate(UiText.t("payout.damage", {
			"boosted": "",
			"attack": attack_base,
			"multiplier": _format_multiplier(multiplier),
			"damage": damage
		}), boosted)
		_spawn_damage_number(damage)
	elif bust_delta > 0:
		_spawn_calc_plate(UiText.t("battle.layer.attack_void"), false, RED)
		_spawn_bust_mark(bust_delta)
	else:
		_spawn_calc_plate(str(outcome.get("message", UiText.t("battle.layer.apply_result"))), false, MUTED)
	if cash_delta != 0:
		_spawn_cash_delta(cash_delta)

func _spawn_result_tray(tint: Color) -> void:
	var tray := ResultTrayBackplate.new()
	tray.tint = Color(tint, 0.56)
	tray.position = UiLayoutSpec.RESULT_TRAY.position
	tray.size = UiLayoutSpec.RESULT_TRAY.size
	tray.modulate.a = 0.0
	add_child(tray)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(tray, "position:y", tray.position.y - 30.0, 1.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(tray, "modulate:a", 1.0, 0.12)
	tween.chain().tween_property(tray, "modulate:a", 0.0, 0.32)
	tween.finished.connect(func() -> void:
		tray.queue_free()
	)

func show_dice_result(values: Array, attack_base: int, rerolls_left: int) -> void:
	var dice_nodes: Array[TextureRect] = []
	var count: int = clamp(values.size(), 1, 2)
	for i in range(count):
		var value: int = int(values[i]) if i < values.size() else 1
		var texture: Texture2D = AssetCatalog.dice_motion_result_texture(value)
		var die := TextureRect.new()
		die.texture = texture
		die.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		die.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		die.position = Vector2(238 + float(i) * 56.0, 504)
		die.size = Vector2(86, 86)
		die.pivot_offset = die.size * 0.5
		die.scale = Vector2(0.82, 0.82)
		die.modulate.a = 0.0
		add_child(die)
		dice_nodes.append(die)

	var title_text := UiText.t("battle.layer.attack_value", {"amount": attack_base}) if attack_base > 0 else UiText.t("battle.layer.attack_choice")
	var title := _floating_label(title_text, 18, GOLD, Vector2(248, 486), Vector2(190, 28))
	var hint := _floating_label(UiText.t("battle.layer.reroll_confirm", {"rerolls": rerolls_left}), 12, MUTED, Vector2(248, 508), Vector2(190, 22))
	add_child(title)
	add_child(hint)

	var tween := create_tween()
	tween.set_parallel(true)
	for die in dice_nodes:
		tween.tween_property(die, "scale", Vector2(1.0, 1.0), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(die, "modulate:a", 1.0, 0.08)
	tween.tween_property(title, "modulate:a", 1.0, 0.10)
	tween.tween_property(hint, "modulate:a", 1.0, 0.14)
	tween.chain().tween_interval(0.28)
	for die in dice_nodes:
		tween.chain().tween_property(die, "modulate:a", 0.0, 0.28)
	tween.parallel().tween_property(title, "modulate:a", 0.0, 0.28)
	tween.parallel().tween_property(hint, "modulate:a", 0.0, 0.28)
	tween.finished.connect(func() -> void:
		for die in dice_nodes:
			die.queue_free()
		title.queue_free()
		hint.queue_free()
	)

func _spawn_event(event: Dictionary, lane: int) -> void:
	var label := Label.new()
	label.text = str(event.get("label", "Effect"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", event.get("color", TEXT))
	label.add_theme_color_override("font_shadow_color", Color("#000000cc"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.modulate.a = 0.0
	label.size = Vector2(220, 32)
	var pos: Vector2 = target_positions.get(str(event.get("target", "table")), target_positions["table"])
	pos += Vector2(-110, -22 - lane * 30)
	label.position = pos
	add_child(label)

	var background := ColorRect.new()
	background.color = PANEL
	background.position = pos + Vector2(8, 4)
	background.size = Vector2(204, 24)
	background.modulate.a = 0.0
	add_child(background)
	move_child(background, label.get_index())

	var travel: float = 26.0 + 10.0 * float(event.get("intensity", 1.0))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - travel, 1.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(background, "position:y", background.position.y - travel, 1.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 1.0, 0.12)
	tween.tween_property(background, "modulate:a", 1.0, 0.12)
	tween.chain().tween_property(label, "modulate:a", 0.0, 0.28)
	tween.parallel().tween_property(background, "modulate:a", 0.0, 0.28)
	tween.finished.connect(func() -> void:
		if is_instance_valid(label):
			label.queue_free()
		if is_instance_valid(background):
			background.queue_free()
	)

func _spawn_result_stamp(text: String, color: Color) -> void:
	var label := _floating_label(text, 28, color, Vector2(820, 306), Vector2(248, 48))
	add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 24.0, 0.95).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 1.0, 0.10)
	tween.chain().tween_property(label, "modulate:a", 0.0, 0.26)
	tween.finished.connect(func() -> void:
		label.queue_free()
	)

func _spawn_calc_plate(text: String, boosted: bool, override_color: Color = Color.TRANSPARENT) -> void:
	var color: Color = override_color if override_color != Color.TRANSPARENT else (GOLD if boosted else TEXT)
	var tray := UiLayoutSpec.RESULT_TRAY
	var plate_pos := tray.position + Vector2(0.0, 64.0)
	var label := _floating_label(text, 18, color, plate_pos + Vector2(12.0, 2.0), Vector2(300, 34))
	var background := _plate_bg(plate_pos, Vector2(tray.size.x, 40.0), Color("#070807", 0.78), color)
	_add_behind(background, label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30.0, 1.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(background, "position:y", background.position.y - 30.0, 1.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 1.0, 0.12)
	tween.tween_property(background, "modulate:a", 1.0, 0.12)
	tween.chain().tween_property(label, "modulate:a", 0.0, 0.32)
	tween.parallel().tween_property(background, "modulate:a", 0.0, 0.32)
	tween.finished.connect(func() -> void:
		label.queue_free()
		background.queue_free()
	)

func _spawn_damage_number(amount: int) -> void:
	var label := _floating_label("-" + str(amount), 44, RED, Vector2(834, 300), Vector2(180, 58))
	add_child(label)
	var hit_pos := Vector2(604, 118)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", hit_pos, 0.62).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", Vector2(1.18, 1.18), 0.18)
	tween.tween_property(label, "modulate:a", 1.0, 0.06)
	tween.chain().tween_property(label, "position:y", hit_pos.y - 32.0, 0.34).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.34)
	tween.finished.connect(func() -> void:
		label.queue_free()
	)

func _spawn_bust_mark(amount: int) -> void:
	var label := _floating_label(UiText.t("battle.layer.bust"), 30, RED, Vector2(842, 356), Vector2(200, 48))
	add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 64.0, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 1.0, 0.08)
	tween.chain().tween_property(label, "modulate:a", 0.0, 0.28)
	tween.finished.connect(func() -> void:
		label.queue_free()
	)

func _spawn_cash_delta(amount: int) -> void:
	var sign := "+" if amount > 0 else ""
	var color := GREEN if amount > 0 else RED
	var label := _floating_label(UiText.t("battle.layer.reward_delta", {"delta": sign + str(amount)}), 18, color, Vector2(804, 420), Vector2(300, 32))
	add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 42.0, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 1.0, 0.12)
	tween.chain().tween_property(label, "modulate:a", 0.0, 0.28)
	tween.finished.connect(func() -> void:
		label.queue_free()
	)

func _floating_label(text: String, font_size: int, color: Color, pos: Vector2, box: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("#000000dd"))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.position = pos
	label.size = box
	label.modulate.a = 0.0
	return label

func _plate_bg(pos: Vector2, box: Vector2, fill: Color, edge: Color) -> Control:
	var background := ResultTrayBackplate.new()
	background.tint = Color(edge, 0.72)
	background.position = pos
	background.size = box
	background.modulate.a = 0.0
	return background

func _add_behind(background: CanvasItem, label: CanvasItem) -> void:
	add_child(label)
	add_child(background)
	move_child(background, label.get_index())

func _format_multiplier(value: float) -> String:
	var snapped_value: float = snapped(value, 0.01)
	if is_equal_approx(snapped_value, round(snapped_value)):
		return str(int(round(snapped_value)))
	return str(snapped_value)
