extends SceneTree

func _initialize() -> void:
	var input_path := _arg_value("--in=")
	var output_path := _arg_value("--out=")
	if input_path == "" or output_path == "":
		push_error("Missing --in=<path> or --out=<path>")
		quit(1)
		return

	var img := Image.load_from_file(input_path)
	if img == null:
		push_error("Could not load " + input_path)
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)

	var out := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var ink := Color(0.105, 0.078, 0.043, 1.0)

	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if _is_chroma_green(c):
				continue
			var darkness: float = clamp(1.0 - ((c.r + c.g + c.b) / 3.0), 0.0, 1.0)
			var alpha: float = clamp(0.50 + darkness * 0.45, 0.0, 0.92)
			var px := ink
			px.a = alpha
			out.set_pixel(x, y, px)

	var err := out.save_png(output_path)
	if err != OK:
		push_error("Failed to save " + output_path + ": " + str(err))
		quit(1)
		return
	print("saved " + output_path)
	quit(0)

func _arg_value(prefix: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.replace(prefix, "").replace("\\", "/")
	for arg in OS.get_cmdline_args():
		if arg.begins_with(prefix):
			return arg.replace(prefix, "").replace("\\", "/")
	return ""

func _is_chroma_green(c: Color) -> bool:
	return c.g > 0.32 and c.g > c.r * 1.15 and c.g > c.b * 1.15
