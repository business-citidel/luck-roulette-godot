extends SceneTree

const RestScene := preload("res://scenes/run/rest_scene.tscn")
const RunStateScript := preload("res://scripts/resources/run_state.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_upgrade_voucher_cost_gates()
	await _check_upgrade_voucher_allows_extra_pick_after_paid_upgrade()
	_check_run_state_removes_vouchers()

	if failures.is_empty():
		print("rest upgrade voucher smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_upgrade_voucher_cost_gates() -> void:
	var scene: Control = RestScene.instantiate()
	scene.configure({
		"run_state": {
			"gold": 12,
			"contract_tickets": 0,
			"potion_ids": [],
			"potion_slots_used": 0,
			"potion_slots_max": 2,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": ["loaded_die"],
			"next_combat_mods": [],
			"run_upgrades": {}
		},
		"map_result": {}
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	scene._choose_by_id("rest_tune")
	await process_frame
	scene._choose_upgrade("upgrade_primary_die")
	await process_frame
	scene._choose_upgrade("upgrade_roulette")
	await process_frame
	if results.size() != 0:
		failures.append("paid upgrades should not resolve without vouchers")
	scene._choose_upgrade("upgrade_roulette_cell")
	await process_frame
	scene._choose_roulette_cell(1)
	await process_frame
	if results.size() != 0:
		failures.append("roulette cell upgrade should not resolve without vouchers")
	scene.queue_free()
	await process_frame

func _check_upgrade_voucher_allows_extra_pick_after_paid_upgrade() -> void:
	var scene: Control = RestScene.instantiate()
	scene.configure({
		"run_state": {
			"gold": 12,
			"contract_tickets": 0,
			"potion_ids": ["upgrade_voucher", "upgrade_voucher"],
			"potion_slots_used": 2,
			"potion_slots_max": 2,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": ["loaded_die"],
			"next_combat_mods": [],
			"run_upgrades": {}
		},
		"map_result": {}
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	scene._choose_by_id("rest_tune")
	await process_frame
	scene._choose_upgrade("upgrade_roulette")
	await process_frame
	if results.size() != 0:
		failures.append("first upgrade should wait for finish when voucher is available")
	if bool(scene.get("upgrade_can_choose")):
		failures.append("upgrade choices should lock after first voucher-session pick")
	var local_upgrades: Dictionary = (scene.get("run_state") as Dictionary).get("run_upgrades", {})
	if abs(float(local_upgrades.get("roulette_bonus", 0.0)) - 0.2) > 0.001:
		failures.append("paid roulette upgrade was not applied locally")
	var local_potions_after_roulette: Array = (scene.get("run_state") as Dictionary).get("potion_ids", [])
	if local_potions_after_roulette.size() != 1:
		failures.append("roulette upgrade should consume one voucher locally")
	scene._finish_upgrade_bundle()
	await process_frame
	if results.size() != 1:
		failures.append("finishing voucher upgrade should emit once")
	else:
		var result: Dictionary = results[0]
		var upgrades: Dictionary = result.get("run_upgrades", {})
		if abs(float(upgrades.get("roulette_bonus", 0.0)) - 0.2) > 0.001:
			failures.append("result missing roulette upgrade: " + str(result))
		if (result.get("remove_potion_ids", []) as Array).size() != 1:
			failures.append("result did not consume one upgrade voucher: " + str(result))
	scene.queue_free()
	await process_frame

	var cell_scene: Control = RestScene.instantiate()
	cell_scene.configure({
		"run_state": {
			"gold": 12,
			"contract_tickets": 0,
			"potion_ids": ["upgrade_voucher"],
			"potion_slots_used": 1,
			"potion_slots_max": 2,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": ["loaded_die"],
			"next_combat_mods": [],
			"run_upgrades": {}
		},
		"map_result": {}
	})
	var cell_results: Array[Dictionary] = []
	cell_scene.completed.connect(func(result: Dictionary) -> void: cell_results.append(result))
	root.add_child(cell_scene)
	await process_frame
	cell_scene._choose_by_id("rest_tune")
	await process_frame
	cell_scene._choose_upgrade("upgrade_roulette_cell")
	await process_frame
	if str(cell_scene.get("screen_id")) != "roulette_cell":
		failures.append("roulette cell upgrade did not open cell screen")
	cell_scene._choose_roulette_cell(1)
	await process_frame
	if cell_results.size() != 1:
		failures.append("roulette cell upgrade did not emit once with voucher")
	else:
		var cell_result: Dictionary = cell_results[0]
		var cell_upgrades: Dictionary = cell_result.get("run_upgrades", {})
		if abs(float(cell_upgrades.get("numeric_roulette_cell_bonus_1", 0.0)) - 0.5) > 0.001:
			failures.append("roulette cell upgrade missing cell bonus: " + str(cell_result))
		if (cell_result.get("remove_potion_ids", []) as Array).size() != 1:
			failures.append("roulette cell upgrade did not consume voucher: " + str(cell_result))
	cell_scene.queue_free()
	await process_frame

func _check_run_state_removes_vouchers() -> void:
	var run_state = RunStateScript.new()
	var voucher_ids: Array[String] = ["upgrade_voucher", "upgrade_voucher"]
	run_state.potion_ids = voucher_ids
	run_state.apply_reward({
		"accepted": true,
		"choice": "upgrade_primary_die",
		"gold_delta": 0,
		"hp_delta": 0,
		"relic_ids": [],
		"next_combat_mods": [],
		"run_upgrades": {"primary_die_bonus": 1.0},
		"remove_potion_ids": ["upgrade_voucher", "upgrade_voucher"]
	})
	if (run_state.potion_ids as Array).has("upgrade_voucher"):
		failures.append("run state did not remove spent upgrade vouchers")
	if float(run_state.run_upgrades.get("primary_die_bonus", 0.0)) != 1.0:
		failures.append("run state did not apply voucher upgrade")
