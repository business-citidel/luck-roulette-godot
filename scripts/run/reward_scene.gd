extends Control

signal completed(result: Dictionary)

const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RelicPoolCatalog := preload("res://scripts/systems/relic_pool_catalog.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const DisplayBridge := preload("res://scripts/runtime/systems/game_object_display_bridge.gd")
const RunTableState := preload("res://scripts/run/run_table_state.gd")
const RunTableWidgets := preload("res://scripts/ui/run_table_widgets.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiLayoutSpec := preload("res://scripts/ui/ui_layout_spec.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const BG := Color("#07090f")
const TEXT := Color("#f6efe2")
const GOLD := Color("#f2be4b")
const GREEN := Color("#65d48e")
const INK := Color("#090704")

const BOARD_ITEM_RECTS := [
	Rect2(Vector2(320, 246), Vector2(204, 232)),
	Rect2(Vector2(538, 246), Vector2(204, 232)),
	Rect2(Vector2(756, 246), Vector2(204, 232))
]
const BOARD_TITLE_POS := Vector2(354, 126)
const BOARD_BODY_POS := Vector2(354, 168)
const BOARD_WINNINGS_POS := Vector2(356, 218)
const BOARD_SUMMARY_RECT := Rect2(Vector2(356, 512), Vector2(568, 84))
const CLAIM_RECT := Rect2(Vector2(916, 604), Vector2(194, 54))
const NORMAL_TICKET_BASE_CHANCE := 15
const NORMAL_TICKET_TURN_BONUS := 3
const NORMAL_TICKET_MAX_CHANCE := 35

var run_state: Dictionary = {}
var combat_result: Dictionary = {}
var buttons: Array[Button] = []
var submitted := false
var selected_choice := ""
var pickup_result: Dictionary = {}
var reward_result: Dictionary = {}
var reward_items: Array[Dictionary] = []

func configure(payload: Dictionary) -> void:
	run_state = payload.get("run_state", {}).duplicate(true)
	combat_result = payload.get("combat_result", {}).duplicate(true)
	reward_result = _build_reward_result()
	reward_items = _build_reward_items(reward_result)
	pickup_result = reward_result.duplicate(true)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if reward_result.is_empty():
		reward_result = _build_reward_result()
		reward_items = _build_reward_items(reward_result)
		pickup_result = reward_result.duplicate(true)
	_build_buttons()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	if not _draw_reward_board():
		UiSkin.draw_table_stage(self)
		UiSkin.draw_parchment_card(self, UiLayoutSpec.MODAL_FOCUS_PANEL, "large")
		_draw_text(UiText.t("reward.title"), Vector2(316, 146), 34, INK)
		_draw_text(UiText.t("reward.subtitle.claim_all"), Vector2(316, 186), 17, Color(INK, 0.72))
		RunTableWidgets.draw_result_summary(self, Rect2(Vector2(316, 344), Vector2(330, 96)), get_table_state().get("pickup", {}))
		return
	_draw_text(UiText.t("reward.title"), BOARD_TITLE_POS, 34, INK)
	_draw_text(UiText.t("reward.subtitle.claim_all"), BOARD_BODY_POS, 17, Color(INK, 0.72))
	_draw_text(UiText.t("reward.winnings", {"amount": _winnings()}), BOARD_WINNINGS_POS, 22, Color(INK, 0.62))
	for i in range(min(reward_items.size(), BOARD_ITEM_RECTS.size())):
		_draw_reward_item(BOARD_ITEM_RECTS[i], reward_items[i])
	RunTableWidgets.draw_result_summary(self, BOARD_SUMMARY_RECT, get_table_state().get("pickup", {}))

func _draw_reward_board() -> bool:
	var texture := AssetCatalog.reward_runtime_texture("reward_screen_full_board")
	if texture == null:
		return false
	draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, 0.96))
	return true

func _build_buttons() -> void:
	for button in buttons:
		button.queue_free()
	buttons.clear()
	var button := Button.new()
	button.name = "RunChoice_combat_reward"
	button.position = CLAIM_RECT.position
	button.size = CLAIM_RECT.size
	button.text = UiText.t("reward.claim")
	button.tooltip_text = UiText.t("reward.claim")
	UiSkin.apply_button(button, true)
	button.pressed.connect(_claim_reward)
	add_child(button)
	buttons.append(button)

func get_choice_controls() -> Array[Button]:
	return buttons

func get_choice_rect(index: int) -> Rect2:
	if index >= 0 and index < BOARD_ITEM_RECTS.size():
		return BOARD_ITEM_RECTS[index]
	return Rect2()

func get_table_state() -> Dictionary:
	return RunTableState.from_run_payload(run_state, pickup_result)

func get_pickup_summary() -> Dictionary:
	return get_table_state().get("pickup", {})

func _build_reward_result() -> Dictionary:
	var result := {
		"accepted": true,
		"choice": _reward_choice_id(),
		"reward_tier": _reward_tier(),
		"gold_delta": _winnings() + _bonus_gold(),
		"contract_tickets_delta": _ticket_reward(),
		"hp_delta": _bonus_heal(),
		"relic_ids": [],
		"next_combat_mods": [],
		"run_upgrades": {},
		"ticket_roll": _normal_ticket_roll() if not _grants_relic_reward() else -1,
		"ticket_chance": _normal_ticket_chance() if not _grants_relic_reward() else 100
	}
	if _grants_relic_reward():
		var relic_id := _next_relic_id()
		result["relic_ids"] = [relic_id] if relic_id != "" else []
	var preview := EffectResolver.apply_relic_trigger("reward_apply", result.merged({
		"seed_text": str(run_state.get("seed_text", "")),
		"player_hp": int(run_state.get("player_hp", 42)),
		"player_max_hp": int(run_state.get("player_max_hp", 42)),
		"contract_tickets": int(run_state.get("contract_tickets", 0)),
		"gold": int(run_state.get("gold", 0))
	}, true), run_state.get("relic_ids", []))
	preview["relic_reward_effects_applied"] = true
	return preview

func _build_reward_items(result: Dictionary) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var gold_amount := int(result.get("gold_delta", 0))
	if gold_amount != 0:
		items.append({
			"kind": "gold",
			"label": UiText.t("reward.item.gold"),
			"effect": "+" + str(gold_amount),
			"note": UiText.t("reward.item.gold.note")
		})
	var ticket_amount := int(result.get("contract_tickets_delta", 0))
	if ticket_amount != 0:
		items.append({
			"kind": "ticket",
			"label": UiText.t("reward.item.tickets"),
			"effect": "+" + str(ticket_amount),
			"note": UiText.t("reward.item.tickets.note")
		})
	var hp_amount := int(result.get("hp_delta", 0))
	if hp_amount != 0:
		items.append({
			"kind": "heal",
			"label": UiText.t("reward.item.heal"),
			"effect": "+" + str(hp_amount) + " HP",
			"note": UiText.t("reward.item.heal.note")
		})
	var relic_ids: Array = result.get("relic_ids", [])
	if not relic_ids.is_empty():
		var relic_id := str(relic_ids[0])
		var object_display := _relic_object_display(relic_id)
		items.append({
			"kind": "relic",
			"label": UiText.t("reward.item.relic"),
			"effect": str(object_display.get("name", RelicCatalog.display_name(relic_id))),
			"note": UiText.t("reward.item.relic.note"),
			"relic_id": relic_id,
			"object_id": relic_id,
			"object_kind": "relic",
			"object_display": object_display
		})
	return items

func _claim_reward() -> void:
	_complete_once(reward_result)

func _choose_default() -> void:
	_claim_reward()

func _choose_money() -> void:
	_claim_reward()

func _choose_relic() -> void:
	_claim_reward()

func _choose_heal() -> void:
	_claim_reward()

func _complete_once(result: Dictionary) -> void:
	if submitted:
		return
	submitted = true
	selected_choice = str(result.get("choice", ""))
	pickup_result = result.duplicate(true)
	for button in buttons:
		button.disabled = true
	queue_redraw()
	completed.emit(result)

func _draw_reward_item(rect: Rect2, item: Dictionary) -> void:
	var title_plate := Rect2(rect.position + Vector2(16, 12), Vector2(rect.size.x - 32, 52))
	draw_rect(title_plate, Color("#f0d7a5", 0.78), true)
	draw_rect(title_plate, Color("#4f3117", 0.34), false, 1.0)
	_draw_text(str(item.get("label", "")), title_plate.position + Vector2(12, 24), 15, INK, title_plate.size.x - 24)
	_draw_text(str(item.get("effect", "")), title_plate.position + Vector2(12, 43), 12, Color("#70490f", 0.88), title_plate.size.x - 24)
	var object_rect := Rect2(rect.position + Vector2((rect.size.x - 104.0) * 0.5, 78.0), Vector2(104, 104))
	_draw_reward_object(object_rect, item)
	var note_plate := Rect2(rect.position + Vector2(18, rect.size.y - 48), Vector2(rect.size.x - 36, 34))
	draw_rect(note_plate, Color("#07160d", 0.30), true)
	draw_rect(note_plate, Color("#d7aa4c", 0.22), false, 1.0)
	_draw_text(str(item.get("note", "")), note_plate.position + Vector2(10, 22), 10, Color("#f4dfb6", 0.86), note_plate.size.x - 20)

func _draw_reward_object(object_rect: Rect2, item: Dictionary) -> void:
	match str(item.get("kind", "")):
		"gold":
			var coin_texture := AssetCatalog.shop_runtime_texture("coin_stack")
			if coin_texture != null:
				draw_texture_rect(coin_texture, object_rect, false, Color(1, 1, 1, 0.92))
			else:
				UiSkin.draw_coin_marker(self, object_rect.get_center(), min(object_rect.size.x, object_rect.size.y) * 0.34, Color(GOLD, 0.88))
		"ticket":
			UiSkin.draw_ledger_slip(self, object_rect, Color(1, 1, 1, 0.90))
			draw_rect(object_rect.grow(-10.0), Color("#5a2619", 0.16), true)
			_draw_text(UiText.t("overlay.tickets"), object_rect.position + Vector2(18, 48), 17, Color("#7a311f"), object_rect.size.x - 36)
			_draw_text(str(item.get("effect", "")), object_rect.position + Vector2(34, 76), 22, Color("#7a311f"))
		"heal":
			var vial_texture := AssetCatalog.consumable_texture("red_vial_object")
			if vial_texture != null:
				draw_texture_rect(vial_texture, object_rect, false, Color(1, 1, 1, 0.92))
		"relic":
			var relic_id := str(item.get("relic_id", ""))
			var object_display: Dictionary = item.get("object_display", _relic_object_display(relic_id))
			var texture := AssetCatalog.relic_object(str(object_display.get("icon_id", RelicCatalog.icon_id(relic_id))))
			if texture != null:
				draw_texture_rect(texture, object_rect, false, Color(1, 1, 1, 0.92))

func _relic_object_display(relic_id: String) -> Dictionary:
	return DisplayBridge.surface_payload(relic_id, "relic", {
		"name": RelicCatalog.display_name(relic_id),
		"description": RelicCatalog.short_description(relic_id),
		"icon_id": RelicCatalog.icon_id(relic_id),
		"rarity": RelicCatalog.rarity(relic_id)
	})

func _next_relic_id() -> String:
	var existing_ids: Array = run_state.get("relic_ids", [])
	var candidate_count := 1 + _reward_option_bonus()
	var best_id := ""
	var best_score := -1
	for i in range(candidate_count):
		var candidate := RelicPoolCatalog.choose_reward_id(existing_ids, {
			"context": RelicPoolCatalog.CONTEXT_REWARD,
			"source_pool": _reward_source_pool(),
			"character_id": str(run_state.get("character_id", "")),
			"seed_text": str(run_state.get("seed_text", "reward")) + "|reward|" + str(combat_result.get("encounter_id", "")) + "|" + _reward_tier() + "|" + str(i)
		})
		var score := _relic_choice_score(candidate)
		if candidate != "" and score > best_score:
			best_id = candidate
			best_score = score
	return best_id

func _reward_option_bonus() -> int:
	var owned: Array = run_state.get("relic_ids", [])
	var bonus := 0
	if owned.has("appraisal_lens") and _reward_tier() != "boss":
		bonus += 1
	if _is_elite_reward() and owned.has("black_star_stub"):
		bonus += 1
	if _is_elite_reward() and owned.has("black_star_contract"):
		bonus += 1
	if _reward_tier() == "boss" and owned.has("boss_map_bounty"):
		bonus += 1
	return bonus

func _relic_choice_score(relic_id: String) -> int:
	if relic_id == "":
		return -1
	var score := 0
	match RelicCatalog.source_pool(relic_id):
		RelicCatalog.SOURCE_BOSS:
			score += 30
		RelicCatalog.SOURCE_RISK:
			score += 20
		_:
			score += 10
	match RelicCatalog.rarity(relic_id):
		"rare":
			score += 3
		"uncommon":
			score += 2
		_:
			score += 1
	return score

func _winnings() -> int:
	return int(combat_result.get("winnings", combat_result.get("combat_cash", combat_result.get("cash", 0))))

func _reward_tier() -> String:
	return str(combat_result.get("reward_tier", "elite" if str(combat_result.get("node_type", "")) == "elite" else "normal"))

func _is_elite_reward() -> bool:
	return _reward_tier() == "elite" or str(combat_result.get("node_type", "")) == "elite"

func _is_boss_reward() -> bool:
	var tier := _reward_tier()
	return tier == "boss" or tier == "final" or str(combat_result.get("node_type", "")) == "boss"

func _grants_relic_reward() -> bool:
	return _is_elite_reward() or _is_boss_reward()

func _reward_source_pool() -> String:
	if _is_boss_reward():
		return RelicCatalog.SOURCE_BOSS
	if _is_elite_reward():
		return RelicCatalog.SOURCE_RISK
	return RelicCatalog.SOURCE_BASIC

func _reward_choice_id() -> String:
	if _is_boss_reward():
		return "boss_reward"
	if _is_elite_reward():
		return "elite_reward"
	return "combat_reward"

func _ticket_reward() -> int:
	if _grants_relic_reward():
		return 1
	return 1 if _normal_ticket_roll() < _normal_ticket_chance() else 0

func _normal_ticket_chance() -> int:
	var clear_turn: int = max(0, int(combat_result.get("turn", combat_result.get("turns", 0))))
	var turn_bonus: int = min(clear_turn, 6) * NORMAL_TICKET_TURN_BONUS
	var base_chance: int = min(NORMAL_TICKET_MAX_CHANCE, NORMAL_TICKET_BASE_CHANCE + turn_bonus)
	return min(100, int(round(float(base_chance) * _reward_chance_multiplier())))

func _normal_ticket_roll() -> int:
	return _stable_roll("ticket", 100)

func _bonus_gold() -> int:
	if _is_elite_reward():
		return 0
	var roll: int = _stable_roll("bonus-kind", 100)
	var bonus_window: int = min(75, int(round(15.0 * _reward_chance_multiplier())))
	if roll >= 25 and roll < 25 + bonus_window:
		return 4 + _stable_roll("bonus-gold", 5)
	return 0

func _bonus_tickets() -> int:
	return 0

func _bonus_heal() -> int:
	if _is_elite_reward():
		return 0
	var current_hp := int(run_state.get("player_hp", 42))
	var max_hp := int(run_state.get("player_max_hp", 42))
	if current_hp >= max_hp:
		return 0
	var roll := _stable_roll("bonus-kind", 100)
	if roll < min(100, int(round(12.0 * _reward_chance_multiplier()))):
		return min(max_hp - current_hp, 2 + _stable_roll("bonus-heal", 2))
	return 0

func _reward_chance_multiplier() -> float:
	return max(1.0, float(combat_result.get("reward_chance_multiplier", 1.0)))

func _stable_roll(salt: String, modulo: int) -> int:
	var text := str(run_state.get("seed_text", "reward")) + "|" + str(combat_result.get("encounter_id", "")) + "|" + str(combat_result.get("monster_id", "")) + "|" + str(combat_result.get("turn", 0)) + "|" + salt
	var value := 0
	for i in range(text.length()):
		value = int((value * 31 + text.unicode_at(i)) % 2147483647)
	return value % max(1, modulo)

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color, width: float = -1.0) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)
