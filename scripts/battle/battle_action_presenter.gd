class_name BattleActionPresenter
extends RefCounted

const PotionCatalog := preload("res://scripts/systems/potion_catalog.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

static func build(snapshot: Dictionary) -> Dictionary:
	if bool(snapshot.get("potion_menu_open", false)):
		return {"potion_menu": true, "buttons": [], "potion_entry": false}
	var phase := str(snapshot.get("phase", ""))
	var buttons: Array[Dictionary] = []
	var potion_entry := false
	match phase:
		"dice":
			potion_entry = _dice_buttons(snapshot, buttons)
		"marble":
			if bool(snapshot.get("marble_setup_ready", false)):
				buttons.append(_button(UiText.t("battle.action.spin"), "_open_roulette_spin_ritual", [], true, true))
			else:
				buttons.append(_button(UiText.t("battle.action.place_marble"), "_open_marble_throw_ritual", [], bool(snapshot.get("can_place_marble", false)), true))
			potion_entry = true
		"wager":
			buttons.append(_button(UiText.t("battle.action.go"), "_adjust_wager", [1], bool(snapshot.get("can_wager_go", false)), false))
			buttons.append(_button(UiText.t("battle.action.stop"), "_open_numeric_roulette_spin", [], true, true))
		"spinning":
			buttons.append(_button(UiText.t("battle.action.spinning"), "_noop", [], false, false))
		"intervene":
			if bool(snapshot.get("is_numeric_core", false)):
				buttons.append(_button(UiText.t("battle.action.go"), "_numeric_go", [], bool(snapshot.get("numeric_go_available", false)), false))
				buttons.append(_button(UiText.t("battle.action.stop"), "_resolve_numeric_pending", [], true, true))
				potion_entry = true
			else:
				buttons.append(_button(UiText.t("battle.action.apply_result"), "_resolve_pending", [], true, true))
				potion_entry = true
		"enemy":
			buttons.append(_button(UiText.t("battle.action.take"), "_enemy_phase_take", [], true, true))
			potion_entry = true
		"result":
			if bool(snapshot.get("run_over", false)):
				buttons.append(_button(UiText.t("battle.action.ack"), "_new_run", [], true, true))
			else:
				buttons.append(_button(UiText.t("battle.action.next_turn"), "_next_turn", [], true, true))
	return {"potion_menu": false, "buttons": buttons, "potion_entry": potion_entry}

static func _dice_buttons(snapshot: Dictionary, buttons: Array[Dictionary]) -> bool:
	if bool(snapshot.get("is_black_signer_rule", false)):
		buttons.append(_button(UiText.t("battle.action.black_sword"), "_select_black_signer_contract", ["sword"], true, true))
		buttons.append(_button(UiText.t("battle.action.black_shield"), "_select_black_signer_contract", ["shield"], true, false))
		buttons.append(_button(UiText.t("battle.action.black_roulette"), "_select_black_signer_contract", ["roulette"], true, false))
		return true
	if bool(snapshot.get("dice_roll_in_progress", false)):
		buttons.append(_button(UiText.t("battle.action.rolling"), "_noop", [], false, true))
		return false
	if not bool(snapshot.get("dice_rolled", false)):
		buttons.append(_button(UiText.t("battle.action.roll"), "_roll_dice", [], true, true))
		return true
	if bool(snapshot.get("needs_attack_die_choice", false)):
		for item in snapshot.get("attack_die_buttons", []):
			if item is Dictionary:
				buttons.append(_button(str((item as Dictionary).get("label", "")), "_select_attack_die", [int((item as Dictionary).get("index", 0))], true, bool((item as Dictionary).get("primary", false))))
		return true
	if bool(snapshot.get("is_dice_push_rule", false)):
		buttons.append(_button(UiText.t("battle.action.push_dice"), "_push_dice", [], bool(snapshot.get("can_push_dice", false)), false))
	else:
		buttons.append(_button(UiText.t("battle.action.reroll"), "_reroll_open", [], bool(snapshot.get("can_reroll", false)), false))
	buttons.append(_button(UiText.t("battle.action.confirm"), "_confirm_dice_result", [], true, true))
	return true

static func potion_menu_buttons(snapshot: Dictionary) -> Array[Dictionary]:
	var buttons: Array[Dictionary] = []
	var enabled_by_id: Dictionary = snapshot.get("potion_enabled", {})
	for potion_id in snapshot.get("active_potion_ids", []):
		var id := str(potion_id)
		buttons.append(_button(UiText.t(PotionCatalog.display_key(id)), "_use_potion", [id], bool(enabled_by_id.get(id, false)), false))
	buttons.append(_button(UiText.t("battle.action.back"), "_close_potion_menu", [], true, true))
	return buttons

static func _button(label: String, method: String, args: Array = [], enabled: bool = true, primary: bool = false) -> Dictionary:
	return {
		"label": label,
		"method": method,
		"args": args.duplicate(),
		"enabled": enabled,
		"primary": primary
	}
