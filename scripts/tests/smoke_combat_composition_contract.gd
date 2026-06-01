extends SceneTree

const RUN_SCENE := preload("res://scenes/run/run_root.tscn")
const MonsterMoveCatalog := preload("res://scripts/systems/monster_move_catalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var run_root: Control = RUN_SCENE.instantiate()
	root.add_child(run_root)

	await _wait_for_run_scene(run_root, "title", 900)
	run_root._test_start_run()
	await _wait_for_run_scene(run_root, "character_select", 900)
	run_root._test_select_default_character()
	await _wait_for_run_scene(run_root, "map", 900)

	run_root.run_state.relic_ids.append("loaded_die")
	run_root._test_mount_combat_encounter("crook_table")
	await _wait_for_combat(run_root, 900)

	var overlay: Control = run_root.get("run_overlay") as Control
	if overlay == null or not overlay.visible:
		failures.append("persistent overlay missing in combat")
	else:
		var overlay_payload: Dictionary = overlay.get("run_payload") as Dictionary
		if int(overlay_payload.get("player_hp", -1)) <= 0:
			failures.append("overlay combat HP payload missing")
		if not (overlay_payload.get("relic_ids", []) as Array).has("loaded_die"):
			failures.append("overlay combat relic payload missing")
		var button: Button = overlay.get("proceed_button") as Button
		if button == null:
			failures.append("overlay proceed button missing")
		elif button.visible:
			failures.append("overlay proceed button should stay hidden in combat")

	var combat: Control = run_root.get("active_combat") as Control
	if combat == null:
		failures.append("combat did not mount")
	else:
		var opponent_layer: Control = combat.get("opponent_layer") as Control
		if opponent_layer == null:
			failures.append("opponent layer missing")
		else:
			var move_id := str(opponent_layer.get("current_move_id"))
			var move := MonsterMoveCatalog.get_move(move_id)
			if str(move.get("intent", "")) == "":
				failures.append("opponent move intent unavailable")
			var intent_text := str(opponent_layer.get("enemy_intent")).to_lower()
			if intent_text == "":
				failures.append("opponent intent text unavailable")
			for blocked in ["risk", "safety", "pressure"]:
				if intent_text.contains(blocked):
					failures.append("opponent intent still exposes abstract state: " + blocked)

	run_root.queue_free()
	await process_frame
	if failures.is_empty():
		print("combat composition contract smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _wait_for_run_scene(run_root: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		var director = run_root.get("run_director")
		if str(run_root.get("phase")) == expected and director != null and str(director.active_scene_name) == expected:
			return
		await process_frame
	failures.append("timed out waiting for " + expected)

func _wait_for_combat(run_root: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if str(run_root.get("phase")) == "combat" and run_root.get("active_combat") != null:
			return
		await process_frame
	failures.append("timed out waiting for combat")
