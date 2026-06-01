class_name DiceRollLayer2D
extends Control

signal roll_finished(value: int)

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const INK := Color("#120d08")
const SHADOW := Color("#030201")

const DEFAULT_TRAY_RECT := Rect2(Vector2(174, 438), Vector2(318, 178))
const DIE_SIZE := Vector2(74, 74)
const MIN_ROLL_TIME := 0.82
const MAX_ROLL_TIME := 1.12
const KEEP_RESULT_TIME := 0.72

var rng := RandomNumberGenerator.new()
var tray_rect := DEFAULT_TRAY_RECT
var roll_theme := "combat"
var rolling := false
var result_live := false
var roll_elapsed := 0.0
var result_elapsed := 0.0
var roll_frames := 0
var result_frames := 0
var roll_duration := 0.82
var result_value := 1
var previous_value := 0
var display_value := 1
var frame_index := 0
var die_pos := Vector2.ZERO
var die_rotation := 0.0
var die_scale := Vector2.ONE
var result_label := ""
var draw_tray_image := true
var draw_result_receipt := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.randomize()
	visible = false
	set_process(true)

func configure(payload: Dictionary = {}) -> void:
	tray_rect = payload.get("tray_rect", tray_rect)
	roll_theme = str(payload.get("theme", roll_theme))
	result_label = str(payload.get("result_label", result_label))
	draw_tray_image = bool(payload.get("draw_tray", draw_tray_image))
	draw_result_receipt = bool(payload.get("draw_result_receipt", draw_result_receipt))
	if payload.has("seed"):
		rng.seed = int(payload.get("seed", 1))
	queue_redraw()

func roll(options: Dictionary = {}) -> void:
	if rolling:
		return
	if options.has("tray_rect") or options.has("theme") or options.has("result_label") or options.has("seed"):
		configure(options)
	previous_value = int(options.get("previous_value", previous_value))
	result_value = _resolve_result_value(options)
	display_value = rng.randi_range(1, 6)
	if display_value == result_value:
		display_value = wrapi(display_value + rng.randi_range(1, 5), 1, 7)
	roll_duration = rng.randf_range(MIN_ROLL_TIME, MAX_ROLL_TIME)
	roll_elapsed = 0.0
	result_elapsed = 0.0
	roll_frames = 0
	result_frames = 0
	frame_index = 0
	die_pos = _tray_center() + Vector2(rng.randf_range(-44.0, 30.0), rng.randf_range(-22.0, 16.0))
	die_rotation = rng.randf_range(-0.38, 0.38)
	die_scale = Vector2.ONE
	rolling = true
	result_live = false
	visible = true
	modulate.a = 1.0
	queue_redraw()

func is_rolling() -> bool:
	return rolling

func _process(delta: float) -> void:
	if rolling:
		roll_elapsed += delta
		roll_frames += 1
		_update_roll_visuals()
		if roll_elapsed >= roll_duration or roll_frames >= 54:
			_finish_roll()
	if result_live:
		result_elapsed += delta
		result_frames += 1
		if result_elapsed >= KEEP_RESULT_TIME or result_frames >= 42:
			result_live = false
			visible = false
	if rolling or result_live:
		queue_redraw()

func _draw() -> void:
	if not visible:
		return
	if draw_tray_image:
		_draw_tray()
	_draw_die()
	if result_live and draw_result_receipt:
		_draw_result_receipt()

func _resolve_result_value(options: Dictionary) -> int:
	var forced := int(options.get("forced_value", 0))
	var value := forced if forced >= 1 and forced <= 6 else rng.randi_range(1, 6)
	if bool(options.get("avoid_previous", false)) and previous_value >= 1 and previous_value <= 6 and value == previous_value:
		value = wrapi(value + rng.randi_range(1, 5), 1, 7)
	return clampi(value, 1, 6)

func _update_roll_visuals() -> void:
	var t: float = clampf(roll_elapsed / max(0.001, roll_duration), 0.0, 1.0)
	var settle := _ease_out_cubic(t)
	var inner := _inner_rect()
	var path_x := lerpf(inner.position.x + inner.size.x * 0.16, inner.position.x + inner.size.x * 0.64, settle)
	var path_y := inner.position.y + inner.size.y * (0.45 + 0.24 * sin(t * TAU * 2.25))
	var jitter := Vector2(
		sin(float(Time.get_ticks_msec()) * 0.056) * (15.0 * (1.0 - t)),
		cos(float(Time.get_ticks_msec()) * 0.064) * (10.0 * (1.0 - t))
	)
	die_pos = _clamped_die_pos(Vector2(path_x, path_y) + jitter)
	die_rotation = lerpf(0.0, TAU * 3.2 + rng.randf_range(-0.18, 0.18), t) + sin(float(Time.get_ticks_msec()) * 0.041) * 0.24 * (1.0 - t)
	var squash := sin(t * PI * 7.0) * 0.12 * (1.0 - t)
	die_scale = Vector2(1.0 + squash, 1.0 - squash * 0.65)
	frame_index += 1
	if t < 0.86:
		display_value = 1 + posmod(frame_index + int(floor(roll_elapsed * 24.0)), 6)
	elif frame_index % 2 == 0:
		display_value = rng.randi_range(1, 6)

func _finish_roll() -> void:
	if not rolling:
		return
	rolling = false
	result_live = true
	result_elapsed = 0.0
	result_frames = 0
	display_value = result_value
	die_pos = _clamped_die_pos(_tray_center() + Vector2(34.0, 8.0))
	die_rotation = rng.randf_range(-0.10, 0.10)
	die_scale = Vector2.ONE
	previous_value = result_value
	roll_finished.emit(result_value)
	queue_redraw()

func _draw_tray() -> void:
	draw_rect(tray_rect.grow(16.0), Color(SHADOW, 0.20), true)
	var tray_texture := AssetCatalog.combat_runtime_texture("dice_tray")
	if tray_texture != null:
		draw_texture_rect(tray_texture, tray_rect.grow(18.0), false, Color(1, 1, 1, 0.88))
	else:
		draw_rect(tray_rect, Color("#17100a", 0.74), true)
		draw_rect(tray_rect, Color(GOLD, 0.38), false, 2.0)
	if rolling:
		var pulse := 0.45 + sin(float(Time.get_ticks_msec()) * 0.026) * 0.18
		draw_rect(tray_rect.grow(7.0), Color(GOLD, pulse * 0.18), false, 3.0)

func _draw_die() -> void:
	if rolling:
		_draw_motion_echoes()
	var texture := AssetCatalog.dice_face(display_value)
	var shadow_rect := Rect2(die_pos - DIE_SIZE * 0.5 + Vector2(8, 12), DIE_SIZE)
	draw_set_transform(shadow_rect.get_center(), die_rotation, die_scale)
	draw_rect(Rect2(-DIE_SIZE * 0.5, DIE_SIZE), Color(SHADOW, 0.30), true)
	draw_set_transform(die_pos, die_rotation, die_scale)
	if texture != null:
		draw_texture_rect(texture, Rect2(-DIE_SIZE * 0.5, DIE_SIZE), false, Color(1, 1, 1, 0.96))
	else:
		_draw_fallback_die(display_value)
	if rolling:
		draw_rect(Rect2(-DIE_SIZE * 0.5, DIE_SIZE), Color(GOLD, 0.18), false, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_motion_echoes() -> void:
	var echo_alpha := 0.18 + 0.08 * sin(float(Time.get_ticks_msec()) * 0.035)
	for i in range(2):
		var echo_value := 1 + posmod(display_value + i + 2, 6)
		var echo_texture := AssetCatalog.dice_face(echo_value)
		if echo_texture == null:
			continue
		var offset := Vector2(-18.0 + float(i) * 34.0, 10.0 - float(i) * 16.0)
		var echo_pos := _clamped_die_pos(die_pos + offset)
		var echo_rot := die_rotation - 0.36 + float(i) * 0.42
		draw_set_transform(echo_pos, echo_rot, Vector2(0.86, 0.86))
		draw_texture_rect(echo_texture, Rect2(-DIE_SIZE * 0.5, DIE_SIZE), false, Color(1, 1, 1, echo_alpha * (1.0 - float(i) * 0.28)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_fallback_die(value: int) -> void:
	draw_rect(Rect2(-DIE_SIZE * 0.5, DIE_SIZE), Color("#f4eadc"), true)
	draw_rect(Rect2(-DIE_SIZE * 0.5, DIE_SIZE), Color("#2a303b", 0.52), false, 2.0)
	var pip_sets: Dictionary = {
		1: [Vector2(0, 0)],
		2: [Vector2(-20, -20), Vector2(20, 20)],
		3: [Vector2(-20, -20), Vector2(0, 0), Vector2(20, 20)],
		4: [Vector2(-20, -20), Vector2(20, -20), Vector2(-20, 20), Vector2(20, 20)],
		5: [Vector2(-20, -20), Vector2(20, -20), Vector2(0, 0), Vector2(-20, 20), Vector2(20, 20)],
		6: [Vector2(-20, -24), Vector2(20, -24), Vector2(-20, 0), Vector2(20, 0), Vector2(-20, 24), Vector2(20, 24)]
	}
	for point in pip_sets.get(value, [Vector2.ZERO]):
		draw_circle(point, 5.5, INK)

func _draw_result_receipt() -> void:
	var receipt := Rect2(tray_rect.position + Vector2(tray_rect.size.x - 154.0, 18.0), Vector2(128, 48))
	draw_rect(receipt, Color("#d6b982", 0.82), true)
	draw_rect(receipt, Color(GOLD, 0.62), false, 2.0)
	var label := result_label
	if label == "":
		label = UiText.t("battle.layer.die_pips", {"value": result_value})
	draw_string(ThemeDB.fallback_font, receipt.position + Vector2(14, 30), label, HORIZONTAL_ALIGNMENT_LEFT, receipt.size.x - 22.0, 18, INK)

func _inner_rect() -> Rect2:
	return tray_rect.grow(-46.0)

func _tray_center() -> Vector2:
	return tray_rect.position + tray_rect.size * 0.5

func _clamped_die_pos(pos: Vector2) -> Vector2:
	var inner := _inner_rect()
	var margin := DIE_SIZE.x * 0.5
	return Vector2(
		clampf(pos.x, inner.position.x + margin, inner.end.x - margin),
		clampf(pos.y, inner.position.y + margin, inner.end.y - margin)
	)

func _ease_out_cubic(t: float) -> float:
	var inv := 1.0 - clampf(t, 0.0, 1.0)
	return 1.0 - inv * inv * inv
