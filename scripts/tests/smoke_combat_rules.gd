extends SceneTree

const MarbleResolver := preload("res://scripts/systems/marble_resolver.gd")
const RouletteResolver := preload("res://scripts/systems/roulette_resolver.gd")
const RouletteSlotCatalog := preload("res://scripts/systems/roulette_slot_catalog.gd")
const PayoutResolver := preload("res://scripts/systems/payout_resolver.gd")
const DiceResolver := preload("res://scripts/systems/dice_resolver.gd")
const EnemyIntentResolver := preload("res://scripts/systems/enemy_intent_resolver.gd")
const MonsterMoveCatalog := preload("res://scripts/systems/monster_move_catalog.gd")
const CombatState := preload("res://scripts/resources/combat_state.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("combat-rules-smoke-2026-05-09")

	var single_attack: Dictionary = DiceResolver.compute_result([4], [false], "single_attack_die", 2)
	if int(single_attack.get("attack_base", 0)) != 4:
		failures.append("single attack die should use die value as attack_base")
	var twin_attack: Dictionary = DiceResolver.compute_result([2, 5], [false, false], "two_dice_sum_attack", 2)
	if int(twin_attack.get("attack_base", 0)) != 7:
		failures.append("dice rule catalog should allow two dice sum attack without BattleScene semantics")
	var high_attack: Dictionary = DiceResolver.compute_result([2, 5], [false, false], "highest_attack_die", 1)
	if int(high_attack.get("attack_base", 0)) != 5:
		failures.append("dice rule catalog should allow alternate attack modes")
	var guard_choice: Dictionary = DiceResolver.compute_result([2, 5], [false, false], "two_dice_attack_guard", 2, [], 1)
	if int(guard_choice.get("attack_base", 0)) != 5:
		failures.append("attack/guard dice rule should use selected die as attack")
	if int(guard_choice.get("guard_value", 0)) != 2:
		failures.append("attack/guard dice rule should turn unchosen die into guard")

	if MarbleResolver.neutral_token() != "plain":
		failures.append("neutral marble token should be plain")
	if MarbleResolver.token_from_die(1) != "plain" or MarbleResolver.token_from_die(3) != "plain" or MarbleResolver.token_from_die(6) != "plain":
		failures.append("dice values should produce neutral marble tokens, not colors")
	if MarbleResolver.color_from_die(6) != "plain":
		failures.append("legacy color_from_die compatibility should return neutral plain token")
	if MarbleResolver.landing_slot_for_marble("plain", 1.0, rng) == "":
		failures.append("plain attack marble should resolve to a roulette slot")

	var placed: Dictionary = {
		"safe": ["plain", "plain"],
		"profit": ["plain"],
		"jackpot": ["plain"],
		"bust": [],
		"overdrive": []
	}
	for slot_id in RouletteSlotCatalog.slot_ids():
		var slot_def: Dictionary = RouletteSlotCatalog.get_slot(slot_id)
		if not slot_def.has("damage_multiplier") or not slot_def.has("cash_delta"):
			failures.append("roulette slot lacks explicit rule fields: " + slot_id)
	var empty_slots: Dictionary = {
		"safe": [],
		"profit": [],
		"jackpot": [],
		"bust": [],
		"overdrive": []
	}
	var base_weights: Dictionary = RouletteResolver.weights(empty_slots)
	var placed_weights: Dictionary = RouletteResolver.weights(placed)
	if float(base_weights["safe"]) != float(placed_weights["safe"]):
		failures.append("placed marbles should not change roulette odds")
	if float(base_weights["profit"]) != float(placed_weights["profit"]):
		failures.append("placed marbles should boost outcomes, not profit odds")
	var boosted_jackpot: Dictionary = RouletteSlotCatalog.outcome("jackpot", 6, placed)
	if not bool(boosted_jackpot.get("boosted", false)) or int(boosted_jackpot.get("damage", 0)) != 18:
		failures.append("marble on jackpot should use boosted x3 outcome")

	var outcome: Dictionary = PayoutResolver.resolve("profit", empty_slots, 18, 42, 92, 1.0, 6)
	if int(outcome["cash"]) != 18 or int(outcome["cash_delta"]) != 0:
		failures.append("base roulette hit should not change battle winnings")
	if int(outcome["damage"]) != 6 or int(outcome["enemy_hp"]) != 86:
		failures.append("profit result should apply direct attack damage, not cash damage")

	var jackpot: Dictionary = PayoutResolver.resolve("jackpot", empty_slots, 18, 42, 92, 1.0, 6)
	if int(jackpot["damage"]) != 12:
		failures.append("jackpot should double attack damage")

	var bust: Dictionary = PayoutResolver.resolve("bust", empty_slots, 50, 42, 92, 1.0, 6)
	if int(bust["bust_delta"]) != 0:
		failures.append("base miss should not increment legacy bust count")
	if int(bust["damage"]) != 0:
		failures.append("miss should deal zero damage")
	if int(bust["player_hp"]) != 42:
		failures.append("miss should not damage player by default")

	var bust_covered_slots: Dictionary = empty_slots.duplicate(true)
	bust_covered_slots["bust"].append("plain")
	var covered_bust: Dictionary = PayoutResolver.resolve("bust", bust_covered_slots, 50, 42, 92, 1.0, 6)
	if not bool(covered_bust.get("boosted", false)):
		failures.append("marble on bust should mark the bust outcome as boosted")
	if int(covered_bust.get("damage", 0)) != 6 or int(covered_bust.get("bust_delta", 1)) != 0:
		failures.append("marble on bust should turn failure into a straight hit")

	var guarded_hit: Dictionary = PayoutResolver.resolve("profit", empty_slots, 18, 42, 92, 1.0, 6, 0, 0, 4)
	if int(guarded_hit.get("damage", 0)) != 2 or int(guarded_hit.get("enemy_block", 0)) != 0:
		failures.append("enemy block should absorb player damage before HP")
	if int(guarded_hit.get("enemy_block_absorbed", 0)) != 4:
		failures.append("enemy block should report absorbed player damage")

	var cursed_hit: Dictionary = PayoutResolver.resolve("profit", empty_slots, 18, 42, 92, 1.0, 6, 0, 0, 0, 0.5)
	if int(cursed_hit.get("damage", 0)) != 3 or int(cursed_hit.get("pre_curse_damage", 0)) != 6:
		failures.append("curse multiplier should halve final player damage")

	if EnemyIntentResolver.enemy_damage(7, 2, 0) != 5:
		failures.append("enemy damage formula changed unexpectedly")
	var blocked_move: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("hp_strike", {"player_hp": 42, "player_block": 5, "enemy_damage_delta": 0, "cash": 0}, 0)
	if int(blocked_move.get("damage", 0)) != 2 or int(blocked_move.get("player_hp", 0)) != 40:
		failures.append("monster damage should consume player block before HP")
	if int(blocked_move.get("player_block", -1)) != 0 or int(blocked_move.get("block_absorbed", 0)) != 5:
		failures.append("monster damage should report consumed block")

	var state: CombatState = CombatState.new()
	state.reset_slots(RouletteSlotCatalog.slot_ids())
	state.placed_slots["safe"].append("plain")
	if state.placed_count(RouletteSlotCatalog.slot_ids()) != 1:
		failures.append("CombatState placed_count failed")
	if state.slot_token_count("safe", "plain") != 1:
		failures.append("CombatState slot_token_count failed")

	if failures.is_empty():
		print("combat rules smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
