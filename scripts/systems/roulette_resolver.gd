class_name RouletteResolver
extends RefCounted

const RouletteSlotCatalog := preload("res://scripts/systems/roulette_slot_catalog.gd")

static func weights(placed_slots: Dictionary) -> Dictionary:
	# Marble placement boosts a slot only if the roulette lands there. It does
	# not change the probability table.
	var _ignored_slots: Dictionary = placed_slots
	var result: Dictionary = {
		"bust": 18.0,
		"safe": 24.0,
		"profit": 24.0,
		"overdrive": 16.0,
		"jackpot": 10.0
	}
	for id in RouletteSlotCatalog.slot_ids():
		result[id] = max(2.0, float(result[id]))
	return result

static func weighted_pick(placed_slots: Dictionary, rng: RandomNumberGenerator) -> String:
	var result_weights: Dictionary = weights(placed_slots)
	var total: float = 0.0
	for id in RouletteSlotCatalog.slot_ids():
		total += float(result_weights[id])
	var roll: float = rng.randf() * total
	var cursor: float = 0.0
	for id in RouletteSlotCatalog.slot_ids():
		cursor += float(result_weights[id])
		if roll <= cursor:
			return id
	return RouletteSlotCatalog.fallback_id()

static func slot_percent(id: String, placed_slots: Dictionary) -> int:
	var result_weights: Dictionary = weights(placed_slots)
	var total: float = 0.0
	for slot in RouletteSlotCatalog.slot_ids():
		total += float(result_weights[slot])
	if total <= 0.0:
		return 0
	return int(round(float(result_weights.get(id, result_weights[RouletteSlotCatalog.fallback_id()])) / total * 100.0))

static func slot_ids() -> Array[String]:
	return RouletteSlotCatalog.slot_ids()
