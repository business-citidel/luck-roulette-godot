class_name GoStopButtonDriver
extends RefCounted

static func button_by_text(combat: Control, text: String) -> Button:
	if combat.prompt_layer == null or combat.prompt_layer.action_bar == null:
		return null
	var children: Array = combat.prompt_layer.action_bar.get_children()
	var disabled_match: Button = null
	for i in range(children.size() - 1, -1, -1):
		var child: Node = children[i]
		if child.is_queued_for_deletion():
			continue
		var button := child as Button
		if button != null and button.text == text:
			if not button.disabled:
				return button
			if disabled_match == null:
				disabled_match = button
	return disabled_match

static func press_button_by_text(combat: Control, text: String) -> String:
	var button := button_by_text(combat, text)
	if button == null:
		return "missing"
	if button.disabled:
		return "disabled"
	button.pressed.emit()
	return ""
