class_name PayoutResolver
extends RefCounted

const RouletteSlotCatalog := preload("res://scripts/systems/roulette_slot_catalog.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

static func resolve(slot_id: String, placed_slots: Dictionary, cash: int, player_hp: int, enemy_hp: int, payout_multiplier: float, attack_base: int = 0, flat_damage_bonus: int = 0, cash_delta_bonus: int = 0, enemy_block: int = 0, player_damage_multiplier: float = 1.0) -> Dictionary:
	var multiplier_adjust: float = payout_multiplier - 1.0
	var slot_outcome: Dictionary = RouletteSlotCatalog.outcome(slot_id, attack_base, placed_slots, multiplier_adjust, flat_damage_bonus)
	var pre_curse_damage: int = int(slot_outcome.get("damage", 0))
	var raw_damage: int = max(0, int(floor(float(pre_curse_damage) * player_damage_multiplier)))
	var enemy_block_absorbed: int = min(max(0, enemy_block), raw_damage)
	var damage: int = max(0, raw_damage - enemy_block_absorbed)
	var cash_delta: int = int(slot_outcome.get("cash_delta", 0)) + cash_delta_bonus
	var next_cash: int = max(0, cash + cash_delta)
	var next_player_hp: int = max(0, player_hp + int(slot_outcome.get("hp_delta", 0)))
	var next_enemy_hp: int = max(0, enemy_hp - damage)
	var next_enemy_block: int = max(0, enemy_block - enemy_block_absorbed)
	var next_bust_delta: int = int(slot_outcome.get("bust_delta", 0))
	var profit: int = max(0, cash_delta)
	var damage_multiplier: float = float(slot_outcome.get("damage_multiplier", 1.0))
	var banner: String = str(slot_outcome.get("banner", "RESULT"))
	var label: String = str(slot_outcome.get("label", slot_id))
	var boosted: bool = bool(slot_outcome.get("boosted", false))
	var message: String
	if next_bust_delta > 0:
		message = UiText.t("payout.bust", {"label": label})
	else:
		message = UiText.t("payout.damage", {
			"boosted": UiText.t("payout.boosted_prefix") if boosted else "",
			"attack": attack_base,
			"multiplier": snapped(damage_multiplier, 0.01),
			"damage": damage
		})
		if player_damage_multiplier < 1.0 and pre_curse_damage > raw_damage:
			message += UiText.t("payout.curse_halved", {"before": pre_curse_damage, "after": raw_damage})
		if cash_delta != 0:
			message += UiText.t("payout.bonus", {"delta": ("+" if cash_delta > 0 else "") + str(cash_delta)})
		if enemy_block_absorbed > 0:
			message += UiText.t("payout.enemy_blocked", {"amount": enemy_block_absorbed})

	return {
		"profit": profit,
		"damage": damage,
		"raw_damage": raw_damage,
		"pre_curse_damage": pre_curse_damage,
		"player_damage_multiplier": player_damage_multiplier,
		"enemy_block": next_enemy_block,
		"enemy_block_absorbed": enemy_block_absorbed,
		"attack_base": attack_base,
		"damage_multiplier": damage_multiplier,
		"payout_multiplier": damage_multiplier,
		"cash_delta": cash_delta,
		"cash": next_cash,
		"player_hp": next_player_hp,
		"enemy_hp": next_enemy_hp,
		"bust_delta": next_bust_delta,
		"boosted": boosted,
		"outcome_mode": str(slot_outcome.get("outcome_mode", "normal")),
		"banner": banner,
		"message": message,
		"pending_slot": str(slot_outcome.get("pending_slot", slot_id))
	}

static func _placed_count(placed_slots: Dictionary) -> int:
	var count: int = 0
	for id in placed_slots.keys():
		var arr: Array = placed_slots.get(id, [])
		count += arr.size()
	return count
