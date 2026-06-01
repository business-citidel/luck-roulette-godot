extends SceneTree

const DisplayBridge := preload("res://scripts/runtime/systems/game_object_display_bridge.gd")
const PotionCatalog := preload("res://scripts/systems/potion_catalog.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RewardSceneScript := preload("res://scripts/run/reward_scene.gd")
const RunTableState := preload("res://scripts/run/run_table_state.gd")
const ShopOfferCatalog := preload("res://scripts/systems/shop_offer_catalog.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

var failures: Array[String] = []

func _initialize() -> void:
	UiText.set_locale("en")
	_check_turn_token_display()
	_check_guard_potion_display()
	_check_existing_surfaces_use_public_display_apis()
	_check_reward_shop_object_payloads()
	_finish()

func _check_turn_token_display() -> void:
	var metadata := DisplayBridge.metadata("turn_token", "relic")
	_assert_eq(metadata.get("display_name"), "Turn Token", "turn token runtime name")
	_assert_eq(metadata.get("description"), "Adds a small cash tip at the start of each turn.", "turn token runtime description")
	_assert_eq(metadata.get("icon_id"), "turn_token", "turn token runtime icon")
	_assert_eq(metadata.get("rarity"), "common", "turn token runtime rarity")
	_assert_eq(metadata.get("shop_price"), 26, "turn token runtime price")
	_assert_eq(RelicCatalog.display_name("turn_token"), "Turn Token", "relic catalog display name bridges runtime")
	_assert_eq(RelicCatalog.short_description("turn_token"), str(metadata.get("description", "")), "relic catalog description bridges runtime")
	_assert_eq(RelicCatalog.icon_id("turn_token"), "turn_token", "relic catalog icon bridges runtime")
	_assert_eq(RelicCatalog.shop_price("turn_token"), 26, "relic catalog price bridges runtime")

func _check_guard_potion_display() -> void:
	var metadata := DisplayBridge.metadata("guard_potion", "potion")
	_assert_eq(metadata.get("display_name"), "Guard Potion", "guard potion runtime name")
	_assert_eq(metadata.get("display_key"), "potion.guard_potion", "guard potion runtime display key")
	_assert_eq(PotionCatalog.display_key("guard_potion"), "potion.guard_potion", "potion catalog display key bridges runtime")

func _check_existing_surfaces_use_public_display_apis() -> void:
	var relic_items := RunTableState.relic_items(["turn_token"], [])
	if relic_items.size() != 1:
		failures.append("run table should build one turn_token relic item")
		return
	var relic_item: Dictionary = relic_items[0]
	_assert_eq(relic_item.get("name"), RelicCatalog.display_name("turn_token"), "run table relic item uses relic catalog name")
	_assert_eq(relic_item.get("description"), RelicCatalog.short_description("turn_token"), "run table relic item uses relic catalog description")
	var pickup := RunTableState.pickup_summary({}, {"choice": "potion", "potion_ids": ["guard_potion"]})
	var lines: Array = pickup.get("lines", [])
	var found := false
	for line in lines:
		if str(line).contains("Guard Potion"):
			found = true
	if not found:
		failures.append("pickup summary should localize guard potion through PotionCatalog.display_key")

func _check_reward_shop_object_payloads() -> void:
	var shop_choices := ShopOfferCatalog.relic_offer_choices({
		"seed_text": "runtime-display-shop",
		"relic_ids": []
	}, 1)
	if shop_choices.is_empty():
		failures.append("shop should produce at least one relic object choice")
	else:
		_assert_object_payload(shop_choices[0] as Dictionary, "shop relic offer")
	var reward_scene := RewardSceneScript.new()
	var reward_items: Array[Dictionary] = reward_scene._build_reward_items({"relic_ids": ["turn_token"]})
	reward_scene.queue_free()
	var found_relic := false
	for item in reward_items:
		if str((item as Dictionary).get("kind", "")) == "relic":
			found_relic = true
			_assert_object_payload(item as Dictionary, "reward relic item")
	if not found_relic:
		failures.append("reward should produce a relic object item")
	var mixed_shop_choices := ShopOfferCatalog.shop_v2_offer_choices({
		"seed_text": "runtime-display-shop-v2",
		"relic_ids": []
	}, 0)
	var found_service_payload := false
	for choice in mixed_shop_choices:
		var choice_dict: Dictionary = choice
		if str(choice_dict.get("slot_kind", "")) == "service":
			found_service_payload = true
			_assert_eq(choice_dict.get("object_kind"), "shop_item", "shop service object kind")
			var service_display: Dictionary = choice_dict.get("object_display", {})
			if service_display.is_empty():
				failures.append("shop service should include object_display")
			elif str(service_display.get("object_id", "")) == "":
				failures.append("shop service display should include object_id")
	if not found_service_payload:
		failures.append("shop v2 should include a service object payload")

func _assert_object_payload(value: Dictionary, label: String) -> void:
	_assert_eq(value.get("object_kind"), "relic", label + " object kind")
	if str(value.get("object_id", "")) == "":
		failures.append(label + " should include object_id")
	var object_display: Dictionary = value.get("object_display", {})
	if object_display.is_empty():
		failures.append(label + " should include object_display")
		return
	_assert_eq(object_display.get("object_id"), value.get("object_id"), label + " display object id")
	_assert_eq(object_display.get("object_kind"), "relic", label + " display object kind")
	if str(object_display.get("name", "")) == "":
		failures.append(label + " display should include name")
	if str(object_display.get("icon_id", "")) == "":
		failures.append(label + " display should include icon")

func _finish() -> void:
	if failures.is_empty():
		print("runtime display bridge smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
