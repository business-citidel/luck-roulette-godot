extends SceneTree

const FeedbackEventMapper := preload("res://scripts/systems/feedback_event_mapper.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RelicEffectResolver := preload("res://scripts/systems/relic_effect_resolver.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_catalog()
	_check_turn_start_effect()
	_check_feedback_mapping()

	if failures.is_empty():
		print("turn token relic smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_catalog() -> void:
	if not RelicCatalog.has_relic("turn_token"):
		failures.append("turn_token missing from relic catalog")
	if not RelicCatalog.all_ids().has("turn_token"):
		failures.append("turn_token missing from reward order")
	if not RelicCatalog.hooks("turn_token").has("turn_start"):
		failures.append("turn_token does not declare turn_start hook")

func _check_turn_start_effect() -> void:
	var result: Dictionary = RelicEffectResolver.apply("turn_start", {
		"turn": 2,
		"cash": 8,
		"player_hp": 30,
		"enemy_hp": 12,
		"applied_effects": []
	}, ["turn_token"])
	if int(result.get("cash", 0)) != 9:
		failures.append("turn_token did not add deterministic cash")
	if not _has_effect(result, "turn_cash_tip"):
		failures.append("turn_token did not record turn_cash_tip effect")

func _check_feedback_mapping() -> void:
	var events: Array[Dictionary] = FeedbackEventMapper.map_effects([{
		"relic_id": "turn_token",
		"effect_id": "turn_cash_tip",
		"name": "Turn Token"
	}], "turn_start")
	if events.size() != 1:
		failures.append("turn_token effect did not map to feedback event")
		return
	if str(events[0].get("target", "")) != "cash":
		failures.append("turn_token feedback target mismatch")
	if str(events[0].get("audio_key", "")) != "coin_spill":
		failures.append("turn_token feedback audio mismatch")
	if str(events[0].get("context", "")) != "turn_start":
		failures.append("turn_token feedback context mismatch")

func _has_effect(payload: Dictionary, effect_id: String) -> bool:
	for item in payload.get("applied_effects", []):
		if item is Dictionary and str((item as Dictionary).get("effect_id", "")) == effect_id:
			return true
	return false
