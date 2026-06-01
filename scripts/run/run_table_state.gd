class_name RunTableState
extends RefCounted

const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const PotionCatalog := preload("res://scripts/systems/potion_catalog.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

static func from_run_payload(run_payload: Dictionary, pending_result: Dictionary = {}) -> Dictionary:
	var payload := run_payload.duplicate(true)
	var preview := preview_payload(payload, pending_result)
	var relic_ids: Array = payload.get("relic_ids", [])
	var incoming_relic_ids: Array = pending_result.get("relic_ids", [])
	var prep_mods: Array = payload.get("next_combat_mods", [])
	var incoming_prep_mods: Array = pending_result.get("next_combat_mods", [])
	return {
		"ledger": _ledger(payload, pending_result, preview),
		"relic_tray": relic_items(relic_ids, incoming_relic_ids),
		"queued_prep_notes": prep_items(prep_mods, incoming_prep_mods),
		"pickup": pickup_summary(payload, pending_result, preview),
		"summary": {
			"relic_count": (preview.get("relic_ids", []) as Array).size(),
			"relic_summary": RelicCatalog.display_names(preview.get("relic_ids", []), 3),
			"prep_count": (preview.get("next_combat_mods", []) as Array).size()
		},
		"preview_payload": preview
	}

static func preview_payload(run_payload: Dictionary, pending_result: Dictionary = {}) -> Dictionary:
	var preview := run_payload.duplicate(true)
	if pending_result.is_empty():
		return preview
	var gold: int = int(preview.get("gold", 0)) + int(pending_result.get("gold_delta", 0))
	var tickets: int = max(0, int(preview.get("contract_tickets", 0)) + int(pending_result.get("contract_tickets_delta", pending_result.get("ticket_delta", 0))))
	var max_hp: int = int(preview.get("player_max_hp", 42))
	var hp: int = clampi(int(preview.get("player_hp", max_hp)) + int(pending_result.get("hp_delta", 0)), 0, max_hp)
	preview["gold"] = gold
	preview["contract_tickets"] = tickets
	preview["player_hp"] = hp
	preview["player_max_hp"] = max_hp
	preview["relic_ids"] = _merged_relic_ids(preview.get("relic_ids", []), pending_result.get("relic_ids", []))
	preview["next_combat_mods"] = _merged_mods(preview.get("next_combat_mods", []), pending_result.get("next_combat_mods", []))
	preview["potion_ids"] = _merged_potion_ids(preview.get("potion_ids", []), pending_result.get("potion_ids", []), int(preview.get("potion_slots_max", 2)))
	preview["potion_ids"] = _removed_potion_ids(preview.get("potion_ids", []), pending_result.get("remove_potion_ids", pending_result.get("potion_ids_remove", [])))
	preview["potion_slots_used"] = (preview.get("potion_ids", []) as Array).size()
	return preview

static func pickup_target(result: Dictionary) -> String:
	var choice := str(result.get("choice", ""))
	if choice == "relic" or choice == "shop_relic" or choice == "event_relic_trade":
		if not (result.get("relic_ids", []) as Array).is_empty():
			return "relic_tray"
	if choice == "shop_prep" or choice == "rest_prepare" or choice == "event_risk_gold":
		if not (result.get("next_combat_mods", []) as Array).is_empty():
			return "queued_prep_notes"
	if not (result.get("potion_ids", []) as Array).is_empty():
		return "ledger"
	if not (result.get("relic_ids", []) as Array).is_empty():
		return "relic_tray"
	if not (result.get("next_combat_mods", []) as Array).is_empty():
		return "queued_prep_notes"
	if int(result.get("gold_delta", 0)) != 0 or int(result.get("hp_delta", 0)) != 0 or int(result.get("contract_tickets_delta", result.get("ticket_delta", 0))) != 0:
		return "ledger"
	return "none"

static func relic_items(ids: Array, incoming_ids: Array = []) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var incoming_lookup := _string_lookup(incoming_ids)
	for id in ids:
		var relic_id := str(id)
		items.append({
			"id": relic_id,
			"name": RelicCatalog.display_name(relic_id),
			"icon_id": RelicCatalog.icon_id(relic_id),
			"description": RelicCatalog.short_description(relic_id),
			"state": "incoming" if incoming_lookup.has(relic_id) else "owned"
		})
	for id in incoming_ids:
		var relic_id := str(id)
		if _contains_relic_item(items, relic_id):
			continue
		items.append({
			"id": relic_id,
			"name": RelicCatalog.display_name(relic_id),
			"icon_id": RelicCatalog.icon_id(relic_id),
			"description": RelicCatalog.short_description(relic_id),
			"state": "incoming"
		})
	return items

static func prep_items(mods: Array, incoming_mods: Array = []) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var incoming_lookup := _mod_lookup(incoming_mods)
	for mod in mods:
		if not (mod is Dictionary):
			continue
		var mod_dict: Dictionary = (mod as Dictionary).duplicate(true)
		var id := str(mod_dict.get("id", "prep_note"))
		items.append({
			"id": id,
			"label": _prep_label(id),
			"description": _prep_description(mod_dict),
			"state": "incoming" if incoming_lookup.has(id) else "queued"
		})
	for mod in incoming_mods:
		if not (mod is Dictionary):
			continue
		var mod_dict: Dictionary = (mod as Dictionary).duplicate(true)
		var id := str(mod_dict.get("id", "prep_note"))
		if _contains_prep_item(items, id):
			continue
		items.append({
			"id": id,
			"label": _prep_label(id),
			"description": _prep_description(mod_dict),
			"state": "incoming"
		})
	return items

static func pickup_summary(run_payload: Dictionary, result: Dictionary, preview_payload_value: Dictionary = {}) -> Dictionary:
	if result.is_empty():
		return {
			"choice": "",
			"target": "none",
			"label": UiText.t("table.pickup.waiting"),
			"lines": [UiText.t("table.pickup.waiting_line")]
		}
	var preview := preview_payload_value if not preview_payload_value.is_empty() else preview_payload(run_payload, result)
	var lines: Array[String] = []
	var gold_delta := int(result.get("gold_delta", 0))
	if gold_delta != 0:
		var old_gold := int(run_payload.get("gold", 0))
		var new_gold := int(preview.get("gold", old_gold))
		if gold_delta < 0:
			lines.append(UiText.t("table.pickup.gold_loss", {"old": old_gold, "new": new_gold, "delta": gold_delta}))
		else:
			lines.append(UiText.t("table.pickup.gold_gain", {"delta": gold_delta, "new": new_gold}))
	var ticket_delta := int(result.get("contract_tickets_delta", result.get("ticket_delta", 0)))
	if ticket_delta != 0:
		var old_tickets := int(run_payload.get("contract_tickets", 0))
		var new_tickets := int(preview.get("contract_tickets", old_tickets))
		if ticket_delta < 0:
			lines.append(UiText.t("table.pickup.ticket_loss", {"old": old_tickets, "new": new_tickets, "delta": ticket_delta}))
		else:
			lines.append(UiText.t("table.pickup.ticket_gain", {"delta": ticket_delta, "new": new_tickets}))
	var hp_delta := int(result.get("hp_delta", 0))
	if hp_delta != 0:
		var old_hp := int(run_payload.get("player_hp", 0))
		var new_hp := int(preview.get("player_hp", old_hp))
		var max_hp := int(preview.get("player_max_hp", 42))
		if hp_delta < 0:
			lines.append(UiText.t("table.pickup.hp_loss", {"old": old_hp, "new": new_hp, "max": max_hp, "delta": hp_delta}))
		else:
			lines.append(UiText.t("table.pickup.hp_gain", {"delta": hp_delta, "new": new_hp, "max": max_hp}))
	for id in result.get("relic_ids", []):
		lines.append(UiText.t("table.pickup.relic_added", {"relic": RelicCatalog.display_name(str(id))}))
	for mod in result.get("next_combat_mods", []):
		if mod is Dictionary:
			lines.append(UiText.t("table.pickup.prep", {"description": _prep_description(mod as Dictionary)}))
	for potion_id in result.get("potion_ids", []):
		lines.append(UiText.t("table.pickup.potion_added", {"potion": _potion_label(str(potion_id))}))
	for potion_id in result.get("remove_potion_ids", result.get("potion_ids_remove", [])):
		lines.append(UiText.t("table.pickup.potion_removed", {"potion": _potion_label(str(potion_id))}))
	if lines.is_empty():
		lines.append(UiText.t("table.pickup.no_change"))
	return {
		"choice": str(result.get("choice", "")),
		"target": pickup_target(result),
		"label": _choice_label(str(result.get("choice", ""))),
		"lines": lines
	}

static func _ledger(payload: Dictionary, result: Dictionary, preview: Dictionary) -> Dictionary:
	return {
		"hp": int(payload.get("player_hp", 42)),
		"max_hp": int(payload.get("player_max_hp", 42)),
		"gold": int(payload.get("gold", 0)),
		"contract_tickets": int(payload.get("contract_tickets", 0)),
		"hp_preview": int(preview.get("player_hp", payload.get("player_hp", 42))),
		"gold_preview": int(preview.get("gold", payload.get("gold", 0))),
		"contract_tickets_preview": int(preview.get("contract_tickets", payload.get("contract_tickets", 0))),
		"gold_delta": int(result.get("gold_delta", 0)),
		"contract_tickets_delta": int(result.get("contract_tickets_delta", result.get("ticket_delta", 0))),
		"hp_delta": int(result.get("hp_delta", 0)),
		"potion_slots_used": int(payload.get("potion_slots_used", (payload.get("potion_ids", []) as Array).size())),
		"potion_slots_max": int(payload.get("potion_slots_max", 2))
	}

static func _merged_relic_ids(existing: Array, incoming: Array) -> Array[String]:
	var result: Array[String] = []
	for id in existing:
		result.append(str(id))
	for id in incoming:
		var relic_id := str(id)
		if not result.has(relic_id):
			result.append(relic_id)
	return result

static func _merged_mods(existing: Array, incoming: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for mod in existing:
		if mod is Dictionary:
			result.append((mod as Dictionary).duplicate(true))
	for mod in incoming:
		if mod is Dictionary:
			result.append((mod as Dictionary).duplicate(true))
	return result

static func _merged_potion_ids(existing: Array, incoming: Array, max_slots: int) -> Array[String]:
	var result: Array[String] = []
	for id in existing:
		if result.size() >= max_slots:
			return result
		result.append(str(id))
	for id in incoming:
		if result.size() >= max_slots:
			return result
		var potion_id := str(id)
		if potion_id != "":
			result.append(potion_id)
	return result

static func _removed_potion_ids(existing: Array, removed: Array) -> Array[String]:
	var result: Array[String] = []
	var removed_ids: Array[String] = []
	for id in removed:
		removed_ids.append(str(id))
	for id in existing:
		var potion_id := str(id)
		if removed_ids.has(potion_id):
			removed_ids.erase(potion_id)
			continue
		result.append(potion_id)
	return result

static func _string_lookup(ids: Array) -> Dictionary:
	var lookup := {}
	for id in ids:
		lookup[str(id)] = true
	return lookup

static func _mod_lookup(mods: Array) -> Dictionary:
	var lookup := {}
	for mod in mods:
		if mod is Dictionary:
			lookup[str((mod as Dictionary).get("id", "prep_note"))] = true
	return lookup

static func _contains_relic_item(items: Array[Dictionary], relic_id: String) -> bool:
	for item in items:
		if str(item.get("id", "")) == relic_id:
			return true
	return false

static func _contains_prep_item(items: Array[Dictionary], prep_id: String) -> bool:
	for item in items:
		if str(item.get("id", "")) == prep_id:
			return true
	return false

static func _choice_label(choice: String) -> String:
	match choice:
		"money":
			return UiText.t("table.choice.money")
		"relic":
			return UiText.t("table.choice.relic")
		"heal":
			return UiText.t("table.choice.heal")
		"shop_relic":
			return UiText.t("table.choice.shop_relic")
		"shop_prep", "rest_prepare":
			return UiText.t("table.choice.prep")
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
		"rest_heal":
			return UiText.t("table.choice.rest_heal")
		"rest_leave":
			return UiText.t("table.choice.rest_leave")
		"rest_ticket_exchange":
			return UiText.t("table.choice.rest_ticket_exchange")
		"ticket_random_potion":
			return UiText.t("table.choice.ticket_random_potion")
		"ticket_upgrade_voucher":
			return UiText.t("table.choice.ticket_upgrade_voucher")
		"ticket_small_heal":
			return UiText.t("table.choice.ticket_small_heal")
		"ticket_random_relic":
			return UiText.t("table.choice.ticket_random_relic")
		"combat_reward":
			return UiText.t("table.choice.combat_reward")
		"elite_reward":
			return UiText.t("table.choice.elite_reward")
		_:
			return UiText.t("table.choice.result")

static func _prep_label(id: String) -> String:
	var words := id.replace("_", " ").split(" ")
	var label_parts: Array[String] = []
	for word in words:
		if word == "":
			continue
		label_parts.append(word.substr(0, 1).to_upper() + word.substr(1))
	return " ".join(label_parts)

static func _prep_description(mod: Dictionary) -> String:
	var parts: Array[String] = []
	if int(mod.get("enemy_damage_delta", 0)) != 0:
		var damage_delta := int(mod.get("enemy_damage_delta", 0))
		if damage_delta > 0:
			parts.append(UiText.t("table.prep.damage_up", {"amount": damage_delta}))
		else:
			parts.append(UiText.t("table.prep.damage_down", {"amount": abs(damage_delta)}))
	if int(mod.get("cash", 0)) != 0:
		parts.append("Cash +" + str(int(mod.get("cash", 0))))
	if int(mod.get("combat_cash", 0)) != 0:
		parts.append("Stake +" + str(int(mod.get("combat_cash", 0))))
	if int(mod.get("rerolls", 0)) != 0:
		parts.append("Reroll +" + str(int(mod.get("rerolls", 0))))
	if parts.is_empty():
		return UiText.t("table.prep.default")
	return ", ".join(parts)

static func _potion_label(id: String) -> String:
	return UiText.t(PotionCatalog.display_key(id), {"fallback": id})
