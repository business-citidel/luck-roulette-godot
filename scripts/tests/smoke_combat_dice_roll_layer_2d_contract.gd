extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var battle: Control = BattleScene.instantiate()
	root.add_child(battle)
	await _settle(12)

	var layer: Variant = battle.get("dice_roll_layer")
	if not (layer is Control):
		failures.append("battle did not create reusable 2D dice roll layer")

	battle._roll_dice()
	await _wait_for_dice_result(battle, 180)
	if not bool(battle.get("dice_rolled")):
		failures.append("battle did not resolve dice roll through 2D layer")
	if bool(battle.get("dice_roll_in_progress")):
		failures.append("battle dice roll stayed in progress")
	if int(battle.get("attack_base")) <= 0:
		failures.append("battle attack_base did not update after 2D roll")
	if str(battle.get("phase")) != "dice":
		failures.append("battle phase changed before confirm after dice roll")

	var first_value := int((battle.get("dice") as Array)[0])
	var first_rerolls := int(battle.get("rerolls_left"))
	battle._reroll_open()
	await _wait_for_reroll_result(battle, first_rerolls, 180)
	if bool(battle.get("dice_roll_in_progress")):
		failures.append("battle reroll stayed in progress")
	if int(battle.get("rerolls_left")) != first_rerolls - 1:
		failures.append("battle reroll count did not decrement once")
	if int((battle.get("dice") as Array)[0]) == first_value:
		failures.append("battle 2D reroll did not avoid previous die value")

	battle.queue_free()
	await process_frame
	if failures.is_empty():
		print("combat 2D dice roll layer contract smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _wait_for_dice_result(battle: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if bool(battle.get("dice_rolled")) and not bool(battle.get("dice_roll_in_progress")):
			return
		await process_frame

func _wait_for_reroll_result(battle: Control, previous_rerolls: int, max_frames: int) -> void:
	for i in range(max_frames):
		if int(battle.get("rerolls_left")) == previous_rerolls - 1 and not bool(battle.get("dice_roll_in_progress")):
			return
		await process_frame

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

