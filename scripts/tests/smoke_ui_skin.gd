extends SceneTree

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiLayoutSpec := preload("res://scripts/ui/ui_layout_spec.gd")

const EXPECTED_PHYSICAL_TEXTURES := [
	"parchment_card_small",
	"parchment_card_large",
	"ledger_slip",
	"prompt_strip",
	"plaque_primary",
	"plaque_secondary",
	"marker_coin",
	"marker_wax",
	"route_pin",
	"route_cord"
]

const EXPECTED_HELPERS := [
	"draw_table_stage",
	"draw_parchment_card",
	"draw_ledger_slip",
	"draw_plaque",
	"draw_coin_marker",
	"draw_wax_stamp",
	"draw_pin",
	"draw_route_cord",
	"draw_offer_card",
	"draw_resource_ledger",
	"draw_result_tray",
	"draw_state_token"
]

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(640, 360)
	_assert_physical_textures()
	var helper_names := _ui_skin_static_methods()
	_assert_ui_skin_helpers(helper_names)
	_assert_layout_spec()

	var fixture := PhysicalUiFixture.new()
	fixture.available_helpers = helper_names
	root.add_child(fixture)
	await process_frame
	await process_frame

	for failure in fixture.failures:
		failures.append(failure)

	fixture.queue_free()
	await process_frame

	if failures.is_empty():
		print("smoke_ui_skin: passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _assert_physical_textures() -> void:
	for texture_id in EXPECTED_PHYSICAL_TEXTURES:
		var path := AssetCatalog.physical_ui_texture_path(texture_id)
		if path == "":
			failures.append("missing physical UI texture id: " + texture_id)
			continue
		var texture := AssetCatalog.physical_ui_texture(texture_id)
		if texture == null:
			failures.append("missing physical UI texture file: " + texture_id + " at " + path)
			continue
		if texture.get_width() <= 0 or texture.get_height() <= 0:
			failures.append("invalid physical UI texture size: " + texture_id)

func _assert_ui_skin_helpers(helper_names: Array[String]) -> void:
	for helper in EXPECTED_HELPERS:
		if not helper_names.has(helper):
			failures.append("missing UiSkin helper: " + helper)

func _assert_layout_spec() -> void:
	if UiLayoutSpec.TABLE_STAGE.size != Vector2(1172, 590):
		failures.append("UiLayoutSpec.TABLE_STAGE size mismatch")
	if UiLayoutSpec.INNER_TABLE.position != Vector2(76, 88):
		failures.append("UiLayoutSpec.INNER_TABLE position mismatch")
	if UiLayoutSpec.PRIMARY_ACTION_ROW.size.y < 80.0:
		failures.append("UiLayoutSpec.PRIMARY_ACTION_ROW too short")
	if UiLayoutSpec.SMALL_CARD_SIZE != Vector2(222, 146):
		failures.append("UiLayoutSpec.SMALL_CARD_SIZE mismatch")
	if UiLayoutSpec.RUN_NODE_BUTTON_TALL_SIZE != Vector2(190, 76):
		failures.append("UiLayoutSpec.RUN_NODE_BUTTON_TALL_SIZE mismatch")

func _ui_skin_static_methods() -> Array[String]:
	var methods: Array[String] = []
	var skin = UiSkin.new()
	for method in skin.get_script().get_script_method_list():
		methods.append(str(method.get("name", "")))
	return methods

class PhysicalUiFixture:
	extends Control

	var failures: Array[String] = []
	var available_helpers: Array[String] = []
	var draw_count := 0

	func _init() -> void:
		custom_minimum_size = Vector2(640, 360)
		size = Vector2(640, 360)

	func _draw() -> void:
		_call_helper("draw_table_stage", [self, Rect2(Vector2(10, 10), Vector2(610, 330)), Rect2(Vector2(24, 24), Vector2(582, 302))])
		_call_helper("draw_parchment_card", [self, Rect2(Vector2(30, 28), Vector2(170, 128))])
		_call_helper("draw_ledger_slip", [self, Rect2(Vector2(220, 34), Vector2(178, 76))])
		_call_helper("draw_plaque", [self, Rect2(Vector2(420, 38), Vector2(164, 58)), true])
		_call_helper("draw_offer_card", [self, Rect2(Vector2(30, 166), Vector2(170, 96)), "chosen"])
		_call_helper("draw_resource_ledger", [self, Rect2(Vector2(220, 134), Vector2(178, 76))])
		_call_helper("draw_result_tray", [self, Rect2(Vector2(410, 126), Vector2(180, 62))])
		_call_helper("draw_coin_marker", [self, Vector2(84, 224), 22.0])
		_call_helper("draw_wax_stamp", [self, Vector2(176, 224), 24.0])
		_call_helper("draw_pin", [self, Vector2(292, 226), Color("#f2be4b")])
		_call_helper("draw_route_cord", [self, Vector2(350, 226), Vector2(560, 226)])
		_call_helper("draw_state_token", [self, Vector2(602, 224), "boss", 18.0])

	func _call_helper(helper: String, args: Array) -> void:
		if not available_helpers.has(helper):
			return
		var callable := Callable(UiSkin, helper)
		if not callable.is_valid():
			failures.append("UiSkin helper is not callable: " + helper)
			return
		callable.callv(args)
		draw_count += 1
