extends SceneTree

const UiText := preload("res://scripts/ui/ui_text.gd")

var failures: Array[String] = []

func _initialize() -> void:
	UiText.set_locale("ko")
	if UiText.t("title.start") != "테이블에 앉기":
		failures.append("known key lookup returned unexpected value")
	if UiText.t("run_end.final_hp", {"hp": 7, "max_hp": 42}) != "최종 HP 7/42":
		failures.append("parameter substitution failed")
	if UiText.t("battle.action.roll") != "굴리기":
		failures.append("battle action key returned unexpected visible copy")
	if UiText.t("battle.prompt.roll") == "":
		failures.append("battle prompt key returned empty text")
	if UiText.t("character.default_guard_dice.name") != "공격/방어 계약":
		failures.append("character name key returned unexpected Korean copy")
	UiText.set_locale("en")
	if UiText.t("title.start") != "Take a Seat":
		failures.append("English title key returned unexpected visible copy")
	if UiText.t("run_end.final_hp", {"hp": 7, "max_hp": 42}) != "Final HP 7/42":
		failures.append("English parameter substitution failed")
	if UiText.t("character.default_guard_dice.name") != "Attack/Guard Contract":
		failures.append("character name key returned unexpected English copy")
	UiText.set_locale("ko")
	var missing := UiText.t("missing.example")
	if missing == "":
		failures.append("missing key returned empty string")
	if not missing.contains("[[missing.example]]"):
		failures.append("missing key fallback was not visible")
	if UiText.has("money") or UiText.has("shop_relic") or UiText.has("event_gold"):
		failures.append("gameplay action ids should not be localization keys")

	if failures.is_empty():
		print("ui text smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
