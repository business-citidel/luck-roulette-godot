extends SceneTree

const CharacterSelectScene := preload("res://scenes/run/character_select_scene.tscn")
const RunState := preload("res://scripts/resources/run_state.gd")
const CharacterContractCatalog := preload("res://scripts/systems/character_contract_catalog.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const CombatScene := preload("res://scenes/battle/battle_scene.tscn")

var shot_dir: String = ""
var active_scene: Control
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir != "":
		DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	await _show_character_select(CharacterContractCatalog.default_character_id())
	await _shot("01_character_select_default_contract")
	await _show_character_select("double_attack_dice")
	await _shot("01b_character_select_double_attack_contract")
	await _show_character_select("black_signer_no_dice")
	await _shot("01c_character_select_black_signer_preview")

	await _show_combat_contract()
	await _shot("02_combat_two_dice_ready")
	active_scene._roll_dice()
	await _settle(14)
	await _shot("03_combat_two_dice_rolled")
	active_scene._select_attack_die(1)
	await _settle(10)
	await _shot("04_combat_attack_guard_assigned")
	active_scene._enemy_action(0)
	await _settle(8)
	await _shot("05_combat_block_absorbs_enemy_hit")
	await _show_combat_contract("black_signer_no_dice")
	await _shot("06_black_signer_contract_ready")
	active_scene._select_black_signer_contract("sword")
	await _settle(10)
	await _shot("07_black_signer_contract_signed")

	if active_scene != null:
		active_scene.queue_free()
		await process_frame

	if failures.is_empty():
		print("character contract flow playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_character_select(character_id: String) -> void:
	_clear_active_scene()
	active_scene = CharacterSelectScene.instantiate()
	active_scene.configure({"character_id": character_id})
	root.add_child(active_scene)
	await _settle(8)

func _show_combat_contract(character_id: String = "") -> void:
	_clear_active_scene()
	var run_state: RunState = RunState.new()
	run_state.character_id = CharacterContractCatalog.default_character_id() if character_id == "" else character_id
	var payload: Dictionary = EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter("opening_debt"))
	active_scene = CombatScene.instantiate()
	root.add_child(active_scene)
	await process_frame
	active_scene.configure_encounter(payload)
	await _settle(8)

func _clear_active_scene() -> void:
	if active_scene == null:
		return
	active_scene.queue_free()
	active_scene = null

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
