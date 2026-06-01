extends SceneTree

const RestScene := preload("res://scenes/run/rest_scene.tscn")

var failures: Array[String] = []
var completed_emitted := false
var completed_result: Dictionary = {}

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _assert_choice_completes("rest_heal", {"hp_delta": 9})
	await _assert_choice_completes("rest_relic", {"relic_count": 1})
	await _assert_upgrade_completes("upgrade_primary_die", "primary_die_bonus", 1.0, ["upgrade_voucher", "upgrade_voucher"], 2)
	await _assert_upgrade_completes("upgrade_secondary_die", "secondary_die_bonus", 1.0, ["upgrade_voucher", "upgrade_voucher"], 2)
	await _assert_upgrade_completes("upgrade_roulette", "roulette_bonus", 0.2, ["upgrade_voucher"], 1)
	await _assert_upgrade_completes("upgrade_roulette_cell", "numeric_roulette_cell_bonus_1", 0.5, ["upgrade_voucher"], 1)

	if failures.is_empty():
		print("rest all choices complete smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _assert_choice_completes(choice_id: String, expected: Dictionary) -> void:
	var scene := _new_rest_scene()
	root.add_child(scene)
	await process_frame
	_begin_capture(scene)
	scene._choose_by_id(choice_id)
	await process_frame
	if not scene._has_resolved_action():
		failures.append(choice_id + " did not resolve")
	var result: Dictionary = await _wait_for_capture(choice_id)
	_assert_common_result(choice_id, result)
	if expected.has("hp_delta") and int(result.get("hp_delta", 0)) != int(expected["hp_delta"]):
		failures.append(choice_id + " hp_delta mismatch: " + str(result))
	if expected.has("relic_count") and (result.get("relic_ids", []) as Array).size() != int(expected["relic_count"]):
		failures.append(choice_id + " relic count mismatch: " + str(result))
	scene.queue_free()
	await process_frame

func _assert_upgrade_completes(choice_id: String, upgrade_key: String, expected_value: float, potion_ids: Array, expected_removed: int) -> void:
	var scene := _new_rest_scene()
	var payload: Dictionary = scene.get("run_state")
	payload["potion_ids"] = potion_ids.duplicate()
	payload["potion_slots_used"] = potion_ids.size()
	scene.set("run_state", payload)
	root.add_child(scene)
	await process_frame
	scene._choose_by_id("rest_tune")
	await process_frame
	_begin_capture(scene)
	scene._choose_upgrade(choice_id)
	await process_frame
	if choice_id == "upgrade_roulette_cell":
		scene._choose_roulette_cell(1)
		await process_frame
	if not scene._has_resolved_action() and scene._has_pending_upgrade_result():
		scene._finish_upgrade_bundle()
		await process_frame
	if not scene._has_resolved_action():
		failures.append(choice_id + " did not resolve")
	var result: Dictionary = await _wait_for_capture(choice_id)
	_assert_common_result(choice_id, result)
	var upgrades: Dictionary = result.get("run_upgrades", {})
	if abs(float(upgrades.get(upgrade_key, 0.0)) - expected_value) > 0.001:
		failures.append(choice_id + " run upgrade mismatch: " + str(result))
	if (result.get("remove_potion_ids", []) as Array).size() != expected_removed:
		failures.append(choice_id + " removed voucher count mismatch: " + str(result))
	scene.queue_free()
	await process_frame

func _new_rest_scene() -> Control:
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
	return scene

func _begin_capture(scene: Control) -> void:
	if not scene.has_signal("completed"):
		failures.append("rest scene has no completed signal")
		return
	completed_emitted = false
	completed_result = {}
	scene.completed.connect(_on_completed, CONNECT_ONE_SHOT)

func _wait_for_capture(label: String) -> Dictionary:
	for i in range(12):
		await process_frame
		if completed_emitted:
			return completed_result
	failures.append(label + " did not emit completed")
	return completed_result

func _on_completed(payload: Dictionary) -> void:
	completed_result = payload.duplicate(true)
	completed_emitted = true

func _assert_common_result(choice_id: String, result: Dictionary) -> void:
	if result.is_empty():
		failures.append(choice_id + " emitted empty result")
		return
	if not bool(result.get("accepted", false)):
		failures.append(choice_id + " did not emit accepted result: " + str(result))
	if str(result.get("choice", "")) != choice_id:
		failures.append(choice_id + " emitted wrong choice id: " + str(result))
