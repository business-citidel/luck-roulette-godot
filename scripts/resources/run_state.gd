class_name RunState
extends Resource

@export var seed_text: String = ""
@export var gold: int = 0
@export var contract_tickets: int = 0
@export var player_hp: int = 30
@export var player_max_hp: int = 30
@export var character_id: String = "default_guard_dice"
@export var relic_ids: Array[String] = []
@export var relic_state: Dictionary = {}
@export var next_combat_mods: Array[Dictionary] = []
@export var run_upgrades: Dictionary = {}
@export var potion_ids: Array[String] = []
@export var potion_slots_max: int = 2
@export var floor_index: int = 1
@export var max_floor: int = 3
@export var map_variant: String = "scroll_20_random"
@export var map_theme_id: String = "01_base"
@export var map_step: int = 0
@export var completed_nodes: Array[String] = []

func to_payload() -> Dictionary:
	return {
		"seed_text": seed_text,
		"gold": gold,
		"contract_tickets": contract_tickets,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"character_id": character_id,
		"relic_ids": relic_ids.duplicate(),
		"relic_state": relic_state.duplicate(true),
		"next_combat_mods": next_combat_mods.duplicate(true),
		"run_upgrades": run_upgrades.duplicate(true),
		"potion_ids": potion_ids.duplicate(),
		"potion_slots_used": potion_ids.size(),
		"potion_slots_max": potion_slots_max,
		"floor_index": floor_index,
		"max_floor": max_floor,
		"map_variant": map_variant,
		"map_theme_id": map_theme_id,
		"map_step": map_step,
		"completed_nodes": completed_nodes.duplicate()
	}

func apply_payload(payload: Dictionary) -> void:
	seed_text = str(payload.get("seed_text", seed_text))
	gold = int(payload.get("gold", gold))
	contract_tickets = max(0, int(payload.get("contract_tickets", contract_tickets)))
	player_hp = int(payload.get("player_hp", player_hp))
	player_max_hp = int(payload.get("player_max_hp", player_max_hp))
	character_id = str(payload.get("character_id", character_id))
	relic_ids = _string_array(payload.get("relic_ids", relic_ids))
	relic_state = (payload.get("relic_state", relic_state) as Dictionary).duplicate(true)
	next_combat_mods = _dictionary_array(payload.get("next_combat_mods", next_combat_mods))
	run_upgrades = (payload.get("run_upgrades", run_upgrades) as Dictionary).duplicate(true)
	potion_ids = _string_array(payload.get("potion_ids", potion_ids))
	potion_slots_max = max(0, int(payload.get("potion_slots_max", potion_slots_max)))
	floor_index = int(payload.get("floor_index", floor_index))
	max_floor = int(payload.get("max_floor", max_floor))
	map_variant = str(payload.get("map_variant", map_variant))
	map_theme_id = str(payload.get("map_theme_id", map_theme_id))
	map_step = int(payload.get("map_step", map_step))
	completed_nodes = _string_array(payload.get("completed_nodes", completed_nodes))

func apply_reward(result: Dictionary) -> void:
	if result.has("player_max_hp"):
		player_max_hp = max(1, int(result.get("player_max_hp", player_max_hp)))
	if result.has("player_hp"):
		player_hp = clamp(int(result.get("player_hp", player_hp)), 0, player_max_hp)
	gold += int(result.get("gold_delta", 0))
	contract_tickets = max(0, contract_tickets + int(result.get("contract_tickets_delta", result.get("ticket_delta", 0))))
	player_hp = clamp(player_hp + int(result.get("hp_delta", 0)), 0, player_max_hp)
	for relic_id in result.get("relic_ids", []):
		var id: String = str(relic_id)
		if not relic_ids.has(id):
			relic_ids.append(id)
	if result.has("relic_state") and result.get("relic_state", {}) is Dictionary:
		relic_state = (result.get("relic_state", {}) as Dictionary).duplicate(true)
	for potion_id in result.get("potion_ids", []):
		if potion_ids.size() >= potion_slots_max:
			break
		var id: String = str(potion_id)
		if id != "":
			potion_ids.append(id)
	for potion_id in result.get("remove_potion_ids", result.get("potion_ids_remove", [])):
		var id: String = str(potion_id)
		if id != "":
			potion_ids.erase(id)
	for mod in result.get("next_combat_mods", []):
		if mod is Dictionary:
			next_combat_mods.append(mod.duplicate(true))
	for key in (result.get("run_upgrades", {}) as Dictionary).keys():
		var id := str(key)
		run_upgrades[id] = float(run_upgrades.get(id, 0.0)) + float((result.get("run_upgrades", {}) as Dictionary).get(key, 0.0))

func consume_next_combat_mods() -> Array[Dictionary]:
	var result: Array[Dictionary] = next_combat_mods.duplicate(true)
	next_combat_mods.clear()
	return result

func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for entry in value:
			result.append(str(entry))
	return result

func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for entry in value:
			if entry is Dictionary:
				result.append((entry as Dictionary).duplicate(true))
	return result
