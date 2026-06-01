class_name EventBaseChoiceObjectNode
extends "res://scripts/ui/interactive_object_button.gd"

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RunChoice := preload("res://scripts/run/run_choice.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")

const INK := Color("#090704")
const GOLD := Color("#f2be4b")
const GREEN := Color("#65d48e")
const RED := Color("#ee5b5b")
const MUTED := Color("#aab4c3")

var choice_id := ""
var choice_data: Dictionary = {}
var event_id := ""
var visual_state := RunChoice.STATE_NORMAL

func configure_choice(choice: Dictionary, input_rect: Rect2, source_event_id: String) -> void:
	choice_data = choice.duplicate(true)
	choice_id = str(choice.get("id", ""))
	event_id = source_event_id
	visual_state = str(choice.get("state", RunChoice.STATE_NORMAL))
	setup_object_button(input_rect)
	name = "RunChoice_" + choice_id
	tooltip_text = str(choice.get("label", choice_id)) + "\n" + str(choice.get("effect", ""))
	disabled = not RunChoice.is_interactive(choice)
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
	_draw_choice_paper(rect)
	_draw_state(rect)
	if not _uses_design_slip():
		_draw_icon(rect)
	_draw_labels(rect)

func _draw_choice_paper(rect: Rect2) -> void:
	var slip := AssetCatalog.event_slip_texture(_choice_slip_texture_id())
	if slip != null:
		var tint := Color(1, 1, 1, 0.98)
		if disabled or visual_state == RunChoice.STATE_DISABLED:
			tint = Color(0.72, 0.72, 0.72, 0.72)
		draw_rect(Rect2(rect.position + Vector2(8, 12), rect.size), Color("#020201", 0.30), true)
		draw_texture_rect(slip, rect, false, tint)
		return
	draw_rect(Rect2(rect.position + Vector2(6, 10), rect.size), Color("#020201", 0.26), true)
	var tint := Color(1, 1, 1, 0.94)
	if disabled or visual_state == RunChoice.STATE_DISABLED:
		tint = Color(0.64, 0.64, 0.64, 0.56)
	UiSkin.draw_parchment_card(self, rect, "small", tint)
	draw_rect(rect.grow(-12.0), Color("#f1d79c", 0.18) * tint, true)
	draw_rect(rect.grow(-12.0), Color("#5b3618", 0.24) * tint, false, 1.0)
	draw_line(rect.position + Vector2(26.0, 120.0), Vector2(rect.end.x - 26.0, rect.position.y + 120.0), Color("#5b3618", 0.22) * tint, 1.0)
	_draw_choice_ribbon(rect, tint)

func _draw_choice_ribbon(rect: Rect2, tint: Color) -> void:
	var color := _accent_color()
	var ribbon := Rect2(rect.position + Vector2(22.0, 14.0), Vector2(48.0, 88.0))
	draw_rect(ribbon, Color("#172814", 0.88) * tint, true)
	if color == RED:
		draw_rect(ribbon, Color("#66211c", 0.82) * tint, true)
	elif color == MUTED:
		draw_rect(ribbon, Color("#1b1b1d", 0.72) * tint, true)
	draw_polygon(PackedVector2Array([
		ribbon.position + Vector2(0, ribbon.size.y),
		ribbon.position + Vector2(ribbon.size.x * 0.5, ribbon.size.y - 16.0),
		ribbon.position + Vector2(ribbon.size.x, ribbon.size.y)
	]), PackedColorArray([Color("#020201", 0.18), Color("#020201", 0.18), Color("#020201", 0.18)]))
	draw_rect(ribbon, Color("#dbb766", 0.32) * tint, false, 1.0)
	UiSkin.draw_state_token(self, ribbon.position + Vector2(ribbon.size.x * 0.5, 29.0), "sealed" if color == RED else "current", 15.0, Color(color, 0.90))

func _uses_design_slip() -> bool:
	return AssetCatalog.event_slip_texture(_choice_slip_texture_id()) != null

func _choice_slip_texture_id() -> String:
	if disabled or visual_state == RunChoice.STATE_DISABLED:
		return "choice_card_disabled"
	var icon_kind := str(choice_data.get("icon_kind", ""))
	if icon_kind == "blood" or icon_kind == "danger" or _choice_has_risk_language():
		return "choice_card_blood_risk"
	if _choice_is_refuse():
		return "choice_card_refuse"
	if _choice_has_cost_language():
		return "choice_card_cost_reward"
	return "choice_card_gain_hover"

func _choice_has_risk_language() -> bool:
	var haystack := (choice_id + " " + str(choice_data.get("label", "")) + " " + str(choice_data.get("note", "")) + " " + str(choice_data.get("effect", ""))).to_lower()
	return haystack.contains("risk") or haystack.contains("risky") or haystack.contains("blood") or haystack.contains("위험") or haystack.contains("피해")

func _choice_is_refuse() -> bool:
	var haystack := (choice_id + " " + str(choice_data.get("label", "")) + " " + str(choice_data.get("note", ""))).to_lower()
	return haystack.contains("leave") or haystack.contains("refuse") or haystack.contains("decline") or haystack.contains("떠난") or haystack.contains("거절")

func _choice_has_cost_language() -> bool:
	var haystack := (str(choice_data.get("note", "")) + " " + str(choice_data.get("effect", ""))).to_lower()
	return haystack.contains("-") or haystack.contains("hp를 내고") or haystack.contains("비용")

func _accent_color() -> Color:
	var icon_kind := str(choice_data.get("icon_kind", ""))
	if visual_state == RunChoice.STATE_DISABLED or disabled:
		return MUTED
	if icon_kind == "blood" or icon_kind == "danger":
		return RED
	if icon_kind == "heal" or icon_kind == "relic":
		return GREEN
	return GOLD

func _draw_state(rect: Rect2) -> void:
	if visual_state == RunChoice.STATE_HOVER:
		draw_rect(rect.grow(7.0), Color(GOLD, 0.11), true)
		draw_rect(rect.grow(7.0), Color(GOLD, 0.62), false, 2.0)
	elif visual_state == RunChoice.STATE_CHOSEN:
		draw_rect(rect.grow(7.0), Color(GREEN, 0.13), true)
		draw_rect(rect.grow(7.0), Color(GREEN, 0.62), false, 2.0)
	elif visual_state == RunChoice.STATE_DISABLED:
		draw_rect(rect, Color("#050403", 0.28), true)

func _draw_icon(rect: Rect2) -> void:
	var icon_rect := Rect2(rect.position + Vector2(30, rect.size.y - 54), Vector2(30, 30))
	var icon_kind := str(choice_data.get("icon_kind", ""))
	if icon_kind != "":
		_draw_icon_kind(icon_kind, icon_rect)
		return
	match choice_id:
		"backroom_die_roll", "backroom_die_cheat", "dice_roll_now":
			var dice := AssetCatalog.dice_face(5)
			if dice != null:
				draw_texture_rect(dice, icon_rect, false, Color(1, 1, 1, 0.78))
			else:
				draw_circle(icon_rect.get_center(), 18.0, Color(GOLD, 0.60))
		"crooked_wheel_small", "crooked_wheel_risky", "roulette_spin_now":
			var wheel := AssetCatalog.event_prop_texture("roulette_medallion")
			if wheel != null:
				draw_texture_rect(wheel, icon_rect.grow(4.0), false, Color(1, 1, 1, 0.72))
			else:
				draw_circle(icon_rect.get_center(), 18.0, Color("#24170d", 0.76))
				draw_arc(icon_rect.get_center(), 18.0, -PI * 0.2, PI * 1.3, 24, GOLD, 2.0)
		"sealed_cards_draw", "sealed_cards_peek":
			var card_back := AssetCatalog.event_prop_texture("card_back")
			if card_back != null:
				draw_texture_rect(card_back, Rect2(icon_rect.position + Vector2(8, -8), Vector2(28, 48)), false, Color(1, 1, 1, 0.76))
			else:
				UiSkin.draw_parchment_card(self, Rect2(icon_rect.position + Vector2(8, -8), Vector2(28, 48)), "small", Color(1, 1, 1, 0.76))
		"event_relic_trade":
			var result_value: Variant = choice_data.get("result", {})
			var relic_id := ""
			if result_value is Dictionary:
				var relics: Array = (result_value as Dictionary).get("relic_ids", [])
				if not relics.is_empty():
					relic_id = str(relics[0])
			var relic := AssetCatalog.relic_object(RelicCatalog.icon_id(relic_id))
			if relic != null:
				draw_texture_rect(relic, icon_rect.grow(3.0), false, Color(1, 1, 1, 0.76))
			else:
				UiSkin.draw_wax_stamp(self, icon_rect.get_center(), 18.0, Color("#7d2b78", 0.72))
		"event_risk_gold":
			UiSkin.draw_wax_stamp(self, icon_rect.get_center(), 18.0, Color("#8f1f1f", 0.72))
		_:
			var coin := AssetCatalog.shop_runtime_texture("coin_stack")
			if coin != null:
				draw_texture_rect(coin, icon_rect.grow(2.0), false, Color(1, 1, 1, 0.76))
			else:
				UiSkin.draw_coin_marker(self, icon_rect.get_center(), 18.0, Color(GOLD, 0.72))

func _draw_icon_kind(icon_kind: String, icon_rect: Rect2) -> void:
	match icon_kind:
		"dice":
			var dice := AssetCatalog.dice_face(5)
			if dice != null:
				draw_texture_rect(dice, icon_rect, false, Color(1, 1, 1, 0.78))
			else:
				draw_circle(icon_rect.get_center(), 18.0, Color(GOLD, 0.60))
		"roulette":
			var wheel := AssetCatalog.event_prop_texture("roulette_medallion")
			if wheel != null:
				draw_texture_rect(wheel, icon_rect.grow(4.0), false, Color(1, 1, 1, 0.72))
			else:
				draw_circle(icon_rect.get_center(), 18.0, Color("#24170d", 0.76))
				draw_arc(icon_rect.get_center(), 18.0, -PI * 0.2, PI * 1.3, 24, GOLD, 2.0)
		"card":
			var card_back := AssetCatalog.event_prop_texture("card_back")
			if card_back != null:
				draw_texture_rect(card_back, Rect2(icon_rect.position + Vector2(8, -8), Vector2(28, 48)), false, Color(1, 1, 1, 0.76))
			else:
				UiSkin.draw_parchment_card(self, Rect2(icon_rect.position + Vector2(8, -8), Vector2(28, 48)), "small", Color(1, 1, 1, 0.76))
		"relic":
			var result_value: Variant = choice_data.get("result", {})
			var relic_id := ""
			if result_value is Dictionary:
				var relics: Array = (result_value as Dictionary).get("relic_ids", [])
				if not relics.is_empty():
					relic_id = str(relics[0])
			var relic := AssetCatalog.relic_object(RelicCatalog.icon_id(relic_id))
			if relic != null:
				draw_texture_rect(relic, icon_rect.grow(3.0), false, Color(1, 1, 1, 0.76))
			else:
				UiSkin.draw_wax_stamp(self, icon_rect.get_center(), 18.0, Color("#7d2b78", 0.72))
		"blood":
			UiSkin.draw_wax_stamp(self, icon_rect.get_center(), 18.0, Color("#9f2424", 0.78))
		"heal":
			UiSkin.draw_wax_stamp(self, icon_rect.get_center(), 18.0, Color("#b73f3f", 0.70))
			draw_line(icon_rect.get_center() + Vector2(-9, 0), icon_rect.get_center() + Vector2(9, 0), Color("#f6d3c1", 0.82), 4.0)
			draw_line(icon_rect.get_center() + Vector2(0, -9), icon_rect.get_center() + Vector2(0, 9), Color("#f6d3c1", 0.82), 4.0)
		"danger":
			UiSkin.draw_wax_stamp(self, icon_rect.get_center(), 18.0, Color("#8f1f1f", 0.72))
		_:
			var coin := AssetCatalog.shop_runtime_texture("coin_stack")
			if coin != null:
				draw_texture_rect(coin, icon_rect.grow(2.0), false, Color(1, 1, 1, 0.76))
			else:
				UiSkin.draw_coin_marker(self, icon_rect.get_center(), 18.0, Color(GOLD, 0.72))

func _draw_labels(rect: Rect2) -> void:
	var label := str(choice_data.get("label", choice_id))
	var note := str(choice_data.get("note", ""))
	var effect := str(choice_data.get("effect", ""))
	var alpha := 0.94
	if disabled or visual_state == RunChoice.STATE_DISABLED:
		alpha = 0.46
	if _uses_design_slip():
		var text_x := rect.position.x + 30.0
		var text_width := rect.size.x - 60.0
		var plate := Rect2(rect.position + Vector2(21.0, 76.0), Vector2(rect.size.x - 42.0, 90.0))
		draw_rect(plate, Color("#f2d9a8", 0.70 * alpha), true)
		draw_rect(plate, Color("#4f3117", 0.30 * alpha), false, 1.0)
		_draw_text(label, Vector2(text_x, rect.position.y + 106.0), 15, Color(INK, alpha), text_width)
		_draw_text(note, Vector2(text_x, rect.position.y + 129.0), 10, Color(INK, alpha * 0.72), text_width)
		_draw_text(effect, Vector2(text_x, rect.position.y + 151.0), 10, Color("#5f3308", alpha * 0.92), text_width)
		return
	var text_x := rect.position.x + 86.0
	var text_width := rect.size.x - 112.0
	_draw_text(label, Vector2(text_x, rect.position.y + 38.0), 15, Color(INK, alpha), text_width)
	_draw_text(note, Vector2(text_x, rect.position.y + 62.0), 10, Color(INK, alpha * 0.62), text_width)
	_draw_text(effect, Vector2(text_x, rect.size.y + rect.position.y - 30.0), 11, Color("#70490f", alpha * 0.84), text_width)

func _draw_text(value: String, pos: Vector2, font_size: int, color: Color, width: float = -1.0) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)
