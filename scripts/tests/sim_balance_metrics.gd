extends SceneTree

const RunStateScript := preload("res://scripts/resources/run_state.gd")
const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const DiceResolver := preload("res://scripts/systems/dice_resolver.gd")
const RouletteResolver := preload("res://scripts/systems/roulette_resolver.gd")
const RouletteSlotCatalog := preload("res://scripts/systems/roulette_slot_catalog.gd")
const PayoutResolver := preload("res://scripts/systems/payout_resolver.gd")
const MonsterMoveCatalog := preload("res://scripts/systems/monster_move_catalog.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RelicPoolCatalog := preload("res://scripts/systems/relic_pool_catalog.gd")
const EventCatalog := preload("res://scripts/systems/event_catalog.gd")
const ShopOfferCatalog := preload("res://scripts/systems/shop_offer_catalog.gd")
const RestActionCatalog := preload("res://scripts/systems/rest_action_catalog.gd")
const CharacterContractCatalog := preload("res://scripts/systems/character_contract_catalog.gd")

const LEGACY_SLOT_SIM_ENV := "LUCK_ALLOW_LEGACY_SLOT_SIM"
const DEFAULT_SEED_COUNT := 80
const MAX_TURNS_PER_COMBAT := 18
const MAX_EVENTS_PER_RUN := 80
const NORMAL_TICKET_BASE_CHANCE := 15
const NORMAL_TICKET_TURN_BONUS := 3
const NORMAL_TICKET_MAX_CHANCE := 35
const POLICIES := [
	{
		"id": "guided",
		"marker_slot": "safe",
		"risk": 0.0,
		"upgrade_bias": "dice"
	},
	{
		"id": "guided_bust_marker",
		"marker_slot": "bust",
		"risk": 0.0,
		"upgrade_bias": "dice"
	},
	{
		"id": "guided_jackpot_marker",
		"marker_slot": "jackpot",
		"risk": 0.0,
		"upgrade_bias": "dice"
	},
	{
		"id": "optimizer",
		"marker_slot": "bust",
		"risk": 0.45,
		"upgrade_bias": "dice"
	},
	{
		"id": "jackpot",
		"marker_slot": "jackpot",
		"risk": 0.8,
		"upgrade_bias": "roulette"
	}
]

func _initialize() -> void:
	if OS.get_environment(LEGACY_SLOT_SIM_ENV) != "1":
		push_error("sim_balance_metrics.gd is a legacy slot-marble simulator. Use sim_numeric_floor1_guard_metrics.gd or sim_numeric_floor1_character_metrics.gd for current Go/Stop proof, or set " + LEGACY_SLOT_SIM_ENV + "=1 for historical inspection.")
		quit(1)
		return
	var summaries: Array[Dictionary] = []
	var seed_count := _seed_count()
	var policies := _selected_policies()
	for policy in policies:
		var policy_summary := _run_policy(policy, seed_count)
		summaries.append(policy_summary)
		_print_summary(policy_summary)
	var failed := false
	for summary in summaries:
		if int(summary.get("runs", 0)) != seed_count:
			failed = true
	if failed:
		quit(1)
	else:
		print("balance metrics simulation passed")
		quit(0)

func _seed_count() -> int:
	var raw := OS.get_environment("LUCK_SIM_SEED_COUNT")
	if raw.is_valid_int():
		return max(1, int(raw))
	return DEFAULT_SEED_COUNT

func _selected_policies() -> Array:
	var raw := OS.get_environment("LUCK_SIM_POLICY_IDS").strip_edges()
	if raw == "":
		return POLICIES
	var allowed: Array[String] = []
	for item in raw.split(",", false):
		var policy_id := str(item).strip_edges()
		if policy_id != "":
			allowed.append(policy_id)
	var selected: Array = []
	for policy in POLICIES:
		if allowed.has(str(policy.get("id", ""))):
			selected.append(policy)
	return selected if not selected.is_empty() else POLICIES

func _character_id() -> String:
	var raw := OS.get_environment("LUCK_SIM_CHARACTER_ID").strip_edges()
	return raw if raw != "" else "default_guard_dice"

func _run_policy(policy: Dictionary, seed_count: int) -> Dictionary:
	var runs: Array[Dictionary] = []
	for i in range(seed_count):
		runs.append(_simulate_run("balance-" + str(i).pad_zeros(4), policy))
	return _summarize_runs(str(policy.get("id", "policy")), runs)

func _simulate_run(seed_text: String, policy: Dictionary) -> Dictionary:
	var run_state = RunStateScript.new()
	run_state.seed_text = seed_text
	run_state.gold = 0
	run_state.player_hp = 42
	run_state.player_max_hp = 42
	run_state.character_id = _character_id()
	run_state.relic_ids = CharacterContractCatalog.starting_relic_ids(run_state.character_id)
	run_state.floor_index = 1
	run_state.max_floor = 3
	run_state.map_variant = "scroll_20_random"
	run_state.map_theme_id = "01_base"
	run_state.map_step = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("balance-run:" + seed_text + ":" + str(policy.get("id", "")))
	var metrics := {
		"seed": seed_text,
		"policy": str(policy.get("id", "")),
		"win": false,
		"death": false,
		"floor": 1,
		"step": 0,
		"combats": 0,
		"combat_wins": 0,
		"events": 0,
		"shops": 0,
		"rests": 0,
		"elites": 0,
		"bosses": 0,
		"turns": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"bust_landings": 0,
		"marked_landings": 0,
		"rewards": 0,
		"relic_rewards": 0,
		"reward_heals": 0,
		"tickets_earned": 0,
		"shop_buys": 0,
		"event_relics": 0,
		"event_hp_delta": 0,
		"event_gold_delta": 0,
		"rest_heals": 0,
		"rest_upgrades": 0,
		"route": []
	}
	var guard := 0
	while guard < MAX_EVENTS_PER_RUN:
		guard += 1
		metrics["floor"] = int(run_state.floor_index)
		metrics["step"] = int(run_state.map_step)
		var floor_seed := str(run_state.seed_text) + ":floor:" + str(int(run_state.floor_index))
		var nodes := EncounterCatalog.map_nodes(str(run_state.map_variant), floor_seed)
		var choices := _nodes_at_step(nodes, int(run_state.map_step))
		if choices.is_empty():
			metrics["death"] = true
			(metrics["route"] as Array).append("missing_step_" + str(run_state.map_step))
			break
		var node := _choose_route_node(choices, run_state, policy)
		var node_type := str(node.get("node_type", "combat"))
		(metrics["route"] as Array).append("f" + str(run_state.floor_index) + "s" + str(run_state.map_step) + ":" + node_type)
		match node_type:
			"combat", "elite", "boss":
				if node_type == "elite":
					metrics["elites"] = int(metrics["elites"]) + 1
				if node_type == "boss":
					metrics["bosses"] = int(metrics["bosses"]) + 1
				var combat_result := _simulate_combat(run_state, node, policy, rng)
				metrics["combats"] = int(metrics["combats"]) + 1
				metrics["turns"] = int(metrics["turns"]) + int(combat_result.get("turns", 0))
				metrics["damage_dealt"] = int(metrics["damage_dealt"]) + int(combat_result.get("damage_dealt", 0))
				metrics["damage_taken"] = int(metrics["damage_taken"]) + int(combat_result.get("damage_taken", 0))
				metrics["bust_landings"] = int(metrics["bust_landings"]) + int(combat_result.get("bust_landings", 0))
				metrics["marked_landings"] = int(metrics["marked_landings"]) + int(combat_result.get("marked_landings", 0))
				run_state.player_hp = int(combat_result.get("player_hp", run_state.player_hp))
				run_state.gold = max(0, int(run_state.gold) + int(combat_result.get("gold_delta", 0)))
				if bool(combat_result.get("victory", false)):
					metrics["combat_wins"] = int(metrics["combat_wins"]) + 1
					if node_type == "boss":
						if int(run_state.floor_index) >= int(run_state.max_floor):
							metrics["win"] = true
							break
						run_state.floor_index += 1
						run_state.player_hp = int(run_state.player_max_hp)
						run_state.map_step = 0
						run_state.completed_nodes.clear()
					else:
						_apply_reward_choice(run_state, combat_result, policy, metrics)
						run_state.map_step += 1
				else:
					metrics["death"] = true
					break
			"event":
				metrics["events"] = int(metrics["events"]) + 1
				_apply_event_choice(run_state, node, policy, rng, metrics)
				run_state.map_step += 1
			"shop":
				metrics["shops"] = int(metrics["shops"]) + 1
				_apply_shop_choice(run_state, policy, metrics)
				run_state.map_step += 1
			"rest":
				metrics["rests"] = int(metrics["rests"]) + 1
				_apply_rest_choice(run_state, policy, metrics)
				run_state.map_step += 1
			_:
				run_state.map_step += 1
		if int(run_state.player_hp) <= 0:
			metrics["death"] = true
			break
	return _finalize_metrics(run_state, metrics)

func _simulate_combat(run_state: Resource, node: Dictionary, policy: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var payload := EffectResolver.build_encounter_payload(run_state, node)
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
	var relic_state := {}
	var run_upgrades: Dictionary = payload.get("run_upgrades", {})
	var dice_rule_id := str(payload.get("dice_rule_id", DiceResolver.default_rule_id()))
	var combat_cash := int(payload.get("combat_cash", 18))
	var turn := 1
	var total_damage := 0
	var total_taken := 0
	var bust_landings := 0
	var marked_landings := 0
	while turn <= MAX_TURNS_PER_COMBAT and player_hp > 0 and enemy_hp > 0:
		var player_block := 0
		var turn_payload := EffectResolver.apply_relic_trigger("turn_start", {
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
			"pattern_tuning": monster_pattern_tuning,
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
		var dice_values := _choose_dice_pair(dice_rule_id, policy, rng, enemy_hp, move_id, enemy_damage_delta, monster_pattern_tuning)
		var selected_index := _choose_attack_die_index(dice_values, policy, enemy_hp, move_id, enemy_damage_delta, monster_pattern_tuning)
		var dice_result := DiceResolver.compute_result(dice_values, [false, false], dice_rule_id, 0, [], selected_index)
		dice_result["cash"] = combat_cash
		dice_result["player_block"] = player_block
		dice_result["relic_state"] = relic_state
		dice_result = EffectResolver.apply_relic_trigger("dice_result", dice_result, relic_ids)
		combat_cash = int(dice_result.get("cash", combat_cash))
		relic_state = dice_result.get("relic_state", relic_state)
		dice_result = _apply_dice_upgrade(dice_result, run_upgrades)
		var attack_base := int(dice_result.get("attack_base", 0))
		player_block += int(dice_result.get("guard_value", dice_result.get("player_block", 0)))
		var marble_payload := EffectResolver.apply_relic_trigger("marble_gain", {
			"attack_base": attack_base,
			"marble_count": 1,
			"marbles": ["plain"],
			"dice_values": dice_result.get("dice_values", dice_values),
			"dice_rule_id": dice_rule_id,
			"selected_attack_die_index": selected_index,
			"guard_value": player_block,
			"player_block": player_block,
			"relic_state": relic_state,
			"applied_effects": []
		}, relic_ids)
		relic_state = marble_payload.get("relic_state", relic_state)
		var placed_slots := _placed_slots_for_policy(policy, int(marble_payload.get("marble_count", 1)))
		var before_spin := EffectResolver.apply_relic_trigger("roulette_before_spin", {
			"placed_slots": placed_slots,
			"attack_base": attack_base,
			"roulette_respins_left": 0,
			"relic_state": relic_state,
			"applied_effects": []
		}, relic_ids)
		relic_state = before_spin.get("relic_state", relic_state)
		var respins_left := int(before_spin.get("roulette_respins_left", 0))
		var pending_slot := RouletteResolver.weighted_pick(placed_slots, rng)
		if pending_slot == "bust" and respins_left > 0:
			var rerolled_slot := RouletteResolver.weighted_pick(placed_slots, rng)
			if rerolled_slot != "bust":
				pending_slot = rerolled_slot
		var after_spin := EffectResolver.apply_relic_trigger("roulette_after_spin", {
			"pending_slot": pending_slot,
			"placed_slots": placed_slots,
			"cash": combat_cash,
			"cash_delta": 0,
			"attack_base": attack_base,
			"relic_state": relic_state,
			"applied_effects": []
		}, relic_ids)
		pending_slot = str(after_spin.get("pending_slot", pending_slot))
		combat_cash = int(after_spin.get("cash", combat_cash))
		relic_state = after_spin.get("relic_state", relic_state)
		if pending_slot == "bust":
			bust_landings += 1
		if RouletteSlotCatalog.has_placed_token(placed_slots, pending_slot):
			marked_landings += 1
		var resolution_payload := {
			"pending_slot": pending_slot,
			"placed_slots": placed_slots,
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
			"dice_values": dice_result.get("dice_values", dice_values),
			"dice_rule_id": dice_rule_id,
			"selected_attack_die_index": selected_index,
			"player_attack_delta": player_attack_delta,
			"player_damage_multiplier": player_damage_multiplier,
			"damage_multiplier": 1.0,
			"payout_multiplier": 1.0,
			"relic_state": relic_state,
			"applied_effects": []
		}
		resolution_payload = EffectResolver.apply_relic_trigger("resolution_before", resolution_payload, relic_ids)
		relic_state = resolution_payload.get("relic_state", relic_state)
		resolution_payload = _apply_resolution_upgrades(resolution_payload, run_upgrades)
		var outcome := PayoutResolver.resolve(
			str(resolution_payload.get("pending_slot", pending_slot)),
			resolution_payload.get("placed_slots", placed_slots),
			int(resolution_payload.get("cash", 0)),
			player_hp,
			enemy_hp,
			float(resolution_payload.get("damage_multiplier", 1.0)),
			int(resolution_payload.get("attack_base", attack_base)),
			int(resolution_payload.get("flat_damage_bonus", 0)),
			int(resolution_payload.get("cash_delta_bonus", 0)),
			int(resolution_payload.get("enemy_block", enemy_block)),
			float(resolution_payload.get("player_damage_multiplier", player_damage_multiplier))
		)
		outcome["enemy_damage_delta"] = int(resolution_payload.get("enemy_damage_delta", enemy_damage_delta))
		outcome["placed_slots"] = resolution_payload.get("placed_slots", placed_slots)
		outcome["relic_state"] = relic_state
		outcome["player_max_hp"] = int(resolution_payload.get("player_max_hp", payload.get("player_max_hp", 42)))
		outcome["dice_values"] = resolution_payload.get("dice_values", dice_values)
		outcome["dice_rule_id"] = str(resolution_payload.get("dice_rule_id", dice_rule_id))
		outcome["selected_attack_die_index"] = int(resolution_payload.get("selected_attack_die_index", selected_index))
		outcome = EffectResolver.apply_relic_trigger("resolution_after", outcome, relic_ids)
		relic_state = outcome.get("relic_state", relic_state)
		var damage := int(outcome.get("damage", 0))
		total_damage += damage
		enemy_hp = int(outcome.get("enemy_hp", enemy_hp))
		enemy_block = int(outcome.get("enemy_block", enemy_block))
		enemy_damage_delta = int(outcome.get("enemy_damage_delta", enemy_damage_delta))
		combat_cash = int(outcome.get("cash", combat_cash))
		player_attack_delta = 0
		player_damage_multiplier = 1.0
		if enemy_hp <= 0:
			break
		var move_result := MonsterMoveCatalog.resolve_enemy_turn(move_id, {
			"player_hp": player_hp,
			"player_block": player_block,
			"enemy_damage_delta": enemy_damage_delta,
			"enemy_damage_multiplier": enemy_damage_multiplier,
			"enemy_block": enemy_block,
			"player_attack_delta": player_attack_delta,
			"player_damage_multiplier": player_damage_multiplier,
			"run_gold": run_gold,
			"pattern_tuning": monster_pattern_tuning,
			"cash": combat_cash
		}, 0)
		move_result["relic_state"] = relic_state
		move_result = EffectResolver.apply_relic_trigger("damage_taken", move_result, relic_ids)
		relic_state = move_result.get("relic_state", relic_state)
		total_taken += int(move_result.get("damage", 0))
		player_hp = int(move_result.get("player_hp", player_hp))
		enemy_damage_delta = int(move_result.get("enemy_damage_delta", 0))
		enemy_damage_multiplier = float(move_result.get("enemy_damage_multiplier", 1.0))
		enemy_block = int(move_result.get("enemy_block", enemy_block))
		player_attack_delta = int(move_result.get("player_attack_delta", player_attack_delta))
		player_damage_multiplier = float(move_result.get("player_damage_multiplier", player_damage_multiplier))
		combat_cash = int(move_result.get("cash", combat_cash))
		run_gold = int(move_result.get("run_gold", run_gold))
		gold_delta += int(move_result.get("gold_delta", 0))
		turn += 1
	var result := {
		"victory": enemy_hp <= 0,
		"defeat": player_hp <= 0 or enemy_hp > 0,
		"player_hp": max(0, player_hp),
		"player_max_hp": int(payload.get("player_max_hp", 42)),
		"enemy_hp": max(0, enemy_hp),
		"turns": turn,
		"turn": turn,
		"damage_dealt": total_damage,
		"damage_taken": total_taken,
		"bust_landings": bust_landings,
		"marked_landings": marked_landings,
		"winnings": combat_cash,
		"combat_cash": combat_cash,
		"cash": combat_cash,
		"run_gold": run_gold,
		"gold_delta": gold_delta,
		"reward_tier": str(payload.get("reward_tier", "normal")),
		"relic_state": relic_state,
		"applied_effects": []
	}
	if bool(result.get("victory", false)):
		result = EffectResolver.apply_relic_trigger("combat_victory", result, relic_ids)
	else:
		result = EffectResolver.apply_relic_trigger("combat_end", result, relic_ids)
	return result

func _choose_dice_pair(rule_id: String, policy: Dictionary, rng: RandomNumberGenerator, enemy_hp: int, move_id: String, enemy_damage_delta: int, monster_pattern_tuning: Dictionary) -> Array[int]:
	var best: Array[int] = [1, 1]
	var best_score := -9999.0
	var rolls := int(DiceResolver.rule(rule_id).get("rerolls", 2)) + 1
	for _i in range(max(1, rolls)):
		var pair: Array[int] = []
		for _j in range(int(DiceResolver.rule(rule_id).get("dice_count", 2))):
			pair.append(rng.randi_range(1, int(DiceResolver.rule(rule_id).get("sides", 6))))
		var score := _dice_pair_score(pair, policy, enemy_hp, move_id, enemy_damage_delta, monster_pattern_tuning)
		if score > best_score:
			best_score = score
			best = pair
	return best

func _dice_pair_score(pair: Array[int], policy: Dictionary, enemy_hp: int, move_id: String, enemy_damage_delta: int, monster_pattern_tuning: Dictionary) -> float:
	var attack_index := _choose_attack_die_index(pair, policy, enemy_hp, move_id, enemy_damage_delta, monster_pattern_tuning)
	var attack := int(pair[attack_index])
	var block := 0
	for i in range(pair.size()):
		if i != attack_index:
			block += int(pair[i])
	var incoming: int = max(0, int(MonsterMoveCatalog.tuned_move(move_id, monster_pattern_tuning).get("damage", 0)) + enemy_damage_delta)
	var prevented: int = min(block, incoming)
	var lethal_bonus := 7.5 if attack >= enemy_hp else 0.0
	var risk := float(policy.get("risk", 0.0))
	return float(attack) * (1.2 + risk) + float(prevented) * (1.0 - risk * 0.45) + lethal_bonus

func _choose_attack_die_index(pair: Array[int], policy: Dictionary, enemy_hp: int, move_id: String, enemy_damage_delta: int, monster_pattern_tuning: Dictionary) -> int:
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
		var incoming: int = max(0, int(MonsterMoveCatalog.tuned_move(move_id, monster_pattern_tuning).get("damage", 0)) + enemy_damage_delta)
		var prevented: int = min(block, incoming)
		var risk := float(policy.get("risk", 0.0))
		var score := float(attack) * (1.2 + risk) + float(prevented) * (1.0 - risk * 0.5)
		if attack >= enemy_hp:
			score += 8.0
		if score > best_score:
			best_score = score
			best_index = i
	return best_index

func _placed_slots_for_policy(policy: Dictionary, marble_count: int) -> Dictionary:
	var result := {}
	var slot := str(policy.get("marker_slot", "safe"))
	if not RouletteSlotCatalog.has_slot(slot):
		slot = RouletteSlotCatalog.fallback_id()
	for id in RouletteSlotCatalog.slot_ids():
		result[id] = []
	var ids := RouletteSlotCatalog.slot_ids()
	var center := ids.find(slot)
	for i in range(max(1, marble_count)):
		var target := slot
		if i > 0:
			var distance := int(ceil(float(i) / 2.0))
			var direction := 1 if i % 2 == 1 else -1
			target = str(ids[(center + direction * distance + ids.size() * 2) % ids.size()])
		(result[target] as Array).append("plain")
	return result

func _apply_dice_upgrade(result: Dictionary, run_upgrades: Dictionary) -> Dictionary:
	var next := result.duplicate(true)
	var primary_bonus := int(round(float(run_upgrades.get("primary_die_bonus", run_upgrades.get("dice_bonus", 0.0)))))
	var secondary_bonus := int(round(float(run_upgrades.get("secondary_die_bonus", 0.0))))
	if primary_bonus != 0:
		next["attack_base"] = max(0, int(next.get("attack_base", 0)) + primary_bonus)
	if secondary_bonus != 0:
		if next.has("guard_value"):
			next["guard_value"] = max(0, int(next.get("guard_value", 0)) + secondary_bonus)
		if next.has("player_block"):
			next["player_block"] = max(0, int(next.get("player_block", 0)) + secondary_bonus)
	return next

func _apply_resolution_upgrades(payload: Dictionary, run_upgrades: Dictionary) -> Dictionary:
	var result := payload.duplicate(true)
	var roulette_bonus := float(run_upgrades.get("roulette_bonus", 0.0))
	var pending := str(result.get("pending_slot", ""))
	var placed: Dictionary = result.get("placed_slots", {})
	var marble_bonus := float(run_upgrades.get("marble_bonus", 0.0)) if RouletteSlotCatalog.has_placed_token(placed, pending) else 0.0
	var marble_multiplier := RouletteSlotCatalog.marble_upgrade_multiplier(pending) if marble_bonus != 0.0 else 1.0
	var current := float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0)))
	var next_multiplier := current + roulette_bonus
	if marble_bonus != 0.0:
		next_multiplier *= marble_multiplier
	if roulette_bonus != 0.0 or marble_bonus != 0.0:
		result["damage_multiplier"] = next_multiplier
		result["payout_multiplier"] = next_multiplier
	return result

func _nodes_at_step(nodes: Array[Dictionary], step: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in nodes:
		if int(node.get("node_index", -1)) == step:
			result.append(node)
	return result

func _choose_route_node(choices: Array[Dictionary], run_state: Resource, policy: Dictionary) -> Dictionary:
	var best := choices[0]
	var best_score := -9999.0
	for node in choices:
		var score := _route_score(str(node.get("node_type", "")), run_state, policy)
		if score > best_score:
			best_score = score
			best = node
	return best

func _route_score(node_type: String, run_state: Resource, policy: Dictionary) -> float:
	match node_type:
		"boss":
			return 100.0
		"rest":
			return 38.0 if int(run_state.player_hp) <= 24 else 16.0
		"shop":
			return 30.0 if int(run_state.gold) >= 30 else 8.0
		"elite":
			return 24.0 + float(policy.get("risk", 0.0)) * 18.0 - (14.0 if int(run_state.player_hp) < 25 else 0.0)
		"event":
			return 28.0
		"combat":
			return 22.0
		_:
			return 0.0

func _apply_reward_choice(run_state: Resource, combat_result: Dictionary, policy: Dictionary, metrics: Dictionary) -> void:
	var winnings := int(combat_result.get("winnings", combat_result.get("combat_cash", 0)))
	var is_elite := str(combat_result.get("reward_tier", "normal")) == "elite"
	var seed_text := str(run_state.seed_text) + "|sim_reward|" + str(metrics.get("combats", 0))
	var reward_relic_id := ""
	if is_elite:
		reward_relic_id = RelicPoolCatalog.choose_reward_id(run_state.relic_ids, {
			"context": RelicPoolCatalog.CONTEXT_REWARD,
			"source_pool": RelicCatalog.SOURCE_BASIC,
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
	if not (choice.get("relic_ids", []) as Array).is_empty():
		metrics["relic_rewards"] = int(metrics["relic_rewards"]) + 1
	EffectResolver.apply_reward_result(run_state, choice)

func _stable_sim_roll(seed_text: String) -> int:
	return abs(int(hash(seed_text))) % 100

func _sim_ticket_delta(is_elite: bool, combat_result: Dictionary, seed_text: String) -> int:
	if is_elite:
		return 1
	var clear_turn: int = max(0, int(combat_result.get("turn", combat_result.get("turns", 0))))
	var chance: int = min(NORMAL_TICKET_MAX_CHANCE, NORMAL_TICKET_BASE_CHANCE + min(clear_turn, 6) * NORMAL_TICKET_TURN_BONUS)
	return 1 if _stable_sim_roll(seed_text + "|ticket") < chance else 0

func _apply_event_choice(run_state: Resource, node: Dictionary, policy: Dictionary, rng: RandomNumberGenerator, metrics: Dictionary) -> void:
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
		var score := _result_utility(result, run_state, policy)
		if score > best_score:
			best_score = score
			best_result = result
	if best_result.is_empty():
		return
	metrics["event_hp_delta"] = int(metrics["event_hp_delta"]) + int(best_result.get("hp_delta", 0))
	metrics["event_gold_delta"] = int(metrics["event_gold_delta"]) + int(best_result.get("gold_delta", 0))
	metrics["event_relics"] = int(metrics["event_relics"]) + (best_result.get("relic_ids", []) as Array).size()
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
	if action == EventCatalog.ACTION_ROULETTE_CHECK:
		var slot := RouletteResolver.weighted_pick({}, rng)
		var table: Dictionary = choice.get("roulette_result_table", {})
		return _hydrate_result(table.get(slot, table.get("default", {})), run_state)
	if action == EventCatalog.ACTION_CARD_DRAW:
		return _simulate_card_draw(choice, run_state, rng)
	return _hydrate_result(choice.get("result_template", {}), run_state)

func _simulate_card_draw(choice: Dictionary, run_state: Resource, rng: RandomNumberGenerator) -> Dictionary:
	var peeked := bool(choice.get("card_peeked", false))
	var outcomes: Array[Dictionary] = [
		{"accepted": true, "choice": str(choice.get("id", "")), "gold_delta": 8, "hp_delta": 0, "relic_reward_count": 0},
		{"accepted": true, "choice": str(choice.get("id", "")), "gold_delta": 0, "hp_delta": -3, "relic_reward_count": 1},
		{"accepted": true, "choice": str(choice.get("id", "")), "gold_delta": 5, "hp_delta": 0, "relic_reward_count": 0},
		{"accepted": true, "choice": str(choice.get("id", "")), "gold_delta": 0, "hp_delta": 5 if peeked else 3, "relic_reward_count": 0}
	]
	if peeked:
		outcomes.append({"accepted": true, "choice": str(choice.get("id", "")), "gold_delta": 6, "hp_delta": 0, "relic_reward_count": 1})
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
			"seed_text": str(run_state.seed_text) + "|sim_event|" + str(owned.size())
		})
		if relic_id == "":
			continue
		if not (result["relic_ids"] as Array).has(relic_id):
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

func _result_utility(result: Dictionary, run_state: Resource, policy: Dictionary) -> float:
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
		+ float(relic_count) * (18.0 + float(policy.get("risk", 0.0)) * 4.0)
		+ float(upgrades.get("primary_die_bonus", upgrades.get("dice_bonus", 0.0))) * 12.0
		+ float(upgrades.get("secondary_die_bonus", 0.0)) * 8.0
		+ float(upgrades.get("roulette_bonus", 0.0)) * 32.0
		+ float(upgrades.get("marble_bonus", 0.0)) * 22.0
		- float(next_damage_delta) * 4.0
	)

func _apply_shop_choice(run_state: Resource, policy: Dictionary, metrics: Dictionary) -> void:
	var offers := ShopOfferCatalog.relic_offer_choices(run_state.to_payload(), 3)
	var best := {}
	var best_score := -9999.0
	for offer in offers:
		var offer_dict: Dictionary = offer
		var price := int(offer_dict.get("price", 999))
		if price > int(run_state.gold):
			continue
		var score := _relic_shop_utility(str(offer_dict.get("relic_id", "")), policy) - float(price)
		if score > best_score:
			best_score = score
			best = offer_dict
	if best.is_empty() or best_score < -6.0:
		return
	var result := {
		"accepted": true,
		"choice": str(best.get("id", "shop_relic")),
		"gold_delta": -int(best.get("price", 0)),
		"hp_delta": 0,
		"relic_ids": [str(best.get("relic_id", ""))],
		"next_combat_mods": []
	}
	metrics["shop_buys"] = int(metrics["shop_buys"]) + 1
	EffectResolver.apply_reward_result(run_state, result)

func _relic_shop_utility(relic_id: String, policy: Dictionary) -> float:
	match relic_id:
		"loaded_die", "snake_eyes_charm", "locksmith_glove":
			return 40.0
		"dice_under_six", "dice_low_guard":
			return 38.0
		"yellow_guard", "bust_insurance", "def_first_hit":
			return 36.0 if float(policy.get("risk", 0.0)) < 0.5 else 30.0
		"twin_marker", "blue_chisel", "purple_contract", "second_chance", "marker_adjacent", "wheel_overdrive_pin":
			return 34.0 + float(policy.get("risk", 0.0)) * 10.0
		"gamblers_spare_marble", "gamblers_last_reroll", "cursed_players_split_tooth", "cursed_players_red_marble", "marble_savant_charm", "roulette_savant_pin":
			return 38.0 + float(policy.get("risk", 0.0)) * 8.0
		"jackpot_knife", "wheel_jackpot_blood", "cursed_players_pain_bell":
			return 34.0 + float(policy.get("risk", 0.0)) * 14.0
		"risk_last_hand", "gamblers_odd_eye", "risk_rare_pull":
			return 32.0
		"turn_token", "green_purse", "last_call_bell", "marker_miss_gold", "wheel_profit_tithe":
			return 30.0
		_:
			return 24.0

func _apply_rest_choice(run_state: Resource, policy: Dictionary, metrics: Dictionary) -> void:
	if int(run_state.player_hp) <= 22:
		metrics["rest_heals"] = int(metrics["rest_heals"]) + 1
		EffectResolver.apply_reward_result(run_state, RestActionCatalog.result("rest_heal"))
		return
	var upgrade_id := "upgrade_primary_die"
	var marker_slot := str(policy.get("marker_slot", "safe"))
	var primary_bonus := float(run_state.run_upgrades.get("primary_die_bonus", run_state.run_upgrades.get("dice_bonus", 0.0)))
	var secondary_bonus := float(run_state.run_upgrades.get("secondary_die_bonus", 0.0))
	if secondary_bonus < 1.0 and int(run_state.player_hp) <= 32:
		upgrade_id = "upgrade_secondary_die"
	elif primary_bonus < 1.0:
		upgrade_id = "upgrade_primary_die"
	elif secondary_bonus < 1.0:
		upgrade_id = "upgrade_secondary_die"
	elif marker_slot != "safe" and float(run_state.run_upgrades.get("marble_bonus", 0.0)) < 1.0:
		upgrade_id = "upgrade_roulette"
	elif str(policy.get("upgrade_bias", "dice")) == "roulette":
		upgrade_id = "upgrade_roulette"
	elif primary_bonus < 2.0:
		upgrade_id = "upgrade_primary_die"
	elif marker_slot != "safe" and float(run_state.run_upgrades.get("marble_bonus", 0.0)) < 1.0:
		upgrade_id = "upgrade_roulette"
	else:
		upgrade_id = "upgrade_roulette"
	metrics["rest_upgrades"] = int(metrics["rest_upgrades"]) + 1
	EffectResolver.apply_reward_result(run_state, RestActionCatalog.result(upgrade_id))

func _finalize_metrics(run_state: Resource, metrics: Dictionary) -> Dictionary:
	metrics["final_hp"] = int(run_state.player_hp)
	metrics["final_gold"] = int(run_state.gold)
	metrics["final_tickets"] = int(run_state.contract_tickets)
	metrics["relic_count"] = run_state.relic_ids.size()
	metrics["run_upgrades"] = run_state.run_upgrades.duplicate(true)
	return metrics

func _summarize_runs(policy_id: String, runs: Array[Dictionary]) -> Dictionary:
	var summary := {
		"policy": policy_id,
		"runs": runs.size(),
		"wins": 0,
		"deaths": 0,
		"avg_floor": 0.0,
		"avg_step": 0.0,
		"avg_hp": 0.0,
		"avg_gold": 0.0,
		"avg_tickets": 0.0,
		"avg_tickets_earned": 0.0,
		"avg_relics": 0.0,
		"avg_combats": 0.0,
		"avg_turns_per_combat": 0.0,
		"avg_damage_taken": 0.0,
		"avg_busts": 0.0,
		"avg_marked_landings": 0.0,
		"avg_shop_buys": 0.0,
		"avg_rest_heals": 0.0,
		"samples": []
	}
	var total_turns := 0
	var total_combats := 0
	for run in runs:
		if bool(run.get("win", false)):
			summary["wins"] = int(summary["wins"]) + 1
		if bool(run.get("death", false)):
			summary["deaths"] = int(summary["deaths"]) + 1
		summary["avg_floor"] = float(summary["avg_floor"]) + float(run.get("floor", 0))
		summary["avg_step"] = float(summary["avg_step"]) + float(run.get("step", 0))
		summary["avg_hp"] = float(summary["avg_hp"]) + float(run.get("final_hp", 0))
		summary["avg_gold"] = float(summary["avg_gold"]) + float(run.get("final_gold", 0))
		summary["avg_tickets"] = float(summary["avg_tickets"]) + float(run.get("final_tickets", 0))
		summary["avg_tickets_earned"] = float(summary["avg_tickets_earned"]) + float(run.get("tickets_earned", 0))
		summary["avg_relics"] = float(summary["avg_relics"]) + float(run.get("relic_count", 0))
		summary["avg_combats"] = float(summary["avg_combats"]) + float(run.get("combats", 0))
		summary["avg_damage_taken"] = float(summary["avg_damage_taken"]) + float(run.get("damage_taken", 0))
		summary["avg_busts"] = float(summary["avg_busts"]) + float(run.get("bust_landings", 0))
		summary["avg_marked_landings"] = float(summary["avg_marked_landings"]) + float(run.get("marked_landings", 0))
		summary["avg_shop_buys"] = float(summary["avg_shop_buys"]) + float(run.get("shop_buys", 0))
		summary["avg_rest_heals"] = float(summary["avg_rest_heals"]) + float(run.get("rest_heals", 0))
		total_turns += int(run.get("turns", 0))
		total_combats += int(run.get("combats", 0))
	for key in ["avg_floor", "avg_step", "avg_hp", "avg_gold", "avg_tickets", "avg_tickets_earned", "avg_relics", "avg_combats", "avg_damage_taken", "avg_busts", "avg_marked_landings", "avg_shop_buys", "avg_rest_heals"]:
		summary[key] = snapped(float(summary[key]) / max(1.0, float(runs.size())), 0.01)
	summary["avg_turns_per_combat"] = snapped(float(total_turns) / max(1.0, float(total_combats)), 0.01)
	for i in range(min(3, runs.size())):
		var run := runs[i]
		(summary["samples"] as Array).append({
			"seed": str(run.get("seed", "")),
			"win": bool(run.get("win", false)),
			"floor": int(run.get("floor", 0)),
			"step": int(run.get("step", 0)),
			"hp": int(run.get("final_hp", 0)),
			"gold": int(run.get("final_gold", 0)),
			"tickets": int(run.get("final_tickets", 0)),
			"relics": int(run.get("relic_count", 0)),
			"route_prefix": (run.get("route", []) as Array).slice(0, 10)
		})
	return summary

func _print_summary(summary: Dictionary) -> void:
	print("BALANCE_SUMMARY " + JSON.stringify(summary))
