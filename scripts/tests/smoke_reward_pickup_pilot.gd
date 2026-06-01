extends SceneTree

const RewardScene := preload("res://scenes/run/reward_scene.tscn")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_normal_reward_ticket_miss()
	await _check_normal_reward_ticket_hit()
	await _check_elite_reward()
	await _check_boss_reward()
	await _check_boss_reward_fallback()

	if failures.is_empty():
		print("reward pickup pilot smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_normal_reward_ticket_miss() -> void:
	var scene := _scene({
		"seed_text": "reward-smoke",
		"gold": 10,
		"contract_tickets": 0,
		"player_hp": 36,
		"player_max_hp": 42,
		"relic_ids": [],
		"next_combat_mods": []
	}, {
		"winnings": 18,
		"node_type": "combat",
		"reward_tier": "normal",
		"encounter_id": "normal_reward_smoke",
		"monster_id": "debt_collector",
		"turn": 1
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	var preview: Dictionary = scene.get_table_state().get("ledger", {})
	if int(preview.get("gold_preview", 0)) < 28:
		failures.append("normal reward did not preview base gold")
	if int(preview.get("contract_tickets_preview", 0)) != 0:
		failures.append("normal reward miss should not preview ticket gain")
	scene._choose_default()
	await process_frame
	if results.size() != 1:
		failures.append("normal reward did not emit exactly one result")
	else:
		var result: Dictionary = results[0]
		if str(result.get("choice", "")) != "combat_reward":
			failures.append("normal reward choice should be combat_reward")
		if int(result.get("gold_delta", 0)) < 18:
			failures.append("normal reward should include base winnings")
		if int(result.get("contract_tickets_delta", 0)) != 0:
			failures.append("normal reward miss should grant zero tickets")
		if int(result.get("ticket_chance", 0)) <= 0 or int(result.get("ticket_roll", -1)) < int(result.get("ticket_chance", 0)):
			failures.append("normal reward miss should expose a failed ticket roll")
		if not (result.get("relic_ids", []) as Array).is_empty():
			failures.append("normal reward should not grant direct relics")
	scene.queue_free()
	await process_frame

func _check_normal_reward_ticket_hit() -> void:
	var scene := _scene({
		"seed_text": "b",
		"gold": 10,
		"contract_tickets": 0,
		"player_hp": 36,
		"player_max_hp": 42,
		"relic_ids": [],
		"next_combat_mods": []
	}, {
		"winnings": 18,
		"node_type": "combat",
		"reward_tier": "normal",
		"encounter_id": "normal_reward_smoke",
		"monster_id": "debt_collector",
		"turn": 1
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	scene._choose_default()
	await process_frame
	if results.size() != 1:
		failures.append("normal reward ticket hit did not emit exactly one result")
	else:
		var result: Dictionary = results[0]
		if int(result.get("contract_tickets_delta", 0)) != 1:
			failures.append("normal reward ticket hit should grant exactly one ticket: " + str(result))
		if int(result.get("ticket_roll", 999)) >= int(result.get("ticket_chance", 0)):
			failures.append("normal reward ticket hit should expose a successful ticket roll")
	scene.queue_free()
	await process_frame

func _check_elite_reward() -> void:
	var scene := _scene({
		"gold": 10,
		"contract_tickets": 0,
		"player_hp": 36,
		"player_max_hp": 42,
		"relic_ids": [],
		"next_combat_mods": []
	}, {
		"winnings": 28,
		"node_type": "elite",
		"reward_tier": "elite",
		"encounter_id": "elite_reward_smoke",
		"monster_id": "elite_house"
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	scene._choose_default()
	await process_frame
	if results.size() != 1:
		failures.append("elite reward did not emit exactly one result")
	else:
		var result: Dictionary = results[0]
		if str(result.get("choice", "")) != "elite_reward":
			failures.append("elite reward choice should be elite_reward")
		if int(result.get("contract_tickets_delta", 0)) != 1:
			failures.append("elite reward should grant exactly one base ticket")
		if (result.get("relic_ids", []) as Array).is_empty():
			failures.append("elite reward should grant a relic")
		else:
			var relic_id := str((result.get("relic_ids", []) as Array)[0])
			if RelicCatalog.source_pool(relic_id) != RelicCatalog.SOURCE_RISK:
				failures.append("elite reward should grant risk-pool relic, got " + relic_id)
	scene.queue_free()
	await process_frame

func _check_boss_reward() -> void:
	var scene := _scene({
		"gold": 10,
		"contract_tickets": 0,
		"player_hp": 36,
		"player_max_hp": 42,
		"relic_ids": [],
		"next_combat_mods": []
	}, {
		"winnings": 40,
		"node_type": "boss",
		"reward_tier": "boss",
		"encounter_id": "boss_reward_smoke",
		"monster_id": "floor_boss"
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	scene._choose_default()
	await process_frame
	if results.size() != 1:
		failures.append("boss reward did not emit exactly one result")
	else:
		var result: Dictionary = results[0]
		if str(result.get("choice", "")) != "boss_reward":
			failures.append("boss reward choice should be boss_reward")
		if (result.get("relic_ids", []) as Array).is_empty():
			failures.append("boss reward should grant a relic")
		else:
			var relic_id := str((result.get("relic_ids", []) as Array)[0])
			if RelicCatalog.source_pool(relic_id) != RelicCatalog.SOURCE_BOSS:
				failures.append("boss reward should grant boss-pool relic, got " + relic_id)
	scene.queue_free()
	await process_frame

func _check_boss_reward_fallback() -> void:
	var scene := _scene({
		"gold": 10,
		"contract_tickets": 0,
		"player_hp": 36,
		"player_max_hp": 42,
		"relic_ids": RelicCatalog.reward_ids(RelicCatalog.SOURCE_BOSS),
		"next_combat_mods": []
	}, {
		"winnings": 40,
		"node_type": "boss",
		"reward_tier": "boss",
		"encounter_id": "boss_reward_fallback_smoke",
		"monster_id": "floor_boss"
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	scene._choose_default()
	await process_frame
	if results.size() != 1:
		failures.append("boss reward fallback did not emit exactly one result")
	else:
		var result: Dictionary = results[0]
		var relic_ids: Array = result.get("relic_ids", [])
		if relic_ids.is_empty():
			failures.append("boss reward fallback should grant a basic relic")
		else:
			var relic_id := str(relic_ids[0])
			if RelicCatalog.source_pool(relic_id) != RelicCatalog.SOURCE_BASIC:
				failures.append("boss reward fallback should use basic pool, got " + relic_id)
	scene.queue_free()
	await process_frame

func _scene(run_payload: Dictionary, combat_payload: Dictionary) -> Control:
	var scene: Control = RewardScene.instantiate()
	scene.configure({
		"run_state": run_payload,
		"combat_result": combat_payload
	})
	return scene
