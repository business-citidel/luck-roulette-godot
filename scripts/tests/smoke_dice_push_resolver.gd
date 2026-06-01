extends SceneTree

const DicePushResolver := preload("res://scripts/systems/dice_push_resolver.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	_assert_push(2, 8, 0, true, false, 6, false, failures)
	_assert_push(6, 7, 0, true, false, 5, false, failures)
	_assert_push(8, 10, 0, true, false, 11, false, failures)
	_assert_push(11, 12, 0, true, false, 24, true, failures)
	_assert_push(11, 7, 0, false, true, 3, true, failures)
	if DicePushResolver.can_push(12, 0):
		failures.append("12 should be locked and unavailable for push")
	var fourth: Dictionary = DicePushResolver.resolve_push(8, 12, 3)
	if bool(fourth.get("accepted", true)):
		failures.append("fourth push should not be accepted")
	if not bool(fourth.get("locked", false)):
		failures.append("unavailable fourth push should report locked")
	if failures.is_empty():
		print("dice push resolver smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _assert_push(current_total: int, new_total: int, push_count: int, success: bool, failed: bool, attack_value: int, locked: bool, failures: Array[String]) -> void:
	var result: Dictionary = DicePushResolver.resolve_push(current_total, new_total, push_count)
	var label := str(current_total) + " -> " + str(new_total)
	if bool(result.get("success", false)) != success:
		failures.append(label + " success mismatch")
	if bool(result.get("failed", false)) != failed:
		failures.append(label + " failed mismatch")
	if int(result.get("attack_value", -1)) != attack_value:
		failures.append(label + " attack value expected " + str(attack_value) + " got " + str(result.get("attack_value", null)))
	if bool(result.get("locked", false)) != locked:
		failures.append(label + " locked mismatch")
