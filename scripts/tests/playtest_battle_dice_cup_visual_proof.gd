extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const DiceResolver := preload("res://scripts/systems/dice_resolver.gd")

var failures: Array[String] = []
var capture_dir := "user://battle-dice-cup-visual-proof"
var battle: Control

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	if OS.has_environment("LR_CAPTURE_DIR"):
		capture_dir = OS.get_environment("LR_CAPTURE_DIR")
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.replace("--capture-dir=", "")
	DirAccess.make_dir_recursive_absolute(capture_dir)

	battle = BattleScene.instantiate()
	root.add_child(battle)
	await _frames(6)
	battle.use_dice_cup_layer_3d = true
	_prepare_two_dice_battle()
	await _capture("00_entry")

	battle._roll_dice()
	await _frames(12)
	await _capture("01_shake")
	await _frames(30)
	await _capture("02_pour")
	await _wait_for_roll_done(180)
	await _frames(12)
	await _capture("03_result")
	_assert_battle_roll("first")

	var before_rerolls := int(battle.rerolls_left)
	battle._reroll_open()
	await _frames(12)
	await _capture("04_reroll_shake")
	await _wait_for_roll_done(180)
	await _frames(12)
	await _capture("05_reroll_result")
	if int(battle.rerolls_left) != before_rerolls - 1:
		failures.append("reroll did not spend exactly one reroll")
	_assert_battle_roll("reroll")

	battle.queue_free()
	await _frames(2)
	if failures.is_empty():
		print("Battle dice cup visual proof passed")
		print("CAPTURE_DIR=" + capture_dir)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("CAPTURE_DIR=" + capture_dir)
		quit(1)

func _prepare_two_dice_battle() -> void:
	battle.dice_rule_id = "two_dice_attack_guard"
	battle.dice = DiceResolver.starting_values(battle.dice_rule_id)
	battle.dice_locked = DiceResolver.starting_locks(battle.dice_rule_id)
	battle.dice_rolled = false
	battle.dice_relics_applied = false
	battle.rerolls_left = int(DiceResolver.rule(battle.dice_rule_id).get("rerolls", 2))
	battle.phase = "dice"
	battle.selected_attack_die_index = -1
	battle.attack_base = 0
	battle.guard_value = 0
	battle._render()

func _assert_battle_roll(context: String) -> void:
	if bool(battle.dice_roll_in_progress):
		failures.append(context + ": roll still in progress")
	if not bool(battle.dice_rolled):
		failures.append(context + ": dice_rolled is false")
	if battle.dice.size() != 2:
		failures.append(context + ": expected two dice, got " + str(battle.dice))
	for value in battle.dice:
		if int(value) < 1 or int(value) > 6:
			failures.append(context + ": out-of-range dice " + str(battle.dice))
	if battle.dice_cup_roll_layer == null:
		failures.append(context + ": missing dice cup layer")
	elif bool(battle.dice_cup_roll_layer.is_rolling()):
		failures.append(context + ": cup layer still rolling")

func _wait_for_roll_done(max_frames: int) -> void:
	for i in range(max_frames):
		if not bool(battle.dice_roll_in_progress):
			return
		await process_frame
	failures.append("roll timed out")

func _capture(name: String) -> void:
	await _frames(4)
	var image := root.get_texture().get_image()
	if image == null:
		failures.append("failed to capture viewport image for " + name)
		return
	var path := capture_dir.path_join(name + ".png")
	var err := image.save_png(path)
	if err != OK:
		failures.append("failed to save capture " + path + ": " + str(err))
	else:
		print("CAPTURE=" + path)

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame
