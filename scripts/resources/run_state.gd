class_name RunState
extends Resource

const MarbleCatalog := preload("res://scripts/systems/marble_catalog.gd")

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
@export var marble_deck: Array[Dictionary] = []
@export var next_marble_instance_number: int = 1

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
		"completed_nodes": completed_nodes.duplicate(),
		"marble_deck": marble_deck.duplicate(true),
		"next_marble_instance_number": next_marble_instance_number
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
	if payload.has("marble_deck"):
		marble_deck = _dictionary_array(payload.get("marble_deck", []))
	next_marble_instance_number = max(1, int(payload.get("next_marble_instance_number", next_marble_instance_number)))

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
	for marble_id in result.get("add_marble_ids", result.get("marble_ids", [])):
		add_marble(str(marble_id), str(result.get("source", "reward")), false)
	for marble in result.get("add_marbles", result.get("marble_instances", [])):
		if marble is Dictionary:
			add_marble_instance(marble as Dictionary)
	for instance_id in result.get("remove_marble_instance_ids", []):
		remove_marble_instance(str(instance_id))
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

func reset_starting_marbles() -> void:
	marble_deck.clear()
	next_marble_instance_number = 1
	for marble_id in MarbleCatalog.starting_deck_ids():
		add_marble(str(marble_id), "starting_deck", false)

func add_marble(marble_id: String, source: String = "reward", is_temporary: bool = false) -> Dictionary:
	var instance_id := "run_marble_%03d" % next_marble_instance_number
	next_marble_instance_number += 1
	var instance := MarbleCatalog.instance_from_id(instance_id, marble_id, source, is_temporary)
	marble_deck.append(instance)
	return instance.duplicate(true)

func add_marble_instance(marble: Dictionary) -> Dictionary:
	var marble_id := MarbleCatalog.normalize_id(str(marble.get("marble_id", MarbleCatalog.PLAIN)))
	var instance_id := str(marble.get("instance_id", ""))
	if instance_id == "":
		return add_marble(marble_id, str(marble.get("source", "external")), bool(marble.get("is_temporary", false)))
	var instance := MarbleCatalog.instance_from_id(instance_id, marble_id, str(marble.get("source", "external")), bool(marble.get("is_temporary", false)))
	marble_deck.append(instance)
	return instance.duplicate(true)

func remove_marble_instance(instance_id: String) -> bool:
	for i in range(marble_deck.size()):
		if str(marble_deck[i].get("instance_id", "")) == instance_id:
			marble_deck.remove_at(i)
			return true
	return false

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
