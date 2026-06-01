extends SceneTree

const CharacterSelectScene := preload("res://scenes/run/character_select_scene.tscn")
const RunState := preload("res://scripts/resources/run_state.gd")
const CharacterContractCatalog := preload("res://scripts/systems/character_contract_catalog.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const CombatScene := preload("res://scenes/battle/battle_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	_check_character_localization()
	await _check_character_select()
	await _check_double_attack_character_select()
	await _check_black_signer_character_select()
	await _check_encounter_payload_contract()
	await _check_combat_attack_guard_selection()
	await _check_combat_attack_guard_floor_growth()
	await _check_combat_double_attack_selection()
	await _check_black_signer_contract_selection()
	if failures.is_empty():
		print("character contract flow smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_character_localization() -> void:
	TranslationServer.set_locale("en")
	for character_id in CharacterContractCatalog.all_character_ids():
		var character := CharacterContractCatalog.get_character(character_id)
		for key in ["name", "subtitle", "rule_text"]:
			if _contains_korean(str(character.get(key, ""))):
				failures.append("English character " + character_id + " has Korean " + key)
	TranslationServer.set_locale("ko")

func _check_character_select() -> void:
	var scene: Control = CharacterSelectScene.instantiate()
	root.add_child(scene)
	await process_frame
	var button := scene.get("select_button") as Button
	if button == null:
		failures.append("character select should expose confirm button")
	elif button.disabled:
		failures.append("default guard-dice character confirmation should be available")
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	scene._select_character("double_attack_dice")
	await process_frame
	if results.size() != 0:
		failures.append("previewing a character should not start the run")
	if str(scene.get("selected_character_id")) != "double_attack_dice":
		failures.append("previewing double attack should update selected_character_id")
	scene._select_character("black_signer_no_dice")
	await process_frame
	if results.size() != 0:
		failures.append("previewing black signer should not start the run")
	if str(scene.get("selected_character_id")) != "black_signer_no_dice":
		failures.append("previewing black signer should update selected_character_id")
	elif button.disabled:
		failures.append("black signer should be confirmable once combat rule exists")
	scene._select_default_character()
	scene._select_default_character()
	await process_frame
	if results.size() != 1:
		failures.append("character select should emit exactly one result")
	elif str(results[0].get("character_id", "")) != CharacterContractCatalog.default_character_id():
		failures.append("character select emitted wrong character id")
	elif str(results[0].get("dice_rule_id", "")) != "two_dice_attack_guard":
		failures.append("character select emitted wrong dice rule")
	scene.queue_free()
	await process_frame

func _check_double_attack_character_select() -> void:
	var scene: Control = CharacterSelectScene.instantiate()
	root.add_child(scene)
	await process_frame
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	scene._select_character("double_attack_dice")
	scene._confirm_selected_character()
	await process_frame
	if results.size() != 1:
		failures.append("double attack character select should emit exactly one result")
	elif str(results[0].get("character_id", "")) != "double_attack_dice":
		failures.append("double attack character select emitted wrong character id")
	elif str(results[0].get("dice_rule_id", "")) != "two_dice_double_attack":
		failures.append("double attack character select emitted wrong dice rule")
	scene.queue_free()
	await process_frame

func _check_black_signer_character_select() -> void:
	var scene: Control = CharacterSelectScene.instantiate()
	root.add_child(scene)
	await process_frame
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	scene._select_character("black_signer_no_dice")
	scene._confirm_selected_character()
	await process_frame
	if results.size() != 1:
		failures.append("black signer character select should emit exactly one result")
	elif str(results[0].get("character_id", "")) != "black_signer_no_dice":
		failures.append("black signer character select emitted wrong character id")
	elif str(results[0].get("dice_rule_id", "")) != "black_signer_contracts":
		failures.append("black signer character select emitted wrong dice rule")
	scene.queue_free()
	await process_frame

func _check_encounter_payload_contract() -> void:
	var run_state: RunState = RunState.new()
	run_state.character_id = CharacterContractCatalog.default_character_id()
	var payload: Dictionary = EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter("opening_debt"))
	if str(payload.get("character_id", "")) != CharacterContractCatalog.default_character_id():
		failures.append("encounter payload should carry selected character")
	if str(payload.get("dice_rule_id", "")) != "two_dice_attack_guard":
		failures.append("encounter payload should use character dice rule")
	if not (payload.get("relic_ids", []) as Array).has("default_guard_crest"):
		failures.append("default guard encounter payload should include starting crest")

func _check_combat_attack_guard_selection() -> void:
	var run_state: RunState = RunState.new()
	run_state.character_id = CharacterContractCatalog.default_character_id()
	var payload: Dictionary = EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter("opening_debt"))
	var combat: Control = CombatScene.instantiate()
	root.add_child(combat)
	await process_frame
	combat.configure_encounter(payload)
	var forced_dice: Array[int] = [2, 6]
	combat.set("dice", forced_dice)
	combat.set("dice_rolled", true)
	combat._confirm_dice_result()
	await process_frame
	combat._select_attack_die(1)
	await process_frame
	if int(combat.get("attack_base")) != 6:
		failures.append("selected attack die should become attack_base")
	if int(combat.get("player_block")) != 3:
		failures.append("default guard crest and unchosen die should stack into player block")
	if str(combat.get("phase")) != "wager":
		failures.append("selecting confirmed attack/guard dice should continue into wager phase")
	var move_result: Dictionary = combat._resolve_monster_move("hp_strike", 0)
	if int(move_result.get("damage", 0)) > 3:
		failures.append("default guard crest should reduce early monster damage")
	combat.set("player_block", 10)
	combat.set("enemy_hp", 20)
	var counter_result: Dictionary = combat._resolve_monster_move("hp_strike", 0)
	if int(counter_result.get("enemy_hp", 0)) != 16:
		failures.append("default guard crest should counter with remaining block after being attacked")
	if int(counter_result.get("guard_counter_damage", 0)) != 4:
		failures.append("default guard crest should report reflected block damage")
	combat.queue_free()
	await process_frame

func _check_combat_attack_guard_floor_growth() -> void:
	var run_state: RunState = RunState.new()
	run_state.character_id = CharacterContractCatalog.default_character_id()
	run_state.floor_index = 3
	var payload: Dictionary = EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter("opening_debt"))
	var combat: Control = CombatScene.instantiate()
	root.add_child(combat)
	await process_frame
	combat.configure_encounter(payload)
	var forced_dice: Array[int] = [2, 6]
	combat.set("dice", forced_dice)
	combat.set("dice_rolled", true)
	combat._confirm_dice_result()
	await process_frame
	combat._select_attack_die(1)
	await process_frame
	if int(combat.get("player_block")) != 5:
		failures.append("floor 3 default guard crest should add 3 block before unchosen die block")
	combat.queue_free()
	await process_frame

func _check_combat_double_attack_selection() -> void:
	var run_state: RunState = RunState.new()
	run_state.character_id = "double_attack_dice"
	var payload: Dictionary = EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter("opening_debt"))
	if not (payload.get("relic_ids", []) as Array).has("double_attack_crest"):
		failures.append("double attack encounter payload should include starting crest")
	var combat: Control = CombatScene.instantiate()
	root.add_child(combat)
	await process_frame
	combat.configure_encounter(payload)
	var forced_dice: Array[int] = [2, 6]
	combat.set("dice", forced_dice)
	combat.set("dice_rolled", true)
	combat._confirm_dice_result()
	await process_frame
	combat._select_attack_die(1)
	await process_frame
	if int(combat.get("attack_base")) != 8:
		failures.append("double attack should add both dice into attack_base")
	if int(combat.get("player_block")) != 0:
		failures.append("double attack should not add dice guard")
	if str(combat.get("phase")) != "wager":
		failures.append("selecting confirmed double attack dice should continue into wager phase")
	var move_result: Dictionary = combat._resolve_monster_move("hp_strike", 0)
	if int(move_result.get("damage", 0)) < 5:
		failures.append("double attack character should not spend unchosen die as block")
	var healed: Dictionary = EffectResolver.apply_relic_trigger("resolution_after", {
		"damage": 19,
		"player_hp": 20,
		"player_max_hp": 42,
		"applied_effects": []
	}, ["double_attack_crest"])
	if int(healed.get("player_hp", 0)) != 22:
		failures.append("double attack crest should heal 10 percent from 19 damage")
	var jackpot_healed: Dictionary = EffectResolver.apply_relic_trigger("resolution_after", {
		"pending_slot": "jackpot",
		"damage": 19,
		"player_hp": 20,
		"player_max_hp": 42,
		"applied_effects": []
	}, ["double_attack_crest"])
	if int(jackpot_healed.get("player_hp", 0)) != 24:
		failures.append("double attack crest should double lifesteal on jackpot")
	var overheal: Dictionary = EffectResolver.apply_relic_trigger("resolution_after", {
		"pending_slot": "jackpot",
		"damage": 50,
		"player_hp": 40,
		"player_max_hp": 42,
		"relic_state": {},
		"applied_effects": []
	}, ["double_attack_crest"])
	var overheal_state: Dictionary = overheal.get("relic_state", {})
	if int(overheal.get("player_hp", 0)) != 42:
		failures.append("double attack crest should cap jackpot healing at max HP")
	if int(overheal_state.get("double_attack_overheal_block_pending", 0)) != 8:
		failures.append("double attack crest should bank jackpot overheal as next-turn block")
	var carried_block: Dictionary = EffectResolver.apply_relic_trigger("turn_start", {
		"turn": 2,
		"player_block": 0,
		"relic_state": overheal_state,
		"applied_effects": []
	}, ["double_attack_crest"])
	if int(carried_block.get("player_block", 0)) != 8:
		failures.append("double attack crest should convert overheal into block next turn")
	combat.queue_free()
	await process_frame

func _check_black_signer_contract_selection() -> void:
	var run_state: RunState = RunState.new()
	run_state.character_id = "black_signer_no_dice"
	var payload: Dictionary = EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter("opening_debt"))
	if str(payload.get("dice_rule_id", "")) != "black_signer_contracts":
		failures.append("black signer encounter payload should use black signer contract rule")
	var combat: Control = CombatScene.instantiate()
	root.add_child(combat)
	await process_frame
	combat.configure_encounter(payload)
	if str(combat.get("dice_rule_id")) != "black_signer_contracts":
		failures.append("black signer combat should initialize contract rule")
	if int((combat.get("dice") as Array).size()) != 0:
		failures.append("black signer combat should start with no dice")
	combat._select_black_signer_contract("shield")
	await process_frame
	if int(combat.get("attack_base")) != 4:
		failures.append("black signer shield contract should set attack base")
	if int(combat.get("player_block")) != 6:
		failures.append("black signer shield contract should add guard")
	if str(combat.get("phase")) != "wager":
		failures.append("black signer contract selection should continue into wager phase")
	combat.queue_free()
	await process_frame

func _contains_korean(text: String) -> bool:
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if code >= 0xac00 and code <= 0xd7a3:
			return true
	return false
