class_name BattleRelicPayloadBridge
extends RefCounted

const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")

static func apply_dice_result(payload: Dictionary, relic_ids: Array[String]) -> Dictionary:
	return EffectResolver.apply_relic_trigger("dice_result", payload, relic_ids)

static func apply_marble_gain(payload: Dictionary, relic_ids: Array[String]) -> Dictionary:
	return EffectResolver.apply_relic_trigger("marble_gain", payload, relic_ids)

static func apply_roulette_before_spin(payload: Dictionary, relic_ids: Array[String]) -> Dictionary:
	return EffectResolver.apply_relic_trigger("roulette_before_spin", payload, relic_ids)

static func apply_roulette_after_spin(payload: Dictionary, relic_ids: Array[String]) -> Dictionary:
	return EffectResolver.apply_relic_trigger("roulette_after_spin", payload, relic_ids)

static func apply_resolution_before(payload: Dictionary, relic_ids: Array[String]) -> Dictionary:
	return EffectResolver.apply_relic_trigger("resolution_before", payload, relic_ids)

static func apply_resolution_after(outcome: Dictionary, relic_ids: Array[String]) -> Dictionary:
	return EffectResolver.apply_relic_trigger("resolution_after", outcome, relic_ids)

static func apply_turn_start(payload: Dictionary, relic_ids: Array[String]) -> Dictionary:
	return EffectResolver.apply_relic_trigger("turn_start", payload, relic_ids)

static func apply_damage_taken(payload: Dictionary, relic_ids: Array[String]) -> Dictionary:
	return EffectResolver.apply_relic_trigger("damage_taken", payload, relic_ids)

static func apply_combat_finish(result: Dictionary, relic_ids: Array[String]) -> Dictionary:
	if bool(result.get("victory", false)):
		return EffectResolver.apply_relic_trigger("combat_victory", result, relic_ids)
	return EffectResolver.apply_relic_trigger("combat_end", result, relic_ids)

