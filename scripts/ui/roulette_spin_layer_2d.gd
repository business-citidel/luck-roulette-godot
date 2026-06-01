class_name RouletteSpinLayer2D
extends Control

signal spin_finished(slot_id: String)

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const RouletteResolver := preload("res://scripts/systems/roulette_resolver.gd")
const RouletteSlotCatalog := preload("res://scripts/systems/roulette_slot_catalog.gd")

const TEXT := Color("#f6efe2")
const GOLD := Color("#f2be4b")
const INK := Color("#120d08")
const SHADOW := Color("#030201")

const DEFAULT_CENTER := Vector2(640, 330)
const DEFAULT_WHEEL_SIZE := Vector2(360, 360)
const MIN_SPIN_TIME := 1.05
const MAX_SPIN_TIME := 1.32
const KEEP_RESULT_TIME := 0.62

var rng := RandomNumberGenerator.new()
var wheel_center := DEFAULT_CENTER
var wheel_size := DEFAULT_WHEEL_SIZE
var wheel_angle := 0.0
var target_angle := 0.0
var start_angle := 0.0
var spin_duration := MIN_SPIN_TIME
var spin_elapsed := 0.0
var spin_frames := 0
var result_elapsed := 0.0
var spinning := false
var result_live := false
var result_slot := ""
var draw_result_badge := true
var wheel_texture_source := "combat"
var wheel_texture_id := "roulette_wheel"
var pointer_texture_source := "combat"
var pointer_texture_id := "roulette_pointer"
var placed_slots: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.randomize()
	visible = false
	set_process(true)

func configure(payload: Dictionary = {}) -> void:
	wheel_center = payload.get("wheel_center", wheel_center)
	wheel_size = payload.get("wheel_size", wheel_size)
	draw_result_badge = bool(payload.get("draw_result_badge", draw_result_badge))
	wheel_texture_source = str(payload.get("wheel_texture_source", wheel_texture_source))
	wheel_texture_id = str(payload.get("wheel_texture_id", wheel_texture_id))
	pointer_texture_source = str(payload.get("pointer_texture_source", pointer_texture_source))
	pointer_texture_id = str(payload.get("pointer_texture_id", pointer_texture_id))
	placed_slots = payload.get("placed_slots", placed_slots).duplicate(true)
	if payload.has("seed"):
		rng.seed = int(payload.get("seed", 1))
	queue_redraw()

func spin(options: Dictionary = {}) -> void:
	if spinning:
		return
	if options.has("wheel_center") or options.has("wheel_size") or options.has("draw_result_badge") or options.has("seed") or options.has("wheel_texture_id") or options.has("pointer_texture_id"):
		configure(options)
	placed_slots = options.get("placed_slots", placed_slots).duplicate(true)
	result_slot = _resolve_result_slot(options)
	start_angle = wheel_angle
	var index := RouletteSlotCatalog.index(result_slot)
	var slot_angle := float(index) * 72.0
	target_angle = start_angle + 1080.0 + 360.0 - slot_angle + rng.randf_range(-7.0, 7.0)
	spin_duration = rng.randf_range(MIN_SPIN_TIME, MAX_SPIN_TIME)
	spin_elapsed = 0.0
	spin_frames = 0
	result_elapsed = 0.0
	spinning = true
	result_live = false
	visible = true
	queue_redraw()

func is_spinning() -> bool:
	return spinning

func _process(delta: float) -> void:
	if spinning:
		spin_elapsed += delta
		spin_frames += 1
		var t: float = clampf(spin_elapsed / max(0.001, spin_duration), 0.0, 1.0)
		wheel_angle = lerpf(start_angle, target_angle, _ease_out_cubic(t))
		if t >= 1.0 or spin_frames >= 86:
			_finish_spin()
	if result_live:
		result_elapsed += delta
		if result_elapsed >= KEEP_RESULT_TIME:
			result_live = false
	if spinning or result_live:
		queue_redraw()

func _draw() -> void:
	if not visible:
		return
	_draw_wheel()
	_draw_pointer()
	if result_live and draw_result_badge:
		_draw_result_badge()

func _resolve_result_slot(options: Dictionary) -> String:
	var forced := str(options.get("forced_slot", ""))
	if RouletteSlotCatalog.has_slot(forced):
		return forced
	return RouletteResolver.weighted_pick(placed_slots, rng)

func _finish_spin() -> void:
	if not spinning:
		return
	spinning = false
	result_live = true
	wheel_angle = target_angle
	spin_finished.emit(result_slot)
	queue_redraw()

func _draw_wheel() -> void:
	var texture := _roulette_texture(wheel_texture_source, wheel_texture_id)
	var shadow_rect := Rect2(wheel_center - wheel_size * 0.5 + Vector2(16, 24), wheel_size)
	if texture != null:
		draw_texture_rect(texture, shadow_rect, false, Color(0, 0, 0, 0.36))
	else:
		draw_circle(wheel_center + Vector2(16, 24), wheel_size.x * 0.48, Color(SHADOW, 0.32))
	draw_set_transform(wheel_center, deg_to_rad(wheel_angle), Vector2.ONE)
	if texture != null:
		draw_texture_rect(texture, Rect2(-wheel_size * 0.5, wheel_size), false, Color(1, 1, 1, 0.98))
	else:
		_draw_fallback_wheel()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_pointer() -> void:
	var texture := _roulette_texture(pointer_texture_source, pointer_texture_id)
	var target := Vector2(52, 138)
	var top_center := wheel_center + Vector2(0, -wheel_size.y * 0.52)
	if texture != null:
		draw_texture_rect(texture, Rect2(top_center - Vector2(target.x * 0.5, target.y * 0.12), target), false, Color(1, 1, 1, 0.96))
	else:
		draw_polygon(PackedVector2Array([
			wheel_center + Vector2(0, -wheel_size.y * 0.48),
			wheel_center + Vector2(-18, -wheel_size.y * 0.64),
			wheel_center + Vector2(18, -wheel_size.y * 0.64)
		]), PackedColorArray([GOLD, GOLD, GOLD]))

func _draw_result_badge() -> void:
	var label := RouletteSlotCatalog.label(result_slot)
	var rect := Rect2(wheel_center + Vector2(-88, wheel_size.y * 0.42), Vector2(176, 46))
	draw_rect(rect, Color("#d6b982", 0.84), true)
	draw_rect(rect, Color(GOLD, 0.70), false, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(18, 30), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 36.0, 18, INK)

func _draw_fallback_wheel() -> void:
	var radius := wheel_size.x * 0.48
	for i in range(RouletteSlotCatalog.slot_ids().size()):
		var slot_id := RouletteSlotCatalog.slot_ids()[i]
		var start_angle := deg_to_rad(float(i) * 72.0 - 126.0)
		var end_angle := deg_to_rad(float(i + 1) * 72.0 - 126.0)
		_sector(Vector2.ZERO, radius, start_angle, end_angle, RouletteSlotCatalog.color(slot_id))
	draw_circle(Vector2.ZERO, radius * 0.35, Color("#15100b"))
	draw_circle(Vector2.ZERO, radius * 0.15, GOLD)

func _roulette_texture(source: String, texture_id: String) -> Texture2D:
	if source == "event":
		return AssetCatalog.event_prop_texture(texture_id)
	return AssetCatalog.combat_runtime_texture(texture_id)

func _sector(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	points.append(center)
	colors.append(color)
	for i in range(20):
		var t := float(i) / 19.0
		var angle := lerpf(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		colors.append(color)
	draw_polygon(points, colors)

func _ease_out_cubic(t: float) -> float:
	var inv := 1.0 - clampf(t, 0.0, 1.0)
	return 1.0 - inv * inv * inv
