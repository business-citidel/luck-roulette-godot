extends SceneTree

const RunStateScript := preload("res://scripts/resources/run_state.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var run_state: Resource = RunStateScript.new()
	run_state.gold = 20
	run_state.player_hp = 30
	run_state.player_max_hp = 42
	run_state.relic_ids.append("loaded_die")

	EffectResolver.apply_reward_result(run_state, {
		"accepted": true,
		"choice": "sim_shop_relic",
		"gold_delta": -10,
		"hp_delta": 0,
		"relic_ids": ["green_purse"],
		"next_combat_mods": [{
			"id": "sim_prep",
			"enemy_damage_delta": -2
		}]
	})

	var encounter: Dictionary = EffectResolver.build_encounter_payload(run_state, {
		"node_id": "sim_elite",
		"node_type": "elite",
		"node_index": 1
	})
	if int(run_state.gold) != 10:
		failures.append("simulation gold did not apply shop spend")
	if run_state.relic_ids.size() != 2 or not run_state.relic_ids.has("green_purse"):
		failures.append("simulation relic IDs did not remain unique/persistent")
	if not (run_state.next_combat_mods as Array).is_empty():
		failures.append("simulation next combat modifier did not consume once")
	if int(encounter.get("enemy_hp", 0)) < 30:
		failures.append("simulation elite payload was not stronger")
	if ((encounter.get("move_pattern", []) as Array).is_empty()
			or str(encounter.get("monster_id", "")) == ""):
		failures.append("simulation elite payload lacked monster move contract")
	if int(encounter.get("combat_cash", 0)) <= 0:
		failures.append("simulation encounter payload had invalid resource values")
	if int(encounter.get("enemy_damage_delta", 0)) != -2:
		failures.append("simulation encounter did not carry direct damage modifier")
	if encounter.has("marbles") or encounter.has("placed_slots") or encounter.has("dice"):
		failures.append("simulation leaked battle-local resources into encounter payload")

	var second_encounter: Dictionary = EffectResolver.build_encounter_payload(run_state, {
		"node_id": "sim_combat",
		"node_type": "combat",
		"node_index": 2
	})
	if (second_encounter.get("next_combat_mods", []) as Array).size() > 0:
		failures.append("simulation next combat modifier appeared to apply twice")

	if failures.is_empty():
		print("core state simulation smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
