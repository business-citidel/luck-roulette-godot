extends SceneTree

const BattleVisualFeedback := preload("res://scripts/battle/battle_visual_feedback.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_effect_event_and_cue()
	_check_triggered_relic_ids()
	_check_result_cue()
	if failures.is_empty():
		print("battle visual feedback smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_effect_event_and_cue() -> void:
	var events := BattleVisualFeedback.events_from_effects([
		{"effect_id": "roulette_respin_plus_one", "relic_id": "second_chance", "name": "Second Chance"}
	], "roulette_before_spin")
	_assert_eq(events.is_empty(), false, "mapped effect event")
	var patch := BattleVisualFeedback.cue_patch(events[0])
	_assert_eq(float(patch.get("wheel_tick_flash", 0.0)) > 0.0, true, "roulette cue flash")
	var audio := BattleVisualFeedback.audio_cue(events[0])
	_assert_eq(audio.get("key"), "wheel_tick", "roulette audio cue")

func _check_triggered_relic_ids() -> void:
	var ids := BattleVisualFeedback.triggered_relic_ids([
		{"type": "relic", "relic_id": "a"},
		{"type": "relic", "relic_id": "a"},
		{"type": "enemy", "source_id": "b"}
	])
	_assert_eq(ids, ["a"], "unique relic ids")

func _check_result_cue() -> void:
	var patch := BattleVisualFeedback.combat_result_cue({
		"damage": 7,
		"bust_delta": 0,
		"banner": "HIT 7",
		"message": "Hit"
	})
	_assert_eq(patch.get("opponent_mood"), "hit", "damage opponent mood")
	_assert_eq(patch.get("coin_burst"), 7, "damage coin burst")
	_assert_eq((patch.get("audio_cues", []) as Array).size(), 2, "damage audio cues")

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
