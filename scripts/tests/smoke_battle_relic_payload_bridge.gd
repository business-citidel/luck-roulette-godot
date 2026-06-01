extends SceneTree

const RelicBridge := preload("res://scripts/battle/battle_relic_payload_bridge.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_dice_result_bridge()
	_check_resolution_bridge()
	_check_combat_finish_bridge()
	if failures.is_empty():
		print("battle relic payload bridge smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_dice_result_bridge() -> void:
	var payload := RelicBridge.apply_dice_result({
		"dice_rule_id": "single_attack_die",
		"dice_values": [2],
		"dice": [2],
		"dice_locked": [],
		"rerolls_left": 0,
		"attack_base": 2,
		"applied_effects": []
	}, ["loaded_die"])
	_assert_eq(int(payload.get("attack_base", 0)), 3, "loaded die bridge attack")

func _check_resolution_bridge() -> void:
	var payload := RelicBridge.apply_resolution_before({
		"pending_slot": "profit",
		"placed_slots": {"safe": [], "profit": ["plain"], "jackpot": [], "bust": [], "overdrive": []},
		"cash_delta_bonus": 0,
		"applied_effects": []
	}, ["green_purse"])
	_assert_eq(int(payload.get("cash_delta_bonus", 0)), 4, "green purse bridge cash bonus")

func _check_combat_finish_bridge() -> void:
	var payload := RelicBridge.apply_combat_finish({
		"victory": true,
		"cash": 10,
		"applied_effects": []
	}, [])
	_assert_eq(bool(payload.get("victory", false)), true, "combat finish victory passthrough")

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))

