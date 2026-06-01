extends SceneTree

const RunStateScript := preload("res://scripts/resources/run_state.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var run_state: Resource = RunStateScript.new()
	run_state.player_hp = 37
	run_state.player_max_hp = 42
	run_state.relic_ids.append("loaded_die")
	run_state.relic_ids.append("green_purse")
	run_state.relic_ids.append("yellow_guard")
	run_state.relic_ids.append("purple_contract")
	run_state.relic_ids.append("bust_insurance")
	run_state.relic_ids.append("snake_eyes_charm")
	run_state.relic_ids.append("second_chance")

	if RelicCatalog.all_ids().size() < 8:
		failures.append("relic catalog has fewer than 8 relics")

	var encounter: Dictionary = EffectResolver.build_encounter_payload(run_state, {
		"node_id": "n2",
		"node_type": "combat",
		"node_index": 2
	})
	if not (encounter.get("relic_ids", []) as Array).has("loaded_die"):
		failures.append("encounter payload did not carry relic IDs")
	if int(encounter.get("enemy_damage_delta", 0)) != 0:
		failures.append("encounter damage payload changed unexpectedly")

	var elite_encounter: Dictionary = EffectResolver.build_encounter_payload(run_state, {
		"node_id": "n1e",
		"node_type": "elite",
		"node_index": 1
	})
	if int(elite_encounter.get("enemy_hp", 0)) <= int(encounter.get("enemy_hp", 0)):
		failures.append("elite encounter did not get stronger enemy HP")
	if ((elite_encounter.get("move_pattern", []) as Array).is_empty()
			or str(elite_encounter.get("monster_id", "")) == ""):
		failures.append("elite encounter did not receive monster move contract")

	var modded_payload: Dictionary = EffectResolver.apply_next_combat_mods_to_encounter_payload({
		"enemy_damage_delta": 0,
		"combat_cash": 18,
		"applied_effects": []
	}, [{
		"id": "rest_prepared_table",
		"enemy_damage_delta": -3,
		"combat_cash": 2
	}])
	if int(modded_payload.get("enemy_damage_delta", 0)) != -3 or int(modded_payload.get("combat_cash", 0)) != 20:
		failures.append("next combat modifier did not change encounter payload")

	var dice_result: Dictionary = EffectResolver.apply_relics_to_dice_result({
		"accepted": true,
		"dice_values": [2],
		"dice": [2],
		"dice_locked": [false],
		"rerolls_left": 0,
		"dice_rule_id": "single_attack_die"
	}, ["loaded_die"])
	var dice: Array = dice_result.get("dice", [])
	if dice.is_empty() or int(dice[0]) != 3 or int(dice_result.get("attack_base", 0)) != 3:
		failures.append("loaded_die did not change attack dice result")

	var snake_dice_result: Dictionary = EffectResolver.apply_relics_to_dice_result({
		"accepted": true,
		"dice_rule_id": "two_dice_sum_attack",
		"dice_values": [2, 2],
		"dice": [2, 2],
		"dice_locked": [false, false],
		"rerolls_left": 0
	}, ["snake_eyes_charm"])
	if int((snake_dice_result.get("dice", []) as Array)[0]) != 3:
		failures.append("snake_eyes_charm did not change doubles")

	var roulette_payload: Dictionary = EffectResolver.apply_relics_to_roulette_payload({
		"placed_slots": {"safe": [], "profit": ["plain"], "jackpot": [], "bust": [], "overdrive": []},
		"roulette_respins_left": 1
	}, ["second_chance"])
	if int(roulette_payload.get("roulette_respins_left", 0)) != 2:
		failures.append("second_chance did not add roulette respin")

	var resolution_payload: Dictionary = EffectResolver.apply_relics_to_resolution_payload({
		"pending_slot": "jackpot",
		"placed_slots": {"safe": ["plain"], "profit": ["plain"], "jackpot": ["plain"], "bust": [], "overdrive": []},
		"enemy_damage_delta": 0,
		"damage_multiplier": 1.0,
		"payout_multiplier": 1.0
	}, ["green_purse", "yellow_guard", "purple_contract"])
	if float(resolution_payload.get("damage_multiplier", 0.0)) <= 1.3:
		failures.append("jackpot-mark relic did not change damage multiplier")
	if int(resolution_payload.get("cash_delta_bonus", 0)) != 0:
		failures.append("profit relic should not trigger when roulette landed jackpot")
	if int(resolution_payload.get("enemy_damage_delta", 0)) != 0:
		failures.append("safe/jackpot relic landed-slot gating failed")

	var profit_resolution_payload: Dictionary = EffectResolver.apply_relics_to_resolution_payload({
		"pending_slot": "profit",
		"placed_slots": {"safe": [], "profit": ["plain"], "jackpot": [], "bust": [], "overdrive": []},
		"damage_multiplier": 1.0,
		"payout_multiplier": 1.0
	}, ["green_purse", "yellow_guard", "purple_contract"])
	if int(profit_resolution_payload.get("cash_delta_bonus", 0)) < 4:
		failures.append("profit-mark relic did not change economy bonus")

	var safe_resolution_payload: Dictionary = EffectResolver.apply_relics_to_resolution_payload({
		"pending_slot": "safe",
		"placed_slots": {"safe": ["plain"], "profit": [], "jackpot": [], "bust": [], "overdrive": []},
		"enemy_damage_delta": 0,
		"damage_multiplier": 1.0,
		"payout_multiplier": 1.0
	}, ["green_purse", "yellow_guard", "purple_contract"])
	if int(safe_resolution_payload.get("enemy_damage_delta", 0)) != -2:
		failures.append("safe-mark relic did not soften next enemy damage")

	var bust_result: Dictionary = EffectResolver.apply_relics_to_resolution_result({
		"cash": 10,
		"player_hp": 20,
		"bust_delta": 1,
		"message": "Bust."
	}, ["bust_insurance"])
	if int(bust_result.get("bust_delta", 1)) != 0 or int(bust_result.get("player_hp", 0)) != 22:
		failures.append("bust_insurance did not soften bust result")

	if failures.is_empty():
		print("effect resolver smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
