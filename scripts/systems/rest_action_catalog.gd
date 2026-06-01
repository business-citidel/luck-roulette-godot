class_name RestActionCatalog
extends RefCounted

const UiText := preload("res://scripts/ui/ui_text.gd")

const ACTION_ORDER := [
	"rest_heal",
	"rest_tune",
	"rest_relic"
]

const UPGRADE_ORDER := [
	"upgrade_primary_die",
	"upgrade_secondary_die",
	"upgrade_roulette",
	"upgrade_roulette_cell"
]

const EXCHANGE_ORDER := [
	"ticket_small_heal",
	"ticket_random_potion",
	"ticket_upgrade_voucher",
	"ticket_random_relic"
]

const ACTIONS := {
	"rest_heal": {
		"id": "rest_heal",
		"label_key": "rest.action.heal.label",
		"note_key": "rest.action.heal.note",
		"effect": "+9 HP",
		"station": "healing_bench",
		"result": {
			"accepted": true,
			"choice": "rest_heal",
			"gold_delta": 0,
			"hp_delta": 9,
			"relic_ids": [],
			"next_combat_mods": []
		}
	},
	"rest_tune": {
		"id": "rest_tune",
		"label_key": "rest.action.tune.label",
		"note_key": "rest.action.tune.note",
		"effect_key": "rest.action.tune.effect",
		"station": "tune_bench",
		"opens": "upgrade"
	},
	"rest_relic": {
		"id": "rest_relic",
		"label_key": "rest.action.relic.label",
		"note_key": "rest.action.relic.note",
		"effect_key": "rest.action.relic.effect",
		"station": "relic_bench"
	},
	"upgrade_primary_die": {
		"id": "upgrade_primary_die",
		"label_key": "rest.upgrade.primary.label",
		"note_key": "rest.upgrade.primary.note",
		"effect_key": "rest.upgrade.primary.effect",
		"station": "upgrade_primary_die",
		"result": {
			"accepted": true,
			"choice": "upgrade_primary_die",
			"gold_delta": 0,
			"hp_delta": 0,
			"relic_ids": [],
			"next_combat_mods": [],
			"run_upgrades": {"primary_die_bonus": 1.0}
		}
	},
	"upgrade_secondary_die": {
		"id": "upgrade_secondary_die",
		"label_key": "rest.upgrade.secondary.label",
		"note_key": "rest.upgrade.secondary.note",
		"effect_key": "rest.upgrade.secondary.effect",
		"station": "upgrade_secondary_die",
		"result": {
			"accepted": true,
			"choice": "upgrade_secondary_die",
			"gold_delta": 0,
			"hp_delta": 0,
			"relic_ids": [],
			"next_combat_mods": [],
			"run_upgrades": {"secondary_die_bonus": 1.0}
		}
	},
	"upgrade_roulette": {
		"id": "upgrade_roulette",
		"label_key": "rest.upgrade.roulette.label",
		"note_key": "rest.upgrade.roulette.note",
		"effect_key": "rest.upgrade.roulette.effect",
		"station": "upgrade_roulette",
		"result": {
			"accepted": true,
			"choice": "upgrade_roulette",
			"gold_delta": 0,
			"hp_delta": 0,
			"relic_ids": [],
			"next_combat_mods": [],
			"run_upgrades": {"roulette_bonus": 0.2}
		}
	},
	"upgrade_roulette_cell": {
		"id": "upgrade_roulette_cell",
		"label_key": "rest.upgrade.roulette_cell.label",
		"note_key": "rest.upgrade.roulette_cell.note",
		"effect_key": "rest.upgrade.roulette_cell.effect",
		"station": "upgrade_roulette_cell",
		"result": {
			"accepted": true,
			"choice": "upgrade_roulette_cell",
			"gold_delta": 0,
			"hp_delta": 0,
			"relic_ids": [],
			"next_combat_mods": [],
			"run_upgrades": {}
		}
	},
	"ticket_small_heal": {
		"id": "ticket_small_heal",
		"label_key": "rest.exchange.small_heal.label",
		"note_key": "rest.exchange.small_heal.note",
		"effect_key": "rest.exchange.small_heal.effect",
		"slot_kind": "service",
		"icon_id": "blood_discount",
		"badge_id": "limited",
		"object_texture_id": "exchange_object_heal_vial",
		"price": 2,
		"result": {
			"accepted": true,
			"choice": "ticket_small_heal",
			"gold_delta": 0,
			"hp_delta": 5,
			"contract_tickets_delta": -2,
			"relic_ids": [],
			"next_combat_mods": [],
			"run_upgrades": {},
			"potion_ids": []
		}
	},
	"ticket_random_potion": {
		"id": "ticket_random_potion",
		"label_key": "rest.exchange.random_potion.label",
		"note_key": "rest.exchange.random_potion.note",
		"effect_key": "rest.exchange.random_potion.effect",
		"slot_kind": "service",
		"icon_id": "risk_contract",
		"badge_id": "contract",
		"object_texture_id": "exchange_object_random_potion",
		"price": 2,
		"result": {
			"accepted": true,
			"choice": "ticket_random_potion",
			"gold_delta": 0,
			"hp_delta": 0,
			"contract_tickets_delta": -2,
			"relic_ids": [],
			"next_combat_mods": [],
			"run_upgrades": {},
			"potion_ids": [],
			"random_potion": true
		}
	},
	"ticket_upgrade_voucher": {
		"id": "ticket_upgrade_voucher",
		"label_key": "rest.exchange.upgrade_voucher.label",
		"note_key": "rest.exchange.upgrade_voucher.note",
		"effect_key": "rest.exchange.upgrade_voucher.effect",
		"slot_kind": "service",
		"icon_id": "dice_tune",
		"badge_id": "ready",
		"object_texture_id": "exchange_object_upgrade_ticket",
		"price": 3,
		"result": {
			"accepted": true,
			"choice": "ticket_upgrade_voucher",
			"gold_delta": 0,
			"hp_delta": 0,
			"contract_tickets_delta": -3,
			"relic_ids": [],
			"next_combat_mods": [],
			"run_upgrades": {},
			"potion_ids": ["upgrade_voucher"]
		}
	},
	"ticket_random_relic": {
		"id": "ticket_random_relic",
		"label_key": "rest.exchange.random_relic.label",
		"note_key": "rest.exchange.random_relic.note",
		"effect_key": "rest.exchange.random_relic.effect",
		"slot_kind": "service",
		"icon_id": "relic",
		"badge_id": "special",
		"object_texture_id": "exchange_object_relic_pouch",
		"price": 5,
		"result": {
			"accepted": true,
			"choice": "ticket_random_relic",
			"gold_delta": 0,
			"hp_delta": 0,
			"contract_tickets_delta": -5,
			"relic_ids": [],
			"next_combat_mods": [],
			"run_upgrades": {},
			"potion_ids": [],
			"random_relic": true
		}
	}
}

static func action_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in ACTION_ORDER:
		ids.append(str(id))
	return ids

static func upgrade_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in UPGRADE_ORDER:
		ids.append(str(id))
	return ids

static func exchange_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in EXCHANGE_ORDER:
		ids.append(str(id))
	return ids

static func action(action_id: String) -> Dictionary:
	if not ACTIONS.has(action_id):
		return {}
	return (ACTIONS[action_id] as Dictionary).duplicate(true)

static func result(action_id: String) -> Dictionary:
	var data := action(action_id)
	if data.is_empty():
		return {}
	return (data.get("result", {}) as Dictionary).duplicate(true)

static func choice_data(action_id: String) -> Dictionary:
	var data := action(action_id)
	if data.is_empty():
		return {}
	var choice := {
		"id": action_id,
		"label": _localized(data, "label", action_id),
		"note": _localized(data, "note", ""),
		"effect": _localized(data, "effect", ""),
		"station": str(data.get("station", "")),
		"result": result(action_id)
	}
	for optional_key in ["slot_kind", "icon_id", "badge_id", "object_texture_id", "price"]:
		if data.has(optional_key):
			choice[optional_key] = data[optional_key]
	return choice

static func choices() -> Array[Dictionary]:
	var result_value: Array[Dictionary] = []
	for id in ACTION_ORDER:
		result_value.append(choice_data(str(id)))
	return result_value

static func upgrade_choices() -> Array[Dictionary]:
	var result_value: Array[Dictionary] = []
	for id in UPGRADE_ORDER:
		result_value.append(choice_data(str(id)))
	return result_value

static func exchange_choices() -> Array[Dictionary]:
	var result_value: Array[Dictionary] = []
	for id in EXCHANGE_ORDER:
		result_value.append(choice_data(str(id)))
	return result_value

static func _localized(data: Dictionary, field: String, fallback: String) -> String:
	var key := str(data.get(field + "_key", ""))
	if key != "":
		return UiText.t(key)
	return str(data.get(field, fallback))
