extends SceneTree

const RUN_SCENE := "res://scenes/run/run_root.tscn"

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var scene: PackedScene = load(RUN_SCENE)
	if scene == null:
		push_error("Could not load run root scene")
		quit(1)
		return

	var run_root: Control = scene.instantiate()
	root.add_child(run_root)
	await _start_to_first_map(run_root)
	await _complete_opening_reward(run_root)
	await _complete_event_with_prep(run_root)
	await _complete_shop_with_relic(run_root)
	await _complete_rest_with_prep(run_root)
	await _prove_next_combat_entry_and_trigger(run_root)
	await _prove_victory_reward_return(run_root)

	if failures.is_empty():
		print("001h map return next combat proof smoke passed")
		run_root.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		run_root.queue_free()
		await process_frame
		quit(1)

func _start_to_first_map(run_root: Control) -> void:
	await _wait_for_run_scene(run_root, "title", 900)
	run_root._test_start_run()
	await _wait_for_run_scene(run_root, "character_select", 900)
	run_root._test_select_default_character()
	await _wait_for_run_scene(run_root, "intro", 900)
	run_root._test_skip_intro()
	await _wait_for_run_scene(run_root, "map", 900)
	if str(run_root.get("phase")) != "map":
		failures.append("run did not reach first map")

func _complete_opening_reward(run_root: Control) -> void:
	run_root._test_select_current_map_node()
	await _wait_for_combat(run_root, 900)
	await _settle(30)
	_emit_combat_victory(run_root, "001h-opening")
	await _wait_for_run_scene(run_root, "reward", 900)
	var reward_scene: Control = _active_scene(run_root)
	if reward_scene == null:
		failures.append("opening reward scene did not mount")
		return
	reward_scene._choose_relic()
	await run_root._test_request_overlay_proceed_after_settle()
	await _wait_for_run_scene(run_root, "map", 900)
	var run_state = run_root.get("run_state")
	var map_scene: Control = _active_scene(run_root)
	if int(run_state.map_step) != 1:
		failures.append("reward return did not advance map to step 1")
	if not (run_state.completed_nodes as Array).has("n0"):
		failures.append("reward return did not mark opening combat completed")
	if not (run_state.relic_ids as Array).has("loaded_die"):
		failures.append("reward relic did not persist before map return")
	if map_scene == null or not ((map_scene.get("run_state") as Dictionary).get("completed_nodes", []) as Array).has("n0"):
		failures.append("map scene did not receive completed reward node state")

func _complete_event_with_prep(run_root: Control) -> void:
	run_root._test_select_current_map_node_type("event")
	await _wait_for_run_scene(run_root, "event", 900)
	var event_scene: Control = _active_scene(run_root)
	if event_scene == null:
		failures.append("event scene did not mount")
		return
	event_scene._choose_risk_gold()
	await run_root._test_request_overlay_proceed_after_settle()
	await _wait_for_run_scene(run_root, "map", 900)
	var run_state = run_root.get("run_state")
	if int(run_state.map_step) != 2:
		failures.append("event return did not advance map to step 2")
	if not (run_state.completed_nodes as Array).has("n1"):
		failures.append("event return did not mark event node completed")
	if not _run_state_has_prep(run_state, "event_hot_table"):
		failures.append("event prep note was not visible in run state after map return")

func _complete_shop_with_relic(run_root: Control) -> void:
	var pre_shop_state = run_root.get("run_state")
	pre_shop_state.gold = max(int(pre_shop_state.gold), 80)
	run_root._test_select_current_map_node_type("shop")
	await _wait_for_run_scene(run_root, "shop", 900)
	var shop_scene: Control = _active_scene(run_root)
	if shop_scene == null:
		failures.append("shop scene did not mount")
		return
	shop_scene._choose_default()
	await run_root._test_request_overlay_proceed_after_settle()
	await _wait_for_run_scene(run_root, "map", 900)
	var run_state = run_root.get("run_state")
	if int(run_state.map_step) != 3:
		failures.append("shop return did not advance map to step 3")
	if not (run_state.completed_nodes as Array).has("n2"):
		failures.append("shop return did not mark shop node completed")
	if (run_state.relic_ids as Array).size() < 2:
		failures.append("shop relic did not persist before next combat")

func _complete_rest_with_prep(run_root: Control) -> void:
	run_root._test_select_current_map_node_type("rest")
	await _wait_for_run_scene(run_root, "rest", 900)
	var rest_scene: Control = _active_scene(run_root)
	if rest_scene == null:
		failures.append("rest scene did not mount")
		return
	rest_scene._prepare()
	await run_root._test_request_overlay_proceed_after_settle()
	await _wait_for_run_scene(run_root, "map", 900)
	var run_state = run_root.get("run_state")
	if int(run_state.map_step) != 4:
		failures.append("rest return did not advance map to next combat step")
	if not (run_state.completed_nodes as Array).has("n3"):
		failures.append("rest return did not mark rest node completed")
	if not _run_state_has_prep(run_state, "rest_prepared_table"):
		failures.append("rest prep note was not queued before next combat")

func _prove_next_combat_entry_and_trigger(run_root: Control) -> void:
	run_root._test_select_current_map_node_type("combat")
	await _wait_for_combat(run_root, 900)
	await _wait_for_payload_node(run_root, "n4", 900)
	var combat: Control = run_root.get("active_combat") as Control
	var payload: Dictionary = run_root.get("last_encounter_payload") as Dictionary
	var run_state = run_root.get("run_state")
	if combat == null:
		failures.append("next combat did not mount")
		return
	if not (payload.get("relic_ids", []) as Array).has("loaded_die") or (payload.get("relic_ids", []) as Array).size() < 2:
		failures.append("next combat payload did not carry persistent relics")
	if (payload.get("next_combat_mods", []) as Array).size() < 2:
		failures.append("next combat payload did not preserve consumed prep receipt")
	if not _payload_has_effect(payload, "event_hot_table") or not _payload_has_effect(payload, "rest_prepared_table"):
		failures.append("prep receipt effects were not recorded at combat start")
	if not (run_state.next_combat_mods as Array).is_empty():
		failures.append("prep notes were not consumed from run state on combat entry")
	var run_hud: Control = combat.get("run_hud") as Control
	if run_hud == null or (run_hud.get("active_prep_mods") as Array).size() < 2:
		failures.append("combat HUD did not receive prep receipt notes")

	var feedback_layer: Control = combat.get("feedback_layer") as Control
	var before_feedback_count := feedback_layer.get_child_count() if feedback_layer != null else 0
	combat._apply_dice_ritual_result({
		"dice_rule_id": "single_attack_die",
		"dice_values": [2],
		"dice": [2],
		"dice_locked": [false],
		"rerolls_left": 0,
		"applied_effects": []
	})
	await _settle(4)
	var dice: Array = combat.get("dice") as Array
	if dice.is_empty() or int(dice[0]) != 3:
		failures.append("loaded_die did not fire through RelicEffectResolver in next combat")
	if feedback_layer == null or feedback_layer.get_child_count() <= before_feedback_count:
		failures.append("relic trigger did not spawn visible feedback")

func _prove_victory_reward_return(run_root: Control) -> void:
	await _settle(30)
	_emit_combat_victory(run_root, "001h-next-combat")
	await _wait_for_run_scene(run_root, "reward", 900)
	if str(run_root.get("phase")) != "reward":
		failures.append("next combat victory did not return to reward")
		return
	var reward_scene: Control = _active_scene(run_root)
	if reward_scene == null:
		failures.append("next combat reward scene did not mount")
		return
	reward_scene._choose_relic()
	await run_root._test_request_overlay_proceed_after_settle()
	await _wait_for_run_scene(run_root, "map", 900)
	var run_state = run_root.get("run_state")
	if int(run_state.map_step) != 5:
		failures.append("post-victory reward did not return to final map step")
	if not (run_state.completed_nodes as Array).has("n4"):
		failures.append("post-victory map did not mark next combat completed")

func _active_scene(run_root: Control) -> Control:
	var director = run_root.get("run_director")
	if director == null:
		return null
	return director.active_scene as Control

func _run_state_has_prep(run_state: Variant, prep_id: String) -> bool:
	for mod in run_state.next_combat_mods:
		if mod is Dictionary and str((mod as Dictionary).get("id", "")) == prep_id:
			return true
	return false

func _payload_has_effect(payload: Dictionary, effect_id: String) -> bool:
	for item in payload.get("applied_effects", []):
		if item is Dictionary and str((item as Dictionary).get("effect_id", "")) == effect_id:
			return true
	return false

func _emit_combat_victory(run_root: Control, reason: String) -> void:
	var combat: Control = run_root.get("active_combat") as Control
	if combat == null:
		failures.append("cannot emit victory without active combat: " + reason)
		return
	var payload: Dictionary = (run_root.get("last_encounter_payload") as Dictionary).duplicate(true)
	var winnings: int = max(80, int(payload.get("combat_cash", 18)))
	combat.combat_finished.emit({
		"accepted": true,
		"reason": reason,
		"victory": true,
		"defeat": false,
		"cash": winnings,
		"combat_cash": winnings,
		"winnings": winnings,
		"player_hp": int(payload.get("player_hp", 42)),
		"enemy_hp": 0,
		"relic_ids": payload.get("relic_ids", []),
		"encounter_id": str(payload.get("encounter_id", "")),
		"monster_id": str(payload.get("monster_id", "")),
		"is_final": bool(payload.get("is_final", false)),
		"on_victory": str(payload.get("on_victory", "reward"))
	})

func _wait_for_run_scene(run_root: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		var director = run_root.get("run_director")
		if str(run_root.get("phase")) == expected and director != null and str(director.active_scene_name) == expected:
			await process_frame
			return
		await process_frame

func _wait_for_combat(run_root: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if run_root.get("active_combat") != null:
			return
		await process_frame

func _wait_for_payload_node(run_root: Control, node_id: String, max_frames: int) -> void:
	for i in range(max_frames):
		var payload: Dictionary = run_root.get("last_encounter_payload") as Dictionary
		if run_root.get("active_combat") != null and str(payload.get("node_id", "")) == node_id:
			return
		await process_frame

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame
