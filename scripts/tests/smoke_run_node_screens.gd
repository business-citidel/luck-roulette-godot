extends SceneTree

const RewardScene := preload("res://scenes/run/reward_scene.tscn")
const ShopScene := preload("res://scenes/run/shop_scene.tscn")
const EventScene := preload("res://scenes/run/event_scene.tscn")
const RestScene := preload("res://scenes/run/rest_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_reward_double_submit()
	await _check_shop_disabled_states()
	await _check_default_choices()
	if failures.is_empty():
		print("run node screens smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_reward_double_submit() -> void:
	var scene: Control = RewardScene.instantiate()
	scene.configure({
		"run_state": {"gold": 0, "player_hp": 42, "player_max_hp": 42, "relic_ids": []},
		"combat_result": {"winnings": 18}
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	scene._choose_relic()
	scene._choose_relic()
	await process_frame
	if results.size() != 1:
		failures.append("reward accepted more than one result")
	elif str(results[0].get("choice", "")) != "combat_reward":
		failures.append("reward default claim result changed")
	for child in scene.get_children():
		if child is Button and not (child as Button).disabled:
			failures.append("reward button stayed enabled after completion")
			break
	scene.queue_free()
	await process_frame

func _check_shop_disabled_states() -> void:
	var scene: Control = ShopScene.instantiate()
	scene.configure({
		"run_state": {"gold": 0, "player_hp": 42, "player_max_hp": 42, "relic_ids": []},
		"map_result": {}
	})
	root.add_child(scene)
	await process_frame
	var disabled_count := 0
	var enabled_count := 0
	for child in scene.get_children():
		if child is Button:
			if (child as Button).disabled:
				disabled_count += 1
			else:
				enabled_count += 1
	if disabled_count < 2:
		failures.append("shop low-gold state did not disable buy/prep buttons")
	if enabled_count != 1:
		failures.append("shop low-gold state should expose exactly one local exit button")
	scene.queue_free()
	await process_frame

func _check_default_choices() -> void:
	await _assert_default_choice(EventScene, {"run_state": {}, "map_result": {}}, "event_gold", "event default choice changed")
	await _assert_default_choice(RestScene, {"run_state": {"potion_ids": ["upgrade_voucher"], "potion_slots_used": 1, "run_upgrades": {}}, "map_result": {}}, "upgrade_roulette_cell", "rest default choice changed")
	await _assert_default_choice(ShopScene, {"run_state": {"gold": 10}, "map_result": {}}, "shop_leave", "shop low-gold default should leave")

func _assert_default_choice(scene_resource: PackedScene, payload: Dictionary, expected_choice: String, label: String) -> void:
	var scene: Control = scene_resource.instantiate()
	scene.configure(payload)
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	scene._choose_default()
	await process_frame
	if results.size() != 1 or str(results[0].get("choice", "")) != expected_choice:
		failures.append(label)
	scene.queue_free()
	await process_frame
