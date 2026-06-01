class_name UiLayoutSpec
extends RefCounted

const CANVAS_SIZE := Vector2(1280, 720)

const TABLE_STAGE := Rect2(Vector2(54, 66), Vector2(1172, 590))
const INNER_TABLE := Rect2(Vector2(76, 88), Vector2(1128, 546))
const TOP_HUD_STRIP := Rect2(Vector2(32, 14), Vector2(1216, 76))
const BOTTOM_ACTION_ZONE := Rect2(Vector2(126, 602), Vector2(1028, 100))
const PRIMARY_ACTION_ROW := Rect2(Vector2(42, 616), Vector2(1196, 80))
const MODAL_FOCUS_PANEL := Rect2(Vector2(238, 82), Vector2(804, 378))
const SHELL_TITLE_CARD := Rect2(Vector2(260, 96), Vector2(760, 292))

const SMALL_CARD_SIZE := Vector2(222, 146)
const MAP_CARD_SIZE := Vector2(118, 152)
const MAP_CARD_MIN_SIZE := Vector2(140, 108)
const MAP_CARD_MAX_SIZE := Vector2(150, 120)
const LARGE_FOCUS_SHEET_SIZE := Vector2(804, 378)
const TITLE_CARD_SIZE := Vector2(760, 292)

const LEDGER_WIDE_SIZE := Vector2(606, 116)
const LEDGER_COMPACT_SIZE := Vector2(276, 126)
const BATTLE_INTENT_LEDGER_SIZE := Vector2(266, 78)

const COMBAT_BUTTON_SIZE := Vector2(248, 64)
const RUN_NODE_BUTTON_SIZE := Vector2(190, 54)
const RUN_NODE_BUTTON_TALL_SIZE := Vector2(190, 76)

const RESULT_TRAY := Rect2(Vector2(780, 306), Vector2(324, 114))
const OFFER_ROW_Y := 470.0
const OFFER_BUTTON_Y := 626.0
const BREATHING_ROOM := 24.0
const MAX_PRIMARY_CHOICES := 3

static func offer_card_rect(index: int, count: int = 3) -> Rect2:
	var card_count: int = max(1, count)
	var gap := 18.0
	var total_width := SMALL_CARD_SIZE.x * float(card_count) + gap * float(card_count - 1)
	var x := 640.0 - total_width * 0.5 + float(index) * (SMALL_CARD_SIZE.x + gap)
	return Rect2(Vector2(x, OFFER_ROW_Y), SMALL_CARD_SIZE)

static func centered_action_rect(index: int, count: int = 3, tall: bool = false) -> Rect2:
	var button_size := RUN_NODE_BUTTON_TALL_SIZE if tall else RUN_NODE_BUTTON_SIZE
	var button_count: int = max(1, count)
	var gap := 34.0
	var total_width := button_size.x * float(button_count) + gap * float(button_count - 1)
	var x := 640.0 - total_width * 0.5 + float(index) * (button_size.x + gap)
	var y := PRIMARY_ACTION_ROW.position.y + (PRIMARY_ACTION_ROW.size.y - button_size.y) * 0.5
	return Rect2(Vector2(x, y), button_size)

static func offer_button_rect(index: int, count: int = 3) -> Rect2:
	var button_count: int = max(1, count)
	var gap := 50.0
	var total_width := RUN_NODE_BUTTON_SIZE.x * float(button_count) + gap * float(button_count - 1)
	var x := 640.0 - total_width * 0.5 + float(index) * (RUN_NODE_BUTTON_SIZE.x + gap)
	return Rect2(Vector2(x, OFFER_BUTTON_Y), RUN_NODE_BUTTON_SIZE)
