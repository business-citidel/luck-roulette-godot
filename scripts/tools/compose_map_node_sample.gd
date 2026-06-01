extends SceneTree

const CARD_PATH := "res://assets/ui/physicalization_001/parchment_card_small.png"
const WAX_PATH := "res://assets/ui/physicalization_001/marker_wax.png"
const PIN_PATH := "res://assets/ui/physicalization_001/route_pin.png"
const ICON_PATH := "res://assets/external/game-icons-node-icons/crossed-swords.png"

func _initialize() -> void:
	var out_path := _arg_value("--out=")
	if out_path == "":
		push_error("Missing --out=<absolute png path>")
		quit(1)
		return

	var card := _load_chroma_asset(CARD_PATH)
	var wax := _load_chroma_asset(WAX_PATH)
	var pin := _load_chroma_asset(PIN_PATH)
	var icon := _load_ink_icon(ICON_PATH, Color(0.13, 0.10, 0.07, 1.0))
	if card.is_empty() or wax.is_empty() or pin.is_empty() or icon.is_empty():
		quit(1)
		return

	card = _trim_alpha(card, 2)
	wax = _trim_alpha(wax, 2)
	pin = _trim_alpha(pin, 2)

	_fit(card, 250, 330)
	_fit(wax, 64, 64)
	_fit(pin, 34, 58)
	_fit(icon, 92, 92)

	var canvas := Image.create(320, 410, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))

	# Transparent asset, but with a soft rectangular grounding stain so the card
	# reads as a physical object on the table.
	_draw_rect(canvas, Rect2i(45, 356, 228, 12), Color(0.03, 0.02, 0.01, 0.24), true)
	_blend(canvas, card, Vector2i(35, 36))

	# Current-state marker stays physical: wax plus a subtle brass edge, not a
	# large color flood over the card.
	_draw_rect(canvas, Rect2i(34, 35, 252, 334), Color(1.00, 0.84, 0.30, 0.45), false, 2)

	# Only the emblem is lifted from the external icon. It behaves like a stamped
	# paper/ink sticker on the card surface, with no foreign square background.
	_draw_rect(canvas, Rect2i(105, 102, 110, 104), Color(0.77, 0.62, 0.38, 0.18), true)
	_blend(canvas, icon, Vector2i(114, 107))

	# Reuse existing physical markers instead of regenerating wax/ring details.
	_blend(canvas, pin, Vector2i(226, 40))
	_blend(canvas, wax, Vector2i(214, 287))

	# Small stains keep the card from reading like a clean flat UI tile.
	_draw_rect(canvas, Rect2i(62, 320, 12, 5), Color(0.23, 0.10, 0.03, 0.22), true)
	_draw_rect(canvas, Rect2i(88, 327, 8, 4), Color(0.15, 0.07, 0.03, 0.20), true)
	_remove_green_fringe(canvas)

	var err := canvas.save_png(out_path)
	if err != OK:
		push_error("Failed to save " + out_path + ": " + str(err))
		quit(1)
		return

	print("saved " + out_path)
	quit(0)

func _arg_value(prefix: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.replace(prefix, "").replace("\\", "/")
	for arg in OS.get_cmdline_args():
		if arg.begins_with(prefix):
			return arg.replace(prefix, "").replace("\\", "/")
	return ""

func _load_chroma_asset(path: String) -> Image:
	var img := Image.load_from_file(path)
	if img == null:
		push_error("Could not load " + path)
		return Image.create_empty(0, 0, false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.g > 0.34 and c.g > c.r * 1.18 and c.g > c.b * 1.18:
				c.a = 0.0
				img.set_pixel(x, y, c)
			elif c.g > c.r * 1.08 and c.g > c.b * 1.08:
				c.g = max(c.r, c.b)
				img.set_pixel(x, y, c)
	return img

func _load_ink_icon(path: String, ink: Color) -> Image:
	var src := Image.load_from_file(path)
	if src == null:
		push_error("Could not load " + path)
		return Image.create_empty(0, 0, false, Image.FORMAT_RGBA8)
	src.convert(Image.FORMAT_RGBA8)
	var img := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(src.get_height()):
		for x in range(src.get_width()):
			var c := src.get_pixel(x, y)
			var brightness: float = max(c.r, max(c.g, c.b))
			if brightness > 0.08:
				var out := ink
				out.a = min(0.9, brightness * 0.9)
				img.set_pixel(x, y, out)
	return img

func _trim_alpha(img: Image, pad: int) -> Image:
	var min_x := img.get_width()
	var min_y := img.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a > 0.02:
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
	if max_x < min_x:
		return img
	min_x = max(0, min_x - pad)
	min_y = max(0, min_y - pad)
	max_x = min(img.get_width() - 1, max_x + pad)
	max_y = min(img.get_height() - 1, max_y + pad)
	return img.get_region(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))

func _fit(img: Image, max_w: int, max_h: int) -> void:
	var scale: float = min(float(max_w) / float(img.get_width()), float(max_h) / float(img.get_height()))
	var new_size := Vector2i(max(1, int(round(img.get_width() * scale))), max(1, int(round(img.get_height() * scale))))
	img.resize(new_size.x, new_size.y, Image.INTERPOLATE_LANCZOS)

func _blend(dst: Image, src: Image, pos: Vector2i) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), pos)

func _draw_rect(img: Image, rect: Rect2i, color: Color, filled: bool, width: int = 1) -> void:
	if filled:
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			for x in range(rect.position.x, rect.position.x + rect.size.x):
				_blend_pixel(img, x, y, color)
		return
	for i in range(width):
		var r := Rect2i(rect.position + Vector2i(i, i), rect.size - Vector2i(i * 2, i * 2))
		for x in range(r.position.x, r.position.x + r.size.x):
			_blend_pixel(img, x, r.position.y, color)
			_blend_pixel(img, x, r.position.y + r.size.y - 1, color)
		for y in range(r.position.y, r.position.y + r.size.y):
			_blend_pixel(img, r.position.x, y, color)
			_blend_pixel(img, r.position.x + r.size.x - 1, y, color)

func _blend_pixel(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	var base := img.get_pixel(x, y)
	var a := color.a
	var out := Color(
		color.r * a + base.r * (1.0 - a),
		color.g * a + base.g * (1.0 - a),
		color.b * a + base.b * (1.0 - a),
		a + base.a * (1.0 - a)
	)
	img.set_pixel(x, y, out)

func _remove_green_fringe(img: Image) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			if c.g > 0.20 and c.g > c.r * 1.05 and c.g > c.b * 1.05:
				if c.g > c.r * 1.18 and c.g > c.b * 1.18:
					c.a = 0.0
				else:
					c.g = max(c.r, c.b)
				img.set_pixel(x, y, c)
