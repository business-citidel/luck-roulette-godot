extends SceneTree

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RunTableState := preload("res://scripts/run/run_table_state.gd")

func _initialize() -> void:
	var icon_id: String = RelicCatalog.icon_id("loaded_die")
	_assert(icon_id == "loaded_die", "loaded die should declare a relic icon id")
	_assert(AssetCatalog.relic_icon(icon_id) != null, "loaded die relic icon should load")
	_assert(RelicCatalog.shop_price("loaded_die") == 30, "loaded die should expose prototype shop price")

	var table_state: Dictionary = RunTableState.from_run_payload({
		"gold": 0,
		"player_hp": 42,
		"player_max_hp": 42,
		"relic_ids": ["loaded_die"],
		"next_combat_mods": []
	})
	var relic_tray: Array = table_state.get("relic_tray", [])
	_assert(relic_tray.size() == 1, "relic tray should include loaded die")
	_assert(str((relic_tray[0] as Dictionary).get("icon_id", "")) == "loaded_die", "relic tray item should carry loaded die icon id")

	print("loaded die relic token smoke passed")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
