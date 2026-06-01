extends SceneTree

const SHEETS := [
	{
		"file": "p1_group_01_alpha.png",
		"ids": ["carbon_copy_coupon", "voucher_coupon", "paper_shield", "wager_padding"]
	},
	{
		"file": "p1_group_02_alpha.png",
		"ids": ["jackpot_sparkler", "spare_heel", "thorn_chip", "glass_jackpot"]
	}
]

func _initialize() -> void:
	var project_dir := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var goal_root := project_dir.get_base_dir().get_base_dir()
	var source_dir := goal_root.path_join("assets/curated/luck-roulette-current/sprints/luck-roulette-visual-system-001/03-relic-and-reward-system/008-p1-relic-design-team-assets/sheets-alpha")
	var output_dirs := [
		goal_root.path_join("assets/runtime/relics"),
		goal_root.path_join("game/luck-roulette-godot/assets/runtime/relics")
	]
	for output_dir in output_dirs:
		DirAccess.make_dir_recursive_absolute(output_dir.path_join("icons"))
		DirAccess.make_dir_recursive_absolute(output_dir.path_join("objects"))
	for sheet in SHEETS:
		_extract_sheet(source_dir.path_join(str(sheet["file"])), sheet["ids"] as Array, output_dirs)
	print("p1 relic design assets extracted")
	quit(0)

func _extract_sheet(path: String, relic_ids: Array, output_dirs: Array) -> void:
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_error("failed to load " + path + ": " + str(err))
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	for index in range(relic_ids.size()):
		var relic_id := str(relic_ids[index])
		var x0 := int(round(float(width) * float(index) / 4.0))
		var x1 := int(round(float(width) * float(index + 1) / 4.0))
		var bbox := _alpha_bbox(image, Rect2i(x0, 0, x1 - x0, height))
		if bbox.size == Vector2i.ZERO:
			push_error("empty alpha slot for " + relic_id + " in " + path)
			quit(1)
			return
		var object_image: Image = _square_asset(image, bbox, 256, 0.88)
		var icon_image: Image = _square_asset(image, bbox, 128, 0.82)
		for output_dir in output_dirs:
			var output_path: String = str(output_dir)
			var object_path: String = output_path.path_join("objects/" + relic_id + "_object.png")
			var icon_path: String = output_path.path_join("icons/" + relic_id + "_icon.png")
			var object_err: Error = object_image.save_png(object_path)
			var icon_err: Error = icon_image.save_png(icon_path)
			if object_err != OK or icon_err != OK:
				push_error("failed to save runtime relic asset for " + relic_id)
				quit(1)
				return
		print(relic_id + " bbox=" + str(bbox))

func _alpha_bbox(image: Image, search: Rect2i) -> Rect2i:
	var min_x := search.position.x + search.size.x
	var min_y := search.position.y + search.size.y
	var max_x := search.position.x
	var max_y := search.position.y
	var found := false
	for y in range(search.position.y, search.position.y + search.size.y):
		for x in range(search.position.x, search.position.x + search.size.x):
			if image.get_pixel(x, y).a > 0.01:
				found = true
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x + 1)
				max_y = max(max_y, y + 1)
	if not found:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x, max_y - min_y)

func _square_asset(image: Image, bbox: Rect2i, size: int, fill_ratio: float) -> Image:
	var item: Image = image.get_region(bbox)
	var target: int = max(1, int(round(float(size) * fill_ratio)))
	var scale: float = min(float(target) / max(1.0, float(item.get_width())), float(target) / max(1.0, float(item.get_height())))
	var next_width: int = max(1, int(round(float(item.get_width()) * scale)))
	var next_height: int = max(1, int(round(float(item.get_height()) * scale)))
	item.resize(next_width, next_height, Image.INTERPOLATE_LANCZOS)
	var canvas: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	canvas.blit_rect(item, Rect2i(0, 0, next_width, next_height), Vector2i((size - next_width) / 2, (size - next_height) / 2))
	return canvas
