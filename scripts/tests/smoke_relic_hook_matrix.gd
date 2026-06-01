extends SceneTree

const FeedbackEventMapper := preload("res://scripts/systems/feedback_event_mapper.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RelicEffectResolver := preload("res://scripts/systems/relic_effect_resolver.gd")
const Payloads := preload("res://scripts/tests/support/relic_hook_payloads.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_catalog_has_matrix_rows()
	_check_matrix_rows()

	if failures.is_empty():
		print("relic hook matrix smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_catalog_has_matrix_rows() -> void:
	var expected_ids := _expected_effects().keys()
	for relic_id in RelicCatalog.all_ids():
		if RelicCatalog.implementation_status(relic_id) != "runtime":
			continue
		if not expected_ids.has(relic_id):
			failures.append(str(relic_id) + " has no relic matrix row")

func _check_matrix_rows() -> void:
	var expected := _expected_effects()
	for relic_id in expected.keys():
		if not RelicCatalog.has_relic(relic_id):
			failures.append(str(relic_id) + " matrix row references missing relic")
			continue
		for row in expected[relic_id]:
			var hook: String = str(row.get("hook", ""))
			if not RelicCatalog.hooks(relic_id).has(hook):
				failures.append(relic_id + " matrix hook not declared in catalog: " + hook)
			var payload: Dictionary = RelicEffectResolver.apply(hook, row.get("payload", {}), [relic_id])
			var effect_id: String = str(row.get("effect_id", ""))
			if not Payloads.has_effect(payload, effect_id):
				failures.append(relic_id + " did not record expected effect " + effect_id + " on " + hook)
			if row.has("assert_key") and payload.get(str(row["assert_key"])) != row.get("assert_value"):
				failures.append(relic_id + " did not set " + str(row["assert_key"]) + " to " + str(row.get("assert_value")))
			var events: Array[Dictionary] = FeedbackEventMapper.map_effects(payload.get("applied_effects", []), hook)
			if bool(row.get("visible", true)) and events.is_empty():
				failures.append(relic_id + " effect " + effect_id + " did not map to visible feedback")
			if row.has("negative_payload"):
				var negative: Dictionary = RelicEffectResolver.apply(hook, row.get("negative_payload", {}), [relic_id])
				if Payloads.has_effect(negative, effect_id):
					failures.append(relic_id + " recorded " + effect_id + " for wrong marked slot")

func _expected_effects() -> Dictionary:
	return {
		"loaded_die": [
			{
				"hook": "dice_result",
				"effect_id": "attack_die_plus_one",
				"payload": Payloads.dice_payload([2], "single_attack_die"),
				"assert_key": "attack_base",
				"assert_value": 3
			},
			{
				"hook": "marble_gain",
				"effect_id": "attack_payload_tagged",
				"payload": {"marbles": ["plain"], "applied_effects": []},
				"visible": false
			}
		],
		"green_purse": [
			{
				"hook": "resolution_before",
				"effect_id": "green_cash_bonus",
				"payload": Payloads.resolution_payload("profit", "profit"),
				"negative_payload": Payloads.resolution_payload("safe", "safe"),
				"assert_key": "cash_delta_bonus",
				"assert_value": 4
			}
		],
		"yellow_guard": [
			{
				"hook": "resolution_before",
				"effect_id": "marked_hit_guard",
				"payload": Payloads.resolution_payload("safe", "safe"),
				"negative_payload": Payloads.resolution_payload("jackpot", "jackpot"),
				"assert_key": "enemy_damage_delta",
				"assert_value": -2
			}
		],
		"purple_contract": [
			{
				"hook": "resolution_before",
				"effect_id": "marked_jackpot_multiplier",
				"payload": Payloads.resolution_payload("jackpot", "jackpot"),
				"negative_payload": Payloads.resolution_payload("profit", "profit"),
				"assert_key": "damage_multiplier",
				"assert_value": 1.35
			}
		],
		"bust_insurance": [
			{
				"hook": "resolution_after",
				"effect_id": "bust_delta_cancelled",
				"payload": {"bust_delta": 1, "player_hp": 20, "message": "", "applied_effects": []},
				"assert_key": "bust_delta",
				"assert_value": 0
			}
		],
		"snake_eyes_charm": [
			{
				"hook": "dice_result",
				"effect_id": "doubles_first_die_plus_one",
				"payload": Payloads.dice_payload([2, 2], "two_dice_sum_attack"),
				"assert_key": "attack_base",
				"assert_value": 5
			}
		],
		"second_chance": [
			{
				"hook": "roulette_before_spin",
				"effect_id": "roulette_respin_plus_one",
				"payload": {"roulette_respins_left": 1, "applied_effects": []},
				"assert_key": "roulette_respins_left",
				"assert_value": 2
			}
		],
		"turn_token": [
			{
				"hook": "turn_start",
				"effect_id": "turn_cash_tip",
				"payload": {"turn": 2, "cash": 8, "applied_effects": []},
				"assert_key": "cash",
				"assert_value": 9
			}
		],
		"locksmith_glove": [
			{
				"hook": "dice_result",
				"effect_id": "last_reroll_die_plus_two",
				"payload": Payloads.dice_payload([3], "single_attack_die"),
				"assert_key": "attack_base",
				"assert_value": 4,
				"negative_payload": Payloads.dice_payload_with_rerolls([3], "single_attack_die", 1)
			}
		],
		"twin_marker": [
			{
				"hook": "marble_gain",
				"effect_id": "strong_attack_extra_marker",
				"payload": {"dice_values": [4, 5], "attack_base": 99, "marble_count": 1, "marbles": ["plain"], "applied_effects": []},
				"assert_key": "marble_count",
				"assert_value": 2,
				"negative_payload": {"dice_values": [3, 5], "attack_base": 99, "marble_count": 1, "marbles": ["plain"], "applied_effects": []}
			}
		],
		"blue_chisel": [
			{
				"hook": "resolution_before",
				"effect_id": "marked_overdrive_flat_damage",
				"payload": Payloads.resolution_payload("overdrive", "overdrive"),
				"negative_payload": Payloads.resolution_payload("safe", "safe"),
				"assert_key": "flat_damage_bonus",
				"assert_value": 2
			}
		],
		"last_call_bell": [
			{
				"hook": "resolution_after",
				"effect_id": "victory_cash_bonus",
				"payload": {"enemy_hp": 0, "damage": 12, "cash": 20, "cash_delta": 0, "message": "", "applied_effects": []},
				"assert_key": "cash",
				"assert_value": 28,
				"negative_payload": {"enemy_hp": 8, "damage": 12, "cash": 20, "cash_delta": 0, "message": "", "applied_effects": []}
			}
		],
		"dice_under_six": [
			{
				"hook": "marble_gain",
				"effect_id": "low_total_extra_marker",
				"payload": {"dice_values": [2, 3], "attack_base": 2, "marble_count": 1, "marbles": ["plain"], "applied_effects": []},
				"assert_key": "marble_count",
				"assert_value": 2,
				"negative_payload": {"dice_values": [4, 5], "attack_base": 4, "marble_count": 1, "marbles": ["plain"], "applied_effects": []}
			}
		],
		"dice_low_guard": [
			{
				"hook": "dice_result",
				"effect_id": "low_attack_guard",
				"payload": Payloads.dice_payload([3], "single_attack_die"),
				"assert_key": "guard_value",
				"assert_value": 3,
				"negative_payload": Payloads.dice_payload([4], "single_attack_die")
			}
		],
		"marker_miss_gold": [
			{
				"hook": "resolution_after",
				"effect_id": "marked_miss_gold",
				"payload": {"pending_slot": "safe", "placed_slots": Payloads.marked_payload("jackpot"), "cash": 20, "cash_delta": 0, "message": "", "applied_effects": []},
				"assert_key": "cash",
				"assert_value": 21,
				"negative_payload": {"pending_slot": "jackpot", "placed_slots": Payloads.marked_payload("jackpot"), "cash": 20, "cash_delta": 0, "message": "", "applied_effects": []}
			}
		],
		"marker_adjacent": [
			{
				"hook": "roulette_after_spin",
				"effect_id": "adjacent_mark_gold",
				"payload": {"pending_slot": "safe", "placed_slots": Payloads.marked_payload("profit"), "cash": 20, "cash_delta": 0, "applied_effects": []},
				"assert_key": "cash",
				"assert_value": 22,
				"negative_payload": {"pending_slot": "safe", "placed_slots": Payloads.marked_payload("overdrive"), "cash": 20, "cash_delta": 0, "applied_effects": []}
			}
		],
		"wheel_profit_tithe": [
			{
				"hook": "resolution_before",
				"effect_id": "profit_tithe_gold",
				"payload": Payloads.resolution_payload("profit", "profit"),
				"assert_key": "cash_delta_bonus",
				"assert_value": 4,
				"negative_payload": Payloads.resolution_payload("safe", "profit")
			}
		],
		"wheel_overdrive_pin": [
			{
				"hook": "resolution_before",
				"effect_id": "overdrive_pin_flat_damage",
				"payload": Payloads.resolution_payload("overdrive", "overdrive"),
				"assert_key": "flat_damage_bonus",
				"assert_value": 2,
				"negative_payload": Payloads.resolution_payload("safe", "overdrive")
			}
		],
		"def_first_hit": [
			{
				"hook": "damage_taken",
				"effect_id": "first_hit_prevented",
				"payload": {"damage": 6, "player_hp": 20, "relic_state": {}, "applied_effects": []},
				"assert_key": "damage",
				"assert_value": 2,
				"negative_payload": {"damage": 6, "player_hp": 20, "relic_state": {"def_first_hit_used": true}, "applied_effects": []}
			}
		],
		"dice_wide_split": [
			{
				"hook": "dice_result",
				"effect_id": "wide_split_bonus",
				"payload": Payloads.dice_payload_with_cash([1, 5], "two_dice_sum_attack", 10),
				"assert_key": "cash",
				"assert_value": 12,
				"negative_payload": Payloads.dice_payload_with_cash([3, 5], "two_dice_sum_attack", 10)
			}
		],
		"econ_low_gold": [
			{
				"hook": "turn_start",
				"effect_id": "low_gold_tip",
				"payload": {"turn": 1, "cash": 8, "player_block": 0, "relic_state": {}, "applied_effects": []},
				"assert_key": "cash",
				"assert_value": 12,
				"negative_payload": {"turn": 2, "cash": 8, "player_block": 0, "relic_state": {}, "applied_effects": []}
			}
		],
		"def_no_block": [
			{
				"hook": "resolution_before",
				"effect_id": "empty_guard_block",
				"payload": Payloads.resolution_payload("safe", "safe"),
				"assert_key": "enemy_damage_delta",
				"assert_value": -3,
				"negative_payload": Payloads.resolution_payload_with_block("safe", "safe", 2)
			}
		],
		"marker_first_hit": [
			{
				"hook": "resolution_before",
				"effect_id": "first_mark_flat_damage",
				"payload": Payloads.resolution_payload("jackpot", "jackpot"),
				"assert_key": "flat_damage_bonus",
				"assert_value": 3,
				"negative_payload": Payloads.resolution_payload_with_state("jackpot", "jackpot", {"marker_first_hit_used": true})
			}
		],
		"dice_exact_four": [
			{
				"hook": "dice_result",
				"effect_id": "exact_four_gold",
				"payload": Payloads.dice_payload_with_cash([4], "single_attack_die", 10),
				"assert_key": "cash",
				"assert_value": 13,
				"negative_payload": Payloads.dice_payload_with_cash([5], "single_attack_die", 10)
			}
		],
		"dice_guard_lead": [
			{
				"hook": "dice_result",
				"effect_id": "guard_lead_block",
				"payload": Payloads.dice_payload_selected([2, 5], "two_dice_attack_guard", 0),
				"assert_key": "guard_value",
				"assert_value": 7,
				"negative_payload": Payloads.dice_payload_selected([2, 5], "two_dice_attack_guard", 1)
			}
		],
		"def_after_bust": [
			{
				"hook": "resolution_after",
				"effect_id": "after_bust_set",
				"payload": {"bust_delta": 1, "player_hp": 20, "relic_state": {}, "message": "", "applied_effects": []}
			},
			{
				"hook": "turn_start",
				"effect_id": "after_bust_block",
				"payload": {"turn": 2, "cash": 12, "player_block": 0, "relic_state": {"def_after_bust_pending": 3}, "applied_effects": []},
				"assert_key": "player_block",
				"assert_value": 3
			}
		],
		"def_marker_block": [
			{
				"hook": "resolution_before",
				"effect_id": "pinned_guard_set",
				"payload": Payloads.resolution_payload("safe", "safe"),
				"negative_payload": Payloads.resolution_payload("profit", "safe")
			},
			{
				"hook": "turn_start",
				"effect_id": "pinned_guard_carry",
				"payload": {"turn": 2, "cash": 12, "player_block": 0, "relic_state": {"def_marker_block_pending": 2}, "applied_effects": []},
				"assert_key": "player_block",
				"assert_value": 2
			}
		],
		"econ_interest": [
			{
				"hook": "combat_victory",
				"effect_id": "interest_token_gold",
				"payload": {"victory": true, "cash": 20, "combat_cash": 20, "winnings": 20, "applied_effects": []},
				"assert_key": "cash",
				"assert_value": 24,
				"negative_payload": {"victory": true, "cash": 19, "combat_cash": 19, "winnings": 19, "applied_effects": []}
			}
		],
		"lucky_low_marble": [
			{
				"hook": "marble_gain",
				"effect_id": "lucky_low_extra_marker",
				"payload": {"dice_values": [2, 6], "selected_attack_die_index": 0, "attack_base": 99, "marble_count": 1, "marbles": ["plain"], "applied_effects": []},
				"assert_key": "marble_count",
				"assert_value": 2,
				"negative_payload": {"dice_values": [3, 6], "selected_attack_die_index": 0, "attack_base": 99, "marble_count": 1, "marbles": ["plain"], "applied_effects": []}
			}
		],
		"marker_repeat_slot": [
			{
				"hook": "resolution_before",
				"effect_id": "repeat_slot_multiplier",
				"payload": Payloads.resolution_payload_with_state("safe", "safe", {"marked_count_safe": 3}),
				"assert_key": "damage_multiplier",
				"assert_value": 1.5,
				"negative_payload": Payloads.resolution_payload_with_state("safe", "safe", {"marked_count_safe": 2})
			}
		],
		"wheel_jackpot_blood": [
			{
				"hook": "resolution_before",
				"effect_id": "blood_jackpot_paid",
				"payload": Payloads.numeric_resolution_payload(3.0, [4, 5], 0, 20, 42),
				"assert_key": "player_hp",
				"assert_value": 18,
				"negative_payload": Payloads.numeric_resolution_payload(1.5, [4, 5], 0, 20, 42)
			}
		],
		"risk_last_hand": [
			{
				"hook": "combat_victory",
				"effect_id": "last_hand_heal",
				"payload": {"victory": true, "turn": 2, "player_hp": 20, "player_max_hp": 42, "applied_effects": []},
				"assert_key": "player_hp",
				"assert_value": 24,
				"negative_payload": {"victory": true, "turn": 3, "player_hp": 20, "player_max_hp": 42, "applied_effects": []}
			}
		],
		"risk_rare_pull": [
			{
				"hook": "combat_victory",
				"effect_id": "calling_bell_gold",
				"payload": {"victory": true, "turn": 1, "cash": 20, "combat_cash": 20, "winnings": 20, "applied_effects": []},
				"assert_key": "cash",
				"assert_value": 30,
				"negative_payload": {"victory": true, "turn": 2, "cash": 20, "combat_cash": 20, "winnings": 20, "applied_effects": []}
			}
		],
		"jackpot_knife": [
			{
				"hook": "resolution_before",
				"effect_id": "jackpot_knife_multiplier",
				"payload": Payloads.numeric_resolution_payload(3.0, [4, 5], 0, 20, 42),
				"assert_key": "damage_multiplier",
				"assert_value": 3.75,
				"negative_payload": Payloads.numeric_resolution_payload(1.5, [4, 5], 0, 20, 42)
			}
		],
		"gamblers_spare_marble": [
			{
				"hook": "marble_gain",
				"effect_id": "spare_marble_double",
				"payload": {"dice_values": [4, 4], "marble_count": 1, "marbles": ["plain"], "applied_effects": []},
				"assert_key": "marble_count",
				"assert_value": 2,
				"negative_payload": {"dice_values": [4, 5], "marble_count": 1, "marbles": ["plain"], "applied_effects": []}
			}
		],
		"gamblers_odd_eye": [
			{
				"hook": "marble_gain",
				"effect_id": "odd_eye_paid",
				"payload": {"dice_values": [4, 5], "cash": 10, "marble_count": 1, "marbles": ["plain"], "applied_effects": []},
				"assert_key": "cash",
				"assert_value": 11,
				"negative_payload": {"dice_values": [4, 6], "cash": 10, "marble_count": 1, "marbles": ["plain"], "applied_effects": []}
			}
		],
		"gamblers_last_reroll": [
			{
				"hook": "dice_result",
				"effect_id": "last_reroll_selected_die_plus_one",
				"payload": Payloads.dice_payload_selected([3, 4], "two_dice_double_attack", 0),
				"assert_key": "attack_base",
				"assert_value": 8,
				"negative_payload": Payloads.dice_payload_selected_with_rerolls([3, 4], "two_dice_double_attack", 0, 1)
			}
		],
		"cursed_players_split_tooth": [
			{
				"hook": "resolution_before",
				"effect_id": "split_tooth_flat_damage",
				"payload": Payloads.numeric_resolution_payload(1.0, [4, 5], 0, 20, 42),
				"assert_key": "flat_damage_bonus",
				"assert_value": 2,
				"negative_payload": Payloads.numeric_resolution_payload(1.0, [3, 5], 0, 20, 42)
			}
		],
		"cursed_players_red_marble": [
			{
				"hook": "resolution_after",
				"effect_id": "red_marble_lifesteal",
				"payload": {"damage": 10, "player_hp": 20, "player_max_hp": 42, "dice_values": [5, 3], "selected_attack_die_index": 0, "applied_effects": []},
				"assert_key": "player_hp",
				"assert_value": 22,
				"negative_payload": {"damage": 10, "player_hp": 20, "player_max_hp": 42, "dice_values": [4, 3], "selected_attack_die_index": 0, "applied_effects": []}
			}
		],
		"cursed_players_pain_bell": [
			{
				"hook": "resolution_before",
				"effect_id": "pain_bell_low_hp",
				"payload": Payloads.numeric_resolution_payload(1.0, [4, 4], 0, 20, 42),
				"assert_key": "flat_damage_bonus",
				"assert_value": 2,
				"negative_payload": Payloads.numeric_resolution_payload(1.0, [4, 4], 0, 30, 42)
			}
		],
		"marble_savant_charm": [
			{
				"hook": "marble_gain",
				"effect_id": "savant_extra_marble",
				"payload": {"dice_values": [5, 5], "marble_count": 1, "marbles": ["plain"], "applied_effects": []},
				"assert_key": "marble_count",
				"assert_value": 2,
				"negative_payload": {"dice_values": [4, 5], "marble_count": 1, "marbles": ["plain"], "applied_effects": []}
			}
		],
		"roulette_savant_pin": [
			{
				"hook": "resolution_before",
				"effect_id": "roulette_savant_pin",
				"payload": Payloads.numeric_resolution_payload(1.5, [6, 2], 0, 20, 42),
				"assert_key": "flat_damage_bonus",
				"assert_value": 2,
				"negative_payload": Payloads.numeric_resolution_payload(1.5, [5, 2], 0, 20, 42)
			}
		],
		"even_keel": [
			{
				"hook": "dice_result",
				"effect_id": "even_keel_block",
				"payload": Payloads.dice_payload([2, 4], "two_dice_sum_attack"),
				"assert_key": "player_block",
				"assert_value": 1,
				"negative_payload": Payloads.dice_payload([2, 5], "two_dice_sum_attack")
			}
		],
		"odd_charm": [
			{
				"hook": "resolution_before",
				"effect_id": "odd_charm_flat_damage",
				"payload": Payloads.numeric_resolution_payload(1.0, [2, 5], 0, 20, 42),
				"assert_key": "flat_damage_bonus",
				"assert_value": 1,
				"negative_payload": Payloads.numeric_resolution_payload(1.0, [2, 4], 0, 20, 42)
			}
		],
		"split_tip": [
			{
				"hook": "dice_result",
				"effect_id": "split_tip_gold",
				"payload": Payloads.dice_payload_with_cash([3, 4], "two_dice_sum_attack", 10),
				"assert_key": "cash",
				"assert_value": 12,
				"negative_payload": Payloads.dice_payload_with_cash([2, 4], "two_dice_sum_attack", 10)
			}
		],
		"zero_receipt": [
			{
				"hook": "resolution_after",
				"effect_id": "zero_receipt_gold",
				"payload": Payloads.numeric_outcome_payload(0.0, 10),
				"assert_key": "cash",
				"assert_value": 11,
				"negative_payload": Payloads.numeric_outcome_payload(1.0, 10)
			}
		],
		"wager_padding": [
			{
				"hook": "resolution_before",
				"effect_id": "wager_padding_block",
				"payload": Payloads.numeric_resolution_payload_with_wager(1.0, [3, 4], 0, 20, 42, 2),
				"assert_key": "player_block",
				"assert_value": 1,
				"negative_payload": Payloads.numeric_resolution_payload_with_wager(1.0, [3, 4], 0, 20, 42, 1)
			}
		],
		"cracked_scepter": [
			{
				"hook": "resolution_before",
				"effect_id": "cracked_scepter_jackpot",
				"payload": Payloads.numeric_resolution_payload(3.0, [4, 5], 0, 20, 42),
				"assert_key": "damage_multiplier",
				"assert_value": 3.7,
				"negative_payload": Payloads.numeric_resolution_payload(1.5, [4, 5], 0, 20, 42)
			},
			{
				"hook": "resolution_before",
				"effect_id": "cracked_scepter_bust_pressure",
				"payload": Payloads.numeric_resolution_payload(0.0, [4, 5], 0, 20, 42),
				"assert_key": "enemy_damage_delta",
				"assert_value": 2
			}
		],
		"thorn_chip": [
			{
				"hook": "damage_taken",
				"effect_id": "thorn_chip_counter",
				"payload": {"damage": 5, "player_hp": 20, "enemy_hp": 20, "relic_state": {}, "applied_effects": []},
				"assert_key": "enemy_hp",
				"assert_value": 17,
				"negative_payload": {"damage": 5, "player_hp": 20, "enemy_hp": 20, "relic_state": {"thorn_chip_used": true}, "applied_effects": []}
			}
		],
		"double_or_debt": [
			{
				"hook": "resolution_before",
				"effect_id": "double_or_debt_jackpot_gold",
				"payload": Payloads.numeric_resolution_payload_with_cash(3.0, [4, 5], 0, 20, 42, 10),
				"assert_key": "cash_delta_bonus",
				"assert_value": 8
			},
			{
				"hook": "resolution_before",
				"effect_id": "double_or_debt_bust_debt",
				"payload": Payloads.numeric_resolution_payload_with_cash(0.0, [4, 5], 0, 20, 42, 10),
				"assert_key": "cash_delta_bonus",
				"assert_value": -4
			}
		],
		"glass_jackpot": [
			{
				"hook": "resolution_before",
				"effect_id": "glass_jackpot_multiplier",
				"payload": Payloads.numeric_resolution_payload(3.0, [4, 5], 0, 20, 42),
				"assert_key": "damage_multiplier",
				"assert_value": 4.0,
				"negative_payload": Payloads.numeric_resolution_payload(1.5, [4, 5], 0, 20, 42)
			},
			{
				"hook": "damage_taken",
				"effect_id": "glass_jackpot_fragility",
				"payload": {"damage": 8, "player_hp": 20, "relic_state": {}, "applied_effects": []},
				"assert_key": "damage",
				"assert_value": 10
			}
		],
		"brass_reroll_key": [
			{
				"hook": "dice_result",
				"effect_id": "brass_key_gold",
				"payload": Payloads.dice_payload_with_rerolls([3, 4], "two_dice_sum_attack", 0),
				"assert_key": "cash",
				"assert_value": 2,
				"negative_payload": Payloads.dice_payload_with_rerolls([3, 4], "two_dice_sum_attack", 1)
			}
		],
		"cheap_insurance_stub": [
			{
				"hook": "damage_taken",
				"effect_id": "cheap_insurance_prevented",
				"payload": {"damage": 5, "player_hp": 20, "relic_state": {}, "applied_effects": []},
				"assert_key": "damage",
				"assert_value": 3,
				"negative_payload": {"damage": 5, "player_hp": 20, "relic_state": {"cheap_insurance_used": true}, "applied_effects": []}
			}
		],
		"econ_gold_armor": [
			{
				"hook": "turn_start",
				"effect_id": "gold_armor_block",
				"payload": {"turn": 2, "cash": 20, "player_block": 0, "applied_effects": []},
				"assert_key": "player_block",
				"assert_value": 1,
				"negative_payload": {"turn": 2, "cash": 19, "player_block": 0, "applied_effects": []}
			}
		],
		"econ_shop_heal": [
			{
				"hook": "combat_victory",
				"effect_id": "shop_meal_heal",
				"payload": {"victory": true, "cash": 25, "combat_cash": 25, "player_hp": 20, "player_max_hp": 42, "applied_effects": []},
				"assert_key": "player_hp",
				"assert_value": 22,
				"negative_payload": {"victory": true, "cash": 24, "combat_cash": 24, "player_hp": 20, "player_max_hp": 42, "applied_effects": []}
			}
		],
		"house_edge_receipt": [
			{
				"hook": "resolution_before",
				"effect_id": "house_edge_gold",
				"payload": Payloads.numeric_resolution_payload_with_cash(1.0, [3, 4], 0, 20, 42, 10),
				"assert_key": "cash_delta_bonus",
				"assert_value": 1,
				"negative_payload": Payloads.numeric_resolution_payload_with_cash(1.5, [3, 4], 0, 20, 42, 10)
			}
		],
		"marker_thimble": [
			{
				"hook": "marble_gain",
				"effect_id": "thimble_extra_marble",
				"payload": {"dice_values": [1, 4], "selected_attack_die_index": 0, "marble_count": 1, "marbles": ["plain"], "applied_effects": []},
				"assert_key": "marble_count",
				"assert_value": 2,
				"negative_payload": {"dice_values": [2, 4], "selected_attack_die_index": 0, "marble_count": 1, "marbles": ["plain"], "applied_effects": []}
			}
		],
		"marker_unmarked_hit": [
			{
				"hook": "resolution_before",
				"effect_id": "unmarked_hit_damage",
				"payload": Payloads.numeric_resolution_payload_with_wager(1.0, [3, 4], 0, 20, 42, 0),
				"assert_key": "flat_damage_bonus",
				"assert_value": 1,
				"negative_payload": Payloads.numeric_resolution_payload_with_wager(1.0, [3, 4], 0, 20, 42, 1)
			}
		],
		"wheel_adjacent_pay": [
			{
				"hook": "resolution_before",
				"effect_id": "neighbor_cut_gold",
				"payload": Payloads.numeric_resolution_payload_with_cash(1.0, [3, 4], 0, 20, 42, 10),
				"assert_key": "cash_delta_bonus",
				"assert_value": 2,
				"negative_payload": Payloads.numeric_resolution_payload_with_cash(0.5, [3, 4], 0, 20, 42, 10)
			}
		],
		"wheel_black_stop": [
			{
				"hook": "resolution_before",
				"effect_id": "black_stop_block",
				"payload": Payloads.numeric_resolution_payload(0.5, [3, 4], 0, 20, 42),
				"assert_key": "player_block",
				"assert_value": 1,
				"negative_payload": Payloads.numeric_resolution_payload(1.0, [3, 4], 0, 20, 42)
			}
		],
		"def_low_hp": [
			{
				"hook": "turn_start",
				"effect_id": "low_hp_block",
				"payload": {"turn": 2, "player_hp": 20, "player_max_hp": 42, "player_block": 0, "relic_state": {}, "applied_effects": []},
				"assert_key": "player_block",
				"assert_value": 2,
				"negative_payload": {"turn": 2, "player_hp": 20, "player_max_hp": 42, "player_block": 0, "relic_state": {"def_low_hp_used": true}, "applied_effects": []}
			}
		],
		"black_candle_bet": [
			{
				"hook": "resolution_before",
				"effect_id": "black_candle_burn",
				"payload": Payloads.numeric_resolution_payload(1.5, [3, 4], 0, 20, 42),
				"assert_key": "damage_multiplier",
				"assert_value": 1.8,
				"negative_payload": Payloads.numeric_resolution_payload(1.0, [3, 4], 0, 20, 42)
			},
			{
				"hook": "resolution_before",
				"effect_id": "black_candle_bust_cost",
				"payload": Payloads.numeric_resolution_payload(0.0, [3, 4], 0, 20, 42),
				"assert_key": "player_hp",
				"assert_value": 19
			}
		],
		"debt_blood_quill": [
			{
				"hook": "resolution_before",
				"effect_id": "blood_quill_paid",
				"payload": Payloads.numeric_resolution_payload(1.0, [3, 4], 0, 20, 42),
				"assert_key": "player_hp",
				"assert_value": 19,
				"negative_payload": Payloads.numeric_resolution_payload(0.0, [3, 4], 0, 20, 42)
			}
		],
		"risk_bust_power": [
			{
				"hook": "resolution_before",
				"effect_id": "bust_power_debt",
				"payload": Payloads.numeric_resolution_payload_with_cash(0.0, [3, 4], 0, 20, 42, 10),
				"assert_key": "cash_delta_bonus",
				"assert_value": 4,
				"negative_payload": Payloads.numeric_resolution_payload_with_cash(0.5, [3, 4], 0, 20, 42, 10)
			}
		],
		"risk_action_cap": [
			{
				"hook": "turn_start",
				"effect_id": "action_cap_early_attack",
				"payload": {"turn": 2, "player_attack_delta": 0, "enemy_damage_delta": 0, "applied_effects": []},
				"assert_key": "player_attack_delta",
				"assert_value": 1
			},
			{
				"hook": "turn_start",
				"effect_id": "action_cap_late_pressure",
				"payload": {"turn": 4, "player_attack_delta": 0, "enemy_damage_delta": 0, "applied_effects": []},
				"assert_key": "enemy_damage_delta",
				"assert_value": 1
			}
		],
		"risk_no_safe": [
			{
				"hook": "resolution_before",
				"effect_id": "no_safe_low_boost",
				"payload": Payloads.numeric_resolution_payload(0.5, [3, 4], 0, 20, 42),
				"assert_key": "damage_multiplier",
				"assert_value": 0.75,
				"negative_payload": Payloads.numeric_resolution_payload(1.0, [3, 4], 0, 20, 42)
			}
		],
		"gold_locked_purse": [
			{
				"hook": "combat_start",
				"effect_id": "gold_locked_purse_start",
				"payload": {"cash": 10, "combat_cash": 10, "enemy_damage_delta": 0, "applied_effects": []},
				"assert_key": "combat_cash",
				"assert_value": 18
			}
		],
		"greedy_house_ledger": [
			{
				"hook": "turn_start",
				"effect_id": "greedy_ledger_turn",
				"payload": {"turn": 2, "cash": 10, "enemy_damage_delta": 0, "applied_effects": []},
				"assert_key": "cash",
				"assert_value": 12
			}
		],
		"no_refund_contract": [
			{
				"hook": "turn_start",
				"effect_id": "no_refund_first_turn",
				"payload": {"turn": 1, "player_hp": 20, "player_damage_multiplier": 1.0, "applied_effects": []},
				"assert_key": "player_hp",
				"assert_value": 18,
				"negative_payload": {"turn": 2, "player_hp": 20, "player_damage_multiplier": 1.0, "applied_effects": []}
			}
		],
		"heavy_crown_die": [
			{
				"hook": "resolution_before",
				"effect_id": "heavy_crown_jackpot",
				"payload": Payloads.numeric_resolution_payload(3.0, [5, 4], 0, 20, 42),
				"assert_key": "damage_multiplier",
				"assert_value": 3.5,
				"negative_payload": Payloads.numeric_resolution_payload(1.5, [4, 4], 0, 20, 42)
			},
			{
				"hook": "resolution_before",
				"effect_id": "heavy_crown_die_flat",
				"payload": Payloads.numeric_resolution_payload(1.5, [5, 4], 0, 20, 42),
				"assert_key": "flat_damage_bonus",
				"assert_value": 1,
				"negative_payload": Payloads.numeric_resolution_payload(1.5, [4, 4], 0, 20, 42)
			}
		],
		"sealed_side_box": [
			{
				"hook": "turn_start",
				"effect_id": "sealed_box_opened",
				"payload": {"turn": 1, "cash": 10, "player_block": 0, "applied_effects": []},
				"assert_key": "cash",
				"assert_value": 15,
				"negative_payload": {"turn": 2, "cash": 10, "player_block": 0, "applied_effects": []}
			}
		],
		"paper_shield": [
			{
				"hook": "turn_start",
				"effect_id": "paper_shield_block",
				"payload": {"turn": 1, "player_block": 0, "applied_effects": []},
				"assert_key": "player_block",
				"assert_value": 1,
				"negative_payload": {"turn": 2, "player_block": 0, "applied_effects": []}
			}
		],
		"warm_canteen": [
			{
				"hook": "combat_start",
				"effect_id": "warm_canteen_heal",
				"payload": {"player_hp": 20, "player_max_hp": 42, "applied_effects": []},
				"assert_key": "player_hp",
				"assert_value": 21,
				"negative_payload": {"player_hp": 30, "player_max_hp": 42, "applied_effects": []}
			}
		],
		"snake_receipt": [
			{
				"hook": "dice_result",
				"effect_id": "snake_receipt_gold",
				"payload": Payloads.dice_payload_with_cash([4, 4], "two_dice_sum_attack", 10),
				"assert_key": "cash",
				"assert_value": 11,
				"negative_payload": Payloads.dice_payload_with_cash([4, 5], "two_dice_sum_attack", 10)
			}
		],
		"overdrive_confetti": [
			{
				"hook": "resolution_before",
				"effect_id": "overdrive_confetti_gold",
				"payload": Payloads.numeric_resolution_payload_with_cash(1.5, [3, 4], 0, 20, 42, 10),
				"assert_key": "cash_delta_bonus",
				"assert_value": 1,
				"negative_payload": Payloads.numeric_resolution_payload_with_cash(1.0, [3, 4], 0, 20, 42, 10)
			}
		],
		"jackpot_sparkler": [
			{
				"hook": "resolution_before",
				"effect_id": "jackpot_sparkler_flat",
				"payload": Payloads.numeric_resolution_payload(3.0, [3, 4], 0, 20, 42),
				"assert_key": "flat_damage_bonus",
				"assert_value": 1,
				"negative_payload": Payloads.numeric_resolution_payload(1.5, [3, 4], 0, 20, 42)
			}
		],
		"umbrella_button": [
			{
				"hook": "resolution_before",
				"effect_id": "umbrella_button_soften",
				"payload": Payloads.numeric_resolution_payload(0.5, [3, 4], 0, 20, 42),
				"assert_key": "enemy_damage_delta",
				"assert_value": -1,
				"negative_payload": Payloads.numeric_resolution_payload(1.0, [3, 4], 0, 20, 42)
			}
		],
		"low_stakes_mat": [
			{
				"hook": "resolution_before",
				"effect_id": "low_stakes_flat",
				"payload": Payloads.numeric_resolution_payload_with_wager(1.0, [3, 4], 0, 20, 42, 1),
				"assert_key": "flat_damage_bonus",
				"assert_value": 1,
				"negative_payload": Payloads.numeric_resolution_payload_with_wager(1.0, [3, 4], 0, 20, 42, 2)
			}
		],
		"cashback_chip": [
			{
				"hook": "reward_apply",
				"effect_id": "cashback_chip_gold",
				"payload": {"choice": "shop_leave", "gold_delta": -8, "applied_effects": []},
				"assert_key": "gold_delta",
				"assert_value": -7,
				"negative_payload": {"choice": "combat_reward", "gold_delta": 0, "applied_effects": []}
			}
		],
		"spare_heel": [
			{
				"hook": "damage_taken",
				"effect_id": "spare_heel_prevented",
				"payload": {"damage": 6, "player_hp": 20, "relic_state": {}, "applied_effects": []},
				"assert_key": "damage",
				"assert_value": 5,
				"negative_payload": {"damage": 6, "player_hp": 20, "relic_state": {"spare_heel_used": true}, "applied_effects": []}
			}
		],
		"cleric_face_coin": [
			{
				"hook": "relic_pickup",
				"effect_id": "cleric_coin_pickup",
				"payload": {"picked_relic_id": "cleric_face_coin", "player_hp": 20, "player_max_hp": 42, "applied_effects": []},
				"assert_key": "player_max_hp",
				"assert_value": 44
			}
		],
		"empty_trophy": [
			{
				"hook": "reward_apply",
				"effect_id": "empty_trophy_elite_gold",
				"payload": {"choice": "elite_reward", "gold_delta": 0, "relic_state": {}, "applied_effects": []},
				"assert_key": "gold_delta",
				"assert_value": 7,
				"negative_payload": {"choice": "elite_reward", "gold_delta": 0, "relic_state": {"empty_trophy_used": true}, "applied_effects": []}
			}
		],
		"bent_coin": [
			{
				"hook": "dice_result",
				"effect_id": "bent_coin_gold",
				"payload": Payloads.dice_payload_selected_with_cash([2, 4], "two_dice_sum_attack", 0, 10),
				"assert_key": "cash",
				"assert_value": 11,
				"negative_payload": Payloads.dice_payload_selected_with_cash([3, 4], "two_dice_sum_attack", 0, 10)
			}
		],
		"lazy_susan": [
			{
				"hook": "resolution_before",
				"effect_id": "lazy_susan_gold",
				"payload": Payloads.numeric_resolution_payload_with_wager_and_cash(1.0, [3, 4], 0, 20, 42, 0, 10),
				"assert_key": "cash_delta_bonus",
				"assert_value": 2,
				"negative_payload": Payloads.numeric_resolution_payload_with_wager_and_cash(1.0, [3, 4], 0, 20, 42, 1, 10)
			}
		],
		"regal_pillow_chip": [
			{
				"hook": "reward_apply",
				"effect_id": "regal_pillow_rest",
				"payload": {"choice": "rest_heal", "hp_delta": 8, "applied_effects": []},
				"assert_key": "hp_delta",
				"assert_value": 13,
				"negative_payload": {"choice": "combat_reward", "hp_delta": 8, "applied_effects": []}
			}
		],
		"high_roller_lint": [
			{
				"hook": "marble_gain",
				"effect_id": "high_roller_lint_gold",
				"payload": {"dice_values": [5, 5], "cash": 10, "marble_count": 1, "marbles": ["plain"], "applied_effects": []},
				"assert_key": "cash",
				"assert_value": 11,
				"negative_payload": {"dice_values": [4, 5], "cash": 10, "marble_count": 1, "marbles": ["plain"], "applied_effects": []}
			}
		],
		"bruise_receipt": [
			{
				"hook": "reward_apply",
				"effect_id": "bruise_receipt_heal",
				"payload": {"choice": "combat_reward", "player_hp": 20, "player_max_hp": 42, "hp_delta": 0, "applied_effects": []},
				"assert_key": "hp_delta",
				"assert_value": 3,
				"negative_payload": {"choice": "combat_reward", "player_hp": 30, "player_max_hp": 42, "hp_delta": 0, "applied_effects": []}
			}
		],
		"double_stamp_pad": [
			{
				"hook": "reward_apply",
				"effect_id": "double_stamp_ticket",
				"payload": {"choice": "combat_reward", "contract_tickets_delta": 1, "floor_index": 1, "relic_state": {}, "forced_percent_double_stamp_pad": 0, "applied_effects": []},
				"assert_key": "contract_tickets_delta",
				"assert_value": 2,
				"negative_payload": {"choice": "combat_reward", "contract_tickets_delta": 1, "floor_index": 1, "relic_state": {"double_stamp_floor_1": true}, "forced_percent_double_stamp_pad": 0, "applied_effects": []}
			}
		],
		"upgrade_receipt": [
			{
				"hook": "reward_apply",
				"effect_id": "upgrade_receipt_gold",
				"payload": {"choice": "upgrade_primary_die", "gold_delta": 0, "applied_effects": []},
				"assert_key": "gold_delta",
				"assert_value": 3,
				"negative_payload": {"choice": "combat_reward", "gold_delta": 0, "applied_effects": []}
			}
		],
		"ticket_lint": [
			{
				"hook": "reward_apply",
				"effect_id": "ticket_lint_chance",
				"payload": {"choice": "combat_reward", "ticket_chance": 15, "ticket_roll": 17, "contract_tickets_delta": 0, "relic_state": {"ticket_lint_bonus": 3}, "applied_effects": []},
				"assert_key": "contract_tickets_delta",
				"assert_value": 1,
				"negative_payload": {"choice": "elite_reward", "ticket_chance": 15, "ticket_roll": 17, "contract_tickets_delta": 0, "relic_state": {"ticket_lint_bonus": 3}, "applied_effects": []}
			}
		],
		"quiet_scalper": [
			{
				"hook": "reward_apply",
				"effect_id": "quiet_scalper_ticket",
				"payload": {"choice": "elite_reward", "contract_tickets_delta": 0, "floor_index": 1, "relic_state": {}, "applied_effects": []},
				"assert_key": "contract_tickets_delta",
				"assert_value": 1,
				"negative_payload": {"choice": "elite_reward", "contract_tickets_delta": 0, "floor_index": 1, "relic_state": {"quiet_scalper_floor_1": true}, "applied_effects": []}
			}
		],
		"polite_haggle": [
			{
				"hook": "reward_apply",
				"effect_id": "polite_haggle_heal",
				"payload": {"choice": "shop_leave", "gold": 8, "gold_delta": 0, "hp_delta": 0, "applied_effects": []},
				"assert_key": "hp_delta",
				"assert_value": 3,
				"negative_payload": {"choice": "shop_leave", "gold": 12, "gold_delta": 0, "hp_delta": 0, "applied_effects": []}
			}
		],
		"sample_tray": [
			{
				"hook": "reward_apply",
				"effect_id": "sample_tray_refund",
				"payload": {"choice": "shop_leave", "potion_ids": ["red_vial"], "gold_delta": -10, "applied_effects": []},
				"assert_key": "gold_delta",
				"assert_value": -6,
				"negative_payload": {"choice": "shop_leave", "potion_ids": [], "gold_delta": -10, "applied_effects": []}
			}
		],
		"pocket_map": [
			{
				"hook": "reward_apply",
				"effect_id": "pocket_map_gold",
				"payload": {"choice": "event_card_draw", "floor_index": 1, "gold_delta": 0, "relic_state": {}, "applied_effects": []},
				"assert_key": "gold_delta",
				"assert_value": 2,
				"negative_payload": {"choice": "combat_reward", "floor_index": 1, "gold_delta": 0, "relic_state": {}, "applied_effects": []}
			}
		],
		"stamp_album": [
			{
				"hook": "reward_apply",
				"effect_id": "stamp_album_ticket",
				"payload": {"choice": "event_card_draw", "contract_tickets_delta": 0, "relic_state": {"stamp_album_event_count": 3}, "applied_effects": []},
				"assert_key": "contract_tickets_delta",
				"assert_value": 1,
				"negative_payload": {"choice": "combat_reward", "contract_tickets_delta": 0, "relic_state": {"stamp_album_event_count": 3}, "applied_effects": []}
			}
		],
		"cult_mask_chip": [
			{
				"hook": "reward_apply",
				"effect_id": "cult_mask_gold",
				"payload": {"choice": "combat_reward", "floor_index": 1, "gold_delta": 0, "relic_state": {}, "applied_effects": []},
				"assert_key": "gold_delta",
				"assert_value": 1,
				"negative_payload": {"choice": "combat_reward", "floor_index": 1, "gold_delta": 0, "relic_state": {"cult_mask_floor_1": true}, "applied_effects": []}
			}
		],
		"dealer_smile": [
			{
				"hook": "reward_apply",
				"effect_id": "dealer_smile_ticket",
				"payload": {"choice": "shop_leave", "floor_index": 1, "contract_tickets_delta": 0, "relic_state": {}, "applied_effects": []},
				"assert_key": "contract_tickets_delta",
				"assert_value": 1,
				"negative_payload": {"choice": "shop_leave", "floor_index": 1, "contract_tickets_delta": 0, "relic_state": {"dealer_smile_floor_1": true}, "applied_effects": []}
			}
		],
		"scarred_ticket_punch": [
			{
				"hook": "reward_apply",
				"effect_id": "scarred_elite_ticket",
				"payload": {"choice": "elite_reward", "contract_tickets_delta": 0, "applied_effects": []},
				"assert_key": "contract_tickets_delta",
				"assert_value": 1,
				"negative_payload": {"choice": "combat_reward", "ticket_chance": 15, "ticket_roll": 20, "contract_tickets_delta": 0, "applied_effects": []}
			}
		],
		"elite_souvenir_mask": [
			{
				"hook": "reward_apply",
				"effect_id": "elite_souvenir_heal",
				"payload": {"choice": "elite_reward", "player_hp": 10, "player_max_hp": 42, "hp_delta": 0, "applied_effects": []},
				"assert_key": "hp_delta",
				"assert_value": 11,
				"negative_payload": {"choice": "elite_reward", "player_hp": 30, "player_max_hp": 42, "hp_delta": 0, "applied_effects": []}
			}
		],
		"voucher_forge_contract": [
			{
				"hook": "reward_apply",
				"effect_id": "voucher_forge_refund",
				"payload": {"choice": "ticket_upgrade_voucher", "contract_tickets_delta": -3, "forced_percent_voucher_forge_contract": 0, "applied_effects": []},
				"assert_key": "contract_tickets_delta",
				"assert_value": -2,
				"negative_payload": {"choice": "combat_reward", "contract_tickets_delta": 0, "forced_percent_voucher_forge_contract": 0, "applied_effects": []}
			},
			{
				"hook": "reward_apply",
				"effect_id": "voucher_forge_rest_tax",
				"payload": {"choice": "rest_heal", "hp_delta": 8, "applied_effects": []},
				"assert_key": "hp_delta",
				"assert_value": 6
			}
		],
		"ivory_ambulance": [
			{
				"hook": "relic_pickup",
				"effect_id": "ivory_ambulance_pickup",
				"payload": {"picked_relic_id": "ivory_ambulance", "player_hp": 20, "player_max_hp": 42, "applied_effects": []},
				"assert_key": "player_hp",
				"assert_value": 52
			},
			{
				"hook": "reward_apply",
				"effect_id": "ivory_ambulance_rest_block",
				"payload": {"choice": "rest_heal", "hp_delta": 8, "applied_effects": []},
				"assert_key": "hp_delta",
				"assert_value": 0
			}
		],
		"tiny_house_box": [
			{
				"hook": "relic_pickup",
				"effect_id": "tiny_house_bundle",
				"payload": {"picked_relic_id": "tiny_house_box", "player_hp": 20, "player_max_hp": 42, "gold_delta": 0, "contract_tickets_delta": 0, "potion_ids": [], "applied_effects": []},
				"assert_key": "gold_delta",
				"assert_value": 20
			}
		],
		"ticket_monopoly": [
			{
				"hook": "reward_apply",
				"effect_id": "ticket_monopoly_plus",
				"payload": {"choice": "combat_reward", "contract_tickets_delta": 1, "applied_effects": []},
				"assert_key": "contract_tickets_delta",
				"assert_value": 2,
				"negative_payload": {"choice": "combat_reward", "contract_tickets_delta": 0, "applied_effects": []}
			}
		],
		"strawberry_chip": [
			{
				"hook": "relic_pickup",
				"effect_id": "strawberry_max_hp",
				"payload": {"picked_relic_id": "strawberry_chip", "player_hp": 20, "player_max_hp": 42, "applied_effects": []},
				"assert_key": "player_max_hp",
				"assert_value": 46
			}
		],
		"waffle_stub": [
			{
				"hook": "relic_pickup",
				"effect_id": "waffle_full_heal",
				"payload": {"picked_relic_id": "waffle_stub", "player_hp": 20, "player_max_hp": 42, "applied_effects": []},
				"assert_key": "player_hp",
				"assert_value": 45
			}
		],
		"ticket_primer": [
			{
				"hook": "reward_apply",
				"effect_id": "ticket_primer_chance",
				"payload": {"choice": "combat_reward", "ticket_chance": 15, "ticket_roll": 20, "contract_tickets_delta": 0, "applied_effects": []},
				"assert_key": "contract_tickets_delta",
				"assert_value": 1,
				"negative_payload": {"choice": "elite_reward", "ticket_chance": 100, "ticket_roll": -1, "contract_tickets_delta": 1, "applied_effects": []}
			}
		],
		"punched_ticket": [
			{
				"hook": "reward_apply",
				"effect_id": "punched_ticket_paid",
				"payload": {"choice": "combat_reward", "contract_tickets_delta": 0, "relic_state": {"punched_ticket_count": 2}, "applied_effects": []},
				"assert_key": "contract_tickets_delta",
				"assert_value": 1,
				"negative_payload": {"choice": "elite_reward", "contract_tickets_delta": 0, "relic_state": {"punched_ticket_count": 2}, "applied_effects": []}
			}
		],
		"carbon_copy_coupon": [
			{
				"hook": "reward_apply",
				"effect_id": "carbon_copy_voucher",
				"payload": {"choice": "ticket_upgrade_voucher", "potion_ids": ["upgrade_voucher"], "forced_percent_carbon_copy_coupon": 0, "applied_effects": []},
				"assert_key": "potion_ids",
				"assert_value": ["upgrade_voucher", "upgrade_voucher"],
				"negative_payload": {"choice": "ticket_small_heal", "potion_ids": [], "forced_percent_carbon_copy_coupon": 0, "applied_effects": []}
			}
		],
		"voucher_coupon": [
			{
				"hook": "reward_apply",
				"effect_id": "voucher_coupon_refund",
				"payload": {"choice": "ticket_upgrade_voucher", "contract_tickets_delta": -3, "relic_state": {}, "applied_effects": []},
				"assert_key": "contract_tickets_delta",
				"assert_value": -2,
				"negative_payload": {"choice": "ticket_upgrade_voucher", "contract_tickets_delta": -3, "relic_state": {"voucher_coupon_used": true}, "applied_effects": []}
			}
		],
		"shop_meal_ticket": [
			{
				"hook": "reward_apply",
				"effect_id": "shop_meal_ticket_heal",
				"payload": {"choice": "shop_leave", "hp_delta": 0, "applied_effects": []},
				"assert_key": "hp_delta",
				"assert_value": 6,
				"negative_payload": {"choice": "combat_reward", "hp_delta": 0, "applied_effects": []}
			}
		],
		"rest_change_jar": [
			{
				"hook": "reward_apply",
				"effect_id": "rest_change_gold",
				"payload": {"choice": "rest_heal", "gold_delta": 0, "applied_effects": []},
				"assert_key": "gold_delta",
				"assert_value": 2,
				"negative_payload": {"choice": "combat_reward", "gold_delta": 0, "applied_effects": []}
			}
		],
		"velvet_price_tag": [
			{
				"hook": "reward_apply",
				"effect_id": "velvet_price_refund",
				"payload": {"choice": "shop_leave", "gold_delta": -30, "relic_ids": ["loaded_die"], "applied_effects": []},
				"assert_key": "gold_delta",
				"assert_value": -25,
				"negative_payload": {"choice": "shop_leave", "gold_delta": 0, "relic_ids": [], "applied_effects": []}
			}
		],
		"red_cordial": [
			{
				"hook": "reward_apply",
				"effect_id": "red_cordial_elite_heal",
				"payload": {"choice": "elite_reward", "hp_delta": 0, "reward_tier": "elite", "applied_effects": []},
				"assert_key": "hp_delta",
				"assert_value": 5,
				"negative_payload": {"choice": "combat_reward", "hp_delta": 0, "reward_tier": "normal", "applied_effects": []}
			}
		],
		"tiny_bandage": [
			{
				"hook": "damage_taken",
				"effect_id": "tiny_bandage_prevented",
				"payload": {"damage": 6, "player_hp": 20, "relic_state": {}, "applied_effects": []},
				"assert_key": "damage",
				"assert_value": 4,
				"negative_payload": {"damage": 6, "player_hp": 20, "relic_state": {"tiny_bandage_used": true}, "applied_effects": []}
			}
		],
		"dusty_shelf": [
			{
				"hook": "reward_apply",
				"effect_id": "dusty_shelf_offer",
				"payload": {"choice": "shop_offer_preview", "shop_relic_offer_delta": 0, "applied_effects": []},
				"assert_key": "shop_relic_offer_delta",
				"assert_value": 1
			}
		],
		"appraisal_lens": [
			{
				"hook": "reward_apply",
				"effect_id": "appraisal_lens_option",
				"payload": {"choice": "relic_reward_preview", "reward_tier": "normal", "relic_reward_option_delta": 0, "applied_effects": []},
				"assert_key": "relic_reward_option_delta",
				"assert_value": 1,
				"negative_payload": {"choice": "relic_reward_preview", "reward_tier": "boss", "relic_reward_option_delta": 0, "applied_effects": []}
			}
		],
		"raincheck_tag": [
			{
				"hook": "reward_apply",
				"effect_id": "raincheck_gold",
				"payload": {"choice": "skip_relic_reward", "gold_delta": 0, "applied_effects": []},
				"assert_key": "gold_delta",
				"assert_value": 6
			}
		],
		"brass_stopwatch": [
			{
				"hook": "resolution_before",
				"effect_id": "brass_stopwatch_gold",
				"payload": Payloads.numeric_resolution_payload_with_action(1.0, "stop"),
				"assert_key": "cash_delta_bonus",
				"assert_value": 2
			}
		],
		"redline_tag": [
			{
				"hook": "resolution_before",
				"effect_id": "redline_tag_flat",
				"payload": Payloads.numeric_resolution_payload_with_action(1.5, "go"),
				"assert_key": "flat_damage_bonus",
				"assert_value": 2
			}
		],
		"cautious_pin": [
			{
				"hook": "resolution_before",
				"effect_id": "cautious_pin_block",
				"payload": Payloads.numeric_resolution_payload_with_action(0.5, "stop"),
				"assert_key": "player_block",
				"assert_value": 2
			}
		],
		"cracked_mirror": [
			{
				"hook": "resolution_after",
				"effect_id": "cracked_mirror_set",
				"payload": Payloads.numeric_resolution_payload_with_action(0.0, "go"),
				"assert_key": "relic_state",
				"assert_value": {"cracked_mirror_pending": 3}
			},
			{
				"hook": "turn_start",
				"effect_id": "cracked_mirror_block",
				"payload": {"turn": 2, "player_block": 0, "relic_state": {"cracked_mirror_pending": 3}, "applied_effects": []},
				"assert_key": "player_block",
				"assert_value": 3
			}
		],
		"tin_helmet": [
			{
				"hook": "combat_start",
				"effect_id": "tin_helmet_elite_block",
				"payload": {"monster_tier": "elite", "player_block": 0, "applied_effects": []},
				"assert_key": "player_block",
				"assert_value": 3,
				"negative_payload": {"monster_tier": "normal", "player_block": 0, "applied_effects": []}
			}
		],
		"tiny_mascot": [
			{
				"hook": "reward_apply",
				"effect_id": "tiny_mascot_boss_gold",
				"payload": {"choice": "boss_reward", "reward_tier": "boss", "gold_delta": 0, "applied_effects": []},
				"assert_key": "gold_delta",
				"assert_value": 8
			}
		],
		"souvenir_keyring": [
			{
				"hook": "reward_apply",
				"effect_id": "souvenir_keyring_risk",
				"payload": {"choice": "event_card_draw", "risk_reward_chance_delta": 0, "applied_effects": []},
				"assert_key": "risk_reward_chance_delta",
				"assert_value": 10
			}
		],
		"black_star_stub": [
			{
				"hook": "reward_apply",
				"effect_id": "black_star_option",
				"payload": {"choice": "elite_reward", "reward_tier": "elite", "relic_reward_option_delta": 0, "applied_effects": []},
				"assert_key": "relic_reward_option_delta",
				"assert_value": 1
			}
		],
		"preserved_insect_pin": [
			{
				"hook": "combat_start",
				"effect_id": "preserved_insect_elite_hp",
				"payload": {"monster_tier": "elite", "enemy_hp": 100, "enemy_max_hp": 100, "applied_effects": []},
				"assert_key": "enemy_hp",
				"assert_value": 88
			}
		],
		"gambler_debt": [
			{
				"hook": "combat_start",
				"effect_id": "gambler_debt_wager",
				"payload": {"wager_marbles_available": 1, "applied_effects": []},
				"assert_key": "wager_marbles_available",
				"assert_value": 2
			},
			{
				"hook": "turn_start",
				"effect_id": "gambler_debt_pressure",
				"payload": {"turn": 2, "uncommitted_wager_marbles": 1, "enemy_damage_delta": 0, "applied_effects": []},
				"assert_key": "enemy_damage_delta",
				"assert_value": 1
			}
		],
		"blood_coupon": [
			{
				"hook": "reward_apply",
				"effect_id": "blood_coupon_discount",
				"payload": {"choice": "shop_leave", "gold_delta": -30, "hp_delta": 0, "relic_ids": ["loaded_die"], "applied_effects": []},
				"assert_key": "hp_delta",
				"assert_value": -2
			}
		],
		"all_in_badge": [
			{
				"hook": "resolution_before",
				"effect_id": "all_in_badge_multiplier",
				"payload": Payloads.numeric_resolution_payload_all_in(1.0, 2),
				"assert_key": "damage_multiplier",
				"assert_value": 1.5
			}
		],
		"noon_duel": [
			{
				"hook": "turn_start",
				"effect_id": "noon_duel_early_attack",
				"payload": {"turn": 1, "player_attack_delta": 0, "enemy_damage_delta": 0, "applied_effects": []},
				"assert_key": "player_attack_delta",
				"assert_value": 2
			},
			{
				"hook": "turn_start",
				"effect_id": "noon_duel_late_pressure",
				"payload": {"turn": 3, "player_attack_delta": 0, "enemy_damage_delta": 0, "applied_effects": []},
				"assert_key": "enemy_damage_delta",
				"assert_value": 1
			}
		],
		"red_letter_lease": [
			{
				"hook": "resolution_before",
				"effect_id": "red_letter_go_gold",
				"payload": Payloads.numeric_resolution_payload_with_action(1.5, "go"),
				"assert_key": "cash_delta_bonus",
				"assert_value": 5
			}
		],
		"lucky_jury": [
			{
				"hook": "reward_apply",
				"effect_id": "lucky_jury_ticket",
				"payload": {"choice": "combat_reward", "contract_tickets_delta": 1, "forced_percent_lucky_jury": 0, "applied_effects": []},
				"assert_key": "contract_tickets_delta",
				"assert_value": 2
			},
			{
				"hook": "resolution_after",
				"effect_id": "lucky_jury_bust_tax",
				"payload": Payloads.numeric_outcome_payload(0.0, 10),
				"assert_key": "cash",
				"assert_value": 8
			}
		],
		"cracked_hourglass": [
			{
				"hook": "turn_start",
				"effect_id": "cracked_hourglass_reroll",
				"payload": {"turn": 3, "rerolls_left": 0, "applied_effects": []},
				"assert_key": "rerolls_left",
				"assert_value": 1
			}
		],
		"boss_map_bounty": [
			{
				"hook": "reward_apply",
				"effect_id": "boss_map_option",
				"payload": {"choice": "boss_reward_preview", "boss_relic_option_delta": 0, "applied_effects": []},
				"assert_key": "boss_relic_option_delta",
				"assert_value": 1
			}
		],
		"golden_table": [
			{
				"hook": "combat_start",
				"effect_id": "golden_table_wager",
				"payload": {"wager_marbles_available": 1, "enemy_damage_delta": 0, "applied_effects": []},
				"assert_key": "wager_marbles_available",
				"assert_value": 2
			}
		],
		"royal_voucher_press": [
			{
				"hook": "reward_apply",
				"effect_id": "royal_press_voucher",
				"payload": {"choice": "ticket_upgrade_voucher", "potion_ids": ["upgrade_voucher"], "applied_effects": []},
				"assert_key": "potion_ids",
				"assert_value": ["upgrade_voucher", "upgrade_voucher"]
			}
		],
		"black_star_contract": [
			{
				"hook": "reward_apply",
				"effect_id": "black_star_elite_contract",
				"payload": {"choice": "elite_reward", "reward_tier": "elite", "contract_tickets_delta": 0, "relic_reward_option_delta": 0, "applied_effects": []},
				"assert_key": "contract_tickets_delta",
				"assert_value": 1
			},
			{
				"hook": "reward_apply",
				"effect_id": "black_star_ticket_tax",
				"payload": {"choice": "combat_reward", "ticket_chance": 15, "ticket_roll": 20, "contract_tickets_delta": 0, "applied_effects": []},
				"assert_key": "ticket_chance",
				"assert_value": 5
			}
		],
		"infinite_reroll_key": [
			{
				"hook": "combat_start",
				"effect_id": "infinite_key_reroll",
				"payload": {"rerolls_left_delta": 0, "applied_effects": []},
				"assert_key": "rerolls_left_delta",
				"assert_value": 1
			},
			{
				"hook": "reward_apply",
				"effect_id": "infinite_key_upgrade_tax",
				"payload": {"choice": "upgrade_primary_die", "contract_tickets_delta": 0, "applied_effects": []},
				"assert_key": "contract_tickets_delta",
				"assert_value": -1
			}
		],
		"empty_vault": [
			{
				"hook": "relic_pickup",
				"effect_id": "empty_vault_pickup",
				"payload": {"picked_relic_id": "empty_vault", "gold_delta": 0, "relic_state": {}, "applied_effects": []},
				"assert_key": "gold_delta",
				"assert_value": 80
			},
			{
				"hook": "reward_apply",
				"effect_id": "empty_vault_gold_lock",
				"payload": {"choice": "combat_reward", "gold_delta": 7, "relic_state": {"empty_vault_next_floor": true}, "applied_effects": []},
				"assert_key": "gold_delta",
				"assert_value": 0
			}
		],
		"house_edge_crown": [
			{
				"hook": "roulette_before_spin",
				"effect_id": "house_edge_crown_weights",
				"payload": {"jackpot_weight_delta": 0, "overdrive_weight_delta": 0, "bust_weight_delta": 0, "applied_effects": []},
				"assert_key": "jackpot_weight_delta",
				"assert_value": 1
			}
		],
		"guard_engine_plaque": [
			{
				"hook": "turn_start",
				"effect_id": "guard_engine_block",
				"payload": {"turn": 1, "floor_index": 2, "player_block": 0, "applied_effects": []},
				"assert_key": "player_block",
				"assert_value": 4
			}
		],
		"velvet_choker_chip": [
			{
				"hook": "roulette_before_spin",
				"effect_id": "velvet_choker_go",
				"payload": {"numeric_extra_go_chances": 0, "applied_effects": []},
				"assert_key": "numeric_extra_go_chances",
				"assert_value": 1
			}
		],
		"default_guard_crest": [
			{
				"hook": "turn_start",
				"effect_id": "starting_guard_block",
				"payload": {"turn": 1, "cash": 12, "player_block": 0, "relic_state": {}, "applied_effects": []},
				"assert_key": "player_block",
				"assert_value": 1
			},
			{
				"hook": "turn_start",
				"effect_id": "starting_guard_block",
				"payload": {"turn": 1, "floor_index": 3, "cash": 12, "player_block": 0, "relic_state": {}, "applied_effects": []},
				"assert_key": "player_block",
				"assert_value": 3
			},
			{
				"hook": "damage_taken",
				"effect_id": "guard_counter_damage",
				"payload": {"incoming_damage": 7, "damage": 0, "player_block": 3, "enemy_hp": 20, "relic_state": {}, "applied_effects": []},
				"assert_key": "enemy_hp",
				"assert_value": 17,
				"negative_payload": {"incoming_damage": 7, "damage": 2, "player_block": 0, "enemy_hp": 20, "relic_state": {}, "applied_effects": []}
			}
		],
		"double_attack_crest": [
			{
				"hook": "resolution_after",
				"effect_id": "starting_lifesteal",
				"payload": {"damage": 20, "player_hp": 10, "player_max_hp": 42, "hp_delta": 0, "applied_effects": []},
				"assert_key": "player_hp",
				"assert_value": 12
			},
			{
				"hook": "turn_start",
				"effect_id": "overheal_block_carry",
				"payload": {"turn": 2, "player_block": 0, "relic_state": {"double_attack_overheal_block_pending": 4}, "applied_effects": []},
				"assert_key": "player_block",
				"assert_value": 4
			}
		]
	}
