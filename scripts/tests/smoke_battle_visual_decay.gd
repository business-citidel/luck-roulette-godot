extends SceneTree

const VisualDecay := preload("res://scripts/battle/battle_visual_decay.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_patch_decays_active_fields()
	_check_patch_ignores_inactive_fields()
	if failures.is_empty():
		print("battle visual decay smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_patch_decays_active_fields() -> void:
	var patch := VisualDecay.state_patch({
		"banner_alpha": 1.0,
		"enemy_flash": 0.25,
		"wheel_pointer_kick": 0.1
	}, 0.5)
	_assert_eq(patch.get("dirty"), true, "dirty active fields")
	_assert_eq(float(patch.get("banner_alpha", -1.0)), 0.6, "banner decay")
	_assert_eq(float(patch.get("enemy_flash", -1.0)), 0.0, "enemy clamp")
	_assert_eq(float(patch.get("wheel_pointer_kick", -1.0)), 0.0, "pointer clamp")

func _check_patch_ignores_inactive_fields() -> void:
	var patch := VisualDecay.state_patch({
		"banner_alpha": 0.0,
		"table_pulse": -1.0
	}, 0.25)
	_assert_eq(patch.get("dirty"), false, "inactive clean")
	_assert_eq(patch.has("banner_alpha"), false, "inactive omitted")
	_assert_eq(VisualDecay.decay_fields().has("dice_roll_fx"), true, "field list exported")

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
