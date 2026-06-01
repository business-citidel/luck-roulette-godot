extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const RestActionCatalog := preload("res://scripts/systems/rest_action_catalog.gd")
const RunStateScript := preload("res://scripts/resources/run_state.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	_assert_run_upgrade_persistence()
	await _assert_combat_uses_run_upgrades()
	_assert_new_run_resets_upgrades()

	if failures.is_empty():
		print("rest run upgrade contract smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _assert_run_upgrade_persistence() -> void:
	var run_state = RunStateScript.new()
	run_state.apply_reward(RestActionCatalog.result("upgrade_primary_die"))
	run_state.apply_reward(RestActionCatalog.result("upgrade_secondary_die"))
	run_state.apply_reward(RestActionCatalog.result("upgrade_roulette"))
	run_state.apply_reward({
		"accepted": true,
		"choice": "upgrade_roulette_cell",
		"gold_delta": 0,
		"hp_delta": 0,
		"relic_ids": [],
		"next_combat_mods": [],
		"run_upgrades": {"numeric_roulette_cell_bonus_1": 0.5}
	})
	if float(run_state.run_upgrades.get("primary_die_bonus", 0.0)) != 1.0:
		failures.append("primary die upgrade was not stored on run state")
	if float(run_state.run_upgrades.get("secondary_die_bonus", 0.0)) != 1.0:
		failures.append("secondary die upgrade was not stored on run state")
	if abs(float(run_state.run_upgrades.get("roulette_bonus", 0.0)) - 0.2) > 0.001:
		failures.append("roulette upgrade was not stored on run state")
	if abs(float(run_state.run_upgrades.get("numeric_roulette_cell_bonus_1", 0.0)) - 0.5) > 0.001:
		failures.append("roulette cell upgrade was not stored on run state")

	var payload := EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter("crook_table"))
	var upgrades: Dictionary = payload.get("run_upgrades", {})
	if float(upgrades.get("primary_die_bonus", 0.0)) != 1.0:
		failures.append("encounter payload did not carry primary die upgrade")
	if float(upgrades.get("secondary_die_bonus", 0.0)) != 1.0:
		failures.append("encounter payload did not carry secondary die upgrade")
	if run_state.run_upgrades.is_empty():
		failures.append("run upgrades were consumed like one-combat prep mods")

func _assert_combat_uses_run_upgrades() -> void:
	var battle: Control = BattleScene.instantiate()
	root.add_child(battle)
	await process_frame
	if not battle.has_method("configure_encounter"):
		failures.append("BattleScene script did not load for run upgrade contract")
		battle.queue_free()
		await process_frame
		return
	battle.configure_encounter({
		"monster_id": "table_crook",
		"monster_name": "Table Crook",
		"combat_cash": 20,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 80,
		"enemy_max_hp": 80,
		"dice_rule_id": "single_attack_die",
		"relic_ids": [],
		"run_upgrades": {
			"primary_die_bonus": 1.0,
			"secondary_die_bonus": 1.0,
			"roulette_bonus": 0.2,
			"marble_bonus": 1.0
		},
		"move_pattern": ["hp_strike"],
		"current_move_id": "hp_strike",
		"applied_effects": []
	})
	await process_frame
	var dice_result: Dictionary = battle._apply_dice_run_upgrades({"attack_base": 3})
	if int(dice_result.get("attack_base", 0)) != 4:
		failures.append("combat did not apply primary_die_bonus")
	var guard_result: Dictionary = battle._apply_dice_run_upgrades({"attack_base": 3, "guard_value": 2, "player_block": 2})
	if int(guard_result.get("guard_value", 0)) != 3 or int(guard_result.get("player_block", 0)) != 3:
		failures.append("combat did not apply secondary_die_bonus")
	var resolution: Dictionary = battle._apply_resolution_run_upgrades({
		"pending_slot": "safe",
		"placed_slots": {"safe": ["plain"], "bust": [], "profit": [], "overdrive": [], "jackpot": []},
		"damage_multiplier": 1.0,
		"payout_multiplier": 1.0
	})
	if abs(float(resolution.get("damage_multiplier", 0.0)) - 0.6) > 0.001:
		failures.append("combat did not apply roulette + marble multiplier bonuses")
	var jackpot_resolution: Dictionary = battle._apply_resolution_run_upgrades({
		"pending_slot": "jackpot",
		"placed_slots": {"safe": [], "bust": [], "profit": [], "overdrive": [], "jackpot": ["plain"]},
		"damage_multiplier": 1.0,
		"payout_multiplier": 1.0
	})
	if abs(float(jackpot_resolution.get("damage_multiplier", 0.0)) - 2.4) > 0.001:
		failures.append("combat did not apply high-risk jackpot marble multiplier")
	battle.queue_free()
	await process_frame

func _assert_new_run_resets_upgrades() -> void:
	var fresh_run = RunStateScript.new()
	if not fresh_run.run_upgrades.is_empty():
		failures.append("fresh run state should not start with rest upgrades")
