extends SceneTree

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RunTableState := preload("res://scripts/run/run_table_state.gd")

func _initialize() -> void:
	var expected_relic_ids: Array[String] = RelicCatalog.all_ids()
	var seen_paths := {}
	for relic_id in expected_relic_ids:
		_assert(RelicCatalog.has_relic(relic_id), "relic catalog should include " + relic_id)
		var icon_id: String = RelicCatalog.icon_id(relic_id)
		_assert(icon_id == relic_id, relic_id + " should declare a matching icon id")
		var path: String = AssetCatalog.relic_icon_path(icon_id)
		var staged_asset := RelicCatalog.asset_status(relic_id) == "concept_sheet"
		if not staged_asset:
			_assert(path != AssetCatalog.RELIC_ICONS["fallback"], relic_id + " should not resolve to fallback icon")
			_assert(not seen_paths.has(path), relic_id + " should have a unique relic icon path")
			seen_paths[path] = true
		var icon := AssetCatalog.relic_icon(icon_id)
		_assert(icon != null, relic_id + " icon should load")
		if icon != null and not staged_asset:
			_assert(icon.get_width() == 128 and icon.get_height() == 128, relic_id + " icon should be 128 square")

	var table_state: Dictionary = RunTableState.from_run_payload({
		"gold": 0,
		"player_hp": 42,
		"player_max_hp": 42,
		"relic_ids": expected_relic_ids,
		"next_combat_mods": []
	})
	var relic_tray: Array = table_state.get("relic_tray", [])
	_assert(relic_tray.size() == expected_relic_ids.size(), "relic tray should include all mini icon relics")
	for i in range(relic_tray.size()):
		var item: Dictionary = relic_tray[i] as Dictionary
		_assert(str(item.get("icon_id", "")) == expected_relic_ids[i], "tray item should carry " + expected_relic_ids[i] + " icon id")

	print("relic mini icon batch smoke passed")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
