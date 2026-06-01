extends SceneTree

const CARD_W := 1024
const CARD_H := 1536
const EMBLEM_SIZE := 1024
const EMBLEM_MARK := 716

const INK := Color(0.10, 0.075, 0.043, 0.88)
const GOLD := Color(1.0, 0.72, 0.20, 0.72)
const RED := Color(0.55, 0.08, 0.045, 0.58)
const BLACK_VEIL := Color(0.02, 0.015, 0.01, 0.58)

func _initialize() -> void:
	var asset_root := _arg_value("--asset-root=")
	var game_root := _arg_value("--game-root=")
	if asset_root == "" or game_root == "":
		push_error("Missing --asset-root=<path> or --game-root=<path>")
		quit(1)
		return

	var kit_root := asset_root.path_join("curated/luck-roulette-current/map-node-card-system-001")
	_make_dirs([
		kit_root.path_join("cards"),
		kit_root.path_join("overlays"),
		kit_root.path_join("emblems"),
		kit_root.path_join("connectors"),
		kit_root.path_join("previews"),
		kit_root.path_join("raw")
	])

	var card_front_path := kit_root.path_join("cards/node_card_front_base.png")
	var front := Image.load_from_file(card_front_path)
	if front == null:
		push_error("Missing front base: " + card_front_path)
		quit(1)
		return
	front.convert(Image.FORMAT_RGBA8)
	_remove_chroma(front)
	front.save_png(card_front_path)

	var wax := _load_image(game_root.path_join("assets/ui/physicalization_001/marker_wax.png"), true)
	var coin := _load_image(game_root.path_join("assets/ui/physicalization_001/marker_coin.png"), true)
	var pin := _load_image(game_root.path_join("assets/ui/physicalization_001/route_pin.png"), true)
	var cord := _load_image(game_root.path_join("assets/ui/physicalization_001/route_cord.png"), true)

	_build_card_back(kit_root, front, game_root)
	_build_generated_emblem(kit_root, "node_emblem_event", game_root.path_join("assets/external/game-icons-node-icons/radial-balance.png"))
	_build_generated_emblem(kit_root, "node_emblem_shop", game_root.path_join("assets/external/game-icons-node-icons/shop.png"))
	_build_generated_emblem(kit_root, "node_emblem_elite", game_root.path_join("assets/external/game-icons-node-icons/crossed-swords.png"), true)
	_build_generated_emblem(kit_root, "node_emblem_boss", game_root.path_join("assets/external/game-icons-node-icons/spinning-wheel.png"), true)

	_build_overlays(kit_root, wax, coin, pin, front)
	_build_connectors(kit_root, wax, coin, pin, cord)
	_build_previews(kit_root)

	print("built " + kit_root)
	quit(0)

func _build_card_back(kit_root: String, front: Image, game_root: String) -> void:
	var back := front.duplicate()
	_tint_image(back, Color(0.36, 0.22, 0.10, 1.0), 0.45)
	_overlay_color(back, Color(0.04, 0.025, 0.015, 0.30))
	var sigil := _load_ink_icon(game_root.path_join("assets/external/game-icons-node-icons/spinning-wheel.png"), Color(0.08, 0.055, 0.032, 0.72))
	_fit(sigil, 520, 520)
	_blend(back, sigil, Vector2i((CARD_W - sigil.get_width()) / 2, 445))
	_draw_rect(back, Rect2i(128, 150, 768, 1236), Color(0.055, 0.035, 0.02, 0.45), false, 8)
	_draw_rect(back, Rect2i(164, 190, 696, 1156), Color(0.33, 0.22, 0.11, 0.30), false, 4)
	_mask_to_card_alpha(back, front)
	back.save_png(kit_root.path_join("cards/node_card_back_covered.png"))

func _build_generated_emblem(kit_root: String, name: String, icon_path: String, add_ring: bool = false) -> void:
	var out := Image.create(EMBLEM_SIZE, EMBLEM_SIZE, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var icon := _load_ink_icon(icon_path, INK)
	_fit(icon, EMBLEM_MARK, EMBLEM_MARK)
	if add_ring:
		_draw_ellipse(out, Vector2i(512, 512), 380, 380, INK, false, 12)
		_draw_ellipse(out, Vector2i(512, 512), 320, 320, Color(0.10, 0.075, 0.043, 0.54), false, 5)
	_blend(out, icon, Vector2i((EMBLEM_SIZE - icon.get_width()) / 2, (EMBLEM_SIZE - icon.get_height()) / 2))
	out.save_png(kit_root.path_join("emblems/" + name + ".png"))

func _build_overlays(kit_root: String, wax: Image, coin: Image, pin: Image, card_mask: Image) -> void:
	var dim := Image.create(CARD_W, CARD_H, false, Image.FORMAT_RGBA8)
	dim.fill(Color(0, 0, 0, 0))
	_overlay_color(dim, BLACK_VEIL)
	_draw_rect(dim, Rect2i(70, 86, 884, 1370), Color(0.0, 0.0, 0.0, 0.35), false, 18)
	_mask_to_card_alpha(dim, card_mask)
	dim.save_png(kit_root.path_join("overlays/node_card_future_dim_overlay.png"))

	var current := Image.create(CARD_W, CARD_H, false, Image.FORMAT_RGBA8)
	current.fill(Color(0, 0, 0, 0))
	_draw_rect(current, Rect2i(64, 68, 896, 1400), GOLD, false, 10)
	_draw_rect(current, Rect2i(96, 104, 832, 1328), Color(1.0, 0.84, 0.35, 0.36), false, 4)
	var current_wax := wax.duplicate()
	_fit(current_wax, 190, 190)
	_blend(current, current_wax, Vector2i(738, 1180))
	var current_pin := pin.duplicate()
	_fit(current_pin, 78, 130)
	_blend(current, current_pin, Vector2i(805, 72))
	current.save_png(kit_root.path_join("overlays/node_card_current_overlay.png"))

	var selected := Image.create(CARD_W, CARD_H, false, Image.FORMAT_RGBA8)
	selected.fill(Color(0, 0, 0, 0))
	_draw_rect(selected, Rect2i(44, 48, 936, 1440), Color(1.0, 0.77, 0.22, 0.42), false, 22)
	_draw_rect(selected, Rect2i(74, 82, 876, 1370), Color(1.0, 0.88, 0.45, 0.56), false, 8)
	_draw_ellipse(selected, Vector2i(512, 720), 350, 350, Color(1.0, 0.72, 0.20, 0.13), true)
	selected.save_png(kit_root.path_join("overlays/node_card_selected_hover_overlay.png"))

	var complete := Image.create(CARD_W, CARD_H, false, Image.FORMAT_RGBA8)
	complete.fill(Color(0, 0, 0, 0))
	_overlay_color(complete, Color(0.03, 0.025, 0.02, 0.32))
	_draw_diagonal_band(complete, Color(0.10, 0.055, 0.025, 0.42))
	_mask_to_card_alpha(complete, card_mask)
	var complete_coin := coin.duplicate()
	_fit(complete_coin, 150, 150)
	_blend(complete, complete_coin, Vector2i(112, 1190))
	complete.save_png(kit_root.path_join("overlays/node_card_completed_overlay.png"))

	var boss := Image.create(CARD_W, CARD_H, false, Image.FORMAT_RGBA8)
	boss.fill(Color(0, 0, 0, 0))
	_draw_rect(boss, Rect2i(42, 46, 940, 1444), RED, false, 28)
	_draw_rect(boss, Rect2i(86, 96, 852, 1342), Color(0.72, 0.10, 0.06, 0.34), false, 8)
	var boss_wax := wax.duplicate()
	_fit(boss_wax, 260, 260)
	_tint_image(boss_wax, Color(0.62, 0.02, 0.018, 1.0), 0.42)
	_blend(boss, boss_wax, Vector2i(692, 1120))
	boss.save_png(kit_root.path_join("overlays/node_card_boss_overlay.png"))

func _build_connectors(kit_root: String, wax: Image, coin: Image, pin: Image, cord: Image) -> void:
	cord.save_png(kit_root.path_join("connectors/route_cord.png"))
	pin.save_png(kit_root.path_join("connectors/route_pin.png"))
	wax.save_png(kit_root.path_join("connectors/wax_seal_current.png"))
	coin.save_png(kit_root.path_join("connectors/wax_seal_completed.png"))
	var boss_wax := wax.duplicate()
	_tint_image(boss_wax, Color(0.62, 0.02, 0.018, 1.0), 0.45)
	boss_wax.save_png(kit_root.path_join("connectors/wax_seal_boss.png"))

func _build_previews(kit_root: String) -> void:
	var front := _load_canvas_image(kit_root.path_join("cards/node_card_front_base.png"))
	var back := _load_canvas_image(kit_root.path_join("cards/node_card_back_covered.png"))
	var combat := _load_image(kit_root.path_join("emblems/node_emblem_combat.png"))
	var rest := _load_image(kit_root.path_join("emblems/node_emblem_rest.png"))
	var event := _load_image(kit_root.path_join("emblems/node_emblem_event.png"))
	var shop := _load_image(kit_root.path_join("emblems/node_emblem_shop.png"))
	var elite := _load_image(kit_root.path_join("emblems/node_emblem_elite.png"))
	var boss_emblem := _load_image(kit_root.path_join("emblems/node_emblem_boss.png"))
	var current := _load_canvas_image(kit_root.path_join("overlays/node_card_current_overlay.png"))
	var selected := _load_canvas_image(kit_root.path_join("overlays/node_card_selected_hover_overlay.png"))
	var complete := _load_canvas_image(kit_root.path_join("overlays/node_card_completed_overlay.png"))
	var dim := _load_canvas_image(kit_root.path_join("overlays/node_card_future_dim_overlay.png"))
	var boss_overlay := _load_canvas_image(kit_root.path_join("overlays/node_card_boss_overlay.png"))

	_save_preview_card(kit_root, "preview_current_combat.png", front, combat, [current])
	_save_preview_card(kit_root, "preview_selected_shop.png", front, shop, [selected])
	_save_preview_card(kit_root, "preview_completed_rest.png", front, rest, [complete])
	var empty_emblem := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	empty_emblem.fill(Color(0, 0, 0, 0))
	_save_preview_card(kit_root, "preview_future_covered.png", back, empty_emblem, [dim])
	_save_preview_card(kit_root, "preview_boss.png", front, boss_emblem, [boss_overlay])
	_save_contact_sheet(kit_root, [combat, event, shop, rest, elite, boss_emblem])
	_save_runtime_size_sheet(kit_root, "runtime_96_contact_sheet.png", Vector2i(96, 144))
	_save_runtime_size_sheet(kit_root, "runtime_112_contact_sheet.png", Vector2i(112, 168))
	_save_runtime_size_sheet(kit_root, "runtime_160_contact_sheet.png", Vector2i(160, 240))

func _save_preview_card(kit_root: String, file_name: String, base: Image, emblem: Image, overlays: Array[Image]) -> void:
	var card := base.duplicate()
	if not emblem.is_empty():
		var mark := emblem.duplicate()
		_fit(mark, 635, 635)
		_blend(card, mark, Vector2i((CARD_W - mark.get_width()) / 2, 500))
	for overlay in overlays:
		_blend(card, overlay, Vector2i.ZERO)
	var black := Image.create(CARD_W, CARD_H, false, Image.FORMAT_RGBA8)
	black.fill(Color(0, 0, 0, 1))
	_blend(black, card, Vector2i.ZERO)
	black.save_png(kit_root.path_join("previews/" + file_name))

func _save_contact_sheet(kit_root: String, emblems: Array[Image]) -> void:
	var sheet := Image.create(1536, 512, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.58, 0.43, 0.25, 1))
	for i in range(emblems.size()):
		_draw_rect(sheet, Rect2i(18 + i * 250, 118, 256, 276), Color(0.83, 0.66, 0.39, 0.34), true)
		_draw_rect(sheet, Rect2i(18 + i * 250, 118, 256, 276), Color(0.13, 0.08, 0.04, 0.35), false, 3)
		var icon := emblems[i].duplicate()
		_fit(icon, 220, 220)
		_blend(sheet, icon, Vector2i(36 + i * 250, 146))
	sheet.save_png(kit_root.path_join("previews/emblem_contact_sheet.png"))

func _save_runtime_size_sheet(kit_root: String, file_name: String, target_size: Vector2i) -> void:
	var names := [
		"preview_current_combat.png",
		"preview_selected_shop.png",
		"preview_completed_rest.png",
		"preview_future_covered.png",
		"preview_boss.png"
	]
	var margin := 36
	var gap := 28
	var sheet_size := Vector2i(margin * 2 + names.size() * target_size.x + (names.size() - 1) * gap, target_size.y + margin * 2)
	var sheet := Image.create(sheet_size.x, sheet_size.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.075, 0.045, 0.023, 1.0))
	for y in range(sheet_size.y):
		for x in range(sheet_size.x):
			var stripe := int(y / 18) % 2
			if stripe == 0:
				_blend_pixel(sheet, x, y, Color(0.16, 0.10, 0.052, 0.18))
	for i in range(names.size()):
		var preview := _load_image(kit_root.path_join("previews/" + names[i]))
		preview.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
		var x := margin + i * (target_size.x + gap)
		var y := margin
		_draw_rect(sheet, Rect2i(x + 6, y + 7, target_size.x, target_size.y), Color(0.0, 0.0, 0.0, 0.36), true)
		_blend(sheet, preview, Vector2i(x, y))
	sheet.save_png(kit_root.path_join("previews/" + file_name))

func _arg_value(prefix: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.replace(prefix, "").replace("\\", "/")
	for arg in OS.get_cmdline_args():
		if arg.begins_with(prefix):
			return arg.replace(prefix, "").replace("\\", "/")
	return ""

func _make_dirs(paths: Array[String]) -> void:
	for path in paths:
		DirAccess.make_dir_recursive_absolute(path)

func _load_image(path: String, remove_chroma: bool = false) -> Image:
	var img := Image.load_from_file(path)
	if img == null:
		push_error("Could not load " + path)
		return Image.create_empty(0, 0, false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	if remove_chroma:
		_remove_chroma(img)
	return _trim_alpha(img, 2)

func _load_canvas_image(path: String) -> Image:
	var img := Image.load_from_file(path)
	if img == null:
		push_error("Could not load " + path)
		return Image.create_empty(0, 0, false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	return img

func _load_ink_icon(path: String, ink: Color) -> Image:
	var src := Image.load_from_file(path)
	if src == null:
		push_error("Could not load " + path)
		return Image.create_empty(0, 0, false, Image.FORMAT_RGBA8)
	src.convert(Image.FORMAT_RGBA8)
	var out := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y in range(src.get_height()):
		for x in range(src.get_width()):
			var c := src.get_pixel(x, y)
			var brightness: float = max(c.r, max(c.g, c.b))
			if brightness > 0.08:
				var px := ink
				px.a = brightness * ink.a
				out.set_pixel(x, y, px)
	return _trim_alpha(out, 4)

func _remove_chroma(img: Image) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.g > 0.34 and c.g > c.r * 1.16 and c.g > c.b * 1.16:
				c.a = 0.0
				img.set_pixel(x, y, c)
			elif c.g > c.r * 1.08 and c.g > c.b * 1.08:
				c.g = max(c.r, c.b)
				img.set_pixel(x, y, c)

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
	if img.is_empty():
		return
	var scale: float = min(float(max_w) / float(img.get_width()), float(max_h) / float(img.get_height()))
	var new_size := Vector2i(max(1, int(round(img.get_width() * scale))), max(1, int(round(img.get_height() * scale))))
	img.resize(new_size.x, new_size.y, Image.INTERPOLATE_LANCZOS)

func _blend(dst: Image, src: Image, pos: Vector2i) -> void:
	if src.is_empty():
		return
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), pos)

func _overlay_color(img: Image, color: Color) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			_blend_pixel(img, x, y, color)

func _tint_image(img: Image, tint: Color, amount: float) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			c.r = lerpf(c.r, tint.r, amount)
			c.g = lerpf(c.g, tint.g, amount)
			c.b = lerpf(c.b, tint.b, amount)
			img.set_pixel(x, y, c)

func _mask_to_card_alpha(img: Image, mask: Image) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			c.a *= clampf(mask.get_pixel(x, y).a * 1.35, 0.0, 1.0)
			img.set_pixel(x, y, c)

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

func _draw_ellipse(img: Image, center: Vector2i, rx: int, ry: int, color: Color, filled: bool, width: int = 1) -> void:
	for y in range(center.y - ry, center.y + ry + 1):
		for x in range(center.x - rx, center.x + rx + 1):
			var dx := float(x - center.x) / float(rx)
			var dy := float(y - center.y) / float(ry)
			var d := dx * dx + dy * dy
			if filled:
				if d <= 1.0:
					_blend_pixel(img, x, y, color)
			elif d <= 1.0 and d >= pow(float(rx - width) / float(rx), 2.0):
				_blend_pixel(img, x, y, color)

func _draw_diagonal_band(img: Image, color: Color) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var line := int(0.42 * float(x) + 560.0)
			if abs(y - line) < 64:
				_blend_pixel(img, x, y, color)

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
