extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const DiceResolver := preload("res://scripts/systems/dice_resolver.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var battle: Control = BattleScene.instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	battle.use_dice_cup_layer_3d = true

	battle.dice_rule_id = "two_dice_attack_guard"
	battle.dice = DiceResolver.starting_values(battle.dice_rule_id)
	battle.dice_locked = DiceResolver.starting_locks(battle.dice_rule_id)
	battle.dice_rolled = false
	battle.rerolls_left = int(DiceResolver.rule(battle.dice_rule_id).get("rerolls", 2))
	battle.phase = "dice"
	battle._render()

	battle._roll_dice()
	await _wait_for_roll_done(battle, 360)
	if bool(battle.dice_roll_in_progress):
		failures.append("BattleScene 3D cup roll did not finish")
	if not bool(battle.dice_rolled):
		failures.append("BattleScene did not mark dice as rolled")
	if battle.dice.size() != 2:
		failures.append("BattleScene did not keep two dice after 3D cup roll: " + str(battle.dice))
	if battle.dice_cup_roll_layer == null:
		failures.append("BattleScene did not create dice_cup_roll_layer")
	if battle.dice_cup_roll_layer != null and bool(battle.dice_cup_roll_layer.is_rolling()):
		failures.append("BattleScene dice cup layer stayed rolling")
	for value in battle.dice:
		if int(value) < 1 or int(value) > 6:
			failures.append("BattleScene emitted out-of-range die value: " + str(battle.dice))

	var before_rerolls: int = int(battle.rerolls_left)
	battle._reroll_open()
	await _wait_for_roll_done(battle, 360)
	if bool(battle.dice_roll_in_progress):
		failures.append("BattleScene 3D cup reroll did not finish")
	if int(battle.rerolls_left) != before_rerolls - 1:
		failures.append("BattleScene reroll did not spend exactly one reroll: before=" + str(before_rerolls) + " after=" + str(battle.rerolls_left))
	if battle.dice.size() != 2:
		failures.append("BattleScene did not keep two dice after 3D cup reroll: " + str(battle.dice))

	battle.queue_free()
	await process_frame
	if failures.is_empty():
		print("BattleScene 3D dice cup layer contract smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _wait_for_roll_done(battle: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if not bool(battle.dice_roll_in_progress):
			return
		await process_frame
