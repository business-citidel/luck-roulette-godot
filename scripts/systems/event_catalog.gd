class_name EventCatalog
extends RefCounted

const RunChoice := preload("res://scripts/run/run_choice.gd")
const ContentMetadata := preload("res://scripts/systems/content_metadata.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const EVENT_STANDARD := "standard_table"

const ACTION_RESULT := "result"
const ACTION_DICE_CHECK := "dice_check"
const ACTION_ROULETTE_CHECK := "roulette_check"
const ACTION_CARD_DRAW := "card_draw"

const FIRST_PACK_IDS := [
	"sealed_side_box",
	"blood_red_receipt",
	"house_marker_loan",
	"backroom_die_test",
	"crooked_wheel_bet",
	"dealer_draw_three",
	"coin_gate_toll",
	"black_wax_contract",
	"quiet_claim_slips",
	"soft_house_favor"
]

const SECOND_PACK_IDS := [
	"healing_catch",
	"warning_map_scrap",
	"red_pin_detour",
	"mirror_token_copy",
	"relic_pouch_ritual",
	"stitched_body_bargain",
	"future_claim_stamp",
	"shop_coupon_tag",
	"rest_voucher_note",
	"banked_luck_token"
]

const THIRD_PACK_IDS := [
	"locked_coin_chest",
	"waxed_relic_crate",
	"stained_claim_locker",
	"missing_bail_contract",
	"three_mark_bounty",
	"sealed_floor_oath",
	"midnight_side_bet",
	"loaded_cup_throw",
	"shrouded_receipt",
	"wrong_seat_marker"
]

const MYSTERY_POOL_IDS := [
	"blood_red_receipt",
	"house_marker_loan",
	"coin_gate_toll",
	"soft_house_favor",
	"healing_catch",
	"mirror_token_copy",
	"stitched_body_bargain",
	"rest_voucher_note",
	"shrouded_receipt",
	"wrong_seat_marker"
]

const CHEST_POOL_IDS := [
	"sealed_side_box",
	"quiet_claim_slips",
	"relic_pouch_ritual",
	"locked_coin_chest",
	"waxed_relic_crate",
	"stained_claim_locker"
]

const QUEST_POOL_IDS := [
	"warning_map_scrap",
	"red_pin_detour",
	"black_wax_contract",
	"future_claim_stamp",
	"missing_bail_contract",
	"three_mark_bounty",
	"sealed_floor_oath"
]

const GAMBLE_POOL_IDS := [
	"backroom_die_test",
	"crooked_wheel_bet",
	"dealer_draw_three",
	"shop_coupon_tag",
	"banked_luck_token",
	"midnight_side_bet",
	"loaded_cup_throw"
]

const KNOWN_EVENT_IDS := [
	EVENT_STANDARD,
	"sealed_side_box",
	"blood_red_receipt",
	"house_marker_loan",
	"backroom_die_test",
	"crooked_wheel_bet",
	"dealer_draw_three",
	"coin_gate_toll",
	"black_wax_contract",
	"quiet_claim_slips",
	"soft_house_favor",
	"healing_catch",
	"warning_map_scrap",
	"red_pin_detour",
	"mirror_token_copy",
	"relic_pouch_ritual",
	"stitched_body_bargain",
	"future_claim_stamp",
	"shop_coupon_tag",
	"rest_voucher_note",
	"banked_luck_token",
	"locked_coin_chest",
	"waxed_relic_crate",
	"stained_claim_locker",
	"missing_bail_contract",
	"three_mark_bounty",
	"sealed_floor_oath",
	"midnight_side_bet",
	"loaded_cup_throw",
	"shrouded_receipt",
	"wrong_seat_marker"
]

const EVENT_ALIASES := {
	"closed_box": "sealed_side_box",
	"sealed_dealer_cards": "dealer_draw_three",
	"risky_loan": "house_marker_loan",
	"dice_challenge": "backroom_die_test",
	"roulette_wager": "crooked_wheel_bet",
	"dealer_favor": "soft_house_favor",
	"ambush_choice": "red_pin_detour",
	"future_reward_modifier": "future_claim_stamp"
}

static func first_pack_event_ids() -> Array[String]:
	var result: Array[String] = []
	for id in FIRST_PACK_IDS:
		result.append(str(id))
	return result

static func second_pack_event_ids() -> Array[String]:
	var result: Array[String] = []
	for id in SECOND_PACK_IDS:
		result.append(str(id))
	return result

static func third_pack_event_ids() -> Array[String]:
	var result: Array[String] = []
	for id in THIRD_PACK_IDS:
		result.append(str(id))
	return result

static func mystery_event_ids() -> Array[String]:
	return _string_array(MYSTERY_POOL_IDS)

static func chest_event_ids() -> Array[String]:
	return _string_array(CHEST_POOL_IDS)

static func quest_event_ids() -> Array[String]:
	return _string_array(QUEST_POOL_IDS)

static func gamble_event_ids() -> Array[String]:
	return _string_array(GAMBLE_POOL_IDS)

static func catalog_event_ids() -> Array[String]:
	var result := first_pack_event_ids()
	for id in second_pack_event_ids():
		result.append(id)
	for id in third_pack_event_ids():
		result.append(id)
	return result

static func pack_event_ids(pool_id: String) -> Array[String]:
	match str(pool_id):
		"first_pack":
			return first_pack_event_ids()
		"second_pack":
			return second_pack_event_ids()
		"third_pack":
			return third_pack_event_ids()
		"catalog":
			return catalog_event_ids()
		"mystery", "event_mystery":
			return mystery_event_ids()
		"chest", "event_chest":
			return chest_event_ids()
		"quest", "event_quest":
			return quest_event_ids()
		"gamble", "event_gamble":
			return gamble_event_ids()
		_:
			return first_pack_event_ids()

static func _string_array(source: Array) -> Array[String]:
	var result: Array[String] = []
	for id in source:
		result.append(str(id))
	return result

static func has_event(event_id: String) -> bool:
	var id := str(event_id)
	if EVENT_ALIASES.has(id):
		id = str(EVENT_ALIASES[id])
	return KNOWN_EVENT_IDS.has(id)

static func normalize_event_id(event_id: String) -> String:
	var id := str(event_id)
	if EVENT_ALIASES.has(id):
		id = str(EVENT_ALIASES[id])
	if KNOWN_EVENT_IDS.has(id):
		return id
	return EVENT_STANDARD

static func configured_event_id(run_state: Dictionary, map_result: Dictionary) -> String:
	var explicit := str(map_result.get("event_id", map_result.get("force_event_id", "")))
	if explicit != "":
		return normalize_event_id(explicit)
	var encounter_id := str(map_result.get("encounter_id", ""))
	if has_event(encounter_id) and encounter_id != EVENT_STANDARD:
		return normalize_event_id(encounter_id)
	var pool_id := str(map_result.get("event_pool", ""))
	if pool_id == "first_pack":
		return pick_event_id(run_state, map_result, first_pack_event_ids())
	if pool_id == "second_pack":
		return pick_event_id(run_state, map_result, second_pack_event_ids())
	if pool_id != "":
		return pick_event_id(run_state, map_result, pack_event_ids(pool_id))
	return EVENT_STANDARD

static func pick_first_pack_event_id(run_state: Dictionary, map_result: Dictionary) -> String:
	return pick_event_id(run_state, map_result, first_pack_event_ids())

static func pick_event_id(run_state: Dictionary, map_result: Dictionary, ids: Array[String]) -> String:
	if ids.is_empty():
		return EVENT_STANDARD
	var seed_text := str(run_state.get("seed_text", ""))
	seed_text += ":" + str(map_result.get("node_id", map_result.get("id", "event")))
	seed_text += ":" + str(map_result.get("encounter_id", "event"))
	seed_text += ":" + str(map_result.get("node_index", map_result.get("index", 0)))
	var index: int = abs(hash(seed_text)) % ids.size()
	return ids[index]

static func get_profile(event_id: String) -> Dictionary:
	var id := normalize_event_id(event_id)
	var profile: Dictionary
	match id:
		"sealed_side_box":
			profile = _sealed_side_box()
		"blood_red_receipt":
			profile = _blood_red_receipt()
		"house_marker_loan":
			profile = _house_marker_loan()
		"backroom_die_test":
			profile = _backroom_die_test()
		"crooked_wheel_bet":
			profile = _crooked_wheel_bet()
		"dealer_draw_three":
			profile = _dealer_draw_three()
		"coin_gate_toll":
			profile = _coin_gate_toll()
		"black_wax_contract":
			profile = _black_wax_contract()
		"quiet_claim_slips":
			profile = _quiet_claim_slips()
		"soft_house_favor":
			profile = _soft_house_favor()
		"healing_catch":
			profile = _healing_catch()
		"warning_map_scrap":
			profile = _warning_map_scrap()
		"red_pin_detour":
			profile = _red_pin_detour()
		"mirror_token_copy":
			profile = _mirror_token_copy()
		"relic_pouch_ritual":
			profile = _relic_pouch_ritual()
		"stitched_body_bargain":
			profile = _stitched_body_bargain()
		"future_claim_stamp":
			profile = _future_claim_stamp()
		"shop_coupon_tag":
			profile = _shop_coupon_tag()
		"rest_voucher_note":
			profile = _rest_voucher_note()
		"banked_luck_token":
			profile = _banked_luck_token()
		"locked_coin_chest":
			profile = _locked_coin_chest()
		"waxed_relic_crate":
			profile = _waxed_relic_crate()
		"stained_claim_locker":
			profile = _stained_claim_locker()
		"missing_bail_contract":
			profile = _missing_bail_contract()
		"three_mark_bounty":
			profile = _three_mark_bounty()
		"sealed_floor_oath":
			profile = _sealed_floor_oath()
		"midnight_side_bet":
			profile = _midnight_side_bet()
		"loaded_cup_throw":
			profile = _loaded_cup_throw()
		"shrouded_receipt":
			profile = _shrouded_receipt()
		"wrong_seat_marker":
			profile = _wrong_seat_marker()
		_:
			profile = _standard_table()
	return _localized_profile(id, profile)

static func get_event(event_id: String) -> Dictionary:
	var id := normalize_event_id(event_id)
	return ContentMetadata.apply(get_profile(id), event_metadata(id))

static func event_metadata(event_id: String) -> Dictionary:
	var id := normalize_event_id(event_id)
	var tags := ["event"]
	for tag in _event_pool_tags(id):
		if not tags.has(tag):
			tags.append(tag)
	return ContentMetadata.build(
		id,
		id,
		id != EVENT_STANDARD,
		id != EVENT_STANDARD,
		ContentMetadata.runtime_event_visual_ready(id),
		_event_rarity(id),
		tags
	)

static func _event_pool_tags(event_id: String) -> Array[String]:
	var result: Array[String] = []
	if MYSTERY_POOL_IDS.has(event_id):
		result.append("mystery")
	if CHEST_POOL_IDS.has(event_id):
		result.append("chest")
	if QUEST_POOL_IDS.has(event_id):
		result.append("quest")
	if GAMBLE_POOL_IDS.has(event_id):
		result.append("gamble")
	if FIRST_PACK_IDS.has(event_id):
		result.append("first_pack")
	if SECOND_PACK_IDS.has(event_id):
		result.append("second_pack")
	if THIRD_PACK_IDS.has(event_id):
		result.append("third_pack")
	return result

static func _event_rarity(event_id: String) -> String:
	if QUEST_POOL_IDS.has(event_id):
		return ContentMetadata.RARITY_RARE
	if CHEST_POOL_IDS.has(event_id) or GAMBLE_POOL_IDS.has(event_id):
		return ContentMetadata.RARITY_UNCOMMON
	return ContentMetadata.RARITY_COMMON

static func _profile(title: String, body: String, choices: Array[Dictionary], extra: Dictionary = {}) -> Dictionary:
	var profile := {
		"title": title,
		"body": body,
		"choices": choices
	}
	for key in extra.keys():
		profile[key] = extra[key]
	return profile

static func _choice(id: String, label: String, note: String, effect: String, action: String, result_template: Dictionary = {}, extra: Dictionary = {}) -> Dictionary:
	var choice := RunChoice.create(id, label, note, effect, {})
	choice["action"] = action
	if not result_template.is_empty():
		choice["result_template"] = result_template.duplicate(true)
	for key in extra.keys():
		choice[key] = extra[key]
	return choice

static func _result(choice_id: String, gold_delta: int, hp_delta: int, title: String, body: String, relic_reward_count: int = 0, next_combat_mods: Array = [], run_upgrades: Dictionary = {}) -> Dictionary:
	return {
		"accepted": true,
		"choice": choice_id,
		"gold_delta": gold_delta,
		"hp_delta": hp_delta,
		"relic_ids": [],
		"relic_reward_count": relic_reward_count,
		"next_combat_mods": next_combat_mods.duplicate(true),
		"run_upgrades": run_upgrades.duplicate(true),
		"result_title": title,
		"result_body": body
	}

static func _dice_table(fail: Dictionary, success: Dictionary, great: Dictionary) -> Dictionary:
	return {
		"fail": fail.duplicate(true),
		"success": success.duplicate(true),
		"great": great.duplicate(true)
	}

static func _roulette_table(bust: Dictionary, safe: Dictionary, profit: Dictionary, overdrive: Dictionary, jackpot: Dictionary) -> Dictionary:
	return {
		"bust": bust.duplicate(true),
		"safe": safe.duplicate(true),
		"default": safe.duplicate(true),
		"profit": profit.duplicate(true),
		"overdrive": overdrive.duplicate(true),
		"jackpot": jackpot.duplicate(true)
	}

static func _localized_profile(event_id: String, profile: Dictionary) -> Dictionary:
	if UiText.current_locale() != "en":
		return profile
	var result := profile.duplicate(true)
	result["title"] = _title_from_id(event_id)
	result["body"] = _event_body_en(event_id)
	var localized_choices: Array[Dictionary] = []
	for choice in profile.get("choices", []):
		if choice is Dictionary:
			localized_choices.append(_localized_choice(choice as Dictionary))
	result["choices"] = localized_choices
	var pages: Array[Dictionary] = []
	var source_pages: Array = profile.get("story_pages", [])
	if not source_pages.is_empty():
		for i in range(source_pages.size()):
			pages.append({
				"title": result["title"],
				"body": _event_story_body_en(event_id, i)
			})
		result["story_pages"] = pages
	return result

static func _localized_choice(choice: Dictionary) -> Dictionary:
	var result := choice.duplicate(true)
	var id := str(result.get("id", "choice"))
	var action := str(result.get("action", ACTION_RESULT))
	var template: Dictionary = result.get("result_template", {})
	result["label"] = _title_from_id(id)
	result["note"] = _choice_note_en(action, result)
	if not template.is_empty():
		result["result_template"] = _localized_result(template, id)
	result["effect"] = _choice_effect_en(action, result)
	if result.has("dice_result_table"):
		result["dice_result_table"] = _localized_result_table(result.get("dice_result_table", {}))
	if result.has("roulette_result_table"):
		result["roulette_result_table"] = _localized_result_table(result.get("roulette_result_table", {}))
	return result

static func _localized_result_table(table: Dictionary) -> Dictionary:
	var result := {}
	for key in table.keys():
		var value: Variant = table[key]
		if value is Dictionary:
			result[key] = _localized_result(value as Dictionary, str(key))
		else:
			result[key] = value
	return result

static func _localized_result(result_template: Dictionary, fallback_id: String) -> Dictionary:
	var result := result_template.duplicate(true)
	result["result_title"] = _title_from_id(str(result.get("choice", fallback_id)))
	result["result_body"] = _result_body_en(result)
	return result

static func _localized_card_deck(deck_id: String, deck: Array[Dictionary]) -> Array[Dictionary]:
	if UiText.current_locale() != "en":
		return deck
	var result: Array[Dictionary] = []
	for i in range(deck.size()):
		var card := deck[i].duplicate(true)
		var token_kind := str(card.get("token_kind", "gold"))
		card["label"] = _card_label_en(token_kind, i)
		if card.has("result_template"):
			card["result_template"] = _localized_result(card.get("result_template", {}), token_kind)
			card["effect"] = _effect_from_result(card.get("result_template", {}))
		result.append(card)
	return result

static func _event_body_en(event_id: String) -> String:
	var tags := _event_pool_tags(event_id)
	if tags.has("chest"):
		return "A sealed object waits on the table. Choose what to claim and what to risk."
	if tags.has("quest"):
		return "A contract slip changes the route ahead. Choose how to mark the next table."
	if tags.has("gamble"):
		return "A gambling side table opens. Dice, cards, or the wheel will settle the slip."
	if tags.has("mystery"):
		return "A strange table offer appears. The payout is clear, but the house keeps its own price."
	return "A house event opens on the table. Choose one slip to settle it."

static func _event_story_body_en(event_id: String, page_index: int) -> String:
	if page_index <= 0:
		return _event_body_en(event_id)
	return "The dealer waits while the next slip narrows the choice."

static func _choice_note_en(action: String, choice: Dictionary) -> String:
	match action:
		ACTION_DICE_CHECK:
			return "Roll 2d6 to settle this slip."
		ACTION_ROULETTE_CHECK:
			return "Spin the event wheel and accept the stopped slot."
		ACTION_CARD_DRAW:
			return "Draw one facedown slip from the table."
		_:
			if int(choice.get("required_gold", 0)) > 0:
				return "Spend gold to settle this offer."
			if int(choice.get("required_hp", 0)) > 0:
				return "Pay HP to settle this offer."
			return "Settle this slip immediately."

static func _choice_effect_en(action: String, choice: Dictionary) -> String:
	var cost_parts: Array[String] = []
	var cost_gold := int(choice.get("cost_gold", 0))
	var cost_hp := int(choice.get("cost_hp", 0))
	if cost_gold > 0:
		cost_parts.append("-" + str(cost_gold) + " Gold")
	if cost_hp > 0:
		cost_parts.append("-" + str(cost_hp) + " HP")
	var base := ""
	match action:
		ACTION_DICE_CHECK:
			base = _table_effect(choice.get("dice_result_table", {}), "Dice check")
		ACTION_ROULETTE_CHECK:
			base = _table_effect(choice.get("roulette_result_table", {}), "Wheel result")
		ACTION_CARD_DRAW:
			base = "Draw a slip"
		_:
			base = _effect_from_result(choice.get("result_template", {}))
	if cost_parts.is_empty():
		return base
	return ", ".join(cost_parts) + " / " + base

static func _table_effect(table: Dictionary, fallback: String) -> String:
	if table.is_empty():
		return fallback
	var parts: Array[String] = []
	if table.has("success"):
		parts.append("8+ " + _short_effect_from_result(table.get("success", {})))
	if table.has("great"):
		parts.append("10+ " + _short_effect_from_result(table.get("great", {})))
	if parts.is_empty() and table.has("jackpot"):
		parts.append("Jackpot " + _short_effect_from_result(table.get("jackpot", {})))
	if parts.is_empty() and table.has("profit"):
		parts.append("Profit " + _short_effect_from_result(table.get("profit", {})))
	if parts.is_empty():
		return fallback
	return " / ".join(parts)

static func _short_effect_from_result(result_template: Dictionary) -> String:
	if result_template.is_empty():
		return "varies"
	var gold_delta := int(result_template.get("gold_delta", 0))
	var hp_delta := int(result_template.get("hp_delta", 0))
	var relic_count := int(result_template.get("relic_reward_count", 0))
	var relics: Array = result_template.get("relic_ids", [])
	if relic_count > 0 or not relics.is_empty():
		return "Relic" if gold_delta == 0 else "Gold+Relic"
	if gold_delta > 0:
		return "Gold"
	if gold_delta < 0:
		return "Cost"
	if hp_delta > 0:
		return "Heal"
	if hp_delta < 0:
		return "HP loss"
	if not (result_template.get("next_combat_mods", []) as Array).is_empty():
		return "Prep"
	if not (result_template.get("run_upgrades", {}) as Dictionary).is_empty():
		return "Upgrade"
	return "No change"

static func _effect_from_result(result_template: Dictionary) -> String:
	if result_template.is_empty():
		return "Varies"
	var parts: Array[String] = []
	var gold_delta := int(result_template.get("gold_delta", 0))
	var hp_delta := int(result_template.get("hp_delta", 0))
	var relic_count := int(result_template.get("relic_reward_count", 0))
	var relics: Array = result_template.get("relic_ids", [])
	var mods: Array = result_template.get("next_combat_mods", [])
	var upgrades: Dictionary = result_template.get("run_upgrades", {})
	if gold_delta != 0:
		parts.append(("+" if gold_delta > 0 else "") + str(gold_delta) + " Gold")
	if hp_delta != 0:
		parts.append(("+" if hp_delta > 0 else "") + str(hp_delta) + " HP")
	if relic_count > 0 or not relics.is_empty():
		parts.append("Relic")
	if not mods.is_empty():
		parts.append("Next combat mark")
	if not upgrades.is_empty():
		parts.append("Run upgrade")
	if parts.is_empty():
		return "No change"
	return ", ".join(parts)

static func _result_body_en(result_template: Dictionary) -> String:
	var effect := _effect_from_result(result_template)
	if effect == "No change":
		return "The slip closes without changing the ledger."
	return "The slip closes. " + effect + "."

static func _card_label_en(token_kind: String, index: int) -> String:
	match token_kind:
		"relic":
			return "Green Claim"
		"blood":
			return "Thorn Slip"
		"danger":
			return "Black Bond"
		"heal":
			return "Medicine Slip"
		"gold":
			return "Blank Claim" if index > 0 else "Coin Claim"
		_:
			return "Sealed Slip"

static func _title_from_id(id: String) -> String:
	var words: Array[String] = []
	for raw_word in id.split("_", false):
		var word := str(raw_word)
		if word == "":
			continue
		words.append(word.substr(0, 1).to_upper() + word.substr(1).to_lower())
	if words.is_empty():
		return "Event Slip"
	return " ".join(words)

static func get_card_deck(deck_id: String) -> Array[Dictionary]:
	var deck: Array[Dictionary]
	match str(deck_id):
		"relic_pouch":
			deck = _relic_pouch_deck(false)
		"relic_pouch_peek":
			deck = _relic_pouch_deck(true)
		_:
			deck = []
	return _localized_card_deck(deck_id, deck)

static func _deck_card(label: String, effect: String, token_kind: String, result_template: Dictionary) -> Dictionary:
	return {
		"label": label,
		"effect": effect,
		"token_kind": token_kind,
		"result_template": result_template.duplicate(true)
	}

static func _relic_pouch_deck(peeked: bool) -> Array[Dictionary]:
	var deck: Array[Dictionary] = [
		_deck_card("녹색 보관증", "유물", "relic", _result("relic_pouch_ritual", 0, 0, "녹색 보관증", "주머니 안쪽 번호표가 숨은 유물을 불러냈다.", 1)),
		_deck_card("가시 전표", "-3 HP, 유물", "blood", _result("relic_pouch_ritual", 0, -3, "가시 전표", "손끝이 찢겼지만 주머니는 유물을 놓쳤다.", 1)),
		_deck_card("빈 보관증", "+5 골드", "gold", _result("relic_pouch_ritual", 5, 0, "빈 보관증", "유물 대신 오래된 보증금만 돌아왔다.")),
		_deck_card("검은 보증서", "유물, 다음 피해 +2", "danger", _result("relic_pouch_ritual", 0, 0, "검은 보증서", "좋은 물건이지만 하우스의 표식이 함께 따라왔다.", 1, [{
			"id": "relic_pouch_black_warranty",
			"enemy_damage_delta": 2,
			"description": "Relic pouch: took a marked relic, next enemy hit is sharper."
		}])),
		_deck_card("약 냄새 나는 천", "+6 HP", "heal", _result("relic_pouch_ritual", 0, 6, "약 냄새 나는 천", "유물은 아니지만 상처를 단단히 묶었다."))
	]
	if peeked:
		deck.append(_deck_card("숨은 녹색 유물", "유물, +6 골드", "relic", _result("relic_pouch_ritual", 6, 0, "숨은 녹색 유물", "돈을 내고 들여다본 덕분에 가장 깊은 보관증을 꺼냈다.", 1)))
	return deck

static func _standard_table() -> Dictionary:
	return _profile("사건 전표", "수상한 제안이 올라왔다. 하나를 고르면 전표가 닫힌다.", [
		_choice("event_gold", "소문값", "작은 골드를 챙긴다.", "+8 골드", ACTION_RESULT, _result("event_gold", 8, 0, "소문값 정산", "위험은 없지만 전표도 얇다."), {"icon_kind": "gold"}),
		_choice("event_relic_trade", "속임수 유물", "HP를 내고 유물을 산다.", "-4 HP, 유물", ACTION_RESULT, _result("event_relic_trade", 0, -4, "속임수 유물", "피로 쓴 서명이 봉인을 열었다.", 1), {"required_hp": 5, "icon_kind": "relic"}),
		_choice("event_risk_gold", "뜨거운 판", "큰 골드와 다음 피해 증가를 받는다.", "+18 골드, 다음 피해 +2", ACTION_RESULT, _result("event_risk_gold", 18, 0, "뜨거운 판", "많은 코인을 챙겼지만 다음 상대가 강해진다.", 0, [{
			"id": "event_hot_table",
			"enemy_damage_delta": 2,
			"description": "Event trade: richer next node, but the next enemy hit is sharper."
		}]), {"icon_kind": "danger"})
	])

static func _sealed_side_box() -> Dictionary:
	return _profile("봉인된 전표 더미", "상자 안에는 뒤집힌 전표들이 있다. 딜러는 한 장만 가져가라고 손짓한다.", [
		_choice("sealed_cards_draw", "전표 뽑기", "뒤집힌 전표 다섯 장 중 하나를 고른다.", "랜덤 보상/손실", ACTION_CARD_DRAW, {}, {"card_peeked": false, "icon_kind": "card"}),
		_choice("sealed_cards_peek", "살짝 훔쳐보기", "3 골드를 내고 더 좋은 전표가 섞이길 빈다.", "-3 골드, 보상폭 증가", ACTION_CARD_DRAW, {}, {"card_peeked": true, "required_gold": 3, "cost_gold": 3, "icon_kind": "card"}),
		_choice("sealed_cards_leave", "상자 닫기", "봉인을 건드리지 않고 작은 값을 챙긴다.", "+5 골드", ACTION_RESULT, _result("sealed_cards_leave", 5, 0, "상자를 닫았다", "큰 봉인은 건드리지 않고 작은 코인만 챙긴다."), {"icon_kind": "gold"})
	])

static func _blood_red_receipt() -> Dictionary:
	return _profile("붉은 피값 전표", "붉은 잉크가 아직 마르지 않았다. 대가는 분명하지만 보상도 선명하다.", [
		_choice("blood_sign_relic", "붉게 서명", "HP를 내고 봉인을 연다.", "-4 HP, 유물", ACTION_RESULT, _result("blood_sign_relic", 0, -4, "피로 연 봉인", "붉은 서명이 유물 하나를 깨웠다.", 1), {"required_hp": 5, "icon_kind": "blood"}),
		_choice("blood_take_vial", "응급 유리병", "전표 옆 약병만 챙긴다.", "+5 HP", ACTION_RESULT, _result("blood_take_vial", 0, 5, "응급 유리병", "쓰지만 효과는 확실했다."), {"icon_kind": "heal"}),
		_choice("blood_refuse", "전표 접기", "피값을 거절한다.", "변화 없음", ACTION_RESULT, _result("blood_refuse", 0, 0, "붉은 전표를 접었다", "딜러가 웃지만 아무것도 가져가지 못했다."))
	])

static func _house_marker_loan() -> Dictionary:
	return _profile("하우스 차용증", "집 문양이 찍힌 차용증이 테이블에 놓인다. 지금은 달콤하고 다음은 쓰다.", [
		_choice("loan_accept", "큰 차용증", "돈을 받고 다음 상대에게 표식이 넘어간다.", "+18 골드, 다음 피해 +2", ACTION_RESULT, _result("loan_accept", 18, 0, "차용증 수령", "코인은 묵직하지만 다음 적이 같은 표식을 들고 온다.", 0, [{
			"id": "house_marker_loan",
			"enemy_damage_delta": 2,
			"description": "Event loan: gain gold now, next enemy hit is sharper."
		}]), {"icon_kind": "danger"}),
		_choice("loan_small", "작은 선불", "위험 표식 없이 조금만 받는다.", "+8 골드", ACTION_RESULT, _result("loan_small", 8, 0, "작은 선불", "딜러가 미련 없이 작은 봉투를 밀어준다."), {"icon_kind": "gold"}),
		_choice("loan_decline", "서명 거부", "차용증을 밀어낸다.", "변화 없음", ACTION_RESULT, _result("loan_decline", 0, 0, "차용증 거부", "빚은 늘지 않았다. 코인도 늘지 않았다."))
	])

static func _backroom_die_test() -> Dictionary:
	return _profile("뒷방 주사위 시험", "딜러가 낡은 쟁반을 밀어 넣는다. 주사위 두 개를 굴려 합계로 전표를 판정한다.", [
		_choice("backroom_die_roll", "판정 받기", "2d6 합계로 결과를 정한다.", "8+ 성공 / 10+ 대성공", ACTION_DICE_CHECK, {}, {"dice_bonus": 0, "icon_kind": "dice"}),
		_choice("backroom_die_cheat", "슬쩍 밀기", "작은 비용으로 합계를 한 칸 올린다.", "-3 골드, 합계 +1", ACTION_DICE_CHECK, {}, {"dice_bonus": 1, "required_gold": 3, "cost_gold": 3, "icon_kind": "dice"}),
		_choice("backroom_die_leave", "사양하기", "딜러의 시선을 피하고 작은 값을 챙긴다.", "+4 골드", ACTION_RESULT, _result("backroom_die_leave", 4, 0, "조용한 퇴장", "큰 판은 피했다. 대신 작은 소문값만 챙긴다."), {"icon_kind": "gold"})
	])

static func _crooked_wheel_bet() -> Dictionary:
	return _profile("비뚤어진 룰렛", "딜러가 작은 바퀴를 꺼낸다. 판돈을 정하면 바퀴가 한 번만 돈다.", [
		_choice("crooked_wheel_small", "작게 걸기", "낮은 판돈으로 안전하게 돌린다.", "실패 없음 / 최대 +18 골드", ACTION_ROULETTE_CHECK, {}, {"roulette_wager": "small", "icon_kind": "roulette"}),
		_choice("crooked_wheel_risky", "크게 걸기", "위험한 칸까지 열고 크게 노린다.", "실패 시 -5 HP / 대박 유물", ACTION_ROULETTE_CHECK, {}, {"roulette_wager": "risky", "icon_kind": "roulette"}),
		_choice("crooked_wheel_leave", "그만두기", "바퀴를 건드리지 않고 물러난다.", "+3 골드", ACTION_RESULT, _result("crooked_wheel_leave", 3, 0, "바퀴를 덮었다", "판돈을 걸지 않고 작은 코인만 챙긴다."), {"icon_kind": "gold"})
	])

static func _dealer_draw_three() -> Dictionary:
	return _profile("딜러의 세 장 전표", "딜러가 전표 더미를 낮게 펼친다. 손끝이 닿는 순간 한 장만 남는다.", [
		_choice("dealer_cards_draw", "한 장 뽑기", "뒤집힌 전표에서 한 장을 고른다.", "랜덤 보상/손실", ACTION_CARD_DRAW, {}, {"card_peeked": false, "icon_kind": "card"}),
		_choice("dealer_cards_peek", "패 훔쳐보기", "코인을 내고 더 좋은 패를 섞는다.", "-3 골드, 보상폭 증가", ACTION_CARD_DRAW, {}, {"card_peeked": true, "required_gold": 3, "cost_gold": 3, "icon_kind": "card"}),
		_choice("dealer_cards_close", "전표 덮기", "손대지 않고 딜러 팁만 받는다.", "+5 골드", ACTION_RESULT, _result("dealer_cards_close", 5, 0, "전표를 덮었다", "딜러가 작은 팁을 던져주고 판을 치운다."), {"icon_kind": "gold"})
	])

static func _coin_gate_toll() -> Dictionary:
	return _profile("동전문 통행세", "황동 문패가 길을 막는다. 값을 치르면 다음 판이 조금 순해진다.", [
		_choice("coin_gate_pay", "통행세 지불", "코인을 내고 다음 적의 기세를 낮춘다.", "-10 골드, 다음 피해 -2", ACTION_RESULT, _result("coin_gate_pay", -10, 0, "통행세 지불", "문패가 부드럽게 돌아간다. 다음 판의 날이 무뎌졌다.", 0, [{
			"id": "coin_gate_toll",
			"enemy_damage_delta": -2,
			"description": "Event toll: paid gold to soften the next enemy hit."
		}]), {"required_gold": 10}),
		_choice("coin_gate_force", "억지로 밀기", "몸으로 문을 열고 떨어진 코인을 줍는다.", "+8 골드, -3 HP", ACTION_RESULT, _result("coin_gate_force", 8, -3, "억지 통과", "문은 열렸지만 어깨가 욱신거린다."), {"required_hp": 4}),
		_choice("coin_gate_turn", "돌아가기", "문패를 건드리지 않는다.", "변화 없음", ACTION_RESULT, _result("coin_gate_turn", 0, 0, "길을 돌렸다", "돈도 피도 잃지 않았다."))
	])

static func _black_wax_contract() -> Dictionary:
	return _profile("검은 왁스 계약", "검은 봉인이 찍힌 계약서가 미세하게 떨린다.", [
		_choice("black_wax_sign", "계약 서명", "유물을 받고 다음 전투 표식을 감수한다.", "유물, 다음 피해 +2", ACTION_RESULT, _result("black_wax_sign", 0, 0, "검은 계약", "계약서 안쪽에서 유물이 굴러 나왔다.", 1, [{
			"id": "black_wax_contract",
			"enemy_damage_delta": 2,
			"description": "Black wax contract: relic now, sharper next enemy hit."
		}])),
		_choice("black_wax_tear", "봉인 뜯기", "계약을 찢고 안쪽 코인만 챙긴다.", "+6 골드", ACTION_RESULT, _result("black_wax_tear", 6, 0, "봉인을 뜯었다", "문장은 사라지고 작은 코인만 남았다.")),
		_choice("black_wax_leave", "읽지 않기", "검은 글자를 피한다.", "변화 없음", ACTION_RESULT, _result("black_wax_leave", 0, 0, "계약 회피", "검은 봉인은 그대로 테이블에 남았다."))
	])

static func _quiet_claim_slips() -> Dictionary:
	return _profile("조용한 청구 전표", "세 장의 청구서가 가지런히 놓였다. 위험은 없지만 하나만 가져갈 수 있다.", [
		_choice("claim_gold", "코인 청구", "코인 묶음을 청구한다.", "+10 골드", ACTION_RESULT, _result("claim_gold", 10, 0, "코인 청구", "청구서가 코인으로 정산됐다.")),
		_choice("claim_medicine", "약품 청구", "숨겨진 응급품을 청구한다.", "+5 HP", ACTION_RESULT, _result("claim_medicine", 0, 5, "약품 청구", "낡은 약 냄새가 상처를 덮는다.")),
		_choice("claim_relic", "유물 청구", "작은 유물 보관증을 고른다.", "유물", ACTION_RESULT, _result("claim_relic", 0, 0, "유물 청구", "보관증의 번호가 숨은 유물을 불러냈다.", 1))
	])

static func _soft_house_favor() -> Dictionary:
	return _profile("하우스의 작은 호의", "딜러가 낮은 목소리로 다음 판의 날을 무디게 해주겠다고 말한다.", [
		_choice("favor_buy", "코인으로 부탁", "돈을 내고 다음 전투를 부드럽게 만든다.", "-8 골드, 다음 피해 -2", ACTION_RESULT, _result("favor_buy", -8, 0, "작은 호의", "하우스가 다음 상대의 손목을 살짝 붙잡아준다.", 0, [{
			"id": "soft_house_favor",
			"enemy_damage_delta": -2,
			"description": "House favor: paid gold to soften next enemy hit."
		}]), {"required_gold": 8}),
		_choice("favor_blood", "피로 부탁", "상처를 감수하고 같은 호의를 산다.", "-3 HP, 다음 피해 -2", ACTION_RESULT, _result("favor_blood", 0, -3, "피로 산 호의", "붉은 약속이 다음 전투의 날을 무디게 한다.", 0, [{
			"id": "soft_house_favor_blood",
			"enemy_damage_delta": -2,
			"description": "House favor: paid HP to soften next enemy hit."
		}]), {"required_hp": 4}),
		_choice("favor_decline", "거절하기", "하우스의 호의를 빚지지 않는다.", "변화 없음", ACTION_RESULT, _result("favor_decline", 0, 0, "호의 거절", "호의를 받지 않은 대신 빚도 없다."))
	])

static func _healing_catch() -> Dictionary:
	return _profile("조건부 응급처치", "붕대와 약병이 올라왔다. 회복은 빠르지만 하우스는 대가를 적어둔다.", [
		_choice("catch_heal_debt", "빚진 치료", "크게 회복하고 다음 전투의 날을 조금 세운다.", "+8 HP, 다음 피해 +1", ACTION_RESULT, _result("catch_heal_debt", 0, 8, "빚진 치료", "상처는 닫혔지만 다음 적의 칼끝이 선명해졌다.", 0, [{
			"id": "healing_catch_debt",
			"enemy_damage_delta": 1,
			"description": "Healing catch: healed now, next enemy hit is sharper."
		}]), {"icon_kind": "heal"}),
		_choice("catch_paid_bandage", "돈 낸 붕대", "코인을 내고 깨끗하게 치료한다.", "-5 골드, +5 HP", ACTION_RESULT, _result("catch_paid_bandage", -5, 5, "돈 낸 붕대", "값을 치른 치료라 뒤끝은 없다."), {"required_gold": 5, "icon_kind": "heal"}),
		_choice("catch_endure", "참아내기", "치료를 미루고 작은 준비를 얻는다.", "+4 골드, 다음 피해 -1", ACTION_RESULT, _result("catch_endure", 4, 0, "참아냈다", "아픔을 넘기자 다음 판을 버틸 여지가 생겼다.", 0, [{
			"id": "healing_catch_endure",
			"enemy_damage_delta": -1,
			"description": "Healing catch: endured pain to soften next enemy hit."
		}]), {"icon_kind": "danger"})
	])

static func _warning_map_scrap() -> Dictionary:
	return _profile("경고 지도 조각", "낡은 지도 위에 붉은 핀이 박혀 있다. 다음 판의 기척이 먼저 보인다.", [
		_choice("warning_brace", "방어 준비", "경고를 믿고 다음 적의 공격을 낮춘다.", "다음 피해 -2", ACTION_RESULT, _result("warning_brace", 0, 0, "방어 준비", "붉은 핀을 따라 피할 길을 외웠다.", 0, [{
			"id": "warning_map_brace",
			"enemy_damage_delta": -2,
			"description": "Warning scrap: next enemy hit is softened."
		}]), {"icon_kind": "danger"}),
		_choice("warning_sell", "정보 팔기", "지도 조각을 코인으로 바꾼다.", "+7 골드", ACTION_RESULT, _result("warning_sell", 7, 0, "정보 판매", "경고는 사라졌고 코인만 남았다."), {"icon_kind": "gold"}),
		_choice("warning_mark_die", "눈금 표시", "주사위에 작은 표식을 남긴다.", "메인 주사위 +1", ACTION_RESULT, _result("warning_mark_die", 0, 0, "눈금 표시", "다음 전투부터 메인 주사위 해석이 조금 유리해진다.", 0, [], {"primary_die_bonus": 1.0}), {"icon_kind": "dice"})
	])

static func _red_pin_detour() -> Dictionary:
	return _profile("붉은 핀 우회로", "지름길은 피 냄새가 나고, 우회로는 돈 냄새가 난다.", [
		_choice("detour_pay", "우회로 매수", "코인을 내고 다음 매복을 무디게 한다.", "-6 골드, 다음 피해 -3", ACTION_RESULT, _result("detour_pay", -6, 0, "우회로 매수", "붉은 핀이 옆길로 옮겨졌다.", 0, [{
			"id": "red_pin_detour_pay",
			"enemy_damage_delta": -3,
			"description": "Detour: paid gold to greatly soften next enemy hit."
		}]), {"required_gold": 6, "icon_kind": "danger"}),
		_choice("detour_press", "정면 돌파", "주사위 합계로 매복을 뚫는다.", "8+ 현상금 / 10+ 유물", ACTION_DICE_CHECK, {}, {"dice_bonus": 0, "icon_kind": "dice", "dice_result_table": _dice_table(
			_result("red_pin_detour", 0, -4, "매복 실패", "붉은 핀 아래에서 매복이 터졌다. 떨어진 코인은 모두 사라졌다."),
			_result("red_pin_detour", 14, 0, "현상금 회수", "위험한 길을 뚫고 현상금을 챙겼다."),
			_result("red_pin_detour", 10, 0, "매복 역이용", "길목을 역으로 잡았다. 현상금과 숨은 유물이 같이 굴러나왔다.", 1)
		)}),
		_choice("detour_wounded", "몸으로 빠져나가기", "피를 조금 내고 떨어진 코인을 줍는다.", "+8 골드, -2 HP", ACTION_RESULT, _result("detour_wounded", 8, -2, "상처 난 우회", "길은 빠져나왔지만 소매에 피가 배었다."), {"required_hp": 3, "icon_kind": "blood"})
	], {
		"story_pages": [
			{"title": "붉은 핀 우회로", "body": "지도 위 붉은 핀이 혼자 움직인다. 딜러는 손가락으로 지름길을 가리키지만, 길 끝의 잉크는 아직 마르지 않았다."},
			{"title": "매복의 값", "body": "핀 아래에는 현상금 봉투가 묶여 있다. 우회하면 안전하고, 정면으로 가면 주사위가 길을 판정한다."}
		]
	})

static func _mirror_token_copy() -> Dictionary:
	return _profile("거울 토큰 복제", "쌍둥이 토큰이 서로를 비춘다. 완전한 복사는 아니지만 손맛은 남는다.", [
		_choice("mirror_dice", "주사위 복제", "코인을 내고 주사위 해석을 강화한다.", "-8 골드, 메인 주사위 +1", ACTION_RESULT, _result("mirror_dice", -8, 0, "주사위 복제", "거울 토큰이 메인 주사위 눈 하나를 더 크게 읽게 만든다.", 0, [], {"primary_die_bonus": 1.0}), {"required_gold": 8, "icon_kind": "dice"}),
		_choice("mirror_marble", "구슬 복제", "마킹 보너스를 조금 키운다.", "-6 골드, 구슬 보너스 +0.5", ACTION_RESULT, _result("mirror_marble", -6, 0, "구슬 복제", "쌍둥이 표식이 룰렛 칸 위에서 더 묵직해졌다.", 0, [], {"marble_bonus": 0.5}), {"required_gold": 6, "icon_kind": "roulette"}),
		_choice("mirror_decline", "거울 팔기", "복제를 포기하고 토큰을 판다.", "+5 골드", ACTION_RESULT, _result("mirror_decline", 5, 0, "거울 판매", "복제의 유혹 대신 코인이 남았다."), {"icon_kind": "gold"})
	])

static func _relic_pouch_ritual() -> Dictionary:
	return _profile("가려진 유물 주머니", "초록 주머니 안에서 금속이 서로 부딪힌다. 안을 보려면 값을 치러야 한다.", [
		_choice("pouch_blind_take", "눈감고 뽑기", "뒤집힌 보관증에서 한 장을 고른다.", "랜덤 유물/상처", ACTION_CARD_DRAW, {}, {"card_deck_id": "relic_pouch", "icon_kind": "card"}),
		_choice("pouch_paid_reveal", "값 내고 보기", "코인을 내고 더 좋은 보관증을 섞는다.", "-7 골드, 좋은 전표 추가", ACTION_CARD_DRAW, {}, {"card_deck_id": "relic_pouch_peek", "required_gold": 7, "cost_gold": 7, "icon_kind": "card"}),
		_choice("pouch_leave_tip", "주머니 닫기", "주머니를 닫고 팁만 받는다.", "+4 골드", ACTION_RESULT, _result("pouch_leave_tip", 4, 0, "주머니를 닫았다", "안쪽 소리는 계속 났지만 손은 멀쩡하다."), {"icon_kind": "gold"})
	], {
		"story_pages": [
			{"title": "가려진 유물 주머니", "body": "딜러가 초록 주머니를 흔든다. 안에서는 금속, 종이, 그리고 무언가 젖은 소리가 함께 난다."},
			{"title": "보관증 한 장", "body": "주머니 안에는 유물이 아니라 보관증이 들어 있다. 어떤 전표는 유물을 부르고, 어떤 전표는 손가락을 문다."}
		]
	})

static func _stitched_body_bargain() -> Dictionary:
	return _profile("꿰맨 몸값 흥정", "붉은 실과 동전이 같은 저울 위에 놓인다. 몸값을 어디에 쓸지 정해야 한다.", [
		_choice("body_bargain_relic", "피로 유물 받기", "큰 상처를 감수하고 유물을 받는다.", "-6 HP, 유물", ACTION_RESULT, _result("body_bargain_relic", 0, -6, "피값 유물", "상처 자리에 유물의 차가운 무게가 남았다.", 1), {"required_hp": 7, "icon_kind": "blood"}),
		_choice("body_bargain_gold", "피로 코인 받기", "작은 상처로 큰 코인을 받는다.", "-3 HP, +16 골드", ACTION_RESULT, _result("body_bargain_gold", 16, -3, "피값 코인", "붉은 실이 끊기고 코인이 쏟아졌다."), {"required_hp": 4, "icon_kind": "gold"}),
		_choice("body_bargain_mend", "실로 꿰매기", "돈을 내고 몸을 보강한다.", "-8 골드, +7 HP", ACTION_RESULT, _result("body_bargain_mend", -8, 7, "몸값 수선", "비싼 실이지만 상처는 깔끔하게 닫혔다."), {"required_gold": 8, "icon_kind": "heal"})
	])

static func _future_claim_stamp() -> Dictionary:
	return _profile("미래 청구 도장", "아직 오지 않은 판에 찍는 도장이다. 지금 얻는 것은 없지만 길이 바뀐다.", [
		_choice("future_dice_stamp", "주사위 도장", "앞으로의 메인 주사위 해석을 강화한다.", "메인 주사위 +1", ACTION_RESULT, _result("future_dice_stamp", 0, 0, "주사위 도장", "청구 도장이 메인 주사위 줄 위에 찍혔다.", 0, [], {"primary_die_bonus": 1.0}), {"icon_kind": "dice"}),
		_choice("future_wheel_stamp", "룰렛 도장", "룰렛 결과 보너스를 조금 키운다.", "룰렛 보너스 +0.2", ACTION_RESULT, _result("future_wheel_stamp", 0, 0, "룰렛 도장", "바퀴 가장자리에 보이지 않는 도장이 남았다.", 0, [], {"roulette_bonus": 0.2}), {"icon_kind": "roulette"}),
		_choice("future_cashout", "지금 정산", "미래 도장을 팔아 현재 코인을 받는다.", "+9 골드", ACTION_RESULT, _result("future_cashout", 9, 0, "즉시 정산", "미래의 청구권을 지금 코인으로 바꿨다."), {"icon_kind": "gold"})
	])

static func _shop_coupon_tag() -> Dictionary:
	return _profile("잘린 가격표", "상점에서 떨어져 나온 가격표다. 지금 쓰면 약하고, 들고 가면 조금 유리해진다.", [
		_choice("coupon_sell", "가격표 팔기", "지금 바로 코인으로 바꾼다.", "+7 골드", ACTION_RESULT, _result("coupon_sell", 7, 0, "가격표 판매", "가격표는 사라지고 코인만 남았다."), {"icon_kind": "gold"}),
		_choice("coupon_steal", "큰 할인 훔치기", "룰렛 칸에 따라 할인권 가치가 바뀐다.", "위험 회전 / 대박 유물", ACTION_ROULETTE_CHECK, {}, {"roulette_wager": "coupon", "icon_kind": "roulette", "roulette_result_table": _roulette_table(
			_result("shop_coupon_tag", 0, -3, "도난 발각", "가격표가 찢기며 경보 도장이 찍혔다."),
			_result("shop_coupon_tag", 6, 0, "작은 할인", "큰일은 없었다. 작은 환급만 챙긴다."),
			_result("shop_coupon_tag", 13, 0, "큰 할인권", "상점 인장이 크게 찍혔다. 코인이 돌아온다."),
			_result("shop_coupon_tag", 18, 0, "과열된 환급", "잘린 가격표가 예상보다 큰 값으로 정산됐다."),
			_result("shop_coupon_tag", 4, 0, "숨은 진열품", "가격표 뒤에 붙어 있던 보관증이 유물을 불렀다.", 1)
		)}),
		_choice("coupon_buy_favor", "정식 할인권", "돈을 내고 다음 전투 준비를 산다.", "-5 골드, 다음 피해 -1", ACTION_RESULT, _result("coupon_buy_favor", -5, 0, "정식 할인권", "할인은 전투 준비 물품으로 정산됐다.", 0, [{
			"id": "shop_coupon_favor",
			"enemy_damage_delta": -1,
			"description": "Shop coupon: bought preparation to soften next enemy hit."
		}]), {"required_gold": 5, "icon_kind": "danger"})
	], {
		"story_pages": [
			{"title": "잘린 가격표", "body": "상점용 가격표가 테이블 밑에서 미끄러져 나온다. 태그의 절반은 잘렸지만 할인 문양은 아직 살아 있다."},
			{"title": "훔친 할인", "body": "정식으로 쓰면 작은 준비가 되고, 몰래 돌리면 룰렛이 그 값을 다시 매긴다."}
		]
	})

static func _rest_voucher_note() -> Dictionary:
	return _profile("휴식권 메모", "접힌 휴식권이 따뜻하다. 바로 쓰거나 장비 손질에 넘길 수 있다.", [
		_choice("voucher_heal_now", "지금 쉬기", "짧게 숨을 고른다.", "+6 HP", ACTION_RESULT, _result("voucher_heal_now", 0, 6, "짧은 휴식", "테이블 아래에서 잠깐 숨을 골랐다."), {"icon_kind": "heal"}),
		_choice("voucher_tune_dice", "주사위 손질", "휴식권을 메인 주사위 강화로 바꾼다.", "메인 주사위 +1", ACTION_RESULT, _result("voucher_tune_dice", 0, 0, "주사위 손질", "휴식권의 여유를 메인 주사위 눈금에 썼다.", 0, [], {"primary_die_bonus": 1.0}), {"icon_kind": "dice"}),
		_choice("voucher_tune_wheel", "룰렛 손질", "휴식권을 룰렛 보정으로 바꾼다.", "룰렛 보너스 +0.2", ACTION_RESULT, _result("voucher_tune_wheel", 0, 0, "룰렛 손질", "바퀴가 아주 조금 부드러워졌다.", 0, [], {"roulette_bonus": 0.2}), {"icon_kind": "roulette"})
	])

static func _banked_luck_token() -> Dictionary:
	return _profile("맡겨둔 행운 토큰", "작은 금고가 열려 있다. 지금 코인을 꺼내거나 행운을 나중으로 미룰 수 있다.", [
		_choice("luck_take_gold", "지금 꺼내기", "맡겨둔 코인을 바로 받는다.", "+10 골드", ACTION_RESULT, _result("luck_take_gold", 10, 0, "즉시 인출", "행운은 작아졌지만 손은 무거워졌다."), {"icon_kind": "gold"}),
		_choice("luck_bank_wheel", "룰렛에 맡기기", "룰렛 보너스를 키운다.", "룰렛 보너스 +0.2", ACTION_RESULT, _result("luck_bank_wheel", 0, 0, "룰렛 행운", "금고 안 행운이 바퀴 쪽으로 굴러갔다.", 0, [], {"roulette_bonus": 0.2}), {"icon_kind": "roulette"}),
		_choice("luck_bank_marble", "구슬에 맡기기", "마킹 보너스를 키운다.", "구슬 보너스 +0.5", ACTION_RESULT, _result("luck_bank_marble", 0, 0, "구슬 행운", "작은 토큰이 구슬 표식에 달라붙었다.", 0, [], {"marble_bonus": 0.5}), {"icon_kind": "roulette"})
	])

static func _locked_coin_chest() -> Dictionary:
	return _profile("잠긴 코인 상자", "상자는 작지만 무겁다. 자물쇠에는 세 개의 긁힌 눈금이 있다.", [
		_choice("coin_chest_force", "억지로 열기", "몸으로 자물쇠를 부순다.", "+14 골드, -2 HP", ACTION_RESULT, _result("coin_chest_force", 14, -2, "상자 강제 개봉", "자물쇠는 부서졌고 손등에는 피가 맺혔다."), {"required_hp": 3, "icon_kind": "gold"}),
		_choice("coin_chest_pick", "눈금 맞추기", "2d6 합계로 자물쇠를 푼다.", "8+ 코인 / 10+ 유물", ACTION_DICE_CHECK, {}, {"dice_bonus": 0, "icon_kind": "dice", "dice_result_table": _dice_table(
			_result("locked_coin_chest", 0, -2, "자물쇠 역침", "상자 안쪽 스프링이 튀어나와 손을 찍었다."),
			_result("locked_coin_chest", 15, 0, "코인 상자", "낡은 동전 더미가 테이블 위로 쏟아졌다."),
			_result("locked_coin_chest", 8, 0, "비밀 칸", "코인 아래 숨은 보관증까지 찾아냈다.", 1)
		)}),
		_choice("coin_chest_sell", "그대로 팔기", "상자를 열지 않고 넘긴다.", "+7 골드", ACTION_RESULT, _result("coin_chest_sell", 7, 0, "상자 판매", "안은 모르지만 무게값은 받았다."), {"icon_kind": "gold"})
	])

static func _waxed_relic_crate() -> Dictionary:
	return _profile("왁스 봉인 유물함", "붉은 왁스가 여러 겹 말라붙은 유물함이다. 안쪽에서 금속 소리가 난다.", [
		_choice("crate_break_wax", "봉인 깨기", "상처를 감수하고 유물을 꺼낸다.", "-4 HP, 유물", ACTION_RESULT, _result("crate_break_wax", 0, -4, "봉인 파손", "붉은 왁스가 깨지며 유물 하나가 굴러나왔다.", 1), {"required_hp": 5, "icon_kind": "relic"}),
		_choice("crate_draw_slip", "보관증 뽑기", "함 안의 전표를 한 장 뽑는다.", "랜덤 유물/손실", ACTION_CARD_DRAW, {}, {"card_deck_id": "relic_pouch", "icon_kind": "card"}),
		_choice("crate_take_coin", "겉동전만 챙기기", "봉인을 건드리지 않는다.", "+6 골드", ACTION_RESULT, _result("crate_take_coin", 6, 0, "겉동전 회수", "왁스 틈에 낀 동전만 빼냈다."), {"icon_kind": "gold"})
	])

static func _stained_claim_locker() -> Dictionary:
	return _profile("얼룩진 보관함", "보관함에는 이름 없는 청구표가 세 장 붙어 있다. 하나만 떼어낼 수 있다.", [
		_choice("locker_gold_claim", "금고 청구표", "보관된 코인을 청구한다.", "+12 골드", ACTION_RESULT, _result("locker_gold_claim", 12, 0, "금고 청구", "오래 맡겨둔 코인이 돌아왔다."), {"icon_kind": "gold"}),
		_choice("locker_medical_claim", "치료 청구표", "비상 약품을 청구한다.", "+7 HP", ACTION_RESULT, _result("locker_medical_claim", 0, 7, "치료 청구", "보관함 안 붕대는 낡았지만 아직 따뜻했다."), {"icon_kind": "heal"}),
		_choice("locker_marked_claim", "표식 청구표", "위험 표식이 붙은 보관증을 고른다.", "유물, 다음 피해 +1", ACTION_RESULT, _result("locker_marked_claim", 0, 0, "표식 청구", "보관증은 유물을 불렀지만 표식도 함께 따라왔다.", 1, [{
			"id": "stained_claim_locker_mark",
			"enemy_damage_delta": 1,
			"description": "Stained locker: claimed a marked relic, next enemy hit is sharper."
		}]), {"icon_kind": "relic"})
	])

static func _missing_bail_contract() -> Dictionary:
	return _profile("사라진 보증 계약", "찢어진 계약서에는 아직 빈 서명칸이 남아 있다. 누군가의 빚을 대신 쓸 수 있다.", [
		_choice("bail_pay_gold", "코인으로 보증", "돈을 내고 다음 판을 부드럽게 만든다.", "-7 골드, 다음 피해 -2", ACTION_RESULT, _result("bail_pay_gold", -7, 0, "보증금 납부", "보증금이 다음 상대의 손목을 묶었다.", 0, [{
			"id": "missing_bail_gold",
			"enemy_damage_delta": -2,
			"description": "Bail contract: paid gold to soften next enemy hit."
		}]), {"required_gold": 7, "icon_kind": "danger"}),
		_choice("bail_sign_name", "이름 대신 쓰기", "HP를 내고 유물 보증을 받는다.", "-3 HP, 유물", ACTION_RESULT, _result("bail_sign_name", 0, -3, "대리 서명", "남의 보증란에 이름을 쓰자 유물 보관증이 떨어졌다.", 1), {"required_hp": 4, "icon_kind": "blood"}),
		_choice("bail_trace_owner", "원주인 추적", "계약 흔적을 따라 작은 코인을 찾는다.", "+6 골드", ACTION_RESULT, _result("bail_trace_owner", 6, 0, "계약 추적", "주인은 없었지만 계약금 일부가 남아 있었다."), {"icon_kind": "gold"})
	], {
		"story_pages": [
			{"title": "사라진 보증 계약", "body": "테이블 밑에서 반쯤 탄 계약서가 발견된다. 보증인은 사라졌고, 딜러는 빈 서명칸을 바라본다."}
		]
	})

static func _three_mark_bounty() -> Dictionary:
	return _profile("세 표식 현상금", "세 개의 붉은 표식이 지도 위에 찍혀 있다. 어느 표식을 밟을지 고르면 주사위가 길을 연다.", [
		_choice("bounty_roll", "표식 밟기", "2d6 합계로 현상금을 판정한다.", "8+ 현상금 / 10+ 유물", ACTION_DICE_CHECK, {}, {"dice_bonus": 0, "icon_kind": "dice", "dice_result_table": _dice_table(
			_result("three_mark_bounty", 0, -4, "표식 실패", "현상금 대신 매복이 튀어나왔다."),
			_result("three_mark_bounty", 16, 0, "현상금 회수", "표식 아래 숨겨진 코인을 회수했다."),
			_result("three_mark_bounty", 10, 0, "세 표식 정산", "세 번째 표식까지 읽어내며 유물 보관증을 얻었다.", 1)
		)}),
		_choice("bounty_buy_tip", "정보상 매수", "코인을 내고 주사위 합계를 올린다.", "-4 골드, 합계 +1", ACTION_DICE_CHECK, {}, {"dice_bonus": 1, "cost_gold": 4, "required_gold": 4, "icon_kind": "dice", "dice_result_table": _dice_table(
			_result("three_mark_bounty", 0, -3, "빗나간 정보", "정보는 맞았지만 한 발 늦었다."),
			_result("three_mark_bounty", 14, 0, "정보 적중", "매수한 정보가 현상금 봉투를 가리켰다."),
			_result("three_mark_bounty", 8, 0, "완전한 지도", "정보상도 몰랐던 유물 칸까지 열렸다.", 1)
		)}),
		_choice("bounty_walk_away", "표식 지우기", "현상금을 포기하고 위험을 낮춘다.", "다음 피해 -1", ACTION_RESULT, _result("bounty_walk_away", 0, 0, "표식 삭제", "현상금은 사라졌지만 다음 길목의 칼끝도 흐려졌다.", 0, [{
			"id": "three_mark_bounty_erased",
			"enemy_damage_delta": -1,
			"description": "Bounty event: erased the mark to soften next enemy hit."
		}]), {"icon_kind": "danger"})
	], {
		"story_pages": [
			{"title": "세 표식 현상금", "body": "지도에 찍힌 붉은 점 세 개가 서로를 향해 당겨진다. 현상금 봉투는 가운데 점 아래에 묶여 있다."}
		]
	})

static func _sealed_floor_oath() -> Dictionary:
	return _profile("봉인된 층의 맹세", "작은 층계도가 계약서 위에 그려져 있다. 맹세를 고르면 다음 몇 걸음의 판이 달라진다.", [
		_choice("oath_dice", "주사위 맹세", "전투 메인 주사위 해석을 강화한다.", "메인 주사위 +1", ACTION_RESULT, _result("oath_dice", 0, 0, "주사위 맹세", "층계도 가장자리에 메인 주사위 눈금이 새겨졌다.", 0, [], {"primary_die_bonus": 1.0}), {"icon_kind": "dice"}),
		_choice("oath_roulette", "룰렛 맹세", "룰렛 보너스를 강화한다.", "룰렛 보너스 +0.2", ACTION_RESULT, _result("oath_roulette", 0, 0, "룰렛 맹세", "작은 층계도가 바퀴처럼 접혔다.", 0, [], {"roulette_bonus": 0.2}), {"icon_kind": "roulette"}),
		_choice("oath_coin", "맹세 팔기", "계약을 팔아 코인을 받는다.", "+9 골드", ACTION_RESULT, _result("oath_coin", 9, 0, "맹세 매각", "맹세는 가벼웠고 코인은 무거웠다."), {"icon_kind": "gold"})
	])

static func _midnight_side_bet() -> Dictionary:
	return _profile("자정 사이드 베팅", "작은 룰렛판이 테이블 모서리에서 혼자 돈다. 자정 전 한 번만 걸 수 있다.", [
		_choice("midnight_small_bet", "작은 사이드", "손실 없이 낮은 판돈을 건다.", "최대 +16 골드", ACTION_ROULETTE_CHECK, {}, {"roulette_wager": "midnight_small", "icon_kind": "roulette", "roulette_result_table": _roulette_table(
			_result("midnight_side_bet", 2, 0, "빈 사이드", "거의 빗나갔지만 작은 칩 하나가 남았다."),
			_result("midnight_side_bet", 7, 0, "안전한 칸", "작은 판돈이 무난하게 돌아왔다."),
			_result("midnight_side_bet", 12, 0, "수익 칸", "옆판이 조용히 코인을 밀어냈다."),
			_result("midnight_side_bet", 16, 0, "자정 직전", "바늘이 뜨거운 칸에 멈췄다."),
			_result("midnight_side_bet", 8, 0, "숨은 보관증", "칩 아래 유물 보관증이 같이 딸려왔다.", 1)
		)}),
		_choice("midnight_blood_bet", "피 묻은 사이드", "위험 칸을 열고 크게 건다.", "실패 -4 HP / 대박 유물", ACTION_ROULETTE_CHECK, {}, {"roulette_wager": "midnight_blood", "icon_kind": "roulette", "roulette_result_table": _roulette_table(
			_result("midnight_side_bet", 0, -4, "자정 손실", "붉은 칸이 손등을 긁고 지나갔다."),
			_result("midnight_side_bet", 6, 0, "간신히 본전", "큰 손실은 피했다."),
			_result("midnight_side_bet", 17, 0, "깊은 수익", "자정 판돈이 묵직하게 돌아왔다."),
			_result("midnight_side_bet", 22, 0, "뜨거운 칸", "작은 판이 잠깐 크게 타올랐다."),
			_result("midnight_side_bet", 8, 0, "자정 대박", "딜러가 숨겨둔 보관증까지 내밀었다.", 1)
		)}),
		_choice("midnight_skip", "시계 덮기", "자정 판을 넘긴다.", "+3 골드", ACTION_RESULT, _result("midnight_skip", 3, 0, "시계 덮기", "작은 칩만 챙기고 판을 덮었다."), {"icon_kind": "gold"})
	])

static func _loaded_cup_throw() -> Dictionary:
	return _profile("무거운 컵 던지기", "딜러가 금속 컵을 흔든다. 안쪽 주사위 소리가 조금 늦게 따라온다.", [
		_choice("cup_throw_plain", "그대로 던지기", "2d6 합계로 컵을 판정한다.", "8+ 성공 / 10+ 대성공", ACTION_DICE_CHECK, {}, {"dice_bonus": 0, "icon_kind": "dice", "dice_result_table": _dice_table(
			_result("loaded_cup_throw", 0, -3, "컵이 엎어졌다", "무거운 컵이 손목을 찍고 굴러갔다."),
			_result("loaded_cup_throw", 11, 0, "컵 적중", "딜러가 코인을 밀어준다."),
			_result("loaded_cup_throw", 5, 0, "컵 안 비밀칸", "컵 바닥에서 유물 보관증이 떨어졌다.", 1)
		)}),
		_choice("cup_throw_weight", "무게 더하기", "코인을 넣고 합계를 올린다.", "-3 골드, 합계 +1", ACTION_DICE_CHECK, {}, {"dice_bonus": 1, "cost_gold": 3, "required_gold": 3, "icon_kind": "dice", "dice_result_table": _dice_table(
			_result("loaded_cup_throw", 0, -2, "무게 실패", "코인은 들어갔지만 컵은 빗나갔다."),
			_result("loaded_cup_throw", 10, 0, "묵직한 적중", "무게가 좋은 쪽으로 기울었다."),
			_result("loaded_cup_throw", 6, 0, "무거운 대성공", "컵이 완벽히 멈추며 숨은 보관증을 열었다.", 1)
		)}),
		_choice("cup_throw_sell", "컵 팔기", "던지지 않고 컵값만 받는다.", "+5 골드", ACTION_RESULT, _result("cup_throw_sell", 5, 0, "컵 판매", "무거운 컵은 사라지고 코인만 남았다."), {"icon_kind": "gold"})
	])

static func _shrouded_receipt() -> Dictionary:
	return _profile("장막 속 전표", "흐릿한 천 아래 전표가 하나 숨겨져 있다. 천을 걷기 전까지 잉크는 읽히지 않는다.", [
		_choice("shroud_lift", "천 걷기", "숨은 전표를 확인한다.", "랜덤 보상/손실", ACTION_CARD_DRAW, {}, {"card_peeked": false, "icon_kind": "card"}),
		_choice("shroud_burn_edge", "가장자리 태우기", "HP를 내고 나쁜 전표 일부를 태운다.", "-2 HP, 좋은 전표 추가", ACTION_CARD_DRAW, {}, {"card_peeked": true, "cost_hp": 2, "required_hp": 3, "icon_kind": "blood"}),
		_choice("shroud_leave", "천 그대로 두기", "모르는 채로 작은 값을 받는다.", "+5 골드", ACTION_RESULT, _result("shroud_leave", 5, 0, "장막 유지", "무엇이었는지는 모르지만 코인은 진짜였다."), {"icon_kind": "gold"})
	])

static func _wrong_seat_marker() -> Dictionary:
	return _profile("잘못 놓인 자리표", "당신 이름이 아닌 자리표가 앞에 놓여 있다. 딜러는 못 본 척한다.", [
		_choice("seat_take_tip", "팁만 챙기기", "남의 팁을 조용히 가져간다.", "+9 골드", ACTION_RESULT, _result("seat_take_tip", 9, 0, "자리표 팁", "잘못 놓인 팁은 빠르게 사라졌다."), {"icon_kind": "gold"}),
		_choice("seat_swap_mark", "표식 바꾸기", "다음 적의 공격을 낮춘다.", "다음 피해 -1", ACTION_RESULT, _result("seat_swap_mark", 0, 0, "자리표 교체", "다음 상대가 엉뚱한 표식을 보고 잠깐 멈칫한다.", 0, [{
			"id": "wrong_seat_marker_swap",
			"enemy_damage_delta": -1,
			"description": "Wrong seat marker: swapped a mark to soften next enemy hit."
		}]), {"icon_kind": "danger"}),
		_choice("seat_confess", "딜러에게 알리기", "정직하게 돌려주고 작은 보상을 받는다.", "+4 HP", ACTION_RESULT, _result("seat_confess", 0, 4, "정직한 반환", "딜러가 뜻밖이라는 듯 약병 하나를 밀어준다."), {"icon_kind": "heal"})
	])
