class_name CharacterContractCatalog
extends RefCounted

const ContentMetadata := preload("res://scripts/systems/content_metadata.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const DEFAULT_CHARACTER_ID := "default_guard_dice"

const RELIC_PROFILE_GUARD := "guard"
const RELIC_PROFILE_DOUBLE_ATTACK := "double_attack"
const RELIC_PROFILE_BLACK_SIGNER := "black_signer"

const CHARACTERS := {
	"default_guard_dice": {
		"id": "default_guard_dice",
		"name": "공격/방어 계약",
		"subtitle": "고른 눈은 공격, 남은 눈은 방어",
		"rule_text": "주사위 2개를 굴린다. 하나를 공격에 쓰면 다른 하나가 이번 턴 방어가 된다.",
		"dice_rule_id": "two_dice_attack_guard",
		"starting_max_hp": 30,
		"starting_relic_ids": ["default_guard_crest"],
		"relic_pool_profile": RELIC_PROFILE_GUARD,
		"capabilities": ["rolls_dice", "uses_support_die", "can_block_with_dice"],
		"enabled": true
	},
	"double_attack_dice": {
		"id": "double_attack_dice",
		"name": "쌍공격 계약",
		"subtitle": "메인도 공격, 보조도 공격",
		"rule_text": "주사위 2개를 굴린다. 하나를 메인 공격으로 고르면 다른 주사위도 공격에 더해진다. 주사위 방어는 없다.",
		"dice_rule_id": "two_dice_double_attack",
		"starting_max_hp": 20,
		"starting_relic_ids": ["double_attack_crest"],
		"relic_pool_profile": RELIC_PROFILE_DOUBLE_ATTACK,
		"capabilities": ["rolls_dice", "uses_support_die", "no_block_identity", "uses_lifesteal"],
		"enabled": true
	},
	"black_signer_no_dice": {
		"id": "black_signer_no_dice",
		"name": "검은 계약자",
		"subtitle": "주사위 대신 계약을 고른다",
		"rule_text": "주사위를 굴리지 않는다. 검/방패/룰렛 계약 중 하나에 서명하고 빚 표식을 쌓는다.",
		"dice_rule_id": "black_signer_contracts",
		"starting_max_hp": 42,
		"relic_pool_profile": RELIC_PROFILE_BLACK_SIGNER,
		"capabilities": ["uses_contracts", "can_contract_block", "contract_debt"],
		"enabled": true,
		"preview_enabled": true
	},
	"future_luck_contract": {
		"id": "future_luck_contract",
		"name": "행운 계약",
		"subtitle": "준비 중",
		"rule_text": "아직 잠겨 있다.",
		"dice_rule_id": "two_dice_attack_guard",
		"starting_max_hp": 30,
		"relic_pool_profile": RELIC_PROFILE_GUARD,
		"capabilities": ["rolls_dice", "uses_support_die", "can_block_with_dice"],
		"enabled": false
	}
}

static func default_character_id() -> String:
	return DEFAULT_CHARACTER_ID

static func get_character(character_id: String = DEFAULT_CHARACTER_ID) -> Dictionary:
	var character := (CHARACTERS[character_id] as Dictionary).duplicate(true) if CHARACTERS.has(character_id) else (CHARACTERS[DEFAULT_CHARACTER_ID] as Dictionary).duplicate(true)
	var id := str(character.get("id", character_id))
	character["name"] = UiText.t("character." + id + ".name")
	character["subtitle"] = UiText.t("character." + id + ".subtitle")
	character["rule_text"] = UiText.t("character." + id + ".rule_text")
	var enabled := bool(character.get("enabled", false))
	var visual_ready := ContentMetadata.runtime_character_visual_ready(id)
	return ContentMetadata.apply(character, ContentMetadata.build(
		id,
		str(character.get("image_id", id)),
		enabled,
		enabled,
		visual_ready,
		ContentMetadata.RARITY_COMMON,
		["character", "contract"]
	))

static func enabled_characters() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in CHARACTERS.keys():
		var character := get_character(str(id))
		if bool(character.get("enabled", false)):
			result.append(character)
	return result

static func dice_rule_id(character_id: String = DEFAULT_CHARACTER_ID) -> String:
	return str(get_character(character_id).get("dice_rule_id", "two_dice_attack_guard"))

static func starting_max_hp(character_id: String = DEFAULT_CHARACTER_ID) -> int:
	return max(1, int(get_character(character_id).get("starting_max_hp", 42)))

static func display_name(character_id: String = DEFAULT_CHARACTER_ID) -> String:
	return str(get_character(character_id).get("name", character_id))

static func rule_text(character_id: String = DEFAULT_CHARACTER_ID) -> String:
	return str(get_character(character_id).get("rule_text", ""))

static func relic_pool_profile(character_id: String = DEFAULT_CHARACTER_ID) -> String:
	return str(get_character(character_id).get("relic_pool_profile", RELIC_PROFILE_GUARD))

static func capabilities(character_id: String = DEFAULT_CHARACTER_ID) -> Array[String]:
	var result: Array[String] = []
	for capability in get_character(character_id).get("capabilities", []):
		result.append(str(capability))
	return result

static func has_capability(character_id: String, capability: String) -> bool:
	return capabilities(character_id).has(capability)

static func starting_relic_ids(character_id: String = DEFAULT_CHARACTER_ID) -> Array[String]:
	var result: Array[String] = []
	var character := get_character(character_id)
	for relic_id in character.get("starting_relic_ids", []):
		result.append(str(relic_id))
	return result

static func all_starting_relic_ids() -> Array[String]:
	var result: Array[String] = []
	for character_id in CHARACTERS.keys():
		for relic_id in starting_relic_ids(str(character_id)):
			if not result.has(relic_id):
				result.append(relic_id)
	return result

static func all_character_ids() -> Array[String]:
	var result: Array[String] = []
	for id in CHARACTERS.keys():
		result.append(str(id))
	return result
