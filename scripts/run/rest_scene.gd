extends Control

signal completed(result: Dictionary)

const RestActionCatalog := preload("res://scripts/systems/rest_action_catalog.gd")
const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const NumericRouletteResolver := preload("res://scripts/systems/numeric_roulette_resolver.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RelicPoolCatalog := preload("res://scripts/systems/relic_pool_catalog.gd")
const RunChoice := preload("res://scripts/run/run_choice.gd")
const RunTableState := preload("res://scripts/run/run_table_state.gd")
const RestActionObjectNode := preload("res://scripts/ui/rest_action_object_node.gd")
const ShopOfferSlotNode := preload("res://scripts/ui/shop_offer_slot_node.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")
const PotionCatalog := preload("res://scripts/systems/potion_catalog.gd")

const BG := Color("#07090f")
const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const GREEN := Color("#65d48e")
const RED := Color("#ee5b5b")
const INK := Color("#090704")

const SCREEN_FRONT := "front"
const SCREEN_UPGRADE := "upgrade"
const SCREEN_EXCHANGE := "exchange"
const SCREEN_ROULETTE_CELL := "roulette_cell"
const UPGRADE_VOUCHER_ID := "upgrade_voucher"
const UPGRADE_VOUCHER_COSTS := {
	"upgrade_primary_die": 2,
	"upgrade_secondary_die": 2,
	"upgrade_roulette": 1
}
const RANDOM_POTION_IDS := PotionCatalog.RANDOM_POOL

const FRONT_RECTS := {
	"rest_heal": Rect2(Vector2(150, 128), Vector2(320, 506)),
	"rest_tune": Rect2(Vector2(480, 128), Vector2(320, 506)),
	"rest_relic": Rect2(Vector2(810, 128), Vector2(320, 506))
}

const UPGRADE_RECTS := {
	"upgrade_primary_die": Rect2(Vector2(132, 128), Vector2(314, 224)),
	"upgrade_secondary_die": Rect2(Vector2(132, 368), Vector2(314, 224)),
	"upgrade_roulette": Rect2(Vector2(474, 128), Vector2(354, 466)),
	"upgrade_roulette_cell": Rect2(Vector2(836, 128), Vector2(354, 466))
}

const FRONT_LABEL_RECTS := {
	"rest_heal": Rect2(Vector2(178, 150), Vector2(270, 96)),
	"rest_tune": Rect2(Vector2(508, 150), Vector2(270, 96)),
	"rest_relic": Rect2(Vector2(838, 150), Vector2(270, 96))
}

const UPGRADE_LABEL_RECTS := {
	"upgrade_primary_die": Rect2(Vector2(174, 150), Vector2(250, 76)),
	"upgrade_secondary_die": Rect2(Vector2(174, 390), Vector2(250, 76)),
	"upgrade_roulette": Rect2(Vector2(526, 150), Vector2(286, 96)),
	"upgrade_roulette_cell": Rect2(Vector2(888, 150), Vector2(286, 96))
}

const UPGRADE_DIE_SOURCE_RECT := Rect2(Vector2(112, 128), Vector2(354, 466))
const ROULETTE_CELL_WHEEL_CENTER := Vector2(640, 350)
const ROULETTE_CELL_WHEEL_RADIUS := 216.0
const ROULETTE_CELL_LABEL_RADIUS := 158.0
const ROULETTE_CELL_COST_RADIUS := 254.0

const BACK_RECT := Rect2(Vector2(152, 640), Vector2(140, 44))
const RESULT_RECT := Rect2(Vector2(352, 628), Vector2(468, 58))
const UPGRADE_VOUCHER_RECT := Rect2(Vector2(846, 640), Vector2(170, 44))
const UPGRADE_FINISH_RECT := Rect2(Vector2(1030, 640), Vector2(148, 44))
const TICKET_EXCHANGE_RECT := Rect2(Vector2(912, 42), Vector2(218, 52))
const EXCHANGE_STATUS_RECT := Rect2(Vector2(230, 122), Vector2(820, 70))
const EXCHANGE_CHOICE_RECTS := [
	Rect2(Vector2(276, 238), Vector2(144, 318)),
	Rect2(Vector2(444, 238), Vector2(144, 318)),
	Rect2(Vector2(612, 238), Vector2(144, 318)),
	Rect2(Vector2(780, 238), Vector2(144, 318))
]
const EXCHANGE_SLOT_RECTS := [
	Rect2(Vector2(280, 260), Vector2(136, 190)),
	Rect2(Vector2(448, 260), Vector2(136, 190)),
	Rect2(Vector2(616, 260), Vector2(136, 190)),
	Rect2(Vector2(784, 260), Vector2(136, 190))
]
const EXCHANGE_TAG_RECTS := [
	Rect2(Vector2(266, 500), Vector2(164, 44)),
	Rect2(Vector2(434, 500), Vector2(164, 44)),
	Rect2(Vector2(602, 500), Vector2(164, 44)),
	Rect2(Vector2(770, 500), Vector2(164, 44))
]
const EXCHANGE_DONE_RECT := Rect2(Vector2(988, 640), Vector2(170, 44))

var run_state: Dictionary = {}
var map_result: Dictionary = {}
var buttons: Array[Button] = []
var back_button: Button
var exchange_button: Button
var exchange_done_button: Button
var upgrade_voucher_button: Button
var upgrade_finish_button: Button
var choices: Array[Dictionary] = []
var resolution_result: Dictionary = {}
var upgrade_result: Dictionary = {}
var exchange_result: Dictionary = {}
var purchased_exchange_ids: Array[String] = []
var selected_choice := ""
var last_upgrade_choice := ""
var screen_id := SCREEN_FRONT
var submitted := false
var local_tickets := 0
var upgrade_can_choose := true

func configure(payload: Dictionary) -> void:
	run_state = payload.get("run_state", {}).duplicate(true)
	map_result = payload.get("map_result", {}).duplicate(true)
	local_tickets = int(run_state.get("contract_tickets", 0))
	upgrade_result = {}
	exchange_result = _empty_exchange_result()
	purchased_exchange_ids.clear()
	last_upgrade_choice = ""
	upgrade_can_choose = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rebuild_buttons()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	_draw_background()
	if screen_id == SCREEN_EXCHANGE:
		_draw_exchange_counter()
	elif screen_id == SCREEN_ROULETTE_CELL:
		_draw_roulette_cell_upgrade_screen()
	_draw_result_strip()

func _draw_background() -> void:
	if screen_id == SCREEN_EXCHANGE:
		var exchange_texture := AssetCatalog.rest_runtime_texture("ticket_exchange_shop")
		if exchange_texture != null:
			draw_texture_rect(exchange_texture, Rect2(Vector2.ZERO, size), false)
			return
	var texture_id := "room_background_clean" if screen_id == SCREEN_ROULETTE_CELL else ("upgrade_direction_lock" if screen_id == SCREEN_UPGRADE else "front_direction_lock")
	var texture := AssetCatalog.rest_runtime_texture(texture_id)
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
		return
	texture = AssetCatalog.rest_runtime_texture("room_background_clean")
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
		return
	UiSkin.draw_table_stage(self)

func _draw_result_strip() -> void:
	if screen_id == SCREEN_EXCHANGE:
		_draw_exchange_status()
		return
	if not _has_resolved_action():
		if screen_id == SCREEN_UPGRADE:
			_draw_upgrade_status()
		elif screen_id == SCREEN_ROULETTE_CELL:
			_draw_roulette_cell_status()
		return
	draw_rect(RESULT_RECT, Color("#2a1b10", 0.82), true)
	draw_rect(RESULT_RECT, Color(GOLD, 0.48), false, 2.0)
	_draw_text(_result_summary_text(), RESULT_RECT.position + Vector2(18, 35), 18, TEXT)

func _result_summary_text() -> String:
	match selected_choice:
		"rest_heal":
			return UiText.t("rest.result.heal", {"amount": int(resolution_result.get("hp_delta", 0))})
		"rest_relic":
			return UiText.t("rest.result.relic", {"relic": RelicCatalog.display_name(str((resolution_result.get("relic_ids", [""]) as Array)[0]))})
		"upgrade_primary_die":
			return UiText.t("rest.result.primary")
		"upgrade_secondary_die":
			return UiText.t("rest.result.secondary")
		"upgrade_roulette":
			return UiText.t("rest.result.roulette")
		"upgrade_roulette_cell":
			return UiText.t("rest.result.roulette_cell", {
				"from": NumericRouletteResolver.multiplier_label(float(resolution_result.get("roulette_cell_from", 0.0))),
				"to": NumericRouletteResolver.multiplier_label(float(resolution_result.get("roulette_cell_to", 0.0)))
			})
		"rest_ticket_exchange":
			return UiText.t("rest.result.exchange", {
				"tickets": abs(int(resolution_result.get("contract_tickets_delta", 0))),
				"potions": (resolution_result.get("potion_ids", []) as Array).size()
			})
		_:
			return UiText.t("rest.result.done")

func _rebuild_buttons() -> void:
	for button in buttons:
		button.queue_free()
	buttons.clear()
	if back_button != null:
		back_button.queue_free()
		back_button = null
	if exchange_button != null:
		exchange_button.queue_free()
		exchange_button = null
	if exchange_done_button != null:
		exchange_done_button.queue_free()
		exchange_done_button = null
	if upgrade_voucher_button != null:
		upgrade_voucher_button.queue_free()
		upgrade_voucher_button = null
	if upgrade_finish_button != null:
		upgrade_finish_button.queue_free()
		upgrade_finish_button = null

	choices = _visible_choice_data()
	if _has_resolved_action():
		for i in range(choices.size()):
			var choice_id := str(choices[i].get("id", ""))
			choices[i]["state"] = RunChoice.state_after_submit(choice_id, selected_choice)
			choices[i]["enabled"] = false
	for i in range(choices.size()):
		var choice := choices[i]
		var choice_id := str(choice.get("id", ""))
		var rect := get_choice_rect(choice_id)
		var button: Button
		if screen_id == SCREEN_EXCHANGE:
			button = _build_exchange_offer_button(choice, choice_id, rect)
		else:
			var rest_button := RestActionObjectNode.new()
			rest_button.configure_action(
				choice,
				rect,
				_source_texture_id_for_choice(choice_id),
				_source_rect_for_choice(choice_id),
				get_label_rect(choice_id)
			)
			button = rest_button
		button.pressed.connect(_choose_by_id.bind(choice_id))
		add_child(button)
		buttons.append(button)

	if screen_id == SCREEN_UPGRADE and not _has_resolved_action():
		back_button = Button.new()
		back_button.text = UiText.t("rest.back")
		back_button.position = BACK_RECT.position
		back_button.size = BACK_RECT.size
		back_button.disabled = _has_pending_upgrade_result()
		UiSkin.apply_button(back_button, false)
		back_button.pressed.connect(_back_to_front)
		add_child(back_button)
		if _has_pending_upgrade_result():
			upgrade_voucher_button = _plain_button(
				UiText.t("rest.upgrade.use_voucher", {"count": _upgrade_voucher_count()}),
				UPGRADE_VOUCHER_RECT,
				_use_upgrade_voucher,
				_upgrade_voucher_count() > 0 and not upgrade_can_choose
			)
			add_child(upgrade_voucher_button)
			upgrade_finish_button = _plain_button(UiText.t("rest.upgrade.finish"), UPGRADE_FINISH_RECT, _finish_upgrade_bundle, not upgrade_can_choose)
			add_child(upgrade_finish_button)
	elif screen_id == SCREEN_EXCHANGE and not _has_resolved_action():
		back_button = _plain_button(UiText.t("rest.back"), BACK_RECT, _back_to_front, not _has_exchange_purchases())
		add_child(back_button)
		exchange_done_button = _plain_button(UiText.t("rest.exchange.done"), EXCHANGE_DONE_RECT, _leave_exchange, _has_exchange_purchases())
		add_child(exchange_done_button)
	elif screen_id == SCREEN_ROULETTE_CELL and not _has_resolved_action():
		back_button = _plain_button(UiText.t("rest.back"), BACK_RECT, _back_to_upgrade, true)
		add_child(back_button)
		_add_roulette_cell_buttons()
	elif screen_id == SCREEN_FRONT and not _has_resolved_action():
		exchange_button = _plain_button(UiText.t("rest.exchange.open"), TICKET_EXCHANGE_RECT, _open_ticket_exchange, true)
		add_child(exchange_button)

func _plain_button(text: String, rect: Rect2, callback: Callable, enabled: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = text
	button.position = rect.position
	button.size = rect.size
	button.disabled = not enabled
	UiSkin.apply_button(button, enabled)
	button.pressed.connect(callback)
	return button

func _add_roulette_cell_buttons() -> void:
	var upgrades: Dictionary = run_state.get("run_upgrades", {})
	var vouchers := _upgrade_voucher_count()
	for i in range(NumericRouletteResolver.cell_count()):
		var cost := NumericRouletteResolver.upgrade_cost_for_index(i, upgrades)
		var enabled := cost > 0 and vouchers >= cost
		var button := Button.new()
		button.name = "RunChoice_upgrade_roulette_cell_" + str(i)
		button.tooltip_text = _roulette_cell_tooltip(i, cost)
		button.position = _roulette_cell_button_rect(i).position
		button.size = _roulette_cell_button_rect(i).size
		button.disabled = not enabled
		button.focus_mode = Control.FOCUS_NONE
		_make_transparent_button(button)
		button.pressed.connect(_choose_roulette_cell.bind(i))
		add_child(button)
		buttons.append(button)

func _make_transparent_button(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("disabled", empty)
	button.add_theme_stylebox_override("focus", empty)

func _build_exchange_offer_button(choice: Dictionary, choice_id: String, rect: Rect2) -> Button:
	var button := ShopOfferSlotNode.new()
	button.name = "RunChoice_" + choice_id
	button.configure_offer(choice, _exchange_metadata(choice), rect, _exchange_slot_rect_for_choice(choice_id), get_price_tag_rect(choice_id))
	button.disabled = not RunChoice.is_interactive(choice)
	return button

func get_choice_controls() -> Array[Button]:
	return buttons

func get_choice_rect(choice_id: String) -> Rect2:
	if FRONT_RECTS.has(choice_id):
		return FRONT_RECTS[choice_id]
	if UPGRADE_RECTS.has(choice_id):
		return UPGRADE_RECTS[choice_id]
	if choice_id == "rest_ticket_exchange":
		return TICKET_EXCHANGE_RECT
	var exchange_index := RestActionCatalog.exchange_ids().find(choice_id)
	if exchange_index >= 0 and exchange_index < EXCHANGE_CHOICE_RECTS.size():
		return EXCHANGE_CHOICE_RECTS[exchange_index]
	return Rect2()

func get_label_rect(choice_id: String) -> Rect2:
	if FRONT_LABEL_RECTS.has(choice_id):
		return FRONT_LABEL_RECTS[choice_id]
	if UPGRADE_LABEL_RECTS.has(choice_id):
		return UPGRADE_LABEL_RECTS[choice_id]
	return Rect2()

func get_price_tag_rect(choice_id: String) -> Rect2:
	var exchange_index := RestActionCatalog.exchange_ids().find(choice_id)
	if exchange_index >= 0 and exchange_index < EXCHANGE_TAG_RECTS.size():
		return EXCHANGE_TAG_RECTS[exchange_index]
	return Rect2()

func get_table_state() -> Dictionary:
	return RunTableState.from_run_payload(run_state, resolution_result)

func get_pickup_summary() -> Dictionary:
	return get_table_state().get("pickup", {})

func _visible_choice_data() -> Array[Dictionary]:
	if screen_id == SCREEN_UPGRADE:
		return _upgrade_choice_data()
	if screen_id == SCREEN_EXCHANGE:
		return _exchange_choice_data()
	if screen_id == SCREEN_ROULETTE_CELL:
		return []
	return _front_choice_data()

func _front_choice_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for action in RestActionCatalog.choices():
		var action_id := str(action.get("id", ""))
		var enabled := _can_select_choice(action_id)
		result.append(RunChoice.create(
			action_id,
			str(action.get("label", action_id)),
			str(action.get("note", "")),
			str(action.get("effect", "")),
			(action.get("result", {}) as Dictionary),
			RunChoice.STATE_NORMAL if enabled else RunChoice.STATE_DISABLED,
			enabled
		))
	return result

func _upgrade_choice_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for action in RestActionCatalog.upgrade_choices():
		var action_id := str(action.get("id", ""))
		var enabled := not _has_resolved_action() and upgrade_can_choose and _can_select_upgrade_choice(action_id)
		var state := RunChoice.STATE_NORMAL if enabled else RunChoice.STATE_DISABLED
		if _has_pending_upgrade_result() and not upgrade_can_choose and action_id == last_upgrade_choice:
			state = RunChoice.STATE_CHOSEN
		var effect := str(action.get("effect", ""))
		var cost := _upgrade_voucher_cost(action_id)
		if action_id == "upgrade_roulette_cell":
			effect = str(action.get("effect", ""))
		elif cost > 0:
			effect = UiText.t("rest.upgrade.effect_cost", {"effect": effect, "count": cost})
		else:
			effect = UiText.t("rest.upgrade.effect_free", {"effect": effect})
		result.append(RunChoice.create(
			action_id,
			str(action.get("label", action_id)),
			str(action.get("note", "")),
			effect,
			(action.get("result", {}) as Dictionary),
			state,
			enabled
		))
	return result

func _exchange_choice_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for action in RestActionCatalog.exchange_choices():
		var action_id := str(action.get("id", ""))
		var enabled := _can_select_exchange(action)
		var choice := RunChoice.create(
			action_id,
			str(action.get("label", action_id)),
			str(action.get("note", "")),
			str(action.get("effect", "")),
			(action.get("result", {}) as Dictionary),
			RunChoice.STATE_NORMAL if enabled else RunChoice.STATE_UNAFFORDABLE,
			enabled
		)
		choice["slot_kind"] = str(action.get("slot_kind", "service"))
		choice["icon_id"] = str(action.get("icon_id", ""))
		choice["badge_id"] = str(action.get("badge_id", ""))
		choice["price"] = int(action.get("price", _ticket_price_for_result(choice.get("result", {}))))
		choice["currency"] = "ticket"
		if purchased_exchange_ids.has(action_id) and not _is_repeatable_exchange(action_id):
			choice["state"] = RunChoice.STATE_SOLD
			choice["enabled"] = false
		result.append(choice)
	return result

func _choose_by_id(choice_id: String) -> void:
	if not _can_select_choice(choice_id):
		return
	if RestActionCatalog.exchange_ids().has(choice_id):
		_commit_exchange_purchase(choice_id)
		return
	if choice_id == "rest_tune":
		screen_id = SCREEN_UPGRADE
		upgrade_can_choose = true
		_rebuild_buttons()
		queue_redraw()
		return
	if choice_id == "upgrade_roulette_cell":
		_open_roulette_cell_upgrade()
		return
	if RestActionCatalog.upgrade_ids().has(choice_id):
		_commit_upgrade_choice(choice_id)
		return
	if choice_id == "rest_relic":
		_resolve_action(_relic_result())
		return
	_resolve_action(RestActionCatalog.result(choice_id))

func _resolve_action(result: Dictionary) -> void:
	if submitted or _has_resolved_action():
		return
	var final_result := _result_with_exchange(result)
	submitted = true
	selected_choice = str(final_result.get("choice", ""))
	resolution_result = final_result.duplicate(true)
	_rebuild_buttons()
	queue_redraw()
	completed.emit(resolution_result)

func _heal() -> void:
	_choose_by_id("rest_heal")

func _heal_result() -> Dictionary:
	return RestActionCatalog.result("rest_heal")

func _prepare() -> void:
	screen_id = SCREEN_ROULETTE_CELL
	_choose_first_affordable_roulette_cell()

func _prepare_result() -> Dictionary:
	return _roulette_cell_result(1)

func _choose_upgrade(choice_id: String) -> void:
	screen_id = SCREEN_UPGRADE
	_choose_by_id(choice_id)

func _choose_relic() -> void:
	_choose_by_id("rest_relic")

func _leave() -> void:
	if not _has_resolved_action():
		return
	completed.emit(resolution_result)

func _leave_result() -> Dictionary:
	return {
		"accepted": true,
		"choice": "rest_leave",
		"gold_delta": 0,
		"hp_delta": 0,
		"relic_ids": [],
		"next_combat_mods": [],
		"run_upgrades": {}
	}

func _choose_default() -> void:
	_choose_by_id("rest_tune")
	_choose_upgrade("upgrade_roulette_cell")
	_choose_first_affordable_roulette_cell()

func _can_select_choice(choice_id: String) -> bool:
	if _has_resolved_action():
		return false
	if choice_id == "rest_ticket_exchange":
		return true
	if RestActionCatalog.exchange_ids().has(choice_id):
		return _can_select_exchange_by_id(choice_id)
	if RestActionCatalog.upgrade_ids().has(choice_id):
		return upgrade_can_choose and _can_select_upgrade_choice(choice_id)
	if choice_id == "rest_heal":
		return int(run_state.get("player_hp", run_state.get("player_max_hp", 42))) < int(run_state.get("player_max_hp", 42))
	return RestActionCatalog.action_ids().has(choice_id) or RestActionCatalog.upgrade_ids().has(choice_id)

func _commit_upgrade_choice(choice_id: String) -> void:
	if choice_id == "upgrade_roulette_cell":
		_open_roulette_cell_upgrade()
		return
	var result := RestActionCatalog.result(choice_id)
	if result.is_empty():
		return
	var voucher_cost := _upgrade_voucher_cost(choice_id)
	if not _can_pay_upgrade_voucher_cost(choice_id):
		return
	if not _has_pending_upgrade_result() and _upgrade_voucher_count() <= 0:
		_resolve_action(result)
		return
	if not upgrade_can_choose:
		return
	var removed_vouchers := _consume_upgrade_vouchers(voucher_cost)
	if removed_vouchers.size() < voucher_cost:
		return
	if not removed_vouchers.is_empty():
		result["remove_potion_ids"] = _merged_strings(result.get("remove_potion_ids", []), removed_vouchers)
	_accumulate_upgrade_result(result)
	_apply_upgrade_to_local_inventory(result)
	last_upgrade_choice = choice_id
	if str(upgrade_result.get("choice", "")) == "":
		upgrade_result["choice"] = choice_id
	selected_choice = str(upgrade_result.get("choice", choice_id))
	upgrade_can_choose = false
	_rebuild_buttons()
	queue_redraw()

func _accumulate_upgrade_result(result: Dictionary) -> void:
	if upgrade_result.is_empty():
		upgrade_result = _empty_upgrade_result(str(result.get("choice", "")))
	var upgrades: Dictionary = upgrade_result.get("run_upgrades", {})
	for key in (result.get("run_upgrades", {}) as Dictionary).keys():
		var id := str(key)
		upgrades[id] = float(upgrades.get(id, 0.0)) + float((result.get("run_upgrades", {}) as Dictionary).get(key, 0.0))
	upgrade_result["run_upgrades"] = upgrades
	upgrade_result["remove_potion_ids"] = _merged_strings(
		upgrade_result.get("remove_potion_ids", []),
		result.get("remove_potion_ids", result.get("potion_ids_remove", []))
	)

func _apply_upgrade_to_local_inventory(result: Dictionary) -> void:
	var upgrades: Dictionary = run_state.get("run_upgrades", {})
	for key in (result.get("run_upgrades", {}) as Dictionary).keys():
		var id := str(key)
		upgrades[id] = float(upgrades.get(id, 0.0)) + float((result.get("run_upgrades", {}) as Dictionary).get(key, 0.0))
	run_state["run_upgrades"] = upgrades

func _use_upgrade_voucher() -> void:
	if screen_id != SCREEN_UPGRADE or not _has_pending_upgrade_result() or upgrade_can_choose:
		return
	if not _remove_local_potion(UPGRADE_VOUCHER_ID):
		return
	var removed: Array = upgrade_result.get("remove_potion_ids", [])
	removed.append(UPGRADE_VOUCHER_ID)
	upgrade_result["remove_potion_ids"] = removed
	upgrade_can_choose = true
	last_upgrade_choice = ""
	_rebuild_buttons()
	queue_redraw()

func _finish_upgrade_bundle() -> void:
	if not _has_pending_upgrade_result() or upgrade_can_choose:
		return
	_resolve_action(upgrade_result)

func _empty_upgrade_result(choice_id: String) -> Dictionary:
	return {
		"accepted": true,
		"choice": choice_id,
		"gold_delta": 0,
		"hp_delta": 0,
		"contract_tickets_delta": 0,
		"relic_ids": [],
		"next_combat_mods": [],
		"run_upgrades": {},
		"potion_ids": [],
		"remove_potion_ids": []
	}

func _has_pending_upgrade_result() -> bool:
	return not upgrade_result.is_empty()

func _upgrade_voucher_count() -> int:
	var count := 0
	for potion_id in run_state.get("potion_ids", []):
		if str(potion_id) == UPGRADE_VOUCHER_ID:
			count += 1
	return count

func _upgrade_voucher_cost(choice_id: String) -> int:
	return int(UPGRADE_VOUCHER_COSTS.get(choice_id, 0))

func _can_pay_upgrade_voucher_cost(choice_id: String) -> bool:
	return _upgrade_voucher_count() >= _upgrade_voucher_cost(choice_id)

func _can_select_upgrade_choice(choice_id: String) -> bool:
	if choice_id == "upgrade_roulette_cell":
		return _can_afford_any_roulette_cell_upgrade()
	return _can_pay_upgrade_voucher_cost(choice_id)

func _can_afford_any_roulette_cell_upgrade() -> bool:
	var upgrades: Dictionary = run_state.get("run_upgrades", {})
	var vouchers := _upgrade_voucher_count()
	for i in range(NumericRouletteResolver.cell_count()):
		if NumericRouletteResolver.can_upgrade_index(i, upgrades, vouchers):
			return true
	return false

func _consume_upgrade_vouchers(count: int) -> Array[String]:
	var removed: Array[String] = []
	for i in range(max(0, count)):
		if not _remove_local_potion(UPGRADE_VOUCHER_ID):
			break
		removed.append(UPGRADE_VOUCHER_ID)
	return removed

func _remove_local_potion(potion_id: String) -> bool:
	var potion_ids: Array = run_state.get("potion_ids", [])
	if not potion_ids.has(potion_id):
		return false
	potion_ids.erase(potion_id)
	run_state["potion_ids"] = potion_ids
	run_state["potion_slots_used"] = potion_ids.size()
	return true

func _open_ticket_exchange() -> void:
	if _has_resolved_action():
		return
	screen_id = SCREEN_EXCHANGE
	_rebuild_buttons()
	queue_redraw()

func _leave_exchange() -> void:
	screen_id = SCREEN_FRONT
	_rebuild_buttons()
	queue_redraw()

func _commit_exchange_purchase(choice_id: String) -> void:
	if submitted or screen_id != SCREEN_EXCHANGE:
		return
	if purchased_exchange_ids.has(choice_id) and not _is_repeatable_exchange(choice_id):
		return
	var result := _resolved_exchange_result(choice_id)
	if not _result_is_exchange_affordable(result):
		return
	purchased_exchange_ids.append(choice_id)
	local_tickets = max(0, local_tickets + int(result.get("contract_tickets_delta", 0)))
	run_state["contract_tickets"] = local_tickets
	_accumulate_exchange_result(result)
	_apply_exchange_to_local_inventory(result)
	_rebuild_buttons()
	queue_redraw()

func _can_select_exchange(action: Dictionary) -> bool:
	var action_id := str(action.get("id", ""))
	return _result_is_exchange_affordable(_resolved_exchange_result(action_id)) and (_is_repeatable_exchange(action_id) or not purchased_exchange_ids.has(action_id))

func _can_select_exchange_by_id(choice_id: String) -> bool:
	if purchased_exchange_ids.has(choice_id) and not _is_repeatable_exchange(choice_id):
		return false
	return _result_is_exchange_affordable(_resolved_exchange_result(choice_id))

func _is_repeatable_exchange(choice_id: String) -> bool:
	return choice_id == "ticket_upgrade_voucher"

func _result_is_exchange_affordable(result: Dictionary) -> bool:
	if result.is_empty():
		return false
	if local_tickets + int(result.get("contract_tickets_delta", 0)) < 0:
		return false
	var incoming_potions: Array = result.get("potion_ids", [])
	var potion_ids: Array = run_state.get("potion_ids", [])
	var max_slots := int(run_state.get("potion_slots_max", 2))
	if potion_ids.size() + incoming_potions.size() > max_slots:
		return false
	var incoming_relics: Array = result.get("relic_ids", [])
	if bool(result.get("random_relic", false)) and incoming_relics.is_empty():
		return false
	var hp_after := int(run_state.get("player_hp", 1)) + int(result.get("hp_delta", 0))
	return hp_after > 0

func _has_exchange_purchases() -> bool:
	return purchased_exchange_ids.size() > 0

func _empty_exchange_result() -> Dictionary:
	return {
		"accepted": true,
		"choice": "rest_ticket_exchange",
		"gold_delta": 0,
		"hp_delta": 0,
		"contract_tickets_delta": 0,
		"relic_ids": [],
		"next_combat_mods": [],
		"run_upgrades": {},
		"potion_ids": []
	}

func _result_with_exchange(result: Dictionary) -> Dictionary:
	var final_result := result.duplicate(true)
	if not _has_exchange_purchases():
		return final_result
	final_result["gold_delta"] = int(final_result.get("gold_delta", 0)) + int(exchange_result.get("gold_delta", 0))
	final_result["hp_delta"] = int(final_result.get("hp_delta", 0)) + int(exchange_result.get("hp_delta", 0))
	final_result["contract_tickets_delta"] = int(final_result.get("contract_tickets_delta", final_result.get("ticket_delta", 0))) + int(exchange_result.get("contract_tickets_delta", 0))
	final_result["relic_ids"] = _merged_unique_strings(final_result.get("relic_ids", []), exchange_result.get("relic_ids", []))
	final_result["potion_ids"] = _merged_strings(final_result.get("potion_ids", []), exchange_result.get("potion_ids", []))
	final_result["remove_potion_ids"] = _merged_strings(final_result.get("remove_potion_ids", final_result.get("potion_ids_remove", [])), exchange_result.get("remove_potion_ids", exchange_result.get("potion_ids_remove", [])))
	final_result["next_combat_mods"] = _merged_dictionaries(final_result.get("next_combat_mods", []), exchange_result.get("next_combat_mods", []))
	final_result["run_upgrades"] = _merged_upgrades(final_result.get("run_upgrades", {}), exchange_result.get("run_upgrades", {}))
	return final_result

func _merged_unique_strings(first: Array, second: Array) -> Array[String]:
	var result: Array[String] = []
	for value in first:
		var id := str(value)
		if id != "" and not result.has(id):
			result.append(id)
	for value in second:
		var id := str(value)
		if id != "" and not result.has(id):
			result.append(id)
	return result

func _merged_strings(first: Array, second: Array) -> Array[String]:
	var result: Array[String] = []
	for value in first:
		var id := str(value)
		if id != "":
			result.append(id)
	for value in second:
		var id := str(value)
		if id != "":
			result.append(id)
	return result

func _merged_dictionaries(first: Array, second: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in first:
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	for value in second:
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result

func _merged_upgrades(first: Dictionary, second: Dictionary) -> Dictionary:
	var result := first.duplicate(true)
	for key in second.keys():
		var id := str(key)
		result[id] = float(result.get(id, 0.0)) + float(second.get(key, 0.0))
	return result

func _accumulate_exchange_result(result: Dictionary) -> void:
	exchange_result["contract_tickets_delta"] = int(exchange_result.get("contract_tickets_delta", 0)) + int(result.get("contract_tickets_delta", 0))
	exchange_result["hp_delta"] = int(exchange_result.get("hp_delta", 0)) + int(result.get("hp_delta", 0))
	var relic_ids: Array = exchange_result.get("relic_ids", [])
	for relic_id in result.get("relic_ids", []):
		var id := str(relic_id)
		if id != "" and not relic_ids.has(id):
			relic_ids.append(id)
	exchange_result["relic_ids"] = relic_ids
	var potions: Array = exchange_result.get("potion_ids", [])
	for potion_id in result.get("potion_ids", []):
		var id := str(potion_id)
		if id != "":
			potions.append(id)
	exchange_result["potion_ids"] = potions

func _apply_exchange_to_local_inventory(result: Dictionary) -> void:
	var relic_ids: Array = run_state.get("relic_ids", [])
	for relic_id in result.get("relic_ids", []):
		var relic := str(relic_id)
		if relic != "" and not relic_ids.has(relic):
			relic_ids.append(relic)
	run_state["relic_ids"] = relic_ids
	var potion_ids: Array = run_state.get("potion_ids", [])
	var max_slots := int(run_state.get("potion_slots_max", 2))
	for potion_id in result.get("potion_ids", []):
		if potion_ids.size() >= max_slots:
			break
		var id := str(potion_id)
		if id != "":
			potion_ids.append(id)
	run_state["potion_ids"] = potion_ids
	run_state["potion_slots_used"] = potion_ids.size()
	run_state["player_hp"] = clamp(
		int(run_state.get("player_hp", 1)) + int(result.get("hp_delta", 0)),
		0,
		int(run_state.get("player_max_hp", 42))
	)

func _resolved_exchange_result(choice_id: String) -> Dictionary:
	var result := RestActionCatalog.result(choice_id)
	if result.is_empty():
		return result
	result.erase("random_potion")
	result.erase("random_relic")
	match choice_id:
		"ticket_random_potion":
			result["potion_ids"] = [_random_potion_id(choice_id)]
		"ticket_random_relic":
			var relic_id := _random_exchange_relic_id(choice_id)
			result["relic_ids"] = [relic_id] if relic_id != "" else []
	return result

func _random_potion_id(choice_id: String) -> String:
	if RANDOM_POTION_IDS.is_empty():
		return PotionCatalog.PURPLE_JACKPOT
	var index: int = abs(int(hash(_exchange_seed(choice_id)))) % RANDOM_POTION_IDS.size()
	return str(RANDOM_POTION_IDS[index])

func _random_exchange_relic_id(choice_id: String) -> String:
	return RelicPoolCatalog.choose_reward_id(run_state.get("relic_ids", []), {
		"context": RelicPoolCatalog.CONTEXT_REST,
		"source_pool": RelicCatalog.SOURCE_BASIC,
		"character_id": str(run_state.get("character_id", "")),
		"seed_text": _exchange_seed(choice_id)
	})

func _exchange_seed(choice_id: String) -> String:
	return str(run_state.get("seed_text", "rest")) + "|ticket_exchange|" + choice_id + "|" + str(purchased_exchange_ids.size())

func _ticket_price_for_result(result_value: Variant) -> int:
	if result_value is Dictionary:
		return abs(int((result_value as Dictionary).get("contract_tickets_delta", 0)))
	return 0

func _exchange_metadata(choice: Dictionary) -> Dictionary:
	return {
		"kind": str(choice.get("slot_kind", "service")),
		"price": int(choice.get("price", _ticket_price_for_result(choice.get("result", {})))),
		"currency": "ticket",
		"icon_id": str(choice.get("icon_id", "")),
		"badge_id": str(choice.get("badge_id", "")),
		"object_texture_id": str(choice.get("object_texture_id", ""))
	}

func _exchange_slot_rect_for_choice(choice_id: String) -> Rect2:
	var exchange_index := RestActionCatalog.exchange_ids().find(choice_id)
	if exchange_index >= 0 and exchange_index < EXCHANGE_SLOT_RECTS.size():
		return EXCHANGE_SLOT_RECTS[exchange_index]
	return Rect2()

func _relic_result() -> Dictionary:
	var relic_id := RelicPoolCatalog.choose_reward_id(run_state.get("relic_ids", []), {
		"context": RelicPoolCatalog.CONTEXT_REST,
		"source_pool": RelicCatalog.SOURCE_BASIC,
		"character_id": str(run_state.get("character_id", "")),
		"seed_text": str(run_state.get("seed_text", "rest")) + "|rest"
	})
	return {
		"accepted": true,
		"choice": "rest_relic",
		"gold_delta": 0,
		"hp_delta": 0,
		"relic_ids": [relic_id] if relic_id != "" else [],
		"next_combat_mods": [],
		"run_upgrades": {}
	}

func _has_resolved_action() -> bool:
	return not resolution_result.is_empty()

func _back_to_front() -> void:
	if _has_resolved_action() or (screen_id == SCREEN_EXCHANGE and _has_exchange_purchases()) or (screen_id == SCREEN_UPGRADE and _has_pending_upgrade_result()):
		return
	screen_id = SCREEN_FRONT
	_rebuild_buttons()
	queue_redraw()

func _back_to_upgrade() -> void:
	if _has_resolved_action():
		return
	screen_id = SCREEN_UPGRADE
	_rebuild_buttons()
	queue_redraw()

func _open_roulette_cell_upgrade() -> void:
	if _has_resolved_action() or not _can_afford_any_roulette_cell_upgrade():
		return
	screen_id = SCREEN_ROULETTE_CELL
	_rebuild_buttons()
	queue_redraw()

func _choose_first_affordable_roulette_cell() -> void:
	var upgrades: Dictionary = run_state.get("run_upgrades", {})
	var vouchers := _upgrade_voucher_count()
	for i in range(NumericRouletteResolver.cell_count()):
		if NumericRouletteResolver.can_upgrade_index(i, upgrades, vouchers):
			_choose_roulette_cell(i)
			return

func _choose_roulette_cell(index: int) -> void:
	if _has_resolved_action() or submitted:
		return
	var upgrades: Dictionary = run_state.get("run_upgrades", {})
	var cost := NumericRouletteResolver.upgrade_cost_for_index(index, upgrades)
	if cost <= 0 or _upgrade_voucher_count() < cost:
		return
	var removed_vouchers := _consume_upgrade_vouchers(cost)
	if removed_vouchers.size() < cost:
		return
	_resolve_action(_roulette_cell_result(index, removed_vouchers))

func _roulette_cell_result(index: int, removed_vouchers: Array[String] = []) -> Dictionary:
	var upgrades: Dictionary = run_state.get("run_upgrades", {})
	var from_multiplier := NumericRouletteResolver.multiplier_for_index(index, upgrades)
	var to_multiplier := NumericRouletteResolver.upgraded_multiplier(from_multiplier)
	var delta := NumericRouletteResolver.upgrade_delta_for_index(index, upgrades)
	var result := RestActionCatalog.result("upgrade_roulette_cell")
	result["run_upgrades"] = {NumericRouletteResolver.cell_bonus_key(index): delta}
	result["remove_potion_ids"] = removed_vouchers.duplicate()
	result["roulette_cell_index"] = index
	result["roulette_cell_from"] = from_multiplier
	result["roulette_cell_to"] = to_multiplier
	return result

func _draw_upgrade_status() -> void:
	var voucher_count := _upgrade_voucher_count()
	_draw_text(UiText.t("rest.upgrade_hint"), Vector2(330, 656), 16, Color(TEXT, 0.72))
	_draw_text(UiText.t("rest.upgrade.vouchers", {"count": voucher_count}), Vector2(330, 680), 14, Color(GOLD, 0.86))
	if _has_pending_upgrade_result():
		if upgrade_can_choose:
			_draw_text(UiText.t("rest.upgrade.ready_again"), Vector2(620, 680), 14, Color(TEXT, 0.74))
		else:
			_draw_text(UiText.t("rest.upgrade.pending_finish"), Vector2(620, 680), 14, Color(TEXT, 0.74))

func _draw_roulette_cell_status() -> void:
	_draw_text(UiText.t("rest.upgrade.roulette_cell.vouchers", {"count": _upgrade_voucher_count()}), Vector2(330, 674), 16, Color(GOLD, 0.86))

func _draw_roulette_cell_upgrade_screen() -> void:
	var center := ROULETTE_CELL_WHEEL_CENTER
	var radius := ROULETTE_CELL_WHEEL_RADIUS
	var upgrades: Dictionary = run_state.get("run_upgrades", {})
	var vouchers := _upgrade_voucher_count()
	_draw_text(UiText.t("rest.upgrade.roulette_cell.title"), Vector2(430, 86), 25, TEXT)
	_draw_text(UiText.t("rest.upgrade.roulette_cell.subtitle"), Vector2(430, 116), 15, Color(TEXT, 0.66))
	draw_circle(center + Vector2(20, 30), radius + 34.0, Color("#020304", 0.36))
	draw_circle(center, radius + 32.0, Color("#21170f", 0.94))
	draw_circle(center, radius + 22.0, Color(GOLD, 0.20), false, 7.0)
	var cells: Array[Dictionary] = NumericRouletteResolver.cells(upgrades)
	var count: int = max(1, cells.size())
	var step := TAU / float(count)
	var base_angle := deg_to_rad(-90.0)
	for i in range(cells.size()):
		var cell: Dictionary = cells[i]
		var cost := int(cell.get("upgrade_cost", 0))
		var affordable := cost > 0 and vouchers >= cost
		var start_angle := base_angle + float(i) * step - step * 0.5
		var end_angle := start_angle + step
		var color := Color(str(cell.get("color", "#26313a")), 0.84 if affordable else 0.34)
		if cost <= 0:
			color = Color("#161b20", 0.42)
		_sector(center, radius, start_angle, end_angle, color)
		draw_arc(center, radius + 5.0, start_angle, end_angle, 18, Color(GOLD, 0.58 if affordable else 0.14), 3.0 if affordable else 1.5)
		var label_angle := start_angle + step * 0.5
		var label_pos := center + Vector2(cos(label_angle), sin(label_angle)) * ROULETTE_CELL_LABEL_RADIUS
		_draw_cell_label(cell, label_pos, affordable, cost)
		if cost > 0:
			var cost_pos := center + Vector2(cos(label_angle), sin(label_angle)) * ROULETTE_CELL_COST_RADIUS
			_draw_cell_cost_badge(cost_pos, cost, affordable)
	draw_circle(center, 74.0, Color("#090c12"))
	draw_circle(center, 48.0, GOLD)
	_draw_centered_text(UiText.t("battle.layer.multiplier"), Rect2(center - Vector2(50, 10), Vector2(100, 24)), 14, INK)
	_draw_roulette_cell_pointer(center, radius)

func _draw_cell_label(cell: Dictionary, pos: Vector2, affordable: bool, cost: int) -> void:
	var label := str(cell.get("label", ""))
	var next_label := NumericRouletteResolver.multiplier_label(float(cell.get("next_multiplier", cell.get("multiplier", 0.0))))
	var rect := Rect2(pos - Vector2(39, 26), Vector2(78, 52))
	var fill := Color("#07090f", 0.78 if affordable else 0.54)
	draw_rect(rect, fill, true)
	draw_rect(rect, Color(GOLD, 0.45 if affordable else 0.16), false, 2.0)
	_draw_centered_text(label, Rect2(rect.position + Vector2(0, 8), Vector2(rect.size.x, 20)), 17, TEXT if affordable else Color(TEXT, 0.50))
	if cost > 0:
		_draw_centered_text(">" + next_label, Rect2(rect.position + Vector2(0, 29), Vector2(rect.size.x, 16)), 12, Color(GOLD, 0.92 if affordable else 0.42))
	else:
		_draw_centered_text(UiText.t("rest.upgrade.roulette_cell.max"), Rect2(rect.position + Vector2(0, 29), Vector2(rect.size.x, 16)), 11, Color(TEXT, 0.38))

func _draw_cell_cost_badge(pos: Vector2, cost: int, affordable: bool) -> void:
	var rect := Rect2(pos - Vector2(31, 16), Vector2(62, 32))
	draw_rect(rect, Color("#140d07", 0.86 if affordable else 0.44), true)
	draw_rect(rect, Color(GOLD, 0.54 if affordable else 0.16), false, 2.0)
	var icon := AssetCatalog.relic_icon("cracked_wax_voucher")
	if icon == null:
		icon = AssetCatalog.shop_runtime_texture("exchange_object_upgrade_ticket")
	if icon != null:
		draw_texture_rect(icon, Rect2(rect.position + Vector2(7, 5), Vector2(22, 22)), false, Color(1, 1, 1, 0.95 if affordable else 0.34))
	_draw_text(str(cost), rect.position + Vector2(36, 22), 16, TEXT if affordable else Color(TEXT, 0.42))

func _draw_roulette_cell_pointer(center: Vector2, radius: float) -> void:
	var pointer := AssetCatalog.combat_runtime_texture("roulette_pointer")
	if pointer != null:
		var target := Vector2(44, 122)
		var top_center := center + Vector2(0, -radius - 72.0)
		draw_texture_rect(pointer, Rect2(top_center - Vector2(target.x * 0.5, target.y * 0.12), target), false, Color(1, 1, 1, 0.96))
		return
	var top := center + Vector2(0, -radius - 24.0)
	draw_polygon(PackedVector2Array([top, top + Vector2(-18, -34), top + Vector2(18, -34)]), PackedColorArray([GOLD, GOLD, GOLD]))

func _roulette_cell_button_rect(index: int) -> Rect2:
	var count: int = max(1, NumericRouletteResolver.cell_count())
	var step := TAU / float(count)
	var angle := deg_to_rad(-90.0) + float(index) * step
	var pos := ROULETTE_CELL_WHEEL_CENTER + Vector2(cos(angle), sin(angle)) * ROULETTE_CELL_LABEL_RADIUS
	return Rect2(pos - Vector2(43, 31), Vector2(86, 62))

func _roulette_cell_tooltip(index: int, cost: int) -> String:
	var current := NumericRouletteResolver.multiplier_for_index(index, run_state.get("run_upgrades", {}))
	if cost <= 0:
		return NumericRouletteResolver.multiplier_label(current)
	var next := NumericRouletteResolver.upgraded_multiplier(current)
	return NumericRouletteResolver.multiplier_label(current) + " > " + NumericRouletteResolver.multiplier_label(next) + " / " + UiText.t("rest.upgrade.roulette_cell.cost", {"count": cost})

func _sector(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	points.append(center)
	colors.append(color)
	for i in range(24):
		var t := float(i) / 23.0
		var angle := lerpf(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		colors.append(color)
	draw_polygon(points, colors)

func _draw_exchange_counter() -> void:
	draw_rect(EXCHANGE_STATUS_RECT, Color("#120b06", 0.72), true)
	draw_rect(EXCHANGE_STATUS_RECT, Color("#8a642f", 0.34), false, 2.0)
	_draw_text(UiText.t("rest.exchange.title"), EXCHANGE_STATUS_RECT.position + Vector2(24, 32), 22, TEXT)
	_draw_text(UiText.t("rest.exchange.subtitle"), EXCHANGE_STATUS_RECT.position + Vector2(24, 56), 13, Color(TEXT, 0.66))

func _draw_exchange_status() -> void:
	_draw_text(UiText.t("rest.exchange.tickets", {"amount": local_tickets}), Vector2(838, 154), 18, GOLD)
	_draw_text(UiText.t("rest.exchange.potions", {
		"used": int(run_state.get("potion_slots_used", (run_state.get("potion_ids", []) as Array).size())),
		"max": int(run_state.get("potion_slots_max", 2))
	}), Vector2(838, 180), 15, Color(TEXT, 0.76))
	if _has_exchange_purchases():
		_draw_text(UiText.t("rest.exchange.locked_back"), Vector2(166, 674), 13, Color(TEXT, 0.58))
	else:
		_draw_text(UiText.t("rest.exchange.back_hint"), Vector2(166, 674), 13, Color(TEXT, 0.58))

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _draw_centered_text(text: String, rect: Rect2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, rect.size.y * 0.72), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)

func _source_texture_id_for_choice(choice_id: String) -> String:
	if choice_id == "upgrade_primary_die" or choice_id == "upgrade_secondary_die":
		return "upgrade_direction_lock"
	return "__screen_overlay"

func _source_rect_for_choice(choice_id: String) -> Rect2:
	if choice_id == "upgrade_primary_die" or choice_id == "upgrade_secondary_die":
		return UPGRADE_DIE_SOURCE_RECT
	return get_choice_rect(choice_id)
