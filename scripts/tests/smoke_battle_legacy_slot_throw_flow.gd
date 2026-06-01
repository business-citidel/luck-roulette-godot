extends SceneTree

const LegacySlotFlow := preload("res://scripts/battle/battle_legacy_slot_flow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_placement_patch()
	_check_particles()
	_check_advance_settle_and_finish()
	if failures.is_empty():
		print("battle legacy slot throw flow smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_placement_patch() -> void:
	var patch := LegacySlotFlow.placement_patch("jackpot", ["plain", "plain"])
	_assert_eq(patch.get("valid"), true, "placement valid")
	_assert_eq(patch.get("target_slot"), "jackpot", "target slot")
	_assert_eq((patch.get("colors", []) as Array).size(), 2, "colors preserved")
	_assert_eq((patch.get("marbles", ["x"]) as Array).is_empty(), true, "marbles cleared")
	_assert_eq(patch.get("slot_feedback_alpha"), 1.0, "slot feedback pulse")

func _check_particles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var particles := LegacySlotFlow.particles_for_slot(["plain", "plain", "plain"], "safe", Vector2(100, 100), 1.0, rng)
	_assert_eq(particles.size(), 3, "particle count")
	_assert_eq(str(particles[0].get("slot")), "safe", "first particle target slot")
	_assert_eq(particles[0].has("target"), true, "particle target exists")
	_assert_eq(float(particles[1].get("t")) < 0.0, true, "particle stagger")
	var random_particles := LegacySlotFlow.random_throw_particles(["plain", "plain"], Vector2(80, 90), 1.2, rng)
	_assert_eq(random_particles.size(), 2, "random particle count")
	_assert_eq(random_particles[0].has("slot"), true, "random particle slot exists")

func _check_advance_settle_and_finish() -> void:
	var thrown := [{
		"color": "plain",
		"slot": "safe",
		"start": Vector2(0, 0),
		"target": Vector2(10, 10),
		"pos": Vector2.ZERO,
		"t": 0.0,
		"duration": 0.1,
		"arc": 10.0,
		"settled": false
	}]
	var advanced := LegacySlotFlow.advance_thrown_marbles(thrown, 0.2)
	_assert_eq((advanced.get("thrown_marbles", []) as Array).is_empty(), true, "finished marble removed")
	_assert_eq((advanced.get("settled", []) as Array).size(), 1, "settled marble emitted")
	_assert_eq(advanced.get("finished"), true, "finished flag")
	var patch := LegacySlotFlow.settle_patch((advanced.get("settled", []) as Array)[0], {})
	_assert_eq((patch.get("placed_slots", {}) as Dictionary).get("safe", []).size(), 1, "settle placed slot")
	_assert_eq(patch.get("marble_feedback_color_id"), "plain", "settle feedback color")
	var finish := LegacySlotFlow.finish_setup_patch(patch.get("placed_slots", {}))
	_assert_eq(finish.get("valid"), true, "finish valid")
	_assert_eq(finish.get("spin_ready_flash"), 1.0, "spin ready flash")

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
