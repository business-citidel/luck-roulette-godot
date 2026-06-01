extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var battle: Control = BattleScene.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set("combat_core", "numeric_roulette")
	battle.set("dice_rolled", true)
	battle.set("dice_relics_applied", true)
	battle.set("dice", [4])
	battle.set("dice_locked", [false])
	battle.set("attack_base", 10)
	battle._take_marbles()
	await process_frame
	var overlay := battle.get_node_or_null("HudCanvas/CombatMarbleStatusOverlay") as Control
	if overlay == null:
		failures.append("combat marble status overlay should be installed")
	else:
		var items: Array = battle.call("_combat_marble_status_items")
		var summary: Dictionary = battle.call("_combat_marble_status_summary")
		if items.size() != 9:
			failures.append("marble choice status should show all combat marbles")
		if int(summary.get("available", 0)) != 9:
			failures.append("revealed + bag marbles should count as available before choice")
		if int(summary.get("discarded", 0)) != 0:
			failures.append("discard should be empty before choosing a revealed marble")
		var pouch_button := _button_covering(battle.get_node("HudCanvas/ObjectInputLayer") as Control, battle.call("_marble_pouch_status_rect"))
		if pouch_button == null:
			failures.append("pouch status hit button should cover the visible pouch")
			battle.call("_open_combat_marble_status")
		else:
			pouch_button.pressed.emit()
		await process_frame
		if not overlay.visible:
			failures.append("pouch status overlay should open from combat")
		overlay.call("close")
		await process_frame
		if overlay.visible:
			failures.append("pouch status overlay should close")
	battle._choose_revealed_marble(0)
	await process_frame
	var selected_items: Array = battle.call("_combat_marble_status_items")
	var selected_summary: Dictionary = battle.call("_combat_marble_status_summary")
	if selected_items.size() != 9:
		failures.append("selected status should still show all combat marbles")
	if int(selected_summary.get("available", 0)) != 7:
		failures.append("selected + bag marbles should count as available after choice")
	if int(selected_summary.get("discarded", 0)) != 2:
		failures.append("unselected revealed marbles should be marked discarded")
	if _count_status(selected_items, "discarded") != 2:
		failures.append("two cards should carry discarded wax status after choice")
	battle.queue_free()
	await process_frame
	if failures.is_empty():
		print("combat marble status overlay smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _count_status(items: Array, status: String) -> int:
	var count := 0
	for item in items:
		if item is Dictionary and str((item as Dictionary).get("status", "")) == status:
			count += 1
	return count

func _button_covering(parent: Control, rect: Rect2) -> Button:
	var center := rect.get_center()
	for child in parent.get_children():
		if child is Button:
			var button := child as Button
			if Rect2(button.position, button.size).has_point(center):
				return button
	return null
