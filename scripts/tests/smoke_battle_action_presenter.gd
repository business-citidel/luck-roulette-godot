extends SceneTree

const ActionPresenter := preload("res://scripts/battle/battle_action_presenter.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_dice_roll_action()
	_check_dice_push_actions()
	_check_wager_actions()
	_check_numeric_intervene_actions()
	_check_potion_menu_actions()
	if failures.is_empty():
		print("battle action presenter smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_dice_roll_action() -> void:
	var presentation := ActionPresenter.build({
		"phase": "dice",
		"dice_rolled": false
	})
	var buttons: Array = presentation.get("buttons", [])
	_assert_eq(buttons.size(), 1, "dice roll button count")
	_assert_eq((buttons[0] as Dictionary).get("method"), "_roll_dice", "dice roll method")
	_assert_eq(presentation.get("potion_entry"), true, "dice roll potion entry")

func _check_dice_push_actions() -> void:
	var presentation := ActionPresenter.build({
		"phase": "dice",
		"dice_rolled": true,
		"is_dice_push_rule": true,
		"can_push_dice": true
	})
	var buttons: Array = presentation.get("buttons", [])
	_assert_eq(buttons.size(), 2, "dice push button count")
	_assert_eq((buttons[0] as Dictionary).get("method"), "_push_dice", "dice push method")
	_assert_eq((buttons[1] as Dictionary).get("method"), "_confirm_dice_result", "dice stop method")

func _check_wager_actions() -> void:
	var presentation := ActionPresenter.build({
		"phase": "wager",
		"can_wager_go": true
	})
	var buttons: Array = presentation.get("buttons", [])
	_assert_eq(buttons.size(), 2, "wager button count")
	_assert_eq((buttons[0] as Dictionary).get("method"), "_adjust_wager", "wager go method")
	_assert_eq(((buttons[0] as Dictionary).get("args", []) as Array)[0], 1, "wager go arg")
	_assert_eq((buttons[1] as Dictionary).get("method"), "_open_numeric_roulette_spin", "wager stop method")

func _check_numeric_intervene_actions() -> void:
	var presentation := ActionPresenter.build({
		"phase": "intervene",
		"is_numeric_core": true,
		"numeric_go_available": false
	})
	var buttons: Array = presentation.get("buttons", [])
	_assert_eq(buttons.size(), 2, "numeric intervention button count")
	_assert_eq((buttons[0] as Dictionary).get("enabled"), false, "numeric go disabled")
	_assert_eq((buttons[1] as Dictionary).get("method"), "_resolve_numeric_pending", "numeric stop method")
	_assert_eq(presentation.get("potion_entry"), true, "numeric intervention potion entry")

func _check_potion_menu_actions() -> void:
	var buttons := ActionPresenter.potion_menu_buttons({
		"active_potion_ids": ["red_recovery", "blue_dice"],
		"potion_enabled": {"red_recovery": true, "blue_dice": false}
	})
	_assert_eq(buttons.size(), 3, "potion menu button count")
	_assert_eq((buttons[0] as Dictionary).get("method"), "_use_potion", "potion use method")
	_assert_eq(((buttons[0] as Dictionary).get("args", []) as Array)[0], "red_recovery", "potion use arg")
	_assert_eq((buttons[0] as Dictionary).get("enabled"), true, "first potion enabled")
	_assert_eq((buttons[1] as Dictionary).get("enabled"), false, "second potion disabled")
	_assert_eq((buttons[2] as Dictionary).get("method"), "_close_potion_menu", "potion back method")
	_assert_eq((buttons[2] as Dictionary).get("primary"), true, "potion back primary")

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
