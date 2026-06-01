extends Control

signal completed(result: Dictionary)

const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const ShopOfferCatalog := preload("res://scripts/systems/shop_offer_catalog.gd")
const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const RunChoice := preload("res://scripts/run/run_choice.gd")
const RunTableState := preload("res://scripts/run/run_table_state.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const ShopOfferSlotNode := preload("res://scripts/ui/shop_offer_slot_node.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const BG := Color("#07090f")
const PANEL := Color("#15120d")
const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const GREEN := Color("#65d48e")
const RED := Color("#ee5b5b")
const INK := Color("#090704")

const RELIC_PRICE := 30
const PREP_PRICE := 14
const REROLL_BASE_PRICE := 6
const REROLL_PRICE_STEP := 4
const SHOP_COUNTER_RECT := Rect2(Vector2(126, 214), Vector2(1028, 430))
const SHOP_MAT_RECT := Rect2(Vector2(158, 250), Vector2(964, 344))
const SHOP_RELIC_CHOICE_RECTS := [
	Rect2(Vector2(192, 238), Vector2(144, 318)),
	Rect2(Vector2(360, 238), Vector2(144, 318))
]
const SHOP_RELIC_SLOT_RECTS := [
	Rect2(Vector2(196, 260), Vector2(136, 190)),
	Rect2(Vector2(364, 260), Vector2(136, 190))
]
const SHOP_RELIC_TAG_RECTS := [
	Rect2(Vector2(182, 500), Vector2(164, 44)),
	Rect2(Vector2(350, 500), Vector2(164, 44))
]
const SHOP_SERVICE_CHOICE_RECTS := [
	Rect2(Vector2(528, 238), Vector2(144, 318)),
	Rect2(Vector2(696, 238), Vector2(144, 318))
]
const SHOP_SERVICE_SLOT_RECTS := [
	Rect2(Vector2(532, 260), Vector2(136, 190)),
	Rect2(Vector2(700, 260), Vector2(136, 190))
]
const SHOP_SERVICE_TAG_RECTS := [
	Rect2(Vector2(518, 500), Vector2(164, 44)),
	Rect2(Vector2(686, 500), Vector2(164, 44))
]
const SHOP_SPECIAL_CHOICE_RECT := Rect2(Vector2(864, 238), Vector2(144, 318))
const SHOP_SPECIAL_SLOT_RECT := Rect2(Vector2(868, 260), Vector2(136, 190))
const SHOP_SPECIAL_TAG_RECT := Rect2(Vector2(854, 500), Vector2(164, 44))
const SHOP_PREP_CHOICE_RECT := Rect2(Vector2(528, 238), Vector2(144, 318))
const SHOP_EXIT_RECT := Rect2(Vector2(1030, 608), Vector2(170, 54))
const SHOP_PREP_SLOT_RECT := Rect2(Vector2(532, 260), Vector2(136, 190))
const SHOP_PREP_TAG_RECT := Rect2(Vector2(518, 500), Vector2(164, 44))
const SHOP_DETAIL_RECT := Rect2(Vector2(170, 592), Vector2(620, 104))
const SHOP_CONFIRM_RECT := Rect2(Vector2(820, 608), Vector2(174, 54))
const SHOP_REROLL_RECT := Rect2(Vector2(574, 184), Vector2(190, 60))

var run_state: Dictionary = {}
var map_result: Dictionary = {}
var offered_relic_id: String = "loaded_die"
var offered_relic_ids: Array[String] = []
var relic_offers: Array[Dictionary] = []
var buttons: Array[Button] = []
var confirm_button: Button
var leave_button: Button
var reroll_button: Button
var reroll_hovered := false
var choices: Array[Dictionary] = []
var pending_result: Dictionary = {}
var visit_result: Dictionary = {}
var local_gold := 0
var reroll_count := 0
var purchased_choice_ids: Array[String] = []
var submitted := false
var selected_choice := ""
var hovered_choice := ""

func configure(payload: Dictionary) -> void:
	run_state = payload.get("run_state", {}).duplicate(true)
	map_result = payload.get("map_result", {}).duplicate(true)
	local_gold = int(run_state.get("gold", 0))
	visit_result = _empty_visit_result()
	reroll_count = 0
	purchased_choice_ids.clear()
	offered_relic_ids = ShopOfferCatalog.relic_offer_ids(run_state, ShopOfferCatalog.SHOP_V2_RELIC_OFFER_LIMIT)
	relic_offers = ShopOfferCatalog.relic_offer_choices(run_state, ShopOfferCatalog.SHOP_V2_RELIC_OFFER_LIMIT)
	offered_relic_id = offered_relic_ids[0] if not offered_relic_ids.is_empty() else ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_buttons()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	var uses_art_background := _draw_shop_background_texture()
	if not uses_art_background:
		UiSkin.draw_table_stage(self)
		_draw_shop_back_room()
	_draw_shop_counter(uses_art_background)

func _draw_shop_background_texture() -> bool:
	var texture := AssetCatalog.shop_runtime_texture("shop_room_background_clean")
	if texture == null:
		texture = AssetCatalog.shop_runtime_texture("background_style_target_001")
	if texture == null:
		return false
	draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false, Color.WHITE)
	draw_rect(Rect2(Vector2.ZERO, size), Color("#050403", 0.08), true)
	return true

func _build_buttons() -> void:
	choices = _build_choices()
	for i in range(choices.size()):
		var choice := choices[i]
		var choice_id := str(choice.get("id", ""))
		var rect := get_choice_rect(choice_id)
		var button := _build_offer_button(choice, choice_id, rect)
		add_child(button)
		buttons.append(button)
	_build_action_buttons()

func _build_offer_button(choice: Dictionary, choice_id: String, rect: Rect2) -> Button:
	var button := ShopOfferSlotNode.new()
	button.name = "RunChoice_" + choice_id
	button.configure_offer(choice, _offer_metadata(choice), rect, _slot_rect_for_choice(choice_id), get_price_tag_rect(choice_id))
	button.disabled = not RunChoice.is_interactive(choice)
	if not button.disabled:
		button.pressed.connect(Callable(self, "_select_by_id").bind(choice_id))
	button.mouse_entered.connect(func() -> void:
		_hover_choice(choice_id)
		button.set_hovered(true)
	)
	button.mouse_exited.connect(func() -> void:
		_clear_hover(choice_id)
		button.set_hovered(false)
	)
	return button

func _build_action_buttons() -> void:
	confirm_button = _action_button(UiText.t("shop.confirm"), get_confirm_rect(), Callable(self, "_confirm_purchase"), false, true)
	add_child(confirm_button)
	leave_button = _action_button(UiText.t("overlay.exit"), get_exit_rect(), Callable(self, "_leave"), true, false)
	add_child(leave_button)
	reroll_button = _action_button(UiText.t("shop.reroll"), get_reroll_rect(), Callable(self, "_reroll_unsold_offers"), _can_reroll(), false)
	reroll_button.mouse_entered.connect(func() -> void:
		reroll_hovered = true
		queue_redraw()
	)
	reroll_button.mouse_exited.connect(func() -> void:
		reroll_hovered = false
		queue_redraw()
	)
	add_child(reroll_button)

func _action_button(text: String, rect: Rect2, callback: Callable, enabled: bool, primary: bool) -> Button:
	var button := Button.new()
	button.text = ""
	button.tooltip_text = text
	button.position = rect.position
	button.size = rect.size
	button.disabled = not enabled
	_apply_transparent_button(button)
	button.pressed.connect(callback)
	return button

func _apply_transparent_button(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("disabled", empty)
	button.add_theme_color_override("font_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_disabled_color", Color.TRANSPARENT)

func get_choice_controls() -> Array[Button]:
	return buttons

func get_choice_rect(choice_id: String) -> Rect2:
	if ShopOfferCatalog.is_relic_choice(choice_id):
		var index := ShopOfferCatalog.relic_choice_index(choice_id)
		if index >= 0 and index < SHOP_RELIC_CHOICE_RECTS.size():
			return SHOP_RELIC_CHOICE_RECTS[index]
	if choice_id == "shop_prep":
		return SHOP_PREP_CHOICE_RECT
	if ShopOfferCatalog.is_service_choice(choice_id):
		var index := ShopOfferCatalog.service_choice_index(choice_id)
		if index >= 0 and index < SHOP_SERVICE_CHOICE_RECTS.size():
			return SHOP_SERVICE_CHOICE_RECTS[index]
	if ShopOfferCatalog.is_special_choice(choice_id):
		return SHOP_SPECIAL_CHOICE_RECT
	if choice_id == "shop_leave":
		return get_exit_rect()
	return Rect2()

func get_price_tag_rect(choice_id: String) -> Rect2:
	if ShopOfferCatalog.is_relic_choice(choice_id):
		var index := ShopOfferCatalog.relic_choice_index(choice_id)
		if index >= 0 and index < SHOP_RELIC_TAG_RECTS.size():
			return SHOP_RELIC_TAG_RECTS[index]
	if choice_id == "shop_prep":
		return SHOP_PREP_TAG_RECT
	if ShopOfferCatalog.is_service_choice(choice_id):
		var index := ShopOfferCatalog.service_choice_index(choice_id)
		if index >= 0 and index < SHOP_SERVICE_TAG_RECTS.size():
			return SHOP_SERVICE_TAG_RECTS[index]
	if ShopOfferCatalog.is_special_choice(choice_id):
		return SHOP_SPECIAL_TAG_RECT
	return Rect2()

func get_confirm_rect() -> Rect2:
	return SHOP_CONFIRM_RECT

func get_exit_rect() -> Rect2:
	return SHOP_EXIT_RECT

func get_reroll_rect() -> Rect2:
	return SHOP_REROLL_RECT

func get_table_state() -> Dictionary:
	return RunTableState.from_run_payload(run_state, pending_result)

func get_pickup_summary() -> Dictionary:
	return get_table_state().get("pickup", {})

func _build_choices() -> Array[Dictionary]:
	var result := ShopOfferCatalog.shop_v2_offer_choices(run_state, reroll_count)
	_apply_choice_affordability(result)
	return result

func _apply_choice_affordability(target_choices: Array[Dictionary]) -> void:
	for i in range(target_choices.size()):
		var id := str(target_choices[i].get("id", ""))
		if purchased_choice_ids.has(id):
			target_choices[i]["state"] = RunChoice.STATE_SOLD
			target_choices[i]["enabled"] = false
		elif _result_is_affordable(target_choices[i].get("result", {})):
			target_choices[i]["state"] = RunChoice.STATE_NORMAL
			target_choices[i]["enabled"] = true
		else:
			target_choices[i]["state"] = RunChoice.STATE_UNAFFORDABLE
			target_choices[i]["enabled"] = false

func _offer_metadata(choice: Dictionary) -> Dictionary:
	var choice_id := str(choice.get("id", ""))
	var result_value: Variant = choice.get("result", {})
	var price := PREP_PRICE
	var relic_id := ""
	var kind := str(choice.get("slot_kind", "relic" if ShopOfferCatalog.is_relic_choice(choice_id) else "service"))
	if result_value is Dictionary:
		price = abs(int((result_value as Dictionary).get("gold_delta", -PREP_PRICE)))
		var relic_ids: Array = (result_value as Dictionary).get("relic_ids", [])
		if not relic_ids.is_empty():
			relic_id = str(relic_ids[0])
	if ShopOfferCatalog.is_relic_choice(choice_id):
		return {
			"kind": "relic",
			"relic_id": relic_id,
			"price": price
		}
	return {
		"kind": "prep" if choice_id == "shop_prep" else kind,
		"price": int(choice.get("price", price)),
		"icon_id": str(choice.get("icon_id", "")),
		"badge_id": str(choice.get("badge_id", ""))
	}

func _select_by_id(choice_id: String) -> void:
	if submitted:
		return
	if ShopOfferCatalog.is_relic_choice(choice_id) or choice_id == "shop_prep" or ShopOfferCatalog.is_service_choice(choice_id) or ShopOfferCatalog.is_special_choice(choice_id):
		_select_purchase(_result_for_choice(choice_id))
	elif choice_id == "shop_leave":
		_leave()

func _select_purchase(result: Dictionary) -> void:
	if not _result_is_affordable(result):
		return
	pending_result = result.duplicate(true)
	selected_choice = str(result.get("choice", ""))
	for i in range(choices.size()):
		var id := str(choices[i].get("id", ""))
		if id == selected_choice:
			choices[i]["state"] = RunChoice.STATE_SELECTED
		elif id == "shop_leave":
			choices[i]["state"] = RunChoice.STATE_NORMAL
		else:
			choices[i]["state"] = RunChoice.STATE_NORMAL if _can_select_choice(id) else RunChoice.STATE_UNAFFORDABLE
			choices[i]["enabled"] = _can_select_choice(id)
	_refresh_buttons()
	queue_redraw()

func _refresh_buttons() -> void:
	for i in range(min(buttons.size(), choices.size())):
		var button := buttons[i]
		var choice := choices[i]
		if button is ShopOfferSlotNode:
			button.set_offer_choice(choice)
		button.disabled = submitted or not RunChoice.is_interactive(choice)
	if confirm_button != null:
		confirm_button.disabled = submitted or pending_result.is_empty()
	if leave_button != null:
		leave_button.disabled = submitted
	if reroll_button != null:
		reroll_button.disabled = submitted or not _can_reroll()
		if reroll_button.disabled:
			reroll_hovered = false

func _buy_relic() -> void:
	var result := _result_for_choice("shop_relic")
	if result.is_empty():
		return
	_select_purchase(result)
	_confirm_purchase()

func _buy_prep() -> void:
	_select_purchase(_result_for_choice("shop_prep"))
	_confirm_purchase()

func _confirm_purchase() -> void:
	if pending_result.is_empty():
		return
	_commit_purchase(pending_result)

func _reroll_unsold_offers() -> void:
	if submitted or not _can_reroll():
		return
	var price := _reroll_price()
	local_gold -= price
	run_state["gold"] = local_gold
	_accumulate_visit_result({
		"accepted": true,
		"choice": "shop_reroll",
		"gold_delta": -price,
		"hp_delta": 0,
		"relic_ids": [],
		"next_combat_mods": [],
		"run_upgrades": {}
	})
	reroll_count += 1
	pending_result.clear()
	selected_choice = ""
	var retained_signatures: Array[String] = []
	for choice in choices:
		if choice is Dictionary and purchased_choice_ids.has(str((choice as Dictionary).get("id", ""))):
			var retained_signature := _offer_signature(choice)
			if retained_signature != "":
				retained_signatures.append(retained_signature)
	for i in range(choices.size()):
		var id := str(choices[i].get("id", ""))
		if purchased_choice_ids.has(id):
			continue
		var replacement := _rerolled_choice_for_slot(i, retained_signatures)
		if replacement.is_empty():
			continue
		choices[i] = replacement
		var signature := _offer_signature(replacement)
		if signature != "":
			retained_signatures.append(signature)
	_apply_choice_affordability(choices)
	_refresh_buttons()
	queue_redraw()

func _rerolled_choice_for_slot(index: int, blocked_signatures: Array[String]) -> Dictionary:
	for attempt in range(8):
		var candidates := ShopOfferCatalog.shop_v2_offer_choices(run_state, reroll_count + attempt)
		if index >= candidates.size():
			return {}
		var candidate := candidates[index]
		var signature := _offer_signature(candidate)
		if signature == "" or not blocked_signatures.has(signature):
			return candidate
	var fallback := ShopOfferCatalog.shop_v2_offer_choices(run_state, reroll_count)
	return fallback[index] if index < fallback.size() else {}

func _offer_signature(choice: Dictionary) -> String:
	var service_id := str(choice.get("service_id", ""))
	if service_id != "":
		return "service:" + service_id
	var relic_id := str(choice.get("relic_id", ""))
	if relic_id != "":
		return "relic:" + relic_id
	var result_value: Variant = choice.get("result", {})
	if result_value is Dictionary:
		var relic_ids: Array = (result_value as Dictionary).get("relic_ids", [])
		if not relic_ids.is_empty():
			return "relic:" + str(relic_ids[0])
	return ""

func _can_reroll() -> bool:
	if local_gold < _reroll_price():
		return false
	for choice in choices:
		if choice is Dictionary and not purchased_choice_ids.has(str((choice as Dictionary).get("id", ""))):
			return true
	return false

func _reroll_price() -> int:
	return REROLL_BASE_PRICE + reroll_count * REROLL_PRICE_STEP

func _relic_result(relic_id: String = "", choice_id: String = "shop_relic") -> Dictionary:
	var selected_relic_id := relic_id if relic_id != "" else (offered_relic_ids[0] if not offered_relic_ids.is_empty() else offered_relic_id)
	var price := RelicCatalog.shop_price(selected_relic_id)
	return {
		"accepted": true,
		"choice": choice_id,
		"gold_delta": -price,
		"hp_delta": 0,
		"relic_ids": [selected_relic_id],
		"next_combat_mods": []
	}

func _prep_result() -> Dictionary:
	var current := _result_for_choice("shop_prep")
	if not current.is_empty():
		return current
	return {
		"accepted": true,
		"choice": "shop_prep",
		"gold_delta": -PREP_PRICE,
		"hp_delta": 0,
		"relic_ids": [],
		"next_combat_mods": [{
			"id": "shop_soft_prep",
			"enemy_damage_delta": -2,
			"description": "Shop prep: next enemy hit is softened."
		}]
	}

func _leave() -> void:
	_complete_once(_leave_result())

func _leave_result() -> Dictionary:
	return {
		"accepted": true,
		"choice": "shop_leave",
		"gold_delta": 0,
		"hp_delta": 0,
		"relic_ids": [],
		"next_combat_mods": [],
		"run_upgrades": {}
	}

func _choose_default() -> void:
	if _can_buy_relic():
		_buy_relic()
	elif _can_buy_prep():
		_buy_prep()
	else:
		_leave()

func _complete_once(result: Dictionary) -> void:
	if submitted:
		return
	if not _result_is_affordable(result):
		return
	submitted = true
	selected_choice = str(result.get("choice", ""))
	if selected_choice == "shop_leave":
		pending_result = visit_result.duplicate(true)
		pending_result["choice"] = "shop_leave"
		pending_result["accepted"] = true
	else:
		pending_result = result.duplicate(true)
	for i in range(choices.size()):
		var id := str(choices[i].get("id", ""))
		if id == selected_choice:
			choices[i]["state"] = RunChoice.STATE_SOLD if selected_choice != "shop_leave" else RunChoice.STATE_CHOSEN
		else:
			choices[i]["state"] = RunChoice.STATE_DISABLED
	_refresh_buttons()
	if confirm_button != null:
		confirm_button.disabled = true
	if leave_button != null:
		leave_button.disabled = true
	queue_redraw()
	completed.emit(pending_result)

func _commit_purchase(result: Dictionary) -> void:
	if submitted or pending_result.is_empty():
		return
	if not _result_is_affordable(result):
		return
	var choice_id := str(result.get("choice", ""))
	if choice_id == "" or purchased_choice_ids.has(choice_id):
		return
	purchased_choice_ids.append(choice_id)
	local_gold += int(result.get("gold_delta", 0))
	run_state["gold"] = local_gold
	_accumulate_visit_result(result)
	_apply_purchase_to_local_inventory(result)
	pending_result.clear()
	selected_choice = ""
	_update_choice_states_after_purchase()
	_refresh_buttons()
	queue_redraw()

func _can_buy_relic(relic_id: String = "") -> bool:
	var selected_relic_id := relic_id if relic_id != "" else (offered_relic_ids[0] if not offered_relic_ids.is_empty() else offered_relic_id)
	if selected_relic_id == "":
		return false
	return local_gold >= ShopOfferCatalog.relic_price_for_run(selected_relic_id, run_state)

func _can_buy_prep() -> bool:
	return local_gold >= PREP_PRICE

func _result_is_affordable(result: Dictionary) -> bool:
	var choice := str(result.get("choice", ""))
	if purchased_choice_ids.has(choice):
		return false
	if ShopOfferCatalog.is_relic_choice(choice):
		return local_gold + int(result.get("gold_delta", 0)) >= 0
	if choice == "shop_leave":
		return true
	var hp_after := int(run_state.get("player_hp", 1)) + int(result.get("hp_delta", 0))
	return local_gold + int(result.get("gold_delta", 0)) >= 0 and hp_after > 0

func _can_select_choice(choice_id: String) -> bool:
	if purchased_choice_ids.has(choice_id):
		return false
	if ShopOfferCatalog.is_relic_choice(choice_id):
		return _can_buy_relic(_relic_id_for_choice(choice_id))
	if choice_id == "shop_leave":
		return true
	return _result_is_affordable(_result_for_choice(choice_id))

func _result_for_choice(choice_id: String) -> Dictionary:
	for choice in choices:
		if not choice is Dictionary:
			continue
		if str((choice as Dictionary).get("id", "")) == choice_id:
			var result: Dictionary = (choice as Dictionary).get("result", {})
			return result.duplicate(true)
	if ShopOfferCatalog.is_relic_choice(choice_id):
		return _relic_result(_relic_id_for_choice(choice_id), choice_id)
	return {}

func _empty_visit_result() -> Dictionary:
	return {
		"accepted": true,
		"choice": "shop_leave",
		"gold_delta": 0,
		"hp_delta": 0,
		"relic_ids": [],
		"next_combat_mods": [],
		"run_upgrades": {}
	}

func _accumulate_visit_result(result: Dictionary) -> void:
	visit_result["gold_delta"] = int(visit_result.get("gold_delta", 0)) + int(result.get("gold_delta", 0))
	visit_result["hp_delta"] = int(visit_result.get("hp_delta", 0)) + int(result.get("hp_delta", 0))
	var relic_ids: Array = visit_result.get("relic_ids", [])
	for relic_id in result.get("relic_ids", []):
		var id := str(relic_id)
		if not relic_ids.has(id):
			relic_ids.append(id)
	visit_result["relic_ids"] = relic_ids
	var mods: Array = visit_result.get("next_combat_mods", [])
	for mod in result.get("next_combat_mods", []):
		if mod is Dictionary:
			mods.append((mod as Dictionary).duplicate(true))
	visit_result["next_combat_mods"] = mods
	var upgrades: Dictionary = visit_result.get("run_upgrades", {})
	for key in (result.get("run_upgrades", {}) as Dictionary).keys():
		var id := str(key)
		upgrades[id] = float(upgrades.get(id, 0.0)) + float((result.get("run_upgrades", {}) as Dictionary).get(key, 0.0))
	visit_result["run_upgrades"] = upgrades

func _apply_purchase_to_local_inventory(result: Dictionary) -> void:
	var relic_ids: Array = run_state.get("relic_ids", [])
	for relic_id in result.get("relic_ids", []):
		var id := str(relic_id)
		if not relic_ids.has(id):
			relic_ids.append(id)
	run_state["relic_ids"] = relic_ids
	var mods: Array = run_state.get("next_combat_mods", [])
	for mod in result.get("next_combat_mods", []):
		if mod is Dictionary:
			mods.append((mod as Dictionary).duplicate(true))
	run_state["next_combat_mods"] = mods
	run_state["player_hp"] = clamp(
		int(run_state.get("player_hp", 1)) + int(result.get("hp_delta", 0)),
		0,
		int(run_state.get("player_max_hp", 42))
	)
	var upgrades: Dictionary = run_state.get("run_upgrades", {})
	for key in (result.get("run_upgrades", {}) as Dictionary).keys():
		var id := str(key)
		upgrades[id] = float(upgrades.get(id, 0.0)) + float((result.get("run_upgrades", {}) as Dictionary).get(key, 0.0))
	run_state["run_upgrades"] = upgrades

func _update_choice_states_after_purchase() -> void:
	for i in range(choices.size()):
		var id := str(choices[i].get("id", ""))
		if purchased_choice_ids.has(id):
			choices[i]["state"] = RunChoice.STATE_SOLD
			choices[i]["enabled"] = false
		elif _can_select_choice(id):
			choices[i]["state"] = RunChoice.STATE_NORMAL
			choices[i]["enabled"] = true
		else:
			choices[i]["state"] = RunChoice.STATE_UNAFFORDABLE
			choices[i]["enabled"] = false

func _draw_shop_back_room() -> void:
	draw_rect(Rect2(Vector2(110, 104), Vector2(1060, 98)), Color("#1a100a", 0.88), true)
	draw_rect(Rect2(Vector2(110, 104), Vector2(1060, 98)), Color("#8a642f", 0.34), false, 3.0)
	for i in range(6):
		var x := 154.0 + float(i) * 172.0
		draw_line(Vector2(x, 118), Vector2(x + 120.0, 118), Color("#6f4a1e", 0.34), 5.0)
		draw_line(Vector2(x + 18.0, 182), Vector2(x + 136.0, 182), Color("#070704", 0.42), 3.0)
	_draw_side_counter_props()

func _draw_side_counter_props() -> void:
	var left_crate := Rect2(Vector2(118, 252), Vector2(92, 156))
	draw_rect(left_crate, Color("#2b1a11", 0.92), true)
	draw_rect(left_crate, Color("#a88956", 0.38), false, 2.0)
	draw_line(left_crate.position + Vector2(10, 38), left_crate.end - Vector2(10, 112), Color("#5a3b22", 0.45), 2.0)
	draw_line(left_crate.position + Vector2(10, 78), left_crate.end - Vector2(10, 72), Color("#5a3b22", 0.36), 2.0)
	for i in range(3):
		UiSkin.draw_coin_marker(self, left_crate.position + Vector2(26.0 + float(i) * 22.0, 28.0), 9.0, Color(1, 1, 1, 0.74))
	var dice_texture := AssetCatalog.dice_face(3)
	if dice_texture != null:
		draw_texture_rect(dice_texture, Rect2(left_crate.position + Vector2(28, 92), Vector2(38, 38)), false, Color(1, 1, 1, 0.78))
	_draw_text(UiText.t("shop.storage"), left_crate.position + Vector2(20, 144), 12, Color(TEXT, 0.54))

	var right_shelf := Rect2(Vector2(1070, 234), Vector2(86, 196))
	draw_rect(right_shelf, Color("#21140d", 0.92), true)
	draw_rect(right_shelf, Color("#a88956", 0.36), false, 2.0)
	for y in [46.0, 98.0, 150.0]:
		draw_line(right_shelf.position + Vector2(8, y), right_shelf.position + Vector2(right_shelf.size.x - 8.0, y), Color("#5a3b22", 0.54), 3.0)
	_draw_icon("shop", Rect2(right_shelf.position + Vector2(24, 14), Vector2(38, 38)), Color(GOLD, 0.5))
	var pouch_texture := AssetCatalog.prop_icon("pouch")
	if pouch_texture != null:
		draw_texture_rect(pouch_texture, Rect2(right_shelf.position + Vector2(23, 118), Vector2(40, 40)), false, Color(1, 1, 1, 0.46))

func _draw_shop_counter(uses_art_background: bool = false) -> void:
	if not uses_art_background:
		draw_rect(SHOP_COUNTER_RECT, Color("#1b0f09", 0.98), true)
		draw_rect(SHOP_COUNTER_RECT, Color("#8a642f", 0.5), false, 4.0)
		draw_rect(SHOP_MAT_RECT, Color("#244b34", 0.96), true)
		draw_rect(SHOP_MAT_RECT, Color("#65d48e", 0.24), false, 3.0)
		draw_rect(SHOP_MAT_RECT.grow(-10.0), Color("#101510", 0.22), false, 1.0)
		for i in range(7):
			var y := SHOP_MAT_RECT.position.y + 24.0 + float(i) * 42.0
			draw_line(SHOP_MAT_RECT.position + Vector2(24, y - SHOP_MAT_RECT.position.y), Vector2(SHOP_MAT_RECT.end.x - 24.0, y), Color("#c9e2a7", 0.07), 1.0)
		_draw_counter_tools(SHOP_COUNTER_RECT)
	_draw_shop_status_plate()
	_draw_shop_reroll_plate()
	_draw_shop_detail_panel()
	_draw_shop_confirm_plate()
	_draw_shop_exit_plate()

func _draw_counter_tools(counter: Rect2) -> void:
	for center in [Vector2(counter.position.x + 72.0, counter.end.y - 66.0), Vector2(counter.end.x - 74.0, counter.position.y + 62.0)]:
		UiSkin.draw_coin_marker(self, center, 12.0, Color(1, 1, 1, 0.62))
		UiSkin.draw_coin_marker(self, center + Vector2(18, 10), 9.0, Color(1, 1, 1, 0.5))
	draw_line(Vector2(counter.position.x + 72.0, counter.position.y + 94.0), Vector2(counter.position.x + 142.0, counter.position.y + 132.0), Color("#b8a16e", 0.6), 4.0)
	draw_line(Vector2(counter.position.x + 142.0, counter.position.y + 94.0), Vector2(counter.position.x + 72.0, counter.position.y + 132.0), Color("#7f6a48", 0.58), 4.0)
	draw_circle(Vector2(counter.position.x + 142.0, counter.position.y + 94.0), 8.0, Color("#2d3740", 0.72))
	draw_line(Vector2(counter.end.x - 152.0, counter.position.y + 208.0), Vector2(counter.end.x - 86.0, counter.position.y + 178.0), Color("#b8a16e", 0.58), 4.0)
	draw_circle(Vector2(counter.end.x - 86.0, counter.position.y + 178.0), 10.0, Color("#2d3740", 0.62))

func _draw_shop_slot(choice: Dictionary) -> void:
	var choice_id := str(choice.get("id", ""))
	var slot := _slot_rect_for_choice(choice_id)
	var tag := get_price_tag_rect(choice_id)
	var state := _choice_visual_state(choice)
	var disabled := state == RunChoice.STATE_UNAFFORDABLE or state == RunChoice.STATE_DISABLED or state == RunChoice.STATE_SOLD
	var tint := Color(1, 1, 1, 0.48) if disabled else Color(1, 1, 1, 0.9)
	var slot_texture_id := "offer_slot_base"
	if state == RunChoice.STATE_SELECTED or state == RunChoice.STATE_HOVER:
		slot_texture_id = "offer_slot_selected"
	elif state == RunChoice.STATE_DISABLED or state == RunChoice.STATE_UNAFFORDABLE:
		slot_texture_id = "offer_slot_disabled"
	_draw_shop_texture(slot_texture_id, slot, tint)
	_draw_shop_ware_prop(choice, slot)
	_draw_price_tag(choice, tag, state)
	if state == RunChoice.STATE_SOLD:
		_draw_shop_texture("offer_slot_sold", slot, Color(1, 1, 1, 0.88))
		_draw_shop_texture("wax_sold", Rect2(slot.position + Vector2(slot.size.x - 44.0, 16.0), Vector2(42, 56)), Color(1, 1, 1, 0.8))
	elif state != RunChoice.STATE_NORMAL and state != RunChoice.STATE_HOVER and state != RunChoice.STATE_SELECTED:
		_draw_shop_texture("wax_disabled", Rect2(slot.position + Vector2(slot.size.x - 42.0, 16.0), Vector2(38, 38)), Color(1, 1, 1, 0.78))

func _slot_rect_for_choice(choice_id: String) -> Rect2:
	if ShopOfferCatalog.is_relic_choice(choice_id):
		var index := ShopOfferCatalog.relic_choice_index(choice_id)
		if index >= 0 and index < SHOP_RELIC_SLOT_RECTS.size():
			return SHOP_RELIC_SLOT_RECTS[index]
	if choice_id == "shop_prep":
		return SHOP_PREP_SLOT_RECT
	if ShopOfferCatalog.is_service_choice(choice_id):
		var index := ShopOfferCatalog.service_choice_index(choice_id)
		if index >= 0 and index < SHOP_SERVICE_SLOT_RECTS.size():
			return SHOP_SERVICE_SLOT_RECTS[index]
	if ShopOfferCatalog.is_special_choice(choice_id):
		return SHOP_SPECIAL_SLOT_RECT
	return Rect2()

func _choice_visual_state(choice: Dictionary) -> String:
	var choice_id := str(choice.get("id", ""))
	if submitted and selected_choice != "":
		if choice_id == selected_choice and choice_id != "shop_leave":
			return RunChoice.STATE_SOLD
		return RunChoice.state_after_submit(choice_id, selected_choice)
	if hovered_choice == choice_id and RunChoice.is_interactive(choice):
		return RunChoice.STATE_HOVER
	return str(choice.get("state", RunChoice.STATE_NORMAL))

func _draw_shop_ware_prop(choice: Dictionary, slot: Rect2) -> void:
	var choice_id := str(choice.get("id", ""))
	var disabled := not RunChoice.is_interactive(choice)
	var tint := Color(1, 1, 1, 0.42) if disabled else Color(1, 1, 1, 0.78)
	var prop_rect := Rect2(slot.position + Vector2(slot.size.x * 0.5 - 48.0, 30.0), Vector2(96, 96))
	if ShopOfferCatalog.is_relic_choice(choice_id):
			var result_value: Variant = choice.get("result", {})
			var relic_id := offered_relic_id
			if result_value is Dictionary:
				var relic_ids: Array = (result_value as Dictionary).get("relic_ids", [])
				if not relic_ids.is_empty():
					relic_id = str(relic_ids[0])
			var texture := AssetCatalog.relic_object(RelicCatalog.icon_id(relic_id))
			if texture != null:
				draw_texture_rect(texture, prop_rect, false, tint)
			UiSkin.draw_coin_marker(self, prop_rect.position + Vector2(-10, 82), 9.0, tint)
			UiSkin.draw_coin_marker(self, prop_rect.position + Vector2(86, 82), 9.0, tint)
			_draw_text(_clip(RelicCatalog.display_name(relic_id), 18), slot.position + Vector2(14, 150), 12, Color(TEXT, tint.a * 0.76))
	elif choice_id == "shop_prep":
		prop_rect = Rect2(slot.position + Vector2(slot.size.x * 0.5 - 34.0, 46.0), Vector2(68, 68))
		var dice_texture := AssetCatalog.dice_face(2)
		if dice_texture != null:
			draw_texture_rect(dice_texture, prop_rect, false, tint)
		_draw_text(UiText.t("shop.prep.label"), slot.position + Vector2(42, 150), 13, Color(TEXT, tint.a * 0.76))

func _draw_price_tag(choice: Dictionary, tag: Rect2, state: String) -> void:
	var disabled := state == RunChoice.STATE_UNAFFORDABLE or state == RunChoice.STATE_DISABLED or state == RunChoice.STATE_SOLD
	var tint := Color(1, 1, 1, 0.46) if disabled else Color(1, 1, 1, 0.86)
	var choice_id := str(choice.get("id", ""))
	var result_value: Variant = choice.get("result", {})
	var price_value := PREP_PRICE
	if result_value is Dictionary:
		price_value = abs(int((result_value as Dictionary).get("gold_delta", -PREP_PRICE)))
	var price := UiText.t("shop.gold_price", {"amount": price_value})
	_draw_shop_texture("price_tag_wide", tag, tint)
	_draw_text(price, tag.position + Vector2(48, 28), 13, Color("#f5d38f", tint.a))
	if disabled and state == RunChoice.STATE_UNAFFORDABLE:
		_draw_text(UiText.t("shop.insufficient"), tag.position + Vector2(tag.size.x - 42.0, 28), 11, Color(RED, tint.a))

func _draw_shop_detail_panel() -> void:
	var rect := SHOP_DETAIL_RECT
	var selected := selected_choice
	_draw_shop_texture("detail_plate", rect, Color(1, 1, 1, 0.92))
	_draw_text(UiText.t("shop.detail.title"), rect.position + Vector2(108, 30), 14, Color("#f5d38f", 0.82))
	if pending_result.is_empty() or selected == "":
		_draw_text(UiText.t("shop.detail.empty"), rect.position + Vector2(108, 62), 15, TEXT)
		_draw_text(UiText.t("shop.detail.empty_note"), rect.position + Vector2(108, 86), 12, Color(TEXT, 0.64))
		return
	_draw_text(_selected_product_name(), rect.position + Vector2(108, 58), 20, TEXT)
	_draw_text(_selected_product_price_text(), rect.position + Vector2(300, 58), 13, Color("#f2be4b"))
	var description_lines := _wrap_words(_selected_product_description(), 58, 2)
	for i in range(description_lines.size()):
		_draw_text(str(description_lines[i]), rect.position + Vector2(108, 82 + i * 17), 12, Color(TEXT, 0.68))

func _draw_shop_confirm_plate() -> void:
	var rect := SHOP_CONFIRM_RECT
	var enabled := not submitted and not pending_result.is_empty()
	var tint := Color(1, 1, 1, 0.94) if enabled else Color(1, 1, 1, 0.44)
	_draw_shop_texture("price_tag_wide", rect, tint)
	if enabled:
		draw_rect(rect.grow(-2.0), Color(GOLD, 0.52), false, 2.0)
	_draw_text(UiText.t("shop.confirm"), rect.position + Vector2(50, 34), 16, Color(TEXT, tint.a))

func _draw_shop_exit_plate() -> void:
	var rect := SHOP_EXIT_RECT
	var tint := Color(1, 1, 1, 0.88) if not submitted else Color(1, 1, 1, 0.42)
	_draw_shop_texture("price_tag_wide", rect, tint)
	_draw_text(UiText.t("overlay.exit"), rect.position + Vector2(56, 34), 16, Color(TEXT, tint.a))

func _draw_shop_status_plate() -> void:
	var rect := Rect2(Vector2(182, 190), Vector2(360, 48))
	draw_rect(rect, Color("#120b08", 0.42), true)
	draw_rect(rect, Color("#d8ad55", 0.36), false, 1.0)
	UiSkin.draw_coin_marker(self, rect.position + Vector2(24, 24), 10.0, Color(GOLD, 0.9))
	_draw_text(UiText.t("shop.gold_price", {"amount": local_gold}), rect.position + Vector2(44, 30), 16, Color("#f5d38f", 0.92))
	var bought := purchased_choice_ids.size()
	var visit_note := UiText.t("shop.visit_bought", {"count": str(bought)})
	_draw_text(visit_note, rect.position + Vector2(184, 30), 13, Color(TEXT, 0.68))

func _draw_shop_reroll_plate() -> void:
	var rect := SHOP_REROLL_RECT
	var enabled := _can_reroll() and not submitted
	var tint := Color(1, 1, 1, 0.88) if enabled else Color(1, 1, 1, 0.42)
	var texture_id := "button_reroll_disabled"
	if enabled:
		texture_id = "button_reroll_hover" if reroll_hovered else "button_reroll"
	if not _draw_shop_texture(texture_id, rect, tint):
		_draw_shop_texture("price_tag_wide", rect, tint)
	var text_color := Color(TEXT, tint.a)
	_draw_text(UiText.t("shop.reroll"), rect.position + Vector2(28, 33), 14, text_color)
	_draw_text(UiText.t("shop.reroll_price", {"amount": str(_reroll_price())}), rect.position + Vector2(128, 33), 11, Color("#f5d38f", tint.a))

func _selected_product_name() -> String:
	if ShopOfferCatalog.is_relic_choice(selected_choice):
		return RelicCatalog.display_name(_selected_relic_id())
	var choice := _choice_for_id(selected_choice)
	if not choice.is_empty():
		return str(choice.get("label", UiText.t("shop.no_selection")))
	return UiText.t("shop.no_selection")

func _selected_product_description() -> String:
	if ShopOfferCatalog.is_relic_choice(selected_choice):
		return RelicCatalog.short_description(_selected_relic_id())
	var choice := _choice_for_id(selected_choice)
	if not choice.is_empty():
		return str(choice.get("description", choice.get("note", "")))
	return ""

func _selected_product_price_text() -> String:
	if ShopOfferCatalog.is_relic_choice(selected_choice):
		return UiText.t("shop.gold_price", {"amount": RelicCatalog.shop_price(_selected_relic_id())})
	var choice := _choice_for_id(selected_choice)
	if not choice.is_empty():
		return UiText.t("shop.gold_price", {"amount": str(choice.get("price", abs(int(_result_for_choice(selected_choice).get("gold_delta", 0)))))})
	return ""

func _choice_for_id(choice_id: String) -> Dictionary:
	for choice in choices:
		if choice is Dictionary and str((choice as Dictionary).get("id", "")) == choice_id:
			return (choice as Dictionary)
	return {}

func _selected_relic_id() -> String:
	var relic_ids: Array = pending_result.get("relic_ids", [])
	if not relic_ids.is_empty():
		return str(relic_ids[0])
	return _relic_id_for_choice(selected_choice)

func _relic_id_for_choice(choice_id: String) -> String:
	var choice := _choice_for_id(choice_id)
	if not choice.is_empty():
		var result: Dictionary = choice.get("result", {})
		var relic_ids: Array = result.get("relic_ids", [])
		if not relic_ids.is_empty():
			return str(relic_ids[0])
	var index := ShopOfferCatalog.relic_choice_index(choice_id)
	if index >= 0 and index < offered_relic_ids.size():
		return offered_relic_ids[index]
	return ""

func _hover_choice(choice_id: String) -> void:
	if submitted:
		return
	hovered_choice = choice_id
	queue_redraw()

func _clear_hover(choice_id: String) -> void:
	if hovered_choice == choice_id:
		hovered_choice = ""
		queue_redraw()

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _draw_shop_texture(texture_id: String, rect: Rect2, tint: Color = Color.WHITE) -> bool:
	var texture := AssetCatalog.shop_runtime_texture(texture_id)
	if texture == null:
		return false
	draw_texture_rect(texture, rect, false, tint)
	return true

func _clip(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, max_chars - 1) + "."

func _wrap_words(text: String, max_chars: int, max_lines: int) -> Array[String]:
	var words := text.split(" ", false)
	var lines: Array[String] = []
	var line := ""
	for word in words:
		var candidate := str(word) if line == "" else line + " " + str(word)
		if candidate.length() > max_chars and line != "":
			lines.append(line)
			line = str(word)
			if lines.size() >= max_lines:
				return lines
		else:
			line = candidate
	if line != "" and lines.size() < max_lines:
		lines.append(line)
	return lines

func _draw_icon(node_type: String, rect: Rect2, tint: Color = Color(1, 1, 1, 0.7)) -> void:
	var texture: Texture2D = AssetCatalog.node_icon(node_type)
	if texture != null:
		draw_texture_rect(texture, rect, false, tint)
