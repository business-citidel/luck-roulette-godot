extends Control

signal completed(result: Dictionary)

const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RelicPoolCatalog := preload("res://scripts/systems/relic_pool_catalog.gd")
const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const EventCatalog := preload("res://scripts/systems/event_catalog.gd")
const RunChoice := preload("res://scripts/run/run_choice.gd")
const RunTableState := preload("res://scripts/run/run_table_state.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const DiceRollLayer2D := preload("res://scripts/ui/dice_roll_layer_2d.gd")
const RouletteSpinLayer2D := preload("res://scripts/ui/roulette_spin_layer_2d.gd")
const EventBaseChoiceObjectNode := preload("res://scripts/ui/event_base_choice_object_node.gd")
const EventCardNode := preload("res://scripts/ui/event_card_node.gd")
const EventPropActionObjectNode := preload("res://scripts/ui/event_prop_action_object_node.gd")
const RouletteSlotCatalog := preload("res://scripts/systems/roulette_slot_catalog.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const BG := Color("#07090f")
const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const GREEN := Color("#65d48e")
const RED := Color("#ee5b5b")
const INK := Color("#090704")

const MODULE_STORY_INTRO := "story_intro"
const MODULE_BASE := "base"
const MODULE_DICE_CHECK := "dice_check"
const MODULE_ROULETTE_CHECK := "roulette_check"
const MODULE_CARD_DRAW := "card_draw"
const MODULE_RESULT := "result_receipt"

const BASE_CHOICE_RECTS := [
	Rect2(Vector2(224, 398), Vector2(208, 248)),
	Rect2(Vector2(536, 398), Vector2(208, 248)),
	Rect2(Vector2(848, 398), Vector2(208, 248))
]

const DICE_ROLL_RECT := Rect2(Vector2(330, 174), Vector2(620, 338))
const DICE_TRAY_RECT := Rect2(Vector2(424, 206), Vector2(432, 292))
const EVENT_CLEAN_TITLE_RECT := Rect2(Vector2(430, 48), Vector2(420, 88))
const EVENT_DICE_TABLE_RECT := Rect2(Vector2(330, 174), Vector2(620, 338))
const EVENT_DICE_TABLE_INNER_RECT := Rect2(Vector2(384, 224), Vector2(512, 226))
const EVENT_DIE_A_RECT := Rect2(Vector2(418, 268), Vector2(202, 178))
const EVENT_DIE_B_RECT := Rect2(Vector2(660, 268), Vector2(202, 178))
const EVENT_DICE_TARGET_RECTS := [
	Rect2(Vector2(986, 150), Vector2(124, 178)),
	Rect2(Vector2(986, 338), Vector2(124, 178)),
	Rect2(Vector2(986, 526), Vector2(124, 178))
]
const DEFAULT_DICE_TARGET := 8
const DEFAULT_DICE_GREAT_TARGET := 10
const ROULETTE_SPIN_RECT := Rect2(Vector2(446, 158), Vector2(388, 388))
const ROULETTE_WHEEL_CENTER := Vector2(640, 352)
const ROULETTE_WHEEL_SIZE := Vector2(388, 388)
const EVENT_ROULETTE_LEGEND_RECTS := [
	Rect2(Vector2(968, 206), Vector2(170, 78)),
	Rect2(Vector2(968, 326), Vector2(170, 78)),
	Rect2(Vector2(968, 446), Vector2(170, 78))
]
const CARD_DRAW_RECTS := [
	Rect2(Vector2(214, 292), Vector2(148, 210)),
	Rect2(Vector2(382, 258), Vector2(148, 210)),
	Rect2(Vector2(550, 238), Vector2(148, 210)),
	Rect2(Vector2(718, 258), Vector2(148, 210)),
	Rect2(Vector2(886, 292), Vector2(148, 210))
]
const BASE_TITLE_POS := Vector2(360, 124)
const BASE_BODY_POS := Vector2(360, 162)
const RESULT_TITLE_POS := Vector2(462, 158)
const RESULT_BODY_POS := Vector2(462, 210)

var run_state: Dictionary = {}
var map_result: Dictionary = {}
var buttons: Array[Button] = []
var choices: Array[Dictionary] = []
var choice_rects: Dictionary = {}
var resolution_result: Dictionary = {}
var submitted := false
var selected_choice := ""
var hovered_choice := ""
var module_id := MODULE_BASE
var story_page_index := 0
var active_event_id := "standard_table"
var pending_dice_bonus := 0
var pending_dice_values: Array[int] = []
var pending_dice_finished := 0
var pending_dice_target := DEFAULT_DICE_TARGET
var pending_dice_great_target := DEFAULT_DICE_GREAT_TARGET
var pending_roulette_wager := "small"
var pending_module_gold_delta := 0
var pending_module_hp_delta := 0
var pending_dice_result_table: Dictionary = {}
var pending_roulette_result_table: Dictionary = {}
var pending_card_deck_id := ""
var card_draw_results: Array[Dictionary] = []
var revealed_card_id := ""
var dice_layer: DiceRollLayer2D
var dice_layer_b: DiceRollLayer2D
var roulette_layer: RouletteSpinLayer2D

func configure(payload: Dictionary) -> void:
	run_state = payload.get("run_state", {}).duplicate(true)
	map_result = payload.get("map_result", {}).duplicate(true)
	active_event_id = _configured_event_id()
	module_id = MODULE_BASE
	story_page_index = 0
	if _has_story_intro() and not bool(map_result.get("skip_story_intro", false)):
		module_id = MODULE_STORY_INTRO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_install_dice_layer()
	_rebuild_buttons()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	_draw_background()
	match module_id:
		MODULE_STORY_INTRO:
			_draw_story_intro()
		MODULE_DICE_CHECK:
			_draw_dice_check()
		MODULE_ROULETTE_CHECK:
			_draw_roulette_check()
		MODULE_CARD_DRAW:
			_draw_card_draw()
		MODULE_RESULT:
			_draw_result_receipt()
		_:
			_draw_base_event()

func _install_dice_layer() -> void:
	dice_layer = DiceRollLayer2D.new()
	dice_layer.configure({
		"theme": "event",
		"tray_rect": DICE_TRAY_RECT,
		"draw_tray": false,
		"draw_result_receipt": false
	})
	dice_layer.roll_finished.connect(_on_event_die_a_finished)
	add_child(dice_layer)
	dice_layer_b = DiceRollLayer2D.new()
	dice_layer_b.configure({
		"theme": "event",
		"tray_rect": EVENT_DIE_B_RECT,
		"draw_tray": false,
		"draw_result_receipt": false
	})
	dice_layer_b.roll_finished.connect(_on_event_die_b_finished)
	add_child(dice_layer_b)
	roulette_layer = RouletteSpinLayer2D.new()
	roulette_layer.configure({
		"wheel_center": ROULETTE_WHEEL_CENTER,
		"wheel_size": ROULETTE_WHEEL_SIZE,
		"wheel_texture_source": "event",
		"wheel_texture_id": "roulette_medallion",
		"draw_result_badge": false
	})
	roulette_layer.spin_finished.connect(_on_roulette_spin_finished)
	add_child(roulette_layer)

func _draw_background() -> void:
	var texture_id := "screen_base"
	if module_id == MODULE_BASE:
		texture_id = "room_background_clean"
	match module_id:
		MODULE_STORY_INTRO:
			texture_id = "room_background_clean"
		MODULE_DICE_CHECK:
			texture_id = "room_background_clean"
		MODULE_ROULETTE_CHECK:
			texture_id = "room_background_clean"
		MODULE_CARD_DRAW:
			texture_id = "room_background_clean"
		MODULE_RESULT:
			texture_id = "result_receipt_focus"
	var texture := AssetCatalog.event_runtime_texture(texture_id)
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
		return
	UiSkin.draw_table_stage(self)

func _draw_base_event() -> void:
	var profile := _event_profile()
	UiSkin.draw_plaque(self, Rect2(Vector2(300, 74), Vector2(680, 134)), false)
	_draw_text(str(profile.get("title", UiText.t("event.fallback.title"))), Vector2(346, 126), 31, INK, 588.0)
	_draw_wrapped_text(str(profile.get("body", "")), Vector2(348, 164), 16, Color(INK, 0.74), 584.0, 22.0, 2)

func _draw_story_intro() -> void:
	var profile := _event_profile()
	var page := _current_story_page()
	var title := str(page.get("title", profile.get("title", UiText.t("event.fallback.title"))))
	var body := str(page.get("body", profile.get("body", "")))
	var panel := Rect2(Vector2(288, 92), Vector2(704, 250))
	UiSkin.draw_plaque(self, panel, false)
	_draw_text(title, panel.position + Vector2(52, 58), 32, INK, panel.size.x - 104.0)
	_draw_wrapped_text(body, panel.position + Vector2(54, 104), 18, Color(INK, 0.76), panel.size.x - 108.0, 28.0, 5)
	var pages: Array = profile.get("story_pages", [])
	if pages.size() > 1:
		_draw_text(str(story_page_index + 1) + " / " + str(pages.size()), panel.position + Vector2(panel.size.x - 112, panel.size.y - 34), 14, Color(INK, 0.50), 74.0)
	_draw_story_continue_prompt()

func _draw_story_continue_prompt() -> void:
	var rect := _story_continue_rect()
	var primary := hovered_choice == "story_intro_next"
	UiSkin.draw_plaque(self, rect, primary)
	var label := UiText.t("event.story.show_choices") if _is_last_story_page() else UiText.t("event.story.next_slip")
	_draw_text(label, rect.position + Vector2(62, 36), 18, INK, rect.size.x - 124.0)

func _draw_dice_check() -> void:
	_draw_clean_event_header(UiText.t("event.header.dice_title"), UiText.t("event.header.dice_subtitle"))
	_draw_dice_table_object()
	_draw_dice_target_slips()
	if pending_dice_values.size() >= 2 and int(pending_dice_values[0]) > 0 and int(pending_dice_values[1]) > 0:
		var total := int(pending_dice_values[0]) + int(pending_dice_values[1]) + pending_dice_bonus
		_draw_text(str(pending_dice_values[0]) + " + " + str(pending_dice_values[1]) + _bonus_text() + " = " + str(total), EVENT_DICE_TABLE_INNER_RECT.position + Vector2(168, 188), 22, Color(GOLD, 0.94), 280.0)

func _draw_clean_event_header(title: String, subtitle: String) -> void:
	UiSkin.draw_plaque(self, EVENT_CLEAN_TITLE_RECT, true)
	_draw_text(title, EVENT_CLEAN_TITLE_RECT.position + Vector2(44, 38), 27, INK, EVENT_CLEAN_TITLE_RECT.size.x - 88.0)
	_draw_text(subtitle, EVENT_CLEAN_TITLE_RECT.position + Vector2(48, 64), 13, Color(INK, 0.68), EVENT_CLEAN_TITLE_RECT.size.x - 96.0)

func _draw_dice_table_object() -> void:
	var outer := EVENT_DICE_TABLE_RECT
	var inner := EVENT_DICE_TABLE_INNER_RECT
	draw_rect(outer.grow(22.0), Color("#020201", 0.44), true)
	if not _draw_event_prop("dice_table", outer, Color(1, 1, 1, 0.95)):
		draw_rect(outer, Color("#160d06", 0.96), true)
		draw_rect(outer.grow(-8.0), Color("#3a2210", 0.88), false, 7.0)
		draw_rect(outer.grow(-20.0), Color("#050403", 0.30), false, 3.0)
		for corner in [
			outer.position + Vector2(28.0, 28.0),
			Vector2(outer.end.x - 28.0, outer.position.y + 28.0),
			Vector2(outer.position.x + 28.0, outer.end.y - 28.0),
			outer.end - Vector2(28.0, 28.0)
		]:
			draw_circle(corner, 13.0, Color("#9f6a2a", 0.86))
			draw_circle(corner, 6.0, Color("#201109", 0.82))
	draw_rect(inner.grow(10.0), Color("#070403", 0.68), true)
	draw_rect(inner, Color("#15371f", 0.99), true)
	draw_rect(inner, Color("#d08b2d", 0.24), false, 2.0)
	draw_rect(inner.grow(-10.0), Color("#0a2414", 0.26), false, 2.0)
	var divider_x := inner.position.x + inner.size.x * 0.5
	draw_line(Vector2(divider_x, inner.position.y + 12.0), Vector2(divider_x, inner.end.y - 12.0), Color("#d08b2d", 0.22), 2.0)
	draw_line(Vector2(inner.position.x + 22.0, inner.position.y + 24.0), Vector2(inner.end.x - 22.0, inner.position.y + 24.0), Color("#e8be71", 0.10), 2.0)
	draw_line(Vector2(inner.position.x + 22.0, inner.end.y - 22.0), Vector2(inner.end.x - 22.0, inner.end.y - 22.0), Color("#050201", 0.35), 3.0)
	var wax_center := Vector2(outer.position.x + outer.size.x * 0.5, outer.end.y - 18.0)
	UiSkin.draw_wax_stamp(self, wax_center, 20.0, Color("#9d2a24", 0.95))
	_draw_text("2D6", inner.position + Vector2(220.0, 120.0), 18, Color("#e7c784", 0.16), 90.0)

func _draw_dice_target_slips() -> void:
	var target_data := [
		{"value": str(pending_dice_great_target) + "+", "label": UiText.t("event.dice.great"), "color": GREEN, "texture": "dice_result_six"},
		{"value": UiText.t("event.dice.target", {"amount": pending_dice_target}), "label": UiText.t("event.dice.success"), "color": GOLD, "texture": "dice_result_three"},
		{"value": "< " + str(pending_dice_target), "label": UiText.t("event.dice.fail"), "color": RED, "texture": "dice_result_one"}
	]
	for i in range(EVENT_DICE_TARGET_RECTS.size()):
		var rect: Rect2 = EVENT_DICE_TARGET_RECTS[i]
		var data: Dictionary = target_data[i]
		var slip_color: Color = data.get("color", GOLD)
		var slip_texture := AssetCatalog.event_slip_texture(str(data.get("texture", "")))
		if slip_texture != null:
			draw_rect(Rect2(rect.position + Vector2(7, 10), rect.size), Color("#020201", 0.30), true)
			draw_texture_rect(slip_texture, rect, false, Color(1, 1, 1, 0.96))
			var label_plate := Rect2(rect.position + Vector2(12, 64), Vector2(rect.size.x - 24, 56))
			draw_rect(label_plate, Color("#f0d7a5", 0.74), true)
			draw_rect(label_plate, Color("#4f3117", 0.28), false, 1.0)
			_draw_text(str(data.get("value", "")), rect.position + Vector2(20, 88), 15, slip_color, rect.size.x - 40.0)
			_draw_text(str(data.get("label", "")), rect.position + Vector2(20, 110), 11, Color(INK, 0.72), rect.size.x - 40.0)
			continue
		UiSkin.draw_ledger_slip(self, rect, Color(1, 1, 1, 0.92))
		UiSkin.draw_state_token(self, rect.position + Vector2(28, 28), "current" if i < 2 else "failed", 16.0, slip_color)
		_draw_text(str(data.get("value", "")), rect.position + Vector2(56, 38), 19, slip_color, rect.size.x - 68.0)
		_draw_text(str(data.get("label", "")), rect.position + Vector2(56, 64), 13, Color(INK, 0.70), rect.size.x - 68.0)

func _draw_roulette_check() -> void:
	_draw_clean_event_header(UiText.t("event.header.roulette_title"), UiText.t("event.header.roulette_subtitle"))
	if not _roulette_is_busy():
		_draw_static_event_roulette()
	_draw_roulette_legend_slips()

func _draw_card_draw() -> void:
	_draw_clean_event_header(UiText.t("event.header.card_title"), UiText.t("event.header.card_subtitle"))

func _draw_static_event_roulette() -> void:
	var wheel_texture := AssetCatalog.event_prop_texture("roulette_medallion")
	var pointer_texture := AssetCatalog.combat_runtime_texture("roulette_pointer")
	var shadow_rect := Rect2(ROULETTE_WHEEL_CENTER - ROULETTE_WHEEL_SIZE * 0.5 + Vector2(16, 24), ROULETTE_WHEEL_SIZE)
	draw_rect(shadow_rect.grow(20.0), Color("#020201", 0.34), true)
	if wheel_texture != null:
		draw_texture_rect(wheel_texture, shadow_rect, false, Color(0, 0, 0, 0.30))
		draw_texture_rect(wheel_texture, Rect2(ROULETTE_WHEEL_CENTER - ROULETTE_WHEEL_SIZE * 0.5, ROULETTE_WHEEL_SIZE), false, Color(1, 1, 1, 0.96))
	else:
		draw_circle(ROULETTE_WHEEL_CENTER, ROULETTE_WHEEL_SIZE.x * 0.48, Color("#24170d", 0.96))
		draw_circle(ROULETTE_WHEEL_CENTER, ROULETTE_WHEEL_SIZE.x * 0.16, Color(GOLD, 0.80))
	var pointer_size := Vector2(56, 148)
	var pointer_top := ROULETTE_WHEEL_CENTER + Vector2(0, -ROULETTE_WHEEL_SIZE.y * 0.54)
	if pointer_texture != null:
		draw_texture_rect(pointer_texture, Rect2(pointer_top - Vector2(pointer_size.x * 0.5, pointer_size.y * 0.12), pointer_size), false, Color(1, 1, 1, 0.96))
	else:
		draw_polygon(PackedVector2Array([
			ROULETTE_WHEEL_CENTER + Vector2(0, -ROULETTE_WHEEL_SIZE.y * 0.48),
			ROULETTE_WHEEL_CENTER + Vector2(-20, -ROULETTE_WHEEL_SIZE.y * 0.64),
			ROULETTE_WHEEL_CENTER + Vector2(20, -ROULETTE_WHEEL_SIZE.y * 0.64)
		]), PackedColorArray([GOLD, GOLD, GOLD]))

func _draw_roulette_legend_slips() -> void:
	var legend_data := [
		{"value": UiText.t("event.roulette.safe"), "label": UiText.t("event.roulette.safe_note"), "color": GOLD, "state": "current"},
		{"value": UiText.t("event.roulette.reward"), "label": UiText.t("event.roulette.reward_note"), "color": GREEN, "state": "reward"},
		{"value": UiText.t("event.roulette.risk"), "label": UiText.t("event.roulette.risk_note"), "color": RED, "state": "failed"}
	]
	for i in range(EVENT_ROULETTE_LEGEND_RECTS.size()):
		var rect: Rect2 = EVENT_ROULETTE_LEGEND_RECTS[i]
		var data: Dictionary = legend_data[i]
		var color: Color = data.get("color", GOLD)
		UiSkin.draw_ledger_slip(self, rect, Color(1, 1, 1, 0.90))
		UiSkin.draw_state_token(self, rect.position + Vector2(27, 27), str(data.get("state", "current")), 15.0, color)
		_draw_text(str(data.get("value", "")), rect.position + Vector2(56, 34), 18, color, rect.size.x - 68.0)
		_draw_text(str(data.get("label", "")), rect.position + Vector2(56, 58), 12, Color(INK, 0.68), rect.size.x - 68.0)

func _draw_event_prop(texture_id: String, rect: Rect2, tint: Color = Color.WHITE) -> bool:
	var texture := AssetCatalog.event_prop_texture(texture_id)
	if texture == null:
		return false
	draw_texture_rect(texture, rect, false, tint)
	return true

func _draw_result_receipt() -> void:
	var title := _result_title()
	var body := _result_body()
	_draw_text(title, RESULT_TITLE_POS, 32, INK, 430.0)
	_draw_text(body, RESULT_BODY_POS, 18, Color(INK, 0.76), 430.0)
	_draw_text(_result_delta_text(), RESULT_BODY_POS + Vector2(0, 78), 22, Color("#70490f", 0.92), 430.0)
	if resolution_result.has("dice_total"):
		var dice_values: Array = resolution_result.get("dice_values", [])
		var dice_line := UiText.t("event.result.dice_total", {"total": int(resolution_result.get("dice_total", 0))})
		if dice_values.size() >= 2:
			dice_line = str(int(dice_values[0])) + " + " + str(int(dice_values[1])) + _result_bonus_text(resolution_result) + " = " + str(int(resolution_result.get("dice_total", 0)))
		dice_line += " / " + UiText.t("event.result.target", {"amount": int(resolution_result.get("dice_target", DEFAULT_DICE_TARGET))})
		_draw_text(dice_line, RESULT_BODY_POS + Vector2(0, 122), 18, Color(INK, 0.70), 430.0)
	elif resolution_result.has("dice_value"):
		_draw_text(UiText.t("event.result.die_pips", {"value": int(resolution_result.get("dice_value", 0))}), RESULT_BODY_POS + Vector2(0, 122), 18, Color(INK, 0.70), 430.0)
	if resolution_result.has("roulette_slot"):
		var slot_id := str(resolution_result.get("roulette_slot", ""))
		_draw_text(UiText.t("event.result.roulette", {"slot": RouletteSlotCatalog.label(slot_id)}), RESULT_BODY_POS + Vector2(0, 122), 18, Color(INK, 0.70), 430.0)
	if resolution_result.has("card_label"):
		_draw_text(UiText.t("event.result.card", {"card": str(resolution_result.get("card_label", ""))}), RESULT_BODY_POS + Vector2(0, 122), 18, Color(INK, 0.70), 430.0)

func _draw_choice_text(choice: Dictionary, rect: Rect2) -> void:
	if rect.size == Vector2.ZERO:
		return
	if module_id == MODULE_DICE_CHECK or module_id == MODULE_ROULETTE_CHECK:
		_draw_runtime_choice_plate(str(choice.get("id", "")), rect)
	var choice_id := str(choice.get("id", ""))
	var alpha := 0.95
	if submitted and selected_choice != choice_id:
		alpha = 0.42
	var label := str(choice.get("label", choice_id))
	var note := str(choice.get("note", ""))
	var effect := str(choice.get("effect", ""))
	if rect.size.y < 140.0:
		var x_offset := 96.0 if (module_id == MODULE_DICE_CHECK or module_id == MODULE_ROULETTE_CHECK) else 26.0
		_draw_text(label, rect.position + Vector2(x_offset, 40), 18, Color(INK, alpha), rect.size.x - x_offset - 28.0)
		_draw_text(note, rect.position + Vector2(x_offset, 64), 12, Color(INK, alpha * 0.66), rect.size.x - x_offset - 28.0)
		_draw_text(effect, rect.position + Vector2(x_offset, 88), 13, Color("#70490f", alpha * 0.88), rect.size.x - x_offset - 28.0)
		return
	_draw_text(label, rect.position + Vector2(94, 44), 19, Color(INK, alpha), rect.size.x - 118.0)
	_draw_text(note, rect.position + Vector2(94, 80), 13, Color(INK, alpha * 0.66), rect.size.x - 118.0)
	_draw_text(effect, rect.position + Vector2(94, rect.size.y - 44), 15, Color("#70490f", alpha * 0.88), rect.size.x - 118.0)

func _draw_choice_states() -> void:
	for choice in choices:
		var choice_id := str(choice.get("id", ""))
		var rect := get_choice_rect(choice_id)
		if rect.size == Vector2.ZERO:
			continue
		if hovered_choice == choice_id and not submitted and not _module_is_busy():
			draw_rect(rect.grow(-10.0), Color(GOLD, 0.19), true)
			draw_rect(rect.grow(-10.0), Color(GOLD, 0.70), false, 3.0)
		if submitted:
			if selected_choice == choice_id:
				draw_rect(rect.grow(-10.0), Color(GREEN, 0.18), true)
				draw_rect(rect.grow(-10.0), Color(GREEN, 0.70), false, 4.0)
		else:
			draw_rect(rect, Color("#050403", 0.38), true)

func _draw_runtime_choice_plate(choice_id: String, rect: Rect2) -> void:
	var primary := hovered_choice == choice_id and not submitted and not _module_is_busy()
	UiSkin.draw_plaque(self, rect, primary)
	var icon_center := rect.position + Vector2(52, rect.size.y * 0.5)
	draw_circle(icon_center, 25.0, Color("#130c07", 0.28))
	if module_id == MODULE_ROULETTE_CHECK:
		draw_circle(icon_center, 20.0, Color("#24170d", 0.94))
		draw_arc(icon_center, 20.0, -PI * 0.25, PI * 1.35, 28, Color(GOLD, 0.82), 3.0)
		draw_polygon(PackedVector2Array([
			icon_center + Vector2(0, -26),
			icon_center + Vector2(-9, -8),
			icon_center + Vector2(9, -8)
		]), PackedColorArray([GOLD, GOLD, GOLD]))
		return
	var dice_texture := AssetCatalog.dice_face(5)
	if dice_texture != null:
		draw_texture_rect(dice_texture, Rect2(icon_center - Vector2(22, 22), Vector2(44, 44)), false, Color(1, 1, 1, 0.82))
	else:
		draw_circle(icon_center, 18.0, Color(GOLD, 0.60))

func _rebuild_buttons() -> void:
	for button in buttons:
		button.queue_free()
	buttons.clear()
	choice_rects.clear()
	if submitted or module_id == MODULE_RESULT:
		return
	choices = _visible_choices()
	for i in range(choices.size()):
		var choice := choices[i]
		var choice_id := str(choice.get("id", "choice_" + str(i)))
		var rect := _rect_for_choice_index(i)
		choice_rects[choice_id] = rect
		var button: Button
		if module_id == MODULE_CARD_DRAW:
			button = _build_event_card_button(choice, choice_id, rect)
		elif module_id == MODULE_BASE:
			button = _build_event_base_choice_button(choice, choice_id, rect)
		elif module_id == MODULE_DICE_CHECK or module_id == MODULE_ROULETTE_CHECK:
			button = _build_event_prop_action_button(choice, choice_id, rect)
		else:
			button = RunChoice.build_hit_button(
				choice,
				i,
				Callable(self, "_choose_by_id").bind(choice_id),
				choices.size(),
				Callable(self, "_hover_choice"),
				Callable(self, "_clear_hover")
			)
		button.position = rect.position
		button.size = rect.size
		add_child(button)
		buttons.append(button)

func _build_event_card_button(choice: Dictionary, choice_id: String, rect: Rect2) -> EventCardNode:
	var card := _card_by_id(choice_id)
	if card.is_empty():
		card = choice.duplicate(true)
	var button := EventCardNode.new()
	button.name = "RunChoice_" + choice_id
	button.configure(card)
	button.set_card_rect(rect)
	button.disabled = not RunChoice.is_interactive(choice)
	if not button.disabled:
		button.pressed.connect(Callable(self, "_choose_by_id").bind(choice_id))
	button.mouse_entered.connect(func() -> void: _hover_choice(choice_id))
	button.mouse_exited.connect(func() -> void: _clear_hover(choice_id))
	return button

func _build_event_prop_action_button(choice: Dictionary, choice_id: String, rect: Rect2) -> EventPropActionObjectNode:
	var button := EventPropActionObjectNode.new()
	var prop_kind := "roulette" if choice_id == "roulette_spin_now" else "dice"
	button.configure_action(choice, rect, prop_kind)
	if not button.disabled:
		button.pressed.connect(Callable(self, "_choose_by_id").bind(choice_id))
	button.mouse_entered.connect(func() -> void: _hover_choice(choice_id))
	button.mouse_exited.connect(func() -> void: _clear_hover(choice_id))
	return button

func _build_event_base_choice_button(choice: Dictionary, choice_id: String, rect: Rect2) -> EventBaseChoiceObjectNode:
	var button := EventBaseChoiceObjectNode.new()
	button.configure_choice(choice, rect, active_event_id)
	if not button.disabled:
		button.pressed.connect(Callable(self, "_choose_by_id").bind(choice_id))
	button.mouse_entered.connect(func() -> void: _hover_choice(choice_id))
	button.mouse_exited.connect(func() -> void: _clear_hover(choice_id))
	return button

func get_choice_controls() -> Array[Button]:
	return buttons

func get_choice_rect(choice_id: String) -> Rect2:
	return choice_rects.get(choice_id, Rect2())

func _card_by_id(card_id: String) -> Dictionary:
	for card in card_draw_results:
		if str(card.get("id", "")) == card_id:
			return card
	return {}

func get_table_state() -> Dictionary:
	return RunTableState.from_run_payload(run_state, resolution_result)

func get_pickup_summary() -> Dictionary:
	return get_table_state().get("pickup", {})

func _visible_choices() -> Array[Dictionary]:
	if module_id == MODULE_STORY_INTRO:
		var label := UiText.t("event.story.show_choices") if _is_last_story_page() else UiText.t("event.story.next_slip")
		return [
			RunChoice.create("story_intro_next", label, "", "", {})
		]
	if module_id == MODULE_DICE_CHECK:
		return [
			RunChoice.create("dice_roll_now", UiText.t("event.action.roll"), "", "", {})
		]
	if module_id == MODULE_ROULETTE_CHECK:
		return [
			RunChoice.create("roulette_spin_now", UiText.t("event.action.spin"), "", "", {})
		]
	if module_id == MODULE_CARD_DRAW:
		var cards: Array[Dictionary] = []
		for card in card_draw_results:
			cards.append(RunChoice.create(
				str(card.get("id", "")),
				str(card.get("label", "")),
				"",
				str(card.get("effect", "")),
				(card.get("result", {}) as Dictionary)
			))
		return cards
	var profile := _event_profile()
	var result: Array[Dictionary] = []
	for choice in profile.get("choices", []):
		if choice is Dictionary:
			result.append((choice as Dictionary).duplicate(true))
	return result

func _event_profile() -> Dictionary:
	var profile := EventCatalog.get_profile(active_event_id)
	var hydrated := profile.duplicate(true)
	var hydrated_choices: Array[Dictionary] = []
	for choice in profile.get("choices", []):
		if choice is Dictionary:
			hydrated_choices.append(_hydrate_catalog_choice(choice as Dictionary))
	hydrated["choices"] = hydrated_choices
	return hydrated

func _has_story_intro() -> bool:
	var profile := EventCatalog.get_profile(active_event_id)
	return (profile.get("story_pages", []) as Array).size() > 0

func _current_story_page() -> Dictionary:
	var profile := _event_profile()
	var pages: Array = profile.get("story_pages", [])
	if pages.is_empty():
		return {
			"title": profile.get("title", UiText.t("event.fallback.title")),
			"body": profile.get("body", "")
		}
	var index := clampi(story_page_index, 0, pages.size() - 1)
	var page: Variant = pages[index]
	if page is Dictionary:
		return (page as Dictionary)
	return {
		"title": profile.get("title", UiText.t("event.fallback.title")),
		"body": str(page)
	}

func _is_last_story_page() -> bool:
	var pages: Array = _event_profile().get("story_pages", [])
	return pages.is_empty() or story_page_index >= pages.size() - 1

func _advance_story_intro() -> void:
	if module_id != MODULE_STORY_INTRO:
		return
	if not _is_last_story_page():
		story_page_index += 1
	else:
		module_id = MODULE_BASE
		hovered_choice = ""
	_rebuild_buttons()
	queue_redraw()

func _standard_choices() -> Array[Dictionary]:
	var profile := EventCatalog.get_profile(EventCatalog.EVENT_STANDARD)
	var result: Array[Dictionary] = []
	for choice in profile.get("choices", []):
		if choice is Dictionary:
			result.append(_hydrate_catalog_choice(choice as Dictionary))
	return result

func _hydrate_catalog_choice(raw_choice: Dictionary) -> Dictionary:
	var choice := raw_choice.duplicate(true)
	var template: Dictionary = choice.get("result_template", {})
	if not template.is_empty():
		choice["result"] = _result_from_template(template, str(choice.get("id", "")))
	var required_gold := int(choice.get("required_gold", 0))
	if required_gold > 0 and int(run_state.get("gold", 0)) < required_gold:
		choice["state"] = RunChoice.STATE_UNAFFORDABLE
		choice["enabled"] = false
	var required_hp := int(choice.get("required_hp", 0))
	if required_hp > 0 and int(run_state.get("player_hp", 0)) <= required_hp:
		choice["state"] = RunChoice.STATE_DISABLED
		choice["enabled"] = false
	return choice

func _catalog_choice_by_id(choice_id: String, event_id: String = "") -> Dictionary:
	var profile := EventCatalog.get_profile(active_event_id if event_id == "" else event_id)
	for choice in profile.get("choices", []):
		if not (choice is Dictionary):
			continue
		var hydrated := _hydrate_catalog_choice(choice as Dictionary)
		if str(hydrated.get("id", "")) == choice_id:
			return hydrated
	return {}

func _result_for_catalog_choice(choice_id: String, event_id: String = "") -> Dictionary:
	var choice := _catalog_choice_by_id(choice_id, event_id)
	if choice.is_empty():
		return {}
	return _result_from_choice(choice)

func _result_from_choice(choice: Dictionary) -> Dictionary:
	var template: Dictionary = choice.get("result_template", choice.get("result", {}))
	return _result_from_template(template, str(choice.get("id", "")))

func _result_from_template(template: Dictionary, fallback_choice_id: String) -> Dictionary:
	var result := {
		"accepted": bool(template.get("accepted", true)),
		"choice": str(template.get("choice", fallback_choice_id)),
		"gold_delta": int(template.get("gold_delta", 0)),
		"hp_delta": int(template.get("hp_delta", 0)),
		"relic_ids": [],
		"next_combat_mods": [],
		"result_title": str(template.get("result_title", UiText.t("event.result.default_title"))),
		"result_body": str(template.get("result_body", UiText.t("event.result.closed")))
	}
	var relic_ids: Array = []
	for relic_id in template.get("relic_ids", []):
		relic_ids.append(str(relic_id))
	var owned_relics: Array = run_state.get("relic_ids", []).duplicate()
	for relic_id in relic_ids:
		if not owned_relics.has(relic_id):
			owned_relics.append(relic_id)
	var reward_count := int(template.get("relic_reward_count", 0))
	var reward_source_pool := _relic_source_pool_for_template(template)
	for i in range(reward_count):
		var next_relic := _next_pool_relic_id(owned_relics, "template_" + str(i), reward_source_pool)
		if next_relic == "":
			continue
		if not relic_ids.has(next_relic):
			relic_ids.append(next_relic)
		if not owned_relics.has(next_relic):
			owned_relics.append(next_relic)
	result["relic_ids"] = relic_ids
	var mods: Array = []
	for mod in template.get("next_combat_mods", []):
		if mod is Dictionary:
			mods.append((mod as Dictionary).duplicate(true))
	result["next_combat_mods"] = mods
	var upgrades: Dictionary = template.get("run_upgrades", {})
	if not upgrades.is_empty():
		result["run_upgrades"] = upgrades.duplicate(true)
	for key in template.keys():
		if result.has(key) or str(key) == "relic_reward_count":
			continue
		var value: Variant = template[key]
		if value is Dictionary or value is Array:
			result[key] = value.duplicate(true)
		else:
			result[key] = value
	return result

func _choose_by_id(choice_id: String) -> void:
	if submitted:
		return
	if choice_id == "story_intro_next":
		_advance_story_intro()
		return
	if choice_id == "dice_roll_now":
		_roll_event_die()
		return
	if choice_id == "roulette_spin_now":
		_spin_event_roulette()
		return
	if choice_id.begins_with("event_card_"):
		_choose_event_card(choice_id)
		return
	var catalog_choice := _catalog_choice_by_id(choice_id)
	if _dispatch_catalog_choice(catalog_choice):
		return
	match choice_id:
		"event_gold":
			_choose_gold()
		"event_relic_trade":
			_choose_trade()
		"event_risk_gold":
			_choose_risk_gold()
		"backroom_die_roll":
			_start_dice_check(0)
		"backroom_die_cheat":
			_start_dice_check(1)
		"backroom_die_leave":
			_complete_once(_backroom_die_leave_result())
		"crooked_wheel_small":
			_start_roulette_check("small")
		"crooked_wheel_risky":
			_start_roulette_check("risky")
		"crooked_wheel_leave":
			_complete_once(_crooked_wheel_leave_result())
		"sealed_cards_draw":
			_start_card_draw(false)
		"sealed_cards_peek":
			_start_card_draw(true)
		"sealed_cards_leave":
			_complete_once(_sealed_cards_leave_result())

func _dispatch_catalog_choice(choice: Dictionary) -> bool:
	if choice.is_empty() or not RunChoice.is_interactive(choice):
		return false
	var action := str(choice.get("action", ""))
	match action:
		EventCatalog.ACTION_RESULT:
			_complete_once(_result_from_choice(choice))
			return true
		EventCatalog.ACTION_DICE_CHECK:
			_start_dice_check(int(choice.get("dice_bonus", 0)), -int(choice.get("cost_gold", 0)), -int(choice.get("cost_hp", 0)), choice.get("dice_result_table", {}))
			return true
		EventCatalog.ACTION_ROULETTE_CHECK:
			_start_roulette_check(str(choice.get("roulette_wager", "small")), -int(choice.get("cost_gold", 0)), -int(choice.get("cost_hp", 0)), choice.get("roulette_result_table", {}))
			return true
		EventCatalog.ACTION_CARD_DRAW:
			_start_card_draw(bool(choice.get("card_peeked", false)), -int(choice.get("cost_gold", 0)), -int(choice.get("cost_hp", 0)), str(choice.get("card_deck_id", "")))
			return true
	return false

func _choose_gold() -> void:
	_complete_once(_gold_result())

func _gold_result() -> Dictionary:
	return _result_for_catalog_choice("event_gold", EventCatalog.EVENT_STANDARD)

func _choose_trade() -> void:
	_complete_once(_trade_result())

func _trade_result() -> Dictionary:
	return _result_for_catalog_choice("event_relic_trade", EventCatalog.EVENT_STANDARD)

func _choose_risk_gold() -> void:
	_complete_once(_risk_gold_result())

func _risk_gold_result() -> Dictionary:
	return _result_for_catalog_choice("event_risk_gold", EventCatalog.EVENT_STANDARD)

func _choose_default() -> void:
	for choice in _event_profile().get("choices", []):
		if not (choice is Dictionary):
			continue
		var data := choice as Dictionary
		if str(data.get("action", "")) == EventCatalog.ACTION_RESULT and RunChoice.is_interactive(data):
			_choose_by_id(str(data.get("id", "")))
			return
	_choose_gold()

func _start_dice_check(bonus: int, cost_gold_delta: int = 0, cost_hp_delta: int = 0, dice_result_table: Dictionary = {}) -> void:
	pending_dice_bonus = bonus
	pending_module_gold_delta = cost_gold_delta
	pending_module_hp_delta = cost_hp_delta
	pending_dice_result_table = dice_result_table.duplicate(true)
	pending_dice_values.clear()
	pending_dice_finished = 0
	pending_dice_target = int(map_result.get("dice_target", map_result.get("target_total", DEFAULT_DICE_TARGET)))
	pending_dice_great_target = int(map_result.get("dice_great_target", map_result.get("great_total", DEFAULT_DICE_GREAT_TARGET)))
	module_id = MODULE_DICE_CHECK
	hovered_choice = ""
	_rebuild_buttons()
	queue_redraw()

func _roll_event_die() -> void:
	if _dice_is_busy():
		return
	for button in buttons:
		button.disabled = true
	pending_dice_values = [0, 0]
	pending_dice_finished = 0
	var forced_values := _forced_event_dice_values()
	var options_a := {
		"theme": "event",
		"tray_rect": EVENT_DIE_A_RECT,
		"draw_tray": false,
		"draw_result_receipt": false,
		"result_label": UiText.t("event.dice.first")
	}
	var options_b := {
		"theme": "event",
		"tray_rect": EVENT_DIE_B_RECT,
		"draw_tray": false,
		"draw_result_receipt": false,
		"result_label": UiText.t("event.dice.second")
	}
	if forced_values.size() >= 2:
		options_a["forced_value"] = int(forced_values[0])
		options_b["forced_value"] = int(forced_values[1])
	dice_layer.roll(options_a)
	dice_layer_b.roll(options_b)
	queue_redraw()

func _forced_event_dice_values() -> Array[int]:
	var raw_values: Variant = map_result.get("dice_forced_values", map_result.get("forced_dice_values", []))
	var result: Array[int] = []
	if raw_values is Array:
		for value in raw_values:
			if result.size() >= 2:
				break
			result.append(clampi(int(value), 1, 6))
	var legacy_forced := int(map_result.get("dice_forced_value", map_result.get("forced_dice_value", 0)))
	if result.is_empty() and legacy_forced >= 1 and legacy_forced <= 6:
		result = [legacy_forced, legacy_forced]
	while result.size() > 0 and result.size() < 2:
		result.append(result[0])
	return result

func _on_event_die_a_finished(value: int) -> void:
	_store_event_die_result(0, value)

func _on_event_die_b_finished(value: int) -> void:
	_store_event_die_result(1, value)

func _store_event_die_result(index: int, value: int) -> void:
	while pending_dice_values.size() < 2:
		pending_dice_values.append(0)
	pending_dice_values[index] = clampi(value, 1, 6)
	pending_dice_finished += 1
	if pending_dice_finished < 2:
		queue_redraw()
		return
	if dice_layer != null:
		dice_layer.visible = false
	if dice_layer_b != null:
		dice_layer_b.visible = false
	_complete_once(_dice_result_2d6(pending_dice_values.duplicate()))

func _start_roulette_check(wager: String, cost_gold_delta: int = 0, cost_hp_delta: int = 0, roulette_result_table: Dictionary = {}) -> void:
	pending_roulette_wager = wager
	pending_module_gold_delta = cost_gold_delta
	pending_module_hp_delta = cost_hp_delta
	pending_roulette_result_table = roulette_result_table.duplicate(true)
	module_id = MODULE_ROULETTE_CHECK
	hovered_choice = ""
	_rebuild_buttons()
	queue_redraw()

func _spin_event_roulette() -> void:
	if _roulette_is_busy():
		return
	for button in buttons:
		button.disabled = true
	var options := {
		"wheel_center": ROULETTE_WHEEL_CENTER,
		"wheel_size": ROULETTE_WHEEL_SIZE,
		"wheel_texture_source": "event",
		"wheel_texture_id": "roulette_medallion",
		"draw_result_badge": false
	}
	var forced := str(map_result.get("roulette_forced_slot", map_result.get("forced_roulette_slot", "")))
	if RouletteSlotCatalog.has_slot(forced):
		options["forced_slot"] = forced
	roulette_layer.spin(options)
	queue_redraw()

func _on_roulette_spin_finished(slot_id: String) -> void:
	if roulette_layer != null:
		roulette_layer.visible = false
	_complete_once(_roulette_result(slot_id))

func _start_card_draw(peeked: bool, cost_gold_delta: int = 0, cost_hp_delta: int = 0, card_deck_id: String = "") -> void:
	pending_module_gold_delta = cost_gold_delta
	pending_module_hp_delta = cost_hp_delta
	pending_card_deck_id = card_deck_id
	card_draw_results = _build_card_draw_results(peeked)
	revealed_card_id = ""
	module_id = MODULE_CARD_DRAW
	hovered_choice = ""
	_rebuild_buttons()
	queue_redraw()

func _choose_event_card(card_id: String) -> void:
	if submitted or revealed_card_id != "":
		return
	for card in card_draw_results:
		if str(card.get("id", "")) != card_id:
			continue
		revealed_card_id = card_id
		for button in buttons:
			button.disabled = true
			if button is EventCardNode:
				if button.card_id == card_id:
					button.reveal_selected()
				else:
					button.set_dimmed(true)
		queue_redraw()
		_resolve_card_after_reveal((card.get("result", {}) as Dictionary).duplicate(true))
		return

func _resolve_card_after_reveal(result: Dictionary) -> void:
	await get_tree().create_timer(0.60).timeout
	_complete_once(result)

func _dice_result_2d6(values: Array[int]) -> Dictionary:
	var total := 0
	for value in values:
		total += clampi(value, 1, 6)
	total += pending_dice_bonus
	var tier := _dice_tier(total)
	if not pending_dice_result_table.is_empty():
		var payload := _payload_from_dice_table(tier, values, total)
		if not payload.is_empty():
			return payload
	if tier == "fail":
		return {
			"accepted": true,
			"choice": "backroom_die_test",
			"gold_delta": 0,
			"hp_delta": -3,
			"relic_ids": [],
			"next_combat_mods": [],
			"dice_value": total,
			"dice_values": values.duplicate(),
			"dice_total": total,
			"dice_target": pending_dice_target,
			"dice_bonus": pending_dice_bonus,
			"dice_tier": tier,
			"result_title": UiText.t("event.result.dice_fail_title"),
			"result_body": UiText.t("event.result.dice_fail_body")
		}
	if tier == "success":
		return {
			"accepted": true,
			"choice": "backroom_die_test",
			"gold_delta": 10,
			"hp_delta": 0,
			"relic_ids": [],
			"next_combat_mods": [],
			"dice_value": total,
			"dice_values": values.duplicate(),
			"dice_total": total,
			"dice_target": pending_dice_target,
			"dice_bonus": pending_dice_bonus,
			"dice_tier": tier,
			"result_title": UiText.t("event.result.dice_success_title"),
			"result_body": UiText.t("event.result.dice_success_body")
		}
	return {
		"accepted": true,
		"choice": "backroom_die_test",
		"gold_delta": 6,
		"hp_delta": 0,
		"relic_ids": _relic_reward_array("backroom_great"),
		"next_combat_mods": [],
		"dice_value": total,
		"dice_values": values.duplicate(),
		"dice_total": total,
		"dice_target": pending_dice_target,
		"dice_bonus": pending_dice_bonus,
		"dice_tier": tier,
		"result_title": UiText.t("event.result.dice_great_title"),
		"result_body": UiText.t("event.result.dice_great_body")
	}

func _dice_tier(total: int) -> String:
	if total >= pending_dice_great_target:
		return "great"
	if total >= pending_dice_target:
		return "success"
	return "fail"

func _payload_from_dice_table(tier: String, values: Array[int], total: int) -> Dictionary:
	var template: Variant = pending_dice_result_table.get(tier, pending_dice_result_table.get("default", {}))
	if not (template is Dictionary) or (template as Dictionary).is_empty():
		return {}
	var payload := _result_from_template(template as Dictionary, active_event_id)
	payload["dice_value"] = total
	payload["dice_values"] = values.duplicate()
	payload["dice_total"] = total
	payload["dice_target"] = pending_dice_target
	payload["dice_bonus"] = pending_dice_bonus
	payload["dice_tier"] = tier
	return payload

func _bonus_text() -> String:
	if pending_dice_bonus == 0:
		return ""
	return " + " + str(pending_dice_bonus)

func _result_bonus_text(result: Dictionary) -> String:
	var bonus := int(result.get("dice_bonus", 0))
	if bonus == 0:
		return ""
	return " + " + str(bonus)

func _backroom_die_leave_result() -> Dictionary:
	return {
		"accepted": true,
		"choice": "backroom_die_leave",
		"gold_delta": 4,
		"hp_delta": 0,
		"relic_ids": [],
		"next_combat_mods": [],
		"result_title": UiText.t("event.result.quiet_exit_title"),
		"result_body": UiText.t("event.result.quiet_exit_body")
	}

func _roulette_result(slot_id: String) -> Dictionary:
	if not pending_roulette_result_table.is_empty():
		return _payload_from_roulette_table(slot_id)
	if pending_roulette_wager == "risky":
		return _risky_roulette_result(slot_id)
	return _small_roulette_result(slot_id)

func _payload_from_roulette_table(slot_id: String) -> Dictionary:
	var template: Variant = pending_roulette_result_table.get(slot_id, pending_roulette_result_table.get("default", {}))
	if not (template is Dictionary) or (template as Dictionary).is_empty():
		template = pending_roulette_result_table.get("safe", {})
	if not (template is Dictionary) or (template as Dictionary).is_empty():
		return _small_roulette_result(slot_id)
	var payload := _result_from_template(template as Dictionary, active_event_id)
	payload["roulette_slot"] = slot_id
	return payload

func _small_roulette_result(slot_id: String) -> Dictionary:
	match slot_id:
		"bust":
			return _roulette_payload(slot_id, 0, 0, [], UiText.t("event.result.roulette.empty_title"), UiText.t("event.result.roulette.empty_body"))
		"jackpot":
			return _roulette_payload(slot_id, 18, 0, [], UiText.t("event.result.roulette.small_jackpot_title"), UiText.t("event.result.roulette.small_jackpot_body"))
		"overdrive":
			return _roulette_payload(slot_id, 12, 0, [], UiText.t("event.result.roulette.strong_spin_title"), UiText.t("event.result.roulette.strong_spin_body"))
		_:
			return _roulette_payload(slot_id, 8, 0, [], UiText.t("event.result.roulette.safe_hit_title"), UiText.t("event.result.roulette.safe_hit_body"))

func _risky_roulette_result(slot_id: String) -> Dictionary:
	match slot_id:
		"bust":
			return _roulette_payload(slot_id, 0, -5, [], UiText.t("event.result.roulette.broken_stake_title"), UiText.t("event.result.roulette.broken_stake_body"))
		"jackpot":
			return _roulette_payload(slot_id, 8, 0, _relic_reward_array("risky_roulette_jackpot", RelicCatalog.SOURCE_RISK), UiText.t("event.result.roulette.jackpot_title"), UiText.t("event.result.roulette.jackpot_body"))
		"overdrive":
			return _roulette_payload(slot_id, 20, 0, [], UiText.t("event.result.roulette.smash_title"), UiText.t("event.result.roulette.smash_body"))
		"profit":
			return _roulette_payload(slot_id, 14, 0, [], UiText.t("event.result.roulette.profit_title"), UiText.t("event.result.roulette.profit_body"))
		_:
			return _roulette_payload(slot_id, 6, 0, [], UiText.t("event.result.roulette.safe_slot_title"), UiText.t("event.result.roulette.safe_slot_body"))

func _roulette_payload(slot_id: String, gold_delta: int, hp_delta: int, relic_ids: Array, title: String, body: String) -> Dictionary:
	return {
		"accepted": true,
		"choice": "crooked_wheel_bet",
		"gold_delta": gold_delta,
		"hp_delta": hp_delta,
		"relic_ids": relic_ids,
		"next_combat_mods": [],
		"roulette_slot": slot_id,
		"result_title": title,
		"result_body": body
	}

func _crooked_wheel_leave_result() -> Dictionary:
	return {
		"accepted": true,
		"choice": "crooked_wheel_leave",
		"gold_delta": 3,
		"hp_delta": 0,
		"relic_ids": [],
		"next_combat_mods": [],
		"result_title": UiText.t("event.result.roulette.leave_title"),
		"result_body": UiText.t("event.result.roulette.leave_body")
	}

func _build_card_draw_results(peeked: bool) -> Array[Dictionary]:
	var deck := _card_result_deck(peeked)
	if pending_card_deck_id != "":
		var catalog_deck := EventCatalog.get_card_deck(pending_card_deck_id)
		if not catalog_deck.is_empty():
			deck = _hydrate_catalog_card_deck(catalog_deck)
	var forced := int(map_result.get("card_forced_index", map_result.get("forced_card_index", -1)))
	if forced >= 0 and forced < deck.size():
		var selected := deck[forced]
		deck.remove_at(forced)
		deck.push_front(selected)
	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(map_result.get("card_seed", hash(str(run_state.get("seed_text", "")) + str(map_result.get("node_id", "event")))))
		for i in range(deck.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp := deck[i]
			deck[i] = deck[j]
			deck[j] = tmp
	var result: Array[Dictionary] = []
	for i in range(min(5, deck.size())):
		var entry: Dictionary = deck[i].duplicate(true)
		entry["id"] = "event_card_" + str(i)
		entry["rect"] = CARD_DRAW_RECTS[i]
		result.append(entry)
	return result

func _hydrate_catalog_card_deck(deck: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card in deck:
		var entry := card.duplicate(true)
		var template: Dictionary = entry.get("result_template", {})
		if not template.is_empty():
			entry["result"] = _result_from_template(template, active_event_id)
			entry.erase("result_template")
		if not entry.has("token_color"):
			entry["token_color"] = _card_color_for_kind(str(entry.get("token_kind", "")))
		result.append(entry)
	return result

func _card_color_for_kind(token_kind: String) -> Color:
	match token_kind:
		"blood", "danger":
			return RED
		"heal":
			return Color("#d95f5f")
		"relic":
			return GREEN
		_:
			return GOLD

func _card_result_deck(peeked: bool) -> Array[Dictionary]:
	var safe_relic_id := _next_pool_relic_id(run_state.get("relic_ids", []), "card_deck_safe")
	var risk_relic_id := _next_pool_relic_id(run_state.get("relic_ids", []), "card_deck_blood", RelicCatalog.SOURCE_RISK)
	var safe_relic_reward: Array[String] = []
	if safe_relic_id != "":
		safe_relic_reward.append(safe_relic_id)
	var risk_relic_reward: Array[String] = []
	if risk_relic_id != "":
		risk_relic_reward.append(risk_relic_id)
	var deck: Array[Dictionary] = [
		_card_entry(UiText.t("event.card.coin"), UiText.t("event.card.coin_effect"), GOLD, _card_payload("coin", 10, 0, [], UiText.t("event.card.coin"), UiText.t("event.card.coin_body"))),
		_card_entry(UiText.t("event.card.blood"), UiText.t("event.card.blood_effect"), RED, _card_payload("blood", 0, -3, risk_relic_reward, UiText.t("event.card.blood"), UiText.t("event.card.blood_body"))),
		_card_entry(UiText.t("event.card.pouch"), UiText.t("event.card.pouch_effect"), GREEN, _card_payload("pouch", 6, 0, [], UiText.t("event.card.pouch"), UiText.t("event.card.pouch_body"))),
		_card_entry(UiText.t("event.card.black"), UiText.t("event.card.black_effect"), Color("#3d3b42"), _card_payload("black", 18, 0, [], UiText.t("event.card.black"), UiText.t("event.card.black_body"), [{
			"id": "sealed_black_mark",
			"enemy_damage_delta": 2,
			"description": "Card event: rich payout, sharper next enemy hit."
		}])),
		_card_entry(UiText.t("event.card.heal"), UiText.t("event.card.heal_effect"), Color("#d95f5f"), _card_payload("heal", 0, 5, [], UiText.t("event.card.heal"), UiText.t("event.card.heal_body")))
	]
	if peeked:
		deck.append(_card_entry(UiText.t("event.card.hidden_relic"), UiText.t("event.card.hidden_relic_effect"), GREEN, _card_payload("hidden_relic", 0, 0, safe_relic_reward, UiText.t("event.card.hidden_relic"), UiText.t("event.card.hidden_relic_body"))))
	return deck

func _card_entry(label: String, effect: String, token_color: Color, result: Dictionary) -> Dictionary:
	return {
		"label": label,
		"effect": effect,
		"token_color": token_color,
		"result": result
	}

func _card_payload(card_key: String, gold_delta: int, hp_delta: int, relic_ids: Array, title: String, body: String, mods: Array = []) -> Dictionary:
	return {
		"accepted": true,
		"choice": "sealed_side_box",
		"gold_delta": gold_delta,
		"hp_delta": hp_delta,
		"relic_ids": relic_ids,
		"next_combat_mods": mods,
		"card_key": card_key,
		"card_label": title,
		"result_title": title,
		"result_body": body
	}

func _next_pool_relic_id(existing_ids: Array, salt: String, source_pool: String = RelicCatalog.SOURCE_BASIC) -> String:
	return RelicPoolCatalog.choose_reward_id(existing_ids, {
		"context": RelicPoolCatalog.CONTEXT_EVENT,
		"source_pool": source_pool,
		"character_id": str(run_state.get("character_id", "")),
		"seed_text": str(run_state.get("seed_text", "event")) + "|" + active_event_id + "|" + salt
	})

func _relic_reward_array(salt: String, source_pool: String = RelicCatalog.SOURCE_BASIC) -> Array[String]:
	var relic_id := _next_pool_relic_id(run_state.get("relic_ids", []), salt, source_pool)
	var result: Array[String] = []
	if relic_id != "":
		result.append(relic_id)
	return result

func _relic_source_pool_for_template(template: Dictionary) -> String:
	var explicit := str(template.get("relic_source_pool", ""))
	if explicit != "":
		return explicit
	if int(template.get("hp_delta", 0)) < 0:
		return RelicCatalog.SOURCE_RISK
	for mod in template.get("next_combat_mods", []):
		if mod is Dictionary and int((mod as Dictionary).get("enemy_damage_delta", 0)) > 0:
			return RelicCatalog.SOURCE_RISK
	return RelicCatalog.SOURCE_BASIC

func _sealed_cards_leave_result() -> Dictionary:
	return {
		"accepted": true,
		"choice": "sealed_cards_leave",
		"gold_delta": 5,
		"hp_delta": 0,
		"relic_ids": [],
		"next_combat_mods": [],
		"result_title": UiText.t("event.result.sealed_leave_title"),
		"result_body": UiText.t("event.result.sealed_leave_body")
	}

func _complete_once(result: Dictionary) -> void:
	if submitted:
		return
	submitted = true
	var final_result := _apply_pending_module_cost(result)
	selected_choice = str(final_result.get("choice", ""))
	resolution_result = final_result.duplicate(true)
	module_id = MODULE_RESULT
	choices.clear()
	_rebuild_buttons()
	queue_redraw()
	completed.emit(final_result)

func _apply_pending_module_cost(result: Dictionary) -> Dictionary:
	var final_result := result.duplicate(true)
	if pending_module_gold_delta != 0:
		final_result["gold_delta"] = int(final_result.get("gold_delta", 0)) + pending_module_gold_delta
	if pending_module_hp_delta != 0:
		final_result["hp_delta"] = int(final_result.get("hp_delta", 0)) + pending_module_hp_delta
	pending_module_gold_delta = 0
	pending_module_hp_delta = 0
	pending_dice_result_table.clear()
	pending_roulette_result_table.clear()
	pending_card_deck_id = ""
	return final_result

func _result_title() -> String:
	return str(resolution_result.get("result_title", _choice_label(str(resolution_result.get("choice", "")))))

func _result_body() -> String:
	return str(resolution_result.get("result_body", UiText.t("event.result.default_body")))

func _result_delta_text() -> String:
	var parts: Array[String] = []
	var gold_delta := int(resolution_result.get("gold_delta", 0))
	var hp_delta := int(resolution_result.get("hp_delta", 0))
	var relics: Array = resolution_result.get("relic_ids", [])
	var mods: Array = resolution_result.get("next_combat_mods", [])
	if gold_delta != 0:
		parts.append(UiText.t("event.result.gold", {"delta": ("+" if gold_delta > 0 else "") + str(gold_delta)}))
	if hp_delta != 0:
		parts.append(("+" if hp_delta > 0 else "") + str(hp_delta) + " HP")
	if not relics.is_empty():
		parts.append(UiText.t("event.result.relic", {"relic": RelicCatalog.display_name(str(relics[0]))}))
	if not mods.is_empty():
		parts.append(UiText.t("event.result.next_mod"))
	if parts.is_empty():
		return UiText.t("event.result.no_change")
	return " / ".join(parts)

func _choice_label(choice: String) -> String:
	match choice:
		"event_gold":
			return UiText.t("table.choice.event_gold")
		"event_relic_trade":
			return UiText.t("table.choice.event_relic_trade")
		"event_risk_gold":
			return UiText.t("table.choice.event_risk_gold")
		"backroom_die_test":
			return UiText.t("table.choice.backroom_die_test")
		"backroom_die_leave":
			return UiText.t("table.choice.backroom_die_leave")
		"crooked_wheel_bet":
			return UiText.t("table.choice.crooked_wheel_bet")
		"crooked_wheel_leave":
			return UiText.t("table.choice.crooked_wheel_leave")
		"sealed_side_box":
			return UiText.t("table.choice.sealed_side_box")
		"sealed_cards_leave":
			return UiText.t("table.choice.sealed_cards_leave")
		_:
			var choice_data := _catalog_choice_by_id(choice)
			if not choice_data.is_empty():
				return str(choice_data.get("label", UiText.t("event.result.default_title")))
			return UiText.t("event.result.default_title")

func _configured_event_id() -> String:
	return EventCatalog.configured_event_id(run_state, map_result)

func _rect_for_choice_index(index: int) -> Rect2:
	if module_id == MODULE_STORY_INTRO:
		return _story_continue_rect()
	if module_id == MODULE_DICE_CHECK:
		return DICE_ROLL_RECT
	if module_id == MODULE_ROULETTE_CHECK:
		return ROULETTE_SPIN_RECT
	if module_id == MODULE_CARD_DRAW:
		if index >= 0 and index < card_draw_results.size():
			return card_draw_results[index].get("rect", Rect2())
		return Rect2()
	if index >= 0 and index < BASE_CHOICE_RECTS.size():
		return BASE_CHOICE_RECTS[index]
	return Rect2()

func _story_continue_rect() -> Rect2:
	return Rect2(Vector2(497, 484), Vector2(286, 112))

func _dice_is_busy() -> bool:
	return (dice_layer != null and bool(dice_layer.is_rolling())) or (dice_layer_b != null and bool(dice_layer_b.is_rolling()))

func _roulette_is_busy() -> bool:
	return roulette_layer != null and bool(roulette_layer.is_spinning())

func _module_is_busy() -> bool:
	return _dice_is_busy() or _roulette_is_busy()

func _hover_choice(choice_id: String) -> void:
	if submitted or _module_is_busy():
		return
	hovered_choice = choice_id
	queue_redraw()

func _clear_hover(choice_id: String) -> void:
	if hovered_choice == choice_id:
		hovered_choice = ""
		queue_redraw()

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color, width: float = -1.0) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _draw_wrapped_text(text: String, pos: Vector2, font_size: int, color: Color, width: float, line_height: float, max_lines: int) -> void:
	var lines := _wrap_text_lines(text, width, font_size, max_lines)
	for i in range(lines.size()):
		_draw_text(lines[i], pos + Vector2(0, line_height * float(i)), font_size, color, width)

func _wrap_text_lines(text: String, width: float, font_size: int, max_lines: int) -> Array[String]:
	var clean := text.strip_edges()
	if clean == "":
		return []
	var max_chars: int = maxi(8, int(width / (float(font_size) * 0.68)))
	var words: PackedStringArray = clean.split(" ", false)
	var lines: Array[String] = []
	var current: String = ""
	for word in words:
		var candidate: String = word if current == "" else current + " " + word
		if candidate.length() <= max_chars:
			current = candidate
			continue
		if current != "":
			lines.append(current)
		current = word
		if lines.size() >= max_lines:
			break
	if lines.size() < max_lines and current != "":
		lines.append(current)
	if lines.size() > max_lines:
		lines.resize(max_lines)
	if lines.size() == max_lines and words.size() > 0:
		var last := lines[max_lines - 1]
		if last.length() > max_chars - 1:
			last = last.substr(0, max_chars - 1)
		if not clean.ends_with(last):
			lines[max_lines - 1] = last + "..."
	return lines
