extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const GoStopButtonDriver := preload("res://scripts/tests/support/go_stop_button_driver.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _assert_roulette_upgrade_applies_without_wager()
	await _assert_cell_upgrade_changes_forced_cell()
	await _assert_wager_polish_requires_committed_wager()
	if failures.is_empty():
		print("numeric run upgrade contract smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _assert_roulette_upgrade_applies_without_wager() -> void:
	var combat := await _configured_combat({
		"roulette_bonus": 0.2,
		"marble_bonus": 1.0
	}, 50)
	if not _combat_ready(combat, "roulette upgrade"):
		return
	combat._finish_dice_roll_with_values([4])
	combat._take_marbles()
	await process_frame
	_press_button_by_text(combat, "Stop", "roulette upgrade spin")
	await _wait_for_phase(combat, "intervene", 180)
	var preview := int(combat._numeric_preview_damage())
	if preview != 5:
		failures.append("roulette_bonus should raise no-wager x1 damage from 4 to 5, got " + str(preview))
	_press_button_by_text(combat, "Stop", "roulette upgrade resolve")
	await process_frame
	if int(combat.get("enemy_hp")) != 45:
		failures.append("roulette_bonus no-wager resolve should deal 5 damage, enemy hp " + str(combat.get("enemy_hp")))
	combat.queue_free()
	await process_frame

func _assert_cell_upgrade_changes_forced_cell() -> void:
	var combat := await _configured_combat({
		"numeric_roulette_cell_bonus_1": 0.5
	}, 50, [1])
	if not _combat_ready(combat, "roulette cell upgrade"):
		return
	combat._finish_dice_roll_with_values([4])
	combat._take_marbles()
	await process_frame
	_press_button_by_text(combat, "Stop", "cell upgrade spin")
	await _wait_for_phase(combat, "intervene", 180)
	if abs(float(combat.get("numeric_roulette_multiplier")) - 1.0) > 0.001:
		failures.append("cell upgrade should raise forced x0.5 cell to x1, got " + str(combat.get("numeric_roulette_multiplier")))
	if int(combat._numeric_preview_damage()) != 4:
		failures.append("cell upgrade preview should use raised cell, got " + str(combat._numeric_preview_damage()))
	combat.queue_free()
	await process_frame

func _assert_wager_polish_requires_committed_wager() -> void:
	var no_wager := await _configured_combat({
		"marble_bonus": 1.0
	}, 50)
	if not _combat_ready(no_wager, "no-wager marble polish"):
		return
	no_wager._finish_dice_roll_with_values([4])
	no_wager._take_marbles()
	await process_frame
	_press_button_by_text(no_wager, "Stop", "no-wager marble polish spin")
	await _wait_for_phase(no_wager, "intervene", 180)
	if int(no_wager._numeric_preview_damage()) != 4:
		failures.append("marble_bonus should not change damage without a committed wager")
	no_wager.queue_free()
	await process_frame

	var wagered := await _configured_combat({
		"marble_bonus": 1.0
	}, 50)
	if not _combat_ready(wagered, "wagered marble polish"):
		return
	wagered._finish_dice_roll_with_values([4])
	wagered._take_marbles()
	await process_frame
	wagered.set("wager_marbles_available", 2)
	_press_button_by_text(wagered, "Go", "wager polish first Go")
	await process_frame
	_press_button_by_text(wagered, "Go", "wager polish second Go")
	await process_frame
	_press_button_by_text(wagered, "Stop", "wager polish Stop")
	await _wait_for_phase(wagered, "intervene", 180)
	var preview := int(wagered._numeric_preview_damage())
	if preview != 7:
		failures.append("marble_bonus should add wager polish for 2 committed marbles, got " + str(preview))
	_press_button_by_text(wagered, "Stop", "wager polish resolve")
	await process_frame
	if int(wagered.get("enemy_hp")) != 43:
		failures.append("wager polish resolve should deal 7 damage, enemy hp " + str(wagered.get("enemy_hp")))
	wagered.queue_free()
	await process_frame

func _configured_combat(run_upgrades: Dictionary, enemy_hp: int, forced_indices: Array[int] = [4]) -> Control:
	var combat: Control = BattleScene.instantiate()
	root.add_child(combat)
	await process_frame
	if not combat.has_method("configure_encounter"):
		failures.append("BattleScene script did not load for numeric run upgrade contract")
		return combat
	combat.configure_encounter({
		"combat_core": "numeric_roulette",
		"numeric_forced_indices": forced_indices,
		"combat_cash": 18,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": enemy_hp,
		"enemy_max_hp": enemy_hp,
		"dice_rule_id": "single_attack_die",
		"monster_id": "debt_collector",
		"monster_name": "Debt Collector",
		"move_pattern": ["hp_strike"],
		"run_upgrades": run_upgrades
	})
	await process_frame
	return combat

func _combat_ready(combat: Control, context: String) -> bool:
	if combat == null:
		failures.append(context + " combat did not instantiate")
		return false
	if not combat.has_method("_finish_dice_roll_with_values") or not combat.has_method("_resolve_numeric_pending"):
		failures.append(context + " combat missing BattleScene methods")
		combat.queue_free()
		return false
	return true

func _wait_for_phase(combat: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if str(combat.get("phase")) == expected:
			return
		await process_frame

func _button_by_text(combat: Control, text: String) -> Button:
	return GoStopButtonDriver.button_by_text(combat, text)

func _press_button_by_text(combat: Control, text: String, context: String) -> void:
	var result := GoStopButtonDriver.press_button_by_text(combat, text)
	if result == "missing":
		failures.append(context + " should expose " + text + " button")
		return
	if result == "disabled":
		failures.append(context + " should expose enabled " + text + " button")
