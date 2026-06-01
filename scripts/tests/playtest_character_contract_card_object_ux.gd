extends SceneTree

const CharacterSelectScene := preload("res://scenes/run/character_select_scene.tscn")
const CharacterContractCatalog := preload("res://scripts/systems/character_contract_catalog.gd")
const CharacterContractCardNode := preload("res://scripts/ui/character_contract_card_node.gd")

var shot_dir: String = ""
var active_scene: Control
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir != "":
		DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)
	active_scene = CharacterSelectScene.instantiate()
	active_scene.configure({"character_id": CharacterContractCatalog.default_character_id()})
	root.add_child(active_scene)
	await _settle(8)
	await _shot("character_card_object_01_ready")
	var cards: Array = active_scene.get("contract_cards")
	if cards.size() != 4:
		failures.append("character card object UX expected four contract card objects")
	else:
		var default_card := cards[0] as CharacterContractCardNode
		var double_attack_card := cards[1] as CharacterContractCardNode
		var black_signer_card := cards[2] as CharacterContractCardNode
		var locked_card := cards[3] as CharacterContractCardNode
		if default_card == null or double_attack_card == null or black_signer_card == null or locked_card == null:
			failures.append("character card object UX controls should be CharacterContractCardNode")
		else:
			if double_attack_card.disabled:
				failures.append("double attack contract card should be enabled")
			if black_signer_card.disabled:
				failures.append("black signer contract card should be previewable")
			if not locked_card.disabled:
				failures.append("future contract card should be disabled")
			default_card.set_hovered(true)
			await _settle(12)
			await _shot("character_card_object_02_hover")
			default_card.set_selected(true)
			await _settle(12)
			await _shot("character_card_object_03_selected")
	if active_scene != null:
		active_scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("character contract card object UX playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _shot_dir_from_args() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	return ""

func _shot(name: String) -> void:
	if shot_dir == "":
		return
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name + "; run this playtest without --headless")
		return
	var image: Image = viewport_texture.get_image()
	if image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path: String = shot_dir.path_join(name + ".png")
	var err: Error = image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
