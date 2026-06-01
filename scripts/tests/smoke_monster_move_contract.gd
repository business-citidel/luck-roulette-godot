extends SceneTree

const RunStateScript := preload("res://scripts/resources/run_state.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const MonsterCatalog := preload("res://scripts/systems/monster_catalog.gd")
const MonsterMoveCatalog := preload("res://scripts/systems/monster_move_catalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_catalog_shapes()
	_check_monster_localization()
	_check_move_resolution()
	_check_encounter_payloads()

	if failures.is_empty():
		print("monster move contract smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_catalog_shapes() -> void:
	var assigned_moves: Dictionary = {}
	for monster_id in MonsterCatalog.all_runtime_monster_ids():
		var monster: Dictionary = MonsterCatalog.get_monster(monster_id)
		if str(monster.get("id", "")) == "":
			failures.append(monster_id + " missing id")
		if int(monster.get("hp", 0)) <= 0:
			failures.append(monster_id + " missing hp")
		if (monster.get("move_pattern", []) as Array).is_empty():
			failures.append(monster_id + " missing move pattern")
		var role := str(monster.get("pattern_role", ""))
		var read := str(monster.get("pattern_read", ""))
		var tuning: Dictionary = monster.get("pattern_tuning", {})
		if role == "":
			failures.append(monster_id + " missing pattern role")
		if read == "":
			failures.append(monster_id + " missing pattern read")
		if tuning.is_empty():
			failures.append(monster_id + " missing pattern tuning")
		if not _monster_pattern_matches_role(monster, role):
			failures.append(monster_id + " pattern does not express role " + role)
		for move_id in monster.get("move_pattern", []):
			var move_key := str(move_id)
			assigned_moves[move_key] = true
			if not MonsterMoveCatalog.has_move(move_key):
				failures.append(monster_id + " references missing move " + move_key)
			if str(MonsterMoveCatalog.intent_text(move_key)) == "":
				failures.append(monster_id + " move has empty intent text " + move_key)

	for move_id in [
		"hp_strike",
		"heavy_hp_strike",
		"guarded_stance",
		"guarded_strike",
		"sharpen_odds",
		"count_up",
		"weak_receipt",
		"marked_stamp",
		"tax_collection",
		"skim_payout",
		"blind_call",
		"misdeal_jab",
		"roulette_audit",
		"dice_appraisal",
		"guard_tithe"
	]:
		if not MonsterMoveCatalog.has_move(move_id):
			failures.append("required move id missing " + move_id)
		elif str(MonsterMoveCatalog.intent_text(move_id)) == "":
			failures.append("required move has empty intent text " + move_id)
		elif not assigned_moves.has(move_id):
			failures.append("required move is not assigned to any monster " + move_id)

	for monster_id in [
		"mug_brawler",
		"chip_stack_bruiser",
		"brass_lockbox",
		"candle_counter",
		"ashtray_curse",
		"coin_shark",
		"wheel_jammer",
		"bell_ringer",
		"blacklist_notary",
		"the_red_seal"
	]:
		if not MonsterCatalog.has_monster(monster_id):
			failures.append("minimal runtime pilot monster missing " + monster_id)

	var floor_two_pool: Array[String] = MonsterCatalog.normal_pool_for_floor(2)
	for monster_id in ["debt_collector", "table_crook", "loaded_dice_runner", "house_errand", "backroom_bookie", "chip_stack_bruiser"]:
		if not floor_two_pool.has(monster_id):
			failures.append("floor two pool missing " + monster_id)
	for monster_id in ["ashtray_curse", "wheel_jammer"]:
		if not floor_two_pool.has(monster_id):
			failures.append("floor two pool missing pilot " + monster_id)

func _check_monster_localization() -> void:
	TranslationServer.set_locale("ko")
	for monster_id in MonsterCatalog.all_runtime_monster_ids():
		if not _contains_korean(str(MonsterCatalog.get_monster(monster_id).get("name", ""))):
			failures.append(monster_id + " needs Korean monster name")
	TranslationServer.set_locale("en")
	for monster_id in MonsterCatalog.all_runtime_monster_ids():
		if _contains_korean(str(MonsterCatalog.get_monster(monster_id).get("name", ""))):
			failures.append(monster_id + " English monster name contains Korean")
	TranslationServer.set_locale("ko")

func _check_move_resolution() -> void:
	var strike: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("hp_strike", {
		"player_hp": 30,
		"cash": 18
	}, 2)
	if int(strike.get("damage", 0)) != 5 or int(strike.get("player_hp", 0)) != 25:
		failures.append("hp_strike did not apply reduced HP damage")

	var sharp: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("heavy_hp_strike", {
		"player_hp": 30,
		"enemy_damage_delta": 2,
		"cash": 18
	}, 0)
	if int(sharp.get("damage", 0)) != 13 or int(sharp.get("player_hp", 0)) != 17:
		failures.append("heavy_hp_strike did not apply direct damage delta")
	if int(sharp.get("enemy_damage_delta", 1)) != 0:
		failures.append("enemy damage delta should be consumed after enemy action")

	var guard: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("guarded_stance", {
		"player_hp": 30,
		"enemy_block": 1,
		"cash": 18
	}, 0)
	if int(guard.get("damage", -1)) != 0 or int(guard.get("enemy_block", 0)) <= 1:
		failures.append("guarded_stance should add enemy block without HP damage")

	var buff: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("sharpen_odds", {
		"player_hp": 30,
		"enemy_damage_delta": 1,
		"cash": 18
	}, 0)
	if int(buff.get("damage", -1)) != 0 or int(buff.get("enemy_damage_delta", 0)) != 3:
		failures.append("sharpen_odds should ramp future enemy damage")

	var tax: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("tax_collection", {
		"player_hp": 30,
		"cash": 10,
		"run_gold": 9
	}, 0)
	if int(tax.get("run_gold", 0)) != 5 or int(tax.get("gold_delta", 0)) != -4 or int(tax.get("cash", 0)) != 10:
		failures.append("tax_collection should reduce run gold, not combat cash")

	var empty_tax: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("tax_collection", {
		"player_hp": 30,
		"cash": 10,
		"run_gold": 0
	}, 0)
	if int(empty_tax.get("gold_delta", 99)) != 0 or int(empty_tax.get("run_gold", 99)) != 0:
		failures.append("tax_collection should not create negative gold when the purse is empty")

	var weak: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("weak_receipt", {
		"player_hp": 30,
		"cash": 10
	}, 0)
	if float(weak.get("player_damage_multiplier", 1.0)) >= 1.0:
		failures.append("weak_receipt should halve next final damage")

	var mark: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("marked_stamp", {
		"player_hp": 30,
		"cash": 10
	}, 0)
	if float(mark.get("enemy_damage_multiplier", 1.0)) <= 1.0:
		failures.append("marked_stamp should double the next incoming hit")

	var blind: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("blind_call", {
		"player_hp": 30,
		"cash": 10
	}, 0)
	if int(blind.get("hidden_intent_turns", 0)) != 1:
		failures.append("blind_call should hide the next intent")

func _check_encounter_payloads() -> void:
	var run_state: Resource = RunStateScript.new()
	run_state.player_hp = 39
	run_state.player_max_hp = 42

	var normal_payload: Dictionary = EffectResolver.build_encounter_payload(run_state, {
		"node_id": "n0",
		"node_type": "combat",
		"node_index": 0
	})
	if str(normal_payload.get("monster_id", "")) != "debt_collector":
		failures.append("normal encounter did not select debt_collector")
	if (normal_payload.get("move_pattern", []) as Array).is_empty():
		failures.append("normal encounter lacks move_pattern")
	if str(normal_payload.get("monster_pattern_role", "")) == "" or str(normal_payload.get("monster_pattern_read", "")) == "":
		failures.append("normal encounter lacks monster pattern metadata")
	if (normal_payload.get("monster_pattern_tuning", {}) as Dictionary).is_empty():
		failures.append("normal encounter lacks monster pattern tuning")

	var elite_payload: Dictionary = EffectResolver.build_encounter_payload(run_state, {
		"node_id": "n1e",
		"node_type": "elite",
		"node_index": 1
	})
	if str(elite_payload.get("monster_id", "")) != "elite_house":
		failures.append("elite encounter did not select elite_house")
	if int(elite_payload.get("enemy_hp", 0)) <= int(normal_payload.get("enemy_hp", 0)):
		failures.append("elite encounter is not stronger than normal")
	if str(elite_payload.get("monster_pattern_role", "")) == "" or str(elite_payload.get("monster_pattern_read", "")) == "":
		failures.append("elite encounter lacks monster pattern metadata")
	if (elite_payload.get("monster_pattern_tuning", {}) as Dictionary).is_empty():
		failures.append("elite encounter lacks monster pattern tuning")
	var elite_tuning: Dictionary = elite_payload.get("monster_pattern_tuning", {})
	if int(elite_tuning.get("attack_damage", 0)) < 9 or int(elite_tuning.get("heavy_damage", 0)) < 17:
		failures.append("elite encounter tuning did not apply difficulty damage bump")

	var brawler_tuning := MonsterCatalog.pattern_tuning("mug_brawler")
	var brawler_strike: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("hp_strike", {
		"player_hp": 30,
		"cash": 18,
		"pattern_tuning": brawler_tuning
	}, 0)
	if int(brawler_strike.get("damage", 0)) != int(brawler_tuning.get("attack_damage", 0)):
		failures.append("monster tuning should override base attack damage")

	var boss_payload: Dictionary = EffectResolver.build_encounter_payload(run_state, {
		"node_id": "boss",
		"node_type": "boss",
		"node_index": 6
	})
	if str(boss_payload.get("monster_id", "")) != "final_house":
		failures.append("boss encounter did not use final_house catalog entry")
	if (boss_payload.get("move_pattern", []) as Array).size() < 4:
		failures.append("boss encounter pattern is too short to prove shared structure")

func _contains_korean(text: String) -> bool:
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if code >= 0xac00 and code <= 0xd7a3:
			return true
	return false

func _monster_pattern_matches_role(monster: Dictionary, role: String) -> bool:
	if role == "":
		return false
	for move_id in monster.get("move_pattern", []):
		var move := MonsterMoveCatalog.get_move(str(move_id))
		var intent := str(move.get("intent", ""))
		var tags: Array = move.get("tags", [])
		if intent == role or intent.contains(role) or tags.has(role):
			return true
		if role == "heavy_attack" and str(move_id) == "heavy_hp_strike":
			return true
	return false
