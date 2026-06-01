extends SceneTree

const RestActionCatalog := preload("res://scripts/systems/rest_action_catalog.gd")
const RestScene := preload("res://scenes/run/rest_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	_assert_catalog_shape()
	await _assert_scene_uses_station_rects()

	if failures.is_empty():
		print("rest action catalog smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _assert_catalog_shape() -> void:
	var ids := RestActionCatalog.action_ids()
	if ids != ["rest_heal", "rest_tune", "rest_relic"]:
		failures.append("rest action order changed: " + str(ids))
	var upgrade_ids := RestActionCatalog.upgrade_ids()
	if upgrade_ids != ["upgrade_primary_die", "upgrade_secondary_die", "upgrade_roulette", "upgrade_roulette_cell"]:
		failures.append("rest upgrade order changed: " + str(upgrade_ids))
	var exchange_ids := RestActionCatalog.exchange_ids()
	if exchange_ids != ["ticket_small_heal", "ticket_random_potion", "ticket_upgrade_voucher", "ticket_random_relic"]:
		failures.append("rest exchange order changed: " + str(exchange_ids))
	var heal := RestActionCatalog.result("rest_heal")
	if int(heal.get("hp_delta", 0)) != 9 or str(heal.get("choice", "")) != "rest_heal":
		failures.append("rest heal result payload changed")
	var primary_upgrade := RestActionCatalog.result("upgrade_primary_die")
	var primary_upgrades: Dictionary = primary_upgrade.get("run_upgrades", {})
	if float(primary_upgrades.get("primary_die_bonus", 0.0)) != 1.0:
		failures.append("primary die upgrade no longer persists primary_die_bonus")
	var secondary_upgrade := RestActionCatalog.result("upgrade_secondary_die")
	var secondary_upgrades: Dictionary = secondary_upgrade.get("run_upgrades", {})
	if float(secondary_upgrades.get("secondary_die_bonus", 0.0)) != 1.0:
		failures.append("secondary die upgrade no longer persists secondary_die_bonus")
	var roulette_upgrade := RestActionCatalog.result("upgrade_roulette")
	if float((roulette_upgrade.get("run_upgrades", {}) as Dictionary).get("roulette_bonus", 0.0)) != 0.2:
		failures.append("roulette upgrade no longer persists roulette_bonus")
	var cell_upgrade := RestActionCatalog.result("upgrade_roulette_cell")
	if str(cell_upgrade.get("choice", "")) != "upgrade_roulette_cell":
		failures.append("roulette cell upgrade result changed")
	var random_potion := RestActionCatalog.result("ticket_random_potion")
	if int(random_potion.get("contract_tickets_delta", 0)) != -2 or not bool(random_potion.get("random_potion", false)):
		failures.append("random potion exchange result changed")
	var upgrade_voucher := RestActionCatalog.result("ticket_upgrade_voucher")
	if int(upgrade_voucher.get("contract_tickets_delta", 0)) != -3 or (upgrade_voucher.get("potion_ids", []) as Array).size() != 1:
		failures.append("upgrade voucher exchange result changed")
	var random_relic := RestActionCatalog.result("ticket_random_relic")
	if int(random_relic.get("contract_tickets_delta", 0)) != -5 or not bool(random_relic.get("random_relic", false)):
		failures.append("random relic exchange result changed")

func _assert_scene_uses_station_rects() -> void:
	var scene: Control = RestScene.instantiate()
	scene.configure({
		"run_state": {
			"gold": 18,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": ["loaded_die"],
			"next_combat_mods": []
		},
		"map_result": {}
	})
	root.add_child(scene)
	await process_frame
	var controls: Array[Button] = scene.get_choice_controls()
	if controls.size() != 3:
		failures.append("rest scene choice count changed")
	for button in controls:
		var choice_id := str(button.name).replace("RunChoice_", "")
		var rect: Rect2 = scene.get_choice_rect(choice_id)
		if rect.size == Vector2.ZERO:
			failures.append(choice_id + " did not expose a rest station rect")
		elif button.position.distance_to(rect.position) > 0.01 or button.size.distance_to(rect.size) > 0.01:
			failures.append(choice_id + " button does not match station rect")
	scene._choose_by_id("rest_tune")
	await process_frame
	controls = scene.get_choice_controls()
	if controls.size() != 4:
		failures.append("rest upgrade choice count changed")
	for button in controls:
		var choice_id := str(button.name).replace("RunChoice_", "")
		var rect: Rect2 = scene.get_choice_rect(choice_id)
		if rect.size == Vector2.ZERO:
			failures.append(choice_id + " did not expose an upgrade station rect")
	scene.queue_free()
	await process_frame
