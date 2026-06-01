extends SceneTree

const MAIN_SCENE := "res://scenes/battle/battle_scene.tscn"
const LegacySlotPlaytestGuard := preload("res://scripts/tests/support/legacy_slot_playtest_guard.gd")

var shot_dir: String = ""
var failures: Array[String] = []

func _initialize() -> void:
	if not LegacySlotPlaytestGuard.is_allowed():
		push_error(LegacySlotPlaytestGuard.message("playtest_full_ritual_flow.gd"))
		quit(1)
		return
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)

	var scene: PackedScene = load(MAIN_SCENE)
	if scene == null:
		push_error("Could not load main scene")
		quit(1)
		return

	var main: Control = scene.instantiate()
	var marked_slot := ""
	root.size = Vector2i(1280, 720)
	root.add_child(main)
	main.set("combat_core", "slot_marble")
	await _settle(16)
	await _shot("00_table_idle_dice_prop", main)

	main._roll_dice()
	await _settle(8)
	await _shot("01_table_dice_roll_motion", main)
	await _wait_for_dice_roll(main, 180)
	await _settle(10)
	await _shot("02_table_dice_result_focus", main)
	main._take_marbles()
	await _settle(36)
	var marbles: Array = main.get("marbles") as Array
	if marbles.size() != 1 or str(marbles[0]) != "plain":
		failures.append("dice result did not create exactly one neutral plain marble")
	await _shot("03_table_return_dice_result", main)

	if failures.is_empty():
		await _settle(24)
		await _shot("04_table_pouch_ready", main)

	if failures.is_empty():
		main._open_marble_throw_ritual()
		await _settle(24)
		await _shot("05_table_marble_place_flight", main)
		await _wait_for_marble_setup_ready(main, 240)
		if not main._marble_setup_ready():
			failures.append("inline marble placement did not finish")
		else:
			marked_slot = str(main._first_filled_slot())
			if marked_slot == "":
				failures.append("inline marble placement did not mark a roulette slot")
			elif not ((main.get("placed_slots") as Dictionary).get(marked_slot, []) as Array).has("plain"):
				failures.append("marked roulette slot does not contain neutral plain token")
			await _settle(12)
			await _shot("06_table_roulette_ready", main)

	if failures.is_empty():
		main._open_roulette_spin_ritual()
		await _settle(36)
		await _shot("07_table_roulette_spinning", main)
		await _wait_for_phase(main, "intervene", 240)
		if marked_slot != "":
			main.set("pending_slot", marked_slot)
			main.set("damage_multiplier", 1.0)
			main.set("payout_multiplier", 1.0)
			main._update_visual_layers()
		await _shot("08_table_roulette_result_choice", main)
		if main.phase != "intervene":
			failures.append("inline roulette did not reach result choice")
		else:
			main._resolve_pending()
			await _wait_for_combat_resolution(main, 900)
			if marked_slot != "" and not str(main.get("message")).contains("강화 칸"):
				failures.append("resolution did not apply boosted marked-slot outcome")
			await _settle(18)
			await _shot("09_table_resolution_return", main)

	if main.ritual_director != null and main.ritual_director.active_ritual != null:
		failures.append("ritual remained active after full flow")
	if failures.is_empty() and not (main.phase in ["enemy", "result"]):
		failures.append("full ritual flow did not reach combat resolution")

	if failures.is_empty():
		print("full ritual flow playtest passed")
		main.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		main.queue_free()
		await process_frame
		quit(1)

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

func _wait_for_ritual(main: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if main.ritual_director != null and main.ritual_director.active_ritual != null:
			return
		await process_frame

func _wait_for_ritual_close(main: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if main.ritual_director != null and main.ritual_director.active_ritual == null:
			return
		await process_frame

func _wait_for_ritual_phase(ritual: Node, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if ritual != null and str(ritual.get("phase")) == expected:
			return
		await process_frame

func _wait_for_marble_setup_ready(main: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if main._marble_setup_ready():
			return
		await process_frame

func _wait_for_combat_resolution(main: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if main.phase in ["enemy", "result"]:
			return
		await process_frame

func _wait_for_phase(main: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if str(main.phase) == expected:
			return
		await process_frame

func _wait_for_dice_roll(main: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if bool(main.get("dice_rolled")):
			return
		await process_frame

func _wait_for_named_ritual(main: Control, ritual_name: String, max_frames: int) -> void:
	for i in range(max_frames):
		if main.ritual_director != null and str(main.ritual_director.active_ritual_name) == ritual_name:
			return
		await process_frame

func _shot(name: String, main: Control) -> void:
	main._update_visual_layers()
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
