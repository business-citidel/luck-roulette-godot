class_name DiceRuleCatalog
extends RefCounted

const DEFAULT_RULE_ID := "single_attack_die"

const RULES := {
	"single_attack_die": {
		"rule_id": "single_attack_die",
		"label": "Attack Die",
		"dice_count": 1,
		"sides": 6,
		"rerolls": 2,
		"lock_mode": "individual",
		"attack_base_mode": "sum"
	},
	"two_dice_sum_attack": {
		"rule_id": "two_dice_sum_attack",
		"label": "Twin Attack Dice",
		"dice_count": 2,
		"sides": 6,
		"rerolls": 2,
		"lock_mode": "individual",
		"attack_base_mode": "sum"
	},
	"highest_attack_die": {
		"rule_id": "highest_attack_die",
		"label": "High Die Attack",
		"dice_count": 2,
		"sides": 6,
		"rerolls": 1,
		"lock_mode": "individual",
		"attack_base_mode": "highest"
	},
	"two_dice_attack_guard": {
		"rule_id": "two_dice_attack_guard",
		"label": "Attack / Guard Dice",
		"dice_count": 2,
		"sides": 6,
		"rerolls": 2,
		"lock_mode": "none",
		"attack_base_mode": "choice_attack_guard",
		"guard_mode": "unchosen_die"
	},
	"two_dice_double_attack": {
		"rule_id": "two_dice_double_attack",
		"label": "Double Attack Dice",
		"dice_count": 2,
		"sides": 6,
		"rerolls": 2,
		"lock_mode": "none",
		"attack_base_mode": "choice_double_attack",
		"guard_mode": "none"
	},
	"black_signer_contracts": {
		"rule_id": "black_signer_contracts",
		"label": "Black Signer Contracts",
		"dice_count": 0,
		"sides": 6,
		"rerolls": 0,
		"lock_mode": "none",
		"attack_base_mode": "black_signer_contract",
		"guard_mode": "none"
	}
}

static func default_rule_id() -> String:
	return DEFAULT_RULE_ID

static func get_rule(rule_id: String = DEFAULT_RULE_ID) -> Dictionary:
	if RULES.has(rule_id):
		return (RULES[rule_id] as Dictionary).duplicate(true)
	return (RULES[DEFAULT_RULE_ID] as Dictionary).duplicate(true)

static func dice_count(rule_id: String = DEFAULT_RULE_ID) -> int:
	return int(get_rule(rule_id).get("dice_count", 1))

static func sides(rule_id: String = DEFAULT_RULE_ID) -> int:
	return int(get_rule(rule_id).get("sides", 6))

static func rerolls(rule_id: String = DEFAULT_RULE_ID) -> int:
	return int(get_rule(rule_id).get("rerolls", 2))

static func has_rule(rule_id: String) -> bool:
	return RULES.has(rule_id)
