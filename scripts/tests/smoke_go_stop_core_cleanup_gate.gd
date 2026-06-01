extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_check_absent("res://scripts/battle/battle_scene.gd", [
		"_wager_all_in",
		"selected_slot_id",
		"marble_place"
	])
	_check_absent("res://scripts/ui/ui_text.gd", [
		"battle.action.wager_",
		"Bet Less",
		"Bet More",
		"All In"
	])
	_check_absent("res://scripts/ui/table_layer.gd", [
		"Bet committed"
	])
	_check_contains("res://scripts/tests/sim_balance_metrics.gd", [
		"LUCK_ALLOW_LEGACY_SLOT_SIM",
		"legacy slot-marble simulator"
	])
	_check_contains("res://scripts/tests/support/legacy_slot_playtest_guard.gd", [
		"LUCK_ALLOW_LEGACY_SLOT_PLAYTEST",
		"legacy slot-marble visual playtest"
	])
	_check_contains("res://scripts/tests/playtest_combat_input_object_pass.gd", [
		"LegacySlotPlaytestGuard",
		"\"combat_core\": \"slot_marble\""
	])
	_check_contains("res://scripts/tests/playtest_combat_fast_command_flow.gd", [
		"LegacySlotPlaytestGuard",
		"\"combat_core\": \"slot_marble\""
	])
	_check_contains("res://scripts/tests/playtest_full_ritual_flow.gd", [
		"LegacySlotPlaytestGuard",
		"\"slot_marble\""
	])
	_check_contains("res://scripts/tests/playtest_end_to_end_structure.gd", [
		"LegacySlotPlaytestGuard",
		"\"slot_marble\""
	])
	_check_absent("res://scripts/tests/smoke_dice_push_battle_flow.gd", [
		"dice_push_pending_total",
		"dice_roll_is_push"
	])
	_check_absent("res://scripts/tests/smoke_numeric_relic_battle_flow.gd", [
		"_numeric_go(",
		"_resolve_numeric_pending(",
		"_adjust_wager(",
		"_open_numeric_roulette_spin("
	])
	_check_contains("res://scripts/tests/sim_numeric_floor1_guard_metrics.gd", [
		"RelicCatalog.SOURCE_RISK",
		"roulette_action",
		"sim_policy_label",
		"decision_count_totals",
		"relic_source_counts_total"
	])
	_check_contains("res://scripts/tests/sim_numeric_floor1_character_metrics.gd", [
		"RelicCatalog.SOURCE_RISK",
		"roulette_action",
		"sim_policy_label",
		"decision_count_totals",
		"relic_source_counts_total"
	])

	if failures.is_empty():
		print("go/stop core cleanup gate smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_absent(path: String, needles: Array[String]) -> void:
	var text := _read(path)
	for needle in needles:
		if text.contains(needle):
			failures.append(path + " should not contain " + needle)

func _check_contains(path: String, needles: Array[String]) -> void:
	var text := _read(path)
	for needle in needles:
		if not text.contains(needle):
			failures.append(path + " should contain " + needle)

func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		failures.append("missing file " + path)
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("could not read " + path)
		return ""
	var text := file.get_as_text()
	file.close()
	return text
