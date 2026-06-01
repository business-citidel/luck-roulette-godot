extends SceneTree

const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const ShopOfferCatalog := preload("res://scripts/systems/shop_offer_catalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_three_unowned_relic_offers()
	_check_owned_unique_relics_are_excluded()
	_check_offer_metadata_matches_relic_catalog()
	_check_relic_price_modifiers()
	_check_exhausted_pool_returns_available_only()
	_check_shop_v2_mix_and_results()
	_check_service_upgrade_payloads()

	if failures.is_empty():
		print("shop offer catalog smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_three_unowned_relic_offers() -> void:
	var offers := ShopOfferCatalog.relic_offer_ids({"relic_ids": [], "seed_text": "shop-smoke"})
	if offers.size() != min(3, RelicCatalog.shop_ids().size()):
		failures.append("shop should offer three relic ids when the pool has enough candidates")
	var repeated := ShopOfferCatalog.relic_offer_ids({"relic_ids": [], "seed_text": "shop-smoke"})
	if offers != repeated:
		failures.append("shop relic offers should be deterministic for a seed")
	for relic_id in offers:
		if not RelicCatalog.has_pool_tag(relic_id, "shop"):
			failures.append("shop offer should come from shop pool: " + relic_id)
		if not RelicCatalog.runtime_allowed(relic_id):
			failures.append("shop offer should be runtime allowed: " + relic_id)

func _check_owned_unique_relics_are_excluded() -> void:
	var offers := ShopOfferCatalog.relic_offer_ids({"relic_ids": ["loaded_die", "green_purse"], "seed_text": "shop-smoke"})
	if offers.has("loaded_die") or offers.has("green_purse"):
		failures.append("shop should exclude already owned unique relics")
	if offers.size() != 3:
		failures.append("shop should refill from later unowned relic candidates")

func _check_offer_metadata_matches_relic_catalog() -> void:
	var choices := ShopOfferCatalog.relic_offer_choices({"relic_ids": [], "seed_text": "shop-smoke"})
	for choice in choices:
		var relic_id := str(choice.get("relic_id", ""))
		if int(choice.get("price", -1)) != RelicCatalog.shop_price(relic_id):
			failures.append("shop offer price should come from RelicCatalog for " + relic_id)
		if str(choice.get("name", "")) != RelicCatalog.display_name(relic_id):
			failures.append("shop offer name should come from RelicCatalog for " + relic_id)

func _check_relic_price_modifiers() -> void:
	var base := RelicCatalog.shop_price("loaded_die")
	if ShopOfferCatalog.relic_price_for_run("loaded_die", {"relic_ids": ["blood_coupon"]}) != max(1, int(floor(float(base) * 0.8))):
		failures.append("blood_coupon should reduce displayed relic shop price")
	if ShopOfferCatalog.relic_price_for_run("loaded_die", {"relic_ids": ["royal_voucher_press"]}) != max(1, int(ceil(float(base) * 1.25))):
		failures.append("royal_voucher_press should increase displayed relic shop price")

func _check_exhausted_pool_returns_available_only() -> void:
	var owned := RelicCatalog.shop_ids()
	var offers := ShopOfferCatalog.relic_offer_ids({"relic_ids": owned})
	if not offers.is_empty():
		failures.append("shop should return no unique relic offers when the shop pool is fully owned")

func _check_shop_v2_mix_and_results() -> void:
	var state := {"relic_ids": [], "seed_text": "shop-v2-smoke"}
	var choices := ShopOfferCatalog.shop_v2_offer_choices(state, 0)
	if choices.size() != 5:
		failures.append("shop v2 should offer 5 choices: 2 relics, 2 services, 1 special")
	var expected_ids := ["shop_relic", "shop_relic_1", "shop_prep", "shop_service_1", "shop_special"]
	for id in expected_ids:
		if not _has_choice_id(choices, id):
			failures.append("shop v2 missing choice id: " + id)
	for choice in choices:
		var choice_id := str(choice.get("id", ""))
		var result: Dictionary = choice.get("result", {})
		if result.is_empty():
			failures.append("shop v2 choice should carry a purchase result: " + choice_id)
		if str(result.get("choice", "")) != choice_id:
			failures.append("shop v2 result choice should match id: " + choice_id)
		if int(result.get("gold_delta", 0)) >= 0:
			failures.append("shop v2 purchase should spend gold: " + choice_id)
		if not ShopOfferCatalog.is_relic_choice(choice_id):
			if str(choice.get("icon_id", "")) == "":
				failures.append("shop v2 service should expose replaceable icon id: " + choice_id)
			if str(choice.get("badge_id", "")) == "":
				failures.append("shop v2 service should expose replaceable badge id: " + choice_id)

	var rerolled := ShopOfferCatalog.shop_v2_offer_choices(state, 1)
	var changed := false
	for i in range(min(choices.size(), rerolled.size())):
		if str(choices[i].get("service_id", choices[i].get("relic_id", ""))) != str(rerolled[i].get("service_id", rerolled[i].get("relic_id", ""))):
			changed = true
	if not changed:
		failures.append("shop v2 reroll should rotate at least one offer for the same seed")

func _has_choice_id(choices: Array[Dictionary], choice_id: String) -> bool:
	for choice in choices:
		if str(choice.get("id", "")) == choice_id:
			return true
	return false

func _check_service_upgrade_payloads() -> void:
	var marble_polish := _service_config("marble_polish")
	var marble_upgrades: Dictionary = (marble_polish.get("result", {}) as Dictionary).get("run_upgrades", {})
	if abs(float(marble_upgrades.get("marble_bonus", 0.0)) - 1.0) > 0.001:
		failures.append("marble_polish should persist marble_bonus as wager polish")
	var roulette_tune := _service_config("roulette_tune")
	var roulette_upgrades: Dictionary = (roulette_tune.get("result", {}) as Dictionary).get("run_upgrades", {})
	if abs(float(roulette_upgrades.get("roulette_bonus", 0.0)) - 0.2) > 0.001:
		failures.append("roulette_tune should persist roulette_bonus")

func _service_config(service_id: String) -> Dictionary:
	for item in ShopOfferCatalog.SERVICE_POOL:
		var config: Dictionary = item
		if str(config.get("service_id", "")) == service_id:
			return config
	failures.append("missing service config: " + service_id)
	return {}
