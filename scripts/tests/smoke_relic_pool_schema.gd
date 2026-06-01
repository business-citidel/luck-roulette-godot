extends SceneTree

const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RelicPoolCatalog := preload("res://scripts/systems/relic_pool_catalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_relic_schema()
	_check_relic_localization()
	_check_pool_selection()

	if failures.is_empty():
		print("relic pool schema smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_relic_schema() -> void:
	var valid_sources := [
		RelicCatalog.SOURCE_BASIC,
		RelicCatalog.SOURCE_SHOP_ONLY,
		RelicCatalog.SOURCE_EVENT_ONLY,
		RelicCatalog.SOURCE_RISK,
		RelicCatalog.SOURCE_BOSS,
		RelicCatalog.SOURCE_QUEST,
		RelicCatalog.SOURCE_CHARACTER,
		RelicCatalog.SOURCE_EXPERIMENTAL
	]
	for relic_id in RelicCatalog.all_ids():
		var relic: Dictionary = RelicCatalog.get_relic(relic_id)
		if not valid_sources.has(RelicCatalog.source_pool(relic_id)):
			failures.append(relic_id + " has unknown source pool")
		if RelicCatalog.core_tags(relic_id).is_empty():
			failures.append(relic_id + " needs at least one core tag")
		if RelicCatalog.risk_level(relic_id) == "":
			failures.append(relic_id + " needs risk_level")
		if RelicCatalog.fun_reason(relic_id) == "":
			failures.append(relic_id + " needs fun_reason")
		if RelicCatalog.danger_reason(relic_id) == "":
			failures.append(relic_id + " needs danger_reason")
		if RelicCatalog.implementation_status(relic_id) == "":
			failures.append(relic_id + " needs implementation_status")
		if not relic.has("runtime_allowed"):
			failures.append(relic_id + " needs runtime_allowed")
		if not relic.has("test_status"):
			failures.append(relic_id + " needs test_status")
		if RelicCatalog.runtime_allowed(relic_id) and RelicCatalog.test_status(relic_id) == "":
			failures.append(relic_id + " runtime relic needs test_status")

func _check_relic_localization() -> void:
	TranslationServer.set_locale("ko")
	for relic_id in RelicCatalog.all_ids():
		if not _contains_korean(RelicCatalog.display_name(relic_id)):
			failures.append(relic_id + " needs Korean display name")
		if not _contains_korean(RelicCatalog.short_description(relic_id)):
			failures.append(relic_id + " needs Korean short description")
	TranslationServer.set_locale("en")
	for relic_id in RelicCatalog.all_ids():
		if _contains_korean(RelicCatalog.display_name(relic_id)):
			failures.append(relic_id + " English display name contains Korean")
		if _contains_korean(RelicCatalog.short_description(relic_id)):
			failures.append(relic_id + " English short description contains Korean")
	TranslationServer.set_locale("ko")

func _check_pool_selection() -> void:
	var first := RelicPoolCatalog.choose_reward_id([], {
		"context": RelicPoolCatalog.CONTEXT_REWARD,
		"source_pool": RelicCatalog.SOURCE_BASIC,
		"seed_text": "schema-smoke"
	})
	var second := RelicPoolCatalog.choose_reward_id([], {
		"context": RelicPoolCatalog.CONTEXT_REWARD,
		"source_pool": RelicCatalog.SOURCE_BASIC,
		"seed_text": "schema-smoke"
	})
	if first == "" or first != second:
		failures.append("pool reward selection should be deterministic and non-empty")
	if first != "" and RelicCatalog.source_pool(first) != RelicCatalog.SOURCE_BASIC:
		failures.append("basic reward selection should stay in the basic pool")
	if first != "" and not RelicCatalog.runtime_allowed(first):
		failures.append("basic reward selection should be runtime allowed")
	var offers := RelicPoolCatalog.shop_offer_ids({"relic_ids": [], "seed_text": "schema-smoke"}, 3)
	if offers.size() != 3:
		failures.append("shop pool should return three offers")
	for id in offers:
		if not RelicCatalog.has_pool_tag(id, "shop"):
			failures.append("shop pool returned non-shop relic " + id)
		if not RelicCatalog.runtime_allowed(id):
			failures.append("shop pool returned runtime-disallowed relic " + id)
	for id in RelicCatalog.reward_ids(RelicCatalog.SOURCE_BASIC):
		if RelicCatalog.source_pool(id) != RelicCatalog.SOURCE_BASIC:
			failures.append("basic reward_ids included non-basic relic " + id)
		if not RelicCatalog.runtime_allowed(id):
			failures.append("basic reward_ids included runtime-disallowed relic " + id)
	for id in RelicCatalog.shop_ids():
		if not RelicCatalog.runtime_allowed(id):
			failures.append("shop_ids included runtime-disallowed relic " + id)
	_check_character_pool_profiles()

func _check_character_pool_profiles() -> void:
	_check_profile_allows_defense("default_guard_dice", ["default_guard_crest"])
	_check_profile_blocks_guard_identity("double_attack_dice", ["double_attack_crest"])
	_check_profile_blocks_guard_identity("black_signer_no_dice", [])
	_check_profile_allows_incident_defense("double_attack_dice", ["double_attack_crest"])
	_check_existing_relic_reclassification()
	_check_common_pool_keeps_defense()

func _check_profile_blocks_guard_identity(character_id: String, owned: Array) -> void:
	for context_id in [
		RelicPoolCatalog.CONTEXT_REWARD,
		RelicPoolCatalog.CONTEXT_SHOP,
		RelicPoolCatalog.CONTEXT_REST,
		RelicPoolCatalog.CONTEXT_EVENT
	]:
		var ids := RelicPoolCatalog.eligible_ids_for_character(RelicCatalog.SOURCE_BASIC, context_id, character_id, owned)
		for id in ids:
			if _is_guard_identity_relic(id):
				failures.append(character_id + " pool should exclude guard identity relic " + id + " in " + context_id)
	var shop_offers := RelicPoolCatalog.shop_offer_ids({
		"relic_ids": owned,
		"character_id": character_id,
		"seed_text": character_id + "-profile-smoke"
	}, 8)
	for id in shop_offers:
		if _is_guard_identity_relic(id):
			failures.append(character_id + " shop offers should exclude guard identity relic " + id)

func _check_profile_allows_incident_defense(character_id: String, owned: Array) -> void:
	var ids := RelicPoolCatalog.eligible_ids_for_character(RelicCatalog.SOURCE_BASIC, RelicPoolCatalog.CONTEXT_REWARD, character_id, owned)
	var found_incident_defense := false
	for id in ids:
		if RelicCatalog.core_tags(id).has("incident_defense"):
			found_incident_defense = true
			break
	if not found_incident_defense:
		failures.append(character_id + " pool should allow at least one incident defense relic")

func _check_profile_allows_defense(character_id: String, owned: Array) -> void:
	var ids := RelicPoolCatalog.eligible_ids_for_character(RelicCatalog.SOURCE_BASIC, RelicPoolCatalog.CONTEXT_REWARD, character_id, owned)
	var found_defense := false
	for id in ids:
		if _is_defensive_relic(id):
			found_defense = true
			break
	if not found_defense:
		failures.append(character_id + " pool should keep at least one defensive relic")

func _check_existing_relic_reclassification() -> void:
	for id in [
		"jackpot_knife",
		"wheel_jackpot_blood",
		"risk_rare_pull",
		"gamblers_spare_marble",
		"gamblers_odd_eye",
		"gamblers_last_reroll",
		"cursed_players_split_tooth",
		"marble_savant_charm",
		"roulette_savant_pin"
	]:
		if not RelicCatalog.allowed_profiles(id).is_empty():
			failures.append(id + " should be all-character common/favored, not profile-locked")
	if not RelicCatalog.allowed_profiles("risk_last_hand").has("double_attack"):
		failures.append("risk_last_hand should stay double-specialized")
	if not RelicCatalog.allowed_profiles("cursed_players_red_marble").has("double_attack"):
		failures.append("cursed_players_red_marble should stay double-specialized")
	if not RelicCatalog.allowed_profiles("cursed_players_pain_bell").has("double_attack"):
		failures.append("cursed_players_pain_bell should stay double-specialized")
	if RelicCatalog.core_tags("dice_guard_lead").has("guard_identity"):
		failures.append("dice_guard_lead should be incident defense, not guard identity")
	var double_basic := RelicPoolCatalog.eligible_ids_for_character(RelicCatalog.SOURCE_BASIC, RelicPoolCatalog.CONTEXT_REWARD, "double_attack_dice", ["double_attack_crest"])
	for id in ["dice_guard_lead", "gamblers_spare_marble", "gamblers_odd_eye", "gamblers_last_reroll", "cursed_players_split_tooth", "marble_savant_charm", "roulette_savant_pin"]:
		if not double_basic.has(id):
			failures.append("double_attack_dice basic pool should include all-character relic " + id)
	var guard_basic := RelicPoolCatalog.eligible_ids_for_character(RelicCatalog.SOURCE_BASIC, RelicPoolCatalog.CONTEXT_REWARD, "default_guard_dice", ["default_guard_crest"])
	for id in ["gamblers_spare_marble", "gamblers_odd_eye", "gamblers_last_reroll", "cursed_players_split_tooth", "marble_savant_charm", "roulette_savant_pin"]:
		if not guard_basic.has(id):
			failures.append("default_guard_dice basic pool should include all-character relic " + id)
	var guard_risk := RelicPoolCatalog.eligible_ids_for_character(RelicCatalog.SOURCE_RISK, RelicPoolCatalog.CONTEXT_REWARD, "default_guard_dice", ["default_guard_crest"])
	for id in ["jackpot_knife", "wheel_jackpot_blood", "risk_rare_pull"]:
		if not guard_risk.has(id):
			failures.append("default_guard_dice risk pool should include all-character relic " + id)
	for id in ["risk_last_hand", "cursed_players_pain_bell"]:
		if guard_risk.has(id):
			failures.append("default_guard_dice risk pool should exclude double-specialized relic " + id)

func _check_common_pool_keeps_defense() -> void:
	var ids := RelicPoolCatalog.eligible_ids(RelicCatalog.SOURCE_BASIC, RelicPoolCatalog.CONTEXT_REWARD, [])
	var found_defense := false
	for id in ids:
		if _is_defensive_relic(id):
			found_defense = true
			break
	if not found_defense:
		failures.append("common pool should keep defensive relics until a character profile is known")

func _is_defensive_relic(id: String) -> bool:
	return RelicCatalog.has_pool_tag(id, "defense") or RelicCatalog.core_tags(id).has("hp_block")

func _is_guard_identity_relic(id: String) -> bool:
	return RelicCatalog.core_tags(id).has("guard_identity")

func _contains_korean(text: String) -> bool:
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if code >= 0xac00 and code <= 0xd7a3:
			return true
	return false
