extends SceneTree

const LegacySlotFlow := preload("res://scripts/battle/battle_legacy_slot_flow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_slots()
	_check_geometry_and_keys()
	if failures.is_empty():
		print("battle legacy slot flow helper smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_slots() -> void:
	var slots := LegacySlotFlow.empty_slots()
	_assert_eq(slots.has("jackpot"), true, "empty slot has jackpot")
	slots["jackpot"].append("plain")
	_assert_eq(LegacySlotFlow.placed_count(slots), 1, "placed count")
	_assert_eq(LegacySlotFlow.first_filled_slot(slots), "jackpot", "first filled slot")
	var normalized := LegacySlotFlow.normalize_slots({"profit": ["yellow"], "unknown": ["plain"]})
	_assert_eq((normalized.get("profit") as Array)[0], "yellow", "normalized known slot")
	_assert_eq(normalized.has("unknown"), false, "normalized unknown slot")
	_assert_eq(LegacySlotFlow.spread_slot_for_marble("jackpot", 1, 3) != "jackpot", true, "spread slot changes second marble")

func _check_geometry_and_keys() -> void:
	var center: Vector2 = LegacySlotFlow.slot_center("jackpot")
	_assert_eq(LegacySlotFlow.slot_at(center), "jackpot", "slot at center")
	var event := InputEventKey.new()
	event.keycode = KEY_5
	event.physical_keycode = KEY_5
	_assert_eq(LegacySlotFlow.slot_id_for_key(event), "jackpot", "slot key mapping")

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))

