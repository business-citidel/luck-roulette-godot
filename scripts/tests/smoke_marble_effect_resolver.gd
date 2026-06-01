extends SceneTree

const MarbleEffectResolver := preload("res://scripts/systems/marble_effect_resolver.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_plain()
	_check_heavy()
	_check_cracked()
	_finish()

func _base_payload(marble_id: String) -> Dictionary:
	return {
		"combat_core": "numeric_roulette",
		"attack_base": 10,
		"damage_multiplier": 1.0,
		"payout_multiplier": 1.0,
		"roulette_multiplier": 1.0,
		"wager_multiplier": 1.0,
		"dice_values": [2, 5],
		"player_block": 0,
		"selected_marble_id": marble_id,
		"selected_marble": {"marble_id": marble_id},
		"applied_effects": []
	}

func _check_plain() -> void:
	var payload := MarbleEffectResolver.apply_resolution_payload(_base_payload("plain"))
	_assert_close(float(payload.get("damage_multiplier", 0.0)), 1.25, "plain damage multiplier")

func _check_heavy() -> void:
	var before := MarbleEffectResolver.apply_before_spin(_base_payload("heavy"))
	_assert_eq(before.get("numeric_go_per_turn_cap"), 0, "heavy disables Go")
	var payload := MarbleEffectResolver.apply_resolution_payload(_base_payload("heavy"))
	_assert_close(float(payload.get("damage_multiplier", 0.0)), 1.60, "heavy damage multiplier")

func _check_cracked() -> void:
	var payload := MarbleEffectResolver.apply_resolution_payload(_base_payload("cracked"))
	_assert_close(float(payload.get("damage_multiplier", 0.0)), 0.60, "cracked damage multiplier")
	_assert_eq(payload.get("player_block"), 2, "cracked low die guard")

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))

func _assert_close(actual: float, expected: float, label: String) -> void:
	if abs(actual - expected) > 0.001:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))

func _finish() -> void:
	if failures.is_empty():
		print("marble effect resolver smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
