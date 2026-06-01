class_name BattlePromptPresenter
extends RefCounted

const NumericRouletteResolver := preload("res://scripts/systems/numeric_roulette_resolver.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

static func action_prompt(snapshot: Dictionary) -> String:
	var phase := str(snapshot.get("phase", ""))
	if phase == "dice":
		if bool(snapshot.get("is_black_signer_rule", false)):
			return UiText.t("battle.message.black_signer_prompt")
		if not bool(snapshot.get("dice_rolled", false)):
			return UiText.t("battle.prompt.roll")
		if bool(snapshot.get("needs_attack_die_choice", false)):
			return str(snapshot.get("attack_die_choice_prompt", ""))
	if phase == "marble":
		if not (snapshot.get("thrown_marbles", []) as Array).is_empty():
			return UiText.t("battle.prompt.marble_landing")
		if bool(snapshot.get("marble_setup_ready", false)):
			return UiText.t("battle.message.click_spin")
		return UiText.t("battle.message.click_marble_slot")
	if phase == "marble_choice":
		return UiText.t("battle.prompt.choose_revealed_marble")
	if phase == "wager":
		var selected: Dictionary = snapshot.get("selected_marble", {})
		if not selected.is_empty():
			return UiText.t("battle.prompt.selected_marble_spin", {
				"marble": str(selected.get("short_name", selected.get("marble_id", "Marble")))
			})
		var committed := int(snapshot.get("wager_marbles_committed", 0))
		return UiText.t("battle.prompt.wager", {
			"committed": committed,
			"available": int(snapshot.get("wager_marbles_available", 0)),
			"multiplier": NumericRouletteResolver.multiplier_label(NumericRouletteResolver.wager_multiplier(committed))
		})
	if phase == "spinning":
		return UiText.t("battle.prompt.wait_result")
	if phase == "intervene":
		if bool(snapshot.get("is_numeric_core", false)):
			return UiText.t("battle.message.numeric_roulette_preview", {
				"roulette": NumericRouletteResolver.multiplier_label(float(snapshot.get("numeric_roulette_multiplier", 1.0))),
				"wager": NumericRouletteResolver.multiplier_label(NumericRouletteResolver.wager_multiplier(int(snapshot.get("wager_marbles_committed", 0)))),
				"damage": int(snapshot.get("numeric_preview_damage", 0))
			})
		return UiText.t("battle.prompt.apply_result")
	if phase == "enemy":
		return UiText.t("battle.prompt.enemy")
	if bool(snapshot.get("run_over", false)):
		return UiText.t("battle.prompt.run_over")
	return UiText.t("battle.prompt.next")
