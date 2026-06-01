extends SceneTree

const RuntimeBridge := preload("res://scripts/runtime/systems/game_object_runtime_bridge.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var result := RuntimeBridge.apply_hook("potion_used", {
		"player_block": 0,
		"active_potion_ids": ["guard_potion"],
		"consumed_potion_ids": [],
		"applied_effects": []
	}, ["guard_potion"], {"potion_id": "guard_potion"})
	_assert_eq(result.get("player_block"), 10, "guard potion runtime block")
	_assert_eq((result.get("active_potion_ids", []) as Array).has("guard_potion"), false, "guard potion runtime removed active")
	_assert_eq((result.get("consumed_potion_ids", []) as Array).has("guard_potion"), true, "guard potion runtime consumed")
	_assert_eq(_has_effect(result, "guard_potion_block"), true, "guard potion runtime effect")
	_assert_eq((result.get("runtime_applied_commands", []) as Array).size(), 2, "guard potion command count")
	_finish()

func _has_effect(payload: Dictionary, effect_id: String) -> bool:
	for item in payload.get("applied_effects", []):
		if item is Dictionary and str((item as Dictionary).get("effect_id", "")) == effect_id:
			return true
	return false

func _finish() -> void:
	if failures.is_empty():
		print("guard potion command gate smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
