extends SceneTree

const RunStateScript := preload("res://scripts/resources/run_state.gd")
const CharacterContractCatalog := preload("res://scripts/systems/character_contract_catalog.gd")
const DiceResolver := preload("res://scripts/systems/dice_resolver.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const EventCatalog := preload("res://scripts/systems/event_catalog.gd")
const MonsterMoveCatalog := preload("res://scripts/systems/monster_move_catalog.gd")
const NumericRouletteResolver := preload("res://scripts/systems/numeric_roulette_resolver.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RelicPoolCatalog := preload("res://scripts/systems/relic_pool_catalog.gd")
const RestActionCatalog := preload("res://scripts/systems/rest_action_catalog.gd")
const ShopOfferCatalog := preload("res://scripts/systems/shop_offer_catalog.gd")

const DEFAULT_RUN_COUNT := 1000
const DEFAULT_CHARACTER_IDS: Array[String] = ["double_attack_dice", "black_signer_no_dice"]
const MAX_TURNS_PER_COMBAT := 18
const MAX_STEPS := 40
const NORMAL_TICKET_BASE_CHANCE := 15
const NORMAL_TICKET_TURN_BONUS := 3
const NORMAL_TICKET_MAX_CHANCE := 35
const HOARDED_WAGER_PRESSURE_CAP := 3

func _initialize() -> void:
	var run_count := _run_count()
	for character_id in _selected_character_ids():
		var runs: Array[Dictionary] = []
		for i in range(run_count):
			runs.append(_simulate_run("numeric-floor1-" + character_id + "-" + str(i).pad_zeros(4), character_id))
		var summary: Dictionary = _summarize(runs, character_id)
		print("NUMERIC_FLOOR1_CHARACTER_SUMMARY " + JSON.stringify(summary))
	quit(0)

func _run_count() -> int:
	var raw := OS.get_environment("LUCK_SIM_RUN_COUNT")
	if raw.is_valid_int():
		return max(1, int(raw))
	return DEFAULT_RUN_COUNT

func _selected_character_ids() -> Array[String]:
	var raw := OS.get_environment("LUCK_SIM_CHARACTER_IDS").strip_edges()
	if raw == "":
		return DEFAULT_CHARACTER_IDS
	var selected: Array[String] = []
	for item in raw.split(",", false):
		var character_id := str(item).strip_edges()
		if character_id != "":
			selected.append(character_id)
	return selected if not selected.is_empty() else DEFAULT_CHARACTER_IDS

func _simulate_run(seed_text: String, character_id: String) -> Dictionary:
	var run_state = RunStateScript.new()
	run_state.seed_text = seed_text
	run_state.gold = 0
	run_state.character_id = character_id
	run_state.player_max_hp = CharacterContractCatalog.starting_max_hp(run_state.character_id)
	run_state.player_hp = int(run_state.player_max_hp)
	run_state.relic_ids = CharacterContractCatalog.starting_relic_ids(run_state.character_id)
	run_state.floor_index = 1
	run_state.max_floor = 1
	run_state.map_variant = "scroll_20_random"
	run_state.map_theme_id = "01_base"
	run_state.map_step = 0
	run_state.completed_nodes.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("numeric-floor1-character:" + seed_text)
	var metrics: Dictionary = {
		"seed": seed_text,
		"sim_policy_label": _sim_policy_label(character_id),
		"clear": false,
		"death": false,
		"step": 0,
		"combats": 0,
		"combat_wins": 0,
		"elites": 0,
		"bosses": 0,
		"events": 0,
		"shops": 0,
		"rests": 0,
		"turns": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"boss_damage_taken": 0,
		"go_attempts": 0,
		"go_successes": 0,
		"go_collapses": 0,
		"zero_hits": 0,
		"wager_committed": 0,
		"wager_turns": 0,
		"dice_go_count": 0,
		"dice_stop_count": 0,
		"dice_bypass_count": 0,
		"wager_go_count": 0,
		"wager_stop_count": 0,
		"wager_bypass_count": 0,
		"roulette_go_count": 0,
		"roulette_stop_count": 0,
		"roulette_bypass_count": 0,
		"roulette_extra_go_chances": 0,
		"black_debt_hits": 0,
		"rewards": 0,
		"reward_heals": 0,
		"tickets_earned": 0,
		"shop_buys": 0,
		"service_buys": 0,
		"rest_heals": 0,
		"rest_upgrades": 0,
		"upgrade_counts": {},
		"upgrade_damage": {
			"primary_die_bonus": 0,
			"roulette_bonus": 0,
			"marble_bonus": 0
		},
		"secondary_block_prevented": 0,
		"route": []
	}

	var guard := 0
	while guard < MAX_STEPS and int(run_state.player_hp) > 0:
		guard += 1
		metrics["step"] = int(run_state.map_step)
		var floor_seed := str(run_state.seed_text) + ":floor:" + str(int(run_state.floor_index))
		var nodes: Array[Dictionary] = EncounterCatalog.map_nodes(str(run_state.map_variant), floor_seed)
		var choices: Array[Dictionary] = _nodes_at_step(nodes, int(run_state.map_step))
		if choices.is_empty():
			metrics["death"] = true
			(metrics["route"] as Array).append("missing_step_" + str(run_state.map_step))
			break
		var node: Dictionary = _choose_route_node(choices, run_state)
		var node_type := str(node.get("node_type", "combat"))
		(metrics["route"] as Array).append("s" + str(run_state.map_step) + ":" + node_type)
		match node_type:
			"combat", "elite", "boss":
				if node_type == "elite":
					metrics["elites"] = int(metrics["elites"]) + 1
				if node_type == "boss":
					metrics["bosses"] = int(metrics["bosses"]) + 1
				var combat_result: Dictionary = _simulate_numeric_combat(run_state, node, rng)
				metrics["combats"] = int(metrics["combats"]) + 1
				metrics["turns"] = int(metrics["turns"]) + int(combat_result.get("turns", 0))
				metrics["damage_dealt"] = int(metrics["damage_dealt"]) + int(combat_result.get("damage_dealt", 0))
				metrics["damage_taken"] = int(metrics["damage_taken"]) + int(combat_result.get("damage_taken", 0))
				metrics["go_attempts"] = int(metrics["go_attempts"]) + int(combat_result.get("go_attempts", 0))
				metrics["go_successes"] = int(metrics["go_successes"]) + int(combat_result.get("go_successes", 0))
				metrics["go_collapses"] = int(metrics["go_collapses"]) + int(combat_result.get("go_collapses", 0))
				metrics["zero_hits"] = int(metrics["zero_hits"]) + int(combat_result.get("zero_hits", 0))
				metrics["wager_committed"] = int(metrics["wager_committed"]) + int(combat_result.get("wager_committed", 0))
				metrics["wager_turns"] = int(metrics["wager_turns"]) + int(combat_result.get("wager_turns", 0))
				_add_decision_counts(metrics, combat_result)
				metrics["black_debt_hits"] = int(metrics["black_debt_hits"]) + int(combat_result.get("black_debt_hits", 0))
				metrics["secondary_block_prevented"] = int(metrics["secondary_block_prevented"]) + int(combat_result.get("secondary_block_prevented", 0))
				_add_upgrade_damage(metrics, combat_result.get("upgrade_damage", {}))
				if node_type == "boss":
					metrics["boss_damage_taken"] = int(combat_result.get("damage_taken", 0))
				run_state.player_hp = int(combat_result.get("player_hp", run_state.player_hp))
				run_state.gold = max(0, int(run_state.gold) + int(combat_result.get("gold_delta", 0)))
				if bool(combat_result.get("victory", false)):
					metrics["combat_wins"] = int(metrics["combat_wins"]) + 1
					if node_type == "boss":
						metrics["clear"] = true
						break
					_apply_reward_choice(run_state, combat_result, metrics)
					run_state.map_step += 1
				else:
					metrics["death"] = true
					break
			"event":
				metrics["events"] = int(metrics["events"]) + 1
				_apply_event_choice(run_state, node, rng, metrics)
				run_state.map_step += 1
			"shop":
				metrics["shops"] = int(metrics["shops"]) + 1
				_apply_shop_choice(run_state, metrics)
				run_state.map_step += 1
			"rest":
				metrics["rests"] = int(metrics["rests"]) + 1
				_apply_rest_choice(run_state, metrics)
				run_state.map_step += 1
			_:
				run_state.map_step += 1
		if int(run_state.player_hp) <= 0:
			metrics["death"] = true
			break
	return _finalize_run_metrics(run_state, metrics)

func _simulate_numeric_combat(run_state: Resource, node: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var payload: Dictionary = EffectResolver.build_encounter_payload(run_state, node)
	var enemy_hp := int(payload.get("enemy_hp", 18))
	var player_hp := int(payload.get("player_hp", 42))
	var run_gold := int(payload.get("run_gold", int(run_state.gold)))
	var gold_delta := 0
	var enemy_damage_delta := int(payload.get("enemy_damage_delta", 0))
	var enemy_damage_multiplier := float(payload.get("enemy_damage_multiplier", 1.0))
	var enemy_block := int(payload.get("enemy_block", 0))
	var player_attack_delta := int(payload.get("player_attack_delta", 0))
	var player_damage_multiplier := float(payload.get("player_damage_multiplier", 1.0))
	var monster_pattern_tuning: Dictionary = payload.get("monster_pattern_tuning", {})
	var move_pattern: Array = payload.get("move_pattern", [])
	var relic_ids: Array = payload.get("relic_ids", [])
	var relic_state: Dictionary = {}
	var run_upgrades: Dictionary = payload.get("run_upgrades", {})
	var dice_rule_id := str(payload.get("dice_rule_id", DiceResolver.default_rule_id()))
	var combat_cash := int(payload.get("combat_cash", 18))
	var wager_available := 1
	var turn := 1
	var total_damage := 0
	var total_taken := 0
	var go_attempts := 0
	var go_successes := 0
	var go_collapses := 0
	var zero_hits := 0
	var wager_committed_total := 0
	var wager_turns := 0
	var dice_go_count := 0
	var dice_stop_count := 0
	var dice_bypass_count := 0
	var wager_go_count := 0
	var wager_stop_count := 0
	var wager_bypass_count := 0
	var roulette_go_count := 0
	var roulette_stop_count := 0
	var roulette_bypass_count := 0
	var roulette_extra_go_chances := 0
	var secondary_block_prevented := 0
	var black_signer_debt := 0
	var black_debt_hits := 0
	var upgrade_damage := {
		"primary_die_bonus": 0,
		"roulette_bonus": 0,
		"marble_bonus": 0
	}
	while turn <= MAX_TURNS_PER_COMBAT and player_hp > 0 and enemy_hp > 0:
		var player_block := 0
		var turn_payload: Dictionary = EffectResolver.apply_relic_trigger("turn_start", {
			"turn": turn,
			"floor_index": int(payload.get("floor_index", 1)),
			"cash": combat_cash,
			"run_gold": run_gold,
			"gold_delta": gold_delta,
			"enemy_damage_delta": enemy_damage_delta,
			"enemy_damage_multiplier": enemy_damage_multiplier,
			"player_hp": player_hp,
			"player_max_hp": int(payload.get("player_max_hp", 42)),
			"enemy_hp": enemy_hp,
			"player_block": player_block,
			"enemy_block": enemy_block,
			"player_attack_delta": player_attack_delta,
			"player_damage_multiplier": player_damage_multiplier,
			"relic_state": relic_state,
			"applied_effects": []
		}, relic_ids)
		combat_cash = int(turn_payload.get("cash", combat_cash))
		run_gold = int(turn_payload.get("run_gold", run_gold))
		enemy_damage_delta = int(turn_payload.get("enemy_damage_delta", enemy_damage_delta))
		enemy_damage_multiplier = float(turn_payload.get("enemy_damage_multiplier", enemy_damage_multiplier))
		player_hp = int(turn_payload.get("player_hp", player_hp))
		enemy_hp = int(turn_payload.get("enemy_hp", enemy_hp))
		player_block = int(turn_payload.get("player_block", player_block))
		enemy_block = int(turn_payload.get("enemy_block", enemy_block))
		player_attack_delta = int(turn_payload.get("player_attack_delta", player_attack_delta))
		player_damage_multiplier = float(turn_payload.get("player_damage_multiplier", player_damage_multiplier))
		relic_state = turn_payload.get("relic_state", relic_state)

		var move_id := MonsterMoveCatalog.move_for_turn(move_pattern, turn)
		var selected_index := -1
		var contract_extra_go_chances := 0
		var dice_values: Array[int] = []
		var dice_payload: Dictionary = {}
		var skip_dice_result_relics := false
		if dice_rule_id == "black_signer_contracts":
			skip_dice_result_relics = true
			var contract_id := _choose_black_signer_contract(enemy_hp, player_hp, move_id, enemy_damage_delta, monster_pattern_tuning, black_signer_debt)
			var contract_values := _black_signer_contract_values(contract_id)
			contract_extra_go_chances = int(contract_values.get("extra_go_chances", 0))
			dice_payload = {
				"accepted": true,
				"dice_values": [],
				"dice": [],
				"dice_locked": [],
				"rerolls_left": 0,
				"attack_base": int(contract_values.get("attack_base", 0)),
				"guard_value": int(contract_values.get("guard_value", 0)),
				"selected_attack_die_index": -1,
				"dice_total": 0,
				"dice_rule_id": dice_rule_id,
				"dice_rule": DiceResolver.rule(dice_rule_id),
			"cash": combat_cash,
			"player_block": player_block + int(contract_values.get("guard_value", 0)),
				"black_signer_contract_id": contract_id,
				"relic_state": relic_state,
				"applied_effects": []
			}
			black_signer_debt += 1
			if black_signer_debt >= 3:
				black_signer_debt = 0
				var before_debt_hp := player_hp
				player_hp = max(0, player_hp - 6)
				total_taken += max(0, before_debt_hp - player_hp)
				black_debt_hits += 1
		else:
			dice_values = _choose_dice_pair(dice_rule_id, rng, enemy_hp, move_id, enemy_damage_delta, monster_pattern_tuning)
			if _is_dice_go_stop_rule(dice_rule_id):
				dice_stop_count += 1
				dice_bypass_count += 1
			selected_index = _choose_attack_die_index(dice_values, enemy_hp, move_id, enemy_damage_delta, monster_pattern_tuning)
			var dice_base: Dictionary = DiceResolver.compute_result(dice_values, [false, false], dice_rule_id, 0, [], selected_index)
			dice_base["cash"] = combat_cash
			dice_base["player_block"] = player_block
			dice_base["relic_state"] = relic_state
			dice_payload = dice_base
		if not skip_dice_result_relics:
			dice_payload = EffectResolver.apply_relic_trigger("dice_result", dice_payload, relic_ids)
		combat_cash = int(dice_payload.get("cash", combat_cash))
		relic_state = dice_payload.get("relic_state", relic_state)
		var attack_before_upgrade := int(dice_payload.get("attack_base", 0))
		var guard_before_upgrade := int(dice_payload.get("guard_value", dice_payload.get("player_block", 0)))
		dice_payload = _apply_dice_upgrade(dice_payload, run_upgrades)
		var attack_base := int(dice_payload.get("attack_base", 0))
		var guard_value := int(dice_payload.get("guard_value", dice_payload.get("player_block", 0)))
		var primary_attack_added: int = max(0, attack_base - attack_before_upgrade)
		var secondary_guard_added: int = max(0, guard_value - guard_before_upgrade)
		player_block += guard_value

		var marble_payload: Dictionary = EffectResolver.apply_relic_trigger("marble_gain", {
			"attack_base": attack_base,
			"marble_count": 1,
			"marbles": ["plain"],
			"dice_values": dice_payload.get("dice_values", dice_values),
			"dice_rule_id": dice_rule_id,
			"selected_attack_die_index": selected_index,
			"guard_value": player_block,
			"player_block": player_block,
			"relic_state": relic_state,
			"applied_effects": []
		}, relic_ids)
		relic_state = marble_payload.get("relic_state", relic_state)
		var gained_marbles: int = max(1, int(marble_payload.get("marble_count", 1)))
		wager_available += max(0, gained_marbles - 1)
		var committed: int = _choose_wager_commit(wager_available, attack_base, enemy_hp)
		wager_available = max(0, wager_available - committed)
		wager_committed_total += committed
		wager_turns += 1
		wager_go_count += committed
		wager_stop_count += 1

		var before_spin: Dictionary = EffectResolver.apply_relic_trigger("roulette_before_spin", {
			"combat_core": "numeric_roulette",
			"attack_base": max(0, attack_base + player_attack_delta),
			"wager_marbles_committed": committed,
			"wager_marbles_available": wager_available,
			"roulette_multiplier": 1.0,
			"relic_state": relic_state,
			"applied_effects": []
		}, relic_ids)
		relic_state = before_spin.get("relic_state", relic_state)
		var go_chances: int = 1 + max(0, int(before_spin.get("numeric_extra_go_chances", 0))) + contract_extra_go_chances
		roulette_extra_go_chances += max(0, go_chances - 1)
		if go_chances <= 0:
			roulette_bypass_count += 1
		var spin_result: Dictionary = NumericRouletteResolver.spin(rng)
		var roulette_multiplier := float(spin_result.get("multiplier", 1.0))
		var used_go := false
		if go_chances > 0 and _should_go(roulette_multiplier):
			used_go = true
			go_attempts += 1
			roulette_go_count += 1
			var previous_multiplier := roulette_multiplier
			spin_result = NumericRouletteResolver.spin(rng)
			roulette_multiplier = float(spin_result.get("multiplier", 1.0))
			if roulette_multiplier <= previous_multiplier:
				roulette_multiplier = 0.0
				go_collapses += 1
			else:
				go_successes += 1
		roulette_stop_count += 1
		var wager_multiplier := NumericRouletteResolver.wager_multiplier(committed)
		var damage_multiplier := roulette_multiplier * wager_multiplier
		var after_spin: Dictionary = EffectResolver.apply_relic_trigger("roulette_after_spin", {
			"combat_core": "numeric_roulette",
			"outcome_mode": "numeric_roulette",
			"pending_slot": "numeric",
			"cash": combat_cash,
			"cash_delta": 0,
			"attack_base": max(0, attack_base + player_attack_delta),
			"roulette_multiplier": roulette_multiplier,
			"wager_multiplier": wager_multiplier,
			"wager_marbles_committed": committed,
			"wager_marbles_available": wager_available,
			"relic_state": relic_state,
			"applied_effects": []
		}, relic_ids)
		combat_cash = int(after_spin.get("cash", combat_cash))
		relic_state = after_spin.get("relic_state", relic_state)

		var resolution: Dictionary = {
			"pending_slot": "numeric",
			"outcome_mode": "numeric_roulette",
			"combat_core": "numeric_roulette",
			"cash": combat_cash,
			"run_gold": run_gold,
			"gold_delta": gold_delta,
			"player_hp": player_hp,
			"player_max_hp": int(payload.get("player_max_hp", 42)),
			"player_block": player_block,
			"enemy_hp": enemy_hp,
			"enemy_block": enemy_block,
			"enemy_damage_delta": enemy_damage_delta,
			"enemy_damage_multiplier": enemy_damage_multiplier,
			"attack_base": max(0, attack_base + player_attack_delta),
			"dice_values": dice_payload.get("dice_values", dice_values),
			"dice_rule_id": dice_rule_id,
			"selected_attack_die_index": selected_index,
			"player_attack_delta": player_attack_delta,
			"player_damage_multiplier": player_damage_multiplier,
			"roulette_multiplier": roulette_multiplier,
			"wager_multiplier": wager_multiplier,
			"damage_multiplier": damage_multiplier,
			"payout_multiplier": damage_multiplier,
			"roulette_action": "go" if used_go else "stop",
			"wager_marbles_committed": committed,
			"wager_marbles_available": wager_available,
			"flat_damage_bonus": 0,
			"cash_delta_bonus": 0,
			"placed_slots": {},
			"relic_state": relic_state,
			"applied_effects": []
		}
		resolution = EffectResolver.apply_relic_trigger("resolution_before", resolution, relic_ids)
		relic_state = resolution.get("relic_state", relic_state)
		var before_upgrade_multiplier: float = float(resolution.get("damage_multiplier", damage_multiplier))
		resolution = _apply_numeric_resolution_upgrades(resolution, run_upgrades)
		var attack_value: int = int(resolution.get("attack_base", attack_base))
		var resolved_multiplier: float = max(0.0, float(resolution.get("damage_multiplier", before_upgrade_multiplier)))
		var pre_curse_damage: int = max(0, int(round(float(attack_value) * resolved_multiplier)) + int(resolution.get("flat_damage_bonus", 0)))
		var pre_block_damage: int = max(0, int(floor(float(pre_curse_damage) * max(0.0, float(resolution.get("player_damage_multiplier", player_damage_multiplier))))))
		var blocked_damage: int = min(max(0, int(resolution.get("enemy_block", enemy_block))), pre_block_damage)
		var damage: int = max(0, pre_block_damage - blocked_damage)
		if damage <= 0:
			zero_hits += 1
		upgrade_damage["primary_die_bonus"] = int(upgrade_damage["primary_die_bonus"]) + int(round(float(primary_attack_added) * resolved_multiplier))
		upgrade_damage["roulette_bonus"] = int(upgrade_damage["roulette_bonus"]) + int(round(float(attack_value) * float(resolution.get("run_upgrade_roulette_bonus", 0.0))))
		upgrade_damage["marble_bonus"] = int(upgrade_damage["marble_bonus"]) + int(round(float(attack_value) * float(resolution.get("run_upgrade_wager_polish_bonus", 0.0))))
		var outcome: Dictionary = {
			"pending_slot": str(resolution.get("pending_slot", "numeric")),
			"outcome_mode": "numeric_roulette",
			"combat_core": "numeric_roulette",
			"profit": max(0, int(resolution.get("cash_delta_bonus", 0))),
			"cash": max(0, int(resolution.get("cash", combat_cash)) + int(resolution.get("cash_delta_bonus", 0))),
			"cash_delta": int(resolution.get("cash_delta_bonus", 0)),
			"run_gold": run_gold,
			"gold_delta": gold_delta,
			"player_hp": int(resolution.get("player_hp", player_hp)),
			"player_max_hp": int(resolution.get("player_max_hp", payload.get("player_max_hp", 42))),
			"player_block": int(resolution.get("player_block", player_block)),
			"enemy_hp": max(0, int(resolution.get("enemy_hp", enemy_hp)) - damage),
			"enemy_block": max(0, int(resolution.get("enemy_block", enemy_block)) - blocked_damage),
			"enemy_damage_delta": int(resolution.get("enemy_damage_delta", enemy_damage_delta)),
			"damage": damage,
			"raw_damage": pre_block_damage,
			"pre_curse_damage": pre_curse_damage,
			"block_absorbed": blocked_damage,
			"bust_delta": 0,
			"attack_base": attack_value,
			"dice_values": resolution.get("dice_values", dice_values),
			"dice_rule_id": str(resolution.get("dice_rule_id", dice_rule_id)),
			"selected_attack_die_index": int(resolution.get("selected_attack_die_index", selected_index)),
			"roulette_multiplier": float(resolution.get("roulette_multiplier", roulette_multiplier)),
			"wager_multiplier": float(resolution.get("wager_multiplier", wager_multiplier)),
			"damage_multiplier": resolved_multiplier,
			"payout_multiplier": resolved_multiplier,
			"wager_marbles_committed": committed,
			"wager_marbles_available": wager_available,
			"placed_slots": {},
			"relic_state": relic_state,
			"message": ""
		}
		outcome = EffectResolver.apply_relic_trigger("resolution_after", outcome, relic_ids)
		relic_state = outcome.get("relic_state", relic_state)
		damage = int(outcome.get("damage", damage))
		total_damage += damage
		enemy_hp = int(outcome.get("enemy_hp", enemy_hp))
		enemy_block = int(outcome.get("enemy_block", enemy_block))
		enemy_damage_delta = int(outcome.get("enemy_damage_delta", enemy_damage_delta))
		combat_cash = int(outcome.get("cash", combat_cash))
		player_attack_delta = 0
		player_damage_multiplier = 1.0
		if enemy_hp <= 0:
			break

		var hoarded_pressure := _hoarded_wager_pressure(wager_available)
		var move_result: Dictionary = MonsterMoveCatalog.resolve_enemy_turn(move_id, {
			"player_hp": player_hp,
			"player_block": player_block,
			"enemy_damage_delta": enemy_damage_delta + hoarded_pressure,
			"enemy_damage_multiplier": enemy_damage_multiplier,
			"enemy_block": enemy_block,
			"player_attack_delta": player_attack_delta,
			"player_damage_multiplier": player_damage_multiplier,
			"run_gold": run_gold,
			"pattern_tuning": monster_pattern_tuning,
			"cash": combat_cash
			}, 0)
		_clear_transient_hoarded_pressure(move_id, monster_pattern_tuning, move_result, hoarded_pressure)
		move_result["hoarded_wager_pressure"] = hoarded_pressure
		move_result["relic_state"] = relic_state
		move_result = EffectResolver.apply_relic_trigger("damage_taken", move_result, relic_ids)
		relic_state = move_result.get("relic_state", relic_state)
		var taken: int = int(move_result.get("damage", 0))
		total_taken += taken
		var incoming_damage: int = int(move_result.get("incoming_damage", taken))
		var block_absorbed: int = int(move_result.get("block_absorbed", 0))
		var non_secondary_block: int = max(0, player_block - secondary_guard_added)
		var absorbed_after_base: int = max(0, block_absorbed - min(non_secondary_block, incoming_damage))
		secondary_block_prevented += min(secondary_guard_added, absorbed_after_base)
		player_hp = int(move_result.get("player_hp", player_hp))
		enemy_damage_delta = int(move_result.get("enemy_damage_delta", 0))
		enemy_damage_multiplier = float(move_result.get("enemy_damage_multiplier", 1.0))
		enemy_block = int(move_result.get("enemy_block", enemy_block))
		player_attack_delta = int(move_result.get("player_attack_delta", player_attack_delta))
		player_damage_multiplier = float(move_result.get("player_damage_multiplier", player_damage_multiplier))
		combat_cash = int(move_result.get("cash", combat_cash))
		run_gold = int(move_result.get("run_gold", run_gold))
		gold_delta += int(move_result.get("gold_delta", 0))
		wager_available += 1
		turn += 1
	var result: Dictionary = {
		"victory": enemy_hp <= 0,
		"defeat": player_hp <= 0 or enemy_hp > 0,
		"player_hp": max(0, player_hp),
		"player_max_hp": int(payload.get("player_max_hp", 42)),
		"enemy_hp": max(0, enemy_hp),
		"turns": turn,
		"turn": turn,
		"damage_dealt": total_damage,
		"damage_taken": total_taken,
		"go_attempts": go_attempts,
		"go_successes": go_successes,
		"go_collapses": go_collapses,
		"zero_hits": zero_hits,
		"wager_committed": wager_committed_total,
		"wager_turns": wager_turns,
		"dice_go_count": dice_go_count,
		"dice_stop_count": dice_stop_count,
		"dice_bypass_count": dice_bypass_count,
		"wager_go_count": wager_go_count,
		"wager_stop_count": wager_stop_count,
		"wager_bypass_count": wager_bypass_count,
		"roulette_go_count": roulette_go_count,
		"roulette_stop_count": roulette_stop_count,
		"roulette_bypass_count": roulette_bypass_count,
		"roulette_extra_go_chances": roulette_extra_go_chances,
		"black_debt_hits": black_debt_hits,
		"winnings": combat_cash,
		"combat_cash": combat_cash,
		"cash": combat_cash,
		"run_gold": run_gold,
		"gold_delta": gold_delta,
		"secondary_block_prevented": secondary_block_prevented,
		"upgrade_damage": upgrade_damage,
		"reward_tier": str(payload.get("reward_tier", "normal")),
		"relic_state": relic_state,
		"applied_effects": []
	}
	if bool(result.get("victory", false)):
		result = EffectResolver.apply_relic_trigger("combat_victory", result, relic_ids)
	else:
		result = EffectResolver.apply_relic_trigger("combat_end", result, relic_ids)
	return result

func _choose_dice_pair(rule_id: String, rng: RandomNumberGenerator, enemy_hp: int, move_id: String, enemy_damage_delta: int, tuning: Dictionary) -> Array[int]:
	var best: Array[int] = [1, 1]
	var best_score := -9999.0
	var rolls := int(DiceResolver.rule(rule_id).get("rerolls", 2)) + 1
	for _i in range(max(1, rolls)):
		var pair: Array[int] = []
		for _j in range(int(DiceResolver.rule(rule_id).get("dice_count", 2))):
			pair.append(rng.randi_range(1, int(DiceResolver.rule(rule_id).get("sides", 6))))
		var score := _dice_pair_score(rule_id, pair, enemy_hp, move_id, enemy_damage_delta, tuning)
		if score > best_score:
				best_score = score
				best = pair
	return best

func _hoarded_wager_pressure(wager_available: int) -> int:
	return min(HOARDED_WAGER_PRESSURE_CAP, max(0, wager_available))

func _clear_transient_hoarded_pressure(move_id: String, tuning: Dictionary, result: Dictionary, hoarded_pressure: int) -> void:
	if hoarded_pressure <= 0:
		return
	var move := MonsterMoveCatalog.tuned_move(move_id, tuning)
	if int(move.get("damage", 0)) <= 0:
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) - hoarded_pressure

func _dice_pair_score(rule_id: String, pair: Array[int], enemy_hp: int, move_id: String, enemy_damage_delta: int, tuning: Dictionary) -> float:
	if str(DiceResolver.rule(rule_id).get("attack_base_mode", "")) == "choice_double_attack":
		var total := 0
		for value in pair:
			total += int(value)
		var lethal_bonus := 8.0 if total >= enemy_hp else 0.0
		return float(total) * 1.25 + lethal_bonus
	var attack_index := _choose_attack_die_index(pair, enemy_hp, move_id, enemy_damage_delta, tuning)
	var attack := int(pair[attack_index])
	var block := 0
	for i in range(pair.size()):
		if i != attack_index:
			block += int(pair[i])
	var incoming: int = max(0, int(MonsterMoveCatalog.tuned_move(move_id, tuning).get("damage", 0)) + enemy_damage_delta)
	var prevented: int = min(block, incoming)
	var lethal_bonus := 8.0 if attack >= enemy_hp else 0.0
	return float(attack) * 1.25 + float(prevented) * 1.05 + lethal_bonus

func _choose_attack_die_index(pair: Array[int], enemy_hp: int, move_id: String, enemy_damage_delta: int, tuning: Dictionary) -> int:
	if pair.size() <= 1:
		return 0
	var best_index := 0
	var best_score := -9999.0
	for i in range(pair.size()):
		var attack := int(pair[i])
		var block := 0
		for j in range(pair.size()):
			if j != i:
				block += int(pair[j])
		var incoming: int = max(0, int(MonsterMoveCatalog.tuned_move(move_id, tuning).get("damage", 0)) + enemy_damage_delta)
		var prevented: int = min(block, incoming)
		var score := float(attack) * 1.25 + float(prevented) * 1.05
		if attack >= enemy_hp:
			score += 8.0
		if score > best_score:
			best_score = score
			best_index = i
	return best_index

func _choose_black_signer_contract(enemy_hp: int, player_hp: int, move_id: String, enemy_damage_delta: int, tuning: Dictionary, debt: int) -> String:
	var incoming: int = max(0, int(MonsterMoveCatalog.tuned_move(move_id, tuning).get("damage", 0)) + enemy_damage_delta)
	var best_id := "sword"
	var best_score := -9999.0
	for contract_id in ["sword", "shield", "roulette"]:
		var values := _black_signer_contract_values(contract_id)
		var attack := int(values.get("attack_base", 0))
		var guard := int(values.get("guard_value", 0))
		var prevented: int = min(guard, incoming)
		var debt_cost := 6.0 if debt >= 2 else 0.0
		var hp_risk := 0.9 if player_hp <= 18 else 0.35
		var score := float(attack) * 1.25 + float(prevented) * 1.2 - debt_cost * hp_risk
		if attack >= enemy_hp:
			score += 10.0
		if contract_id == "roulette":
			score += 1.35
			if enemy_hp > attack * 2:
				score += 0.8
		if contract_id == "shield" and player_hp <= 22:
			score += 2.2
		if score > best_score:
			best_score = score
			best_id = contract_id
	return best_id

func _black_signer_contract_values(contract_id: String) -> Dictionary:
	match contract_id:
		"sword":
			return {"attack_base": 8, "guard_value": 0, "extra_go_chances": 0}
		"shield":
			return {"attack_base": 4, "guard_value": 6, "extra_go_chances": 0}
		"roulette":
			return {"attack_base": 5, "guard_value": 0, "extra_go_chances": 1}
		_:
			return {"attack_base": 6, "guard_value": 0, "extra_go_chances": 0}

func _choose_wager_commit(available: int, attack_base: int, enemy_hp: int) -> int:
	if available <= 0:
		return 0
	if enemy_hp <= attack_base * 2:
		return min(available, 4)
	return min(available, 4)

func _should_go(multiplier: float) -> bool:
	return multiplier <= 0.5

func _sim_policy_label(_character_id: String) -> String:
	return "mechanical_direct_floor1:dice_push_bypassed,wager_direct_commit,roulette_single_go_threshold_0.5"

func _is_dice_go_stop_rule(rule_id: String) -> bool:
	var rule_data: Dictionary = DiceResolver.rule(rule_id)
	var attack_mode := str(rule_data.get("attack_base_mode", ""))
	return int(rule_data.get("dice_count", 1)) == 2 and int(rule_data.get("sides", 6)) == 6 and attack_mode in ["sum", "choice_attack_guard", "choice_double_attack"]

func _decision_count_keys() -> Array[String]:
	return [
		"dice_go_count",
		"dice_stop_count",
		"dice_bypass_count",
		"wager_go_count",
		"wager_stop_count",
		"wager_bypass_count",
		"roulette_go_count",
		"roulette_stop_count",
		"roulette_bypass_count",
		"roulette_extra_go_chances"
	]

func _empty_decision_counts() -> Dictionary:
	var result: Dictionary = {}
	for key in _decision_count_keys():
		result[key] = 0
	return result

func _decision_counts_from(source: Dictionary) -> Dictionary:
	var result := _empty_decision_counts()
	for key in _decision_count_keys():
		result[key] = int(source.get(key, 0))
	return result

func _add_decision_counts(target: Dictionary, source: Dictionary) -> void:
	for key in _decision_count_keys():
		target[key] = int(target.get(key, 0)) + int(source.get(key, 0))

func _apply_dice_upgrade(result: Dictionary, run_upgrades: Dictionary) -> Dictionary:
	var next := result.duplicate(true)
	var primary_bonus := int(round(float(run_upgrades.get("primary_die_bonus", run_upgrades.get("dice_bonus", 0.0)))))
	var secondary_bonus := int(round(float(run_upgrades.get("secondary_die_bonus", 0.0))))
	if primary_bonus != 0:
		next["attack_base"] = max(0, int(next.get("attack_base", 0)) + primary_bonus)
	if secondary_bonus != 0:
		var attack_mode := str(next.get("dice_rule", DiceResolver.rule(str(next.get("dice_rule_id", "")))).get("attack_base_mode", ""))
		if attack_mode == "choice_double_attack":
			next["attack_base"] = max(0, int(next.get("attack_base", 0)) + secondary_bonus)
		elif next.has("guard_value"):
			next["guard_value"] = max(0, int(next.get("guard_value", 0)) + secondary_bonus)
		if attack_mode != "choice_double_attack" and next.has("player_block"):
			next["player_block"] = max(0, int(next.get("player_block", 0)) + secondary_bonus)
	return next

func _apply_numeric_resolution_upgrades(payload: Dictionary, run_upgrades: Dictionary) -> Dictionary:
	var result := payload.duplicate(true)
	var roulette_bonus := float(run_upgrades.get("roulette_bonus", 0.0))
	var committed := clampi(int(result.get("wager_marbles_committed", 0)), 0, 4)
	var marble_bonus := float(run_upgrades.get("marble_bonus", 0.0))
	var current := float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0)))
	var wager_polish := 0.1 * marble_bonus * float(committed)
	var next_multiplier := current + roulette_bonus + wager_polish
	if roulette_bonus != 0.0 or wager_polish != 0.0:
		result["damage_multiplier"] = next_multiplier
		result["payout_multiplier"] = next_multiplier
		result["run_upgrade_multiplier_bonus"] = next_multiplier - current
	if roulette_bonus != 0.0:
		result["run_upgrade_roulette_bonus"] = roulette_bonus
	if wager_polish != 0.0:
		result["run_upgrade_wager_polish_bonus"] = wager_polish
	return result

func _nodes_at_step(nodes: Array[Dictionary], step: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in nodes:
		if int(node.get("node_index", -1)) == step:
			result.append(node)
	return result

func _choose_route_node(choices: Array[Dictionary], run_state: Resource) -> Dictionary:
	var best := choices[0]
	var best_score := -9999.0
	for node in choices:
		var score := _route_score(str(node.get("node_type", "")), run_state)
		if score > best_score:
			best_score = score
			best = node
	return best

func _route_score(node_type: String, run_state: Resource) -> float:
	match node_type:
		"boss":
			return 100.0
		"rest":
			return 44.0 if int(run_state.player_hp) <= 24 else 22.0
		"shop":
			return 36.0 if int(run_state.gold) >= 22 else 10.0
		"elite":
			return 22.0 - (16.0 if int(run_state.player_hp) < 28 else 0.0)
		"event":
			return 28.0
		"combat":
			return 24.0
		_:
			return 0.0

func _apply_reward_choice(run_state: Resource, combat_result: Dictionary, metrics: Dictionary) -> void:
	var winnings := int(combat_result.get("winnings", combat_result.get("combat_cash", 0)))
	var is_elite := str(combat_result.get("reward_tier", "normal")) == "elite"
	var seed_text := str(run_state.seed_text) + "|numeric_floor1_reward|" + str(metrics.get("combats", 0))
	var reward_relic_id := ""
	if is_elite:
		reward_relic_id = RelicPoolCatalog.choose_reward_id(run_state.relic_ids, {
			"context": RelicPoolCatalog.CONTEXT_REWARD,
			"source_pool": RelicCatalog.SOURCE_RISK,
			"character_id": str(run_state.character_id),
			"seed_text": seed_text
		})
	var hp_delta := 0
	if not is_elite and int(run_state.player_hp) < int(run_state.player_max_hp) and _stable_sim_roll(seed_text + "|heal") < 12:
		hp_delta = min(3, int(run_state.player_max_hp) - int(run_state.player_hp))
	var ticket_delta := _sim_ticket_delta(is_elite, combat_result, seed_text)
	var gold_bonus := 0
	if not is_elite and _stable_sim_roll(seed_text + "|gold") < 35:
		gold_bonus = 6
	var choice := {
		"accepted": true,
		"choice": "elite_reward" if is_elite else "combat_reward",
		"gold_delta": winnings + gold_bonus,
		"hp_delta": hp_delta,
		"contract_tickets_delta": ticket_delta,
		"relic_ids": [reward_relic_id] if is_elite and reward_relic_id != "" else [],
		"next_combat_mods": []
	}
	metrics["rewards"] = int(metrics["rewards"]) + 1
	metrics["tickets_earned"] = int(metrics.get("tickets_earned", 0)) + ticket_delta
	if hp_delta > 0:
		metrics["reward_heals"] = int(metrics.get("reward_heals", 0)) + 1
	EffectResolver.apply_reward_result(run_state, choice)

func _stable_sim_roll(seed_text: String) -> int:
	return abs(int(hash(seed_text))) % 100

func _sim_ticket_delta(is_elite: bool, combat_result: Dictionary, seed_text: String) -> int:
	if is_elite:
		return 1
	var clear_turn: int = max(0, int(combat_result.get("turn", combat_result.get("turns", 0))))
	var chance: int = min(NORMAL_TICKET_MAX_CHANCE, NORMAL_TICKET_BASE_CHANCE + min(clear_turn, 6) * NORMAL_TICKET_TURN_BONUS)
	return 1 if _stable_sim_roll(seed_text + "|ticket") < chance else 0

func _apply_event_choice(run_state: Resource, node: Dictionary, rng: RandomNumberGenerator, metrics: Dictionary) -> void:
	var event_id := EventCatalog.configured_event_id(run_state.to_payload(), node)
	var profile := EventCatalog.get_profile(event_id)
	var choices: Array = profile.get("choices", [])
	var best_result := {}
	var best_score := -9999.0
	for choice in choices:
		var choice_dict: Dictionary = choice
		if not _choice_is_payable(choice_dict, run_state):
			continue
		var result := _simulate_event_choice_result(choice_dict, run_state, rng)
		var score := _result_utility(result, run_state)
		if score > best_score:
			best_score = score
			best_result = result
	if best_result.is_empty():
		return
	EffectResolver.apply_reward_result(run_state, best_result)

func _simulate_event_choice_result(choice: Dictionary, run_state: Resource, rng: RandomNumberGenerator) -> Dictionary:
	var action := str(choice.get("action", EventCatalog.ACTION_RESULT))
	if action == EventCatalog.ACTION_DICE_CHECK:
		var dice_total := rng.randi_range(1, 6) + rng.randi_range(1, 6) + int(choice.get("dice_bonus", 0))
		var table: Dictionary = choice.get("dice_result_table", {})
		var result: Dictionary = table.get("fail", {"accepted": true, "choice": str(choice.get("id", "")), "hp_delta": -2, "gold_delta": 0})
		if dice_total >= 10:
			result = table.get("great", {"accepted": true, "choice": str(choice.get("id", "")), "hp_delta": 0, "gold_delta": 10, "relic_reward_count": 1})
		elif dice_total >= 8:
			result = table.get("success", {"accepted": true, "choice": str(choice.get("id", "")), "hp_delta": 0, "gold_delta": 10})
		var hydrated := _hydrate_result(result, run_state)
		hydrated["gold_delta"] = int(hydrated.get("gold_delta", 0)) - int(choice.get("cost_gold", 0))
		hydrated["hp_delta"] = int(hydrated.get("hp_delta", 0)) - int(choice.get("cost_hp", 0))
		return hydrated
	if action == EventCatalog.ACTION_CARD_DRAW:
		return _simulate_card_draw(choice, run_state, rng)
	return _hydrate_result(choice.get("result_template", {}), run_state)

func _simulate_card_draw(choice: Dictionary, run_state: Resource, rng: RandomNumberGenerator) -> Dictionary:
	var outcomes: Array[Dictionary] = [
		{"accepted": true, "choice": str(choice.get("id", "")), "gold_delta": 8, "hp_delta": 0, "relic_reward_count": 0},
		{"accepted": true, "choice": str(choice.get("id", "")), "gold_delta": 0, "hp_delta": -3, "relic_reward_count": 1},
		{"accepted": true, "choice": str(choice.get("id", "")), "gold_delta": 5, "hp_delta": 0, "relic_reward_count": 0},
		{"accepted": true, "choice": str(choice.get("id", "")), "gold_delta": 0, "hp_delta": 3, "relic_reward_count": 0}
	]
	var result := _hydrate_result(outcomes[rng.randi_range(0, outcomes.size() - 1)], run_state)
	result["gold_delta"] = int(result.get("gold_delta", 0)) - int(choice.get("cost_gold", 0))
	result["hp_delta"] = int(result.get("hp_delta", 0)) - int(choice.get("cost_hp", 0))
	return result

func _hydrate_result(template: Dictionary, run_state: Resource) -> Dictionary:
	var result := template.duplicate(true)
	if result.is_empty():
		result = {"accepted": true, "choice": "event_none", "gold_delta": 0, "hp_delta": 0, "relic_ids": [], "next_combat_mods": []}
	if not result.has("relic_ids"):
		result["relic_ids"] = []
	var owned: Array = run_state.relic_ids.duplicate()
	for id in result.get("relic_ids", []):
		if not owned.has(str(id)):
			owned.append(str(id))
	for _i in range(int(result.get("relic_reward_count", 0))):
		var relic_id := RelicPoolCatalog.choose_reward_id(owned, {
			"context": RelicPoolCatalog.CONTEXT_EVENT,
			"source_pool": RelicCatalog.SOURCE_BASIC,
			"character_id": str(run_state.character_id),
			"seed_text": str(run_state.seed_text) + "|numeric_floor1_event|" + str(owned.size())
		})
		if relic_id != "" and not (result["relic_ids"] as Array).has(relic_id):
			(result["relic_ids"] as Array).append(relic_id)
			owned.append(relic_id)
	if not result.has("next_combat_mods"):
		result["next_combat_mods"] = []
	if not result.has("run_upgrades"):
		result["run_upgrades"] = {}
	if not result.has("gold_delta"):
		result["gold_delta"] = 0
	if not result.has("hp_delta"):
		result["hp_delta"] = 0
	return result

func _choice_is_payable(choice: Dictionary, run_state: Resource) -> bool:
	if int(choice.get("required_gold", 0)) > int(run_state.gold):
		return false
	if int(choice.get("required_hp", 0)) > int(run_state.player_hp):
		return false
	return true

func _result_utility(result: Dictionary, run_state: Resource) -> float:
	var relic_count := (result.get("relic_ids", []) as Array).size()
	var next_damage_delta := 0
	for mod in result.get("next_combat_mods", []):
		if mod is Dictionary:
			next_damage_delta += int((mod as Dictionary).get("enemy_damage_delta", 0))
	var upgrades: Dictionary = result.get("run_upgrades", {})
	var low_hp_bonus := 1.8 if int(run_state.player_hp) <= 20 else 1.0
	return (
		float(result.get("gold_delta", 0))
		+ float(result.get("hp_delta", 0)) * 3.0 * low_hp_bonus
		+ float(relic_count) * 20.0
		+ float(upgrades.get("primary_die_bonus", upgrades.get("dice_bonus", 0.0))) * 14.0
		+ float(upgrades.get("secondary_die_bonus", 0.0)) * 10.0
		+ float(upgrades.get("roulette_bonus", 0.0)) * 30.0
		+ float(upgrades.get("marble_bonus", 0.0)) * 20.0
		- float(next_damage_delta) * 4.0
	)

func _apply_shop_choice(run_state: Resource, metrics: Dictionary) -> void:
	var bought_any := true
	var bought_ids: Array[String] = []
	while bought_any:
		bought_any = false
		var choices: Array[Dictionary] = ShopOfferCatalog.shop_v2_offer_choices(run_state.to_payload(), 0)
		var best: Dictionary = {}
		var best_score := -9999.0
		for choice in choices:
			var choice_id := str(choice.get("id", ""))
			var service_id := str(choice.get("service_id", choice.get("relic_id", choice_id)))
			if bought_ids.has(service_id):
				continue
			var result: Dictionary = choice.get("result", {})
			var price: int = abs(int(result.get("gold_delta", -int(choice.get("price", 999)))))
			if price > int(run_state.gold):
				continue
			var score := _result_utility(result, run_state)
			if score > best_score:
				best_score = score
				best = choice
		if best.is_empty() or best_score < -2.0:
			break
		var best_result: Dictionary = best.get("result", {})
		var best_id := str(best.get("service_id", best.get("relic_id", best.get("id", ""))))
		bought_ids.append(best_id)
		if best.has("service_id"):
			metrics["service_buys"] = int(metrics["service_buys"]) + 1
		metrics["shop_buys"] = int(metrics["shop_buys"]) + 1
		_record_upgrade_counts(metrics, best_result.get("run_upgrades", {}))
		EffectResolver.apply_reward_result(run_state, best_result)
		bought_any = true

func _apply_rest_choice(run_state: Resource, metrics: Dictionary) -> void:
	if int(run_state.player_hp) <= 22:
		metrics["rest_heals"] = int(metrics["rest_heals"]) + 1
		EffectResolver.apply_reward_result(run_state, RestActionCatalog.result("rest_heal"))
		return
	var upgrade_id := "upgrade_primary_die"
	var primary_bonus := float(run_state.run_upgrades.get("primary_die_bonus", run_state.run_upgrades.get("dice_bonus", 0.0)))
	var secondary_bonus := float(run_state.run_upgrades.get("secondary_die_bonus", 0.0))
	var roulette_bonus := float(run_state.run_upgrades.get("roulette_bonus", 0.0))
	var marble_bonus := float(run_state.run_upgrades.get("marble_bonus", 0.0))
	if primary_bonus < 1.0:
		upgrade_id = "upgrade_primary_die"
	elif secondary_bonus < 1.0 and int(run_state.player_hp) <= 32:
		upgrade_id = "upgrade_secondary_die"
	elif roulette_bonus < 0.2:
		upgrade_id = "upgrade_roulette"
	elif marble_bonus < 1.0:
		upgrade_id = "upgrade_roulette"
	elif primary_bonus < 2.0:
		upgrade_id = "upgrade_primary_die"
	elif secondary_bonus < 2.0:
		upgrade_id = "upgrade_secondary_die"
	else:
		upgrade_id = "upgrade_roulette"
	var result: Dictionary = RestActionCatalog.result(upgrade_id)
	metrics["rest_upgrades"] = int(metrics["rest_upgrades"]) + 1
	_record_upgrade_counts(metrics, result.get("run_upgrades", {}))
	EffectResolver.apply_reward_result(run_state, result)

func _record_upgrade_counts(metrics: Dictionary, upgrades: Dictionary) -> void:
	var counts: Dictionary = metrics.get("upgrade_counts", {})
	for key in upgrades.keys():
		var id := str(key)
		counts[id] = int(counts.get(id, 0)) + int(round(float(upgrades.get(key, 0.0)) / (0.2 if id == "roulette_bonus" else 1.0)))
	metrics["upgrade_counts"] = counts

func _add_upgrade_damage(metrics: Dictionary, damage: Variant) -> void:
	if not damage is Dictionary:
		return
	var total: Dictionary = metrics.get("upgrade_damage", {})
	for key in (damage as Dictionary).keys():
		var id := str(key)
		total[id] = int(total.get(id, 0)) + int((damage as Dictionary).get(key, 0))
	metrics["upgrade_damage"] = total

func _finalize_run_metrics(run_state: Resource, metrics: Dictionary) -> Dictionary:
	metrics["final_hp"] = int(run_state.player_hp)
	metrics["final_gold"] = int(run_state.gold)
	metrics["final_tickets"] = int(run_state.contract_tickets)
	metrics["relic_count"] = run_state.relic_ids.size()
	metrics["relic_source_counts"] = _relic_source_counts(run_state.relic_ids)
	metrics["decision_counts"] = _decision_counts_from(metrics)
	metrics["run_upgrades"] = run_state.run_upgrades.duplicate(true)
	return metrics

func _relic_source_counts(relic_ids: Array) -> Dictionary:
	var counts: Dictionary = {}
	for id in relic_ids:
		var source := RelicCatalog.source_pool(str(id))
		counts[source] = int(counts.get(source, 0)) + 1
	return counts

func _summarize(runs: Array[Dictionary], character_id: String) -> Dictionary:
	var summary: Dictionary = {
		"runs": runs.size(),
		"character": character_id,
		"sim_policy_label": _sim_policy_label(character_id),
		"floor": 1,
		"clears": 0,
		"deaths": 0,
		"clear_rate": 0.0,
		"avg_step": 0.0,
		"avg_final_hp": 0.0,
		"avg_final_gold": 0.0,
		"avg_final_tickets": 0.0,
		"avg_tickets_earned": 0.0,
		"avg_relics": 0.0,
		"avg_combats": 0.0,
		"avg_turns_per_combat": 0.0,
		"avg_damage_taken": 0.0,
		"avg_boss_damage_taken": 0.0,
		"go_attempt_rate": 0.0,
		"go_success_rate": 0.0,
		"zero_hit_rate": 0.0,
		"avg_wager_committed": 0.0,
		"avg_shop_buys": 0.0,
		"avg_service_buys": 0.0,
		"avg_rest_heals": 0.0,
		"avg_rest_upgrades": 0.0,
		"avg_black_debt_hits": 0.0,
		"decision_count_totals": _empty_decision_counts(),
		"avg_decision_counts": {},
		"upgrade_pick_counts": {},
		"upgrade_damage_total": {"primary_die_bonus": 0, "roulette_bonus": 0, "marble_bonus": 0},
		"secondary_block_prevented": 0,
		"relic_source_counts_total": {},
		"avg_relic_source_counts": {},
		"death_steps": {},
		"samples": []
	}
	var total_turns := 0
	var total_combats := 0
	var total_go_attempts := 0
	var total_go_successes := 0
	var total_hits := 0
	var total_zero_hits := 0
	var total_wager_turns := 0
	var total_wager_committed := 0
	for run in runs:
		if bool(run.get("clear", false)):
			summary["clears"] = int(summary["clears"]) + 1
		if bool(run.get("death", false)):
			summary["deaths"] = int(summary["deaths"]) + 1
			var step_id := str(int(run.get("step", 0)))
			var death_steps: Dictionary = summary.get("death_steps", {})
			death_steps[step_id] = int(death_steps.get(step_id, 0)) + 1
			summary["death_steps"] = death_steps
		summary["avg_step"] = float(summary["avg_step"]) + float(run.get("step", 0))
		summary["avg_final_hp"] = float(summary["avg_final_hp"]) + float(run.get("final_hp", 0))
		summary["avg_final_gold"] = float(summary["avg_final_gold"]) + float(run.get("final_gold", 0))
		summary["avg_final_tickets"] = float(summary["avg_final_tickets"]) + float(run.get("final_tickets", 0))
		summary["avg_tickets_earned"] = float(summary["avg_tickets_earned"]) + float(run.get("tickets_earned", 0))
		summary["avg_relics"] = float(summary["avg_relics"]) + float(run.get("relic_count", 0))
		summary["avg_combats"] = float(summary["avg_combats"]) + float(run.get("combats", 0))
		summary["avg_damage_taken"] = float(summary["avg_damage_taken"]) + float(run.get("damage_taken", 0))
		summary["avg_boss_damage_taken"] = float(summary["avg_boss_damage_taken"]) + float(run.get("boss_damage_taken", 0))
		summary["avg_shop_buys"] = float(summary["avg_shop_buys"]) + float(run.get("shop_buys", 0))
		summary["avg_service_buys"] = float(summary["avg_service_buys"]) + float(run.get("service_buys", 0))
		summary["avg_rest_heals"] = float(summary["avg_rest_heals"]) + float(run.get("rest_heals", 0))
		summary["avg_rest_upgrades"] = float(summary["avg_rest_upgrades"]) + float(run.get("rest_upgrades", 0))
		summary["avg_black_debt_hits"] = float(summary["avg_black_debt_hits"]) + float(run.get("black_debt_hits", 0))
		total_turns += int(run.get("turns", 0))
		total_combats += int(run.get("combats", 0))
		total_go_attempts += int(run.get("go_attempts", 0))
		total_go_successes += int(run.get("go_successes", 0))
		total_hits += int(run.get("wager_turns", 0))
		total_zero_hits += int(run.get("zero_hits", 0))
		total_wager_turns += int(run.get("wager_turns", 0))
		total_wager_committed += int(run.get("wager_committed", 0))
		_add_decision_counts(summary["decision_count_totals"], run)
		_merge_counts(summary, "upgrade_pick_counts", run.get("upgrade_counts", {}))
		_merge_counts(summary, "upgrade_damage_total", run.get("upgrade_damage", {}))
		_merge_counts(summary, "relic_source_counts_total", run.get("relic_source_counts", {}))
		summary["secondary_block_prevented"] = int(summary["secondary_block_prevented"]) + int(run.get("secondary_block_prevented", 0))
	for key in ["avg_step", "avg_final_hp", "avg_final_gold", "avg_final_tickets", "avg_tickets_earned", "avg_relics", "avg_combats", "avg_damage_taken", "avg_boss_damage_taken", "avg_shop_buys", "avg_service_buys", "avg_rest_heals", "avg_rest_upgrades", "avg_black_debt_hits"]:
		summary[key] = snapped(float(summary[key]) / max(1.0, float(runs.size())), 0.01)
	summary["clear_rate"] = snapped(float(summary["clears"]) / max(1.0, float(runs.size())), 0.001)
	summary["avg_turns_per_combat"] = snapped(float(total_turns) / max(1.0, float(total_combats)), 0.01)
	summary["go_attempt_rate"] = snapped(float(total_go_attempts) / max(1.0, float(total_hits)), 0.001)
	summary["go_success_rate"] = snapped(float(total_go_successes) / max(1.0, float(total_go_attempts)), 0.001)
	summary["zero_hit_rate"] = snapped(float(total_zero_hits) / max(1.0, float(total_hits)), 0.001)
	summary["avg_wager_committed"] = snapped(float(total_wager_committed) / max(1.0, float(total_wager_turns)), 0.01)
	var avg_decisions: Dictionary = {}
	for key in _decision_count_keys():
		avg_decisions[key] = snapped(float((summary["decision_count_totals"] as Dictionary).get(key, 0)) / max(1.0, float(runs.size())), 0.01)
	summary["avg_decision_counts"] = avg_decisions
	var avg_sources: Dictionary = {}
	for key in (summary["relic_source_counts_total"] as Dictionary).keys():
		var id := str(key)
		avg_sources[id] = snapped(float((summary["relic_source_counts_total"] as Dictionary).get(key, 0)) / max(1.0, float(runs.size())), 0.01)
	summary["avg_relic_source_counts"] = avg_sources
	for i in range(min(5, runs.size())):
		var run := runs[i]
		(summary["samples"] as Array).append({
			"seed": str(run.get("seed", "")),
			"clear": bool(run.get("clear", false)),
			"step": int(run.get("step", 0)),
			"hp": int(run.get("final_hp", 0)),
			"gold": int(run.get("final_gold", 0)),
			"tickets": int(run.get("final_tickets", 0)),
			"relics": int(run.get("relic_count", 0)),
			"relic_sources": run.get("relic_source_counts", {}),
			"decision_counts": run.get("decision_counts", {}),
			"upgrades": run.get("run_upgrades", {}),
			"route_prefix": (run.get("route", []) as Array).slice(0, 12)
		})
	return summary

func _merge_counts(summary: Dictionary, key: String, counts_value: Variant) -> void:
	if not counts_value is Dictionary:
		return
	var target: Dictionary = summary.get(key, {})
	for count_key in (counts_value as Dictionary).keys():
		var id := str(count_key)
		target[id] = int(target.get(id, 0)) + int((counts_value as Dictionary).get(count_key, 0))
	summary[key] = target
