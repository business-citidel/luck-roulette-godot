extends SceneTree

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiLayoutSpec := preload("res://scripts/ui/ui_layout_spec.gd")

var shot_dir: String = ""
var failures: Array[String] = []
var fixture: Control

func _initialize() -> void:
	print("ui skin fixture playtest start")
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)
	fixture = PhysicalUiFixture.new()
	root.add_child(fixture)
	await _settle(8)
	await _shot("ui_skin_physicalization_fixture")
	fixture.queue_free()
	await process_frame
	if failures.is_empty():
		print("ui skin fixture playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _shot_dir_from_args() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	return ""

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _shot(name: String) -> void:
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name + "; run this playtest without --headless")
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path: String = shot_dir.path_join(name + ".png")
	var err: Error = image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)

class PhysicalUiFixture:
	extends Control

	func _init() -> void:
		size = Vector2(1280, 720)
		custom_minimum_size = size

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#07090d"), true)
		UiSkin.draw_table_stage(self)

		UiSkin.draw_parchment_card(self, Rect2(Vector2(94, 96), Vector2(222, 146)), "small")
		UiSkin.draw_parchment_card(self, Rect2(Vector2(94, 274), UiLayoutSpec.MAP_CARD_SIZE), "small", Color(1, 1, 1, 0.82))
		UiSkin.draw_parchment_card(self, UiLayoutSpec.MODAL_FOCUS_PANEL, "large")
		UiSkin.draw_parchment_card(self, UiLayoutSpec.SHELL_TITLE_CARD, "large", Color(1, 1, 1, 0.2))
		UiSkin.draw_resource_ledger(self, Rect2(Vector2(970, 92), UiLayoutSpec.LEDGER_COMPACT_SIZE))
		UiSkin.draw_resource_ledger(self, Rect2(Vector2(336, 214), UiLayoutSpec.LEDGER_WIDE_SIZE), Color(1, 1, 1, 0.9))
		UiSkin.draw_resource_ledger(self, Rect2(Vector2(970, 198), UiLayoutSpec.BATTLE_INTENT_LEDGER_SIZE), Color(1, 1, 1, 0.86))
		UiSkin.draw_result_tray(self, UiLayoutSpec.RESULT_TRAY)
		UiSkin.draw_prompt_strip(self, UiLayoutSpec.BOTTOM_ACTION_ZONE)
		UiSkin.draw_plaque(self, Rect2(Vector2(960, 250), Vector2(232, 62)), true)
		UiSkin.draw_plaque(self, Rect2(Vector2(960, 330), Vector2(232, 62)), false)
		UiSkin.draw_plaque(self, Rect2(Vector2(960, 410), Vector2(232, 62)), true, true)
		UiSkin.draw_plaque(self, Rect2(Vector2(472, 622), UiLayoutSpec.COMBAT_BUTTON_SIZE), true)

		for i in range(3):
			var state: String = ["current", "locked", "cleared"][i]
			UiSkin.draw_offer_card(self, UiLayoutSpec.offer_card_rect(i), state)

		UiSkin.draw_route_cord(self, Vector2(226, 454), Vector2(504, 454), Color("#f6d28a", 0.85), 12.0)
		UiSkin.draw_route_cord(self, Vector2(504, 454), Vector2(778, 454), Color("#c79b58", 0.78), 10.0)
		UiSkin.draw_pin(self, Vector2(226, 454), Color("#f2be4b"))
		UiSkin.draw_pin(self, Vector2(504, 454), 34.0)
		UiSkin.draw_pin(self, Vector2(778, 454), Color("#cf4f56"))
		UiSkin.draw_state_token(self, Vector2(1026, 520), "available", 30.0)
		UiSkin.draw_state_token(self, Vector2(1108, 520), "boss", 32.0)
