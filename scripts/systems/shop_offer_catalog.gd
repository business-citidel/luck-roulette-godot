class_name ShopOfferCatalog
extends RefCounted

const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RelicPoolCatalog := preload("res://scripts/systems/relic_pool_catalog.gd")
const DisplayBridge := preload("res://scripts/runtime/systems/game_object_display_bridge.gd")
const RunChoice := preload("res://scripts/run/run_choice.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const DEFAULT_RELIC_OFFER_LIMIT := 3
const SHOP_V2_RELIC_OFFER_LIMIT := 2
const SHOP_V2_SERVICE_OFFER_LIMIT := 2

const SERVICE_POOL := [
	{
		"service_id": "soft_prep",
		"slot_kind": "service",
		"label_key": "shop.service.soft_prep.label",
		"note_key": "shop.service.soft_prep.note",
		"effect_key": "shop.service.soft_prep.effect",
		"description_key": "shop.service.soft_prep.description",
		"price": 14,
		"icon_id": "dice_tune",
		"badge_id": "ready",
		"result": {
			"accepted": true,
			"gold_delta": -14,
			"hp_delta": 0,
			"relic_ids": [],
			"next_combat_mods": [{
				"id": "shop_soft_prep",
				"enemy_damage_delta": -2,
				"description": "Shop prep: next enemy hit is softened."
			}]
		}
	},
	{
		"service_id": "cash_bait",
		"slot_kind": "service",
		"label_key": "shop.service.cash_bait.label",
		"note_key": "shop.service.cash_bait.note",
		"effect_key": "shop.service.cash_bait.effect",
		"description_key": "shop.service.cash_bait.description",
		"price": 10,
		"icon_id": "cash_bait",
		"badge_id": "special",
		"result": {
			"accepted": true,
			"gold_delta": -10,
			"hp_delta": 0,
			"relic_ids": [],
			"next_combat_mods": [{
				"id": "shop_cash_bait",
				"combat_cash": 8,
				"description": "Shop bait: next combat pays more."
			}]
		}
	},
	{
		"service_id": "heal_vial",
		"slot_kind": "service",
		"label_key": "shop.service.heal_vial.label",
		"note_key": "shop.service.heal_vial.note",
		"effect_key": "shop.service.heal_vial.effect",
		"description_key": "shop.service.heal_vial.description",
		"price": 22,
		"icon_id": "heal_vial",
		"badge_id": "ready",
		"result": {
			"accepted": true,
			"gold_delta": -22,
			"hp_delta": 8,
			"relic_ids": [],
			"next_combat_mods": []
		}
	},
	{
		"service_id": "marble_polish",
		"slot_kind": "service",
		"label_key": "shop.service.marble_polish.label",
		"note_key": "shop.service.marble_polish.note",
		"effect_key": "shop.service.marble_polish.effect",
		"description_key": "shop.service.marble_polish.description",
		"price": 20,
		"icon_id": "marble_polish",
		"badge_id": "ready",
		"result": {
			"accepted": true,
			"gold_delta": -20,
			"hp_delta": 0,
			"relic_ids": [],
			"next_combat_mods": [],
			"run_upgrades": {"marble_bonus": 1.0}
		}
	},
	{
		"service_id": "dice_tune",
		"slot_kind": "service",
		"label_key": "shop.service.dice_tune.label",
		"note_key": "shop.service.dice_tune.note",
		"effect_key": "shop.service.dice_tune.effect",
		"description_key": "shop.service.dice_tune.description",
		"price": 24,
		"icon_id": "dice_tune",
		"badge_id": "ready",
		"result": {
			"accepted": true,
			"gold_delta": -24,
			"hp_delta": 0,
			"relic_ids": [],
			"next_combat_mods": [],
			"run_upgrades": {"primary_die_bonus": 1.0}
		}
	},
	{
		"service_id": "roulette_tune",
		"slot_kind": "service",
		"label_key": "shop.service.roulette_tune.label",
		"note_key": "shop.service.roulette_tune.note",
		"effect_key": "shop.service.roulette_tune.effect",
		"description_key": "shop.service.roulette_tune.description",
		"price": 24,
		"icon_id": "roulette_tune",
		"badge_id": "special",
		"result": {
			"accepted": true,
			"gold_delta": -24,
			"hp_delta": 0,
			"relic_ids": [],
			"next_combat_mods": [],
			"run_upgrades": {"roulette_bonus": 0.2}
		}
	}
]

const SPECIAL_POOL := [
	{
		"service_id": "risk_contract",
		"slot_kind": "special",
		"label_key": "shop.service.risk_contract.label",
		"note_key": "shop.service.risk_contract.note",
		"effect_key": "shop.service.risk_contract.effect",
		"description_key": "shop.service.risk_contract.description",
		"price": 12,
		"icon_id": "risk_contract",
		"badge_id": "gamble",
		"result": {
			"accepted": true,
			"gold_delta": -12,
			"hp_delta": 0,
			"relic_ids": [],
			"next_combat_mods": [{
				"id": "shop_risk_contract",
				"combat_cash": 14,
				"enemy_damage_delta": 2,
				"description": "Risk contract: next combat pays more but hits harder."
			}]
		}
	},
	{
		"service_id": "blood_discount",
		"slot_kind": "special",
		"label_key": "shop.service.blood_discount.label",
		"note_key": "shop.service.blood_discount.note",
		"effect_key": "shop.service.blood_discount.effect",
		"description_key": "shop.service.blood_discount.description",
		"price": 8,
		"icon_id": "blood_discount",
		"badge_id": "contract",
		"result": {
			"accepted": true,
			"gold_delta": -8,
			"hp_delta": -3,
			"relic_ids": [],
			"next_combat_mods": [{
				"id": "shop_blood_discount",
				"combat_cash": 10,
				"description": "Blood discount: paid in blood for a better next payout."
			}]
		}
	}
]

static func relic_offer_ids(run_state: Dictionary, limit: int = DEFAULT_RELIC_OFFER_LIMIT, source_pool_override: String = "") -> Array[String]:
	var source_pool := source_pool_override
	if source_pool == "":
		source_pool = str(run_state.get("relic_shop_source_pool", RelicCatalog.SOURCE_BASIC))
	var dynamic_limit := limit
	var owned: Array = run_state.get("relic_ids", [])
	if owned.has("dusty_shelf"):
		dynamic_limit += 1
	if owned.has("ticket_monopoly"):
		dynamic_limit = max(1, dynamic_limit - 1)
	return RelicPoolCatalog.shop_offer_ids(run_state, dynamic_limit, {
		"context": RelicPoolCatalog.CONTEXT_SHOP,
		"source_pool": source_pool,
		"seed_text": str(run_state.get("seed_text", "shop"))
	})

static func relic_offer_choices(run_state: Dictionary, limit: int = DEFAULT_RELIC_OFFER_LIMIT, source_pool_override: String = "") -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var relic_ids := relic_offer_ids(run_state, limit, source_pool_override)
	for i in range(relic_ids.size()):
		var relic_id := relic_ids[i]
		var choice_id := relic_choice_id(i)
		var price := relic_price_for_run(relic_id, run_state)
		var object_display := _relic_object_display(relic_id, price)
		choices.append({
			"id": choice_id,
			"relic_id": relic_id,
			"object_id": relic_id,
			"object_kind": "relic",
			"object_display": object_display,
			"name": str(object_display.get("name", RelicCatalog.display_name(relic_id))),
			"description": str(object_display.get("description", RelicCatalog.short_description(relic_id))),
			"icon_id": str(object_display.get("icon_id", RelicCatalog.icon_id(relic_id))),
			"price": price,
			"rarity": str(object_display.get("rarity", RelicCatalog.rarity(relic_id)))
		})
	return choices

static func relic_price_for_run(relic_id: String, run_state: Dictionary) -> int:
	var price := RelicCatalog.shop_price(relic_id)
	var owned: Array = run_state.get("relic_ids", [])
	if owned.has("blood_coupon"):
		price = max(1, int(floor(float(price) * 0.8)))
	if owned.has("royal_voucher_press"):
		price = max(1, int(ceil(float(price) * 1.25)))
	return price

static func shop_v2_offer_choices(run_state: Dictionary, reroll_index: int = 0) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var reroll_state := _reroll_state(run_state, reroll_index)
	for choice in relic_offer_choices(reroll_state, 1, RelicCatalog.SOURCE_BASIC):
		choices.append(_runtime_relic_choice(choice))
	var shop_state := _with_extra_owned(reroll_state, _choice_relic_ids(choices))
	var shop_only_choices := relic_offer_choices(shop_state, 1, RelicCatalog.SOURCE_SHOP_ONLY)
	if shop_only_choices.is_empty():
		shop_only_choices = relic_offer_choices(shop_state, 1, RelicCatalog.SOURCE_BASIC)
	for choice in shop_only_choices:
		var normalized := choice.duplicate(true)
		normalized["id"] = relic_choice_id(choices.size())
		choices.append(_runtime_relic_choice(normalized))
		break
	var services := service_offer_choices(run_state, SHOP_V2_SERVICE_OFFER_LIMIT, reroll_index)
	for service in services:
		choices.append(service)
	choices.append(special_offer_choice(run_state, reroll_index))
	return choices

static func service_offer_choices(run_state: Dictionary, limit: int = SHOP_V2_SERVICE_OFFER_LIMIT, reroll_index: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if limit <= 0 or SERVICE_POOL.is_empty():
		return result
	result.append(_service_choice(SERVICE_POOL[0], "shop_prep"))
	var secondary_pool: Array[Dictionary] = []
	for i in range(1, SERVICE_POOL.size()):
		secondary_pool.append(SERVICE_POOL[i])
	var ids := _rotated_pool(secondary_pool, run_state, reroll_index)
	for i in range(min(limit - 1, ids.size())):
		result.append(_service_choice(ids[i], "shop_service_" + str(i + 1)))
	return result

static func special_offer_choice(run_state: Dictionary, reroll_index: int = 0) -> Dictionary:
	var ids := _rotated_pool(SPECIAL_POOL, run_state, reroll_index)
	return _service_choice(ids[0], "shop_special")

static func service_choice_index(choice_id: String) -> int:
	if choice_id == "shop_prep":
		return 0
	if choice_id.begins_with("shop_service_"):
		return int(choice_id.replace("shop_service_", ""))
	return -1

static func is_service_choice(choice_id: String) -> bool:
	return service_choice_index(choice_id) >= 0

static func is_special_choice(choice_id: String) -> bool:
	return choice_id == "shop_special"

static func relic_choice_id(index: int) -> String:
	if index <= 0:
		return "shop_relic"
	return "shop_relic_" + str(index)

static func relic_choice_index(choice_id: String) -> int:
	if choice_id == "shop_relic":
		return 0
	if choice_id.begins_with("shop_relic_"):
		return int(choice_id.replace("shop_relic_", ""))
	return -1

static func is_relic_choice(choice_id: String) -> bool:
	return relic_choice_index(choice_id) >= 0

static func _service_choice(template: Dictionary, choice_id: String) -> Dictionary:
	var result: Dictionary = (template.get("result", {}) as Dictionary).duplicate(true)
	result["choice"] = choice_id
	var service_id := str(template.get("service_id", ""))
	var slot_kind := str(template.get("slot_kind", "service"))
	var price := int(template.get("price", 0))
	var icon_id := str(template.get("icon_id", "service"))
	var object_display := DisplayBridge.surface_payload(service_id, "shop_item", {
		"name": UiText.t(str(template.get("label_key", ""))),
		"description": UiText.t(str(template.get("description_key", ""))),
		"icon_id": icon_id,
		"price": price
	})
	return RunChoice.create(
		choice_id,
		str(object_display.get("name", UiText.t(str(template.get("label_key", ""))))),
		UiText.t(str(template.get("note_key", ""))),
		UiText.t(str(template.get("effect_key", ""))),
		result,
		RunChoice.STATE_NORMAL,
		true
	).merged({
		"service_id": service_id,
		"slot_kind": slot_kind,
		"object_id": service_id,
		"object_kind": "shop_item",
		"object_display": object_display,
		"price": price,
		"icon_id": icon_id,
		"badge_id": str(template.get("badge_id", "ready")),
		"description": str(object_display.get("description", UiText.t(str(template.get("description_key", "")))))
	}, true)

static func _runtime_relic_choice(offer: Dictionary) -> Dictionary:
	var choice_id := str(offer.get("id", "shop_relic"))
	var relic_id := str(offer.get("relic_id", ""))
	var price := int(offer.get("price", RelicCatalog.shop_price(relic_id)))
	var object_display: Dictionary = offer.get("object_display", _relic_object_display(relic_id, price))
	return RunChoice.create(
		choice_id,
		str(object_display.get("name", offer.get("name", RelicCatalog.display_name(relic_id)))),
		str(object_display.get("rarity", offer.get("rarity", RelicCatalog.rarity(relic_id)))),
		UiText.t("shop.gold_price", {"amount": str(price)}),
		{
			"accepted": true,
			"choice": choice_id,
			"gold_delta": -price,
			"hp_delta": 0,
			"relic_ids": [relic_id],
			"next_combat_mods": []
		},
		RunChoice.STATE_NORMAL,
		true
	).merged({
		"slot_kind": "relic",
		"relic_id": relic_id,
		"object_id": relic_id,
		"object_kind": "relic",
		"object_display": object_display,
		"icon_id": str(object_display.get("icon_id", RelicCatalog.icon_id(relic_id))),
		"description": str(object_display.get("description", RelicCatalog.short_description(relic_id))),
		"price": price
	}, true)

static func _relic_object_display(relic_id: String, price: int = -1) -> Dictionary:
	var resolved_price := price if price >= 0 else RelicCatalog.shop_price(relic_id)
	return DisplayBridge.surface_payload(relic_id, "relic", {
		"name": RelicCatalog.display_name(relic_id),
		"description": RelicCatalog.short_description(relic_id),
		"icon_id": RelicCatalog.icon_id(relic_id),
		"rarity": RelicCatalog.rarity(relic_id),
		"price": resolved_price
	})

static func _rotated_pool(pool: Array, run_state: Dictionary, reroll_index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in pool:
		if entry is Dictionary:
			result.append((entry as Dictionary).duplicate(true))
	if result.is_empty():
		return result
	var seed_text := str(run_state.get("seed_text", "shop-v2"))
	var offset: int = abs((seed_text + "|" + str(reroll_index)).hash()) % result.size()
	var rotated: Array[Dictionary] = []
	for i in range(result.size()):
		rotated.append(result[(i + offset) % result.size()])
	return rotated

static func _reroll_state(run_state: Dictionary, reroll_index: int) -> Dictionary:
	var result := run_state.duplicate(true)
	result["seed_text"] = str(run_state.get("seed_text", "shop")) + "|shop-v2-reroll-" + str(reroll_index)
	return result

static func _choice_relic_ids(choices: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for choice in choices:
		var relic_id := str(choice.get("relic_id", ""))
		if relic_id != "" and not result.has(relic_id):
			result.append(relic_id)
	return result

static func _with_extra_owned(run_state: Dictionary, extra_relic_ids: Array[String]) -> Dictionary:
	var result := run_state.duplicate(true)
	var relic_ids: Array = result.get("relic_ids", []).duplicate()
	for relic_id in extra_relic_ids:
		if not relic_ids.has(relic_id):
			relic_ids.append(relic_id)
	result["relic_ids"] = relic_ids
	return result
