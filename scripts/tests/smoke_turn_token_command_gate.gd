extends SceneTree

const RuntimeBridge := preload("res://scripts/runtime/systems/game_object_runtime_bridge.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var result := RuntimeBridge.apply_hook("turn_start", {
		"cash": 8,
		"applied_effects": []
	}, ["turn_token"])
	_assert_eq(result.get("cash"), 9, "turn token runtime cash")
	_assert_eq(_has_effect(result, "turn_cash_tip"), true, "turn token runtime effect")
	_assert_eq((result.get("runtime_applied_commands", []) as Array).size(), 1, "turn token command count")
	_finish()

func _has_effect(payload: Dictionary, effect_id: String) -> bool:
	for item in payload.get("applied_effects", []):
		if item is Dictionary and str((item as Dictionary).get("effect_id", "")) == effect_id:
			return true
	return false

func _finish() -> void:
	if failures.is_empty():
		print("turn token command gate smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
