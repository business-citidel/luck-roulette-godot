extends Control

signal completed(result: Dictionary)

const RunChoice := preload("res://scripts/run/run_choice.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiLayoutSpec := preload("res://scripts/ui/ui_layout_spec.gd")

const BG := Color("#07090f")
const INK := Color("#090704")

var buttons: Array[Button] = []
var choices: Array[Dictionary] = []
var submitted := false
var selected_choice := ""
var hovered_choice := ""

func configure(payload: Dictionary) -> void:
	var mode := str(payload.get("mode", "mixed"))
	if mode == "resolved":
		selected_choice = "sample_gold"
		submitted = true
	choices = _build_choices(mode)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if choices.is_empty():
		configure({})
	_build_buttons()
	queue_redraw()

func get_choice_controls() -> Array[Button]:
	return buttons

func _build_buttons() -> void:
	for button in buttons:
		button.queue_free()
	buttons.clear()
	for i in range(choices.size()):
		var choice := choices[i]
		var button := RunChoice.build_hit_button(
			choice,
			i,
			Callable(self, "_choose").bind(str(choice.get("id", ""))),
			choices.size(),
			Callable(self, "_hover_choice"),
			Callable(self, "_clear_hover")
		)
		add_child(button)
		buttons.append(button)

func _build_choices(mode: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		RunChoice.create("sample_gold", "골드 주머니", "카드 중앙을 누르면 선택된다.", "+9 골드", _result("sample_gold", 9), RunChoice.STATE_NORMAL, true),
		RunChoice.create("sample_locked", "봉인된 제안", "읽을 수 있지만 누를 수 없다.", "비활성", _result("sample_locked", 0), RunChoice.STATE_DISABLED, false),
		RunChoice.create("sample_sold", "이미 산 물건", "팔린 물건은 테이블에 남는다.", "판매 완료", _result("sample_sold", 0), RunChoice.STATE_SOLD, true)
	]
	if mode == "unaffordable":
		result[1]["state"] = RunChoice.STATE_UNAFFORDABLE
		result[1]["enabled"] = true
		result[1]["effect"] = "골드 부족"
	elif mode == "resolved":
		for choice in result:
			choice["state"] = RunChoice.state_after_submit(str(choice.get("id", "")), selected_choice)
			choice["enabled"] = false
	return result

func _result(choice_id: String, gold: int) -> Dictionary:
	return {
		"accepted": true,
		"choice": choice_id,
		"gold_delta": gold,
		"hp_delta": 0,
		"relic_ids": [],
		"next_combat_mods": []
	}

func _choose(choice_id: String) -> void:
	for choice in choices:
		if str(choice.get("id", "")) == choice_id:
			if not RunChoice.is_interactive(choice):
				return
			_complete_once(choice.get("result", {}))
			return

func _complete_once(result: Dictionary) -> void:
	if submitted:
		return
	submitted = true
	selected_choice = str(result.get("choice", ""))
	for i in range(choices.size()):
		choices[i]["state"] = RunChoice.state_after_submit(str(choices[i].get("id", "")), selected_choice)
		choices[i]["enabled"] = false
	for button in buttons:
		button.disabled = true
	queue_redraw()
	completed.emit(result)

func _hover_choice(choice_id: String) -> void:
	if submitted:
		return
	hovered_choice = choice_id
	queue_redraw()

func _clear_hover(choice_id: String) -> void:
	if hovered_choice == choice_id:
		hovered_choice = ""
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	UiSkin.draw_table_stage(self)
	_draw_text("RunChoice Fixture", Vector2(320, 154), 32, Color("#f6efe2"))
	_draw_text("보이는 카드 rect가 실제 버튼 rect와 같다.", Vector2(320, 188), 16, Color("#d8caa2", 0.78))
	for i in range(choices.size()):
		var choice := choices[i]
		var rect := RunChoice.hit_rect(i, choices.size())
		var state := str(choice.get("state", RunChoice.STATE_NORMAL))
		if hovered_choice == str(choice.get("id", "")) and RunChoice.is_interactive(choice):
			state = RunChoice.STATE_HOVER
		UiSkin.draw_offer_card(self, rect, state)
		_draw_text(str(choice.get("label", "")), rect.position + Vector2(24, 32), 16, INK)
		_draw_text(str(choice.get("note", "")), rect.position + Vector2(24, 58), 12, Color(INK, 0.58))
		_draw_text(str(choice.get("effect", "")), rect.position + Vector2(24, 82), 14, Color("#70490f", 0.82))

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
