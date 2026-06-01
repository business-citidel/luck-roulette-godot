extends SceneTree

const TitleScene := preload("res://scenes/run/title_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var scene: Control = TitleScene.instantiate()
	scene.configure({"seed_text": "title-lobby-contract", "has_continue": false})
	root.add_child(scene)
	await process_frame

	var start_button := scene.get("start_button") as Button
	var continue_button := scene.get("continue_button") as Button
	var gallery_button := scene.get("gallery_button") as Button
	var settings_button := scene.get("settings_button") as Button
	var quit_button := scene.get("quit_button") as Button
	if start_button == null:
		failures.append("title should expose a start/new-run button")
	elif start_button.disabled:
		failures.append("title new-run button should be enabled")
	elif start_button.text == "":
		failures.append("title new-run button should have visible text")
	if continue_button == null:
		failures.append("title should expose a continue button")
	elif not continue_button.disabled:
		failures.append("title continue should stay disabled when no save exists")
	if gallery_button == null:
		failures.append("title should expose a gallery button")
	elif gallery_button.disabled:
		failures.append("title gallery should be enabled")
	if settings_button == null:
		failures.append("title should expose a settings button")
	elif settings_button.disabled:
		failures.append("title settings should be enabled")
	if quit_button == null:
		failures.append("title should expose a quit button")

	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	scene._start_run()
	scene._start_run()
	await process_frame
	if results.size() != 1:
		failures.append("title start should emit exactly one result")
	elif str(results[0].get("action", "")) != "start_run":
		failures.append("title start action changed")

	scene.queue_free()
	await process_frame

	var continue_scene: Control = TitleScene.instantiate()
	continue_scene.configure({"seed_text": "title-lobby-contract", "has_continue": true})
	root.add_child(continue_scene)
	await process_frame
	var enabled_continue_button := continue_scene.get("continue_button") as Button
	if enabled_continue_button == null or enabled_continue_button.disabled:
		failures.append("title continue should enable when a save exists")
	continue_scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("title lobby contract smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
