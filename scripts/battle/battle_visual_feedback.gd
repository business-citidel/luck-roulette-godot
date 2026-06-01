class_name BattleVisualFeedback
extends RefCounted

const FeedbackEventMapper := preload("res://scripts/systems/feedback_event_mapper.gd")

static func events_from_effects(applied_effects: Array, context: String) -> Array[Dictionary]:
	return FeedbackEventMapper.map_effects(applied_effects, context)

static func triggered_relic_ids(events: Array) -> Array[String]:
	var ids: Array[String] = []
	for event in events:
		if not event is Dictionary:
			continue
		if str(event.get("type", "")) != "relic":
			continue
		var relic_id := str(event.get("relic_id", event.get("source_id", "")))
		if relic_id != "" and not ids.has(relic_id):
			ids.append(relic_id)
	return ids

static func cue_patch(event: Dictionary) -> Dictionary:
	var target := str(event.get("target", "table"))
	var intensity := float(event.get("intensity", 1.0))
	match target:
		"dice":
			return {
				"dice_roll_fx": 0.55 * intensity,
				"table_pulse": 0.35 * intensity
			}
		"roulette":
			return {
				"wheel_tick_flash": 0.75 * intensity,
				"wheel_pointer_kick": 0.55 * intensity,
				"table_pulse": 0.3 * intensity
			}
		"cash":
			return {
				"table_hit_flash": 0.35 * intensity,
				"coin_burst": 8,
				"coin_burst_requires_cash": true
			}
		"bust":
			return {
				"table_hit_flash": 0.75 * intensity,
				"player_flash": 0.45 * intensity
			}
		"enemy":
			return {
				"opponent_reaction": 0.6 * intensity,
				"enemy_flash": 0.35 * intensity
			}
		_:
			return {
				"table_pulse": 0.25 * intensity
			}

static func audio_cue(event: Dictionary) -> Dictionary:
	var audio_key := str(event.get("audio_key", ""))
	if audio_key == "":
		return {}
	return {
		"key": audio_key,
		"pitch": 0.92 + 0.08 * float(event.get("intensity", 1.0)),
		"volume_db": -10.0
	}

static func combat_result_cue(outcome: Dictionary) -> Dictionary:
	var damage := int(outcome.get("damage", 0))
	var bust_delta := int(outcome.get("bust_delta", 0))
	var patch := {
		"banner_text": str(outcome.get("banner", "RESULT")),
		"message": str(outcome.get("message", "")),
		"audio_cues": [],
		"coin_burst": 0
	}
	var audio_cues: Array[Dictionary] = []
	if bust_delta > 0:
		patch["player_flash"] = 1.0
		patch["table_hit_flash"] = 1.0
		patch["opponent_reaction"] = 1.0
		patch["opponent_mood"] = "smirk"
		audio_cues.append({"key": "table_hit", "pitch": 0.7, "volume_db": -4.0})
	if damage > 0:
		patch["enemy_flash"] = 1.0
		patch["table_hit_flash"] = 1.0
		patch["opponent_reaction"] = 1.0
		patch["opponent_mood"] = "hit"
		patch["coin_burst"] = damage
		audio_cues.append({"key": "coin_spill", "pitch": 1.0, "volume_db": -5.0})
		audio_cues.append({"key": "table_hit", "pitch": 0.85, "volume_db": -7.0})
	patch["audio_cues"] = audio_cues
	return patch
