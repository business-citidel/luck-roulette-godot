class_name ShopOfferSlotNode
extends "res://scripts/ui/interactive_object_button.gd"

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RunChoice := preload("res://scripts/run/run_choice.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const TEXT := Color("#f6efe2")
const GOLD := Color("#f2be4b")
const RED := Color("#ee5b5b")
const INK := Color("#090704")

var choice_id := ""
var choice_data: Dictionary = {}
var product_kind := "relic"
var relic_id := ""
var icon_id := ""
var badge_id := ""
var object_texture_id := ""
var price := 0
var currency_id := "gold"
var slot_rect := Rect2()
var tag_rect := Rect2()
var visual_state := RunChoice.STATE_NORMAL

func configure_offer(choice: Dictionary, metadata: Dictionary, input_rect: Rect2, global_slot_rect: Rect2, global_tag_rect: Rect2) -> void:
	_sync_offer_data(choice, metadata)
	setup_object_button(input_rect)
	slot_rect = Rect2(global_slot_rect.position - input_rect.position, global_slot_rect.size)
	tag_rect = Rect2(global_tag_rect.position - input_rect.position, global_tag_rect.size)
	tooltip_text = _product_name() + "\n" + _product_effect()
	queue_redraw()

func set_offer_choice(choice: Dictionary) -> void:
	_sync_offer_data(choice)
	disabled = not RunChoice.is_interactive(choice)
	tooltip_text = _product_name() + "\n" + _product_effect()
	tween_visual_to(Vector2.ZERO, Vector2.ONE, 0.12)
	queue_redraw()

func _sync_offer_data(choice: Dictionary, metadata: Dictionary = {}) -> void:
	choice_data = choice.duplicate(true)
	choice_id = str(choice.get("id", ""))
	product_kind = str(metadata.get("kind", choice.get("slot_kind", "relic" if str(choice.get("relic_id", "")) != "" else "service")))
	relic_id = str(metadata.get("relic_id", choice.get("relic_id", "")))
	var result_value: Variant = choice.get("result", {})
	if relic_id == "" and result_value is Dictionary:
		var relic_ids: Array = (result_value as Dictionary).get("relic_ids", [])
		if not relic_ids.is_empty():
			relic_id = str(relic_ids[0])
	icon_id = str(metadata.get("icon_id", choice.get("icon_id", "")))
	badge_id = str(metadata.get("badge_id", choice.get("badge_id", "")))
	object_texture_id = str(metadata.get("object_texture_id", choice.get("object_texture_id", "")))
	price = int(metadata.get("price", choice.get("price", 0)))
	currency_id = str(metadata.get("currency", choice.get("currency", "gold")))
	if price <= 0 and result_value is Dictionary:
		price = abs(int((result_value as Dictionary).get("gold_delta", 0)))
	visual_state = str(choice.get("state", RunChoice.STATE_NORMAL))

func set_hovered(value: bool) -> void:
	if disabled or visual_state == RunChoice.STATE_SOLD or visual_state == RunChoice.STATE_DISABLED or visual_state == RunChoice.STATE_UNAFFORDABLE:
		return
	if value:
		visual_state = RunChoice.STATE_HOVER
		z_index = 20
		tween_visual_to(Vector2(0, -12), Vector2(1.035, 1.035), 0.12)
	else:
		visual_state = str(choice_data.get("state", RunChoice.STATE_NORMAL))
		z_index = 1
		tween_visual_to(Vector2.ZERO, Vector2.ONE, 0.12)
	queue_redraw()

func _ready() -> void:
	apply_transparent_object_style()

func _draw() -> void:
	var draw_slot := visual_rect(slot_rect)
	var draw_tag := visual_rect(tag_rect)
	var state := visual_state
	var unavailable := state == RunChoice.STATE_UNAFFORDABLE or state == RunChoice.STATE_DISABLED
	var sold := state == RunChoice.STATE_SOLD
	var selected := state == RunChoice.STATE_SELECTED or state == RunChoice.STATE_HOVER
	var tint := Color(1, 1, 1, 0.48) if unavailable or sold else Color(1, 1, 1, 0.92)
	var shadow := draw_slot.grow(10.0)
	draw_rect(Rect2(shadow.position + Vector2(7, 10), shadow.size), Color("#020201", 0.30 if selected else 0.22), true)
	if selected:
		draw_rect(draw_slot.grow(12.0), Color(GOLD, 0.17), true)
		draw_rect(draw_slot.grow(12.0), Color(GOLD, 0.70), false, 3.0)
	var slot_texture_id := "offer_slot_selected" if selected else "offer_slot_base"
	_draw_shop_texture(slot_texture_id, draw_slot, tint)
	_draw_product(draw_slot, tint)
	_draw_price_tag(draw_tag, tint, unavailable)
	if unavailable:
		_draw_shop_texture("wax_disabled", Rect2(draw_slot.position + Vector2(draw_slot.size.x - 42.0, 16.0), Vector2(38, 38)), Color(1, 1, 1, 0.78))
		draw_rect(draw_slot, Color("#111111", 0.30), true)
	if sold:
		draw_rect(draw_slot, Color("#ded4bb", 0.26), true)
		_draw_shop_texture("wax_sold", Rect2(draw_slot.position + Vector2(draw_slot.size.x - 44.0, 16.0), Vector2(42, 56)), Color(1, 1, 1, 0.88))

func _draw_product(rect: Rect2, tint: Color) -> void:
	if product_kind == "prep" or product_kind == "service" or product_kind == "special":
		_draw_service_header(Rect2(rect.position + Vector2(-7.0, 16.0), Vector2(rect.size.x + 14.0, 30.0)), tint)
		var object_rect := Rect2(rect.position + Vector2(rect.size.x * 0.5 - 48.0, 42.0), Vector2(96, 96))
		if not _draw_offer_object(object_rect, tint):
			var prep_rect := Rect2(rect.position + Vector2(rect.size.x * 0.5 - 34.0, 56.0), Vector2(68, 68))
			_draw_service_icon(prep_rect, tint)
		_draw_service_badge(Rect2(rect.position + Vector2(rect.size.x - 45.0, 17.0), Vector2(36, 36)), tint)
		_draw_text(_clip(_product_name(), 18), rect.position + Vector2(14, 150), 12, Color(TEXT, tint.a * 0.78), rect.size.x - 28.0)
		return
	var prop_rect := Rect2(rect.position + Vector2(rect.size.x * 0.5 - 48.0, 30.0), Vector2(96, 96))
	var texture := AssetCatalog.relic_object(RelicCatalog.icon_id(relic_id))
	if texture != null:
		draw_texture_rect(texture, prop_rect, false, tint)
	UiSkin.draw_coin_marker(self, prop_rect.position + Vector2(-10, 82), 9.0, tint)
	UiSkin.draw_coin_marker(self, prop_rect.position + Vector2(86, 82), 9.0, tint)
	_draw_text(_clip(_product_name(), 18), rect.position + Vector2(14, 150), 12, Color(TEXT, tint.a * 0.76), rect.size.x - 28.0)

func _draw_price_tag(rect: Rect2, tint: Color, unavailable: bool) -> void:
	_draw_shop_texture("price_tag_wide", rect, tint)
	if currency_id == "ticket":
		_draw_shop_texture("ticket_token_48", Rect2(rect.position + Vector2(18, 8), Vector2(28, 28)), Color(1, 1, 1, tint.a))
		_draw_text(str(price), rect.position + Vector2(54, 29), 16, Color("#f5d38f", tint.a), rect.size.x - 64.0)
	else:
		_draw_text(UiText.t("shop.gold_price", {"amount": price}), rect.position + Vector2(48, 28), 13, Color("#f5d38f", tint.a), rect.size.x - 58.0)
	if unavailable:
		_draw_text(UiText.t("shop.insufficient"), rect.position + Vector2(rect.size.x - 42.0, 28), 11, Color(RED, tint.a), 42.0)

func _product_name() -> String:
	if relic_id != "":
		return RelicCatalog.display_name(relic_id)
	return str(choice_data.get("label", UiText.t("shop.product_fallback")))

func _product_effect() -> String:
	if relic_id != "":
		return RelicCatalog.short_description(relic_id)
	return str(choice_data.get("effect", ""))

func _draw_service_icon(rect: Rect2, tint: Color) -> void:
	var texture := AssetCatalog.shop_runtime_texture("service_icon_" + icon_id)
	if texture != null:
		draw_texture_rect(texture, rect, false, tint)
		return
	var center := rect.get_center()
	var ink := Color("#130d08", tint.a * 0.9)
	var brass := Color("#d9ad55", tint.a)
	var red := Color("#9b2f2f", tint.a)
	draw_circle(center, rect.size.x * 0.45, Color("#2a2118", tint.a * 0.72))
	draw_arc(center, rect.size.x * 0.45, 0.0, TAU, 32, brass, 3.0)
	if icon_id == "cash_bait":
		for i in range(3):
			draw_circle(center + Vector2(float(i - 1) * 14.0, float(i % 2) * 8.0), 12.0, Color("#c99a3b", tint.a))
			draw_arc(center + Vector2(float(i - 1) * 14.0, float(i % 2) * 8.0), 12.0, 0.0, TAU, 24, ink, 2.0)
	elif icon_id == "roulette_tune" or icon_id == "risk_contract":
		draw_arc(center, 25.0, 0.0, TAU, 32, red, 7.0)
		draw_arc(center, 17.0, 0.0, TAU, 32, ink, 3.0)
		draw_line(center, center + Vector2(0, -23), brass, 4.0)
		draw_line(center, center + Vector2(20, 10), brass, 3.0)
	elif icon_id == "blood_discount":
		draw_rect(Rect2(rect.position + Vector2(12, 18), Vector2(44, 32)), Color("#d9c29a", tint.a * 0.9), true)
		draw_circle(center + Vector2(14, -5), 13.0, red)
		draw_arc(center + Vector2(14, -5), 13.0, 0.0, TAU, 24, ink, 2.0)
	else:
		var dice_texture := AssetCatalog.dice_face(2)
		if dice_texture != null:
			draw_texture_rect(dice_texture, rect.grow(-9.0), false, tint)
		else:
			draw_rect(rect.grow(-14.0), Color("#d9c29a", tint.a), true)
			draw_circle(center, 4.0, ink)

func _draw_offer_object(rect: Rect2, tint: Color) -> bool:
	if object_texture_id == "":
		return false
	var texture := AssetCatalog.shop_runtime_texture(object_texture_id)
	if texture == null:
		return false
	draw_texture_rect(texture, rect, false, tint)
	return true

func _draw_service_header(rect: Rect2, tint: Color) -> void:
	var header_id := badge_id
	if header_id == "discount":
		header_id = "limited"
	var texture := AssetCatalog.shop_runtime_texture("service_header_" + header_id)
	if texture == null and header_id != "ready":
		texture = AssetCatalog.shop_runtime_texture("service_header_ready")
	if texture != null:
		draw_texture_rect(texture, rect, false, Color(1, 1, 1, tint.a))

func _draw_service_badge(rect: Rect2, tint: Color) -> void:
	var texture := AssetCatalog.shop_runtime_texture("badge_" + badge_id)
	if texture != null:
		draw_texture_rect(texture, rect, false, tint)
		return
	var badge_color := Color("#d0a14a", tint.a)
	if badge_id == "gamble":
		badge_color = Color("#9b2f2f", tint.a)
	elif badge_id == "contract":
		badge_color = Color("#7c6f62", tint.a)
	elif badge_id == "special":
		badge_color = Color("#32794f", tint.a)
	draw_circle(rect.get_center(), min(rect.size.x, rect.size.y) * 0.42, badge_color)
	draw_arc(rect.get_center(), min(rect.size.x, rect.size.y) * 0.42, 0.0, TAU, 24, Color("#160d08", tint.a), 2.0)

func _draw_shop_texture(texture_id: String, rect: Rect2, tint: Color = Color.WHITE) -> bool:
	var texture := AssetCatalog.shop_runtime_texture(texture_id)
	if texture == null:
		return false
	draw_texture_rect(texture, rect, false, tint)
	return true

func _draw_text(value: String, pos: Vector2, font_size: int, color: Color, width: float = -1.0) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _clip(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	return value.substr(0, max_chars - 1) + "."
