extends SceneTree

const RUN_SCENE := "res://scenes/run/run_root.tscn"
const LegacySlotPlaytestGuard := preload("res://scripts/tests/support/legacy_slot_playtest_guard.gd")

var shot_dir: String = ""
var failures: Array[String] = []

func _initialize() -> void:
	if not LegacySlotPlaytestGuard.is_allowed():
		push_error(LegacySlotPlaytestGuard.message("playtest_end_to_end_structure.gd"))
		quit(1)
		return
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)

	var scene: PackedScene = load(RUN_SCENE)
	if scene == null:
		push_error("Could not load run root scene")
		quit(1)
		return

	var run_root: Control = scene.instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(run_root)
	await _wait_for_run_scene(run_root, "title", 900)
	run_root._test_start_run()
	await _wait_for_run_scene(run_root, "intro", 900)
	run_root._test_skip_intro()
	await _wait_for_run_scene(run_root, "map", 900)
	await _shot("00_run_map_select_node", run_root)
	run_root._test_select_current_map_node()

	await _wait_for_combat(run_root, 900)
	await _settle(30)
	var combat: Control = run_root.get("active_combat") as Control
	if combat == null:
		failures.append("combat did not open")
	else:
		await _shot("01_combat_table_idle", run_root)
		await _drive_combat(combat, run_root)

	await _wait_for_run_scene(run_root, "reward", 1200)
	await _shot("07_reward_relic_choices", run_root)
	run_root._test_choose_default_reward()
	await _wait_for_run_scene(run_root, "map", 1200)
	await _shot("08_return_to_map_with_relic", run_root)

	if str(run_root.get("phase")) != "map":
		failures.append("did not return to map")
	var run_state = run_root.get("run_state")
	if int(run_state.map_step) < 1:
		failures.append("map progress did not advance")
	if not run_state.relic_ids.has("loaded_die"):
		failures.append("reward relic did not persist")

	if failures.is_empty():
		run_root._test_select_current_map_node()
		await _wait_for_run_scene(run_root, "event", 900)
		await _shot("09_event_payload_scene", run_root)
		run_root._test_choose_default_scene()
		await _wait_for_run_scene(run_root, "map", 900)
		await _shot("10_return_to_map_after_event", run_root)

	if failures.is_empty():
		run_root._test_select_current_map_node()
		await _wait_for_run_scene(run_root, "shop", 900)
		await _shot("11_shop_scene_relic_offer", run_root)
		run_root._test_choose_default_scene()
		await _wait_for_run_scene(run_root, "map", 900)
		await _shot("12_return_to_map_after_shop", run_root)

	if failures.is_empty():
		run_root._test_select_current_map_node()
		await _wait_for_run_scene(run_root, "rest", 900)
		await _shot("13_rest_scene_next_combat_mod", run_root)
		run_root._test_choose_default_scene()
		await _wait_for_run_scene(run_root, "map", 900)
		await _shot("14_return_to_map_with_next_mod", run_root)

	if failures.is_empty():
		run_root._test_select_current_map_node()
		await _wait_for_combat(run_root, 900)
		await _settle(30)
		await _wait_for_combat_relic(run_root, "loaded_die", 900)
		await _settle(45)
		var next_combat: Control = run_root.get("active_combat") as Control
		await _shot("15_next_combat_with_relic_and_mod_payload", run_root)
		if next_combat == null:
			failures.append("next combat did not open after rest")
		elif not (next_combat.get("active_relic_ids") as Array).has("loaded_die"):
			failures.append("next combat did not receive loaded_die")
		elif int((run_root.get("last_encounter_payload") as Dictionary).get("enemy_damage_delta", 0)) >= 0:
			failures.append("next combat did not receive rest/shop modifier")

	if failures.is_empty():
		print("end-to-end structure playtest passed")
		run_root.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		run_root.queue_free()
		await process_frame
		quit(1)

func _drive_combat(combat: Control, run_root: Control) -> void:
	combat.set("combat_core", "slot_marble")
	combat._roll_dice()
	await _wait_for_dice_roll(combat, 180)
	await _settle(8)
	await _shot("02_table_dice_result", run_root)
	await _settle(18)
	combat.set("attack_base", 120)
	if str(combat.get("phase")) != "marble" or (combat.get("marbles") as Array).is_empty():
		combat._take_marbles()
	await _settle(12)
	await _shot("03_table_marble_ready", run_root)
	combat._open_marble_throw_ritual()
	await _wait_for_marble_setup_ready(combat, 1200)
	await _settle(18)
	await _shot("04_table_marble_placed", run_root)
	combat._open_roulette_spin_ritual()
	await _wait_for_combat_phase(combat, "intervene", 1200)
	await _settle(18)
	await _shot("05_table_roulette_result", run_root)
	combat._resolve_pending()
	await _wait_for_combat_finished(combat, 1200)
	await _settle(24)
	await _shot("06_combat_resolution_return", run_root)

func _shot_dir_from_args() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	return ""

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _wait_for_dice_roll(combat: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if bool(combat.get("dice_rolled")):
			return
		await process_frame

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

func _wait_for_combat_relic(run_root: Control, relic_id: String, max_frames: int) -> void:
	for i in range(max_frames):
		var combat: Control = run_root.get("active_combat") as Control
		if combat != null and (combat.get("active_relic_ids") as Array).has(relic_id):
			return
		await process_frame

func _wait_for_ritual(combat: Control, ritual_name: String, max_frames: int) -> void:
	for i in range(max_frames):
		if combat.ritual_director != null and str(combat.ritual_director.active_ritual_name) == ritual_name:
			return
		await process_frame

func _wait_for_ritual_close(combat: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if combat.ritual_director != null and combat.ritual_director.active_ritual == null:
			return
		await process_frame

func _wait_for_ritual_phase(ritual: Node, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if ritual != null and str(ritual.get("phase")) == expected:
			return
		await process_frame

func _wait_for_marble_setup_ready(combat: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if combat._marble_setup_ready():
			return
		await process_frame

func _wait_for_combat_phase(combat: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if str(combat.get("phase")) == expected:
			return
		await process_frame

func _wait_for_combat_finished(combat: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if bool(combat.get("combat_result_emitted")):
			return
		await process_frame

func _shot(name: String, run_root: Control) -> void:
	await _settle(3)
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name + "; run this playtest without --headless")
		return
	var image: Image = viewport_texture.get_image()
	if image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path: String = shot_dir.path_join(name + ".png")
	var err: Error = image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
