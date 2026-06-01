class_name RelicPoolCatalog
extends RefCounted

const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const CharacterContractCatalog := preload("res://scripts/systems/character_contract_catalog.gd")

const CONTEXT_REWARD := "reward"
const CONTEXT_SHOP := "shop"
const CONTEXT_REST := "rest"
const CONTEXT_EVENT := "event"
const CONTEXT_RISK := "risk"

const STARTER_BASIC_IDS: Array[String] = [
	"loaded_die",
	"dice_low_guard",
	"def_first_hit",
	"dice_under_six",
	"lucky_low_marble",
	"gamblers_spare_marble",
	"gamblers_odd_eye",
	"gamblers_last_reroll",
	"strawberry_chip",
	"bruise_receipt",
	"ticket_lint",
	"upgrade_receipt",
	"polite_haggle",
	"pocket_map",
	"stamp_album",
	"dealer_smile",
	"ticket_primer",
	"punched_ticket",
	"shop_meal_ticket",
	"rest_change_jar",
	"velvet_price_tag"
]

const REST_SAFE_IDS: Array[String] = [
	"loaded_die",
	"yellow_guard",
	"dice_under_six",
	"dice_low_guard",
	"def_first_hit",
	"dice_wide_split",
	"econ_low_gold",
	"dice_exact_four",
	"dice_guard_lead",
	"def_after_bust",
	"lucky_low_marble"
]

const PROFILE_COMMON := "common"
const PROFILE_GUARD := CharacterContractCatalog.RELIC_PROFILE_GUARD
const PROFILE_DOUBLE_ATTACK := CharacterContractCatalog.RELIC_PROFILE_DOUBLE_ATTACK
const PROFILE_BLACK_SIGNER := CharacterContractCatalog.RELIC_PROFILE_BLACK_SIGNER

const PROFILE_RULES := {
	PROFILE_GUARD: {
		"blocked_pool_tags": [],
		"blocked_core_tags": []
	},
	PROFILE_DOUBLE_ATTACK: {
		"blocked_pool_tags": [],
		"blocked_core_tags": ["guard_identity"]
	},
	PROFILE_BLACK_SIGNER: {
		"blocked_pool_tags": [],
		"blocked_core_tags": ["guard_identity"]
	}
}

static func choose_reward_id(existing_ids: Array, context: Dictionary = {}) -> String:
	var source_pool := str(context.get("source_pool", RelicCatalog.SOURCE_BASIC))
	var ids := eligible_ids(source_pool, CONTEXT_REWARD, existing_ids, context)
	if source_pool == RelicCatalog.SOURCE_BASIC and existing_ids.size() < 2:
		var starter_ids := _starter_eligible(ids)
		if not starter_ids.is_empty():
			ids = starter_ids
	if ids.is_empty():
		ids = eligible_ids(_fallback_source(source_pool), CONTEXT_REWARD, existing_ids, context)
	return _weighted_pick(ids, context, existing_ids)

static func shop_offer_ids(run_state: Dictionary, limit: int = 3, context: Dictionary = {}) -> Array[String]:
	var source_pool := str(context.get("source_pool", RelicCatalog.SOURCE_BASIC))
	var existing_ids: Array = run_state.get("relic_ids", [])
	var local_context := context.duplicate(true)
	if not local_context.has("character_id") and run_state.has("character_id"):
		local_context["character_id"] = str(run_state.get("character_id", ""))
	var ids := eligible_ids(source_pool, CONTEXT_SHOP, existing_ids, local_context)
	if ids.size() < limit:
		for id in eligible_ids(_fallback_source(source_pool), CONTEXT_SHOP, existing_ids, local_context):
			if not ids.has(id):
				ids.append(id)
	var result: Array[String] = []
	for i in range(limit):
		if ids.is_empty():
			break
		local_context["offer_index"] = i
		var picked := _weighted_pick(ids, local_context, existing_ids)
		if picked == "":
			break
		result.append(picked)
		ids.erase(picked)
	return result

static func eligible_ids(source_pool: String, context_id: String, existing_ids: Array = [], context: Dictionary = {}) -> Array[String]:
	var owned := _owned_lookup(existing_ids)
	var profile := _profile_for_context(owned, context)
	var result: Array[String] = []
	for id in RelicCatalog.all_ids():
		if RelicCatalog.source_pool(id) != source_pool:
			continue
		if RelicCatalog.implementation_status(id) != "runtime":
			continue
		if not RelicCatalog.runtime_allowed(id):
			continue
		if context_id == CONTEXT_SHOP and not RelicCatalog.has_pool_tag(id, "shop"):
			continue
		if context_id != CONTEXT_SHOP and not RelicCatalog.has_pool_tag(id, "reward"):
			continue
		if not _context_allows(id, context_id):
			continue
		if RelicCatalog.is_unique(id) and owned.has(id):
			continue
		if not relic_allowed_for_profile(id, profile):
			continue
		result.append(id)
	return result

static func eligible_ids_for_character(source_pool: String, context_id: String, character_id: String, existing_ids: Array = []) -> Array[String]:
	return eligible_ids(source_pool, context_id, existing_ids, {"character_id": character_id})

static func source_pool_counts() -> Dictionary:
	var counts := {}
	for id in RelicCatalog.all_ids():
		var source := RelicCatalog.source_pool(id)
		counts[source] = int(counts.get(source, 0)) + 1
	return counts

static func _weighted_pick(ids: Array[String], context: Dictionary, existing_ids: Array) -> String:
	if ids.is_empty():
		return ""
	var total := 0.0
	for id in ids:
		total += max(0.01, RelicCatalog.reward_weight(id))
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_from_context(context, existing_ids)
	var roll := rng.randf() * total
	var cursor := 0.0
	for id in ids:
		cursor += max(0.01, RelicCatalog.reward_weight(id))
		if roll <= cursor:
			return id
	return ids[0]

static func _seed_from_context(context: Dictionary, existing_ids: Array) -> int:
	var seed_text := str(context.get("seed_text", context.get("seed", "luck-roulette-relic-pool")))
	var source_pool := str(context.get("source_pool", RelicCatalog.SOURCE_BASIC))
	var context_id := str(context.get("context", CONTEXT_REWARD))
	var offer_index := int(context.get("offer_index", 0))
	var text := seed_text + "|" + source_pool + "|" + context_id + "|" + str(existing_ids.size()) + "|" + str(offer_index)
	for id in existing_ids:
		text += "|" + str(id)
	return max(1, abs(text.hash()))

static func _owned_lookup(relic_ids: Array) -> Dictionary:
	var lookup := {}
	for id in relic_ids:
		lookup[str(id)] = true
	return lookup

static func _starter_eligible(ids: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for id in ids:
		if STARTER_BASIC_IDS.has(id):
			result.append(id)
	return result

static func relic_allowed_for_profile(id: String, profile: String) -> bool:
	var allowed := RelicCatalog.allowed_profiles(id)
	if not allowed.is_empty() and not allowed.has(profile):
		return false
	var rules: Dictionary = PROFILE_RULES.get(profile, {})
	for tag in rules.get("blocked_pool_tags", []):
		if RelicCatalog.has_pool_tag(id, str(tag)):
			return false
	for tag in rules.get("blocked_core_tags", []):
		if RelicCatalog.core_tags(id).has(str(tag)):
			return false
	return true

static func _profile_for_context(owned: Dictionary, context: Dictionary) -> String:
	var character_id := str(context.get("character_id", ""))
	if character_id != "":
		return CharacterContractCatalog.relic_pool_profile(character_id)
	if owned.has("default_guard_crest"):
		return PROFILE_GUARD
	if owned.has("double_attack_crest"):
		return PROFILE_DOUBLE_ATTACK
	return PROFILE_COMMON

static func _fallback_source(source_pool: String) -> String:
	if source_pool == RelicCatalog.SOURCE_BASIC:
		return RelicCatalog.SOURCE_RISK
	return RelicCatalog.SOURCE_BASIC

static func _context_allows(id: String, context_id: String) -> bool:
	match context_id:
		CONTEXT_REST:
			return REST_SAFE_IDS.has(id)
		CONTEXT_EVENT:
			if RelicCatalog.source_pool(id) == RelicCatalog.SOURCE_RISK:
				return true
			return RelicCatalog.rarity(id) != "rare" and RelicCatalog.risk_level(id) == "low"
		CONTEXT_RISK:
			return RelicCatalog.source_pool(id) == RelicCatalog.SOURCE_RISK or RelicCatalog.rarity(id) == "rare"
		_:
			return true
