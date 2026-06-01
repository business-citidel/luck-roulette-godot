extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	var battle: Control = BattleScene.instantiate()
	root.add_child(battle)
	root.size = Vector2i(1280, 720)
	await process_frame
	battle.set("combat_core", "numeric_roulette")
	battle.set("dice_rolled", true)
	battle.set("dice_relics_applied", true)
	battle.set("dice", [4])
	battle.set("dice_locked", [false])
	battle.set("attack_base", 10)
	battle._take_marbles()
	await process_frame
	if str(battle.get("phase")) != "marble_choice":
		failures.append("numeric combat did not enter marble choice phase")
	var revealed: Array = battle.get("revealed_marbles")
	if revealed.size() < 1 or revealed.size() > 3:
		failures.append("marble choice should reveal 1-3 marbles")
	battle._choose_revealed_marble(0)
	await process_frame
	if str(battle.get("phase")) != "wager":
		failures.append("choosing a marble did not prepare roulette spin")
	if (battle.get("selected_marble") as Dictionary).is_empty():
		failures.append("selected marble payload missing")
	if int(battle.get("wager_marbles_committed")) != 0:
		failures.append("typed marble flow should not use count-based wager damage")
	battle.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("numeric marble selection flow smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
