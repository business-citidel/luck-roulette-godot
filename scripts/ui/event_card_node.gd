class_name EventCardNode
extends "res://scripts/ui/interactive_object_button.gd"

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")

const INK := Color("#090704")
const GOLD := Color("#f2be4b")
const GREEN := Color("#65d48e")

var card_id := ""
var card_label := ""
var card_effect := ""
var token_color := GOLD
var base_position := Vector2.ZERO
var is_hovered := false
var is_revealed := false
var is_dimmed := false
var is_selected := false
var flip_scale := 1.0:
	set(value):
		flip_scale = value
		queue_redraw()

func configure(card: Dictionary) -> void:
	card_id = str(card.get("id", ""))
	card_label = str(card.get("label", ""))
	card_effect = str(card.get("effect", ""))
	var incoming_color = card.get("token_color", GOLD)
	if incoming_color is Color:
		token_color = incoming_color
	tooltip_text = card_label + "\n" + card_effect
	queue_redraw()

func set_card_rect(rect: Rect2) -> void:
	base_position = rect.position
	setup_object_button(rect)
	flip_scale = 1.0

func _ready() -> void:
	apply_transparent_object_style()
	mouse_entered.connect(func() -> void: set_hovered(true))
	mouse_exited.connect(func() -> void: set_hovered(false))

func set_hovered(value: bool) -> void:
	if is_revealed or is_dimmed or disabled:
		return
	is_hovered = value
	z_index = 24 if is_hovered else 1
	tween_visual_to(Vector2(0, -20) if is_hovered else Vector2.ZERO, Vector2(1.055, 1.055) if is_hovered else Vector2.ONE, 0.13)
	queue_redraw()

func set_dimmed(value: bool) -> void:
	is_dimmed = value
	is_hovered = false
	disabled = value
	if is_dimmed:
		z_index = 0
		tween_visual_to(Vector2(0, 6), Vector2(0.96, 0.96), 0.14)
	else:
		z_index = 1
		tween_visual_to(Vector2.ZERO, Vector2.ONE, 0.12)
	queue_redraw()

func reveal_selected() -> void:
	if is_revealed:
		return
	is_selected = true
	is_dimmed = false
	disabled = true
	z_index = 40
	tween_visual_to(Vector2(0, -30), Vector2(1.09, 1.09), 0.12)
	await get_tree().create_timer(0.12).timeout
	kill_visual_tween()
	object_motion_tween = create_tween()
	object_motion_tween.tween_property(self, "flip_scale", 0.08, 0.11).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await object_motion_tween.finished
	is_revealed = true
	queue_redraw()
	object_motion_tween = create_tween()
	object_motion_tween.tween_property(self, "flip_scale", 1.0, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await object_motion_tween.finished

func _draw() -> void:
	var rect := visual_rect(Rect2(Vector2.ZERO, size), flip_scale)
	if rect.size == Vector2.ZERO:
		return
	var shadow_alpha := 0.32 if is_hovered or is_selected else 0.22
	draw_rect(Rect2(rect.grow(8.0).position + Vector2(6, 9), rect.grow(8.0).size), Color("#020201", shadow_alpha), true)
	if is_hovered and not is_revealed:
		draw_rect(rect.grow(10.0), Color(GOLD, 0.17), true)
		draw_rect(rect.grow(10.0), Color(GOLD, 0.78), false, 3.0)
	if is_selected:
		draw_rect(rect.grow(12.0), Color(GREEN, 0.18), true)
		draw_rect(rect.grow(12.0), Color(GREEN, 0.76), false, 4.0)
	if is_revealed:
		_draw_front(rect)
	else:
		_draw_back(rect)
	if is_dimmed:
		draw_rect(rect, Color("#020202", 0.48), true)

func _draw_back(rect: Rect2) -> void:
	var texture := AssetCatalog.event_prop_texture("card_back")
	var tint := Color(1, 1, 1, 0.55) if is_dimmed else Color(1, 1, 1, 0.98)
	if texture != null:
		draw_texture_rect(texture, rect, false, tint)
	else:
		draw_rect(rect, Color("#171009", 0.96) * tint, true)
		draw_rect(rect.grow(-12.0), Color("#8d622b", 0.58) * tint, false, 2.0)

func _draw_front(rect: Rect2) -> void:
	var texture := AssetCatalog.event_prop_texture("card_front")
	if texture != null:
		draw_texture_rect(texture, rect, false, Color(1, 1, 1, 0.99))
	else:
		draw_rect(rect, Color("#ead4a0", 0.98), true)
		draw_rect(rect.grow(-12.0), Color("#70490f", 0.44), false, 2.0)
	draw_circle(rect.position + Vector2(rect.size.x * 0.5, 54), 21.0, Color(token_color, 0.74))
	draw_string(ThemeDB.fallback_font, Vector2(14, 104), card_label, HORIZONTAL_ALIGNMENT_CENTER, size.x - 28.0, 17, INK)
	draw_string(ThemeDB.fallback_font, Vector2(14, 142), card_effect, HORIZONTAL_ALIGNMENT_CENTER, size.x - 28.0, 13, Color("#70490f", 0.92))
