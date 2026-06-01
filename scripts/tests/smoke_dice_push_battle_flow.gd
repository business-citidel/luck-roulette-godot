extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const GoStopButtonDriver := preload("res://scripts/tests/support/go_stop_button_driver.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_double_attack_confirm_then_choose()
	await _check_double_attack_push_success()
	await _check_attack_guard_push_then_choose()
	if failures.is_empty():
		print("dice push battle flow smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_double_attack_confirm_then_choose() -> void:
	var combat: Control = BattleScene.instantiate()
	root.add_child(combat)
	await process_frame
	combat.configure_encounter({
		"combat_core": "numeric_roulette",
		"combat_cash": 18,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 50,
		"enemy_max_hp": 50,
		"dice_rule_id": "two_dice_double_attack",
		"monster_id": "debt_collector",
		"monster_name": "Debt Collector",
		"move_pattern": ["hp_strike"]
	})
	await process_frame
	combat._finish_dice_roll_with_values([2, 6])
	await process_frame
	if bool(combat.get("dice_role_selecting")):
		failures.append("double attack should not enter die selection before confirm")
	var action_texts := _action_texts(combat)
	if not action_texts.has("Go") or not action_texts.has("Stop"):
		failures.append("double attack dice should show Go/Stop actions after roll, got " + str(action_texts))
	if action_texts.has("Reroll") or action_texts.has("다시 굴리기"):
		failures.append("push-enabled dice should not show Reroll beside Go/Stop")
	_press_button_by_text(combat, "Stop", "double attack dice confirm")
	await process_frame
	if not bool(combat.get("dice_role_selecting")):
		failures.append("double attack confirm should enter die selection")
	combat._select_attack_die(1)
	await process_frame
	if str(combat.get("phase")) != "wager":
		failures.append("double attack selection should enter wager after confirm")
	if int(combat.get("attack_base")) != 8:
		failures.append("double attack initial attack should be raw total 8")
	if int(combat.get("dice_push_current_total")) != 8:
		failures.append("push seed should use raw visible total 8")
	combat.queue_free()
	for i in range(20):
		await process_frame

func _action_texts(combat: Control) -> Array[String]:
	var texts: Array[String] = []
	if combat.prompt_layer == null or combat.prompt_layer.action_bar == null:
		return texts
	for child in combat.prompt_layer.action_bar.get_children():
		var button := child as Button
		if button != null:
			texts.append(button.text)
	return texts

func _press_button_by_text(combat: Control, text: String, context: String) -> void:
	var result: String = GoStopButtonDriver.press_button_by_text(combat, text)
	if result != "":
		failures.append(context + " action " + text + " was " + result)

func _check_double_attack_push_success() -> void:
	var combat: Control = BattleScene.instantiate()
	root.add_child(combat)
	await process_frame
	combat.configure_encounter({
		"combat_core": "numeric_roulette",
		"combat_cash": 18,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 50,
		"enemy_max_hp": 50,
		"dice_rule_id": "two_dice_double_attack",
		"monster_id": "debt_collector",
		"monster_name": "Debt Collector",
		"move_pattern": ["hp_strike"]
	})
	await process_frame
	combat._finish_dice_roll_with_values([2, 6])
	await process_frame
	if bool(combat.get("dice_role_selecting")):
		failures.append("double attack should not enter die selection before push/confirm")
	if int(combat.get("dice_push_current_total")) != 8:
		failures.append("push seed should use raw visible total 8")
	combat.set("use_dice_cup_layer_3d", true)
	_press_button_by_text(combat, "Go", "double attack dice push")
	await process_frame
	combat._finish_dice_roll_with_values([5, 5])
	await process_frame
	if int(combat.get("dice_push_count")) != 1:
		failures.append("push count should increment once")
	if int(combat.get("dice_push_current_total")) != 10:
		failures.append("push current total should move to new raw total 10")
	if int(combat.get("attack_base")) != 11:
		failures.append("8 -> 10 push should preview attack 11")
	if str(combat.get("phase")) != "dice":
		failures.append("successful push should still wait for lock/confirm")
	if bool(combat.get("dice_role_selecting")):
		failures.append("successful push should not enter die selection before confirm")
	_press_button_by_text(combat, "Stop", "double attack dice confirm after push")
	await process_frame
	if not bool(combat.get("dice_role_selecting")):
		failures.append("double attack confirm after push should enter die selection")
	combat._select_attack_die(1)
	await process_frame
	if str(combat.get("phase")) != "wager":
		failures.append("selected pushed double attack dice should enter wager phase")
	if int(combat.get("attack_base")) != 11:
		failures.append("confirmed pushed attack should remain 11 before roulette, got " + str(combat.get("attack_base")))
	combat.queue_free()
	for i in range(20):
		await process_frame

func _check_attack_guard_push_then_choose() -> void:
	var combat: Control = BattleScene.instantiate()
	root.add_child(combat)
	await process_frame
	combat.configure_encounter({
		"combat_core": "numeric_roulette",
		"combat_cash": 18,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 50,
		"enemy_max_hp": 50,
		"dice_rule_id": "two_dice_attack_guard",
		"monster_id": "debt_collector",
		"monster_name": "Debt Collector",
		"move_pattern": ["hp_strike"]
	})
	await process_frame
	combat._finish_dice_roll_with_values([2, 6])
	await process_frame
	if int(combat.get("dice_push_current_total")) != 8:
		failures.append("attack/guard push seed should use raw visible total 8")
	if bool(combat.get("dice_role_selecting")):
		failures.append("attack/guard should not enter die selection before push/confirm")
	combat.set("use_dice_cup_layer_3d", true)
	_press_button_by_text(combat, "Go", "attack/guard dice push")
	await process_frame
	combat._finish_dice_roll_with_values([5, 5])
	await process_frame
	if int(combat.get("attack_base")) != 11:
		failures.append("attack/guard 8 -> 10 push should preview attack 11")
	if int(combat.get("selected_attack_die_index")) != -1:
		failures.append("attack/guard should still wait for main die choice after push")
	if bool(combat.get("dice_role_selecting")):
		failures.append("attack/guard push should still wait for confirm before die choice")
	_press_button_by_text(combat, "Stop", "attack/guard dice confirm after push")
	await process_frame
	if not bool(combat.get("dice_role_selecting")):
		failures.append("attack/guard confirm after push should enter die selection")
	combat._select_attack_die(0)
	await process_frame
	if str(combat.get("phase")) != "wager":
		failures.append("attack/guard selection after confirm should enter wager")
	if int(combat.get("attack_base")) != 11:
		failures.append("attack/guard selection should keep pushed attack 11")
	if int(combat.get("guard_value")) != 5:
		failures.append("attack/guard selection should use unchosen pushed die as guard 5")
	if int(combat.get("player_block")) != 5:
		failures.append("attack/guard selection should add guard 5 to player block")
	if int(combat.get("attack_base")) != 11:
		failures.append("confirmed attack/guard pushed attack should remain 11")
	combat.queue_free()
	for i in range(20):
		await process_frame
