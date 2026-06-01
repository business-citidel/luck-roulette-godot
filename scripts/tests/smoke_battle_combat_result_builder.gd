extends SceneTree

const BattleResultBuilder := preload("res://scripts/battle/battle_combat_result_builder.gd")
const BattleScene := preload("res://scenes/battle/battle_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_builder_contract()
	if failures.is_empty():
		print("battle combat result builder smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_builder_contract() -> void:
	var battle: Control = BattleScene.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set("last_encounter_payload", {
		"encounter_id": "stub-encounter",
		"node_type": "elite",
		"reward_tier": "risk",
		"is_final": false,
		"on_victory": "reward"
	})
	battle.set("enemy_hp", 0)
	battle.set("player_hp", 12)
	battle.set("player_max_hp", 42)
	battle.set("busts", 0)
	battle.set("cash", 33)
	battle.set("run_gold", 8)
	battle.set("gold_delta", 2)
	battle.set("banked", 5)
	battle.set("monster_id", "table_crook")
	battle.set("monster_name", "Table Crook")
	battle.set("monster_tier", "elite")
	battle.set("turn", 4)
	battle.set("enemy_damage_delta", 1)
	battle.set("enemy_damage_multiplier", 1.25)
	battle.set("enemy_block", 3)
	battle.set("player_attack_delta", 2)
	battle.set("player_damage_multiplier", 1.5)
	battle.set("player_block", 6)
	var relic_ids: Array[String] = ["loaded_die"]
	var potion_ids: Array[String] = ["red_recovery"]
	var consumed_potion_ids: Array[String] = ["red_recovery"]
	battle.set("active_relic_ids", relic_ids)
	battle.set("active_potion_ids", potion_ids)
	battle.set("consumed_potion_ids", consumed_potion_ids)
	battle.set("reward_chance_multiplier", 2.0)
	battle.set("active_relic_state", {"loaded_die": {"turns": 1}})
	battle.set("last_applied_effects", [{"effect_id": "stub_effect"}])
	var result: Dictionary = BattleResultBuilder.build("resolution", battle)
	_assert_eq(result.get("reason"), "resolution", "reason")
	_assert_eq(result.get("victory"), true, "victory")
	_assert_eq(result.get("defeat"), false, "defeat")
	_assert_eq(result.get("cash"), 33, "cash")
	_assert_eq(result.get("combat_cash"), 33, "combat_cash")
	_assert_eq(result.get("winnings"), 33, "winnings")
	_assert_eq(result.get("encounter_id"), "stub-encounter", "encounter_id")
	_assert_eq(result.get("node_type"), "elite", "node_type")
	_assert_eq(result.get("reward_tier"), "risk", "reward_tier")
	_assert_eq(result.get("monster_id"), "table_crook", "monster_id")
	_assert_eq(result.get("turn"), 4, "turn")
	var result_relics: Array = result.get("relic_ids") as Array
	var result_removed_potions: Array = result.get("remove_potion_ids") as Array
	_assert_eq(result_relics.size(), 1, "relic_ids")
	_assert_eq(result_removed_potions.size(), 1, "remove_potion_ids size")
	if not result_removed_potions.is_empty():
		_assert_eq(result_removed_potions[0], "red_recovery", "remove_potion_ids")
	_assert_eq((result.get("relic_state") as Dictionary).has("loaded_die"), true, "relic_state")
	_assert_eq((result.get("applied_effects") as Array).size(), 1, "applied_effects")
	battle.queue_free()
	await process_frame

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
