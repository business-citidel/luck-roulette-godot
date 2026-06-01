class_name RouletteSlotCatalog
extends RefCounted

const UiText := preload("res://scripts/ui/ui_text.gd")

const SLOT_ORDER: Array[String] = ["bust", "safe", "profit", "overdrive", "jackpot"]

static func slot_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in SLOT_ORDER:
		ids.append(id)
	return ids

static func fallback_id() -> String:
	return "safe"

static func has_slot(slot_id: String) -> bool:
	return SLOT_ORDER.has(slot_id)

static func get_slot(slot_id: String) -> Dictionary:
	var id: String = slot_id if has_slot(slot_id) else fallback_id()
	match id:
		"profit":
			return _slot("profit", UiText.t("roulette.slot.profit.label"), UiText.t("roulette.slot.profit.hint"), "x1", "#60cf86", 1.0, 0, 0, 0, UiText.t("roulette.slot.profit.banner"))
		"jackpot":
			return _slot("jackpot", UiText.t("roulette.slot.jackpot.label"), UiText.t("roulette.slot.jackpot.hint"), "x2", "#a879ef", 2.0, 0, 0, 0, UiText.t("roulette.slot.jackpot.banner"))
		"bust":
			return _slot("bust", UiText.t("roulette.slot.bust.label"), UiText.t("roulette.slot.bust.hint"), "x0", "#dd4e59", 0.0, 0, 0, 0, UiText.t("roulette.slot.bust.banner"))
		"overdrive":
			return _slot("overdrive", UiText.t("roulette.slot.overdrive.label"), UiText.t("roulette.slot.overdrive.hint"), "x1.5", "#4fa9ff", 1.5, 0, 0, 0, UiText.t("roulette.slot.overdrive.banner"))
		_:
			return _slot("safe", UiText.t("roulette.slot.safe.label"), UiText.t("roulette.slot.safe.hint"), "x1", "#d9c46d", 1.0, 0, 0, 0, UiText.t("roulette.slot.safe.banner"))

static func label(slot_id: String) -> String:
	return str(get_slot(slot_id).get("label", slot_id))

static func hint(slot_id: String) -> String:
	return str(get_slot(slot_id).get("hint", ""))

static func reward_text(slot_id: String) -> String:
	return str(get_slot(slot_id).get("display_reward", ""))

static func boosted_reward_text(slot_id: String) -> String:
	return str(_boosted_slot(get_slot(slot_id)).get("display_reward", ""))

static func marble_upgrade_multiplier(slot_id: String) -> float:
	match slot_id if has_slot(slot_id) else fallback_id():
		"safe":
			return 0.5
		"profit":
			return 1.0
		"overdrive":
			return 1.5
		"bust":
			return 1.5
		"jackpot":
			return 2.0
		_:
			return 1.0

static func color(slot_id: String) -> Color:
	return Color(str(get_slot(slot_id).get("color", "#ffffff")))

static func index(slot_id: String) -> int:
	var found: int = SLOT_ORDER.find(slot_id)
	return 0 if found < 0 else found

static func outcome(slot_id: String, attack_base: int, placed_slots: Dictionary, multiplier_adjust: float = 0.0, flat_damage_bonus: int = 0) -> Dictionary:
	var base_slot: Dictionary = get_slot(slot_id)
	var resolved_id: String = str(base_slot.get("id", slot_id))
	var boosted: bool = has_placed_token(placed_slots, resolved_id)
	var slot: Dictionary = _boosted_slot(base_slot) if boosted else base_slot
	var damage_multiplier: float = max(0.0, float(slot.get("damage_multiplier", 1.0)) + multiplier_adjust)
	var cash_delta: int = int(slot.get("cash_delta", 0))
	var final_damage: int = int(round(float(max(0, attack_base)) * damage_multiplier + float(flat_damage_bonus)))
	return {
		"slot_id": str(slot.get("id", slot_id)),
		"pending_slot": str(slot.get("id", slot_id)),
		"label": str(slot.get("label", slot_id)),
		"damage_multiplier": damage_multiplier,
		"cash_delta": cash_delta,
		"hp_delta": int(slot.get("hp_delta", 0)),
		"bust_delta": int(slot.get("bust_delta", 0)),
		"flat_damage_bonus": flat_damage_bonus,
		"attack_base": attack_base,
		"damage": max(0, final_damage),
		"banner": str(slot.get("banner", "RESULT")),
		"boosted": boosted,
		"outcome_mode": "boosted" if boosted else "normal"
	}

static func _slot(id: String, label_text: String, hint_text: String, reward_text_value: String, color_value: String, damage_multiplier: float, cash_delta: int, hp_delta: int, bust_delta: int, banner_text: String) -> Dictionary:
	return {
		"id": id,
		"label": label_text,
		"hint": hint_text,
		"display_reward": reward_text_value,
		"color": color_value,
		"damage_multiplier": damage_multiplier,
		"cash_delta": cash_delta,
		"hp_delta": hp_delta,
		"bust_delta": bust_delta,
		"banner": banner_text
	}

static func _boosted_slot(slot: Dictionary) -> Dictionary:
	var id: String = str(slot.get("id", fallback_id()))
	match id:
		"profit":
			return _slot("profit", UiText.t("roulette.slot.profit.boost_label"), UiText.t("roulette.slot.profit.boost_hint"), "x1.5", "#60cf86", 1.5, 0, 0, 0, UiText.t("roulette.slot.profit.boost_banner"))
		"jackpot":
			return _slot("jackpot", UiText.t("roulette.slot.jackpot.boost_label"), UiText.t("roulette.slot.jackpot.boost_hint"), "x3", "#a879ef", 3.0, 0, 0, 0, UiText.t("roulette.slot.jackpot.boost_banner"))
		"bust":
			return _slot("bust", UiText.t("roulette.slot.bust.boost_label"), UiText.t("roulette.slot.bust.boost_hint"), "x1", "#dd4e59", 1.0, 0, 0, 0, UiText.t("roulette.slot.bust.boost_banner"))
		"overdrive":
			return _slot("overdrive", UiText.t("roulette.slot.overdrive.boost_label"), UiText.t("roulette.slot.overdrive.boost_hint"), "x2", "#4fa9ff", 2.0, 0, 0, 0, UiText.t("roulette.slot.overdrive.boost_banner"))
		_:
			return _slot("safe", UiText.t("roulette.slot.safe.boost_label"), UiText.t("roulette.slot.safe.boost_hint"), "x1.5", "#d9c46d", 1.5, 0, 0, 0, UiText.t("roulette.slot.safe.boost_banner"))

static func has_placed_token(placed_slots: Dictionary, slot_id: String) -> bool:
	return _slot_count(placed_slots, slot_id) > 0

static func _slot_count(placed_slots: Dictionary, id: String) -> int:
	var arr: Array = placed_slots.get(id, [])
	return arr.size()
