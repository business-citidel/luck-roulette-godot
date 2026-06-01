extends SceneTree

const PROP_SOURCE := "res://../../assets/curated/luck-roulette-current/sprints/luck-roulette-visual-system-001/04-shop-event-rest-system/004-reward-event-choice-paperwork-kit/variants/event_prop_pack_sample_001.png"
const MAP_CARD_FRONT := "res://assets/runtime/map/cards/node_card_front_base.png"
const MAP_CARD_BACK := "res://assets/runtime/map/cards/node_card_back_covered.png"
const PROJECT_RUNTIME_ROOT := "res://assets/runtime/event/"
const SHARED_RUNTIME_ROOT := "res://../../assets/runtime/event/"

const PROP_SPECS := [
	{
		"id": "props/roulette_medallion",
		"rect": Rect2i(620, 388, 228, 228),
		"size": Vector2i(360, 360),
		"mask": "dark_ellipse"
	},
	{
		"id": "props/dice_table",
		"rect": Rect2i(66, 386, 538, 236),
		"size": Vector2i(680, 300),
		"mask": "dark_soft_rect"
	},
	{
		"id": "props/choice_slip",
		"rect": Rect2i(786, 654, 246, 212),
		"size": Vector2i(256, 196),
		"mask": "dark_soft_rect"
	}
]

const CARD_SPECS := [
	{
		"id": "props/card_front",
		"path": MAP_CARD_FRONT,
		"size": Vector2i(256, 384),
		"back": false
	},
	{
		"id": "props/card_back",
		"path": MAP_CARD_FRONT,
		"size": Vector2i(256, 384),
		"back": true
	}
]

func _initialize() -> void:
	_prepare_dirs()
	var source := Image.new()
	var err := source.load(ProjectSettings.globalize_path(PROP_SOURCE))
	if err != OK:
		push_error("failed to load event prop pack: " + PROP_SOURCE + " err=" + str(err))
		quit(1)
		return
	var preview_items: Array[Dictionary] = []
	for spec in PROP_SPECS:
		var image := _extract_prop(source, spec["rect"], spec["size"], spec["mask"])
		_save_to_roots(str(spec["id"]) + ".png", image)
		preview_items.append({"id": str(spec["id"]), "image": image})
		print("wrote " + str(spec["id"]) + ".png")
	for spec in CARD_SPECS:
		var image := _extract_card(str(spec["path"]), spec["size"], bool(spec.get("back", false)))
		_save_to_roots(str(spec["id"]) + ".png", image)
		preview_items.append({"id": str(spec["id"]), "image": image})
		print("wrote " + str(spec["id"]) + ".png")
	_save_preview(preview_items)
	print("event prop pack runtime props extracted")
	quit(0)

func _prepare_dirs() -> void:
	for root in [PROJECT_RUNTIME_ROOT, SHARED_RUNTIME_ROOT]:
		for subdir in ["props", "previews"]:
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root + subdir))

func _extract_prop(source: Image, rect: Rect2i, target_size: Vector2i, mask: String) -> Image:
	var image := source.get_region(rect)
	image.convert(Image.FORMAT_RGBA8)
	if mask.begins_with("dark"):
		_apply_dark_key(image)
	image = _trim_alpha(image, 2)
	_contain(image, target_size)
	match mask:
		"dark_ellipse":
			_apply_ellipse_mask(image, 0.47, 0.47)
		"dark_soft_rect":
			_apply_soft_rect_mask(image, 0.035)
	return image

func _extract_card(path: String, target_size: Vector2i, back: bool) -> Image:
	var image := Image.new()
	var err := image.load(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("failed to load card source: " + path + " err=" + str(err))
		return Image.create(target_size.x, target_size.y, false, Image.FORMAT_RGBA8)
	image.convert(Image.FORMAT_RGBA8)
	_remove_green_chroma(image)
	image = _trim_alpha(image, 2)
	_contain(image, target_size)
	if back:
		_make_card_back(image)
	return image

func _make_card_back(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			var tint := Color(0.34, 0.22, 0.11, 1.0)
			color.r = lerp(color.r, tint.r, 0.40)
			color.g = lerp(color.g, tint.g, 0.40)
			color.b = lerp(color.b, tint.b, 0.40)
			color.r *= 0.68
			color.g *= 0.66
			color.b *= 0.62
			image.set_pixel(x, y, color)
	var line_color := Color(0.84, 0.62, 0.28, 0.20)
	_draw_line(image, Vector2i(64, 72), Vector2i(image.get_width() - 64, image.get_height() - 72), line_color, 3)
	_draw_line(image, Vector2i(image.get_width() - 64, 72), Vector2i(64, image.get_height() - 72), line_color, 3)

func _contain(image: Image, target_size: Vector2i) -> void:
	var source_size := image.get_size()
	var scale: float = min(float(target_size.x) / max(1.0, float(source_size.x)), float(target_size.y) / max(1.0, float(source_size.y))) * 0.96
	var next_size := Vector2i(max(1, int(float(source_size.x) * scale)), max(1, int(float(source_size.y) * scale)))
	image.resize(next_size.x, next_size.y, Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(target_size.x, target_size.y, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	var pos := Vector2i((target_size.x - next_size.x) / 2, (target_size.y - next_size.y) / 2)
	_blend(canvas, image, pos)
	image.copy_from(canvas)

func _trim_alpha(image: Image, pad: int) -> Image:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.02:
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
	if max_x < min_x or max_y < min_y:
		return image
	min_x = max(0, min_x - pad)
	min_y = max(0, min_y - pad)
	max_x = min(image.get_width() - 1, max_x + pad)
	max_y = min(image.get_height() - 1, max_y + pad)
	return image.get_region(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))

func _apply_dark_key(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			var brightness: float = max(color.r, max(color.g, color.b))
			var alpha: float = smoothstep(0.05, 0.20, brightness)
			color.a *= alpha
			image.set_pixel(x, y, color)

func _remove_green_chroma(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			var green_bias: float = color.g - max(color.r, color.b)
			if color.g > 0.42 and green_bias > 0.18:
				color.a = 0.0
			image.set_pixel(x, y, color)

func _apply_ellipse_mask(image: Image, radius_x: float, radius_y: float) -> void:
	var center := Vector2(float(image.get_width() - 1) * 0.5, float(image.get_height() - 1) * 0.5)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var normalized := Vector2((float(x) - center.x) / (float(image.get_width()) * radius_x), (float(y) - center.y) / (float(image.get_height()) * radius_y))
			var distance := normalized.length()
			var alpha: float = clamp((1.0 - distance) * 24.0, 0.0, 1.0)
			var color := image.get_pixel(x, y)
			color.a *= alpha
			image.set_pixel(x, y, color)

func _apply_soft_rect_mask(image: Image, edge_ratio: float) -> void:
	var edge: float = min(float(image.get_width()), float(image.get_height())) * edge_ratio
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var edge_distance: float = min(min(float(x), float(image.get_width() - 1 - x)), min(float(y), float(image.get_height() - 1 - y)))
			var alpha: float = clamp(edge_distance / max(1.0, edge), 0.0, 1.0)
			var color := image.get_pixel(x, y)
			color.a *= alpha
			image.set_pixel(x, y, color)

func _blend(dst: Image, src: Image, pos: Vector2i) -> void:
	for y in range(src.get_height()):
		for x in range(src.get_width()):
			var target := pos + Vector2i(x, y)
			if target.x < 0 or target.y < 0 or target.x >= dst.get_width() or target.y >= dst.get_height():
				continue
			var source_color := src.get_pixel(x, y)
			if source_color.a <= 0.0:
				continue
			var base := dst.get_pixel(target.x, target.y)
			var out_a := source_color.a + base.a * (1.0 - source_color.a)
			if out_a <= 0.0:
				dst.set_pixel(target.x, target.y, Color(0, 0, 0, 0))
				continue
			var out := Color(
				(source_color.r * source_color.a + base.r * base.a * (1.0 - source_color.a)) / out_a,
				(source_color.g * source_color.a + base.g * base.a * (1.0 - source_color.a)) / out_a,
				(source_color.b * source_color.a + base.b * base.a * (1.0 - source_color.a)) / out_a,
				out_a
			)
			dst.set_pixel(target.x, target.y, out)

func _draw_line(image: Image, from_pos: Vector2i, to_pos: Vector2i, color: Color, width: int) -> void:
	var delta: Vector2i = to_pos - from_pos
	var steps: int = max(abs(delta.x), abs(delta.y))
	if steps <= 0:
		return
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var center := Vector2i(roundi(lerpf(float(from_pos.x), float(to_pos.x), t)), roundi(lerpf(float(from_pos.y), float(to_pos.y), t)))
		for oy in range(-width, width + 1):
			for ox in range(-width, width + 1):
				if Vector2(float(ox), float(oy)).length() > float(width):
					continue
				var p := center + Vector2i(ox, oy)
				if p.x < 0 or p.y < 0 or p.x >= image.get_width() or p.y >= image.get_height():
					continue
				var base := image.get_pixel(p.x, p.y)
				var out_a := color.a + base.a * (1.0 - color.a)
				if out_a <= 0.0:
					continue
				image.set_pixel(p.x, p.y, Color(
					(color.r * color.a + base.r * base.a * (1.0 - color.a)) / out_a,
					(color.g * color.a + base.g * base.a * (1.0 - color.a)) / out_a,
					(color.b * color.a + base.b * base.a * (1.0 - color.a)) / out_a,
					out_a
				))

func _save_preview(_items: Array[Dictionary]) -> void:
	# Runtime folders should contain loadable game assets only; contact sheets
	# belong in run evidence or curated source folders.
	pass

func _save_to_roots(rel: String, image: Image) -> void:
	for root in [PROJECT_RUNTIME_ROOT, SHARED_RUNTIME_ROOT]:
		var path: String = root + rel
		var err := image.save_png(ProjectSettings.globalize_path(path))
		if err != OK:
			push_error("failed to save " + path + ": " + str(err))
