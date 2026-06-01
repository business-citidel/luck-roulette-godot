extends SceneTree

const FeedbackEventMapper := preload("res://scripts/systems/feedback_event_mapper.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var relic_events: Array[Dictionary] = FeedbackEventMapper.map_effects([{
		"relic_id": "green_purse",
		"effect_id": "green_payout_multiplier",
		"name": "Green Purse"
	}], "resolution")
	if relic_events.size() != 1:
		failures.append("green relic effect did not map to feedback event")
	elif str(relic_events[0].get("target", "")) != "cash" or str(relic_events[0].get("audio_key", "")) != "coin_spill":
		failures.append("green relic feedback target/audio mismatch")
	elif str(relic_events[0].get("relic_id", "")) != "green_purse" or str(relic_events[0].get("icon_id", "")) != "green_purse":
		failures.append("green relic feedback should carry relic icon pulse metadata")
	elif str(relic_events[0].get("pulse", "")) != "relic":
		failures.append("green relic feedback should request relic pulse")

	var respin_events: Array[Dictionary] = FeedbackEventMapper.map_effects([{
		"relic_id": "second_chance",
		"effect_id": "roulette_respin_plus_one",
		"name": "Second Chance"
	}], "roulette")
	if respin_events.size() != 1:
		failures.append("roulette respin relic effect did not map to feedback event")
	elif str(respin_events[0].get("type", "")) != "relic" or str(respin_events[0].get("target", "")) != "roulette":
		failures.append("roulette respin feedback type/target mismatch")
	elif str(respin_events[0].get("icon_id", "")) != "second_chance":
		failures.append("roulette respin feedback should carry second chance icon id")

	var bust_events: Array[Dictionary] = FeedbackEventMapper.map_effects([{
		"relic_id": "bust_insurance",
		"effect_id": "bust_delta_cancelled",
		"name": "Bust Insurance"
	}], "resolution")
	if bust_events.size() != 1 or str(bust_events[0].get("target", "")) != "bust":
		failures.append("bust feedback did not map to bust target")

	var ignored: Array[Dictionary] = FeedbackEventMapper.map_effects([{
		"effect_id": "unknown_effect",
		"name": "Unknown"
	}], "unknown")
	if not ignored.is_empty():
		failures.append("unknown effect should be ignored safely")

	if failures.is_empty():
		print("feedback mapper smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
