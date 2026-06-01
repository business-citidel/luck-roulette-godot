extends SceneTree

const SOURCE_PATH := "res://../../assets/curated/luck-roulette-current/sprints/luck-roulette-visual-system-001/02-combat-table-system/000-combat-core-props-4plus1/final-reference/combat_core_props_direction_lock_002.png"
const PROJECT_RUNTIME_ROOT := "res://assets/runtime/combat/"
const SHARED_RUNTIME_ROOT := "res://../../assets/runtime/combat/"

const SPECS := [
	{
		"id": "roulette/wheel",
		"rect": Rect2i(70, 55, 690, 610),
		"size": Vector2i(512, 512),
		"mask": "ellipse"
	},
	{
		"id": "roulette/pointer",
		"rect": Rect2i(836, 142, 184, 404),
		"size": Vector2i(128, 256),
		"mask": "dark_key"
	},
	{
		"id": "tray/dice_tray",
		"rect": Rect2i(84, 855, 790, 346),
		"size": Vector2i(512, 224),
		"mask": "soft_rect"
	},
	{
		"id": "pouch/marble_pouch",
		"rect": Rect2i(1200, 856, 566, 344),
		"size": Vector2i(320, 196),
		"mask": "soft_rect"
	}
]

const DICE_SPECS := [
	{"id": "dice/die_1", "rect": Rect2i(1282, 182, 122, 126)},
	{"id": "dice/die_2", "rect": Rect2i(1455, 182, 122, 126)},
	{"id": "dice/die_3", "rect": Rect2i(1626, 182, 122, 126)},
	{"id": "dice/die_4", "rect": Rect2i(1280, 354, 122, 126)},
	{"id": "dice/die_5", "rect": Rect2i(1454, 354, 122, 126)},
	{"id": "dice/die_6", "rect": Rect2i(1625, 354, 122, 126)}
]

const MARBLE_SPECS := [
	{"id": "marbles/marble_plain", "rect": Rect2i(1128, 624, 104, 104)},
	{"id": "marbles/marble_black", "rect": Rect2i(1236, 624, 104, 104)},
	{"id": "marbles/marble_skull", "rect": Rect2i(1347, 624, 104, 104)},
	{"id": "marbles/marble_swords", "rect": Rect2i(1458, 624, 104, 104)},
	{"id": "marbles/marble_star", "rect": Rect2i(1567, 624, 104, 104)},
	{"id": "marbles/marble_guard", "rect": Rect2i(1678, 624, 104, 104)}
]

func _initialize() -> void:
	var source := Image.new()
	var err := source.load(ProjectSettings.globalize_path(SOURCE_PATH))
	if err != OK:
		push_error("failed to load source: " + SOURCE_PATH + " err=" + str(err))
		quit(1)
		return
	_prepare_dirs()
	for spec in SPECS:
		_extract(source, spec["id"], spec["rect"], spec["size"], spec["mask"])
	for spec in DICE_SPECS:
		_extract(source, spec["id"], spec["rect"], Vector2i(128, 128), "rounded_rect")
	for spec in MARBLE_SPECS:
		_extract(source, spec["id"], spec["rect"], Vector2i(128, 128), "circle")
	print("combat core props extracted")
	quit(0)

func _prepare_dirs() -> void:
	for root in [PROJECT_RUNTIME_ROOT, SHARED_RUNTIME_ROOT]:
		for subdir in ["roulette", "dice", "marbles", "tray", "pouch"]:
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root + subdir))

func _extract(source: Image, id: String, rect: Rect2i, target_size: Vector2i, mask: String) -> void:
	var image := source.get_region(rect)
	image.convert(Image.FORMAT_RGBA8)
	image.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	_apply_mask(image, mask)
	_save(image, PROJECT_RUNTIME_ROOT + id + ".png")
	_save(image, SHARED_RUNTIME_ROOT + id + ".png")

func _save(image: Image, path: String) -> void:
	var err := image.save_png(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("failed to save " + path + ": " + str(err))

func _apply_mask(image: Image, mask: String) -> void:
	match mask:
		"ellipse":
			_apply_ellipse_mask(image, 0.49, 0.49)
		"circle":
			_apply_ellipse_mask(image, 0.46, 0.46)
		"rounded_rect":
			_apply_rounded_rect_mask(image, 0.18)
		"soft_rect":
			_apply_soft_rect_mask(image, 0.035)
		"dark_key":
			_apply_dark_key(image)

func _apply_ellipse_mask(image: Image, radius_x: float, radius_y: float) -> void:
	var size: Vector2i = image.get_size()
	var center: Vector2 = Vector2(float(size.x - 1) * 0.5, float(size.y - 1) * 0.5)
	for y in range(size.y):
		for x in range(size.x):
			var normalized: Vector2 = Vector2((float(x) - center.x) / (float(size.x) * radius_x), (float(y) - center.y) / (float(size.y) * radius_y))
			var distance: float = normalized.length()
			var alpha: float = clamp((1.0 - distance) * 22.0, 0.0, 1.0)
			var color: Color = image.get_pixel(x, y)
			color.a *= alpha
			image.set_pixel(x, y, color)

func _apply_rounded_rect_mask(image: Image, corner_ratio: float) -> void:
	var size: Vector2i = image.get_size()
	var radius: float = min(float(size.x), float(size.y)) * corner_ratio
	for y in range(size.y):
		for x in range(size.x):
			var dx: float = max(max(radius - float(x), float(x) - (float(size.x) - radius)), 0.0)
			var dy: float = max(max(radius - float(y), float(y) - (float(size.y) - radius)), 0.0)
			var distance: float = Vector2(dx, dy).length()
			var alpha: float = clamp((radius - distance) * 0.9, 0.0, 1.0)
			var color: Color = image.get_pixel(x, y)
			color.a *= alpha
			image.set_pixel(x, y, color)

func _apply_soft_rect_mask(image: Image, edge_ratio: float) -> void:
	var size: Vector2i = image.get_size()
	var edge: float = min(float(size.x), float(size.y)) * edge_ratio
	for y in range(size.y):
		for x in range(size.x):
			var edge_distance: float = min(min(float(x), float(size.x - 1 - x)), min(float(y), float(size.y - 1 - y)))
			var alpha: float = clamp(edge_distance / edge, 0.0, 1.0)
			var color: Color = image.get_pixel(x, y)
			color.a *= alpha
			image.set_pixel(x, y, color)

func _apply_dark_key(image: Image) -> void:
	var size := image.get_size()
	for y in range(size.y):
		for x in range(size.x):
			var color := image.get_pixel(x, y)
			var brightness := (color.r + color.g + color.b) / 3.0
			var alpha := smoothstep(0.08, 0.22, brightness)
			color.a *= alpha
			image.set_pixel(x, y, color)
