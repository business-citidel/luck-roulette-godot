extends SceneTree

const MAIN_SCENE := "res://scenes/battle/battle_scene.tscn"

var failures: Array[String] = []

func _initialize() -> void:
	var scene: PackedScene = load(MAIN_SCENE)
	if scene == null:
		push_error("Could not load main scene")
		quit(1)
		return

	var main: Control = scene.instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(main)
	await _settle(8)
	main.set("combat_core", "slot_marble")

	if main.ritual_director == null:
		failures.append("ritual director missing")
	else:
		main._roll_dice()
		await _wait_for_dice_roll(main, 180)
		main._try_toggle_die(main._die_rect(0).get_center())
		await _settle(6)
		main._take_marbles()
		await _settle(50)

	if main.ritual_director != null and main.ritual_director.active_ritual != null:
		failures.append("inline table dice should not open a ritual")
	if not main.dice_rolled:
		failures.append("dice result was not applied to combat table")
	if main.phase != "marble":
		failures.append("dice ritual should advance directly to marble placement phase")
	if main.dice.is_empty() or int(main.dice[0]) < 1 or int(main.dice[0]) > 6:
		failures.append("dice ritual returned invalid d6 values")
	if int(main.attack_base) <= 0:
		failures.append("dice ritual did not produce attack_base")

	if failures.is_empty():
		await _settle(12)
		if main.phase != "marble" or main.marbles.size() != 1:
			failures.append("dice result did not create one neutral marble automatically")
		elif str(main.marbles[0]) != "plain":
			failures.append("dice result created a colored marble instead of neutral plain token")
		else:
			main._open_marble_throw_ritual()
			await _wait_for_marble_setup_ready(main, 240)

	if failures.is_empty():
		if not main._marble_setup_ready():
			failures.append("inline marble placement did not set up placed slots")
		elif not _has_plain_mark(main.get("placed_slots") as Dictionary):
			failures.append("inline marble placement did not mark a roulette slot with plain token")
		else:
			main._open_roulette_spin_ritual()
			await _wait_for_phase(main, "intervene", 240)
			if main.phase != "intervene":
				failures.append("inline roulette spin did not reach result application phase")
			else:
				main._resolve_pending()
				await _wait_for_combat_resolution(main, 900)

	if main.ritual_director != null and main.ritual_director.active_ritual != null:
		failures.append("ritual remained active after full flow")
	if failures.is_empty() and not (main.phase in ["enemy", "result"]):
		failures.append("inline roulette did not return to combat resolution")

	if failures.is_empty():
		print("ritual flow smoke passed")
		main.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		main.queue_free()
		await process_frame
		quit(1)

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _wait_for_dice_roll(main: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if bool(main.get("dice_rolled")):
			return
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

func _has_plain_mark(placed_slots: Dictionary) -> bool:
	for slot_id in placed_slots.keys():
		var arr: Array = placed_slots.get(slot_id, [])
		if arr.has("plain"):
			return true
	return false

func _wait_for_named_ritual(main: Control, ritual_name: String, max_frames: int) -> void:
	for i in range(max_frames):
		if main.ritual_director != null and str(main.ritual_director.active_ritual_name) == ritual_name:
			return
		await process_frame
