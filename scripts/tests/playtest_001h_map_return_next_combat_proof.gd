extends SceneTree

const RUN_SCENE := "res://scenes/run/run_root.tscn"

var shot_dir: String = ""
var failures: Array[String] = []

func _initialize() -> void:
	print("001h map return next combat playtest start")
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	var scene: PackedScene = load(RUN_SCENE)
	if scene == null:
		push_error("Could not load run root scene")
		quit(1)
		return
	var run_root: Control = scene.instantiate()
	root.add_child(run_root)

	await _start_to_map(run_root)
	await _opening_reward_return(run_root)
	await _shot("00_map_return_after_reward_relic")
	await _event_return(run_root)
	await _shot("01_map_return_after_event_prep")
	await _shop_return(run_root)
	await _shot("02_map_return_after_shop_relic")
	await _rest_return(run_root)
	await _shot("03_map_return_after_rest_prep")
	await _next_combat_entry(run_root)
	await _shot("04_next_combat_hud_receipts")
	await _relic_trigger_feedback(run_root)
	await _shot("05_relic_trigger_feedback_loaded_die")
	await _second_reward_return(run_root)
	await _shot("06_victory_reward_return_to_final_map")

	run_root.queue_free()
	await process_frame
	if failures.is_empty():
		print("001h map return next combat playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _start_to_map(run_root: Control) -> void:
	await _wait_for_run_scene(run_root, "title", 900)
	run_root._test_start_run()
	await _wait_for_run_scene(run_root, "intro", 900)
	run_root._test_skip_intro()
	await _wait_for_run_scene(run_root, "map", 900)

func _opening_reward_return(run_root: Control) -> void:
	run_root._test_select_current_map_node()
	await _wait_for_combat(run_root, 900)
	await _settle(30)
	_emit_combat_victory(run_root, "001h-shot-opening")
	await _wait_for_run_scene(run_root, "reward", 900)
	var reward_scene: Control = _active_scene(run_root)
	if reward_scene == null:
		failures.append("opening reward scene unavailable for screenshot proof")
		return
	reward_scene._choose_relic()
	await _wait_for_run_scene(run_root, "map", 900)
	await _settle(10)

func _event_return(run_root: Control) -> void:
	run_root._test_select_current_map_node_type("event")
	await _wait_for_run_scene(run_root, "event", 900)
	var event_scene: Control = _active_scene(run_root)
	if event_scene == null:
		failures.append("event scene unavailable for screenshot proof")
		return
	event_scene._choose_risk_gold()
	await _wait_for_run_scene(run_root, "map", 900)
	await _settle(10)

func _shop_return(run_root: Control) -> void:
	run_root._test_select_current_map_node_type("shop")
	await _wait_for_run_scene(run_root, "shop", 900)
	var shop_scene: Control = _active_scene(run_root)
	if shop_scene == null:
		failures.append("shop scene unavailable for screenshot proof")
		return
	shop_scene._buy_relic()
	await _wait_for_run_scene(run_root, "map", 900)
	await _settle(10)

func _rest_return(run_root: Control) -> void:
	run_root._test_select_current_map_node_type("rest")
	await _wait_for_run_scene(run_root, "rest", 900)
	var rest_scene: Control = _active_scene(run_root)
	if rest_scene == null:
		failures.append("rest scene unavailable for screenshot proof")
		return
	rest_scene._prepare()
	await _wait_for_run_scene(run_root, "map", 900)
	await _settle(10)

func _next_combat_entry(run_root: Control) -> void:
	run_root._test_select_current_map_node_type("combat")
	await _wait_for_combat(run_root, 900)
	await _wait_for_payload_node(run_root, "n4", 900)
	await _settle(18)
	var combat: Control = run_root.get("active_combat") as Control
	if combat == null:
		failures.append("next combat unavailable for screenshot proof")

func _relic_trigger_feedback(run_root: Control) -> void:
	var combat: Control = run_root.get("active_combat") as Control
	if combat == null:
		failures.append("cannot trigger relic feedback without active combat")
		return
	combat._apply_dice_ritual_result({
		"dice_rule_id": "single_attack_die",
		"dice_values": [2],
		"dice": [2],
		"dice_locked": [false],
		"rerolls_left": 0,
		"applied_effects": []
	})
	await _settle(4)

func _second_reward_return(run_root: Control) -> void:
	await _settle(30)
	_emit_combat_victory(run_root, "001h-shot-next-combat")
	await _wait_for_run_scene(run_root, "reward", 900)
	var reward_scene: Control = _active_scene(run_root)
	if reward_scene == null:
		failures.append("next combat reward scene unavailable for screenshot proof")
		return
	reward_scene._choose_relic()
	await _wait_for_run_scene(run_root, "map", 900)
	await _settle(10)

func _active_scene(run_root: Control) -> Control:
	var director = run_root.get("run_director")
	if director == null:
		return null
	return director.active_scene as Control

func _wait_for_run_scene(run_root: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		var director = run_root.get("run_director")
		if str(run_root.get("phase")) == expected and director != null and str(director.active_scene_name) == expected:
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

func _shot_dir_from_args() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	return ""

func _shot(name: String) -> void:
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name)
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path: String = shot_dir.path_join(name + ".png")
	var err: Error = image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
