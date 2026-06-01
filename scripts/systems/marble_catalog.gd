class_name MarbleCatalog
extends RefCounted

const PLAIN := "plain"
const HEAVY := "heavy"
const LEECH := "leech"
const GUARD := "guard"
const PIERCE := "pierce"
const GAMBLE := "gamble"
const STABLE := "stable"
const POISON := "poison"
const CRACKED := "cracked"

const TYPE_ORDER: Array[String] = [
	PLAIN,
	HEAVY,
	LEECH,
	GUARD,
	PIERCE,
	GAMBLE,
	STABLE,
	POISON,
	CRACKED
]

const STARTING_DECK: Array[String] = [
	PLAIN,
	PLAIN,
	PLAIN,
	HEAVY,
	LEECH,
	GUARD,
	PIERCE,
	GAMBLE,
	CRACKED
]

const MAX_DECK_SIZE := 12
const MIN_DECK_SIZE := 1
const REVEAL_COUNT := 3

const DEFINITIONS := {
	PLAIN: {
		"name": "Plain Marble",
		"short_name": "Plain",
		"role": "Reliable baseline",
		"effect": "Damage x1.25.",
		"asset_key": "marble_plain_v2",
		"damage_multiplier": 1.25
	},
	HEAVY: {
		"name": "Heavy Marble",
		"short_name": "Heavy",
		"role": "High output, reduced control",
		"effect": "Damage x1.60. Go disabled.",
		"asset_key": "marble_heavy",
		"damage_multiplier": 1.60,
		"disable_go": true
	},
	LEECH: {
		"name": "Leech Marble",
		"short_name": "Leech",
		"role": "Sustain",
		"effect": "Damage x0.75. Heal 25% dealt.",
		"asset_key": "marble_leech",
		"damage_multiplier": 0.75,
		"heal_damage_ratio": 0.25
	},
	GUARD: {
		"name": "Guard Marble",
		"short_name": "Guard",
		"role": "Defense conversion",
		"effect": "Damage x0.65. Gain 4 guard.",
		"asset_key": "marble_guard_v2",
		"damage_multiplier": 0.65,
		"guard_gain": 4
	},
	PIERCE: {
		"name": "Pierce Marble",
		"short_name": "Pierce",
		"role": "Counter armored enemies",
		"effect": "Damage x0.85. Add 3 flat damage.",
		"asset_key": "marble_pierce",
		"damage_multiplier": 0.85,
		"flat_damage_bonus": 3
	},
	GAMBLE: {
		"name": "Gamble Marble",
		"short_name": "Gamble",
		"role": "Big result chasing",
		"effect": "Big/Jackpot x1.80, otherwise x0.70.",
		"asset_key": "marble_gamble",
		"big_damage_multiplier": 1.80,
		"miss_damage_multiplier": 0.70
	},
	STABLE: {
		"name": "Stable Marble",
		"short_name": "Stable",
		"role": "Variance control",
		"effect": "Bust becomes Half. Jackpot caps to Big. Damage x0.92.",
		"asset_key": "marble_stable",
		"damage_multiplier": 0.92,
		"floor_roulette_multiplier": 0.5,
		"cap_roulette_multiplier": 1.5
	},
	POISON: {
		"name": "Poison Marble",
		"short_name": "Poison",
		"role": "Delayed damage",
		"effect": "Damage x0.55. Add +2 enemy damage pressure.",
		"asset_key": "marble_poison",
		"damage_multiplier": 0.55,
		"enemy_damage_delta": 2
	},
	CRACKED: {
		"name": "Cracked Marble",
		"short_name": "Cracked",
		"role": "Weak dump target",
		"effect": "Damage x0.60. Dice 1-2 grants 2 guard.",
		"asset_key": "marble_cracked",
		"damage_multiplier": 0.60,
		"low_die_guard": 2
	}
}

static func type_ids() -> Array[String]:
	return TYPE_ORDER.duplicate()

static func starting_deck_ids() -> Array[String]:
	return STARTING_DECK.duplicate()

static func is_valid(id: String) -> bool:
	return DEFINITIONS.has(id)

static func normalize_id(id: String) -> String:
	return id if is_valid(id) else PLAIN

static func definition(id: String) -> Dictionary:
	return (DEFINITIONS.get(normalize_id(id), DEFINITIONS[PLAIN]) as Dictionary).duplicate(true)

static func display_name(id: String) -> String:
	return str(definition(id).get("name", id.capitalize()))

static func short_name(id: String) -> String:
	return str(definition(id).get("short_name", display_name(id)))

static func effect_text(id: String) -> String:
	return str(definition(id).get("effect", ""))

static func role_text(id: String) -> String:
	return str(definition(id).get("role", ""))

static func asset_key(id: String) -> String:
	return str(definition(id).get("asset_key", "marble_plain_v2"))

static func instance_from_id(instance_id: String, marble_id: String, source: String = "deck", is_temporary: bool = false) -> Dictionary:
	var id := normalize_id(marble_id)
	return {
		"instance_id": instance_id,
		"marble_id": id,
		"is_temporary": is_temporary,
		"source": source,
		"name": display_name(id),
		"short_name": short_name(id),
		"role": role_text(id),
		"effect": effect_text(id),
		"asset_key": asset_key(id)
	}
