class_name BattleCombatResultBuilder
extends RefCounted

static func build(reason: String, battle: Object) -> Dictionary:
	var encounter_payload: Dictionary = _dict(battle.get("last_encounter_payload"))
	return {
		"accepted": true,
		"reason": reason,
		"victory": int(battle.get("enemy_hp")) <= 0,
		"defeat": int(battle.get("player_hp")) <= 0 or int(battle.get("busts")) >= 2,
		"cash": int(battle.get("cash")),
		"combat_cash": int(battle.get("cash")),
		"winnings": int(battle.get("cash")),
		"run_gold": int(battle.get("run_gold")),
		"gold_delta": int(battle.get("gold_delta")),
		"banked": int(battle.get("banked")),
		"player_hp": int(battle.get("player_hp")),
		"player_max_hp": int(battle.get("player_max_hp")),
		"enemy_hp": int(battle.get("enemy_hp")),
		"encounter_id": str(encounter_payload.get("encounter_id", "")),
		"node_type": str(encounter_payload.get("node_type", "")),
		"reward_tier": str(encounter_payload.get("reward_tier", "")),
		"is_final": bool(encounter_payload.get("is_final", false)),
		"on_victory": str(encounter_payload.get("on_victory", "")),
		"monster_id": str(battle.get("monster_id")),
		"monster_name": str(battle.get("monster_name")),
		"monster_tier": str(battle.get("monster_tier")),
		"turn": int(battle.get("turn")),
		"enemy_damage_delta": int(battle.get("enemy_damage_delta")),
		"enemy_damage_multiplier": float(battle.get("enemy_damage_multiplier")),
		"enemy_block": int(battle.get("enemy_block")),
		"player_attack_delta": int(battle.get("player_attack_delta")),
		"player_damage_multiplier": float(battle.get("player_damage_multiplier")),
		"player_block": int(battle.get("player_block")),
		"busts": int(battle.get("busts")),
		"relic_ids": _array_duplicate(battle.get("active_relic_ids")),
		"potion_ids": _array_duplicate(battle.get("active_potion_ids")),
		"remove_potion_ids": _array_duplicate(battle.get("consumed_potion_ids")),
		"reward_chance_multiplier": float(battle.get("reward_chance_multiplier")),
		"relic_state": _dict(battle.get("active_relic_state")),
		"applied_effects": _array_duplicate(battle.get("last_applied_effects"))
	}

static func _array_duplicate(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []

static func _dict(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}

