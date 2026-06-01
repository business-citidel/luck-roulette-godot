class_name EffectResolver
extends RefCounted

const RelicEffectResolver := preload("res://scripts/systems/relic_effect_resolver.gd")
const MonsterCatalog := preload("res://scripts/systems/monster_catalog.gd")
const CharacterContractCatalog := preload("res://scripts/systems/character_contract_catalog.gd")
const PotionCatalog := preload("res://scripts/systems/potion_catalog.gd")

static func build_encounter_payload(run_state: Variant, map_node: Dictionary) -> Dictionary:
	var node_type: String = str(_read(map_node, "node_type", _read(map_node, "type", "combat")))
	var is_elite: bool = node_type == "elite"
	var is_final: bool = bool(_read(map_node, "is_final", node_type == "boss"))
	var node_index: int = int(_read(map_node, "node_index", _read(map_node, "index", 0)))
	var floor_index: int = int(_read(run_state, "floor_index", int(_read(map_node, "floor_index", 1))))
	var seed_text: String = str(_read(run_state, "seed_text", _read(map_node, "seed_text", "")))
	var monster_id: String = str(_read(map_node, "monster_id", MonsterCatalog.id_for_node(node_type, node_index, floor_index, seed_text)))
	var monster_fields: Dictionary = MonsterCatalog.build_encounter_fields(monster_id)
	var character_id: String = str(_read(run_state, "character_id", CharacterContractCatalog.default_character_id()))
	var character := CharacterContractCatalog.get_character(character_id)
	var relic_ids := _string_array(_read(run_state, "relic_ids", []))
	for starter_id in CharacterContractCatalog.starting_relic_ids(character_id):
		if not relic_ids.has(starter_id):
			relic_ids.append(starter_id)
	var payload := {
		"encounter_id": str(_read(map_node, "encounter_id", "")),
		"node_id": str(_read(map_node, "node_id", _read(map_node, "id", ""))),
		"node_type": node_type,
		"node_index": node_index,
		"floor_index": floor_index,
		"reward_tier": str(_read(map_node, "reward_tier", "elite" if is_elite else "normal")),
		"is_final": is_final,
		"on_victory": str(_read(map_node, "on_victory", "run_clear" if is_final else "reward")),
		"monster_id": monster_fields.get("monster_id", monster_id),
		"monster_name": monster_fields.get("monster_name", monster_id),
		"monster_tier": monster_fields.get("monster_tier", "normal"),
		"monster_pattern_role": str(monster_fields.get("monster_pattern_role", "")),
		"monster_pattern_read": str(monster_fields.get("monster_pattern_read", "")),
		"monster_pattern_tuning": _upgrade_dict(monster_fields.get("monster_pattern_tuning", {})),
		"player_hp": int(_read(run_state, "player_hp", 42)),
		"player_max_hp": int(_read(run_state, "player_max_hp", 42)),
		"run_gold": int(_read(run_state, "gold", 0)),
		"enemy_hp": int(monster_fields.get("enemy_hp", 30 if is_elite else 18)),
		"enemy_max_hp": int(monster_fields.get("enemy_max_hp", 30 if is_elite else 18)),
		"combat_cash": int(monster_fields.get("combat_cash", 20 if is_elite else 18)),
		"enemy_damage_delta": 0,
		"character_id": character_id,
		"character_name": str(character.get("name", character_id)),
		"character_rule_text": str(character.get("rule_text", "")),
		"dice_rule_id": str(character.get("dice_rule_id", "two_dice_attack_guard")),
		"relic_ids": relic_ids,
		"potion_ids": _combat_potion_ids(_read(run_state, "potion_ids", [])),
		"potion_slots_max": int(_read(run_state, "potion_slots_max", 2)),
		"run_upgrades": _upgrade_dict(_read(run_state, "run_upgrades", {})),
		"move_pattern": _string_array(monster_fields.get("move_pattern", [])),
		"current_move_id": str(monster_fields.get("current_move_id", "hp_strike")),
		"enemy_intent": str(monster_fields.get("enemy_intent", "")),
		"next_combat_mods": _mod_array(_read(run_state, "next_combat_mods", [])),
		"applied_effects": []
	}
	payload = apply_floor_scaling_to_encounter_payload(payload, floor_index)
	payload = apply_next_combat_mods_to_encounter_payload(payload, payload["next_combat_mods"])
	if run_state != null and not (run_state is Dictionary) and run_state.has_method("consume_next_combat_mods"):
		run_state.consume_next_combat_mods()
	payload = apply_relic_trigger(RelicEffectResolver.COMBAT_START, payload, payload["relic_ids"])
	return payload

static func apply_floor_scaling_to_encounter_payload(payload: Dictionary, floor_index: int) -> Dictionary:
	var result := payload.duplicate(true)
	var floor: int = max(1, floor_index)
	var hp_bonus: int = 0
	var damage_bonus: int = 0
	if floor == 2:
		hp_bonus = 8
		damage_bonus = 1
	elif floor >= 3:
		hp_bonus = 16
		damage_bonus = 3
	if hp_bonus != 0:
		result["enemy_hp"] = int(result.get("enemy_hp", 0)) + hp_bonus
		result["enemy_max_hp"] = int(result.get("enemy_max_hp", result.get("enemy_hp", 0))) + hp_bonus
		result["floor_enemy_hp_bonus"] = hp_bonus
	if damage_bonus != 0:
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) + damage_bonus
		result["floor_enemy_damage_delta"] = damage_bonus
		_record(result, "floor_scaling", "floor_" + str(floor) + "_enemy_power")
	return result

static func apply_next_combat_mods_to_encounter_payload(payload: Dictionary, mods: Array) -> Dictionary:
	var result := payload.duplicate(true)
	result["applied_effects"] = _effects(result)
	for mod in mods:
		if not mod is Dictionary:
			continue
		var id: String = str(mod.get("id", "next_combat_mod"))
		if mod.has("enemy_damage_delta"):
			result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) + int(mod.get("enemy_damage_delta", 0))
		if mod.has("combat_cash"):
			result["combat_cash"] = int(result.get("combat_cash", 0)) + int(mod.get("combat_cash", 0))
		_record(result, "run_mod", id)
	return result

static func apply_relics_to_encounter_payload(payload: Dictionary, relic_ids: Array) -> Dictionary:
	return apply_relic_trigger(RelicEffectResolver.COMBAT_START, payload, relic_ids)

static func apply_relics_to_dice_result(result: Dictionary, relic_ids: Array) -> Dictionary:
	return apply_relic_trigger(RelicEffectResolver.DICE_RESULT, result, relic_ids)

static func apply_relics_to_marble_payload(payload: Dictionary, relic_ids: Array) -> Dictionary:
	return apply_relic_trigger(RelicEffectResolver.MARBLE_GAIN, payload, relic_ids)

static func apply_relics_to_roulette_payload(payload: Dictionary, relic_ids: Array) -> Dictionary:
	return apply_relic_trigger(RelicEffectResolver.ROULETTE_BEFORE_SPIN, payload, relic_ids)

static func apply_relics_to_resolution_payload(payload: Dictionary, relic_ids: Array) -> Dictionary:
	return apply_relic_trigger(RelicEffectResolver.RESOLUTION_BEFORE, payload, relic_ids)

static func apply_relics_to_resolution_result(result: Dictionary, relic_ids: Array) -> Dictionary:
	return apply_relic_trigger(RelicEffectResolver.RESOLUTION_AFTER, result, relic_ids)

static func apply_relic_trigger(trigger: String, payload: Dictionary, relic_ids: Array) -> Dictionary:
	return RelicEffectResolver.apply(trigger, payload, relic_ids)

static func apply_reward_result(run_state: Variant, reward_result: Dictionary) -> Variant:
	if run_state != null and run_state.has_method("apply_reward"):
		var owned_relic_ids := _string_array(_read(run_state, "relic_ids", []))
		var payload := reward_result.duplicate(true)
		if not bool(payload.get("relic_reward_effects_applied", false)):
			payload["seed_text"] = str(_read(run_state, "seed_text", payload.get("seed_text", "")))
			payload["player_hp"] = int(_read(run_state, "player_hp", payload.get("player_hp", 0)))
			payload["player_max_hp"] = int(_read(run_state, "player_max_hp", payload.get("player_max_hp", 0)))
			payload["contract_tickets"] = int(_read(run_state, "contract_tickets", payload.get("contract_tickets", 0)))
			payload["gold"] = int(_read(run_state, "gold", payload.get("gold", 0)))
			payload["floor_index"] = int(_read(run_state, "floor_index", payload.get("floor_index", 1)))
			payload["map_step"] = int(_read(run_state, "map_step", payload.get("map_step", 0)))
			payload["relic_state"] = _upgrade_dict(_read(run_state, "relic_state", payload.get("relic_state", {})))
			payload = apply_relic_trigger(RelicEffectResolver.REWARD_APPLY, payload, owned_relic_ids)
			for relic_id in payload.get("relic_ids", []):
				var id := str(relic_id)
				if id == "" or owned_relic_ids.has(id):
					continue
				payload["picked_relic_id"] = id
				payload = apply_relic_trigger(RelicEffectResolver.RELIC_PICKUP, payload, [id])
			payload["relic_reward_effects_applied"] = true
		run_state.apply_reward(payload)
	return run_state

static func _effects(payload: Dictionary) -> Array:
	var effects: Array = []
	for item in payload.get("applied_effects", []):
		effects.append(item)
	return effects

static func _record(payload: Dictionary, source_id: String, effect_id: String) -> void:
	var effects: Array = _effects(payload)
	effects.append({
		"relic_id": source_id,
		"effect_id": effect_id,
		"name": effect_id
	})
	payload["applied_effects"] = effects

static func _read(source: Variant, key: String, fallback: Variant) -> Variant:
	if source is Dictionary:
		return source.get(key, fallback)
	if source != null:
		return source.get(key) if source.get(key) != null else fallback
	return fallback

static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result

static func _combat_potion_ids(value: Variant) -> Array[String]:
	var result: Array[String] = []
	for id in _string_array(value):
		if PotionCatalog.is_combat_potion(id):
			result.append(id)
	return result

static func _mod_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				result.append(item.duplicate(true))
	return result

static func _upgrade_dict(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if value is Dictionary:
		for key in value.keys():
			result[str(key)] = float(value.get(key, 0.0))
	return result
