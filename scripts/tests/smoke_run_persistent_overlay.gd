extends SceneTree

const RUN_SCENE := "res://scenes/run/run_root.tscn"

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var scene: PackedScene = load(RUN_SCENE)
	var run_root: Control = scene.instantiate()
	root.add_child(run_root)

	await _wait_for_run_scene(run_root, "title", 900)
	_assert_overlay_hidden(run_root, "title")
	run_root._test_start_run()
	await _wait_for_run_scene(run_root, "character_select", 900)
	_assert_overlay_hidden(run_root, "character_select")
	run_root._test_select_default_character()
	await _wait_for_run_scene(run_root, "map", 900)
	_assert_overlay_visible(run_root, "map")

	var shop_scene: Node = run_root.run_director.show_terminal_scene("shop", load("res://scenes/run/shop_scene.tscn"), {
		"run_state": run_root.run_state.to_payload(),
		"map_result": {"node_type": "shop", "node_index": 2}
	})
	var shop_results: Array[Dictionary] = []
	shop_scene.completed.connect(func(result: Dictionary) -> void: shop_results.append(result))
	run_root.set("phase", "shop")
	run_root._sync_overlay()
	await process_frame
	_assert_overlay_visible(run_root, "shop")
	_assert_overlay_proceed(run_root, true)
	run_root.set("stage_proceed_pending", true)
	run_root._sync_overlay()
	_assert_overlay_proceed(run_root, true)
	run_root.set("stage_proceed_pending", false)

	run_root.run_state.relic_ids.append("loaded_die")
	run_root._test_mount_combat_encounter("crook_table")
	await _wait_for_combat(run_root, 900)
	_assert_overlay_visible(run_root, "combat")
	_assert_overlay_proceed(run_root, false)
	var combat: Control = run_root.get("active_combat") as Control
	if combat == null:
		failures.append("combat did not mount for overlay payload check")
	else:
		combat.set("player_hp", 17)
		combat._render()
		await process_frame
		var overlay: Control = run_root.get("run_overlay") as Control
		var overlay_payload: Dictionary = overlay.get("run_payload") as Dictionary
		if int(overlay_payload.get("player_hp", -1)) != 17:
			failures.append("overlay did not mirror live combat HP")
		if not (overlay_payload.get("relic_ids", []) as Array).has("loaded_die"):
			failures.append("overlay did not mirror combat relic ids")
		combat._show_feedback_from_effects([{
			"relic_id": "loaded_die",
			"effect_id": "attack_die_plus_one",
			"name": "Loaded Die"
		}], "dice")
		await process_frame
		var pulse_timers: Dictionary = overlay.get("relic_pulse_timers") as Dictionary
		if not pulse_timers.has("loaded_die"):
			failures.append("overlay did not pulse triggered combat relic")

	run_root._test_force_run_clear()
	await _wait_for_terminal_phase(run_root, "run_clear", 900)
	_assert_overlay_hidden(run_root, "run_clear")

	run_root.queue_free()
	await process_frame
	if failures.is_empty():
		print("run persistent overlay smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _assert_overlay_visible(run_root: Control, label: String) -> void:
	var overlay: Control = run_root.get("run_overlay") as Control
	if overlay == null:
		failures.append("run overlay missing during " + label)
	elif not overlay.visible:
		failures.append("run overlay hidden during " + label)
	elif (overlay.get("run_payload") as Dictionary).is_empty():
		failures.append("run overlay payload empty during " + label)

func _assert_overlay_hidden(run_root: Control, label: String) -> void:
	var overlay: Control = run_root.get("run_overlay") as Control
	if overlay == null:
		failures.append("run overlay missing during " + label)
	elif overlay.visible:
		failures.append("run overlay visible during non-play phase " + label)

func _assert_overlay_proceed(run_root: Control, expected_visible: bool) -> void:
	var overlay: Control = run_root.get("run_overlay") as Control
	if overlay == null:
		failures.append("run overlay missing for proceed check")
		return
	var button: Button = overlay.get("proceed_button") as Button
	if button == null:
		failures.append("overlay proceed button missing")
	elif button.visible != expected_visible:
		failures.append("overlay proceed visibility mismatch: visible=" + str(button.visible) + " phase=" + str(run_root.get("phase")))
	elif expected_visible and button.disabled:
		failures.append("overlay proceed should be enabled: disabled=" + str(button.disabled) + " phase=" + str(run_root.get("phase")))

func _press_overlay_proceed(run_root: Control) -> void:
	var overlay: Control = run_root.get("run_overlay") as Control
	if overlay == null:
		failures.append("run overlay missing for proceed press")
		return
	var button: Button = overlay.get("proceed_button") as Button
	if button == null:
		failures.append("overlay proceed button missing for press")
		return
	button.pressed.emit()

func _wait_for_run_scene(run_root: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		var director = run_root.get("run_director")
		if str(run_root.get("phase")) == expected and director != null and str(director.active_scene_name) == expected:
			return
		await process_frame

func _wait_for_terminal_phase(run_root: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if str(run_root.get("phase")) == expected:
			return
		await process_frame

func _wait_for_combat(run_root: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if str(run_root.get("phase")) == "combat" and run_root.get("active_combat") != null:
			return
		await process_frame
