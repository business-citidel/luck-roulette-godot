extends SceneTree

const PromptPresenter := preload("res://scripts/battle/battle_prompt_presenter.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_dice_prompts()
	_check_marble_prompts()
	_check_numeric_prompts()
	if failures.is_empty():
		print("battle prompt presenter smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_dice_prompts() -> void:
	_assert_eq(PromptPresenter.action_prompt({"phase": "dice", "dice_rolled": false}), UiText.t("battle.prompt.roll"), "dice roll prompt")
	_assert_eq(PromptPresenter.action_prompt({
		"phase": "dice",
		"dice_rolled": true,
		"needs_attack_die_choice": true,
		"attack_die_choice_prompt": "Choose"
	}), "Choose", "attack die prompt")

func _check_marble_prompts() -> void:
	_assert_eq(PromptPresenter.action_prompt({"phase": "marble", "thrown_marbles": [{}]}), UiText.t("battle.prompt.marble_landing"), "marble landing prompt")
	_assert_eq(PromptPresenter.action_prompt({"phase": "marble", "marble_setup_ready": true}), UiText.t("battle.message.click_spin"), "marble spin prompt")
	_assert_eq(PromptPresenter.action_prompt({"phase": "marble"}), UiText.t("battle.message.click_marble_slot"), "marble slot prompt")

func _check_numeric_prompts() -> void:
	var wager_prompt := PromptPresenter.action_prompt({
		"phase": "wager",
		"wager_marbles_committed": 2,
		"wager_marbles_available": 4
	})
	_assert_eq(wager_prompt.contains("2"), true, "wager prompt committed")
	var intervene_prompt := PromptPresenter.action_prompt({
		"phase": "intervene",
		"is_numeric_core": true,
		"numeric_roulette_multiplier": 2.0,
		"wager_marbles_committed": 1,
		"numeric_preview_damage": 12
	})
	_assert_eq(intervene_prompt.contains("12"), true, "numeric preview damage")

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
