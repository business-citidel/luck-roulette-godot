extends SceneTree

const EventCatalog := preload("res://scripts/systems/event_catalog.gd")
const EventScene := preload("res://scenes/run/event_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	_check_catalog_shape()
	_check_pack_helpers()
	_check_subtype_pack_helpers()
	_check_english_catalog_surface()
	await _check_scene_profiles_mount()
	await _check_map_pool_pick()
	await _check_catalog_result_choice()
	if failures.is_empty():
		print("event catalog smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_catalog_shape() -> void:
	var ids := EventCatalog.catalog_event_ids()
	if ids.size() < 20:
		failures.append("catalog event pool is smaller than 20 ids")
	for event_id in ids:
		var profile := EventCatalog.get_profile(event_id)
		if str(profile.get("title", "")) == "":
			failures.append(event_id + " missing title")
		var choices: Array = profile.get("choices", [])
		if choices.size() < 2 or choices.size() > 3:
			failures.append(event_id + " should expose 2-3 base choices")
		var has_supported_action := false
		for choice in choices:
			if not (choice is Dictionary):
				failures.append(event_id + " has non-dictionary choice")
				continue
			var action := str((choice as Dictionary).get("action", ""))
			if [
				EventCatalog.ACTION_RESULT,
				EventCatalog.ACTION_DICE_CHECK,
				EventCatalog.ACTION_ROULETTE_CHECK,
				EventCatalog.ACTION_CARD_DRAW
			].has(action):
				has_supported_action = true
		if not has_supported_action:
			failures.append(event_id + " has no supported action")

func _check_pack_helpers() -> void:
	if EventCatalog.first_pack_event_ids().size() < 10:
		failures.append("first event pack is smaller than 10 ids")
	if EventCatalog.second_pack_event_ids().size() < 10:
		failures.append("second event pack is smaller than 10 ids")
	if EventCatalog.third_pack_event_ids().size() < 10:
		failures.append("third event pack is smaller than 10 ids")
	if EventCatalog.pack_event_ids("catalog").size() != EventCatalog.catalog_event_ids().size():
		failures.append("catalog pack helper does not match combined ids")
	if EventCatalog.pack_event_ids("second_pack") != EventCatalog.second_pack_event_ids():
		failures.append("second pack helper does not match second-pack ids")
	if EventCatalog.pack_event_ids("third_pack") != EventCatalog.third_pack_event_ids():
		failures.append("third pack helper does not match third-pack ids")

func _check_subtype_pack_helpers() -> void:
	var subtype_pools := {
		"mystery": EventCatalog.mystery_event_ids(),
		"chest": EventCatalog.chest_event_ids(),
		"quest": EventCatalog.quest_event_ids(),
		"gamble": EventCatalog.gamble_event_ids()
	}
	for pool_id in subtype_pools.keys():
		var ids: Array = subtype_pools[pool_id]
		if ids.size() < 5:
			failures.append(str(pool_id) + " event pool is smaller than 5 ids")
		if EventCatalog.pack_event_ids(str(pool_id)) != ids:
			failures.append(str(pool_id) + " pack helper mismatch")
		if EventCatalog.pack_event_ids("event_" + str(pool_id)) != ids:
			failures.append("event_" + str(pool_id) + " pack helper mismatch")
		for id in ids:
			if not EventCatalog.has_event(str(id)):
				failures.append(str(pool_id) + " pool has unknown event " + str(id))

func _check_english_catalog_surface() -> void:
	TranslationServer.set_locale("en")
	for event_id in EventCatalog.catalog_event_ids():
		var profile := EventCatalog.get_profile(event_id)
		_check_no_korean_value(profile, "en event " + event_id)
	for deck_id in ["relic_pouch", "relic_pouch_peek"]:
		_check_no_korean_value(EventCatalog.get_card_deck(deck_id), "en event deck " + deck_id)
	TranslationServer.set_locale("ko")

func _check_scene_profiles_mount() -> void:
	for event_id in EventCatalog.catalog_event_ids():
		var scene := _scene({"event_id": event_id})
		root.add_child(scene)
		await process_frame
		if str(scene.get("active_event_id")) != event_id:
			failures.append(event_id + " did not configure as active event")
		await _advance_story_if_present(scene, event_id)
		if scene.get_choice_controls().size() != 3:
			failures.append(event_id + " did not expose three base controls")
		scene.queue_free()
		await process_frame

func _check_map_pool_pick() -> void:
	var scene := _scene({
		"encounter_id": "crossroad_event",
		"node_id": "n1",
		"node_index": 1,
		"event_pool": "first_pack"
	})
	root.add_child(scene)
	await process_frame
	if not EventCatalog.first_pack_event_ids().has(str(scene.get("active_event_id"))):
		failures.append("map event pool did not pick a first-pack event")
	scene.queue_free()
	await process_frame
	for pool_id in ["mystery", "chest", "quest", "gamble", "event_chest", "event_quest", "event_gamble"]:
		var pool_scene := _scene({
			"encounter_id": "crossroad_event",
			"node_id": "n1_" + pool_id,
			"node_index": 2,
			"event_pool": pool_id
		})
		root.add_child(pool_scene)
		await process_frame
		if not EventCatalog.pack_event_ids(pool_id).has(str(pool_scene.get("active_event_id"))):
			failures.append(pool_id + " event pool did not pick from its pack")
		pool_scene.queue_free()
		await process_frame

func _advance_story_if_present(scene: Control, event_id: String) -> void:
	var guard := 0
	while str(scene.get("module_id")) == "story_intro" and guard < 6:
		if scene.get_choice_controls().size() != 1:
			failures.append(event_id + " story intro did not expose one continue control")
			return
		scene._choose_by_id("story_intro_next")
		guard += 1
		await process_frame
	if str(scene.get("module_id")) == "story_intro":
		failures.append(event_id + " story intro did not advance to base")
	var second_scene := _scene({
		"encounter_id": "crossroad_event",
		"node_id": "n1",
		"node_index": 1,
		"event_pool": "second_pack"
	})
	root.add_child(second_scene)
	await process_frame
	if not EventCatalog.second_pack_event_ids().has(str(second_scene.get("active_event_id"))):
		failures.append("second event pool did not pick a second-pack event")
	second_scene.queue_free()
	await process_frame

func _check_catalog_result_choice() -> void:
	var scene := _scene({"event_id": "quiet_claim_slips"})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	scene._choose_by_id("claim_relic")
	await process_frame
	if results.size() != 1:
		failures.append("catalog result choice did not emit exactly once")
	elif str(results[0].get("choice", "")) != "claim_relic":
		failures.append("catalog result choice emitted wrong choice")
	elif (results[0].get("relic_ids", []) as Array).is_empty():
		failures.append("catalog relic reward did not hydrate relic id")
	if str(scene.get("module_id")) != "result_receipt":
		failures.append("catalog result choice did not enter receipt module")
	scene.queue_free()
	await process_frame

func _scene(map_payload: Dictionary) -> Control:
	var scene: Control = EventScene.instantiate()
	scene.configure({
		"run_state": {
			"seed_text": "event-catalog-smoke",
			"gold": 30,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": [],
			"next_combat_mods": []
		},
		"map_result": map_payload
	})
	return scene

func _check_no_korean_value(value: Variant, label: String) -> void:
	if value is String:
		if _contains_korean(str(value)):
			failures.append(label + " contains Korean text: " + str(value))
	elif value is Dictionary:
		for key in (value as Dictionary).keys():
			_check_no_korean_value((value as Dictionary)[key], label + "." + str(key))
	elif value is Array:
		var index := 0
		for item in value:
			_check_no_korean_value(item, label + "[" + str(index) + "]")
			index += 1

func _contains_korean(text: String) -> bool:
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if code >= 0xac00 and code <= 0xd7a3:
			return true
	return false
