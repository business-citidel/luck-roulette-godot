extends SceneTree

const RestScene := preload("res://scenes/run/rest_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_exchange_multi_buy()
	await _check_exchange_relic_and_upgrade()
	await _check_exchange_affordability()

	if failures.is_empty():
		print("rest ticket exchange smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_exchange_multi_buy() -> void:
	var scene := _new_rest_scene({
		"contract_tickets": 4,
		"potion_ids": [],
		"potion_slots_used": 0,
		"potion_slots_max": 2,
		"player_hp": 30,
		"player_max_hp": 42
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	if scene.get_choice_controls().size() != 3:
		failures.append("front rest choices should stay separate from exchange button")
	if scene.get_choice_rect("rest_ticket_exchange").size == Vector2.ZERO:
		failures.append("ticket exchange entry rect missing")
	scene._open_ticket_exchange()
	await process_frame
	if str(scene.get("screen_id")) != "exchange":
		failures.append("ticket exchange did not open exchange screen")
	if scene.get_choice_controls().size() != 4:
		failures.append("ticket exchange should expose four offers")
	scene._choose_by_id("ticket_small_heal")
	await process_frame
	if int(scene.get("local_tickets")) != 2:
		failures.append("first exchange did not spend two tickets")
	var local_hp := int((scene.get("run_state") as Dictionary).get("player_hp", 0))
	if local_hp != 35:
		failures.append("small heal exchange did not heal locally")
	scene._choose_by_id("ticket_random_potion")
	await process_frame
	var local_potions: Array = (scene.get("run_state") as Dictionary).get("potion_ids", [])
	if local_potions.size() != 1:
		failures.append("random potion exchange did not fill one potion slot")
	scene._leave_exchange()
	await process_frame
	if str(scene.get("screen_id")) != "front":
		failures.append("exchange should return to front rest screen after done")
	if results.size() != 0:
		failures.append("exchange should not complete rest before a rest action")
	scene._choose_by_id("rest_heal")
	await process_frame
	if results.size() != 1:
		failures.append("rest action after exchange did not emit exactly one result")
	else:
		var result: Dictionary = results[0]
		if str(result.get("choice", "")) != "rest_heal":
			failures.append("exchange should be bundled into chosen rest action: " + str(result))
		if int(result.get("contract_tickets_delta", 0)) != -4:
			failures.append("exchange did not accumulate ticket spend: " + str(result))
		if int(result.get("hp_delta", 0)) != 14:
			failures.append("exchange heal and rest heal did not bundle: " + str(result))
		if (result.get("potion_ids", []) as Array).size() != 1:
			failures.append("exchange did not accumulate random potion id: " + str(result))
	scene.queue_free()
	await process_frame

func _check_exchange_relic_and_upgrade() -> void:
	var scene := _new_rest_scene({
		"seed_text": "rest-ticket-relic-smoke",
		"character_id": "default_guard_dice",
		"contract_tickets": 11,
		"potion_ids": [],
		"potion_slots_used": 0,
		"potion_slots_max": 2,
		"player_hp": 30,
		"player_max_hp": 42
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	scene._open_ticket_exchange()
	await process_frame
	scene._choose_by_id("ticket_upgrade_voucher")
	await process_frame
	scene._choose_by_id("ticket_upgrade_voucher")
	await process_frame
	scene._choose_by_id("ticket_random_relic")
	await process_frame
	scene._leave_exchange()
	await process_frame
	if results.size() != 0:
		failures.append("relic/voucher exchange should wait for a rest action")
	scene._choose_by_id("rest_tune")
	await process_frame
	scene._choose_upgrade("upgrade_primary_die")
	await process_frame
	scene._finish_upgrade_bundle()
	await process_frame
	if results.size() != 1:
		failures.append("relic/voucher exchange plus upgrade did not emit exactly one result")
	else:
		var result: Dictionary = results[0]
		if str(result.get("choice", "")) != "upgrade_primary_die":
			failures.append("relic/voucher exchange should bundle into upgrade action: " + str(result))
		if int(result.get("contract_tickets_delta", 0)) != -11:
			failures.append("relic/voucher exchange spend mismatch: " + str(result))
		if not (result.get("potion_ids", []) as Array).has("upgrade_voucher"):
			failures.append("upgrade voucher was not added as a consumable: " + str(result))
		if (result.get("potion_ids", []) as Array).size() != 2:
			failures.append("upgrade exchange should add two voucher consumables: " + str(result))
		if (result.get("remove_potion_ids", []) as Array).size() != 2:
			failures.append("die upgrade should consume two upgrade vouchers: " + str(result))
		if (result.get("relic_ids", []) as Array).is_empty():
			failures.append("random relic exchange did not add a relic: " + str(result))
		var upgrades: Dictionary = result.get("run_upgrades", {})
		if float(upgrades.get("primary_die_bonus", 0.0)) != 1.0:
			failures.append("bundled upgrade missing primary die bonus: " + str(result))
	scene.queue_free()
	await process_frame

func _check_exchange_affordability() -> void:
	var scene := _new_rest_scene({
		"contract_tickets": 1,
		"potion_ids": ["attack_potion", "guard_potion"],
		"potion_slots_used": 2,
		"potion_slots_max": 2,
		"player_hp": 40,
		"player_max_hp": 42
	})
	root.add_child(scene)
	await process_frame
	scene._open_ticket_exchange()
	await process_frame
	for button in scene.get_choice_controls():
		if not button.disabled:
			failures.append("exchange offer should be disabled without tickets or potion slots: " + str(button.name))
	scene.queue_free()
	await process_frame

func _new_rest_scene(overrides: Dictionary) -> Control:
	var run_payload := {
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
	}
	for key in overrides.keys():
		run_payload[key] = overrides[key]
	var scene: Control = RestScene.instantiate()
	scene.configure({
		"run_state": run_payload,
		"map_result": {}
	})
	return scene
