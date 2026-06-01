class_name BattleVisualLayerSnapshots
extends RefCounted

const NumericRouletteResolver := preload("res://scripts/systems/numeric_roulette_resolver.gd")

static func table_state(snapshot: Dictionary) -> Dictionary:
	return {
		"table_pulse": float(snapshot.get("table_pulse", 0.0)),
		"table_hit_flash": float(snapshot.get("table_hit_flash", 0.0)),
		"wheel_angle": float(snapshot.get("wheel_angle", -90.0)),
		"wheel_tick_flash": float(snapshot.get("wheel_tick_flash", 0.0)),
		"wheel_pointer_kick": float(snapshot.get("wheel_pointer_kick", 0.0)),
		"placed_slots": snapshot.get("placed_slots", {}),
		"pending_slot": str(snapshot.get("pending_slot", "")),
		"slot_feedback_id": str(snapshot.get("slot_feedback_id", "")),
		"slot_feedback_alpha": float(snapshot.get("slot_feedback_alpha", 0.0)),
		"spin_ready_flash": float(snapshot.get("spin_ready_flash", 0.0)),
		"marble_setup_ready": bool(snapshot.get("marble_setup_ready", false)),
		"hovered_slot_id": str(snapshot.get("hovered_slot_id", "")),
		"hovered_spin_wheel": bool(snapshot.get("hovered_spin_wheel", false)),
		"coin_particles": snapshot.get("coin_particles", []),
		"active_phase": str(snapshot.get("phase", "")),
		"numeric_roulette_cells": NumericRouletteResolver.cells(snapshot.get("active_run_upgrades", {})) if bool(snapshot.get("is_numeric_core", false)) else [],
		"numeric_roulette_index": int(snapshot.get("numeric_roulette_index", -1)),
		"numeric_roulette_multiplier": float(snapshot.get("numeric_roulette_multiplier", 1.0)),
		"wager_marbles_available": int(snapshot.get("wager_marbles_available", 0)),
		"wager_marbles_committed": int(snapshot.get("wager_marbles_committed", 0))
	}

static func hand_state(snapshot: Dictionary) -> Dictionary:
	return {
		"dice": snapshot.get("dice", []),
		"dice_locked": snapshot.get("dice_locked", []),
		"dice_rolled": bool(snapshot.get("dice_rolled", false)),
		"rerolls_left": int(snapshot.get("rerolls_left", 0)),
		"attack_base": int(snapshot.get("attack_base", 0)),
		"selected_attack_die_index": int(snapshot.get("selected_attack_die_index", -1)),
		"guard_value": int(snapshot.get("guard_value", 0)),
		"player_block": int(snapshot.get("player_block", 0)),
		"hovered_attack_die_index": int(snapshot.get("hovered_attack_die_index", -1)),
		"dice_roll_fx": float(snapshot.get("dice_roll_fx", 0.0)),
		"dice_roll_in_progress": bool(snapshot.get("dice_roll_in_progress", false)),
		"marbles": snapshot.get("marbles", []),
		"stored": snapshot.get("stored", []),
		"throwing_hand": bool(snapshot.get("throwing_hand", false)),
		"hand_start_pos": snapshot.get("hand_start_pos", Vector2.ZERO),
		"hand_pos": snapshot.get("hand_pos", Vector2.ZERO),
		"hand_shake": float(snapshot.get("hand_shake", 0.0)),
		"hand_velocity": snapshot.get("hand_velocity", Vector2.ZERO),
		"hand_marble_preview": snapshot.get("hand_marble_preview", []),
		"thrown_marbles": snapshot.get("thrown_marbles", []),
		"marble_feedback_pos": snapshot.get("marble_feedback_pos", Vector2.ZERO),
		"marble_feedback_color": snapshot.get("marble_feedback_color", Color.WHITE),
		"marble_feedback_alpha": float(snapshot.get("marble_feedback_alpha", 0.0)),
		"active_phase": str(snapshot.get("phase", ""))
	}

static func run_hud_state(snapshot: Dictionary) -> Dictionary:
	return {
		"seed_text": str(snapshot.get("seed_text", "")),
		"turn": int(snapshot.get("turn", 1)),
		"floor_index": int(snapshot.get("floor_index", 1)),
		"cash": int(snapshot.get("cash", 0)),
		"run_gold": int(snapshot.get("run_gold", 0)),
		"gold_delta": int(snapshot.get("gold_delta", 0)),
		"banked": int(snapshot.get("banked", 0)),
		"busts": int(snapshot.get("busts", 0)),
		"player_hp": int(snapshot.get("player_hp", 1)),
		"player_max_hp": int(snapshot.get("player_max_hp", 1)),
		"enemy_hp": int(snapshot.get("enemy_hp", 1)),
		"enemy_max_hp": int(snapshot.get("enemy_max_hp", 1)),
		"player_block": int(snapshot.get("player_block", 0)),
		"monster_id": str(snapshot.get("monster_id", "")),
		"monster_name": str(snapshot.get("monster_name", "")),
		"active_relic_ids": snapshot.get("active_relic_ids", []),
		"potion_ids": snapshot.get("active_potion_ids", []),
		"potion_slots_used": (snapshot.get("active_potion_ids", []) as Array).size(),
		"potion_slots_max": int(snapshot.get("potion_slots_max", 2)),
		"active_prep_mods": snapshot.get("active_prep_mods", [])
	}

static func opponent_state(snapshot: Dictionary) -> Dictionary:
	return {
		"monster_id": str(snapshot.get("monster_id", "")),
		"monster_name": str(snapshot.get("monster_name", "")),
		"monster_pattern_tuning": snapshot.get("monster_pattern_tuning", {}),
		"enemy_hp": int(snapshot.get("enemy_hp", 0)),
		"enemy_max_hp": int(snapshot.get("enemy_max_hp", 1)),
		"enemy_intent": str(snapshot.get("enemy_intent", "")),
		"current_move_id": str(snapshot.get("current_move_id", "")),
		"enemy_flash": float(snapshot.get("enemy_flash", 0.0)),
		"player_flash": float(snapshot.get("player_flash", 0.0)),
		"opponent_reaction": float(snapshot.get("opponent_reaction", 0.0)),
		"opponent_mood": str(snapshot.get("opponent_mood", "watching"))
	}

static func overlay_payload(snapshot: Dictionary) -> Dictionary:
	var potion_ids: Array = (snapshot.get("active_potion_ids", []) as Array).duplicate()
	return {
		"player_hp": int(snapshot.get("player_hp", 1)),
		"player_max_hp": int(snapshot.get("player_max_hp", 1)),
		"relic_ids": (snapshot.get("active_relic_ids", []) as Array).duplicate(),
		"potion_ids": potion_ids,
		"potion_slots_used": potion_ids.size(),
		"potion_slots_max": int(snapshot.get("potion_slots_max", 2)),
		"player_block": int(snapshot.get("player_block", 0)),
		"run_upgrades": (snapshot.get("active_run_upgrades", {}) as Dictionary).duplicate(true)
	}

static func camera_beat(snapshot: Dictionary) -> String:
	var phase := str(snapshot.get("phase", ""))
	if phase == "dice" or phase == "wager":
		return "wide_table"
	if phase == "marble":
		if bool(snapshot.get("throwing_hand", false)) or not (snapshot.get("thrown_marbles", []) as Array).is_empty():
			return "wheel_close"
		return "wide_table"
	if phase == "spinning" or phase == "intervene":
		return "wheel_close"
	if phase == "enemy":
		return "opponent_intent"
	if phase == "result":
		return "result_hit"
	return "wide_table"
