class_name MonsterMoveCatalog
extends RefCounted

const UiText := preload("res://scripts/ui/ui_text.gd")

const MOVES := {
	"hp_strike": {
		"id": "hp_strike",
		"label": "Strike",
		"intent": "attack",
		"tags": ["damage"],
		"damage": 7
	},
	"heavy_hp_strike": {
		"id": "heavy_hp_strike",
		"label": "Heavy Strike",
		"intent": "heavy_attack",
		"tags": ["damage", "elite"],
		"damage": 11
	},
	"guarded_stance": {
		"id": "guarded_stance",
		"label": "Guarded Stance",
		"intent": "guard",
		"tags": ["guard"],
		"enemy_block": 8
	},
	"guarded_strike": {
		"id": "guarded_strike",
		"label": "Guarded Strike",
		"intent": "attack+guard",
		"tags": ["damage", "guard"],
		"damage": 5,
		"enemy_block": 4
	},
	"sharpen_odds": {
		"id": "sharpen_odds",
		"label": "Sharpen Odds",
		"intent": "buff",
		"tags": ["buff"],
		"enemy_damage_delta": 2
	},
	"count_up": {
		"id": "count_up",
		"label": "Count Up",
		"intent": "buff",
		"tags": ["buff"],
		"enemy_damage_delta": 3
	},
	"weak_receipt": {
		"id": "weak_receipt",
		"label": "Weak Receipt",
		"intent": "curse",
		"tags": ["curse"],
		"player_damage_multiplier": 0.65
	},
	"marked_stamp": {
		"id": "marked_stamp",
		"label": "Marked Stamp",
		"intent": "curse",
		"tags": ["curse", "marked"],
		"enemy_damage_multiplier": 1.6
	},
	"tax_collection": {
		"id": "tax_collection",
		"label": "Tax Collection",
		"intent": "tax",
		"tags": ["tax"],
		"gold_delta": -4
	},
	"skim_payout": {
		"id": "skim_payout",
		"label": "Skim Payout",
		"intent": "attack+tax",
		"tags": ["damage", "tax"],
		"damage": 4,
		"gold_delta": -3
	},
	"blind_call": {
		"id": "blind_call",
		"label": "Blind Call",
		"intent": "disrupt",
		"tags": ["disrupt"],
		"hidden_intent_turns": 1
	},
	"misdeal_jab": {
		"id": "misdeal_jab",
		"label": "Misdeal Jab",
		"intent": "attack+disrupt",
		"tags": ["damage", "disrupt"],
		"damage": 4,
		"hidden_intent_turns": 1
	},
	"roulette_audit": {
		"id": "roulette_audit",
		"label": "Roulette Audit",
		"intent": "audit",
		"tags": ["audit", "roulette"],
		"conditional_effects": [
				{
					"condition": "last_roulette_go_used",
					"enemy_damage_delta": 3,
					"enemy_damage_delta_tuning": "roulette_audit_damage_delta",
					"effect_id": "enemy_damage_up"
				},
				{
					"condition": "last_roulette_multiplier_lte",
					"threshold": 0.5,
					"threshold_tuning": "roulette_audit_low_multiplier",
					"enemy_block": 5,
					"enemy_block_tuning": "roulette_audit_block",
					"effect_id": "enemy_guard"
				}
			]
	},
	"dice_appraisal": {
		"id": "dice_appraisal",
		"label": "Dice Appraisal",
		"intent": "appraise",
		"tags": ["appraise", "dice"],
		"conditional_effects": [
				{
					"condition": "last_attack_base_gte",
					"threshold": 8,
					"threshold_tuning": "dice_appraisal_attack_threshold",
					"player_damage_multiplier": 0.72,
					"player_damage_multiplier_tuning": "dice_appraisal_damage_multiplier",
					"enemy_block": 4,
					"enemy_block_tuning": "dice_appraisal_block",
					"effect_id": "player_attack_down"
				}
			]
	},
	"guard_tithe": {
		"id": "guard_tithe",
		"label": "Guard Tithe",
		"intent": "tithe",
		"tags": ["tithe", "tax", "guard"],
		"conditional_effects": [
				{
					"condition": "player_block_gte",
					"threshold": 6,
					"threshold_tuning": "guard_tithe_block_threshold",
					"gold_delta": -4,
					"gold_delta_tuning": "guard_tithe_gold",
					"enemy_damage_delta": 1,
					"enemy_damage_delta_tuning": "guard_tithe_damage_delta",
					"effect_id": "cash_taxed"
				}
			]
	}
}

static func get_move(id: String) -> Dictionary:
	return MOVES.get(id, MOVES["hp_strike"]).duplicate(true)

static func has_move(id: String) -> bool:
	return MOVES.has(id)

static func tuned_move(id: String, tuning: Dictionary = {}) -> Dictionary:
	var move := get_move(id)
	var intent := str(move.get("intent", "attack"))
	if move.has("damage"):
		if intent == "heavy_attack":
			move["damage"] = int(tuning.get("heavy_damage", move.get("damage", 0)))
		elif intent == "attack+tax":
			move["damage"] = int(tuning.get("tax_attack_damage", tuning.get("attack_damage", move.get("damage", 0))))
		elif intent == "attack+disrupt":
			move["damage"] = int(tuning.get("disrupt_attack_damage", tuning.get("attack_damage", move.get("damage", 0))))
		elif intent == "attack+guard":
			move["damage"] = int(tuning.get("guard_attack_damage", tuning.get("attack_damage", move.get("damage", 0))))
		else:
			move["damage"] = int(tuning.get("attack_damage", move.get("damage", 0)))
	if move.has("enemy_block"):
		if intent == "attack+guard":
			move["enemy_block"] = int(tuning.get("guarded_strike_block", tuning.get("guard_block", move.get("enemy_block", 0))))
		else:
			move["enemy_block"] = int(tuning.get("guard_block", move.get("enemy_block", 0)))
	if move.has("enemy_damage_delta"):
		if id == "count_up":
			move["enemy_damage_delta"] = int(tuning.get("count_up_delta", tuning.get("buff_delta", move.get("enemy_damage_delta", 0))))
		else:
			move["enemy_damage_delta"] = int(tuning.get("buff_delta", move.get("enemy_damage_delta", 0)))
	if move.has("player_damage_multiplier"):
		move["player_damage_multiplier"] = float(tuning.get("weak_multiplier", move.get("player_damage_multiplier", 1.0)))
	if move.has("enemy_damage_multiplier"):
		move["enemy_damage_multiplier"] = float(tuning.get("marked_multiplier", move.get("enemy_damage_multiplier", 1.0)))
	if move.has("gold_delta"):
		if intent == "attack+tax":
			move["gold_delta"] = -abs(int(tuning.get("skim_gold", abs(int(move.get("gold_delta", 0))))))
		else:
			move["gold_delta"] = -abs(int(tuning.get("tax_gold", abs(int(move.get("gold_delta", 0))))))
	return move

static func intent_text(id: String, tuning: Dictionary = {}) -> String:
	var move := tuned_move(id, tuning)
	var intent := str(move.get("intent", "attack"))
	if intent == "guard":
		return UiText.t("battle.intent.guard", {"amount": int(move.get("enemy_block", 0))})
	if intent == "attack+guard":
		return UiText.t("battle.intent.attack_guard", {
			"damage": int(move.get("damage", 0)),
			"block": int(move.get("enemy_block", 0))
		})
	if intent == "buff":
		return UiText.t("battle.intent.buff", {"amount": int(move.get("enemy_damage_delta", 0))})
	if intent == "curse":
		if move.has("player_damage_multiplier"):
			return UiText.t("battle.intent.curse_weak_final", {"percent": int(round(float(move.get("player_damage_multiplier", 1.0)) * 100.0))})
		if move.has("enemy_damage_multiplier"):
			return UiText.t("battle.intent.curse_mark_double", {"multiplier": snapped(float(move.get("enemy_damage_multiplier", 1.0)), 0.1)})
		return UiText.t("battle.intent.curse_mark", {"amount": int(move.get("enemy_damage_delta", 0))})
	if intent == "tax":
		return UiText.t("battle.intent.tax", {"amount": abs(int(move.get("gold_delta", move.get("cash_delta", 0))))})
	if intent == "attack+tax":
		return UiText.t("battle.intent.attack_tax", {
			"damage": int(move.get("damage", 0)),
			"amount": abs(int(move.get("gold_delta", move.get("cash_delta", 0))))
		})
	if intent == "disrupt":
		return UiText.t("battle.intent.disrupt")
	if intent == "attack+disrupt":
		return UiText.t("battle.intent.attack_disrupt", {"damage": int(move.get("damage", 0))})
	if intent == "audit":
		return UiText.t("battle.intent.audit")
	if intent == "appraise":
		return UiText.t("battle.intent.appraise")
	if intent == "tithe":
		return UiText.t("battle.intent.tithe")
	if move.has("damage"):
		return UiText.t("battle.intent.damage", {"amount": int(move.get("damage", 0))})
	return id

static func hidden_intent_text() -> String:
	return UiText.t("battle.intent.hidden")

static func label(id: String) -> String:
	return str(get_move(id).get("label", id))

static func move_for_turn(pattern: Array, turn: int) -> String:
	if pattern.is_empty():
		return "hp_strike"
	var index: int = max(0, turn - 1) % pattern.size()
	return str(pattern[index])

static func next_move_for_turn(pattern: Array, turn: int) -> String:
	if pattern.is_empty():
		return "hp_strike"
	var index: int = max(0, turn) % pattern.size()
	return str(pattern[index])

static func resolve_enemy_turn(move_id: String, state: Dictionary, reduction: int = 0) -> Dictionary:
	var tuning := _tuning_dict(state.get("pattern_tuning", {}))
	var move := tuned_move(move_id, tuning)
	var cash: int = int(state.get("cash", state.get("winnings", 0)))
	var player_hp: int = int(state.get("player_hp", 42))
	var player_block: int = max(0, int(state.get("player_block", 0)))
	var enemy_block: int = max(0, int(state.get("enemy_block", 0)))
	var player_attack_delta: int = int(state.get("player_attack_delta", 0))
	var player_damage_multiplier: float = float(state.get("player_damage_multiplier", 1.0))
	var enemy_damage_multiplier: float = float(state.get("enemy_damage_multiplier", 1.0))
	var run_gold: int = max(0, int(state.get("run_gold", state.get("gold", 0))))
	var last_attack_base: int = int(state.get("last_attack_base", state.get("attack_base", 0)))
	var last_roulette_multiplier: float = float(state.get("last_roulette_multiplier", state.get("roulette_multiplier", 1.0)))
	var last_roulette_go_used: bool = bool(state.get("last_roulette_go_used", state.get("roulette_go_used", false)))
	var last_wager_marbles_committed: int = int(state.get("last_wager_marbles_committed", state.get("wager_marbles_committed", 0)))
	var base_damage: int = int(move.get("damage", 0))
	var damage_delta: int = int(state.get("enemy_damage_delta", state.get("damage_delta", 0)))
	var incoming_damage: int = max(0, int(ceil(float(base_damage + damage_delta) * enemy_damage_multiplier)) - reduction) if base_damage > 0 else 0
	var block_absorbed: int = min(player_block, incoming_damage)
	var damage: int = max(0, incoming_damage - block_absorbed)
	var cash_delta: int = int(move.get("cash_delta", 0))
	var gold_delta_raw: int = int(move.get("gold_delta", 0))
	var gold_loss: int = min(run_gold, abs(gold_delta_raw)) if gold_delta_raw < 0 else 0
	var gold_delta: int = -gold_loss if gold_delta_raw < 0 else gold_delta_raw
	var enemy_block_delta: int = int(move.get("enemy_block", 0))
	var move_damage_delta: int = int(move.get("enemy_damage_delta", 0))
	if gold_delta_raw < 0 and gold_loss <= 0:
		move_damage_delta += int(move.get("empty_purse_enemy_damage_delta", 0))
	var move_enemy_damage_multiplier: float = float(move.get("enemy_damage_multiplier", 1.0))
	var player_attack_delta_next: int = player_attack_delta + int(move.get("player_attack_delta", 0))
	var player_damage_multiplier_next: float = player_damage_multiplier
	if move.has("player_damage_multiplier"):
		player_damage_multiplier_next *= float(move.get("player_damage_multiplier", 1.0))
	var enemy_damage_multiplier_next: float = 1.0 if base_damage > 0 else enemy_damage_multiplier * move_enemy_damage_multiplier
	var hidden_intent_turns: int = int(move.get("hidden_intent_turns", 0))
	var effects: Array = []
	if damage > 0:
		effects.append({
			"source_id": move_id,
			"effect_id": "hp_damage",
			"name": str(move.get("label", move_id))
		})
	if enemy_block_delta > 0:
		effects.append({
			"source_id": move_id,
			"effect_id": "enemy_guard",
			"name": str(move.get("label", move_id))
		})
	if move_damage_delta > 0 or move_enemy_damage_multiplier > 1.0:
		effects.append({
			"source_id": move_id,
			"effect_id": "enemy_damage_up",
			"name": str(move.get("label", move_id))
		})
	if int(move.get("player_attack_delta", 0)) < 0 or float(move.get("player_damage_multiplier", 1.0)) < 1.0:
		effects.append({
			"source_id": move_id,
			"effect_id": "player_attack_down",
			"name": str(move.get("label", move_id))
		})
	if cash_delta < 0 or gold_delta_raw < 0:
		effects.append({
			"source_id": move_id,
			"effect_id": "cash_taxed",
			"name": str(move.get("label", move_id))
		})
	if hidden_intent_turns > 0:
		effects.append({
			"source_id": move_id,
			"effect_id": "intent_hidden",
			"name": str(move.get("label", move_id))
		})
	var conditional_state := {
		"last_attack_base": last_attack_base,
		"last_roulette_multiplier": last_roulette_multiplier,
		"last_roulette_go_used": last_roulette_go_used,
		"last_wager_marbles_committed": last_wager_marbles_committed,
		"player_block": player_block
	}
	var conditional_result := _apply_conditional_effects(move_id, move, conditional_state, tuning, {
		"enemy_block_delta": enemy_block_delta,
		"move_damage_delta": move_damage_delta,
		"gold_delta": gold_delta,
		"run_gold": run_gold,
		"player_damage_multiplier_next": player_damage_multiplier_next,
		"effects": effects
	})
	enemy_block_delta = int(conditional_result.get("enemy_block_delta", enemy_block_delta))
	move_damage_delta = int(conditional_result.get("move_damage_delta", move_damage_delta))
	gold_delta = int(conditional_result.get("gold_delta", gold_delta))
	player_damage_multiplier_next = float(conditional_result.get("player_damage_multiplier_next", player_damage_multiplier_next))
	effects = conditional_result.get("effects", effects)
	return {
		"accepted": true,
		"move_id": move_id,
		"move_label": str(move.get("label", move_id)),
		"damage": damage,
		"incoming_damage": incoming_damage,
		"block_absorbed": block_absorbed,
		"player_block": max(0, player_block - block_absorbed),
		"player_hp": max(0, player_hp - damage),
		"cash": max(0, cash + cash_delta),
		"winnings": max(0, cash + cash_delta),
		"cash_delta": cash_delta,
		"run_gold": max(0, run_gold + gold_delta),
		"gold": max(0, run_gold + gold_delta),
		"gold_delta": gold_delta,
		"enemy_block": max(0, enemy_block + enemy_block_delta),
		"enemy_damage_delta": (0 if base_damage > 0 else damage_delta) + move_damage_delta,
		"enemy_damage_multiplier": enemy_damage_multiplier_next,
		"player_attack_delta": player_attack_delta_next,
		"player_damage_multiplier": player_damage_multiplier_next,
		"hidden_intent_turns": hidden_intent_turns,
		"applied_effects": effects,
		"message": str(move.get("label", move_id)) + " resolved."
	}

static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result

static func _tuning_dict(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary)
	return {}

static func _apply_conditional_effects(move_id: String, move: Dictionary, state: Dictionary, tuning: Dictionary, result: Dictionary) -> Dictionary:
	var next_result := result.duplicate(true)
	var effects: Array = next_result.get("effects", [])
	for item in move.get("conditional_effects", []):
		if not item is Dictionary:
			continue
		var condition: Dictionary = item
		if not _condition_matches(condition, state, tuning):
			continue
		var effect_id := str(condition.get("effect_id", "enemy_damage_up"))
		var label := str(move.get("label", move_id))
		if condition.has("enemy_block"):
			next_result["enemy_block_delta"] = int(next_result.get("enemy_block_delta", 0)) + _condition_int(condition, "enemy_block", tuning)
		if condition.has("enemy_damage_delta"):
			next_result["move_damage_delta"] = int(next_result.get("move_damage_delta", 0)) + _condition_int(condition, "enemy_damage_delta", tuning)
		if condition.has("gold_delta"):
			var desired_delta: int = _condition_int(condition, "gold_delta", tuning)
			if desired_delta < 0:
				var available_gold: int = max(0, int(next_result.get("run_gold", 0)) + int(next_result.get("gold_delta", 0)))
				next_result["gold_delta"] = int(next_result.get("gold_delta", 0)) - min(available_gold, abs(desired_delta))
			else:
				next_result["gold_delta"] = int(next_result.get("gold_delta", 0)) + desired_delta
		if condition.has("player_damage_multiplier"):
			next_result["player_damage_multiplier_next"] = float(next_result.get("player_damage_multiplier_next", 1.0)) * _condition_float(condition, "player_damage_multiplier", tuning)
		effects.append({
			"source_id": move_id,
			"effect_id": effect_id,
			"name": label
		})
	next_result["effects"] = effects
	return next_result

static func _condition_matches(condition: Dictionary, state: Dictionary, tuning: Dictionary) -> bool:
	var kind := str(condition.get("condition", ""))
	match kind:
		"last_attack_base_gte":
			return int(state.get("last_attack_base", 0)) >= _condition_int(condition, "threshold", tuning)
		"player_block_gte":
			return int(state.get("player_block", 0)) >= _condition_int(condition, "threshold", tuning)
		"last_roulette_multiplier_lte":
			return float(state.get("last_roulette_multiplier", 1.0)) <= _condition_float(condition, "threshold", tuning)
		"last_roulette_go_used":
			return bool(state.get("last_roulette_go_used", false))
		"last_wager_marbles_committed_gte":
			return int(state.get("last_wager_marbles_committed", 0)) >= _condition_int(condition, "threshold", tuning)
	return false

static func _condition_int(condition: Dictionary, key: String, tuning: Dictionary) -> int:
	var tuning_key := str(condition.get(key + "_tuning", ""))
	if tuning_key != "":
		return int(tuning.get(tuning_key, condition.get(key, 0)))
	return int(condition.get(key, 0))

static func _condition_float(condition: Dictionary, key: String, tuning: Dictionary) -> float:
	var tuning_key := str(condition.get(key + "_tuning", ""))
	if tuning_key != "":
		return float(tuning.get(tuning_key, condition.get(key, 0.0)))
	return float(condition.get(key, 0.0))
