extends Control

signal combat_finished(result: Dictionary)
signal combat_overlay_changed(payload: Dictionary)

const MarbleResolver := preload("res://scripts/systems/marble_resolver.gd")
const MarbleDeckState := preload("res://scripts/resources/marble_deck_state.gd")
const MarbleEffectResolver := preload("res://scripts/systems/marble_effect_resolver.gd")
const RouletteResolver := preload("res://scripts/systems/roulette_resolver.gd")
const RouletteSlotCatalog := preload("res://scripts/systems/roulette_slot_catalog.gd")
const NumericRouletteResolver := preload("res://scripts/systems/numeric_roulette_resolver.gd")
const PayoutResolver := preload("res://scripts/systems/payout_resolver.gd")
const DiceResolver := preload("res://scripts/systems/dice_resolver.gd")
const DicePushResolver := preload("res://scripts/systems/dice_push_resolver.gd")
const EnemyIntentResolver := preload("res://scripts/systems/enemy_intent_resolver.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const MonsterMoveCatalog := preload("res://scripts/systems/monster_move_catalog.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const PotionCatalog := preload("res://scripts/systems/potion_catalog.gd")
const AudioBankScript := preload("res://scripts/systems/audio_bank.gd")
const PromptLayerScript := preload("res://scripts/ui/prompt_layer.gd")
const FeedbackLayerScript := preload("res://scripts/ui/feedback_layer.gd")
const TableLayerScript := preload("res://scripts/ui/table_layer.gd")
const HandLayerScript := preload("res://scripts/ui/hand_layer.gd")
const DiceRollLayer2DScript := preload("res://scripts/ui/dice_roll_layer_2d.gd")
const DiceCupRollLayer3DScript := preload("res://scripts/ui/dice_cup_roll_layer_3d.gd")
const RunHudScript := preload("res://scripts/ui/run_hud.gd")
const OpponentLayerScript := preload("res://scripts/ui/opponent_layer.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")
const CombatCameraRigScript := preload("res://scripts/camera/combat_camera_rig.gd")
const RitualDirectorScript := preload("res://scripts/systems/ritual_director.gd")
const ActionPresenter := preload("res://scripts/battle/battle_action_presenter.gd")
const PromptPresenter := preload("res://scripts/battle/battle_prompt_presenter.gd")
const AttackDieHandoff := preload("res://scripts/battle/battle_attack_die_handoff.gd")
const DiceFlow := preload("res://scripts/battle/battle_dice_flow.gd")
const DiceRollHandoff := preload("res://scripts/battle/battle_dice_roll_handoff.gd")
const LegacySlotFlow := preload("res://scripts/battle/battle_legacy_slot_flow.gd")
const NumericRouletteFlow := preload("res://scripts/battle/battle_numeric_roulette_flow.gd")
const MarbleChoiceFlow := preload("res://scripts/battle/battle_marble_choice_flow.gd")
const RelicBridge := preload("res://scripts/battle/battle_relic_payload_bridge.gd")
const CombatResultBuilder := preload("res://scripts/battle/battle_combat_result_builder.gd")
const VisualFeedback := preload("res://scripts/battle/battle_visual_feedback.gd")
const VisualSnapshots := preload("res://scripts/battle/battle_visual_layer_snapshots.gd")
const VisualDecay := preload("res://scripts/battle/battle_visual_decay.gd")
const ResolutionOutcomeFlow := preload("res://scripts/battle/battle_resolution_outcome_flow.gd")
const RuntimeBridge := preload("res://scripts/runtime/systems/game_object_runtime_bridge.gd")
const CombatResolutionBeatScene := preload("res://scenes/rituals/combat_resolution_beat.tscn")
const EnemyIntentBeatScene := preload("res://scenes/rituals/enemy_intent_beat.tscn")

const BG := Color("#07090f")
const PANEL := Color("#101720")
const PANEL_2 := Color("#182331")
const LINE := Color("#495569")
const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const YELLOW := Color("#f4da63")
const GREEN := Color("#65d48e")
const PURPLE := Color("#a879ef")
const RED := Color("#ee5b5b")
const BLUE := Color("#66a8ff")
const HOARDED_WAGER_PRESSURE_CAP := 3

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var seed_text: String = ""
var floor_index: int = 1
var use_dice_cup_layer_3d: bool = false

var phase: String = "dice"
var turn: int = 1
var cash: int = 18
var banked: int = 0
var run_gold: int = 0
var gold_delta: int = 0
var enemy_damage_delta: int = 0
var enemy_damage_multiplier: float = 1.0
var enemy_block: int = 0
var player_attack_delta: int = 0
var player_damage_multiplier: float = 1.0
var enemy_intent_hidden_turns: int = 0
var busts: int = 0

var player_hp: int = 42
var player_max_hp: int = 42
var enemy_hp: int = 92
var enemy_max_hp: int = 92
var enemy_intent: String = UiText.t("battle.intent.damage", {"amount": 7})
var monster_id: String = "debt_collector"
var monster_name: String = "Debt Collector"
var monster_tier: String = "normal"
var monster_pattern_tuning: Dictionary = {}
var move_pattern: Array[String] = ["hp_strike"]
var current_move_id: String = "hp_strike"

var dice_rule_id: String = "single_attack_die"
var dice: Array[int] = [1]
var dice_locked: Array[bool] = [false]
var dice_rolled: bool = false
var dice_relics_applied: bool = false
var rerolls_left: int = 2
var attack_base: int = 0
var selected_attack_die_index: int = -1
var guard_value: int = 0
var player_block: int = 0
var dice_role_selecting: bool = false
var black_signer_debt: int = 0
var black_signer_contract_id: String = ""

var marbles: Array[String] = []
var stored: Array[String] = []
var placed_slots: Dictionary = {}
var selected_marble_slot_id: String = "safe"
var marble_deck_state: Resource = MarbleDeckState.new()
var revealed_marbles: Array[Dictionary] = []
var selected_marble: Dictionary = {}
var selected_marble_id: String = ""
var hovered_marble_choice_index: int = -1
var combat_core: String = "numeric_roulette"
var wager_marbles_available: int = 1
var wager_marbles_committed: int = 0
var numeric_roulette_index: int = -1
var numeric_roulette_multiplier: float = 1.0
var numeric_go_available: bool = false
var numeric_next_go_available: bool = true
var numeric_go_chances_left: int = 1
var numeric_go_per_turn_cap: int = 999
var numeric_pending_intervention_message: String = ""
var numeric_forced_indices: Array[int] = []
var numeric_go_used_this_spin: bool = false
var last_attack_base: int = 0
var last_roulette_multiplier: float = 1.0
var last_wager_marbles_committed: int = 0
var last_roulette_go_used: bool = false
var active_potion_ids: Array[String] = []
var consumed_potion_ids: Array[String] = []
var potion_menu_open: bool = false
var last_turn_damage_taken: int = 0
var reward_chance_multiplier: float = 1.0
var jackpot_damage_bonus: int = 0
var jackpot_bonus_spent: bool = false
var potion_extra_go_chances: int = 0

var throwing_hand: bool = false
var hand_start_pos: Vector2 = Vector2.ZERO
var hand_pos: Vector2 = Vector2.ZERO
var hand_shake: float = 0.0
var hand_velocity: Vector2 = Vector2.ZERO
var hand_marble_preview: Array[String] = []
var thrown_marbles: Array = []

var wheel_angle: float = -90.0
var pending_slot: String = ""
var payout_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var spin_locked: bool = false
var run_over: bool = false
var embedded_encounter: bool = false
var combat_result_emitted: bool = false
var active_relic_ids: Array[String] = []
var active_run_upgrades: Dictionary = {}
var active_relic_state: Dictionary = {}
var last_encounter_payload: Dictionary = {}
var last_applied_effects: Array = []
var roulette_respins_left: int = 0

var message: String = UiText.t("battle.message.initial")
var banner_text: String = "DICE TIME"
var banner_alpha: float = 0.0
var enemy_flash: float = 0.0
var player_flash: float = 0.0
var table_pulse: float = 0.0
var dice_roll_fx: float = 0.0
var dice_roll_in_progress: bool = false
var dice_roll_is_reroll: bool = false
var dice_roll_is_push: bool = false
var dice_push_count: int = 0
var dice_push_current_total: int = 0
var dice_push_attack_base: int = 0
var dice_push_active: bool = false
var dice_push_failed: bool = false
var dice_push_locked: bool = false
var dice_push_pending_total: int = 0
var dice_push_history: Array = []
var dice_result_feedback_token: int = 0
var hovered_attack_die_index: int = -1
var hovered_slot_id: String = ""
var hovered_spin_wheel: bool = false
var marble_feedback_pos: Vector2 = Vector2.ZERO
var marble_feedback_color: Color = Color.WHITE
var marble_feedback_alpha: float = 0.0
var slot_feedback_id: String = ""
var slot_feedback_alpha: float = 0.0
var wheel_tick_segment: int = -1
var wheel_tick_flash: float = 0.0
var wheel_pointer_kick: float = 0.0
var table_hit_flash: float = 0.0
var opponent_reaction: float = 0.0
var opponent_mood: String = "watching"
var coin_particles: Array = []
var spin_ready_flash: float = 0.0

var audio_bank: Node
var world_root: Node2D
var hud_canvas: CanvasLayer
var camera_rig: Node
var table_layer: Control
var hand_layer: Control
var dice_roll_layer: Control
var dice_cup_roll_layer: Control
var run_hud: Control
var opponent_layer: Control
var prompt_layer: Control
var feedback_layer: Control
var object_input_layer: Control
var ritual_director: Node

func _ready() -> void:
	seed_text = _seed_from_args()
	rng.seed = hash(seed_text)
	marble_deck_state.reset_starting_deck(rng)
	_reset_slots()
	_build_shell()
	_build_audio_bank()
	_render()

func configure_encounter(payload: Dictionary) -> void:
	last_encounter_payload = payload.duplicate(true)
	active_relic_ids = _string_array(payload.get("relic_ids", []))
	active_run_upgrades = _upgrade_dict(payload.get("run_upgrades", {}))
	active_relic_state = {}
	last_applied_effects = []
	embedded_encounter = true
	combat_result_emitted = false
	turn = 1
	phase = "dice"
	combat_core = str(payload.get("combat_core", "numeric_roulette"))
	floor_index = max(1, int(payload.get("floor_index", 1)))
	wager_marbles_available = int(payload.get("wager_marbles_available", 1 if _is_numeric_core() else 0))
	wager_marbles_committed = 0
	marble_deck_state.reset_starting_deck(rng)
	revealed_marbles.clear()
	selected_marble.clear()
	selected_marble_id = ""
	hovered_marble_choice_index = -1
	numeric_roulette_index = -1
	numeric_roulette_multiplier = 1.0
	numeric_go_available = false
	numeric_next_go_available = true
	numeric_go_chances_left = 1
	numeric_go_per_turn_cap = 999
	numeric_pending_intervention_message = ""
	numeric_forced_indices = _int_array(payload.get("numeric_forced_indices", []))
	numeric_go_used_this_spin = false
	last_attack_base = 0
	last_roulette_multiplier = 1.0
	last_wager_marbles_committed = 0
	last_roulette_go_used = false
	active_potion_ids = _combat_potion_ids(payload.get("potion_ids", []))
	consumed_potion_ids.clear()
	potion_menu_open = false
	last_turn_damage_taken = 0
	reward_chance_multiplier = 1.0
	jackpot_damage_bonus = 0
	jackpot_bonus_spent = false
	potion_extra_go_chances = 0
	cash = int(payload.get("combat_cash", 18))
	banked = 0
	run_gold = int(payload.get("run_gold", payload.get("gold", 0)))
	gold_delta = 0
	enemy_damage_delta = int(payload.get("enemy_damage_delta", 0))
	enemy_damage_multiplier = float(payload.get("enemy_damage_multiplier", 1.0))
	enemy_block = int(payload.get("enemy_block", 0))
	player_attack_delta = int(payload.get("player_attack_delta", 0))
	player_damage_multiplier = float(payload.get("player_damage_multiplier", 1.0))
	enemy_intent_hidden_turns = int(payload.get("hidden_intent_turns", 0))
	busts = 0
	player_hp = int(payload.get("player_hp", player_hp))
	player_max_hp = int(payload.get("player_max_hp", player_max_hp))
	enemy_hp = int(payload.get("enemy_hp", enemy_hp))
	enemy_max_hp = int(payload.get("enemy_max_hp", max(enemy_hp, enemy_max_hp)))
	monster_id = str(payload.get("monster_id", monster_id))
	monster_name = str(payload.get("monster_name", monster_name))
	monster_tier = str(payload.get("monster_tier", monster_tier))
	monster_pattern_tuning = _upgrade_dict(payload.get("monster_pattern_tuning", payload.get("pattern_tuning", {})))
	move_pattern = _string_array(payload.get("move_pattern", move_pattern))
	if move_pattern.is_empty():
		move_pattern = ["hp_strike"]
	current_move_id = str(payload.get("current_move_id", MonsterMoveCatalog.move_for_turn(move_pattern, turn)))
	enemy_intent = str(payload.get("enemy_intent", MonsterMoveCatalog.intent_text(current_move_id, monster_pattern_tuning)))
	dice_rule_id = str(payload.get("dice_rule_id", DiceResolver.default_rule_id()))
	dice = DiceResolver.starting_values(dice_rule_id)
	dice_locked = DiceResolver.starting_locks(dice_rule_id)
	dice_rolled = false
	dice_relics_applied = false
	rerolls_left = int(DiceResolver.rule(dice_rule_id).get("rerolls", 2)) + int(payload.get("rerolls_left_delta", 0))
	attack_base = 0
	selected_attack_die_index = -1
	guard_value = 0
	player_block = int(payload.get("player_block", 0))
	black_signer_debt = 0
	black_signer_contract_id = ""
	dice_role_selecting = false
	marbles.clear()
	stored.clear()
	thrown_marbles.clear()
	hand_marble_preview.clear()
	throwing_hand = false
	selected_marble_slot_id = RouletteSlotCatalog.fallback_id()
	pending_slot = ""
	payout_multiplier = 1.0
	damage_multiplier = 1.0
	roulette_respins_left = 0
	spin_locked = false
	run_over = false
	opponent_mood = "watching"
	message = UiText.t("battle.message.encounter")
	if active_relic_ids.size() > 0:
		message += UiText.t("battle.message.relics", {"relics": RelicCatalog.display_names(active_relic_ids, 2)})
	message += UiText.t("battle.message.opponent", {"monster": monster_name})
	var applied_effects: Array = payload.get("applied_effects", [])
	if not applied_effects.is_empty():
		message += UiText.t("battle.message.start_mods", {"count": applied_effects.size()})
	banner_text = "ENCOUNTER"
	banner_alpha = 0.8
	_reset_slots()
	var turn_effects := _apply_turn_start_relics()
	if prompt_layer != null:
		_render()
		_show_feedback_from_effects(applied_effects, "encounter")
		_show_feedback_from_effects(turn_effects, "turn_start")

func _process(delta: float) -> void:
	var dirty: bool = false
	var decay_patch := VisualDecay.state_patch(_visual_decay_snapshot(), delta)
	if bool(decay_patch.get("dirty", false)):
		_apply_visual_decay_patch(decay_patch)
		dirty = true
	if not coin_particles.is_empty():
		_update_coin_particles(delta)
		dirty = true
	if not thrown_marbles.is_empty():
		_update_thrown_marbles(delta)
		dirty = true
	if throwing_hand or spin_locked:
		dirty = true
	if spin_locked:
		_update_wheel_tick()
	if dirty:
		_update_visual_layers()
		queue_redraw()

func _visual_decay_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for field in VisualDecay.decay_fields():
		snapshot[field] = get(field)
	return snapshot

func _apply_visual_decay_patch(patch: Dictionary) -> void:
	for key in patch.keys():
		if str(key) == "dirty":
			continue
		set(str(key), patch[key])

func _gui_input(event: InputEvent) -> void:
	if ritual_director != null and ritual_director.has_method("is_ritual_active") and ritual_director.is_ritual_active():
		return
	if dice_roll_in_progress:
		return
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if throwing_hand:
			var table_pos: Vector2 = _screen_to_world_pos(motion.position)
			hand_velocity = table_pos - hand_pos
			hand_pos = table_pos
			hand_shake += motion.relative.length()
			_update_visual_layers()
			queue_redraw()
		else:
			if _update_object_hover(_screen_to_world_pos(motion.position), motion.position):
				_update_visual_layers()
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		var table_pos: Vector2 = _screen_to_world_pos(mouse.position)
		if mouse.pressed:
			if phase == "dice" and dice_rolled:
				if not _try_toggle_die(table_pos):
					_try_toggle_die(mouse.position)
			elif phase == "marble":
				var slot_id: String = _slot_at(table_pos)
				if slot_id != "" and not marbles.is_empty():
					_place_marbles_on_slot(slot_id)
				elif _hand_rect().has_point(table_pos) and not marbles.is_empty():
					_open_marble_throw_ritual()
				elif _marble_setup_ready() and _roulette_spin_rect().has_point(table_pos):
					_open_roulette_spin_ritual()
		else:
			if throwing_hand:
				_release_hand_throw(table_pos)

func _unhandled_key_input(event: InputEvent) -> void:
	if ritual_director != null and ritual_director.has_method("is_ritual_active") and ritual_director.is_ritual_active():
		return
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if phase == "wager":
		if _is_wager_increase_key(key_event):
			_adjust_wager(1)
			get_viewport().set_input_as_handled()
			return
		if _is_wager_decrease_key(key_event):
			_adjust_wager(-1)
			get_viewport().set_input_as_handled()
			return
	if phase == "marble" and not marbles.is_empty() and not throwing_hand and thrown_marbles.is_empty():
		var slot_id: String = _slot_id_for_key(key_event)
		if slot_id != "":
			_place_marbles_on_slot(slot_id)
			get_viewport().set_input_as_handled()

func _is_wager_increase_key(key_event: InputEventKey) -> bool:
	var keys: Array[Key] = [KEY_PLUS, KEY_EQUAL, KEY_KP_ADD]
	return keys.has(key_event.keycode) or keys.has(key_event.physical_keycode)

func _is_wager_decrease_key(key_event: InputEventKey) -> bool:
	var keys: Array[Key] = [KEY_MINUS, KEY_KP_SUBTRACT]
	return keys.has(key_event.keycode) or keys.has(key_event.physical_keycode)

func _seed_from_args() -> String:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--seed="):
			return arg.replace("--seed=", "")
	return "external-wheel-combat-v2-2026-05-09"

func _build_shell() -> void:
	world_root = Node2D.new()
	world_root.name = "WorldRoot"
	add_child(world_root)

	hud_canvas = CanvasLayer.new()
	hud_canvas.name = "HudCanvas"
	hud_canvas.layer = 20
	add_child(hud_canvas)

	camera_rig = CombatCameraRigScript.new()
	camera_rig.name = "CombatCameraRig"
	add_child(camera_rig)

	table_layer = TableLayerScript.new()
	world_root.add_child(table_layer)
	hand_layer = HandLayerScript.new()
	world_root.add_child(hand_layer)
	dice_roll_layer = DiceRollLayer2DScript.new()
	dice_roll_layer.roll_finished.connect(_on_dice_roll_finished)
	hud_canvas.add_child(dice_roll_layer)
	dice_cup_roll_layer = DiceCupRollLayer3DScript.new()
	dice_cup_roll_layer.roll_finished.connect(_on_dice_cup_roll_finished)
	hud_canvas.add_child(dice_cup_roll_layer)
	run_hud = RunHudScript.new()
	hud_canvas.add_child(run_hud)
	opponent_layer = OpponentLayerScript.new()
	world_root.add_child(opponent_layer)
	prompt_layer = PromptLayerScript.new()
	hud_canvas.add_child(prompt_layer)
	object_input_layer = Control.new()
	object_input_layer.name = "ObjectInputLayer"
	object_input_layer.size = Vector2(1280, 720)
	object_input_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_canvas.add_child(object_input_layer)
	feedback_layer = FeedbackLayerScript.new()
	hud_canvas.add_child(feedback_layer)
	ritual_director = RitualDirectorScript.new()
	ritual_director.name = "RitualDirector"
	add_child(ritual_director)

func _build_audio_bank() -> void:
	audio_bank = AudioBankScript.new()
	add_child(audio_bank)

func _play_sfx(key: String, pitch: float = 1.0, volume_db: float = -6.0) -> void:
	if audio_bank != null:
		audio_bank.play_sfx(key, pitch, volume_db)

func _show_feedback_from_effects(applied_effects: Array, context: String) -> void:
	var events: Array[Dictionary] = VisualFeedback.events_from_effects(applied_effects, context)
	if events.is_empty():
		return
	_emit_relic_trigger_overlay(events)
	if feedback_layer != null and feedback_layer.has_method("show_events"):
		feedback_layer.show_events(events)
	for event in events:
		_apply_feedback_cue_patch(VisualFeedback.cue_patch(event))
		_play_feedback_audio_cue(VisualFeedback.audio_cue(event))
	_update_visual_layers()
	queue_redraw()

func _emit_relic_trigger_overlay(events: Array[Dictionary]) -> void:
	var triggered_ids: Array[String] = VisualFeedback.triggered_relic_ids(events)
	if triggered_ids.is_empty():
		return
	var payload := _overlay_payload()
	payload["triggered_relic_ids"] = triggered_ids
	combat_overlay_changed.emit(payload)

func _apply_feedback_cue_patch(patch: Dictionary) -> void:
	if patch.has("dice_roll_fx"):
		dice_roll_fx = max(dice_roll_fx, float(patch.get("dice_roll_fx", 0.0)))
	if patch.has("table_pulse"):
		table_pulse = max(table_pulse, float(patch.get("table_pulse", 0.0)))
	if patch.has("wheel_tick_flash"):
		wheel_tick_flash = max(wheel_tick_flash, float(patch.get("wheel_tick_flash", 0.0)))
	if patch.has("wheel_pointer_kick"):
		wheel_pointer_kick = max(wheel_pointer_kick, float(patch.get("wheel_pointer_kick", 0.0)))
	if patch.has("table_hit_flash"):
		table_hit_flash = max(table_hit_flash, float(patch.get("table_hit_flash", 0.0)))
	if patch.has("player_flash"):
		player_flash = max(player_flash, float(patch.get("player_flash", 0.0)))
	if patch.has("enemy_flash"):
		enemy_flash = max(enemy_flash, float(patch.get("enemy_flash", 0.0)))
	if patch.has("opponent_reaction"):
		opponent_reaction = max(opponent_reaction, float(patch.get("opponent_reaction", 0.0)))
	if patch.has("opponent_mood"):
		opponent_mood = str(patch.get("opponent_mood", opponent_mood))
	var coin_burst := int(patch.get("coin_burst", 0))
	var requires_cash := bool(patch.get("coin_burst_requires_cash", false))
	if coin_burst > 0 and (not requires_cash or int(cash) > 0):
		_spawn_coin_burst(coin_burst)

func _play_feedback_audio_cue(cue: Dictionary) -> void:
	var key := str(cue.get("key", ""))
	if key == "":
		return
	_play_sfx(key, float(cue.get("pitch", 1.0)), float(cue.get("volume_db", -6.0)))

func _render() -> void:
	_update_visual_layers()
	prompt_layer.clear()
	_clear_object_inputs()
	queue_redraw()
	_render_labels()
	_render_buttons()
	_render_object_inputs()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)

func _render_labels() -> void:
	var prompt := _action_prompt()
	if prompt == "":
		return
	_label(prompt, Vector2(342, 500), Vector2(596, 24), 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER)

func _update_visual_layers() -> void:
	_update_table_layer()
	_update_hand_layer()
	_update_run_hud()
	_update_opponent_layer()
	prompt_layer.set_banner(banner_text, banner_alpha)
	_update_camera_beat()

func _update_table_layer() -> void:
	table_layer.set_state(VisualSnapshots.table_state(_visual_layer_snapshot({
		"table_pulse": table_pulse,
		"table_hit_flash": table_hit_flash,
		"wheel_angle": wheel_angle,
		"wheel_tick_flash": wheel_tick_flash,
		"wheel_pointer_kick": wheel_pointer_kick,
		"placed_slots": placed_slots,
		"pending_slot": pending_slot,
		"slot_feedback_id": slot_feedback_id,
		"slot_feedback_alpha": slot_feedback_alpha,
		"spin_ready_flash": spin_ready_flash,
		"hovered_slot_id": hovered_slot_id,
		"hovered_spin_wheel": hovered_spin_wheel,
		"coin_particles": coin_particles,
			"numeric_roulette_index": numeric_roulette_index,
			"numeric_roulette_multiplier": numeric_roulette_multiplier,
			"wager_marbles_available": wager_marbles_available,
			"wager_marbles_committed": wager_marbles_committed,
			"revealed_marbles": revealed_marbles,
			"selected_marble": selected_marble,
			"hovered_marble_choice_index": hovered_marble_choice_index,
			"marble_zone_counts": marble_deck_state.zone_counts(),
			"is_numeric_core": _is_numeric_core(),
			"marble_setup_ready": _marble_setup_ready()
		})))

func _update_hand_layer() -> void:
	hand_layer.set_state(VisualSnapshots.hand_state(_visual_layer_snapshot({
		"dice": dice,
		"dice_locked": dice_locked,
		"dice_rolled": dice_rolled,
		"rerolls_left": rerolls_left,
		"attack_base": attack_base,
		"selected_attack_die_index": selected_attack_die_index,
		"guard_value": guard_value,
		"player_block": player_block,
		"hovered_attack_die_index": hovered_attack_die_index,
		"dice_roll_fx": dice_roll_fx,
		"dice_roll_in_progress": dice_roll_in_progress,
		"marbles": marbles,
		"stored": stored,
		"throwing_hand": throwing_hand,
		"hand_start_pos": hand_start_pos,
		"hand_pos": hand_pos,
		"hand_shake": hand_shake,
		"hand_velocity": hand_velocity,
		"hand_marble_preview": hand_marble_preview,
		"thrown_marbles": thrown_marbles,
		"marble_feedback_pos": marble_feedback_pos,
		"marble_feedback_color": marble_feedback_color,
		"marble_feedback_alpha": marble_feedback_alpha
	})))

func _update_run_hud() -> void:
	run_hud.set_state(VisualSnapshots.run_hud_state(_visual_layer_snapshot({
		"seed_text": seed_text,
		"turn": turn,
		"floor_index": floor_index,
		"cash": cash,
		"run_gold": run_gold,
		"gold_delta": gold_delta,
		"banked": banked,
		"busts": busts,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"enemy_hp": enemy_hp,
		"enemy_max_hp": enemy_max_hp,
		"player_block": player_block,
		"monster_id": monster_id,
		"monster_name": monster_name,
		"active_relic_ids": active_relic_ids,
		"active_potion_ids": active_potion_ids.duplicate(),
		"potion_slots_max": int(last_encounter_payload.get("potion_slots_max", 2)),
		"active_prep_mods": last_encounter_payload.get("next_combat_mods", [])
	})))
	combat_overlay_changed.emit(_overlay_payload())

func _overlay_payload() -> Dictionary:
	return VisualSnapshots.overlay_payload(_visual_layer_snapshot({
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"active_relic_ids": active_relic_ids,
		"active_potion_ids": active_potion_ids,
		"potion_slots_max": int(last_encounter_payload.get("potion_slots_max", 2)),
		"player_block": player_block
	}))

func _apply_dice_run_upgrades(result: Dictionary) -> Dictionary:
	return DiceFlow.apply_run_upgrades(result, dice_rule_id, active_run_upgrades)

func _is_attack_guard_rule() -> bool:
	return DiceFlow.is_attack_guard_rule(dice_rule_id)

func _is_double_attack_rule() -> bool:
	return DiceFlow.is_double_attack_rule(dice_rule_id)

func _is_black_signer_rule() -> bool:
	return DiceFlow.is_black_signer_rule(dice_rule_id)

func _is_dice_push_rule() -> bool:
	return DiceFlow.is_dice_push_rule(dice_rule_id)

func _visible_dice_total() -> int:
	return DiceFlow.visible_total(dice)

func _dice_push_state() -> Dictionary:
	return {
		"count": dice_push_count,
		"current_total": dice_push_current_total,
		"attack_base": dice_push_attack_base,
		"active": dice_push_active,
		"failed": dice_push_failed,
		"locked": dice_push_locked,
		"pending_total": dice_push_pending_total,
		"history": dice_push_history.duplicate(true)
	}

func _apply_dice_push_state(state: Dictionary) -> void:
	dice_push_count = int(state.get("count", 0))
	dice_push_current_total = int(state.get("current_total", 0))
	dice_push_attack_base = int(state.get("attack_base", 0))
	dice_push_active = bool(state.get("active", false))
	dice_push_failed = bool(state.get("failed", false))
	dice_push_locked = bool(state.get("locked", false))
	dice_push_pending_total = int(state.get("pending_total", 0))
	dice_push_history = (state.get("history", []) as Array).duplicate(true)

func _reset_dice_push_state() -> void:
	_apply_dice_push_state(DiceFlow.empty_push_state())

func _sync_dice_push_seed() -> void:
	_apply_dice_push_state(DiceFlow.synced_push_state(dice, dice_locked, dice_rule_id, rerolls_left, selected_attack_die_index))

func _dice_push_has_attack_override() -> bool:
	return DiceFlow.push_has_attack_override(dice_rule_id, dice_push_active, dice_push_failed)

func _can_push_dice() -> bool:
	return DiceFlow.can_push(phase, dice_rolled, dice_roll_in_progress, dice_role_selecting, dice_rule_id, dice_push_failed, dice_push_locked, dice_push_current_total, dice_push_count, dice)

func _requires_attack_die_choice() -> bool:
	return DiceFlow.requires_attack_die_choice(dice_rule_id)

func _attack_die_choice_prompt() -> String:
	if _is_double_attack_rule():
		return UiText.t("battle.message.double_attack_prompt")
	return UiText.t("battle.message.attack_guard_prompt")

func _attack_die_roll_message() -> String:
	if _is_double_attack_rule():
		return UiText.t("battle.message.double_attack_roll")
	return UiText.t("battle.message.attack_guard_roll")

func _attack_die_result_message() -> String:
	if _is_double_attack_rule():
		return UiText.t("battle.message.double_attack_result", {"values": _dice_values_text(dice)})
	return UiText.t("battle.message.attack_guard_result", {"values": _dice_values_text(dice)})

func _compute_current_dice_result() -> Dictionary:
	return DiceFlow.current_result(dice, dice_locked, dice_rule_id, rerolls_left, selected_attack_die_index, _dice_push_state())

func _recompute_attack_and_guard() -> void:
	var result: Dictionary = _apply_dice_run_upgrades(_compute_current_dice_result())
	dice = DiceResolver.normalize_values(result.get("dice_values", dice), dice_rule_id)
	dice_locked = DiceResolver.normalize_locks(result.get("dice_locked", dice_locked), dice_rule_id)
	attack_base = int(result.get("attack_base", 0))
	guard_value = int(result.get("guard_value", 0))

func _apply_resolution_run_upgrades(payload: Dictionary) -> Dictionary:
	var result := payload.duplicate(true)
	var roulette_bonus := float(active_run_upgrades.get("roulette_bonus", 0.0))
	var numeric_mode := str(result.get("combat_core", result.get("outcome_mode", ""))) == "numeric_roulette"
	if numeric_mode:
		var committed := clampi(int(result.get("wager_marbles_committed", wager_marbles_committed)), 0, 4)
		var marble_bonus := float(active_run_upgrades.get("marble_bonus", 0.0))
		var current_multiplier := float(result.get("damage_multiplier", result.get("payout_multiplier", damage_multiplier)))
		var wager_polish_bonus := 0.1 * marble_bonus * float(committed)
		var next_multiplier := current_multiplier + roulette_bonus + wager_polish_bonus
		if roulette_bonus != 0.0 or wager_polish_bonus != 0.0:
			result["damage_multiplier"] = next_multiplier
			result["payout_multiplier"] = next_multiplier
			result["run_upgrade_multiplier_bonus"] = next_multiplier - current_multiplier
		if roulette_bonus != 0.0:
			result["run_upgrade_roulette_bonus"] = roulette_bonus
		if wager_polish_bonus != 0.0:
			result["run_upgrade_wager_polish_bonus"] = wager_polish_bonus
		return result
	var pending := str(result.get("pending_slot", pending_slot))
	var placed := _normalize_slots(result.get("placed_slots", placed_slots))
	var marked := RouletteSlotCatalog.has_placed_token(placed, pending)
	var marble_bonus := float(active_run_upgrades.get("marble_bonus", 0.0)) if marked else 0.0
	var marble_multiplier := RouletteSlotCatalog.marble_upgrade_multiplier(pending) if marble_bonus != 0.0 else 1.0
	var current_multiplier := float(result.get("damage_multiplier", result.get("payout_multiplier", damage_multiplier)))
	var next_multiplier := current_multiplier + roulette_bonus
	if marble_bonus != 0.0:
		next_multiplier *= marble_multiplier
	if roulette_bonus != 0.0 or marble_bonus != 0.0:
		result["damage_multiplier"] = next_multiplier
		result["payout_multiplier"] = next_multiplier
		result["run_upgrade_multiplier_bonus"] = next_multiplier - current_multiplier
	if roulette_bonus != 0.0:
		result["run_upgrade_roulette_bonus"] = roulette_bonus
	if marble_bonus != 0.0:
		result["run_upgrade_marble_multiplier"] = marble_multiplier
	return result

func _update_opponent_layer() -> void:
	opponent_layer.set_state(VisualSnapshots.opponent_state(_visual_layer_snapshot({
		"monster_id": monster_id,
		"monster_name": monster_name,
		"monster_pattern_tuning": monster_pattern_tuning,
		"enemy_hp": enemy_hp,
		"enemy_max_hp": enemy_max_hp,
		"enemy_intent": enemy_intent,
		"current_move_id": current_move_id,
		"enemy_flash": enemy_flash,
		"player_flash": player_flash,
		"opponent_reaction": opponent_reaction,
		"opponent_mood": opponent_mood
	})))

func _visual_layer_snapshot(extra: Dictionary = {}) -> Dictionary:
	var snapshot := {
		"phase": phase,
		"active_run_upgrades": active_run_upgrades
	}
	for key in extra.keys():
		snapshot[key] = extra[key]
	return snapshot

func _update_camera_beat() -> void:
	if camera_rig == null:
		return
	camera_rig.set_beat(_camera_beat())

func _camera_beat() -> String:
	return VisualSnapshots.camera_beat(_visual_layer_snapshot({
		"throwing_hand": throwing_hand,
		"thrown_marbles": thrown_marbles
	}))

func _screen_to_world_pos(pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * pos

func _render_buttons() -> void:
	var presentation: Dictionary = ActionPresenter.build(_action_presenter_snapshot())
	if bool(presentation.get("potion_menu", false)):
		_render_potion_menu_buttons()
		return
	for descriptor in presentation.get("buttons", []):
		if descriptor is Dictionary:
			_render_action_button(descriptor)
	if bool(presentation.get("potion_entry", false)):
		_render_potion_entry_button()

func _action_presenter_snapshot() -> Dictionary:
	var attack_die_buttons: Array[Dictionary] = []
	if _requires_attack_die_choice() and selected_attack_die_index < 0 and dice_role_selecting:
		for i in range(dice.size()):
			attack_die_buttons.append({
				"label": _attack_die_button_text(i),
				"index": i,
				"primary": i == 0
			})
	return {
		"phase": phase,
		"potion_menu_open": potion_menu_open,
		"is_black_signer_rule": _is_black_signer_rule(),
		"dice_roll_in_progress": dice_roll_in_progress,
		"dice_rolled": dice_rolled,
		"needs_attack_die_choice": _requires_attack_die_choice() and selected_attack_die_index < 0 and dice_role_selecting,
		"attack_die_buttons": attack_die_buttons,
		"is_dice_push_rule": _is_dice_push_rule(),
		"can_push_dice": _can_push_dice(),
		"can_reroll": rerolls_left > 0 and not _all_dice_locked() and dice_push_count <= 0,
			"marble_setup_ready": _marble_setup_ready(),
			"can_place_marble": marbles.size() > 0 and not throwing_hand and thrown_marbles.is_empty(),
			"can_wager_go": wager_marbles_committed < wager_marbles_available,
			"revealed_marbles": revealed_marbles,
			"has_selected_marble": not selected_marble.is_empty(),
			"is_numeric_core": _is_numeric_core(),
		"numeric_go_available": numeric_go_available,
		"run_over": run_over
	}

func _render_action_button(descriptor: Dictionary) -> void:
	var method := str(descriptor.get("method", "_noop"))
	var callable := Callable(self, method)
	for arg in descriptor.get("args", []):
		callable = callable.bind(arg)
	_button(str(descriptor.get("label", "")), callable, bool(descriptor.get("enabled", true)), bool(descriptor.get("primary", false)))

func _render_potion_entry_button() -> void:
	if _can_open_potion_menu():
		_button(UiText.t("battle.action.potion"), Callable(self, "_open_potion_menu"), true)

func _render_potion_menu_buttons() -> void:
	var enabled_by_id: Dictionary = {}
	for potion_id in active_potion_ids:
		var id := str(potion_id)
		enabled_by_id[id] = _can_use_potion(id)
	for descriptor in ActionPresenter.potion_menu_buttons({
		"active_potion_ids": active_potion_ids,
		"potion_enabled": enabled_by_id
	}):
		_render_action_button(descriptor)

func _open_potion_menu() -> void:
	if not _can_open_potion_menu():
		return
	potion_menu_open = true
	_render()

func _close_potion_menu() -> void:
	potion_menu_open = false
	_render()

func _can_open_potion_menu() -> bool:
	return not active_potion_ids.is_empty() and not (phase in ["spinning", "result"]) and not dice_roll_in_progress

func _can_use_potion(potion_id: String) -> bool:
	var id := PotionCatalog.canonical_id(potion_id)
	match id:
		PotionCatalog.RED_RECOVERY:
			return last_turn_damage_taken > 0 and player_hp < player_max_hp
		PotionCatalog.YELLOW_GUARD:
			return not (phase in ["spinning", "result"])
		PotionCatalog.GREEN_REWARD:
			return reward_chance_multiplier <= 1.0 and not run_over
		PotionCatalog.PURPLE_JACKPOT:
			return jackpot_damage_bonus <= 0 and not jackpot_bonus_spent and not run_over
		PotionCatalog.BLUE_DICE:
			return phase == "dice" and dice_rolled and not dice_roll_in_progress and not _all_dice_locked()
		PotionCatalog.WHITE_WAGER:
			return _is_numeric_core() and phase == "wager" and selected_marble.is_empty()
		PotionCatalog.CYAN_TIME:
			return _is_numeric_core() and phase in ["dice", "wager", "intervene"]
	return false

func _use_potion(potion_id: String) -> void:
	if not _can_use_potion(potion_id):
		return
	var id := PotionCatalog.canonical_id(potion_id)
	var consumed_by_runtime := false
	match id:
		PotionCatalog.RED_RECOVERY:
			var healed: int = min(last_turn_damage_taken, player_max_hp - player_hp)
			player_hp += healed
			message = UiText.t("battle.message.potion.red", {"amount": healed})
		PotionCatalog.YELLOW_GUARD:
			_apply_potion_runtime_patch(RuntimeBridge.apply_hook("potion_used", _potion_runtime_snapshot(), ["guard_potion"], {"potion_id": id}))
			consumed_by_runtime = true
			message = UiText.t("battle.message.potion.guard")
		PotionCatalog.GREEN_REWARD:
			reward_chance_multiplier = 2.0
			message = UiText.t("battle.message.potion.reward")
		PotionCatalog.PURPLE_JACKPOT:
			jackpot_damage_bonus = 30
			message = UiText.t("battle.message.potion.jackpot")
		PotionCatalog.BLUE_DICE:
			rerolls_left += 1
			_consume_potion(potion_id)
			potion_menu_open = false
			_reroll_open()
			return
		PotionCatalog.WHITE_WAGER:
			wager_marbles_available += 2
			_sync_wager_marbles_visual()
			message = UiText.t("battle.message.potion.wager")
		PotionCatalog.CYAN_TIME:
			if phase == "intervene":
				numeric_go_chances_left += 1
				numeric_go_available = true
				numeric_next_go_available = true
			else:
				potion_extra_go_chances += 1
			message = UiText.t("battle.message.potion.time")
	if not consumed_by_runtime:
		_consume_potion(potion_id)
	potion_menu_open = false
	_render()

func _potion_runtime_snapshot() -> Dictionary:
	return {
		"player_block": player_block,
		"active_potion_ids": active_potion_ids.duplicate(),
		"consumed_potion_ids": consumed_potion_ids.duplicate(),
		"applied_effects": last_applied_effects.duplicate(true)
	}

func _apply_potion_runtime_patch(patch: Dictionary) -> void:
	player_block = int(patch.get("player_block", player_block))
	active_potion_ids = (patch.get("active_potion_ids", active_potion_ids) as Array).duplicate()
	consumed_potion_ids = (patch.get("consumed_potion_ids", consumed_potion_ids) as Array).duplicate()
	last_applied_effects = (patch.get("applied_effects", last_applied_effects) as Array).duplicate(true)

func _consume_potion(potion_id: String) -> void:
	var index := active_potion_ids.find(potion_id)
	if index < 0:
		return
	active_potion_ids.remove_at(index)
	consumed_potion_ids.append(potion_id)

func _button(text: String, callback: Callable, enabled: bool = true, primary: bool = false) -> void:
	prompt_layer.add_button(text, callback, enabled, primary)

func _clear_object_inputs() -> void:
	if object_input_layer == null:
		return
	for child in object_input_layer.get_children():
		child.queue_free()

func _render_object_inputs() -> void:
	if object_input_layer == null:
		return
	if phase == "dice" and dice_rolled and _requires_attack_die_choice() and selected_attack_die_index < 0 and dice_role_selecting and not dice_roll_in_progress:
		for i in range(dice.size()):
			_object_button(_die_rect(i).grow(12.0), Callable(self, "_select_attack_die").bind(i), Callable(self, "_set_hovered_attack_die").bind(i), Callable(self, "_clear_hovered_attack_die").bind(i))
	elif phase == "marble":
		if not marbles.is_empty():
			for slot_id in RouletteSlotCatalog.slot_ids():
				var rect := Rect2(_slot_center(slot_id) - Vector2(54, 38), Vector2(108, 76))
				_object_button(rect, Callable(self, "_place_marbles_on_slot").bind(slot_id), Callable(self, "_set_hovered_slot").bind(slot_id), Callable(self, "_clear_hovered_slot").bind(slot_id))
		elif _marble_setup_ready():
			_object_button(_roulette_spin_rect(), Callable(self, "_open_roulette_spin_ritual"), Callable(self, "_set_hovered_spin_wheel"), Callable(self, "_clear_hovered_spin_wheel"))
	elif phase == "marble_choice":
		for i in range(revealed_marbles.size()):
			_object_button(_marble_choice_rect(i), Callable(self, "_choose_revealed_marble").bind(i), Callable(self, "_set_hovered_marble_choice").bind(i), Callable(self, "_clear_hovered_marble_choice").bind(i))
	elif phase == "wager":
		_object_button(_roulette_spin_rect(), Callable(self, "_open_numeric_roulette_spin"), Callable(self, "_set_hovered_spin_wheel"), Callable(self, "_clear_hovered_spin_wheel"))

func _object_button(rect: Rect2, callback: Callable, enter_callback: Callable, exit_callback: Callable) -> void:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_transparent_object_button_style(button)
	button.mouse_entered.connect(enter_callback)
	button.mouse_exited.connect(exit_callback)
	button.pressed.connect(callback)
	object_input_layer.add_child(button)

func _apply_transparent_object_button_style(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, empty)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(color_name, Color(1, 1, 1, 0))

func _set_hovered_attack_die(index: int) -> void:
	hovered_attack_die_index = index
	_update_visual_layers()

func _clear_hovered_attack_die(index: int) -> void:
	if hovered_attack_die_index != index:
		return
	hovered_attack_die_index = -1
	_update_visual_layers()

func _set_hovered_slot(slot_id: String) -> void:
	hovered_slot_id = slot_id
	_update_visual_layers()

func _clear_hovered_slot(slot_id: String) -> void:
	if hovered_slot_id != slot_id:
		return
	hovered_slot_id = ""
	_update_visual_layers()

func _set_hovered_spin_wheel() -> void:
	hovered_spin_wheel = true
	_update_visual_layers()

func _clear_hovered_spin_wheel() -> void:
	hovered_spin_wheel = false
	_update_visual_layers()

func _set_hovered_marble_choice(index: int) -> void:
	hovered_marble_choice_index = index
	_update_visual_layers()

func _clear_hovered_marble_choice(index: int) -> void:
	if hovered_marble_choice_index != index:
		return
	hovered_marble_choice_index = -1
	_update_visual_layers()

func _action_prompt() -> String:
	return PromptPresenter.action_prompt(_action_prompt_snapshot())

func _action_prompt_snapshot() -> Dictionary:
	return {
		"phase": phase,
		"is_black_signer_rule": _is_black_signer_rule(),
		"dice_rolled": dice_rolled,
		"needs_attack_die_choice": _requires_attack_die_choice() and selected_attack_die_index < 0,
		"attack_die_choice_prompt": _attack_die_choice_prompt(),
		"thrown_marbles": thrown_marbles,
		"marble_setup_ready": _marble_setup_ready(),
			"wager_marbles_committed": wager_marbles_committed,
			"wager_marbles_available": wager_marbles_available,
			"selected_marble": selected_marble,
			"is_numeric_core": _is_numeric_core(),
		"numeric_roulette_multiplier": numeric_roulette_multiplier,
		"numeric_preview_damage": _numeric_preview_damage(),
		"run_over": run_over
	}

func _open_dice_ritual() -> void:
	if phase != "dice" or dice_rolled:
		return
	_roll_dice()

func _apply_dice_ritual_result(result: Dictionary) -> void:
	dice_rule_id = str(result.get("dice_rule_id", dice_rule_id))
	var normalized: Dictionary = DiceResolver.compute_result(
		result.get("dice_values", result.get("dice", dice)),
		result.get("dice_locked", dice_locked),
		dice_rule_id,
		int(result.get("rerolls_left", rerolls_left)),
		result.get("applied_effects", []),
		int(result.get("selected_attack_die_index", selected_attack_die_index))
	)
	normalized["cash"] = cash
	normalized["player_block"] = player_block
	normalized["relic_state"] = active_relic_state
	normalized = RelicBridge.apply_dice_result(normalized, active_relic_ids)
	cash = int(normalized.get("cash", cash))
	active_relic_state = normalized.get("relic_state", active_relic_state)
	normalized = _apply_dice_run_upgrades(normalized)
	dice = DiceResolver.normalize_values(normalized.get("dice_values", []), dice_rule_id)
	dice_locked = DiceResolver.normalize_locks(normalized.get("dice_locked", []), dice_rule_id)
	rerolls_left = int(normalized.get("rerolls_left", 0))
	attack_base = int(normalized.get("attack_base", 0))
	selected_attack_die_index = int(normalized.get("selected_attack_die_index", selected_attack_die_index))
	guard_value = int(normalized.get("guard_value", guard_value))
	if _is_attack_guard_rule():
		player_block = max(0, player_block + guard_value)
	dice_relics_applied = true
	dice_rolled = true
	dice_roll_fx = 1.0
	table_pulse = 1.0
	banner_text = "LOCK OR TAKE"
	banner_alpha = 0.0
	message = UiText.t("battle.message.dice_attack_ready", {"attack": attack_base})
	_play_sfx("dice_roll", 0.95, -4.0)
	_render()
	_show_feedback_from_effects(normalized.get("applied_effects", []), "dice")
	_take_marbles()

func _roll_dice() -> void:
	if dice_roll_in_progress:
		return
	if _is_black_signer_rule():
		return
	_reset_dice_push_state()
	dice_role_selecting = false
	if _begin_dice_roll(false):
		return
	dice_rolled = true
	dice_locked = DiceResolver.starting_locks(dice_rule_id)
	rerolls_left = int(DiceResolver.rule(dice_rule_id).get("rerolls", 2))
	_randomize_open_dice()
	dice_relics_applied = false
	selected_attack_die_index = -1
	dice_role_selecting = false
	guard_value = 0
	attack_base = 0 if _requires_attack_die_choice() else int(_apply_dice_run_upgrades(DiceResolver.compute_result(dice, dice_locked, dice_rule_id, rerolls_left)).get("attack_base", 0))
	_sync_dice_push_seed()
	dice_roll_fx = 1.0
	banner_text = ""
	banner_alpha = 0.0
	table_pulse = 1.0
	message = _attack_die_roll_message() if _requires_attack_die_choice() else UiText.t("battle.message.roll_single", {"attack": attack_base})
	_play_sfx("dice_roll", 0.95, -4.0)
	_render()
	dice_result_feedback_token += 1
	_queue_dice_result_feedback(dice_result_feedback_token)

func _reroll_open() -> void:
	if dice_roll_in_progress:
		return
	if _is_black_signer_rule():
		return
	if rerolls_left <= 0:
		return
	if dice_push_count > 0:
		return
	dice_role_selecting = false
	if _begin_dice_roll(true):
		return
	rerolls_left -= 1
	_randomize_open_dice()
	dice_relics_applied = false
	selected_attack_die_index = -1
	dice_role_selecting = false
	guard_value = 0
	attack_base = 0 if _requires_attack_die_choice() else int(_apply_dice_run_upgrades(DiceResolver.compute_result(dice, dice_locked, dice_rule_id, rerolls_left)).get("attack_base", 0))
	_sync_dice_push_seed()
	dice_roll_fx = 1.0
	banner_text = ""
	banner_alpha = 0.0
	table_pulse = 1.0
	message = UiText.t("battle.message.reroll_choice", {"prompt": _attack_die_choice_prompt()}) if _requires_attack_die_choice() else UiText.t("battle.message.reroll_single", {"attack": attack_base})
	_play_sfx("dice_roll", 1.08, -5.0)
	_render()
	dice_result_feedback_token += 1
	_queue_dice_result_feedback(dice_result_feedback_token)

func _begin_dice_roll(is_reroll: bool, is_push: bool = false) -> bool:
	var start := DiceRollHandoff.begin_roll({
		"dice_rule_id": dice_rule_id,
		"dice": dice,
		"dice_locked": dice_locked,
		"rerolls_left": rerolls_left,
		"is_reroll": is_reroll,
		"is_push": is_push,
		"use_dice_cup_layer_3d": use_dice_cup_layer_3d,
		"has_dice_cup_roll_layer": dice_cup_roll_layer != null,
		"has_dice_roll_layer": dice_roll_layer != null
	})
	dice_locked = DiceResolver.normalize_locks(start.get("dice_locked", dice_locked), dice_rule_id)
	rerolls_left = int(start.get("rerolls_left", rerolls_left))
	dice_roll_in_progress = bool(start.get("dice_roll_in_progress", false))
	dice_roll_is_reroll = bool(start.get("dice_roll_is_reroll", is_reroll))
	dice_roll_is_push = bool(start.get("dice_roll_is_push", is_push))
	dice_roll_fx = float(start.get("dice_roll_fx", 1.0))
	banner_text = str(start.get("banner_text", ""))
	banner_alpha = float(start.get("banner_alpha", 0.0))
	table_pulse = float(start.get("table_pulse", 1.0))
	message = UiText.t("battle.message.roll_cup") if _can_use_dice_cup_layer() else UiText.t("battle.message.roll_slot")
	_play_sfx("dice_roll", 0.95 if not is_reroll else 1.08, -4.0 if not is_reroll else -5.0)
	_render()
	if str(start.get("route", "immediate")) == "cup" and dice_cup_roll_layer != null and dice_cup_roll_layer.has_method("roll"):
		dice_cup_roll_layer.roll(start.get("cup_payload", {}))
		return true
	if str(start.get("route", "immediate")) == "immediate":
		return false
	if str(start.get("route", "immediate")) == "roll_2d" and dice_roll_layer != null and dice_roll_layer.has_method("roll"):
		dice_roll_layer.roll(start.get("roll_payload", {}))
		return true
	dice_roll_in_progress = false
	return false

func _can_use_dice_cup_layer() -> bool:
	return DiceRollHandoff.can_use_cup_layer(use_dice_cup_layer_3d, dice_cup_roll_layer != null, dice_rule_id)

func _can_use_dice_roll_layer() -> bool:
	return DiceRollHandoff.can_use_roll_layer(dice_roll_layer != null, dice_rule_id)

func _on_dice_roll_finished(value: int) -> void:
	if not dice_roll_in_progress or phase != "dice":
		return
	var rolled_value: int = clamp(value, 1, 6)
	_finish_dice_roll_with_values([rolled_value])

func _on_dice_cup_roll_finished(values: Array) -> void:
	if not dice_roll_in_progress or phase != "dice":
		return
	_finish_dice_roll_with_values(values)

func _finish_dice_roll_with_values(values: Array) -> void:
	var finish := DiceRollHandoff.finish_roll({
		"dice_rule_id": dice_rule_id,
		"dice": dice,
		"dice_locked": dice_locked,
		"rerolls_left": rerolls_left,
		"dice_roll_is_reroll": dice_roll_is_reroll,
		"dice_roll_is_push": dice_roll_is_push,
		"selected_attack_die_index": selected_attack_die_index,
		"active_run_upgrades": active_run_upgrades
	}, values)
	dice_roll_in_progress = bool(finish.get("dice_roll_in_progress", false))
	dice = DiceResolver.normalize_values(finish.get("dice", dice), dice_rule_id)
	dice_rolled = bool(finish.get("dice_rolled", true))
	dice_relics_applied = bool(finish.get("dice_relics_applied", false))
	dice_role_selecting = bool(finish.get("dice_role_selecting", false))
	if bool(finish.get("finish_push", false)):
		_finish_dice_push_roll()
		dice_roll_is_push = bool(finish.get("dice_roll_is_push", false))
		dice_roll_is_reroll = bool(finish.get("dice_roll_is_reroll", false))
		return
	_apply_dice_push_state(finish.get("push_state", DiceFlow.empty_push_state()))
	attack_base = int(finish.get("attack_base", 0))
	guard_value = int(finish.get("guard_value", 0))
	dice_roll_fx = float(finish.get("dice_roll_fx", 1.0))
	banner_text = str(finish.get("banner_text", ""))
	banner_alpha = float(finish.get("banner_alpha", 0.0))
	table_pulse = float(finish.get("table_pulse", 1.0))
	dice_roll_is_push = bool(finish.get("dice_roll_is_push", false))
	dice_roll_is_reroll = bool(finish.get("dice_roll_is_reroll", false))
	if _requires_attack_die_choice() and selected_attack_die_index < 0:
		message = _attack_die_result_message()
	else:
		message = UiText.t("battle.message.dice_result_single", {"values": _dice_values_text(dice), "attack": attack_base})
	_render()
	dice_result_feedback_token += 1
	_queue_dice_result_feedback(dice_result_feedback_token)

func _dice_values_text(values: Array) -> String:
	return DiceFlow.dice_values_text(values)

func _show_dice_result_feedback() -> void:
	if feedback_layer != null and feedback_layer.has_method("show_dice_result"):
		feedback_layer.show_dice_result(dice.duplicate(), attack_base, rerolls_left)

func _queue_dice_result_feedback(token: int) -> void:
	await get_tree().create_timer(0.18).timeout
	if token != dice_result_feedback_token or phase != "dice" or not dice_rolled:
		return
	if _requires_attack_die_choice() and selected_attack_die_index < 0:
		return
	_show_dice_result_feedback()

func _push_dice() -> void:
	if not _can_push_dice():
		return
	dice_role_selecting = false
	dice_push_pending_total = dice_push_current_total if dice_push_current_total > 0 else _visible_dice_total()
	if _begin_dice_roll(false, true):
		return
	var open_values := DiceResolver.starting_values(dice_rule_id)
	var open_locks := DiceResolver.starting_locks(dice_rule_id)
	_finish_dice_roll_with_values(DiceResolver.roll_open(open_values, open_locks, dice_rule_id, rng))

func _finish_dice_push_roll() -> void:
	var previous_total := dice_push_pending_total if dice_push_pending_total > 0 else _visible_dice_total()
	var new_total := _visible_dice_total()
	var push_result := DicePushResolver.resolve_push(previous_total, new_total, dice_push_count)
	dice_push_active = bool(push_result.get("accepted", false))
	dice_push_failed = bool(push_result.get("failed", false))
	dice_push_locked = bool(push_result.get("locked", false))
	dice_push_count = int(push_result.get("push_count", dice_push_count))
	dice_push_current_total = int(push_result.get("current_total", new_total))
	dice_push_attack_base = int(push_result.get("attack_value", new_total))
	dice_push_pending_total = 0
	dice_push_history.append(push_result.duplicate(true))
	var computed := _apply_dice_run_upgrades(_compute_current_dice_result())
	attack_base = int(computed.get("attack_base", dice_push_attack_base))
	guard_value = int(computed.get("guard_value", guard_value))
	dice_roll_fx = 1.0
	table_pulse = 1.0
	dice_role_selecting = false
	banner_alpha = 1.0
	banner_text = UiText.t("battle.banner.dice_push_failed") if dice_push_failed else UiText.t("battle.banner.dice_push_success")
	var pushes_left: int = max(0, DicePushResolver.MAX_PUSHES - dice_push_count)
	if dice_push_failed:
		message = UiText.t("battle.message.dice_push_failed", {"from": previous_total, "to": new_total, "attack": attack_base})
	elif dice_push_locked:
		message = UiText.t("battle.message.dice_push_locked", {"from": previous_total, "to": new_total, "attack": attack_base})
	else:
		message = UiText.t("battle.message.dice_push_success", {"from": previous_total, "to": new_total, "attack": attack_base, "left": pushes_left})
	_play_sfx("dice_roll", 0.98, -4.5)
	_play_sfx("table_hit", 0.75, -9.0)
	_render()
	dice_result_feedback_token += 1
	_queue_dice_result_feedback(dice_result_feedback_token)

func _push_risk_roll() -> void:
	rerolls_left += 1
	dice_locked = DiceResolver.starting_locks(dice_rule_id)
	_randomize_open_dice()
	dice_relics_applied = false
	selected_attack_die_index = -1
	guard_value = 0
	attack_base = 0 if _requires_attack_die_choice() else int(_apply_dice_run_upgrades(DiceResolver.compute_result(dice, dice_locked, dice_rule_id, rerolls_left)).get("attack_base", 0))
	dice_roll_fx = 1.0
	banner_text = "EXTRA ROLL"
	banner_alpha = 1.0
	table_pulse = 1.0
	message = UiText.t("battle.message.extra_roll_choice", {"prompt": _attack_die_choice_prompt()}) if _requires_attack_die_choice() else UiText.t("battle.message.extra_roll_single", {"attack": attack_base})
	_play_sfx("dice_roll", 0.86, -3.5)
	_play_sfx("table_hit", 0.75, -9.0)
	_render()

func _confirm_dice_result() -> void:
	if _requires_attack_die_choice() and selected_attack_die_index < 0:
		dice_role_selecting = true
		message = _attack_die_choice_prompt()
		banner_text = UiText.t("battle.banner.choose_attack_die")
		banner_alpha = 1.0
		_play_sfx("dice_lock", 0.92, -8.0)
		_render()
		return
	_take_marbles()

func _take_marbles() -> void:
	if _requires_attack_die_choice() and selected_attack_die_index < 0:
		message = UiText.t("battle.message.choose_attack_first")
		_render()
		return
	if not dice_relics_applied:
		var current_dice_payload := _compute_current_dice_result()
		current_dice_payload["cash"] = cash
		current_dice_payload["player_block"] = player_block
		current_dice_payload["relic_state"] = active_relic_state
		var dice_payload: Dictionary = RelicBridge.apply_dice_result(current_dice_payload, active_relic_ids)
		cash = int(dice_payload.get("cash", cash))
		active_relic_state = dice_payload.get("relic_state", active_relic_state)
		if _dice_push_has_attack_override():
			dice_payload["attack_base"] = max(0, dice_push_attack_base)
		dice_payload = _apply_dice_run_upgrades(dice_payload)
		dice = DiceResolver.normalize_values(dice_payload.get("dice_values", dice), dice_rule_id)
		dice_locked = DiceResolver.normalize_locks(dice_payload.get("dice_locked", dice_locked), dice_rule_id)
		rerolls_left = int(dice_payload.get("rerolls_left", rerolls_left))
		attack_base = int(dice_payload.get("attack_base", attack_base))
		guard_value = int(dice_payload.get("guard_value", guard_value))
		selected_attack_die_index = int(dice_payload.get("selected_attack_die_index", selected_attack_die_index))
		if _is_attack_guard_rule():
			player_block = max(0, int(dice_payload.get("player_block", player_block)))
		dice_relics_applied = true
		_show_feedback_from_effects(dice_payload.get("applied_effects", []), "dice")
	if attack_base <= 0:
		attack_base = int(_apply_dice_run_upgrades(_compute_current_dice_result()).get("attack_base", 1))
	var payload: Dictionary = {
		"attack_base": attack_base,
		"marble_count": 1,
		"marbles": ["plain"],
		"dice_values": dice.duplicate(),
		"dice_rule_id": dice_rule_id,
		"selected_attack_die_index": selected_attack_die_index,
		"guard_value": guard_value,
		"player_block": player_block,
		"relic_state": active_relic_state
	}
	payload = RelicBridge.apply_marble_gain(payload, active_relic_ids)
	active_relic_state = payload.get("relic_state", active_relic_state)
	if _is_numeric_core():
		_enter_marble_choice_phase(payload)
		return
	var payload_marbles: Array[String] = _string_array(payload.get("marbles", []))
	var count: int = max(1, int(payload.get("marble_count", payload_marbles.size())))
	if payload_marbles.is_empty():
		for i in range(count):
			payload_marbles.append("plain")
	var color: String = str(payload_marbles[0])
	for i in range(count):
		marbles.append(str(payload_marbles[min(i, payload_marbles.size() - 1)]))
	phase = "marble"
	hovered_attack_die_index = -1
	hovered_slot_id = ""
	hovered_spin_wheel = false
	selected_marble_slot_id = RouletteSlotCatalog.fallback_id()
	banner_text = UiText.t("battle.banner.attack_marbles", {"attack": attack_base, "count": count})
	banner_alpha = 0.0
	slot_feedback_id = selected_marble_slot_id
	slot_feedback_alpha = 1.0
	message = UiText.t("battle.message.marble_instruction")
	marble_feedback_pos = _marble_pos(0)
	marble_feedback_color = _marble_color(color)
	marble_feedback_alpha = 1.0
	_play_sfx("marble_drop", 1.1, -7.0)
	_render()

func _enter_marble_choice_phase(payload: Dictionary) -> void:
	var state := MarbleChoiceFlow.enter_choice_state(marble_deck_state, rng, attack_base)
	phase = str(state.get("phase", "marble_choice"))
	revealed_marbles = _dictionary_array(state.get("revealed_marbles", []))
	selected_marble = (state.get("selected_marble", {}) as Dictionary).duplicate(true)
	selected_marble_id = str(selected_marble.get("marble_id", ""))
	wager_marbles_available = max(0, int(payload.get("marble_count", 1)) - 1)
	wager_marbles_committed = 0
	numeric_roulette_index = -1
	numeric_roulette_multiplier = 1.0
	numeric_go_available = false
	numeric_next_go_available = true
	numeric_go_chances_left = 1
	numeric_go_per_turn_cap = 999
	numeric_pending_intervention_message = ""
	pending_slot = ""
	placed_slots = _normalize_slots({})
	hovered_attack_die_index = -1
	hovered_slot_id = ""
	hovered_spin_wheel = false
	hovered_marble_choice_index = -1
	marbles.clear()
	banner_text = str(state.get("banner_text", "MARBLE CHOICE"))
	banner_alpha = float(state.get("banner_alpha", 1.0))
	message = str(state.get("message", UiText.t("battle.prompt.choose_revealed_marble")))
	_play_sfx("marble_drop", 1.05, -7.0)
	_render()

func _choose_revealed_marble(index: int) -> void:
	if phase != "marble_choice":
		return
	var state := MarbleChoiceFlow.choose_state(marble_deck_state, index)
	if not bool(state.get("valid", false)):
		return
	phase = str(state.get("phase", "wager"))
	revealed_marbles = _dictionary_array(state.get("revealed_marbles", []))
	selected_marble = (state.get("selected_marble", {}) as Dictionary).duplicate(true)
	selected_marble_id = str(state.get("selected_marble_id", selected_marble.get("marble_id", "")))
	wager_marbles_available = int(state.get("wager_marbles_available", 0))
	wager_marbles_committed = int(state.get("wager_marbles_committed", 0))
	hovered_marble_choice_index = -1
	hovered_spin_wheel = false
	banner_text = str(state.get("banner_text", "MARBLE READY"))
	banner_alpha = float(state.get("banner_alpha", 1.0))
	message = str(state.get("message", UiText.t("battle.prompt.selected_marble_spin", {"marble": selected_marble.get("short_name", selected_marble_id)})))
	_sync_wager_marbles_visual()
	_play_sfx("marble_drop", 1.14, -6.0)
	_render()

func _enter_wager_phase(gained_marbles: int = 1) -> void:
	var extra_marbles: int = max(0, gained_marbles - 1)
	wager_marbles_available = max(0, wager_marbles_available + extra_marbles)
	wager_marbles_committed = clampi(wager_marbles_committed, 0, wager_marbles_available)
	numeric_roulette_index = -1
	numeric_roulette_multiplier = 1.0
	numeric_go_available = false
	numeric_next_go_available = true
	numeric_go_chances_left = 1
	numeric_go_per_turn_cap = 999
	numeric_pending_intervention_message = ""
	pending_slot = ""
	placed_slots = _normalize_slots({})
	phase = "wager"
	hovered_attack_die_index = -1
	hovered_slot_id = ""
	hovered_spin_wheel = false
	_sync_wager_marbles_visual()
	var wager_label := NumericRouletteResolver.multiplier_label(NumericRouletteResolver.wager_multiplier(wager_marbles_committed))
	banner_text = UiText.t("battle.banner.wager", {"attack": _effective_attack_base()})
	banner_alpha = 1.0
	message = UiText.t("battle.message.wager_ready", {
		"attack": _effective_attack_base(),
		"available": wager_marbles_available,
		"committed": wager_marbles_committed,
		"multiplier": wager_label
	})
	_play_sfx("marble_drop", 1.05, -7.0)
	_render()

func _adjust_wager(delta: int) -> void:
	if phase != "wager":
		return
	wager_marbles_committed = clampi(wager_marbles_committed + delta, 0, wager_marbles_available)
	_sync_wager_marbles_visual()
	message = UiText.t("battle.message.wager_changed", {
		"committed": wager_marbles_committed,
		"multiplier": NumericRouletteResolver.multiplier_label(NumericRouletteResolver.wager_multiplier(wager_marbles_committed))
	})
	_play_sfx("marble_drop", 0.94, -8.0)
	_render()

func _sync_wager_marbles_visual() -> void:
	marbles.clear()
	var loose_count: int = max(0, wager_marbles_available - wager_marbles_committed)
	for i in range(loose_count):
		marbles.append("plain")

func _open_marble_throw_ritual() -> void:
	if phase != "marble" or marbles.is_empty() or throwing_hand or not thrown_marbles.is_empty():
		return
	_place_marbles_on_slot(selected_marble_slot_id)

func _place_marbles_on_slot(slot_id: String) -> void:
	if phase != "marble" or marbles.is_empty() or throwing_hand or not thrown_marbles.is_empty():
		return
	var placement := LegacySlotFlow.placement_patch(slot_id, marbles)
	if not bool(placement.get("valid", false)):
		return
	var target_slot: String = str(placement.get("target_slot", RouletteSlotCatalog.fallback_id()))
	selected_marble_slot_id = target_slot
	var payload: Dictionary = {
		"marbles": marbles.duplicate(),
		"marble_count": marbles.size(),
		"attack_base": attack_base,
		"dice_values": dice.duplicate(),
		"dice_rule_id": dice_rule_id,
		"placed_slots": _normalize_slots(placed_slots),
		"relic_state": active_relic_state,
		"seed": rng.randi()
	}
	active_relic_state = payload.get("relic_state", active_relic_state)
	marbles = _string_array(payload.get("marbles", marbles))
	placement = LegacySlotFlow.placement_patch(target_slot, marbles)
	var colors: Array[String] = _string_array(placement.get("colors", marbles))
	marbles = _string_array(placement.get("marbles", []))
	hovered_slot_id = str(placement.get("hovered_slot_id", ""))
	hovered_spin_wheel = bool(placement.get("hovered_spin_wheel", false))
	throwing_hand = bool(placement.get("throwing_hand", false))
	hand_marble_preview = _string_array(placement.get("hand_marble_preview", []))
	table_pulse = float(placement.get("table_pulse", table_pulse))
	slot_feedback_id = str(placement.get("slot_feedback_id", target_slot))
	slot_feedback_alpha = float(placement.get("slot_feedback_alpha", slot_feedback_alpha))
	banner_text = str(placement.get("banner_text", banner_text))
	banner_alpha = float(placement.get("banner_alpha", banner_alpha))
	message = str(placement.get("message", message))
	_play_sfx("marble_pick", 0.92, -8.0)
	_render()
	_place_marbles_to_wheel_slot(colors, target_slot, _hand_rect().get_center())

func _apply_marble_throw_ritual_result(result: Dictionary) -> void:
	placed_slots = _normalize_slots(result.get("placed_slots", {}))
	marbles.clear()
	throwing_hand = false
	hand_marble_preview.clear()
	thrown_marbles.clear()
	table_pulse = 1.0
	spin_ready_flash = 1.0
	slot_feedback_id = _first_filled_slot()
	slot_feedback_alpha = 1.0 if slot_feedback_id != "" else 0.0
	var consumed: Array[String] = _string_array(result.get("consumed_marbles", []))
	banner_text = UiText.t("battle.banner.marble_count", {"count": consumed.size()})
	banner_alpha = 1.0
	message = UiText.t("battle.message.marble_setup_done")
	_play_sfx("marble_drop", 0.96, -6.0)
	_render()

func _randomize_open_dice() -> void:
	dice = DiceResolver.roll_open(dice, dice_locked, dice_rule_id, rng)

func _select_black_signer_contract(contract_id: String) -> void:
	if phase != "dice" or not _is_black_signer_rule():
		return
	black_signer_contract_id = contract_id
	dice = []
	dice_locked = []
	dice_rolled = true
	dice_relics_applied = true
	rerolls_left = 0
	selected_attack_die_index = -1
	guard_value = 0
	player_block = 0
	attack_base = 0
	match contract_id:
		"sword":
			attack_base = 8
			message = UiText.t("battle.message.black_signer_sword", {"attack": attack_base, "debt": min(3, black_signer_debt + 1)})
		"shield":
			attack_base = 4
			guard_value = 6
			player_block = 6
			message = UiText.t("battle.message.black_signer_shield", {"attack": attack_base, "guard": player_block, "debt": min(3, black_signer_debt + 1)})
		"roulette":
			attack_base = 5
			roulette_respins_left += 1
			message = UiText.t("battle.message.black_signer_roulette", {"attack": attack_base, "debt": min(3, black_signer_debt + 1)})
		_:
			attack_base = 6
			message = UiText.t("battle.message.black_signer_sword", {"attack": attack_base, "debt": min(3, black_signer_debt + 1)})
	black_signer_debt += 1
	if black_signer_debt >= 3:
		black_signer_debt = 0
		player_hp = max(0, player_hp - 6)
		player_flash = 1.0
		table_hit_flash = 1.0
		message += " " + UiText.t("battle.message.black_signer_debt_hit")
	banner_text = str(DiceResolver.rule(dice_rule_id).get("label", "CONTRACT"))
	banner_alpha = 1.0
	table_pulse = 1.0
	_play_sfx("dice_lock", 0.92, -7.0)
	_render()
	_take_marbles()

func _attack_die_button_text(index: int) -> String:
	var side := UiText.t("battle.die.left") if index == 0 else UiText.t("battle.die.right")
	var value := int(dice[index]) if index >= 0 and index < dice.size() else 0
	if _is_double_attack_rule():
		return side + " " + str(value) + "\n" + UiText.t("battle.die.main_attack")
	return side + " " + str(value) + "\n" + UiText.t("battle.die.attack")

func _try_toggle_die(pos: Vector2) -> bool:
	var index := _die_index_at(pos)
	if index < 0:
		return false
	if _requires_attack_die_choice():
		_select_attack_die(index)
		return true
	dice_locked[index] = not dice_locked[index]
	var lock_state := UiText.t("battle.message.locked") if dice_locked[index] else UiText.t("battle.message.unlocked")
	message = UiText.t("battle.message.die_lock", {"index": index + 1, "state": lock_state})
	dice_roll_fx = 0.3
	_play_sfx("dice_lock", 1.1 if dice_locked[index] else 0.86, -7.0)
	_render()
	return true

func _die_index_at(pos: Vector2) -> int:
	for i in range(dice.size()):
		if _die_rect(i).grow(10.0).has_point(pos):
			return i
	return -1

func _update_object_hover(table_pos: Vector2, screen_pos: Vector2) -> bool:
	var next_attack_die_index := -1
	var next_slot_id := ""
	var next_spin_wheel := false
	if phase == "dice" and dice_rolled and _requires_attack_die_choice() and selected_attack_die_index < 0 and dice_role_selecting:
		next_attack_die_index = _die_index_at(table_pos)
		if next_attack_die_index < 0:
			next_attack_die_index = _die_index_at(screen_pos)
		elif phase == "marble":
			if not marbles.is_empty():
				next_slot_id = _slot_at(table_pos)
			if _marble_setup_ready():
				next_spin_wheel = _roulette_spin_rect().has_point(table_pos)
		elif phase == "wager":
			next_spin_wheel = _roulette_spin_rect().has_point(table_pos)
	var changed := next_attack_die_index != hovered_attack_die_index or next_slot_id != hovered_slot_id or next_spin_wheel != hovered_spin_wheel
	if changed:
		hovered_attack_die_index = next_attack_die_index
		hovered_slot_id = next_slot_id
		hovered_spin_wheel = next_spin_wheel
	return changed

func _select_attack_die(index: int) -> void:
	var result := AttackDieHandoff.select_attack_die({
		"index": index,
		"dice_rolled": dice_rolled,
		"dice": dice,
		"dice_locked": dice_locked,
		"dice_rule_id": dice_rule_id,
		"rerolls_left": rerolls_left,
		"player_block": player_block,
		"active_run_upgrades": active_run_upgrades,
		"push_state": _dice_push_state()
	})
	if not bool(result.get("valid", false)):
		return
	selected_attack_die_index = int(result.get("selected_attack_die_index", index))
	dice_role_selecting = bool(result.get("dice_role_selecting", false))
	hovered_attack_die_index = int(result.get("hovered_attack_die_index", -1))
	dice = DiceResolver.normalize_values(result.get("dice", dice), dice_rule_id)
	dice_locked = DiceResolver.normalize_locks(result.get("dice_locked", dice_locked), dice_rule_id)
	attack_base = int(result.get("attack_base", attack_base))
	guard_value = int(result.get("guard_value", guard_value))
	player_block = int(result.get("player_block", player_block))
	dice_roll_fx = float(result.get("dice_roll_fx", dice_roll_fx))
	banner_text = str(result.get("banner_text", banner_text))
	banner_alpha = float(result.get("banner_alpha", banner_alpha))
	message = str(result.get("message", message))
	_play_sfx("dice_lock", 1.12, -7.0)
	_apply_dice_push_state(result.get("push_state", _dice_push_state()))
	_render()
	_take_marbles()

func _try_start_hand_throw(pos: Vector2) -> void:
	if marbles.is_empty() or not _hand_rect().has_point(pos):
		return
	throwing_hand = true
	hand_start_pos = pos
	hand_pos = pos
	hand_velocity = Vector2.ZERO
	hand_shake = 0.0
	hand_marble_preview = marbles.duplicate()
	message = UiText.t("battle.message.marble_scene")
	marble_feedback_pos = pos
	marble_feedback_color = _marble_color(marbles[0])
	marble_feedback_alpha = 1.0
	_play_sfx("marble_pick", 1.04, -8.0)
	queue_redraw()

func _release_hand_throw(pos: Vector2) -> void:
	if marbles.is_empty():
		throwing_hand = false
		return
	var throw_power: float = clamp(hand_shake / 160.0 + hand_velocity.length() / 90.0, 0.45, 1.65)
	var thrown_colors: Array[String] = marbles.duplicate()
	var slot_id: String = _slot_at(pos)
	if slot_id == "":
		slot_id = RouletteSlotCatalog.fallback_id()
	marbles.clear()
	throwing_hand = false
	hand_marble_preview.clear()
	table_pulse = 1.0
	banner_text = UiText.t("battle.banner.marble_setting")
	banner_alpha = 1.0
	message = UiText.t("battle.message.marble_slot_selected", {"slot": RouletteSlotCatalog.label(slot_id)})
	_place_marbles_to_wheel_slot(thrown_colors, slot_id, pos, throw_power)
	_play_sfx("marble_drop", 0.9 + throw_power * 0.1, -5.0)
	_render()

func _store_one() -> void:
	if marbles.is_empty():
		return
	var color: String = marbles.pop_front()
	stored.append(color)
	message = UiText.t("battle.message.marble_stored", {"marble": _marble_name(color)})
	_play_sfx("marble_pick", 0.82, -9.0)
	_render()

func _recall_stored() -> void:
	if stored.is_empty():
		return
	marbles.append_array(stored)
	stored.clear()
	phase = "marble"
	message = UiText.t("battle.message.marble_recalled")
	_play_sfx("marble_drop", 0.92, -7.0)
	_render()

func _start_spin() -> void:
	if spin_locked or not _marble_setup_ready():
		return
	spin_locked = true
	hovered_slot_id = ""
	hovered_spin_wheel = false
	phase = "spinning"
	payout_multiplier = 1.0
	damage_multiplier = 1.0
	pending_slot = RouletteResolver.weighted_pick(placed_slots, rng)
	if pending_slot == "bust" and roulette_respins_left > 0:
		roulette_respins_left -= 1
		var rerolled_slot := RouletteResolver.weighted_pick(placed_slots, rng)
		if rerolled_slot != "bust":
			pending_slot = rerolled_slot
	var after_payload: Dictionary = RelicBridge.apply_roulette_after_spin({
		"pending_slot": pending_slot,
		"placed_slots": _normalize_slots(placed_slots),
		"cash": cash,
		"cash_delta": 0,
		"attack_base": attack_base,
		"relic_state": active_relic_state,
		"applied_effects": []
	}, active_relic_ids)
	pending_slot = str(after_payload.get("pending_slot", pending_slot))
	cash = int(after_payload.get("cash", cash))
	active_relic_state = after_payload.get("relic_state", active_relic_state)
	last_applied_effects = after_payload.get("applied_effects", [])
	var index: int = RouletteSlotCatalog.index(pending_slot)
	var target_angle: float = 720.0 + float(rng.randi_range(80, 260)) - float(index) * 72.0
	wheel_tick_segment = -1
	wheel_tick_flash = 0.0
	wheel_pointer_kick = 0.0
	spin_ready_flash = 0.0
	banner_text = UiText.t("battle.banner.roulette_start")
	banner_alpha = 1.0
	message = UiText.t("battle.message.roulette_start")
	_play_sfx("wheel_tick", 0.8, -11.0)
	_render()
	var tween: Tween = create_tween()
	tween.tween_property(self, "wheel_angle", wheel_angle + target_angle, 1.15).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	tween.finished.connect(Callable(self, "_open_intervention"))

func _open_roulette_spin_ritual() -> void:
	if _is_numeric_core():
		_open_numeric_roulette_spin()
		return
	if spin_locked or not _marble_setup_ready():
		return
	var payload: Dictionary = {
		"placed_slots": _normalize_slots(placed_slots),
		"attack_base": attack_base,
		"roulette_rerolls_left": 1,
		"roulette_respins_left": roulette_respins_left,
		"relic_state": active_relic_state,
		"seed": rng.randi(),
		"wheel_angle": wheel_angle
	}
	payload = RelicBridge.apply_roulette_before_spin(payload, active_relic_ids)
	roulette_respins_left = int(payload.get("roulette_respins_left", roulette_respins_left))
	active_relic_state = payload.get("relic_state", active_relic_state)
	_show_feedback_from_effects(payload.get("applied_effects", []), "roulette")
	_start_spin()

func _open_numeric_roulette_spin() -> void:
	if spin_locked or phase != "wager":
		return
	var commit_state := NumericRouletteFlow.commit_wager_state(wager_marbles_available, wager_marbles_committed)
	wager_marbles_committed = int(commit_state.get("wager_marbles_committed", wager_marbles_committed))
	wager_marbles_available = int(commit_state.get("wager_marbles_available", wager_marbles_available))
	numeric_go_used_this_spin = false
	numeric_go_per_turn_cap = 999
	_sync_wager_marbles_visual()
	var payload: Dictionary = RelicBridge.apply_roulette_before_spin(
		NumericRouletteFlow.roulette_before_spin_payload(_numeric_flow_snapshot({"seed": rng.randi()})),
		active_relic_ids
	)
	payload = MarbleEffectResolver.apply_before_spin(payload)
	active_relic_state = payload.get("relic_state", active_relic_state)
	_show_feedback_from_effects(payload.get("applied_effects", []), "roulette")
	var spin_result := _numeric_spin_result(payload)
	_apply_numeric_flow_state(NumericRouletteFlow.open_spin_state(_numeric_flow_snapshot(), payload, spin_result))
	_apply_numeric_after_spin_relics()
	_play_sfx("wheel_tick", 0.8, -11.0)
	_render()
	var target_angle: float = _numeric_target_wheel_delta(numeric_roulette_index, 2 + rng.randi_range(0, 1))
	var tween: Tween = create_tween()
	tween.tween_property(self, "wheel_angle", wheel_angle + target_angle, 1.15).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	tween.finished.connect(Callable(self, "_open_numeric_intervention"))

func _numeric_spin_result(spin_payload: Dictionary = {}) -> Dictionary:
	var forced_index := -1
	if not numeric_forced_indices.is_empty():
		forced_index = int(numeric_forced_indices.pop_front())
	if forced_index >= 0:
		return NumericRouletteResolver.spin(rng, forced_index, active_run_upgrades)
	var weighted_indices := _numeric_weighted_indices(spin_payload)
	if weighted_indices.is_empty():
		return NumericRouletteResolver.spin(rng, -1, active_run_upgrades)
	var picked_index := int(weighted_indices[rng.randi_range(0, weighted_indices.size() - 1)])
	return NumericRouletteResolver.spin(rng, picked_index, active_run_upgrades)

func _numeric_weighted_indices(spin_payload: Dictionary) -> Array[int]:
	return NumericRouletteFlow.weighted_indices(active_run_upgrades, spin_payload)

func _numeric_target_wheel_delta(index: int, rotations: int = 2) -> float:
	return NumericRouletteFlow.target_wheel_delta(index, wheel_angle, rotations)

func _apply_numeric_spin_result(spin_result: Dictionary) -> void:
	var state := NumericRouletteFlow.spin_state(spin_result, wager_marbles_committed)
	numeric_roulette_index = int(state.get("index", -1))
	numeric_roulette_multiplier = float(state.get("multiplier", 1.0))
	damage_multiplier = float(state.get("damage_multiplier", 1.0))
	payout_multiplier = float(state.get("payout_multiplier", damage_multiplier))
	pending_slot = str(state.get("pending_slot", "numeric_" + str(numeric_roulette_index)))

func _apply_numeric_after_spin_relics() -> void:
	var payload: Dictionary = RelicBridge.apply_roulette_after_spin(NumericRouletteFlow.roulette_after_spin_payload(_numeric_flow_snapshot()), active_relic_ids)
	cash = int(payload.get("cash", cash))
	active_relic_state = payload.get("relic_state", active_relic_state)
	last_applied_effects = payload.get("applied_effects", [])

func _open_numeric_intervention() -> void:
	_apply_numeric_flow_state(NumericRouletteFlow.intervention_state(_numeric_flow_snapshot({"preview_damage": _numeric_preview_damage()})))
	_play_sfx("table_hit", 0.9, -10.0)
	_render()
	_show_feedback_from_effects(last_applied_effects, "roulette_after_spin")

func _numeric_go() -> void:
	if phase != "intervene" or not numeric_go_available:
		return
	var spin_result := _numeric_spin_result()
	_apply_numeric_flow_state(NumericRouletteFlow.go_spin_state(_numeric_flow_snapshot(), spin_result))
	_apply_numeric_after_spin_relics()
	numeric_next_go_available = numeric_go_chances_left > 0
	numeric_pending_intervention_message = UiText.t("battle.message.numeric_go_result", {
		"roulette": NumericRouletteResolver.multiplier_label(numeric_roulette_multiplier),
		"damage": _numeric_preview_damage()
	})
	var target_angle: float = _numeric_target_wheel_delta(numeric_roulette_index, 1 + rng.randi_range(0, 1))
	_play_sfx("wheel_tick", 1.12, -8.0)
	_render()
	var tween: Tween = create_tween()
	tween.tween_property(self, "wheel_angle", wheel_angle + target_angle, 0.95).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	tween.finished.connect(Callable(self, "_open_numeric_intervention"))

func _numeric_preview_damage() -> int:
	var payload: Dictionary = _apply_resolution_run_upgrades({
		"combat_core": combat_core,
		"outcome_mode": "numeric_roulette",
		"pending_slot": pending_slot,
		"attack_base": _effective_attack_base(),
		"roulette_multiplier": numeric_roulette_multiplier,
		"wager_multiplier": NumericRouletteResolver.wager_multiplier(wager_marbles_committed),
		"wager_marbles_committed": wager_marbles_committed,
		"damage_multiplier": damage_multiplier,
		"payout_multiplier": damage_multiplier,
		"dice_values": dice.duplicate(),
		"selected_marble": selected_marble,
		"selected_marble_id": selected_marble_id,
		"applied_effects": []
	})
	payload = MarbleEffectResolver.apply_resolution_payload(payload)
	var attack_value: int = int(payload.get("attack_base", _effective_attack_base()))
	var resolved_damage_multiplier: float = max(0.0, float(payload.get("damage_multiplier", damage_multiplier)))
	var flat_bonus: int = _pending_jackpot_damage_bonus()
	return NumericRouletteFlow.preview_damage(attack_value, resolved_damage_multiplier, flat_bonus, player_damage_multiplier)

func _pending_jackpot_damage_bonus() -> int:
	if jackpot_damage_bonus <= 0 or jackpot_bonus_spent:
		return 0
	return jackpot_damage_bonus if numeric_roulette_multiplier >= 3.0 else 0

func _apply_roulette_spin_ritual_result(result: Dictionary) -> void:
	pending_slot = str(result.get("pending_slot", "safe"))
	damage_multiplier = float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0)))
	payout_multiplier = damage_multiplier
	wheel_angle = float(result.get("wheel_angle", wheel_angle))
	wheel_pointer_kick = 1.0
	wheel_tick_flash = 1.0
	banner_text = RouletteSlotCatalog.label(pending_slot)
	banner_alpha = 1.0
	message = UiText.t("battle.message.roulette_return", {"multiplier": snapped(damage_multiplier, 0.01)})
	_play_sfx("table_hit", 0.82, -7.0)
	await _open_combat_resolution_beat()

func _numeric_flow_snapshot(extra: Dictionary = {}) -> Dictionary:
	var snapshot := {
		"combat_core": combat_core,
		"cash": cash,
		"run_gold": run_gold,
		"gold_delta": gold_delta,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"player_block": player_block,
		"enemy_hp": enemy_hp,
		"enemy_block": enemy_block,
		"enemy_damage_delta": enemy_damage_delta,
		"enemy_damage_multiplier": enemy_damage_multiplier,
		"attack_base": _effective_attack_base(),
		"dice_values": dice.duplicate(),
		"dice_rule_id": dice_rule_id,
		"selected_attack_die_index": selected_attack_die_index,
		"player_attack_delta": player_attack_delta,
		"player_damage_multiplier": player_damage_multiplier,
		"pending_slot": pending_slot,
		"numeric_roulette_multiplier": numeric_roulette_multiplier,
			"wager_marbles_committed": wager_marbles_committed,
			"wager_marbles_available": wager_marbles_available,
			"selected_marble": selected_marble,
			"selected_marble_id": selected_marble_id,
			"numeric_go_used_this_spin": numeric_go_used_this_spin,
		"numeric_go_chances_left": numeric_go_chances_left,
		"numeric_go_per_turn_cap": numeric_go_per_turn_cap,
		"numeric_go_available": numeric_go_available,
		"numeric_next_go_available": numeric_next_go_available,
		"numeric_pending_intervention_message": numeric_pending_intervention_message,
		"potion_extra_go_chances": potion_extra_go_chances,
		"damage_multiplier": damage_multiplier,
		"payout_multiplier": payout_multiplier,
		"relic_state": active_relic_state,
		"wheel_angle": wheel_angle,
		"placed_slots": _normalize_slots({})
	}
	for key in extra.keys():
		snapshot[key] = extra[key]
	return snapshot

func _apply_numeric_flow_state(state: Dictionary) -> void:
	if state.has("phase"):
		phase = str(state.get("phase"))
	if state.has("spin_locked"):
		spin_locked = bool(state.get("spin_locked"))
	if state.has("numeric_go_available"):
		numeric_go_available = bool(state.get("numeric_go_available"))
	if state.has("numeric_next_go_available"):
		numeric_next_go_available = bool(state.get("numeric_next_go_available"))
	if state.has("numeric_go_chances_left"):
		numeric_go_chances_left = int(state.get("numeric_go_chances_left"))
	if state.has("numeric_go_per_turn_cap"):
		numeric_go_per_turn_cap = int(state.get("numeric_go_per_turn_cap"))
	if state.has("numeric_go_used_this_spin"):
		numeric_go_used_this_spin = bool(state.get("numeric_go_used_this_spin"))
	if state.has("numeric_pending_intervention_message"):
		numeric_pending_intervention_message = str(state.get("numeric_pending_intervention_message"))
	if state.has("numeric_roulette_index"):
		numeric_roulette_index = int(state.get("numeric_roulette_index"))
	if state.has("numeric_roulette_multiplier"):
		numeric_roulette_multiplier = float(state.get("numeric_roulette_multiplier"))
	if state.has("damage_multiplier"):
		damage_multiplier = float(state.get("damage_multiplier"))
	if state.has("payout_multiplier"):
		payout_multiplier = float(state.get("payout_multiplier"))
	if state.has("pending_slot"):
		pending_slot = str(state.get("pending_slot"))
	if state.has("potion_extra_go_chances"):
		potion_extra_go_chances = int(state.get("potion_extra_go_chances"))
	if state.has("wheel_tick_segment"):
		wheel_tick_segment = int(state.get("wheel_tick_segment"))
	if state.has("wheel_tick_flash"):
		wheel_tick_flash = float(state.get("wheel_tick_flash"))
	if state.has("wheel_pointer_kick"):
		wheel_pointer_kick = float(state.get("wheel_pointer_kick"))
	if state.has("spin_ready_flash"):
		spin_ready_flash = float(state.get("spin_ready_flash"))
	if state.has("banner_text"):
		banner_text = str(state.get("banner_text"))
	if state.has("banner_alpha"):
		banner_alpha = float(state.get("banner_alpha"))
	if state.has("message"):
		message = str(state.get("message"))

func _open_combat_resolution_beat() -> void:
	var payload: Dictionary = {
		"pending_slot": pending_slot,
		"placed_slots": _normalize_slots(placed_slots),
		"cash": cash,
		"run_gold": run_gold,
		"gold_delta": gold_delta,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"player_block": player_block,
		"enemy_hp": enemy_hp,
		"enemy_block": enemy_block,
		"enemy_damage_delta": enemy_damage_delta,
		"enemy_damage_multiplier": enemy_damage_multiplier,
		"attack_base": _effective_attack_base(),
		"dice_values": dice.duplicate(),
		"dice_rule_id": dice_rule_id,
		"selected_attack_die_index": selected_attack_die_index,
		"player_attack_delta": player_attack_delta,
		"player_damage_multiplier": player_damage_multiplier,
		"damage_multiplier": damage_multiplier,
		"payout_multiplier": damage_multiplier,
		"relic_state": active_relic_state
	}
	payload = RelicBridge.apply_resolution_before(payload, active_relic_ids)
	active_relic_state = payload.get("relic_state", active_relic_state)
	payload = _apply_resolution_run_upgrades(payload)
	_show_feedback_from_effects(payload.get("applied_effects", []), "resolution_payload")
	var outcome: Dictionary = PayoutResolver.resolve(
		str(payload.get("pending_slot", pending_slot)),
		payload.get("placed_slots", placed_slots),
		int(payload.get("cash", cash)),
		int(payload.get("player_hp", player_hp)),
		int(payload.get("enemy_hp", enemy_hp)),
		float(payload.get("damage_multiplier", payload.get("payout_multiplier", damage_multiplier))),
		int(payload.get("attack_base", attack_base)),
		int(payload.get("flat_damage_bonus", 0)),
		int(payload.get("cash_delta_bonus", 0)),
		int(payload.get("enemy_block", enemy_block)),
		float(payload.get("player_damage_multiplier", player_damage_multiplier))
	)
	outcome["enemy_damage_delta"] = int(payload.get("enemy_damage_delta", enemy_damage_delta))
	outcome["placed_slots"] = payload.get("placed_slots", placed_slots)
	outcome["relic_state"] = active_relic_state
	outcome["player_max_hp"] = int(payload.get("player_max_hp", player_max_hp))
	outcome["dice_values"] = payload.get("dice_values", dice.duplicate())
	outcome["dice_rule_id"] = str(payload.get("dice_rule_id", dice_rule_id))
	outcome["selected_attack_die_index"] = int(payload.get("selected_attack_die_index", selected_attack_die_index))
	var after_outcome := RelicBridge.apply_resolution_after(outcome, active_relic_ids)
	active_relic_state = after_outcome.get("relic_state", active_relic_state)
	_show_combat_result_feedback(after_outcome)

func _open_intervention() -> void:
	spin_locked = false
	phase = "intervene"
	banner_text = RouletteSlotCatalog.label(pending_slot) + "?"
	banner_alpha = 1.0
	message = UiText.t("battle.message.roulette_stopped")
	_play_sfx("table_hit", 0.9, -10.0)
	_render()
	_show_feedback_from_effects(last_applied_effects, "roulette_after_spin")

func _intervene_brake() -> void:
	if pending_slot == "bust" and rng.randf() < 0.65:
		pending_slot = "safe"
		message = UiText.t("battle.message.brake_success")
	else:
		damage_multiplier *= 0.72
		payout_multiplier = damage_multiplier
		message = UiText.t("battle.message.brake_reduce")
	_play_sfx("wheel_tick", 0.62, -8.0)
	_resolve_pending()

func _intervene_nudge() -> void:
	var index: int = RouletteSlotCatalog.index(pending_slot)
	if index < 0:
		index = 0
	var ids: Array[String] = RouletteSlotCatalog.slot_ids()
	index = (index + 1) % ids.size()
	pending_slot = ids[index]
	message = UiText.t("battle.message.nudge_result", {"slot": RouletteSlotCatalog.label(pending_slot)})
	wheel_pointer_kick = 1.0
	_play_sfx("wheel_tick", 1.22, -6.0)
	_resolve_pending()

func _intervene_double() -> void:
	damage_multiplier *= 2.0
	payout_multiplier = damage_multiplier
	message = UiText.t("battle.message.double_down")
	table_pulse = 1.0
	_play_sfx("table_hit", 0.78, -5.0)
	_resolve_pending()

func _resolve_pending() -> void:
	if _is_numeric_core():
		_resolve_numeric_pending()
		return
	var payload: Dictionary = {
		"pending_slot": pending_slot,
		"placed_slots": _normalize_slots(placed_slots),
		"cash": cash,
		"run_gold": run_gold,
		"gold_delta": gold_delta,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"player_block": player_block,
		"enemy_hp": enemy_hp,
		"enemy_block": enemy_block,
		"enemy_damage_delta": enemy_damage_delta,
		"enemy_damage_multiplier": enemy_damage_multiplier,
		"attack_base": _effective_attack_base(),
		"dice_values": dice.duplicate(),
		"dice_rule_id": dice_rule_id,
		"selected_attack_die_index": selected_attack_die_index,
		"player_attack_delta": player_attack_delta,
		"player_damage_multiplier": player_damage_multiplier,
		"damage_multiplier": damage_multiplier,
		"payout_multiplier": damage_multiplier,
		"relic_state": active_relic_state
	}
	payload = RelicBridge.apply_resolution_before(payload, active_relic_ids)
	active_relic_state = payload.get("relic_state", active_relic_state)
	payload = _apply_resolution_run_upgrades(payload)
	_show_feedback_from_effects(payload.get("applied_effects", []), "resolution_payload")
	var outcome: Dictionary = PayoutResolver.resolve(
		str(payload.get("pending_slot", pending_slot)),
		payload.get("placed_slots", placed_slots),
		int(payload.get("cash", cash)),
		int(payload.get("player_hp", player_hp)),
		int(payload.get("enemy_hp", enemy_hp)),
		float(payload.get("damage_multiplier", payload.get("payout_multiplier", damage_multiplier))),
		int(payload.get("attack_base", attack_base)),
		int(payload.get("flat_damage_bonus", 0)),
		int(payload.get("cash_delta_bonus", 0)),
		int(payload.get("enemy_block", enemy_block)),
		float(payload.get("player_damage_multiplier", player_damage_multiplier))
	)
	outcome["enemy_damage_delta"] = int(payload.get("enemy_damage_delta", enemy_damage_delta))
	outcome["placed_slots"] = payload.get("placed_slots", placed_slots)
	outcome["relic_state"] = active_relic_state
	outcome["player_max_hp"] = int(payload.get("player_max_hp", player_max_hp))
	outcome["dice_values"] = payload.get("dice_values", dice.duplicate())
	outcome["dice_rule_id"] = str(payload.get("dice_rule_id", dice_rule_id))
	outcome["selected_attack_die_index"] = int(payload.get("selected_attack_die_index", selected_attack_die_index))
	var after_outcome := RelicBridge.apply_resolution_after(outcome, active_relic_ids)
	active_relic_state = after_outcome.get("relic_state", active_relic_state)
	_show_combat_result_feedback(after_outcome)

func _resolve_numeric_pending() -> void:
	if phase != "intervene":
		return
	numeric_go_available = false
	var snapshot := _numeric_flow_snapshot()
	var payload: Dictionary = NumericRouletteFlow.resolution_before_payload(snapshot)
	payload = RelicBridge.apply_resolution_before(payload, active_relic_ids)
	active_relic_state = payload.get("relic_state", active_relic_state)
	_show_feedback_from_effects(payload.get("applied_effects", []), "resolution_payload")
	payload = _apply_resolution_run_upgrades(payload)
	payload = MarbleEffectResolver.apply_resolution_payload(payload)
	var jackpot_bonus := _pending_jackpot_damage_bonus()
	var outcome: Dictionary = NumericRouletteFlow.resolution_outcome(payload, snapshot, jackpot_bonus)
	outcome = MarbleEffectResolver.apply_outcome(outcome)
	outcome["relic_state"] = active_relic_state
	var after_outcome := RelicBridge.apply_resolution_after(outcome, active_relic_ids)
	if jackpot_bonus > 0:
		jackpot_bonus_spent = true
		jackpot_damage_bonus = 0
	active_relic_state = after_outcome.get("relic_state", active_relic_state)
	_show_combat_result_feedback(after_outcome)

func _show_combat_result_feedback(outcome: Dictionary) -> void:
	if feedback_layer != null and feedback_layer.has_method("show_combat_result"):
		feedback_layer.show_combat_result(outcome)
	_apply_resolution_outcome(outcome)

func _apply_resolution_outcome(outcome: Dictionary) -> void:
	var result_cue := VisualFeedback.combat_result_cue(outcome)
	if result_cue.has("message") and str(result_cue.get("message", "")) == "":
		result_cue["message"] = message
	_apply_feedback_cue_patch(result_cue)
	for cue in result_cue.get("audio_cues", []):
		_play_feedback_audio_cue(cue)

		_apply_resolution_state_patch(ResolutionOutcomeFlow.state_patch(_resolution_state_snapshot(), outcome))
		_finish_selected_marble_turn()
		_render()
		_show_feedback_from_effects(last_applied_effects, "resolution_result")
		_emit_combat_finished_if_ready("resolution")

func _finish_selected_marble_turn() -> void:
	if selected_marble_id == "":
		return
	marble_deck_state.finish_selected(rng)
	selected_marble.clear()
	selected_marble_id = ""
	revealed_marbles.clear()
	hovered_marble_choice_index = -1

func _resolution_state_snapshot() -> Dictionary:
	return {
		"attack_base": attack_base,
		"numeric_roulette_multiplier": numeric_roulette_multiplier,
		"wager_marbles_committed": wager_marbles_committed,
		"numeric_go_used_this_spin": numeric_go_used_this_spin,
		"cash": cash,
		"player_hp": player_hp,
		"enemy_hp": enemy_hp,
		"enemy_block": enemy_block,
		"enemy_damage_delta": enemy_damage_delta,
		"player_attack_delta": player_attack_delta,
		"player_damage_multiplier": player_damage_multiplier,
		"busts": busts,
		"run_over": run_over
	}

func _apply_resolution_state_patch(patch: Dictionary) -> void:
	last_attack_base = int(patch.get("last_attack_base", last_attack_base))
	last_roulette_multiplier = float(patch.get("last_roulette_multiplier", last_roulette_multiplier))
	last_wager_marbles_committed = int(patch.get("last_wager_marbles_committed", last_wager_marbles_committed))
	last_roulette_go_used = bool(patch.get("last_roulette_go_used", last_roulette_go_used))
	cash = int(patch.get("cash", cash))
	player_hp = int(patch.get("player_hp", player_hp))
	enemy_hp = int(patch.get("enemy_hp", enemy_hp))
	enemy_block = int(patch.get("enemy_block", enemy_block))
	enemy_damage_delta = int(patch.get("enemy_damage_delta", enemy_damage_delta))
	player_attack_delta = int(patch.get("player_attack_delta", player_attack_delta))
	player_damage_multiplier = float(patch.get("player_damage_multiplier", player_damage_multiplier))
	busts = int(patch.get("busts", busts))
	last_applied_effects = patch.get("last_applied_effects", last_applied_effects)
	if bool(patch.get("reset_slots", false)):
		_reset_slots()
	pending_slot = str(patch.get("pending_slot", pending_slot))
	numeric_roulette_index = int(patch.get("numeric_roulette_index", numeric_roulette_index))
	numeric_roulette_multiplier = float(patch.get("numeric_roulette_multiplier", numeric_roulette_multiplier))
	wager_marbles_committed = int(patch.get("wager_marbles_committed", wager_marbles_committed))
	numeric_next_go_available = bool(patch.get("numeric_next_go_available", numeric_next_go_available))
	numeric_go_chances_left = int(patch.get("numeric_go_chances_left", numeric_go_chances_left))
	numeric_pending_intervention_message = str(patch.get("numeric_pending_intervention_message", numeric_pending_intervention_message))
	numeric_go_used_this_spin = bool(patch.get("numeric_go_used_this_spin", numeric_go_used_this_spin))
	if bool(patch.get("sync_wager_marbles_visual", false)):
		_sync_wager_marbles_visual()
	banner_alpha = float(patch.get("banner_alpha", banner_alpha))
	run_over = bool(patch.get("run_over", run_over))
	phase = str(patch.get("phase", phase))

func _enemy_phase_brace() -> void:
	_enemy_action(3)

func _enemy_phase_take() -> void:
	_enemy_action(0)

func _open_enemy_intent_beat(reduction: int) -> void:
	_enemy_action(reduction)

func _apply_enemy_intent_result(result: Dictionary) -> void:
	var move_id: String = str(result.get("move_id", current_move_id))
	var reduction: int = int(result.get("reduction", 0))
	var move_result: Dictionary = _resolve_monster_move(move_id, reduction)
	var damage: int = int(move_result.get("damage", result.get("damage", 0)))
	last_turn_damage_taken = max(0, damage)
	player_hp = int(move_result.get("player_hp", result.get("player_hp", player_hp)))
	enemy_hp = int(move_result.get("enemy_hp", enemy_hp))
	enemy_damage_delta = int(move_result.get("enemy_damage_delta", 0))
	enemy_damage_multiplier = float(move_result.get("enemy_damage_multiplier", 1.0))
	enemy_block = int(move_result.get("enemy_block", enemy_block))
	player_attack_delta = int(move_result.get("player_attack_delta", player_attack_delta))
	player_damage_multiplier = float(move_result.get("player_damage_multiplier", player_damage_multiplier))
	enemy_intent_hidden_turns = max(enemy_intent_hidden_turns, int(move_result.get("hidden_intent_turns", 0)))
	player_block = int(move_result.get("player_block", player_block))
	cash = int(move_result.get("cash", cash))
	var move_gold_delta := int(move_result.get("gold_delta", 0))
	run_gold = int(move_result.get("run_gold", run_gold))
	gold_delta += move_gold_delta
	last_applied_effects = move_result.get("applied_effects", [])
	player_flash = 1.0 if damage > 0 else 0.0
	table_hit_flash = 1.0 if damage > 0 else 0.0
	opponent_reaction = 0.85
	opponent_mood = "press"
	enemy_intent = _intent_text_for_move(MonsterMoveCatalog.next_move_for_turn(move_pattern, turn))
	message = UiText.t("battle.message.enemy_action", {
		"monster": monster_name,
		"move": MonsterMoveCatalog.label(move_id),
		"block": int(move_result.get("block_absorbed", 0)),
		"damage": damage
	})
	_play_sfx("table_hit", 0.78, -6.0)
	run_over = not _combat_is_live()
	phase = "result"
	_render()
	_show_feedback_from_effects(last_applied_effects, "enemy_move")
	_emit_combat_finished_if_ready("enemy")

func _enemy_action(reduction: int) -> void:
	var move_result: Dictionary = _resolve_monster_move(current_move_id, reduction)
	var damage: int = int(move_result.get("damage", 0))
	last_turn_damage_taken = max(0, damage)
	player_hp = int(move_result.get("player_hp", player_hp))
	enemy_hp = int(move_result.get("enemy_hp", enemy_hp))
	enemy_damage_delta = int(move_result.get("enemy_damage_delta", 0))
	enemy_damage_multiplier = float(move_result.get("enemy_damage_multiplier", 1.0))
	enemy_block = int(move_result.get("enemy_block", enemy_block))
	player_attack_delta = int(move_result.get("player_attack_delta", player_attack_delta))
	player_damage_multiplier = float(move_result.get("player_damage_multiplier", player_damage_multiplier))
	enemy_intent_hidden_turns = max(enemy_intent_hidden_turns, int(move_result.get("hidden_intent_turns", 0)))
	player_block = int(move_result.get("player_block", player_block))
	cash = int(move_result.get("cash", cash))
	var move_gold_delta := int(move_result.get("gold_delta", 0))
	run_gold = int(move_result.get("run_gold", run_gold))
	gold_delta += move_gold_delta
	last_applied_effects = move_result.get("applied_effects", [])
	player_flash = 1.0 if damage > 0 else 0.0
	table_hit_flash = 1.0 if damage > 0 else 0.0
	opponent_reaction = 0.85
	opponent_mood = "press"
	enemy_intent = _intent_text_for_move(MonsterMoveCatalog.next_move_for_turn(move_pattern, turn))
	message = UiText.t("battle.message.enemy_action", {
		"monster": monster_name,
		"move": MonsterMoveCatalog.label(current_move_id),
		"block": int(move_result.get("block_absorbed", 0)),
		"damage": damage
	})
	_play_sfx("table_hit", 0.78, -6.0)
	run_over = not _combat_is_live()
	phase = "result"
	_render()
	_show_feedback_from_effects(last_applied_effects, "enemy_move")
	_emit_combat_finished_if_ready("enemy")

func _next_turn() -> void:
	turn += 1
	potion_menu_open = false
	current_move_id = MonsterMoveCatalog.move_for_turn(move_pattern, turn)
	enemy_intent = _intent_text_for_turn_start(current_move_id)
	phase = "dice"
	dice_rolled = false
	dice_relics_applied = false
	dice = DiceResolver.starting_values(dice_rule_id)
	dice_locked = DiceResolver.starting_locks(dice_rule_id)
	rerolls_left = int(DiceResolver.rule(dice_rule_id).get("rerolls", 2))
	attack_base = 0
	selected_attack_die_index = -1
	guard_value = 0
	player_block = 0
	black_signer_contract_id = ""
	selected_marble_slot_id = RouletteSlotCatalog.fallback_id()
	revealed_marbles.clear()
	selected_marble.clear()
	selected_marble_id = ""
	hovered_marble_choice_index = -1
	if _is_numeric_core():
		wager_marbles_available += 1
		wager_marbles_committed = 0
		numeric_roulette_index = -1
		numeric_roulette_multiplier = 1.0
		numeric_go_available = false
		numeric_next_go_available = true
		numeric_go_chances_left = 1
		numeric_go_per_turn_cap = 999
		numeric_pending_intervention_message = ""
		_sync_wager_marbles_visual()
	var turn_effects := _apply_turn_start_relics()
	banner_text = "DICE TIME"
	banner_alpha = 0.8
	opponent_mood = "watching"
	message = UiText.t("battle.message.turn_start")
	_render()
	_show_feedback_from_effects(turn_effects, "turn_start")

func _apply_turn_start_relics() -> Array:
	var turn_payload: Dictionary = RelicBridge.apply_turn_start({
		"turn": turn,
		"floor_index": floor_index,
		"cash": cash,
		"run_gold": run_gold,
		"gold_delta": gold_delta,
		"enemy_damage_delta": enemy_damage_delta,
		"enemy_damage_multiplier": enemy_damage_multiplier,
		"rerolls_left": rerolls_left,
		"uncommitted_wager_marbles": max(0, wager_marbles_available - wager_marbles_committed),
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"enemy_hp": enemy_hp,
		"player_block": player_block,
		"enemy_block": enemy_block,
		"player_attack_delta": player_attack_delta,
		"player_damage_multiplier": player_damage_multiplier,
		"relic_state": active_relic_state,
		"applied_effects": []
	}, active_relic_ids)
	cash = int(turn_payload.get("cash", cash))
	run_gold = int(turn_payload.get("run_gold", run_gold))
	enemy_damage_delta = int(turn_payload.get("enemy_damage_delta", enemy_damage_delta))
	enemy_damage_multiplier = float(turn_payload.get("enemy_damage_multiplier", enemy_damage_multiplier))
	player_hp = int(turn_payload.get("player_hp", player_hp))
	enemy_hp = int(turn_payload.get("enemy_hp", enemy_hp))
	player_block = int(turn_payload.get("player_block", player_block))
	enemy_block = int(turn_payload.get("enemy_block", enemy_block))
	player_attack_delta = int(turn_payload.get("player_attack_delta", player_attack_delta))
	player_damage_multiplier = float(turn_payload.get("player_damage_multiplier", player_damage_multiplier))
	rerolls_left = int(turn_payload.get("rerolls_left", rerolls_left))
	active_relic_state = turn_payload.get("relic_state", active_relic_state)
	last_applied_effects = turn_payload.get("applied_effects", [])
	return last_applied_effects

func _effective_attack_base() -> int:
	return max(0, attack_base + player_attack_delta)

func _intent_text_for_move(move_id: String) -> String:
	if enemy_intent_hidden_turns > 0:
		return MonsterMoveCatalog.hidden_intent_text()
	return MonsterMoveCatalog.intent_text(move_id, monster_pattern_tuning)

func _intent_text_for_turn_start(move_id: String) -> String:
	if enemy_intent_hidden_turns > 0:
		enemy_intent_hidden_turns -= 1
		return MonsterMoveCatalog.hidden_intent_text()
	return MonsterMoveCatalog.intent_text(move_id, monster_pattern_tuning)

func _preview_current_monster_move(reduction: int) -> Dictionary:
	return _resolve_monster_move_core(current_move_id, reduction, false)

func _resolve_monster_move(move_id: String, reduction: int) -> Dictionary:
	return _resolve_monster_move_core(move_id, reduction, true)

func _resolve_monster_move_core(move_id: String, reduction: int, apply_damage_taken: bool) -> Dictionary:
	var hoarded_pressure := _hoarded_wager_pressure()
	var result: Dictionary = MonsterMoveCatalog.resolve_enemy_turn(move_id, {
		"player_hp": player_hp,
		"player_block": player_block,
		"enemy_damage_delta": enemy_damage_delta + hoarded_pressure,
		"enemy_damage_multiplier": enemy_damage_multiplier,
		"enemy_hp": enemy_hp,
		"enemy_block": enemy_block,
		"player_attack_delta": player_attack_delta,
		"player_damage_multiplier": player_damage_multiplier,
		"run_gold": run_gold,
		"pattern_tuning": monster_pattern_tuning,
		"cash": cash,
		"last_attack_base": last_attack_base,
		"last_roulette_multiplier": last_roulette_multiplier,
		"last_wager_marbles_committed": last_wager_marbles_committed,
		"last_roulette_go_used": last_roulette_go_used
	}, reduction)
	_clear_transient_hoarded_pressure(move_id, result, hoarded_pressure)
	result["hoarded_wager_pressure"] = hoarded_pressure
	result["move_id"] = move_id
	result["reduction"] = reduction
	result["enemy_hp"] = enemy_hp
	result["relic_state"] = active_relic_state
	if apply_damage_taken:
		result = RelicBridge.apply_damage_taken(result, active_relic_ids)
		active_relic_state = result.get("relic_state", active_relic_state)
	return result

func _hoarded_wager_pressure() -> int:
	if not _is_numeric_core():
		return 0
	return min(HOARDED_WAGER_PRESSURE_CAP, max(0, wager_marbles_available))

func _clear_transient_hoarded_pressure(move_id: String, result: Dictionary, hoarded_pressure: int) -> void:
	if hoarded_pressure <= 0:
		return
	var move := MonsterMoveCatalog.tuned_move(move_id, monster_pattern_tuning)
	if int(move.get("damage", 0)) <= 0:
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) - hoarded_pressure

func _cash_out() -> void:
	var gained: int = cash
	banked += cash
	cash = 0
	run_over = true
	phase = "result"
	banner_text = "CASHED OUT $" + str(gained)
	banner_alpha = 1.0
	message = UiText.t("battle.message.cash_out")
	_play_sfx("coin_spill", 0.92, -5.0)
	_render()
	_emit_combat_finished_if_ready("cash_out")

func _emit_combat_finished_if_ready(reason: String) -> void:
	if combat_result_emitted or not run_over:
		return
	combat_result_emitted = true
	var result: Dictionary = CombatResultBuilder.build(reason, self)
	result = RelicBridge.apply_combat_finish(result, active_relic_ids)
	last_applied_effects = result.get("applied_effects", [])
	active_relic_state = result.get("relic_state", active_relic_state)
	cash = int(result.get("cash", cash))
	combat_finished.emit(result)

func _new_run() -> void:
	get_tree().reload_current_scene()

func _noop() -> void:
	pass

func _update_wheel_tick() -> void:
	var segment: int = int(floor(fposmod(wheel_angle, 360.0) / 12.0))
	if segment == wheel_tick_segment:
		return
	wheel_tick_segment = segment
	wheel_tick_flash = 1.0
	wheel_pointer_kick = 1.0
	var pitch: float = 0.8 + clamp(abs(wheel_angle) / 1200.0, 0.0, 0.45)
	_play_sfx("wheel_tick", pitch, -16.0)

func _spawn_coin_burst(amount: int) -> void:
	var count: int = clamp(6 + int(amount / 8), 8, 22)
	for i in range(count):
		var angle: float = rng.randf_range(-0.35, 0.35)
		var speed: float = rng.randf_range(170.0, 310.0)
		var particle: Dictionary = {
			"pos": Vector2(665, 340) + Vector2(rng.randf_range(-20.0, 20.0), rng.randf_range(-18.0, 18.0)),
			"vel": Vector2(cos(angle), sin(angle)) * speed + Vector2(250.0, rng.randf_range(-105.0, 90.0)),
			"life": rng.randf_range(0.55, 0.95),
			"max_life": 0.95,
			"radius": rng.randf_range(3.5, 6.5)
		}
		coin_particles.append(particle)

func _update_coin_particles(delta: float) -> void:
	for i in range(coin_particles.size() - 1, -1, -1):
		var particle: Dictionary = coin_particles[i]
		particle["life"] = float(particle["life"]) - delta
		if float(particle["life"]) <= 0.0:
			coin_particles.remove_at(i)
			continue
		var pos: Vector2 = particle["pos"]
		var vel: Vector2 = particle["vel"]
		vel.y += 360.0 * delta
		pos += vel * delta
		particle["pos"] = pos
		particle["vel"] = vel
		coin_particles[i] = particle

func _throw_marbles_to_wheel(colors: Array[String], release_pos: Vector2, throw_power: float) -> void:
	thrown_marbles.append_array(LegacySlotFlow.random_throw_particles(colors, release_pos, throw_power, rng))

func _place_marbles_to_wheel_slot(colors: Array[String], slot_id: String, release_pos: Vector2, throw_power: float = 1.0) -> void:
	thrown_marbles.append_array(LegacySlotFlow.particles_for_slot(colors, slot_id, release_pos, throw_power, rng))

func _spread_slot_for_marble(target_slot: String, index: int, count: int) -> String:
	return LegacySlotFlow.spread_slot_for_marble(target_slot, index, count)

func _landing_slot_for_marble(color: String, index: int, throw_power: float) -> String:
	return LegacySlotFlow.landing_slot_for_marble(color, index, throw_power, rng)

func _update_thrown_marbles(delta: float) -> void:
	var result := LegacySlotFlow.advance_thrown_marbles(thrown_marbles, delta)
	thrown_marbles = result.get("thrown_marbles", [])
	for marble in result.get("settled", []):
		_settle_thrown_marble(marble)
	if bool(result.get("finished", false)) and phase == "marble":
		_finish_marble_setup()

func _settle_thrown_marble(marble: Dictionary) -> void:
	var patch := LegacySlotFlow.settle_patch(marble, placed_slots)
	placed_slots = _normalize_slots(patch.get("placed_slots", placed_slots))
	slot_feedback_id = str(patch.get("slot_feedback_id", slot_feedback_id))
	slot_feedback_alpha = float(patch.get("slot_feedback_alpha", slot_feedback_alpha))
	marble_feedback_pos = patch.get("marble_feedback_pos", marble_feedback_pos)
	marble_feedback_color = _marble_color(str(patch.get("marble_feedback_color_id", "plain")))
	marble_feedback_alpha = float(patch.get("marble_feedback_alpha", marble_feedback_alpha))
	banner_text = str(patch.get("banner_text", banner_text))
	banner_alpha = max(banner_alpha, float(patch.get("banner_alpha_min", banner_alpha)))
	var cue: Dictionary = patch.get("audio_cue", {})
	if not cue.is_empty():
		var jitter := rng.randf_range(-float(cue.get("pitch_jitter", 0.0)), float(cue.get("pitch_jitter", 0.0)))
		_play_sfx(str(cue.get("key", "marble_drop")), float(cue.get("pitch", 1.0)) + jitter, float(cue.get("volume_db", -7.0)))

func _finish_marble_setup() -> void:
	var patch := LegacySlotFlow.finish_setup_patch(placed_slots)
	if not bool(patch.get("valid", false)):
		return
	spin_ready_flash = float(patch.get("spin_ready_flash", spin_ready_flash))
	banner_text = str(patch.get("banner_text", banner_text))
	banner_alpha = float(patch.get("banner_alpha", banner_alpha))
	message = str(patch.get("message", message))
	var cue: Dictionary = patch.get("audio_cue", {})
	if not cue.is_empty():
		_play_sfx(str(cue.get("key", "table_hit")), float(cue.get("pitch", 1.0)), float(cue.get("volume_db", -10.0)))
	_render()

func _marble_setup_ready() -> bool:
	return phase == "marble" and _placed_count() > 0 and thrown_marbles.is_empty() and not throwing_hand

func _ease_out(value: float) -> float:
	return 1.0 - pow(1.0 - value, 3.0)

func _weighted_pick() -> String:
	return RouletteResolver.weighted_pick(placed_slots, rng)

func _weights() -> Dictionary:
	return RouletteResolver.weights(placed_slots)

func _slot_percent(id: String) -> int:
	return RouletteResolver.slot_percent(id, placed_slots)

func _placed_count() -> int:
	return LegacySlotFlow.placed_count(placed_slots)

func _normalize_slots(value: Variant) -> Dictionary:
	return LegacySlotFlow.normalize_slots(value)

func _first_filled_slot() -> String:
	return LegacySlotFlow.first_filled_slot(placed_slots)

func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result

func _combat_potion_ids(value: Variant) -> Array[String]:
	var result: Array[String] = []
	for id in _string_array(value):
		if PotionCatalog.is_combat_potion(id):
			result.append(id)
	return result

func _int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for item in value:
			result.append(int(item))
	return result

func _upgrade_dict(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if value is Dictionary:
		for key in value.keys():
			result[str(key)] = float(value.get(key, 0.0))
	return result

func _reset_slots() -> void:
	placed_slots = LegacySlotFlow.empty_slots()

func _combat_is_live() -> bool:
	return enemy_hp > 0 and player_hp > 0 and busts < 2 and not run_over

func _all_dice_locked() -> bool:
	for locked in dice_locked:
		if not locked:
			return false
	return true

func _is_numeric_core() -> bool:
	return combat_core == "numeric_roulette"

func _phase_title() -> String:
	if phase == "dice":
		return UiText.t("battle.phase.dice")
	if phase == "marble_choice":
		return UiText.t("battle.phase.marble_choice")
	if phase == "marble":
		return UiText.t("battle.phase.marble")
	if phase == "wager":
		return UiText.t("battle.phase.wager")
	if phase == "spinning":
		return UiText.t("battle.phase.spinning")
	if phase == "intervene":
		return UiText.t("battle.phase.intervene")
	if phase == "enemy":
		return UiText.t("battle.phase.enemy")
	if run_over and enemy_hp <= 0:
		return UiText.t("battle.phase.win")
	if run_over:
		return UiText.t("battle.phase.end")
	return UiText.t("battle.phase.result")

func _next_intent_text() -> String:
	return EnemyIntentResolver.next_intent_text(rng)

func _slot_name(id: String) -> String:
	return RouletteSlotCatalog.label(id)

func _marble_name(color: String) -> String:
	if color == "plain":
		return UiText.t("battle.marble.plain")
	if color == "yellow":
		return UiText.t("battle.marble.yellow")
	if color == "green":
		return UiText.t("battle.marble.green")
	return UiText.t("battle.marble.purple")

func _marble_color(color: String) -> Color:
	if color == "yellow":
		return YELLOW
	if color == "green":
		return GREEN
	if color == "plain":
		return Color("#e8e0cf")
	return PURPLE

func _die_rect(index: int) -> Rect2:
	var gap: float = 14.0
	var die_size: float = 58.0
	var count: int = max(1, dice.size())
	var total_width: float = float(count) * die_size + float(count - 1) * gap
	var start_x: float = 281.0 - total_width * 0.5
	return Rect2(Vector2(start_x + float(index) * (die_size + gap), 542), Vector2(die_size, die_size))

func _hand_rect() -> Rect2:
	return Rect2(Vector2(822, 540), Vector2(230, 86))

func _roulette_spin_rect() -> Rect2:
	return Rect2(Vector2(440, 160), Vector2(400, 400))

func _marble_choice_rect(index: int) -> Rect2:
	return Rect2(Vector2(820, 176 + float(index) * 106.0), Vector2(292, 92))

func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not value is Array:
		return result
	for item in value:
		if item is Dictionary:
			result.append((item as Dictionary).duplicate(true))
	return result

func _hand_marble_pos(index: int) -> Vector2:
	return Vector2(1012 + float(index % 3) * 18.0, 570 + floor(float(index) / 3.0) * 18.0)

func _marble_pos(index: int) -> Vector2:
	return Vector2(1012 + float(index % 3) * 18.0, 570 + floor(float(index) / 3.0) * 18.0)

func _marble_index_at(pos: Vector2) -> int:
	for i in range(marbles.size()):
		if pos.distance_to(_marble_pos(i)) <= 15.0:
			return i
	return -1

func _slot_center(id: String) -> Vector2:
	return LegacySlotFlow.slot_center(id)

func _slot_at(pos: Vector2) -> String:
	return LegacySlotFlow.slot_at(pos)

func _slot_id_for_key(event: InputEventKey) -> String:
	return LegacySlotFlow.slot_id_for_key(event)

func _label(text: String, pos: Vector2, box: Vector2, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	prompt_layer.add_label(text, pos, box, font_size, color, align)
