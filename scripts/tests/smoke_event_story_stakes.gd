extends SceneTree

const EventScene := preload("res://scenes/run/event_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_red_pin_dice_story()
	await _check_shop_coupon_roulette_story()
	await _check_relic_pouch_card_story()
	if failures.is_empty():
		print("event story stakes smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_red_pin_dice_story() -> void:
	var scene := _scene({
		"event_id": "red_pin_detour",
		"dice_forced_values": [5, 5]
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	await _advance_story(scene, "red_pin_detour")
	scene._choose_by_id("detour_press")
	await process_frame
	if str(scene.get("module_id")) != "dice_check":
		failures.append("red_pin_detour did not enter dice module")
	scene._choose_by_id("dice_roll_now")
	await _wait_for_result(results, 180)
	if results.size() != 1:
		failures.append("red_pin_detour did not emit after dice roll")
	elif str(results[0].get("dice_tier", "")) != "great":
		failures.append("red_pin_detour forced total did not use great tier")
	elif (results[0].get("relic_ids", []) as Array).is_empty():
		failures.append("red_pin_detour great result did not award relic")
	scene.queue_free()
	await process_frame

func _check_shop_coupon_roulette_story() -> void:
	var scene := _scene({
		"event_id": "shop_coupon_tag",
		"roulette_forced_slot": "jackpot"
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	await _advance_story(scene, "shop_coupon_tag")
	scene._choose_by_id("coupon_steal")
	await process_frame
	if str(scene.get("module_id")) != "roulette_check":
		failures.append("shop_coupon_tag did not enter roulette module")
	scene._choose_by_id("roulette_spin_now")
	await _wait_for_result(results, 180)
	if results.size() != 1:
		failures.append("shop_coupon_tag did not emit after roulette spin")
	elif str(results[0].get("roulette_slot", "")) != "jackpot":
		failures.append("shop_coupon_tag did not preserve forced jackpot")
	elif (results[0].get("relic_ids", []) as Array).is_empty():
		failures.append("shop_coupon_tag jackpot result did not award relic")
	scene.queue_free()
	await process_frame

func _check_relic_pouch_card_story() -> void:
	var scene := _scene({
		"event_id": "relic_pouch_ritual",
		"card_forced_index": 5
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	await _advance_story(scene, "relic_pouch_ritual")
	scene._choose_by_id("pouch_paid_reveal")
	await process_frame
	if str(scene.get("module_id")) != "card_draw":
		failures.append("relic_pouch_ritual did not enter card module")
	scene._choose_by_id("event_card_0")
	await process_frame
	if str(scene.get("revealed_card_id")) == "":
		failures.append("relic_pouch_ritual did not reveal selected card")
	await _wait_for_result(results, 180)
	if results.size() != 1:
		failures.append("relic_pouch_ritual did not emit after card reveal")
	elif (results[0].get("relic_ids", []) as Array).is_empty():
		failures.append("relic_pouch_ritual hidden card did not award relic")
	elif int(results[0].get("gold_delta", 0)) != -1:
		failures.append("relic_pouch_ritual did not apply peek cost to card payout")
	scene.queue_free()
	await process_frame

func _advance_story(scene: Control, label: String) -> void:
	if str(scene.get("module_id")) != "story_intro":
		failures.append(label + " did not start on story_intro")
		return
	var guard := 0
	while str(scene.get("module_id")) == "story_intro" and guard < 6:
		scene._choose_by_id("story_intro_next")
		guard += 1
		await process_frame
	if str(scene.get("module_id")) != "base":
		failures.append(label + " did not advance from story to base")
	if scene.get_choice_controls().size() != 3:
		failures.append(label + " did not expose three base choices after story")

func _scene(map_payload: Dictionary) -> Control:
	var scene: Control = EventScene.instantiate()
	scene.configure({
		"run_state": {
			"seed_text": "event-story-stakes-smoke",
			"gold": 30,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": [],
			"next_combat_mods": []
		},
		"map_result": map_payload
	})
	return scene

func _wait_for_result(results: Array[Dictionary], max_frames: int) -> void:
	for i in range(max_frames):
		if results.size() > 0:
			return
		await process_frame
