extends SceneTree

const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const RunStateScript := preload("res://scripts/resources/run_state.gd")
const RunTableState := preload("res://scripts/run/run_table_state.gd")
const RunPersistentOverlay := preload("res://scripts/ui/run_persistent_overlay.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_run_state_payload()
	_check_reward_ticket_delta()
	_check_table_preview()
	await _check_overlay_payload_slots()

	if failures.is_empty():
		print("ticket economy skeleton smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_run_state_payload() -> void:
	var run_state: Resource = RunStateScript.new()
	run_state.contract_tickets = 3
	var potion_ids: Array[String] = ["red_vial"]
	run_state.potion_ids = potion_ids
	run_state.potion_slots_max = 2
	var payload: Dictionary = run_state.to_payload()
	if int(payload.get("contract_tickets", -1)) != 3:
		failures.append("run payload missing contract tickets")
	if int(payload.get("potion_slots_used", -1)) != 1:
		failures.append("run payload missing potion slot usage")
	if int(payload.get("potion_slots_max", -1)) != 2:
		failures.append("run payload missing potion slot max")

	var restored: Resource = RunStateScript.new()
	restored.apply_payload(payload)
	if int(restored.contract_tickets) != 3:
		failures.append("apply_payload did not restore contract tickets")
	if (restored.potion_ids as Array).size() != 1:
		failures.append("apply_payload did not restore potion ids")

func _check_reward_ticket_delta() -> void:
	var run_state: Resource = RunStateScript.new()
	EffectResolver.apply_reward_result(run_state, {
		"accepted": true,
		"choice": "ticket_test_gain",
		"gold_delta": 0,
		"hp_delta": 0,
		"contract_tickets_delta": 2,
		"relic_ids": [],
		"next_combat_mods": []
	})
	if int(run_state.contract_tickets) != 2:
		failures.append("reward result did not add contract tickets")

	EffectResolver.apply_reward_result(run_state, {
		"accepted": true,
		"choice": "ticket_test_spend",
		"gold_delta": 0,
		"hp_delta": 0,
		"contract_tickets_delta": -1,
		"relic_ids": [],
		"next_combat_mods": []
	})
	if int(run_state.contract_tickets) != 1:
		failures.append("reward result did not spend contract tickets")

	EffectResolver.apply_reward_result(run_state, {
		"accepted": true,
		"choice": "ticket_test_clamp",
		"gold_delta": 0,
		"hp_delta": 0,
		"contract_tickets_delta": -99,
		"relic_ids": [],
		"next_combat_mods": []
	})
	if int(run_state.contract_tickets) != 0:
		failures.append("contract tickets should clamp at zero")

func _check_table_preview() -> void:
	var table_state := RunTableState.from_run_payload({
		"gold": 0,
		"contract_tickets": 1,
		"player_hp": 30,
		"player_max_hp": 42,
		"relic_ids": [],
		"next_combat_mods": [],
		"potion_ids": [],
		"potion_slots_max": 2
	}, {
		"accepted": true,
		"choice": "ticket_test_gain",
		"contract_tickets_delta": 2,
		"gold_delta": 0,
		"hp_delta": 0,
		"relic_ids": [],
		"next_combat_mods": []
	})
	var ledger: Dictionary = table_state.get("ledger", {})
	if int(ledger.get("contract_tickets", -1)) != 1:
		failures.append("ledger missing current tickets")
	if int(ledger.get("contract_tickets_preview", -1)) != 3:
		failures.append("ledger preview missing pending tickets")
	if str(table_state.get("pickup", {}).get("target", "")) != "ledger":
		failures.append("ticket-only result should target ledger")

func _check_overlay_payload_slots() -> void:
	var overlay := RunPersistentOverlay.new()
	root.add_child(overlay)
	overlay.configure({
		"gold": 7,
		"contract_tickets": 4,
		"player_hp": 21,
		"player_max_hp": 42,
		"relic_ids": [],
		"potion_ids": ["red_vial"],
		"potion_slots_used": 1,
		"potion_slots_max": 2,
		"floor_index": 1,
		"map_step": 3
	}, "map", false, false, "")
	await process_frame
	var payload: Dictionary = overlay.get("run_payload") as Dictionary
	if int(payload.get("contract_tickets", -1)) != 4:
		failures.append("overlay payload missing tickets")
	if int(payload.get("potion_slots_used", -1)) != 1:
		failures.append("overlay payload missing potion slot usage")
	overlay.queue_free()
	await process_frame
