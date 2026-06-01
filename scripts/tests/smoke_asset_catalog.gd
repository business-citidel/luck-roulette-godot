extends SceneTree

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")

func _init() -> void:
	var ids: Dictionary = AssetCatalog.first_pass_asset_ids()
	for monster_id in ids["monsters"]:
		_assert_texture(AssetCatalog.monster_texture(str(monster_id)), "monster " + str(monster_id))
		var region: Rect2 = AssetCatalog.monster_region(str(monster_id))
		_assert(region.size.x > 0.0 and region.size.y > 0.0, "monster region should be non-empty for " + str(monster_id))
	for node_type in ids["node_types"]:
		_assert_texture(AssetCatalog.node_icon(str(node_type)), "node " + str(node_type))
	for prop_id in ids["props"]:
		_assert_texture(AssetCatalog.prop_icon(str(prop_id)), "prop " + str(prop_id))
	for relic_id in ids.get("relics", []):
		_assert_texture(AssetCatalog.relic_icon(str(relic_id)), "relic " + str(relic_id))
	for ui_id in ids["ui"]:
		_assert_texture(AssetCatalog.ui_texture(str(ui_id)), "ui " + str(ui_id))
	for physical_ui_id in ids.get("physical_ui", []):
		_assert_texture(AssetCatalog.physical_ui_texture(str(physical_ui_id)), "physical ui " + str(physical_ui_id))
	for map_node_kit_id in ids.get("map_node_kit", []):
		_assert_texture(AssetCatalog.map_node_kit_texture(str(map_node_kit_id)), "map node kit " + str(map_node_kit_id))
	for map_node_token_id in ids.get("map_node_tokens", []):
		_assert_texture(AssetCatalog.map_node_token_texture(str(map_node_token_id)), "map node token " + str(map_node_token_id))
	for shop_runtime_id in ids.get("shop_runtime", []):
		_assert_texture(AssetCatalog.shop_runtime_texture(str(shop_runtime_id)), "shop runtime " + str(shop_runtime_id))
	for rest_runtime_id in ids.get("rest_runtime", []):
		_assert_texture(AssetCatalog.rest_runtime_texture(str(rest_runtime_id)), "rest runtime " + str(rest_runtime_id))
	for event_runtime_id in ids.get("event_runtime", []):
		_assert_texture(AssetCatalog.event_runtime_texture(str(event_runtime_id)), "event runtime " + str(event_runtime_id))
	for relic_object_id in ids.get("relic_objects", []):
		_assert_texture(AssetCatalog.relic_object(str(relic_object_id)), "relic object " + str(relic_object_id))
	for relic_icon_override_id in ids.get("relic_icon_overrides", []):
		_assert_texture(AssetCatalog.relic_icon(str(relic_icon_override_id)), "runtime relic icon " + str(relic_icon_override_id))
	for consumable_id in ids.get("consumables", []):
		_assert_texture(AssetCatalog.consumable_texture(str(consumable_id)), "consumable " + str(consumable_id))
	for art_pack_id in ids.get("art_pack", []):
		_assert_texture(AssetCatalog.art_pack_texture(str(art_pack_id)), "art pack " + str(art_pack_id))
	for dice_motion_id in ids.get("dice_motion", []):
		var _ignored_id: String = str(dice_motion_id)
		_assert_texture(AssetCatalog.dice_motion_texture(), "dice motion spritesheet")
		_assert(AssetCatalog.dice_motion_region(0).size == Vector2(128, 128), "dice motion frame should be 128 square")
	for value in range(1, 7):
		_assert_texture(AssetCatalog.dice_face(value), "runtime dice face " + str(value))
	_assert_texture(AssetCatalog.combat_runtime_texture("dice_tray"), "runtime dice tray")
	_assert_texture(AssetCatalog.node_icon("missing_node_type"), "fallback node")
	_assert_texture(AssetCatalog.ui_texture("missing_ui_type"), "fallback ui")
	print("smoke_asset_catalog: passed")
	quit(0)

func _assert_texture(texture: Texture2D, label: String) -> void:
	_assert(texture != null, "missing texture for " + label)
	if texture == null:
		return
	_assert(texture.get_width() > 0 and texture.get_height() > 0, "invalid texture size for " + label)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
