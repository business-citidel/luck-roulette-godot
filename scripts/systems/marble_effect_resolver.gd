class_name MarbleEffectResolver
extends RefCounted

const MarbleCatalog := preload("res://scripts/systems/marble_catalog.gd")

static func apply_before_spin(payload: Dictionary) -> Dictionary:
	var result := payload.duplicate(true)
	var marble_id := _selected_marble_id(result)
	if marble_id == "":
		return result
	var definition := MarbleCatalog.definition(marble_id)
	if bool(definition.get("disable_go", false)):
		result["numeric_go_per_turn_cap"] = 0
		_append_effect(result, marble_id, "go_disabled")
	return result

static func apply_resolution_payload(payload: Dictionary) -> Dictionary:
	var result := payload.duplicate(true)
	var marble_id := _selected_marble_id(result)
	if marble_id == "":
		return result
	var definition := MarbleCatalog.definition(marble_id)
	_apply_roulette_floor_and_cap(result, definition, marble_id)
	var multiplier := _damage_multiplier_for(result, definition)
	var current := float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0)))
	var next: float = max(0.0, current * multiplier)
	result["damage_multiplier"] = next
	result["payout_multiplier"] = next
	result["selected_marble_damage_multiplier"] = multiplier
	if int(definition.get("flat_damage_bonus", 0)) != 0:
		result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + int(definition.get("flat_damage_bonus", 0))
	if int(definition.get("guard_gain", 0)) != 0:
		result["player_block"] = int(result.get("player_block", 0)) + int(definition.get("guard_gain", 0))
	if int(definition.get("enemy_damage_delta", 0)) != 0:
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) + int(definition.get("enemy_damage_delta", 0))
	if int(definition.get("low_die_guard", 0)) != 0 and _has_low_die(result):
		result["player_block"] = int(result.get("player_block", 0)) + int(definition.get("low_die_guard", 0))
		_append_effect(result, marble_id, "low_die_guard")
	_append_effect(result, marble_id, "damage_multiplier")
	return result

static func apply_outcome(outcome: Dictionary) -> Dictionary:
	var result := outcome.duplicate(true)
	var marble_id := _selected_marble_id(result)
	if marble_id == "":
		return result
	var definition := MarbleCatalog.definition(marble_id)
	var heal_ratio := float(definition.get("heal_damage_ratio", 0.0))
	if heal_ratio > 0.0:
		var healed := int(floor(float(max(0, int(result.get("damage", 0)))) * heal_ratio))
		if healed > 0:
			var max_hp := int(result.get("player_max_hp", result.get("player_hp", 0)))
			result["player_hp"] = min(max_hp, int(result.get("player_hp", 0)) + healed)
			result["selected_marble_heal"] = healed
			_append_effect(result, marble_id, "heal")
	return result

static func _selected_marble_id(payload: Dictionary) -> String:
	if payload.has("selected_marble_id"):
		return MarbleCatalog.normalize_id(str(payload.get("selected_marble_id", "")))
	var selected: Variant = payload.get("selected_marble", {})
	if selected is Dictionary:
		return MarbleCatalog.normalize_id(str((selected as Dictionary).get("marble_id", "")))
	return ""

static func _damage_multiplier_for(payload: Dictionary, definition: Dictionary) -> float:
	var roulette := float(payload.get("roulette_multiplier", 1.0))
	if definition.has("big_damage_multiplier") or definition.has("miss_damage_multiplier"):
		return float(definition.get("big_damage_multiplier", 1.0)) if roulette >= 1.5 else float(definition.get("miss_damage_multiplier", 1.0))
	return float(definition.get("damage_multiplier", 1.0))

static func _apply_roulette_floor_and_cap(payload: Dictionary, definition: Dictionary, marble_id: String) -> void:
	if not definition.has("floor_roulette_multiplier") and not definition.has("cap_roulette_multiplier"):
		return
	var roulette := float(payload.get("roulette_multiplier", 1.0))
	var adjusted := roulette
	if definition.has("floor_roulette_multiplier"):
		adjusted = max(adjusted, float(definition.get("floor_roulette_multiplier", adjusted)))
	if definition.has("cap_roulette_multiplier"):
		adjusted = min(adjusted, float(definition.get("cap_roulette_multiplier", adjusted)))
	if abs(adjusted - roulette) < 0.001:
		return
	var wager := float(payload.get("wager_multiplier", 1.0))
	payload["roulette_multiplier"] = adjusted
	payload["damage_multiplier"] = adjusted * wager
	payload["payout_multiplier"] = adjusted * wager
	_append_effect(payload, marble_id, "roulette_adjust")

static func _has_low_die(payload: Dictionary) -> bool:
	var dice_values: Array = payload.get("dice_values", [])
	for value in dice_values:
		if int(value) <= 2:
			return true
	return false

static func _append_effect(payload: Dictionary, marble_id: String, effect_id: String) -> void:
	var effects: Array = payload.get("applied_effects", [])
	effects.append({
		"source": "marble",
		"marble_id": marble_id,
		"effect_id": effect_id
	})
	payload["applied_effects"] = effects
