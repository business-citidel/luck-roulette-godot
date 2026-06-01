class_name RewardChoiceObjectNode
extends "res://scripts/ui/interactive_object_button.gd"

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RunChoice := preload("res://scripts/run/run_choice.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")

const INK := Color("#090704")
const GOLD := Color("#f2be4b")
const GREEN := Color("#65d48e")
const MUTED := Color("#aab4c3")

var choice_id := ""
var choice_data: Dictionary = {}
var visual_state := RunChoice.STATE_NORMAL

func configure_choice(choice: Dictionary, input_rect: Rect2) -> void:
	choice_data = choice.duplicate(true)
	choice_id = str(choice.get("id", ""))
	visual_state = str(choice.get("state", RunChoice.STATE_NORMAL))
	setup_object_button(input_rect)
	name = "RunChoice_" + choice_id
	tooltip_text = str(choice.get("label", choice_id)) + "\n" + str(choice.get("effect", ""))
	disabled = not RunChoice.is_interactive(choice)
	queue_redraw()

func set_choice(choice: Dictionary) -> void:
	choice_data = choice.duplicate(true)
	visual_state = str(choice.get("state", RunChoice.STATE_NORMAL))
	disabled = not RunChoice.is_interactive(choice)
	tween_visual_to(Vector2.ZERO, Vector2.ONE, 0.12)
	queue_redraw()

func _ready() -> void:
	apply_transparent_object_style()
	mouse_entered.connect(func() -> void: set_hovered(true))
	mouse_exited.connect(func() -> void: set_hovered(false))

func set_hovered(value: bool) -> void:
	if disabled or visual_state == RunChoice.STATE_DISABLED or visual_state == RunChoice.STATE_CHOSEN:
		return
	if value:
		visual_state = RunChoice.STATE_HOVER
		z_index = 20
		tween_visual_to(Vector2(0, -10), Vector2(1.035, 1.035), 0.12)
	else:
		visual_state = str(choice_data.get("state", RunChoice.STATE_NORMAL))
		z_index = 1
		tween_visual_to(Vector2.ZERO, Vector2.ONE, 0.12)
	queue_redraw()

func _draw() -> void:
	var rect := visual_rect(Rect2(Vector2.ZERO, size))
	var state := visual_state
	if _is_board_slot():
		_draw_board_slot(rect, state)
		return
	if state == RunChoice.STATE_HOVER:
		draw_rect(rect.grow(10.0), Color(GOLD, 0.16), true)
		draw_rect(rect.grow(10.0), Color(GOLD, 0.74), false, 3.0)
	elif state == RunChoice.STATE_CHOSEN:
		draw_rect(rect.grow(10.0), Color(GREEN, 0.16), true)
		draw_rect(rect.grow(10.0), Color(GREEN, 0.74), false, 3.0)
	UiSkin.draw_offer_card(self, rect, state)
	_draw_choice_text(rect)
	_draw_choice_object(rect)

func _is_board_slot() -> bool:
	return str(choice_data.get("visual_style", "")) == "reward_board_slot"

func _draw_board_slot(rect: Rect2, state: String) -> void:
	if state == RunChoice.STATE_HOVER:
		draw_rect(rect.grow(6.0), Color(GOLD, 0.14), true)
		draw_rect(rect.grow(6.0), Color(GOLD, 0.78), false, 2.0)
	elif state == RunChoice.STATE_CHOSEN:
		draw_rect(rect.grow(6.0), Color(GREEN, 0.16), true)
		draw_rect(rect.grow(6.0), Color(GREEN, 0.78), false, 2.0)
	elif state == RunChoice.STATE_DISABLED:
		draw_rect(rect, Color("#050403", 0.26), true)
	var title_plate := Rect2(rect.position + Vector2(16, 12), Vector2(rect.size.x - 32, 52))
	draw_rect(title_plate, Color("#f0d7a5", 0.78), true)
	draw_rect(title_plate, Color("#4f3117", 0.34), false, 1.0)
	_draw_text(str(choice_data.get("label", "")), title_plate.position + Vector2(12, 24), 15, INK, title_plate.size.x - 24)
	_draw_text(str(choice_data.get("effect", "")), title_plate.position + Vector2(12, 43), 11, Color("#70490f", 0.86), title_plate.size.x - 24)
	var object_rect := Rect2(rect.position + Vector2((rect.size.x - 104.0) * 0.5, 78.0), Vector2(104, 104))
	_draw_choice_object_at(object_rect)
	var note_plate := Rect2(rect.position + Vector2(18, rect.size.y - 48), Vector2(rect.size.x - 36, 34))
	draw_rect(note_plate, Color("#07160d", 0.30), true)
	draw_rect(note_plate, Color("#d7aa4c", 0.22), false, 1.0)
	_draw_text(str(choice_data.get("note", "")), note_plate.position + Vector2(10, 22), 10, Color("#f4dfb6", 0.86), note_plate.size.x - 20)

func _draw_choice_text(rect: Rect2) -> void:
	var text_width := rect.size.x - 112.0
	_draw_text(str(choice_data.get("label", "")), rect.position + Vector2(26, 30), 16, INK, text_width)
	_draw_text(str(choice_data.get("note", "")), rect.position + Vector2(26, 56), 12, Color(INK, 0.58), text_width)
	_draw_text(str(choice_data.get("effect", "")), rect.position + Vector2(26, 82), 14, Color("#70490f", 0.84), text_width)

func _draw_choice_object(rect: Rect2) -> void:
	match choice_id:
		"money":
			_draw_money_object(Rect2(rect.position + Vector2(rect.size.x - 88.0, 42.0), Vector2(58, 58)))
		"heal":
			_draw_heal_object(Rect2(rect.position + Vector2(rect.size.x - 94.0, 32.0), Vector2(72, 72)))
		_:
			_draw_relic_object(rect)

func _draw_choice_object_at(object_rect: Rect2) -> void:
	match choice_id:
		"money":
			_draw_money_object(object_rect)
		"heal":
			_draw_heal_object(object_rect)
		_:
			_draw_relic_object_at(object_rect)

func _draw_money_object(object_rect: Rect2) -> void:
	var coin_texture := AssetCatalog.shop_runtime_texture("coin_stack")
	if coin_texture != null:
		draw_texture_rect(coin_texture, object_rect, false, Color(1, 1, 1, 0.90))
	else:
		UiSkin.draw_coin_marker(self, object_rect.get_center(), min(object_rect.size.x, object_rect.size.y) * 0.34, Color(GOLD, 0.88))

func _draw_heal_object(object_rect: Rect2) -> void:
	var vial_texture := AssetCatalog.consumable_texture("red_vial_object")
	if vial_texture != null:
		draw_texture_rect(vial_texture, object_rect, false, Color(1, 1, 1, 0.90))
	else:
		draw_circle(object_rect.get_center(), min(object_rect.size.x, object_rect.size.y) * 0.34, Color("#bb2e36", 0.82))

func _draw_relic_object(rect: Rect2) -> void:
	var result_value: Variant = choice_data.get("result", {})
	if not result_value is Dictionary:
		return
	var relic_ids: Array = (result_value as Dictionary).get("relic_ids", [])
	if relic_ids.is_empty():
		return
	var relic_id := str(relic_ids[0])
	var texture := AssetCatalog.relic_object(RelicCatalog.icon_id(relic_id))
	if texture != null:
		draw_texture_rect(texture, Rect2(rect.position + Vector2(rect.size.x - 104.0, 30.0), Vector2(78, 78)), false, Color(1, 1, 1, 0.9))

func _draw_relic_object_at(object_rect: Rect2) -> void:
	var result_value: Variant = choice_data.get("result", {})
	if not result_value is Dictionary:
		return
	var relic_ids: Array = (result_value as Dictionary).get("relic_ids", [])
	if relic_ids.is_empty():
		return
	var relic_id := str(relic_ids[0])
	var texture := AssetCatalog.relic_object(RelicCatalog.icon_id(relic_id))
	if texture != null:
		draw_texture_rect(texture, object_rect, false, Color(1, 1, 1, 0.92))

func _draw_text(value: String, pos: Vector2, font_size: int, color: Color, width: float = -1.0) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)
