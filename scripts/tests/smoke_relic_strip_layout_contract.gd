extends SceneTree

const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RunTableState := preload("res://scripts/run/run_table_state.gd")
const RunTableWidgets := preload("res://scripts/ui/run_table_widgets.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var tray_rects: Array[Dictionary] = [
		{"label": "rest/event", "rect": Rect2(Vector2(632, 344), Vector2(150, 86))},
		{"label": "battle hud", "rect": Rect2(Vector2(92, 84), Vector2(270, 56))},
		{"label": "map", "rect": Rect2(Vector2(108, 174), Vector2(298, 58))},
		{"label": "reward", "rect": Rect2(Vector2(628, 344), Vector2(310, 86))}
	]
	for tray in tray_rects:
		for count in [0, 1, 3, 4, RelicCatalog.all_ids().size(), 15]:
			_check_layout(str(tray.get("label", "")), tray.get("rect", Rect2()), _items(count))

	if failures.is_empty():
		print("relic strip layout contract smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_layout(label: String, rect: Rect2, items: Array) -> void:
	var entries := RunTableWidgets.relic_icon_rects(rect, items)
	for entry in entries:
		var icon_rect: Rect2 = entry.get("rect", Rect2())
		if not rect.encloses(icon_rect):
			failures.append(label + " icon rect escaped tray for count " + str(items.size()) + ": " + str(icon_rect))
	if items.is_empty() and not entries.is_empty():
		failures.append(label + " empty layout should not produce entries")
	if not items.is_empty() and entries.is_empty():
		failures.append(label + " non-empty layout should produce entries")
	if items.size() > entries.size():
		var last: Dictionary = entries[entries.size() - 1]
		if not bool(last.get("overflow", false)):
			failures.append(label + " overflowing layout should end with overflow marker")

func _items(count: int) -> Array:
	var ids := RelicCatalog.all_ids()
	var selected_ids: Array[String] = []
	for i in range(count):
		selected_ids.append(ids[i % ids.size()])
	return RunTableState.relic_items(selected_ids)
