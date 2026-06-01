extends SceneTree

const RunStateScript := preload("res://scripts/resources/run_state.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const MonsterMoveCatalog := preload("res://scripts/systems/monster_move_catalog.gd")
const RUN_SCENE := "res://scenes/run/run_root.tscn"

var failures: Array[String] = []

func _initialize() -> void:
	_check_run_reward_resources()
	_check_encounter_payload_boundaries()
	await _check_run_fail_path()

	if failures.is_empty():
		print("resource contract smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_run_reward_resources() -> void:
	var run_state: Resource = RunStateScript.new()
	run_state.gold = 12
	run_state.player_hp = 20
	run_state.player_max_hp = 42
	EffectResolver.apply_reward_result(run_state, {
		"accepted": true,
		"choice": "money",
		"gold_delta": 30,
		"hp_delta": 0,
		"relic_ids": [],
		"next_combat_mods": []
	})
	if int(run_state.gold) != 42:
		failures.append("reward money did not modify run gold")
	if int(run_state.player_hp) != 20:
		failures.append("reward money changed run HP")

	EffectResolver.apply_reward_result(run_state, {
		"accepted": true,
		"choice": "rest_heal",
		"gold_delta": 0,
		"hp_delta": 9,
		"relic_ids": [],
		"next_combat_mods": []
	})
	if int(run_state.gold) != 42:
		failures.append("rest heal changed run gold")
	if int(run_state.player_hp) != 29:
		failures.append("rest heal did not modify run HP")

	EffectResolver.apply_reward_result(run_state, {
		"accepted": true,
		"choice": "shop_relic",
		"gold_delta": -30,
		"hp_delta": 0,
		"relic_ids": ["loaded_die"],
		"next_combat_mods": []
	})
	if int(run_state.gold) != 12:
		failures.append("shop spend did not use run gold")
	if int(run_state.player_hp) != 29:
		failures.append("shop spend changed run HP")

func _check_encounter_payload_boundaries() -> void:
	var run_state: Resource = RunStateScript.new()
	run_state.gold = 99
	run_state.player_hp = 17
	run_state.player_max_hp = 42
	run_state.relic_ids.append("loaded_die")
	var payload: Dictionary = EffectResolver.build_encounter_payload(run_state, {
		"node_id": "n0",
		"node_type": "combat",
		"node_index": 0
	})
	if int(payload.get("player_hp", 0)) != 17:
		failures.append("encounter payload did not copy run HP")
	if not (payload.get("relic_ids", []) as Array).has("loaded_die"):
		failures.append("encounter payload did not carry relic IDs")
	if payload.has("gold"):
		failures.append("encounter payload should not expose legacy gold as a battle resource")
	if int(payload.get("run_gold", -1)) != 99:
		failures.append("encounter payload should carry run_gold for tax-style enemy moves")
	if payload.has("dice") or payload.has("marbles") or payload.has("placed_slots"):
		failures.append("encounter payload leaked battle attack resources")
	if not payload.has("combat_cash"):
		failures.append("encounter payload lacks battle-local combat_cash")
	var tax_result: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("tax_collection", {
		"player_hp": 17,
		"cash": int(payload.get("combat_cash", 0)),
		"run_gold": int(payload.get("run_gold", 0))
	}, 0)
	if int(tax_result.get("run_gold", 0)) != 95 or int(tax_result.get("gold_delta", 0)) != -4:
		failures.append("tax move should spend run_gold through the encounter payload")
	if int(tax_result.get("cash", 0)) != int(payload.get("combat_cash", 0)):
		failures.append("tax move should not spend battle-local combat_cash")

func _check_run_fail_path() -> void:
	var scene: PackedScene = load(RUN_SCENE)
	if scene == null:
		failures.append("could not load run root")
		return
	var run_root: Control = scene.instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(run_root)
	await _settle(8)
	if run_root.has_method("_test_force_run_failed"):
		run_root._test_force_run_failed()
		await _settle(3)
		if str(run_root.get("phase")) != "run_failed":
			failures.append("run fail path did not enter run_failed phase")
	else:
		failures.append("run root lacks test run fail helper")
	run_root.queue_free()
	await process_frame

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame
