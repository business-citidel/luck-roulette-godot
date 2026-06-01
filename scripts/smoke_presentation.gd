extends SceneTree

const MAIN_SCENE := "res://scenes/battle/battle_scene.tscn"

func _initialize() -> void:
	var scene: PackedScene = load(MAIN_SCENE)
	if scene == null:
		push_error("Could not load main scene")
		quit(1)
		return

	var main: Control = scene.instantiate()
	root.add_child(main)
	root.size = Vector2i(1280, 720)
	await process_frame
	main.set("combat_core", "legacy_slot")

	var failures: Array[String] = []
	if main.world_root == null:
		failures.append("world root is missing")
	if main.hud_canvas == null:
		failures.append("hud canvas is missing")
	if main.camera_rig == null:
		failures.append("combat camera rig is missing")
	elif not main.camera_rig.phantom_camera_vendored:
		failures.append("phantom camera addon is not vendored")
	if main.table_layer == null:
		failures.append("table layer is missing")
	if main.hand_layer == null:
		failures.append("hand layer is missing")
	if main.run_hud == null:
		failures.append("run hud layer is missing")
	if main.opponent_layer == null:
		failures.append("opponent layer is missing")
	if main.prompt_layer == null:
		failures.append("prompt layer is missing")
	elif main.prompt_layer.action_bar == null:
		failures.append("prompt action bar is missing")
	elif main.prompt_layer.action_bar.get_child_count() < 1:
		failures.append("prompt action buttons are not mounted")
	elif main.prompt_layer.action_bar.size.x < 900 or main.prompt_layer.action_bar.size.y < 50:
		failures.append("prompt action bar has invalid size")
	elif main.prompt_layer.action_bar.position.y < 560:
		failures.append("prompt action bar is not positioned near the bottom")
	if main.ritual_director == null:
		failures.append("ritual director is missing")
	if main.audio_bank == null:
		failures.append("audio bank is missing")
	elif not main.audio_bank.has_sfx("dice_roll"):
		failures.append("dice_roll streams missing")
	elif not main.audio_bank.has_sfx("marble_drop"):
		failures.append("marble_drop streams missing")
	elif not main.audio_bank.has_sfx("wheel_tick"):
		failures.append("wheel_tick streams missing")

	main._roll_dice()
	await process_frame
	if main.dice_roll_fx <= 0.0:
		failures.append("dice roll feedback did not start")
	if main.camera_rig.get_active_beat() != "wide_table":
		failures.append("dice phase should keep the wide table camera until ritual focus")

	main._try_toggle_die(main._die_rect(0).get_center())
	await process_frame
	if not main.dice_locked[0]:
		failures.append("die lock click did not toggle")

	main._take_marbles()
	await process_frame
	if main.phase != "marble" or main.marbles.is_empty():
		failures.append("take marbles did not enter marble phase")
	if main.camera_rig.get_active_beat() != "wide_table":
		failures.append("marble phase should keep wide table camera before focused ritual")

	var marble_start: Vector2 = main._hand_rect().get_center()
	main._try_start_hand_throw(marble_start)
	main.hand_pos = marble_start + Vector2(92, -36)
	main.hand_velocity = Vector2(34, -18)
	main.hand_shake = 240.0
	main._release_hand_throw(main.hand_pos)
	await process_frame
	if main.camera_rig.get_active_beat() != "wheel_close":
		failures.append("marble throw did not select wheel camera beat")
	if main.marbles.size() != 0:
		failures.append("hand throw did not consume held marbles")
	if main.thrown_marbles.is_empty():
		failures.append("hand throw did not spawn flying marbles")
	for i in range(24):
		main._update_thrown_marbles(0.05)
		await process_frame
	if main._placed_count() <= 0:
		failures.append("thrown marbles did not settle into wheel plates")
	if not main._marble_setup_ready():
		failures.append("marble setup did not become spin-ready")
	if not main.message.contains("룰렛"):
		failures.append("spin-ready message does not point to roulette step")
	if main.slot_feedback_alpha <= 0.0:
		failures.append("slot feedback did not start")

	main._start_spin()
	await process_frame
	if main.phase != "spinning":
		failures.append("spin-ready state did not start roulette spin")
	if main.camera_rig.get_active_beat() != "wheel_close":
		failures.append("spin phase did not stay on wheel camera beat")
	main.pending_slot = "profit"
	main.payout_multiplier = 1.0
	main._resolve_pending()
	await process_frame
	if main.enemy_flash <= 0.0:
		failures.append("enemy hit feedback did not start")
	if main.coin_particles.is_empty():
		failures.append("coin particles did not spawn")
	if main.opponent_mood != "hit":
		failures.append("opponent did not enter hit reaction")

	if failures.is_empty():
		print("presentation smoke passed")
		main.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		main.queue_free()
		await process_frame
		quit(1)
