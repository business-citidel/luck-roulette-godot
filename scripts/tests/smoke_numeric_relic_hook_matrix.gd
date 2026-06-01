extends SceneTree

const RelicEffectResolver := preload("res://scripts/systems/relic_effect_resolver.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_resolution_before_numeric()
	_check_resolution_after_numeric()
	_check_before_spin_numeric()
	if failures.is_empty():
		print("numeric relic hook matrix smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_resolution_before_numeric() -> void:
	var retired_bail: Dictionary = RelicEffectResolver.apply("resolution_before", _numeric_payload(0.0, 1), ["marker_bust_bail"])
	_expect_float(retired_bail, "roulette_multiplier", 0.0, "retired marker_bust_bail must not erase x0")
	var purse: Dictionary = RelicEffectResolver.apply("resolution_before", _numeric_payload(1.5, 1), ["green_purse"])
	_expect_int(purse, "cash_delta_bonus", 4, "green_purse should pay on marked x1.5")
	var tithe: Dictionary = RelicEffectResolver.apply("resolution_before", _numeric_payload(1.5, 0), ["wheel_profit_tithe"])
	_expect_int(tithe, "cash_delta_bonus", 2, "wheel_profit_tithe should pay on x1.5")
	var guard: Dictionary = RelicEffectResolver.apply("resolution_before", _numeric_payload(0.5, 1), ["yellow_guard"])
	_expect_int(guard, "enemy_damage_delta", -2, "yellow_guard should guard marked x0.5")
	var purple: Dictionary = RelicEffectResolver.apply("resolution_before", _numeric_payload(3.0, 1), ["purple_contract"])
	_expect_float(purple, "damage_multiplier", 4.1, "purple_contract should boost marked x3 damage multiplier")
	var overdrive: Dictionary = RelicEffectResolver.apply("resolution_before", _numeric_payload(1.5, 1), ["blue_chisel", "wheel_overdrive_pin"])
	_expect_int(overdrive, "flat_damage_bonus", 4, "overdrive relics should add flat damage on x1.5")
	var no_block: Dictionary = RelicEffectResolver.apply("resolution_before", _numeric_payload(1.0, 0), ["def_no_block"])
	_expect_int(no_block, "enemy_damage_delta", -3, "def_no_block should still work on numeric resolve")
	var first_mark: Dictionary = RelicEffectResolver.apply("resolution_before", _numeric_payload(1.0, 1), ["marker_first_hit"])
	_expect_int(first_mark, "flat_damage_bonus", 3, "marker_first_hit should boost first wagered hit")
	var repeat: Dictionary = RelicEffectResolver.apply("resolution_before", _numeric_payload(1.0, 3), ["marker_repeat_slot"])
	_expect_float(repeat, "damage_multiplier", 2.25, "marker_repeat_slot should reward 3+ wager marbles")

func _check_resolution_after_numeric() -> void:
	var insurance: Dictionary = RelicEffectResolver.apply("resolution_after", _numeric_outcome(0.0, 1, 0), ["bust_insurance"])
	_expect_int(insurance, "player_block", 4, "bust_insurance should bank block on wagered x0")
	var miss: Dictionary = RelicEffectResolver.apply("resolution_after", _numeric_outcome(0.0, 1, 0), ["marker_miss_gold"])
	_expect_int(miss, "cash", 21, "marker_miss_gold should pay on wagered whiff")
	var after_bust: Dictionary = RelicEffectResolver.apply("resolution_after", _numeric_outcome(0.0, 0, 0), ["def_after_bust"])
	var state: Dictionary = after_bust.get("relic_state", {})
	if int(state.get("def_after_bust_pending", 0)) != 3:
		failures.append("def_after_bust should set next-turn block after x0")
	var lifesteal: Dictionary = RelicEffectResolver.apply("resolution_after", _numeric_outcome(1.0, 0, 30), ["double_attack_crest"])
	_expect_int(lifesteal, "player_hp", 33, "double_attack_crest should heal 10 percent of numeric damage")
	var jackpot_lifesteal: Dictionary = RelicEffectResolver.apply("resolution_after", _numeric_outcome(3.0, 0, 30), ["double_attack_crest"])
	_expect_int(jackpot_lifesteal, "player_hp", 36, "double_attack_crest should double numeric jackpot lifesteal")

func _check_before_spin_numeric() -> void:
	var second: Dictionary = RelicEffectResolver.apply("roulette_before_spin", {
		"combat_core": "numeric_roulette",
		"roulette_multiplier": 1.0,
		"numeric_extra_go_chances": 0,
		"applied_effects": []
	}, ["second_chance"])
	_expect_int(second, "numeric_extra_go_chances", 1, "second_chance should add a numeric go chance")

func _numeric_payload(multiplier: float, committed: int) -> Dictionary:
	var wager_multiplier: float = 1.0 + float(clampi(committed, 0, 4)) * 0.25
	return {
		"combat_core": "numeric_roulette",
		"outcome_mode": "numeric_roulette",
		"roulette_multiplier": multiplier,
		"wager_multiplier": wager_multiplier,
		"wager_marbles_committed": committed,
		"attack_base": 4,
		"damage_multiplier": multiplier * wager_multiplier,
		"payout_multiplier": multiplier * wager_multiplier,
		"enemy_damage_delta": 0,
		"player_block": 0,
		"flat_damage_bonus": 0,
		"cash_delta_bonus": 0,
		"relic_state": {},
		"applied_effects": []
	}

func _numeric_outcome(multiplier: float, committed: int, damage: int) -> Dictionary:
	var payload := _numeric_payload(multiplier, committed)
	payload["cash"] = 20
	payload["cash_delta"] = 0
	payload["damage"] = damage
	payload["player_hp"] = 30
	payload["player_max_hp"] = 42
	payload["player_block"] = 0
	payload["message"] = ""
	return payload

func _expect_int(payload: Dictionary, key: String, expected: int, note: String) -> void:
	if int(payload.get(key, -99999)) != expected:
		failures.append(note + " got " + str(payload.get(key)))

func _expect_float(payload: Dictionary, key: String, expected: float, note: String) -> void:
	if abs(float(payload.get(key, -99999.0)) - expected) > 0.001:
		failures.append(note + " got " + str(payload.get(key)))
