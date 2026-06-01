extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const RewardScene := preload("res://scenes/run/reward_scene.tscn")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const PotionCatalog := preload("res://scripts/systems/potion_catalog.gd")
const GoStopButtonDriver := preload("res://scripts/tests/support/go_stop_button_driver.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_payload_carries_combat_potions()
	await _check_basic_potion_use()
	await _check_jackpot_bonus_damage()
	await _check_reward_chance_multiplier()
	if failures.is_empty():
		print("potion combat flow smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_payload_carries_combat_potions() -> void:
	var state := {
		"seed_text": "potion-smoke",
		"player_hp": 30,
		"player_max_hp": 42,
		"gold": 0,
		"relic_ids": [],
		"run_upgrades": {},
		"potion_ids": [PotionCatalog.RED_RECOVERY, PotionCatalog.UPGRADE_VOUCHER, "attack_potion"],
		"potion_slots_max": 3
	}
	var payload := EffectResolver.build_encounter_payload(state, {
		"node_type": "combat",
		"monster_id": "debt_collector"
	})
	var potions: Array = payload.get("potion_ids", [])
	if not potions.has(PotionCatalog.RED_RECOVERY):
		failures.append("encounter payload should carry red recovery potion")
	if potions.has(PotionCatalog.UPGRADE_VOUCHER):
		failures.append("encounter payload should not carry non-combat upgrade voucher")
	if not potions.has("attack_potion"):
		failures.append("encounter payload should preserve legacy potion ids for removal")

func _check_basic_potion_use() -> void:
	var combat: Control = await _new_combat([
		PotionCatalog.RED_RECOVERY,
		PotionCatalog.YELLOW_GUARD,
		PotionCatalog.GREEN_REWARD,
		PotionCatalog.WHITE_WAGER,
		PotionCatalog.CYAN_TIME
	])
	combat.set("player_hp", 25)
	combat.set("last_turn_damage_taken", 8)
	combat._use_potion(PotionCatalog.RED_RECOVERY)
	if int(combat.get("player_hp")) != 33:
		failures.append("red potion should restore previous-turn damage")
	combat._use_potion(PotionCatalog.YELLOW_GUARD)
	if int(combat.get("player_block")) != 10:
		failures.append("yellow potion should add 10 block")
	combat._use_potion(PotionCatalog.GREEN_REWARD)
	if abs(float(combat.get("reward_chance_multiplier")) - 2.0) > 0.001:
		failures.append("green potion should set reward chance multiplier to 2")
	combat._finish_dice_roll_with_values([4])
	combat._take_marbles()
	await process_frame
	combat._use_potion(PotionCatalog.WHITE_WAGER)
	if int(combat.get("wager_marbles_available")) != 3:
		failures.append("white potion should add two plain wager marbles")
	combat._use_potion(PotionCatalog.CYAN_TIME)
	if int(combat.get("potion_extra_go_chances")) != 1:
		failures.append("cyan potion should queue one extra Go chance before spin")
	var consumed: Array = combat.get("consumed_potion_ids")
	if consumed.size() != 5:
		failures.append("using five potions should record five consumed ids")
	combat.queue_free()
	for i in range(30):
		await process_frame

func _check_jackpot_bonus_damage() -> void:
	var combat: Control = await _new_combat([PotionCatalog.PURPLE_JACKPOT])
	combat.configure_encounter({
		"combat_core": "numeric_roulette",
		"numeric_forced_indices": [9],
		"combat_cash": 18,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 80,
		"enemy_max_hp": 80,
		"dice_rule_id": "single_attack_die",
		"monster_id": "debt_collector",
		"monster_name": "Debt Collector",
		"move_pattern": ["hp_strike"],
		"potion_ids": [PotionCatalog.PURPLE_JACKPOT]
	})
	await process_frame
	combat._use_potion(PotionCatalog.PURPLE_JACKPOT)
	combat._finish_dice_roll_with_values([4])
	combat._take_marbles()
	await process_frame
	_press_button_by_text(combat, "Go", "purple jackpot wager Go")
	await process_frame
	_press_button_by_text(combat, "Stop", "purple jackpot spin")
	await _wait_for_phase(combat, "intervene", 180)
	if int(combat._numeric_preview_damage()) != 45:
		failures.append("purple potion jackpot preview should be 15 + 30")
	_press_button_by_text(combat, "Stop", "purple jackpot resolve")
	await process_frame
	if int(combat.get("enemy_hp")) != 35:
		failures.append("purple potion jackpot should deal 45 total damage")
	if int(combat.get("jackpot_damage_bonus")) != 0:
		failures.append("purple potion jackpot bonus should be spent after triggering")
	combat.queue_free()
	for i in range(30):
		await process_frame

func _check_reward_chance_multiplier() -> void:
	var reward: Control = RewardScene.instantiate()
	root.add_child(reward)
	reward.configure({
		"run_state": {
			"seed_text": "reward-multiplier",
			"player_hp": 30,
			"player_max_hp": 42
		},
		"combat_result": {
			"encounter_id": "smoke",
			"monster_id": "debt_collector",
			"turn": 2,
			"reward_chance_multiplier": 2.0
		}
	})
	if int(reward._normal_ticket_chance()) != 42:
		failures.append("green potion should double final normal ticket chance from 21 to 42")
	reward.queue_free()
	for i in range(10):
		await process_frame

func _new_combat(potion_ids: Array) -> Control:
	var combat: Control = BattleScene.instantiate()
	root.add_child(combat)
	await process_frame
	combat.configure_encounter({
		"combat_core": "numeric_roulette",
		"combat_cash": 18,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 50,
		"enemy_max_hp": 50,
		"dice_rule_id": "single_attack_die",
		"monster_id": "debt_collector",
		"monster_name": "Debt Collector",
		"move_pattern": ["hp_strike"],
		"potion_ids": potion_ids
	})
	return combat

func _wait_for_phase(combat: Control, wanted: String, frames: int) -> void:
	for i in range(frames):
		if str(combat.get("phase")) == wanted:
			return
		await process_frame

func _press_button_by_text(combat: Control, text: String, context: String) -> void:
	var result: String = GoStopButtonDriver.press_button_by_text(combat, text)
	if result != "":
		failures.append(context + " action " + text + " was " + result)
