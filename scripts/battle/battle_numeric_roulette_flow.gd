class_name BattleNumericRouletteFlow
extends RefCounted

const NumericRouletteResolver := preload("res://scripts/systems/numeric_roulette_resolver.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

static func commit_wager_state(wager_marbles_available: int, wager_marbles_committed: int) -> Dictionary:
	var committed := clampi(wager_marbles_committed, 0, wager_marbles_available)
	return {
		"wager_marbles_committed": committed,
		"wager_marbles_available": max(0, wager_marbles_available - committed)
	}

static func roulette_before_spin_payload(snapshot: Dictionary) -> Dictionary:
	return {
		"attack_base": int(snapshot.get("attack_base", 0)),
		"wager_marbles_committed": int(snapshot.get("wager_marbles_committed", 0)),
		"wager_marbles_available": int(snapshot.get("wager_marbles_available", 0)),
		"roulette_multiplier": float(snapshot.get("numeric_roulette_multiplier", 1.0)),
		"relic_state": snapshot.get("relic_state", {}),
		"seed": int(snapshot.get("seed", 0)),
		"wheel_angle": float(snapshot.get("wheel_angle", 0.0))
	}

static func open_spin_state(snapshot: Dictionary, spin_payload: Dictionary, spin_result: Dictionary) -> Dictionary:
	var committed := int(snapshot.get("wager_marbles_committed", 0))
	var state := spin_state(spin_result, committed)
	var go_cap: int = max(1, int(spin_payload.get("numeric_go_per_turn_cap", 999)))
	var go_chances: int = 1 + max(0, int(spin_payload.get("numeric_extra_go_chances", 0))) + int(snapshot.get("potion_extra_go_chances", 0))
	go_chances = min(go_chances, go_cap)
	return {
		"numeric_go_chances_left": go_chances,
		"numeric_go_per_turn_cap": go_cap,
		"potion_extra_go_chances": 0,
		"numeric_roulette_index": int(state.get("index", -1)),
		"numeric_roulette_multiplier": float(state.get("multiplier", 1.0)),
		"damage_multiplier": float(state.get("damage_multiplier", 1.0)),
		"payout_multiplier": float(state.get("payout_multiplier", 1.0)),
		"pending_slot": str(state.get("pending_slot", "")),
		"spin_locked": true,
		"phase": "spinning",
		"numeric_go_available": false,
		"numeric_next_go_available": true,
		"numeric_pending_intervention_message": "",
		"wheel_tick_segment": -1,
		"wheel_tick_flash": 0.0,
		"wheel_pointer_kick": 0.0,
		"spin_ready_flash": 0.0,
		"banner_text": UiText.t("battle.banner.roulette_start"),
		"banner_alpha": 1.0,
		"message": UiText.t("battle.message.numeric_roulette_start", {
			"committed": committed,
			"wager": NumericRouletteResolver.multiplier_label(NumericRouletteResolver.wager_multiplier(committed))
		})
	}

static func roulette_after_spin_payload(snapshot: Dictionary) -> Dictionary:
	return {
		"combat_core": snapshot.get("combat_core", "numeric_roulette"),
		"outcome_mode": "numeric_roulette",
		"pending_slot": str(snapshot.get("pending_slot", "")),
		"cash": int(snapshot.get("cash", 0)),
		"cash_delta": 0,
		"attack_base": int(snapshot.get("attack_base", 0)),
		"roulette_multiplier": float(snapshot.get("numeric_roulette_multiplier", 1.0)),
		"wager_multiplier": NumericRouletteResolver.wager_multiplier(int(snapshot.get("wager_marbles_committed", 0))),
		"wager_marbles_committed": int(snapshot.get("wager_marbles_committed", 0)),
		"wager_marbles_available": int(snapshot.get("wager_marbles_available", 0)),
		"relic_state": snapshot.get("relic_state", {}),
		"applied_effects": []
	}

static func intervention_state(snapshot: Dictionary) -> Dictionary:
	var multiplier := float(snapshot.get("numeric_roulette_multiplier", 1.0))
	var committed := int(snapshot.get("wager_marbles_committed", 0))
	var pending_message := str(snapshot.get("numeric_pending_intervention_message", ""))
	var message := pending_message
	if message == "":
		message = UiText.t("battle.message.numeric_roulette_preview", {
			"roulette": NumericRouletteResolver.multiplier_label(multiplier),
			"wager": NumericRouletteResolver.multiplier_label(NumericRouletteResolver.wager_multiplier(committed)),
			"damage": int(snapshot.get("preview_damage", 0))
		})
	return {
		"spin_locked": false,
		"phase": "intervene",
		"numeric_go_available": bool(snapshot.get("numeric_next_go_available", true)) and int(snapshot.get("numeric_go_chances_left", 0)) > 0,
		"numeric_pending_intervention_message": "",
		"wheel_pointer_kick": 1.0,
		"wheel_tick_flash": 1.0,
		"banner_text": NumericRouletteResolver.multiplier_label(multiplier) + "?",
		"banner_alpha": 1.0,
		"message": message
	}

static func go_spin_state(snapshot: Dictionary, spin_result: Dictionary) -> Dictionary:
	var previous_multiplier := float(snapshot.get("numeric_roulette_multiplier", 1.0))
	var committed := int(snapshot.get("wager_marbles_committed", 0))
	var state := spin_state(spin_result, committed)
	var next_multiplier := float(state.get("multiplier", 1.0))
	var damage := float(state.get("damage_multiplier", 1.0))
	var payout := float(state.get("payout_multiplier", damage))
	if next_multiplier <= previous_multiplier:
		next_multiplier = 0.0
		damage = 0.0
		payout = 0.0
	return {
		"numeric_go_used_this_spin": true,
		"numeric_go_chances_left": max(0, int(snapshot.get("numeric_go_chances_left", 0)) - 1),
		"numeric_roulette_index": int(state.get("index", -1)),
		"numeric_roulette_multiplier": next_multiplier,
		"damage_multiplier": damage,
		"payout_multiplier": payout,
		"pending_slot": str(state.get("pending_slot", "")),
		"numeric_go_available": false,
		"phase": "spinning",
		"spin_locked": true,
		"wheel_tick_segment": -1,
		"wheel_tick_flash": 0.0,
		"wheel_pointer_kick": 0.0,
		"banner_text": UiText.t("battle.banner.roulette_start"),
		"banner_alpha": 1.0,
		"message": UiText.t("battle.message.numeric_roulette_start", {
			"committed": committed,
			"wager": NumericRouletteResolver.multiplier_label(NumericRouletteResolver.wager_multiplier(committed))
		})
	}

static func resolution_before_payload(snapshot: Dictionary) -> Dictionary:
	return {
		"pending_slot": str(snapshot.get("pending_slot", "")),
		"outcome_mode": "numeric_roulette",
		"combat_core": snapshot.get("combat_core", "numeric_roulette"),
		"cash": int(snapshot.get("cash", 0)),
		"run_gold": int(snapshot.get("run_gold", 0)),
		"gold_delta": int(snapshot.get("gold_delta", 0)),
		"player_hp": int(snapshot.get("player_hp", 0)),
		"player_max_hp": int(snapshot.get("player_max_hp", 0)),
		"player_block": int(snapshot.get("player_block", 0)),
		"enemy_hp": int(snapshot.get("enemy_hp", 0)),
		"enemy_block": int(snapshot.get("enemy_block", 0)),
		"enemy_damage_delta": int(snapshot.get("enemy_damage_delta", 0)),
		"enemy_damage_multiplier": float(snapshot.get("enemy_damage_multiplier", 1.0)),
		"attack_base": int(snapshot.get("attack_base", 0)),
		"dice_values": (snapshot.get("dice_values", []) as Array).duplicate(),
		"dice_rule_id": str(snapshot.get("dice_rule_id", "")),
		"selected_attack_die_index": int(snapshot.get("selected_attack_die_index", -1)),
		"player_attack_delta": int(snapshot.get("player_attack_delta", 0)),
		"player_damage_multiplier": float(snapshot.get("player_damage_multiplier", 1.0)),
		"roulette_multiplier": float(snapshot.get("numeric_roulette_multiplier", 1.0)),
		"wager_multiplier": NumericRouletteResolver.wager_multiplier(int(snapshot.get("wager_marbles_committed", 0))),
		"damage_multiplier": float(snapshot.get("damage_multiplier", 1.0)),
		"payout_multiplier": float(snapshot.get("damage_multiplier", 1.0)),
		"wager_marbles_committed": int(snapshot.get("wager_marbles_committed", 0)),
		"wager_marbles_available": int(snapshot.get("wager_marbles_available", 0)),
		"roulette_go_used": bool(snapshot.get("numeric_go_used_this_spin", false)),
		"flat_damage_bonus": 0,
		"cash_delta_bonus": 0,
		"placed_slots": snapshot.get("placed_slots", {}),
		"relic_state": snapshot.get("relic_state", {})
	}

static func resolution_outcome(payload: Dictionary, snapshot: Dictionary, jackpot_bonus: int) -> Dictionary:
	var attack_value := int(payload.get("attack_base", snapshot.get("attack_base", 0)))
	var resolved_damage_multiplier: float = max(0.0, float(payload.get("damage_multiplier", snapshot.get("damage_multiplier", 1.0))))
	var pre_curse_damage: int = max(0, int(round(float(attack_value) * resolved_damage_multiplier)) + int(payload.get("flat_damage_bonus", 0)) + jackpot_bonus)
	var pre_block_damage: int = max(0, int(floor(float(pre_curse_damage) * max(0.0, float(payload.get("player_damage_multiplier", snapshot.get("player_damage_multiplier", 1.0)))))))
	var blocked_damage: int = min(max(0, int(payload.get("enemy_block", snapshot.get("enemy_block", 0)))), pre_block_damage)
	var damage: int = max(0, pre_block_damage - blocked_damage)
	var next_enemy_block: int = max(0, int(payload.get("enemy_block", snapshot.get("enemy_block", 0))) - blocked_damage)
	var cash_delta := int(payload.get("cash_delta_bonus", 0))
	var committed := int(payload.get("wager_marbles_committed", snapshot.get("wager_marbles_committed", 0)))
	return {
		"pending_slot": str(payload.get("pending_slot", snapshot.get("pending_slot", ""))),
		"outcome_mode": "numeric_roulette",
		"combat_core": snapshot.get("combat_core", "numeric_roulette"),
		"profit": max(0, cash_delta),
		"cash": max(0, int(payload.get("cash", snapshot.get("cash", 0))) + cash_delta),
		"cash_delta": cash_delta,
		"run_gold": int(snapshot.get("run_gold", 0)),
		"gold_delta": int(snapshot.get("gold_delta", 0)),
		"player_hp": int(payload.get("player_hp", snapshot.get("player_hp", 0))),
		"player_max_hp": int(payload.get("player_max_hp", snapshot.get("player_max_hp", 0))),
		"player_block": int(payload.get("player_block", snapshot.get("player_block", 0))),
		"enemy_hp": max(0, int(payload.get("enemy_hp", snapshot.get("enemy_hp", 0))) - damage),
		"enemy_block": next_enemy_block,
		"enemy_damage_delta": int(payload.get("enemy_damage_delta", snapshot.get("enemy_damage_delta", 0))),
		"damage": damage,
		"raw_damage": pre_block_damage,
		"pre_curse_damage": pre_curse_damage,
		"block_absorbed": blocked_damage,
		"potion_jackpot_damage_bonus": jackpot_bonus,
		"bust_delta": 0,
		"attack_base": attack_value,
		"dice_values": payload.get("dice_values", []),
		"dice_rule_id": str(payload.get("dice_rule_id", snapshot.get("dice_rule_id", ""))),
		"selected_attack_die_index": int(payload.get("selected_attack_die_index", snapshot.get("selected_attack_die_index", -1))),
		"roulette_multiplier": float(payload.get("roulette_multiplier", snapshot.get("numeric_roulette_multiplier", 1.0))),
		"wager_multiplier": float(payload.get("wager_multiplier", NumericRouletteResolver.wager_multiplier(committed))),
		"damage_multiplier": resolved_damage_multiplier,
		"payout_multiplier": resolved_damage_multiplier,
		"wager_marbles_committed": committed,
		"wager_marbles_available": int(payload.get("wager_marbles_available", snapshot.get("wager_marbles_available", 0))),
		"roulette_go_used": bool(payload.get("roulette_go_used", snapshot.get("numeric_go_used_this_spin", false))),
		"placed_slots": snapshot.get("placed_slots", {}),
		"relic_state": snapshot.get("relic_state", {}),
		"banner": "HIT " + str(damage) if damage > 0 else "NO DAMAGE",
		"message": UiText.t("battle.message.numeric_damage", {
			"attack": attack_value,
			"roulette": NumericRouletteResolver.multiplier_label(float(payload.get("roulette_multiplier", snapshot.get("numeric_roulette_multiplier", 1.0)))),
			"wager": NumericRouletteResolver.multiplier_label(float(payload.get("wager_multiplier", NumericRouletteResolver.wager_multiplier(committed)))),
			"damage": damage
		})
	}

static func weighted_indices(active_run_upgrades: Dictionary, spin_payload: Dictionary) -> Array[int]:
	var weighted: Array[int] = []
	for i in range(NumericRouletteResolver.cell_count()):
		weighted.append(i)
	for i in range(NumericRouletteResolver.cell_count()):
		var multiplier := NumericRouletteResolver.multiplier_for_index(i, active_run_upgrades)
		var extra := 0
		if multiplier <= 0.001:
			extra += max(0, int(spin_payload.get("bust_weight_delta", 0)))
		elif multiplier >= 3.0:
			extra += max(0, int(spin_payload.get("jackpot_weight_delta", 0)))
		elif multiplier >= 1.5:
			extra += max(0, int(spin_payload.get("overdrive_weight_delta", 0)))
		for _j in range(extra):
			weighted.append(i)
	return weighted

static func target_wheel_delta(index: int, wheel_angle: float, rotations: int = 2) -> float:
	var count := NumericRouletteResolver.cell_count()
	if count <= 0:
		return 360.0 * float(max(1, rotations))
	var step := 360.0 / float(count)
	var target_angle := -float(wrapi(index, 0, count)) * step
	var current_angle := fposmod(wheel_angle, 360.0)
	var delta := fposmod(target_angle - current_angle, 360.0)
	return delta + 360.0 * float(max(1, rotations))

static func spin_state(spin_result: Dictionary, wager_marbles_committed: int) -> Dictionary:
	var multiplier := float(spin_result.get("multiplier", 1.0))
	var damage_multiplier := multiplier * NumericRouletteResolver.wager_multiplier(wager_marbles_committed)
	return {
		"index": int(spin_result.get("index", -1)),
		"multiplier": multiplier,
		"damage_multiplier": damage_multiplier,
		"payout_multiplier": damage_multiplier,
		"pending_slot": "numeric_" + str(int(spin_result.get("index", -1)))
	}

static func preview_damage(attack_value: int, damage_multiplier: float, flat_bonus: int, player_damage_multiplier: float) -> int:
	var pre_curse_damage: int = max(0, int(round(float(attack_value) * max(0.0, damage_multiplier))) + flat_bonus)
	return max(0, int(floor(float(pre_curse_damage) * max(0.0, player_damage_multiplier))))
