class_name BattleMarbleChoiceFlow
extends RefCounted

const MarbleCatalog := preload("res://scripts/systems/marble_catalog.gd")

static func enter_choice_state(deck_state: Resource, rng: RandomNumberGenerator, attack_base: int) -> Dictionary:
	var revealed: Array[Dictionary] = deck_state.call("reveal_next", rng, MarbleCatalog.REVEAL_COUNT)
	return {
		"phase": "marble_choice",
		"revealed_marbles": revealed,
		"selected_marble": {},
		"banner_text": "MARBLE CHOICE",
		"banner_alpha": 1.0,
		"message": "Choose one revealed marble for attack " + str(attack_base) + "."
	}

static func choose_state(deck_state: Resource, index: int) -> Dictionary:
	var selected: Dictionary = deck_state.call("choose_revealed", index)
	if selected.is_empty():
		return {"valid": false}
	return {
		"valid": true,
		"phase": "wager",
		"revealed_marbles": [],
		"selected_marble": selected,
		"selected_marble_id": str(selected.get("marble_id", "")),
		"wager_marbles_available": 0,
		"wager_marbles_committed": 0,
		"banner_text": str(selected.get("short_name", selected.get("marble_id", ""))).to_upper() + " READY",
		"banner_alpha": 1.0,
		"message": str(selected.get("name", "Marble")) + " locked. Spin the roulette."
	}
