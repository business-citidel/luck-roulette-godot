class_name BattleResolutionOutcomeFlow
extends RefCounted

static func state_patch(snapshot: Dictionary, outcome: Dictionary) -> Dictionary:
	var bust_delta := int(outcome.get("bust_delta", 0))
	var next_player_hp := int(outcome.get("player_hp", snapshot.get("player_hp", 0)))
	var next_enemy_hp := int(outcome.get("enemy_hp", snapshot.get("enemy_hp", 0)))
	var next_busts := int(snapshot.get("busts", 0)) + bust_delta
	var live := next_enemy_hp > 0 and next_player_hp > 0 and next_busts < 2 and not bool(snapshot.get("run_over", false))
	return {
		"last_attack_base": int(outcome.get("attack_base", snapshot.get("attack_base", 0))),
		"last_roulette_multiplier": float(outcome.get("roulette_multiplier", snapshot.get("numeric_roulette_multiplier", 1.0))),
		"last_wager_marbles_committed": int(outcome.get("wager_marbles_committed", snapshot.get("wager_marbles_committed", 0))),
		"last_roulette_go_used": bool(outcome.get("roulette_go_used", snapshot.get("numeric_go_used_this_spin", false))),
		"cash": int(outcome.get("cash", snapshot.get("cash", 0))),
		"player_hp": next_player_hp,
		"enemy_hp": next_enemy_hp,
		"enemy_block": int(outcome.get("enemy_block", snapshot.get("enemy_block", 0))),
		"enemy_damage_delta": int(outcome.get("enemy_damage_delta", snapshot.get("enemy_damage_delta", 0))),
		"player_attack_delta": 0,
		"player_damage_multiplier": 1.0,
		"busts": next_busts,
		"last_applied_effects": outcome.get("applied_effects", []),
		"pending_slot": "",
		"numeric_roulette_index": -1,
		"numeric_roulette_multiplier": 1.0,
		"wager_marbles_committed": 0,
		"numeric_next_go_available": true,
		"numeric_go_chances_left": 1,
		"numeric_pending_intervention_message": "",
		"numeric_go_used_this_spin": false,
		"banner_alpha": 0.0,
		"run_over": not live,
		"phase": "enemy" if live else "result",
		"reset_slots": true,
		"sync_wager_marbles_visual": true
	}
