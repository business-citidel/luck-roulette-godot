extends Control

signal completed(result: Dictionary)

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const CharacterContractCatalog := preload("res://scripts/systems/character_contract_catalog.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const CharacterContractCardNode := preload("res://scripts/ui/character_contract_card_node.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const BG := Color("#05070d")
const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const INK := Color("#110b06")
const BLUE := Color("#9bc7e8")

const HERO_RECT := Rect2(Vector2(108, 104), Vector2(454, 470))
const DETAIL_RECT := Rect2(Vector2(760, 118), Vector2(380, 386))
const RAIL_RECT := Rect2(Vector2(214, 576), Vector2(568, 120))
const CARD_SIZE := Vector2(104, 104)

var select_button: Button
var confirm_button: Button
var contract_cards: Array[CharacterContractCardNode] = []
var selected_character_id: String = CharacterContractCatalog.default_character_id()
var accepted := false
var selected := false

func configure(payload: Dictionary) -> void:
	selected_character_id = str(payload.get("character_id", CharacterContractCatalog.default_character_id()))

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_contract_cards()
	_build_confirm_button()
	_set_preview_character(selected_character_id)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	var texture := AssetCatalog.character_runtime_texture("character_select_table_bg")
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false, Color(0.92, 0.92, 0.92, 1.0))
	else:
		_draw_fallback_table()
	_draw_composed_stage()
	_draw_detail_plaque()

func _build_contract_cards() -> void:
	contract_cards.clear()
	var card_specs := [
		{"id": CharacterContractCatalog.default_character_id(), "rect": Rect2(Vector2(252, 584), CARD_SIZE)},
		{"id": "double_attack_dice", "rect": Rect2(Vector2(382, 584), CARD_SIZE)},
		{"id": "black_signer_no_dice", "rect": Rect2(Vector2(512, 584), CARD_SIZE)},
		{"id": "future_luck_contract", "rect": Rect2(Vector2(642, 584), CARD_SIZE)}
	]
	for spec in card_specs:
		var card: CharacterContractCardNode = CharacterContractCardNode.new()
		var card_id := str(spec.get("id", ""))
		var card_rect: Rect2 = spec.get("rect", Rect2())
		card.configure_contract(card_id, card_rect)
		card.pressed.connect(_select_character.bind(card_id))
		add_child(card)
		contract_cards.append(card)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_confirm_selected_character()

func _build_confirm_button() -> void:
	confirm_button = Button.new()
	confirm_button.name = "ConfirmContractButton"
	confirm_button.text = UiText.t("character.select.confirm")
	confirm_button.position = Vector2(838, 612)
	confirm_button.size = Vector2(246, 58)
	confirm_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UiSkin.apply_button(confirm_button, true)
	confirm_button.pressed.connect(_confirm_selected_character)
	add_child(confirm_button)
	select_button = confirm_button

func _select_default_character() -> void:
	_set_preview_character(CharacterContractCatalog.default_character_id())
	_confirm_selected_character()

func _select_character(character_id: String) -> void:
	_set_preview_character(character_id)

func _set_preview_character(character_id: String) -> void:
	if accepted:
		return
	var character := CharacterContractCatalog.get_character(character_id)
	if not _can_preview_character(character):
		return
	selected_character_id = str(character.get("id", character_id))
	for card in contract_cards:
		card.set_selected(card.character_id == selected_character_id)
	if confirm_button != null:
		confirm_button.disabled = not _can_confirm_character(character)
	queue_redraw()

func _confirm_selected_character() -> void:
	if accepted:
		return
	var character := CharacterContractCatalog.get_character(selected_character_id)
	if not _can_confirm_character(character):
		return
	accepted = true
	selected = true
	if confirm_button != null:
		confirm_button.disabled = true
	completed.emit({
		"accepted": true,
		"action": "character_selected",
		"character_id": str(character.get("id", selected_character_id)),
		"dice_rule_id": str(character.get("dice_rule_id", "two_dice_attack_guard"))
	})

func _can_preview_character(character: Dictionary) -> bool:
	return bool(character.get("enabled", false)) or bool(character.get("preview_enabled", false))

func _can_confirm_character(character: Dictionary) -> bool:
	return bool(character.get("enabled", false))

func _draw_detail_plaque() -> void:
	var character := CharacterContractCatalog.get_character(selected_character_id)
	_draw_text(UiText.t("character.select.title"), Vector2(74, 64), 32, TEXT, 420.0, HORIZONTAL_ALIGNMENT_LEFT)
	UiSkin.draw_panel(self, DETAIL_RECT, GOLD, 0.82)
	_draw_text(str(character.get("name", "")), DETAIL_RECT.position + Vector2(28, 52), 25, GOLD, DETAIL_RECT.size.x - 56.0)
	_draw_text(str(character.get("subtitle", "")), DETAIL_RECT.position + Vector2(28, 92), 16, Color(TEXT, 0.90), DETAIL_RECT.size.x - 56.0)
	UiSkin.draw_divider(self, DETAIL_RECT.position + Vector2(DETAIL_RECT.size.x * 0.5, 122), DETAIL_RECT.size.x - 62.0, GOLD)
	_draw_wrapped_text(str(character.get("rule_text", "")), DETAIL_RECT.position + Vector2(28, 164), 15, Color(TEXT, 0.82), DETAIL_RECT.size.x - 56.0, 5)
	_draw_starting_relic(character, DETAIL_RECT.position + Vector2(28, 286), DETAIL_RECT.size.x - 56.0)
	_draw_text(UiText.t("character.select.hint"), DETAIL_RECT.position + Vector2(28, 360), 13, Color(TEXT, 0.66), DETAIL_RECT.size.x - 56.0)

func _draw_composed_stage() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#020204", 0.22), true)
	var hero_panel := HERO_RECT.grow(20.0)
	UiSkin.draw_panel(self, hero_panel, GOLD, 0.72)
	_draw_character_hero(HERO_RECT, selected_character_id)
	draw_rect(HERO_RECT.grow(4.0), Color(GOLD, 0.74), false, 2.0)
	draw_rect(RAIL_RECT.grow(10.0), Color("#040506", 0.42), true)
	draw_rect(RAIL_RECT.grow(10.0), Color(GOLD, 0.22), false, 2.0)
	draw_rect(RAIL_RECT.grow(-8.0), Color("#040506", 0.18), true)

func _draw_character_hero(rect: Rect2, character_id: String) -> void:
	var texture := AssetCatalog.character_runtime_texture(character_id + "_hero")
	if texture == null:
		return
	var source_size := texture.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return
	var target_aspect := rect.size.x / rect.size.y
	var source_aspect := source_size.x / source_size.y
	var src := Rect2(Vector2.ZERO, source_size)
	if source_aspect > target_aspect:
		var crop_w := source_size.y * target_aspect
		src.position.x = (source_size.x - crop_w) * 0.5
		src.size.x = crop_w
	else:
		var crop_h := source_size.x / target_aspect
		src.position.y = max(0.0, (source_size.y - crop_h) * 0.18)
		src.size.y = min(source_size.y, crop_h)
	draw_texture_rect_region(texture, rect, src, Color.WHITE)
	var gradient_steps := 8
	for i in range(gradient_steps):
		var alpha := float(i) / float(gradient_steps) * 0.34
		draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 130.0 + i * 16.0), Vector2(rect.size.x, 18.0)), Color("#020204", alpha), true)

func _draw_starting_relic(character: Dictionary, pos: Vector2, width: float) -> void:
	var relic_ids: Array = character.get("starting_relic_ids", [])
	if relic_ids.is_empty():
		return
	var relic_id := str(relic_ids[0])
	var icon := AssetCatalog.relic_icon(RelicCatalog.icon_id(relic_id))
	var panel := Rect2(pos, Vector2(width, 58.0))
	draw_rect(panel, Color("#05070d", 0.42), true)
	draw_rect(panel, Color(GOLD, 0.34), false, 1.0)
	_draw_text(UiText.t("character.starting_relic.label"), pos + Vector2(0, 12), 11, Color(GOLD, 0.9), width)
	if icon != null:
		draw_texture_rect(icon, Rect2(pos + Vector2(0, 18), Vector2(34, 34)), false, Color.WHITE)
	_draw_text(RelicCatalog.display_name(relic_id), pos + Vector2(44, 30), 14, TEXT, width - 44.0)
	_draw_text(RelicCatalog.short_description(relic_id), pos + Vector2(44, 49), 11, Color(TEXT, 0.72), width - 44.0)

func _draw_fallback_table() -> void:
	UiSkin.draw_table_stage(self, Rect2(Vector2(52, 52), Vector2(1176, 616)), Rect2(Vector2(84, 82), Vector2(1112, 556)), Color(1, 1, 1, 0.94))
	var center_card := Rect2(Vector2(480, 174), Vector2(320, 398))
	UiSkin.draw_parchment_card(self, center_card, "large", Color(1, 1, 1, 0.92))
	draw_rect(center_card.grow(8), Color(GOLD, 0.76), false, 3.0)
	var left := Rect2(Vector2(238, 216), Vector2(254, 318))
	var right := Rect2(Vector2(788, 216), Vector2(254, 318))
	UiSkin.draw_parchment_card(self, left, "large", Color(1, 1, 1, 0.36))
	UiSkin.draw_parchment_card(self, right, "large", Color(1, 1, 1, 0.36))
	_draw_text("LOCKED", left.position + Vector2(76, 166), 20, Color(INK, 0.54), 120.0)
	_draw_text("LOCKED", right.position + Vector2(76, 166), 20, Color(INK, 0.54), 120.0)

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color, width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, align, width, font_size, color)

func _draw_wrapped_text(text: String, pos: Vector2, font_size: int, color: Color, width: float, max_lines: int) -> void:
	var words := _wrap_units(text)
	var line := ""
	var y := pos.y
	var line_height := float(font_size) + 8.0
	var lines_drawn := 0
	for word in words:
		var next_line := word if line == "" else line + word
		if ThemeDB.fallback_font.get_string_size(next_line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > width and line != "":
			_draw_text(line, Vector2(pos.x, y), font_size, color, width)
			lines_drawn += 1
			if lines_drawn >= max_lines:
				return
			line = word
			y += line_height
		else:
			line = next_line
	if line != "" and lines_drawn < max_lines:
		_draw_text(line, Vector2(pos.x, y), font_size, color, width)

func _wrap_units(text: String) -> Array[String]:
	var result: Array[String] = []
	var current := ""
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		current += ch
		if ch == " ":
			result.append(current)
			current = ""
	if current != "":
		result.append(current)
	return result
