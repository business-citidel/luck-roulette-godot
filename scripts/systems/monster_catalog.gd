class_name MonsterCatalog
extends RefCounted

const MonsterMoveCatalog := preload("res://scripts/systems/monster_move_catalog.gd")
const ContentMetadata := preload("res://scripts/systems/content_metadata.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const MONSTER_KO_NAMES := {
	"debt_collector": "빚 회수꾼",
	"table_crook": "테이블 사기꾼",
	"loaded_dice_runner": "속임수 주사위 운반꾼",
	"house_errand": "하우스 심부름꾼",
	"mug_brawler": "잔 싸움꾼",
	"backroom_bookie": "뒷방 장부꾼",
	"chip_stack_bruiser": "칩 더미 난폭꾼",
	"busted_lantern": "깨진 등불",
	"coin_shark": "코인 상어",
	"roulette_sweeper": "룰렛 청소꾼",
	"marked_card_sneak": "표식 카드 도둑",
	"pocket_ace_thief": "소매 에이스 도둑",
	"pawn_ticket": "전당표",
	"candle_counter": "촛불 계산원",
	"burnt_receipt": "탄 영수증",
	"bell_ringer": "종 울리는 자",
	"false_dealer_hand": "가짜 딜러 손",
	"brass_lockbox": "황동 금고",
	"ashtray_curse": "재떨이 저주",
	"snake_eye_clerk": "뱀눈 서기",
	"last_call_drunk": "마감 술꾼",
	"wheel_jammer": "룰렛 방해꾼",
	"elite_house": "하우스 집행자",
	"pit_boss_sentinel": "핏 보스 파수꾼",
	"taxed_roulette_knight": "세금 룰렛 기사",
	"blacklist_notary": "블랙리스트 공증인",
	"loaded_vault_keeper": "속임수 금고지기",
	"final_house": "마지막 하우스",
	"the_croupier": "크루피에",
	"the_red_seal": "붉은 봉인"
}

const MONSTER_PATTERN_ROLES := {
	"debt_collector": "tax",
	"table_crook": "disrupt",
	"loaded_dice_runner": "disrupt",
	"house_errand": "attack",
	"mug_brawler": "attack",
	"backroom_bookie": "buff",
	"chip_stack_bruiser": "heavy_attack",
	"busted_lantern": "disrupt",
	"coin_shark": "tax",
	"roulette_sweeper": "disrupt",
	"marked_card_sneak": "curse",
	"pocket_ace_thief": "tax",
	"pawn_ticket": "guard",
	"candle_counter": "buff",
	"burnt_receipt": "curse",
	"bell_ringer": "buff",
	"false_dealer_hand": "disrupt",
	"brass_lockbox": "guard",
	"ashtray_curse": "curse",
	"snake_eye_clerk": "heavy_attack",
	"last_call_drunk": "heavy_attack",
	"wheel_jammer": "disrupt",
	"elite_house": "guard",
	"pit_boss_sentinel": "guard",
	"taxed_roulette_knight": "audit",
	"blacklist_notary": "appraise",
	"loaded_vault_keeper": "tithe",
	"final_house": "tax",
	"the_croupier": "disrupt",
	"the_red_seal": "curse"
}

const MONSTER_PATTERN_READS := {
	"debt_collector": "Takes spendable gold unless the player ends the fight quickly.",
	"table_crook": "Hides the next read before slipping in cheap damage.",
	"loaded_dice_runner": "Clouds the table, then threatens a delayed heavy hit.",
	"house_errand": "Applies plain HP pressure with one predictable heavy beat.",
	"mug_brawler": "Throws steady damage before a simple heavy swing.",
	"backroom_bookie": "Boosts future hits unless the player races the setup.",
	"chip_stack_bruiser": "Mixes a guarded jab into a heavy bruiser cycle.",
	"busted_lantern": "Blinds the next intent, then pushes ordinary damage.",
	"coin_shark": "Skims spendable gold and chips health at the same time.",
	"roulette_sweeper": "Obscures the table read with misdeal pressure.",
	"marked_card_sneak": "Marks the player so the next hit becomes sharper.",
	"pocket_ace_thief": "Steals spendable gold before trying to finish with heavy pressure.",
	"pawn_ticket": "Stalls behind guard while taxing a later turn.",
	"candle_counter": "Counts up future damage unless the player bursts early.",
	"burnt_receipt": "Weakens the next attack, then tests the lowered output.",
	"bell_ringer": "Ramps damage faster than a normal setup enemy.",
	"false_dealer_hand": "Hides intent and follows the fake read with damage.",
	"brass_lockbox": "Builds guard until a burst window opens.",
	"ashtray_curse": "Weakens attacks, then marks the player for a sharper reply.",
	"snake_eye_clerk": "Counts up before repeating heavy spike damage.",
	"last_call_drunk": "Marks the player before a heavy last-call swing.",
	"wheel_jammer": "Repeatedly hides intent and jams planning tempo.",
	"elite_house": "Guards first, then alternates honest heavy pressure and guarded strikes.",
	"pit_boss_sentinel": "Marks first, then punishes no-block burst plans with guarded heavy pressure.",
	"taxed_roulette_knight": "Audits greedy roulette turns and taxes spendable gold between heavy swings.",
	"blacklist_notary": "Appraises high dice attacks, weakens obvious burst, then answers behind guard.",
	"loaded_vault_keeper": "Taxes excessive guard and layers vault block until a breach turn appears.",
	"final_house": "Claims spendable gold and guards before the House heavy cycle.",
	"the_croupier": "Controls information with repeated blind calls and misdeals.",
	"the_red_seal": "Turns marks and taxes into a boss pressure cycle."
}

const MONSTER_PATTERN_TUNING := {
	"debt_collector": {"attack_damage": 5, "tax_attack_damage": 4, "heavy_damage": 9, "tax_gold": 3, "skim_gold": 2},
	"table_crook": {"attack_damage": 5, "disrupt_attack_damage": 3, "heavy_damage": 9},
	"loaded_dice_runner": {"attack_damage": 5, "disrupt_attack_damage": 3, "heavy_damage": 12},
	"house_errand": {"attack_damage": 5, "heavy_damage": 8},
	"mug_brawler": {"attack_damage": 7, "heavy_damage": 12},
	"backroom_bookie": {"attack_damage": 5, "heavy_damage": 10, "buff_delta": 2},
	"chip_stack_bruiser": {"attack_damage": 8, "guard_attack_damage": 6, "heavy_damage": 14, "guarded_strike_block": 3},
	"busted_lantern": {"attack_damage": 5, "disrupt_attack_damage": 3, "heavy_damage": 9},
	"coin_shark": {"attack_damage": 4, "tax_attack_damage": 3, "heavy_damage": 8, "tax_gold": 5, "skim_gold": 4},
	"roulette_sweeper": {"attack_damage": 5, "disrupt_attack_damage": 4, "heavy_damage": 9},
	"marked_card_sneak": {"attack_damage": 5, "heavy_damage": 10, "marked_multiplier": 1.5},
	"pocket_ace_thief": {"attack_damage": 4, "tax_attack_damage": 4, "heavy_damage": 11, "tax_gold": 4, "skim_gold": 5},
	"pawn_ticket": {"attack_damage": 4, "heavy_damage": 8, "guard_block": 7, "tax_gold": 2},
	"candle_counter": {"attack_damage": 4, "heavy_damage": 10, "buff_delta": 2, "count_up_delta": 3},
	"burnt_receipt": {"attack_damage": 4, "heavy_damage": 8, "weak_multiplier": 0.65},
	"bell_ringer": {"attack_damage": 5, "heavy_damage": 12, "buff_delta": 2, "count_up_delta": 4},
	"false_dealer_hand": {"attack_damage": 5, "disrupt_attack_damage": 4, "heavy_damage": 11},
	"brass_lockbox": {"attack_damage": 4, "heavy_damage": 9, "guard_block": 12, "guarded_strike_block": 7},
	"ashtray_curse": {"attack_damage": 4, "heavy_damage": 8, "weak_multiplier": 0.6, "marked_multiplier": 1.55},
	"snake_eye_clerk": {"attack_damage": 4, "heavy_damage": 14, "count_up_delta": 3},
	"last_call_drunk": {"attack_damage": 6, "heavy_damage": 13, "marked_multiplier": 1.45},
	"wheel_jammer": {"attack_damage": 4, "disrupt_attack_damage": 4, "heavy_damage": 9},
	"elite_house": {"attack_damage": 9, "guard_attack_damage": 7, "heavy_damage": 17, "guard_block": 13, "guarded_strike_block": 8},
	"pit_boss_sentinel": {"attack_damage": 8, "guard_attack_damage": 7, "heavy_damage": 17, "guarded_strike_block": 8, "marked_multiplier": 1.7},
	"taxed_roulette_knight": {"attack_damage": 8, "tax_attack_damage": 7, "heavy_damage": 18, "tax_gold": 6, "skim_gold": 5, "roulette_audit_damage_delta": 3, "roulette_audit_low_multiplier": 0.5, "roulette_audit_block": 5},
	"blacklist_notary": {"attack_damage": 7, "guard_attack_damage": 6, "heavy_damage": 16, "guarded_strike_block": 6, "weak_multiplier": 0.55, "dice_appraisal_attack_threshold": 8, "dice_appraisal_damage_multiplier": 0.72, "dice_appraisal_block": 4},
	"loaded_vault_keeper": {"attack_damage": 8, "guard_attack_damage": 7, "heavy_damage": 19, "guard_block": 15, "guarded_strike_block": 9, "guard_tithe_block_threshold": 6, "guard_tithe_gold": -4, "guard_tithe_damage_delta": 1},
	"final_house": {"attack_damage": 8, "tax_attack_damage": 7, "heavy_damage": 18, "guard_block": 14, "tax_gold": 7, "skim_gold": 6},
	"the_croupier": {"attack_damage": 7, "disrupt_attack_damage": 6, "heavy_damage": 17},
	"the_red_seal": {"attack_damage": 7, "tax_attack_damage": 6, "heavy_damage": 19, "tax_gold": 7, "skim_gold": 6, "weak_multiplier": 0.5, "marked_multiplier": 1.8}
}

const MONSTERS := {
	"debt_collector": {
		"id": "debt_collector",
		"name": "Debt Collector",
		"tier": "normal",
		"hp": 18,
		"combat_cash": 18,
		"move_pattern": ["tax_collection", "hp_strike", "skim_payout"]
	},
	"table_crook": {
		"id": "table_crook",
		"name": "Table Crook",
		"tier": "normal",
		"hp": 22,
		"combat_cash": 20,
		"move_pattern": ["blind_call", "hp_strike", "misdeal_jab"]
	},
	"loaded_dice_runner": {
		"id": "loaded_dice_runner",
		"name": "Loaded Dice Runner",
		"tier": "normal",
		"hp": 20,
		"combat_cash": 19,
		"move_pattern": ["blind_call", "hp_strike", "heavy_hp_strike"]
	},
	"house_errand": {
		"id": "house_errand",
		"name": "House Errand",
		"tier": "normal",
		"hp": 19,
		"combat_cash": 18,
		"move_pattern": ["hp_strike", "hp_strike", "hp_strike", "heavy_hp_strike"]
	},
	"mug_brawler": {
		"id": "mug_brawler",
		"name": "Mug Brawler",
		"tier": "normal",
		"hp": 23,
		"combat_cash": 20,
		"move_pattern": ["hp_strike", "hp_strike", "heavy_hp_strike"]
	},
	"backroom_bookie": {
		"id": "backroom_bookie",
		"name": "Backroom Bookie",
		"tier": "normal",
		"hp": 25,
		"combat_cash": 22,
		"move_pattern": ["sharpen_odds", "hp_strike", "sharpen_odds", "heavy_hp_strike"]
	},
	"chip_stack_bruiser": {
		"id": "chip_stack_bruiser",
		"name": "Chip Stack Bruiser",
		"tier": "normal",
		"hp": 28,
		"combat_cash": 21,
		"move_pattern": ["hp_strike", "guarded_strike", "heavy_hp_strike"]
	},
	"busted_lantern": {
		"id": "busted_lantern",
		"name": "Busted Lantern",
		"tier": "normal",
		"hp": 26,
		"combat_cash": 21,
		"move_pattern": ["blind_call", "hp_strike", "hp_strike", "heavy_hp_strike"]
	},
	"coin_shark": {
		"id": "coin_shark",
		"name": "Coin Shark",
		"tier": "normal",
		"hp": 24,
		"combat_cash": 24,
		"move_pattern": ["tax_collection", "hp_strike", "skim_payout"]
	},
	"roulette_sweeper": {
		"id": "roulette_sweeper",
		"name": "Roulette Sweeper",
		"tier": "normal",
		"hp": 27,
		"combat_cash": 22,
		"move_pattern": ["blind_call", "misdeal_jab", "hp_strike"]
	},
	"marked_card_sneak": {
		"id": "marked_card_sneak",
		"name": "Marked Card Sneak",
		"tier": "normal",
		"hp": 25,
		"combat_cash": 23,
		"move_pattern": ["marked_stamp", "hp_strike", "heavy_hp_strike"]
	},
	"pocket_ace_thief": {
		"id": "pocket_ace_thief",
		"name": "Pocket Ace Thief",
		"tier": "normal",
		"hp": 26,
		"combat_cash": 23,
		"move_pattern": ["skim_payout", "tax_collection", "hp_strike", "heavy_hp_strike"]
	},
	"pawn_ticket": {
		"id": "pawn_ticket",
		"name": "Pawn Ticket",
		"tier": "normal",
		"hp": 21,
		"combat_cash": 20,
		"move_pattern": ["guarded_stance", "hp_strike", "tax_collection", "hp_strike"]
	},
	"candle_counter": {
		"id": "candle_counter",
		"name": "Candle Counter",
		"tier": "normal",
		"hp": 22,
		"combat_cash": 20,
		"move_pattern": ["count_up", "hp_strike", "count_up", "heavy_hp_strike"]
	},
	"burnt_receipt": {
		"id": "burnt_receipt",
		"name": "Burnt Receipt",
		"tier": "normal",
		"hp": 24,
		"combat_cash": 24,
		"move_pattern": ["weak_receipt", "hp_strike", "hp_strike"]
	},
	"bell_ringer": {
		"id": "bell_ringer",
		"name": "Bell Ringer",
		"tier": "normal",
		"hp": 23,
		"combat_cash": 21,
		"move_pattern": ["sharpen_odds", "hp_strike", "count_up", "heavy_hp_strike"]
	},
	"false_dealer_hand": {
		"id": "false_dealer_hand",
		"name": "False Dealer Hand",
		"tier": "normal",
		"hp": 25,
		"combat_cash": 23,
		"move_pattern": ["blind_call", "misdeal_jab", "hp_strike", "heavy_hp_strike"]
	},
	"brass_lockbox": {
		"id": "brass_lockbox",
		"name": "Brass Lockbox",
		"tier": "normal",
		"hp": 30,
		"combat_cash": 21,
		"move_pattern": ["guarded_stance", "hp_strike", "guarded_stance", "heavy_hp_strike"]
	},
	"ashtray_curse": {
		"id": "ashtray_curse",
		"name": "Ashtray Curse",
		"tier": "normal",
		"hp": 24,
		"combat_cash": 22,
		"move_pattern": ["weak_receipt", "hp_strike", "marked_stamp"]
	},
	"snake_eye_clerk": {
		"id": "snake_eye_clerk",
		"name": "Snake-Eye Clerk",
		"tier": "normal",
		"hp": 24,
		"combat_cash": 23,
		"move_pattern": ["count_up", "heavy_hp_strike", "hp_strike", "heavy_hp_strike"]
	},
	"last_call_drunk": {
		"id": "last_call_drunk",
		"name": "Last Call Drunk",
		"tier": "normal",
		"hp": 26,
		"combat_cash": 22,
		"move_pattern": ["hp_strike", "marked_stamp", "heavy_hp_strike"]
	},
	"wheel_jammer": {
		"id": "wheel_jammer",
		"name": "Wheel Jammer",
		"tier": "normal",
		"hp": 27,
		"combat_cash": 22,
		"move_pattern": ["blind_call", "misdeal_jab", "blind_call", "hp_strike"]
	},
	"elite_house": {
		"id": "elite_house",
		"name": "House Enforcer",
		"tier": "elite",
		"hp": 34,
		"combat_cash": 26,
		"move_pattern": ["guarded_stance", "heavy_hp_strike", "guarded_strike", "heavy_hp_strike"]
	},
	"pit_boss_sentinel": {
		"id": "pit_boss_sentinel",
		"name": "Pit Boss Sentinel",
		"tier": "elite",
		"hp": 38,
		"combat_cash": 28,
		"move_pattern": ["marked_stamp", "guarded_strike", "heavy_hp_strike", "hp_strike"]
	},
	"taxed_roulette_knight": {
		"id": "taxed_roulette_knight",
		"name": "Taxed Roulette Knight",
		"tier": "elite",
		"hp": 40,
		"combat_cash": 30,
		"move_pattern": ["roulette_audit", "tax_collection", "skim_payout", "heavy_hp_strike"]
	},
	"blacklist_notary": {
		"id": "blacklist_notary",
		"name": "Blacklist Notary",
		"tier": "elite",
		"hp": 39,
		"combat_cash": 29,
		"move_pattern": ["dice_appraisal", "weak_receipt", "guarded_strike", "heavy_hp_strike"]
	},
	"loaded_vault_keeper": {
		"id": "loaded_vault_keeper",
		"name": "Loaded Vault Keeper",
		"tier": "elite",
		"hp": 44,
		"combat_cash": 30,
		"move_pattern": ["guarded_stance", "guard_tithe", "guarded_stance", "heavy_hp_strike"]
	},
	"final_house": {
		"id": "final_house",
		"name": "Final House",
		"tier": "boss",
		"hp": 48,
		"combat_cash": 34,
		"move_pattern": ["tax_collection", "guarded_stance", "heavy_hp_strike", "skim_payout", "heavy_hp_strike"]
	},
	"the_croupier": {
		"id": "the_croupier",
		"name": "The Croupier",
		"tier": "boss",
		"hp": 56,
		"combat_cash": 38,
		"move_pattern": ["blind_call", "misdeal_jab", "hp_strike", "heavy_hp_strike", "misdeal_jab"]
	},
	"the_red_seal": {
		"id": "the_red_seal",
		"name": "The Red Seal",
		"tier": "boss",
		"hp": 64,
		"combat_cash": 42,
		"move_pattern": ["marked_stamp", "tax_collection", "heavy_hp_strike", "weak_receipt", "skim_payout", "heavy_hp_strike"]
	}
}

const ALWAYS_NORMAL_POOL := ["debt_collector", "table_crook", "loaded_dice_runner", "house_errand"]
const FLOOR_NORMAL_POOLS := {
	1: ["debt_collector", "table_crook", "loaded_dice_runner", "house_errand", "mug_brawler", "pawn_ticket", "candle_counter", "last_call_drunk", "brass_lockbox", "ashtray_curse"],
	2: ["backroom_bookie", "chip_stack_bruiser", "busted_lantern", "coin_shark", "roulette_sweeper", "burnt_receipt", "bell_ringer", "brass_lockbox", "ashtray_curse", "wheel_jammer"],
	3: ["roulette_sweeper", "marked_card_sneak", "pocket_ace_thief", "chip_stack_bruiser", "busted_lantern", "false_dealer_hand", "snake_eye_clerk", "brass_lockbox", "ashtray_curse", "wheel_jammer"]
}
const FLOOR_ELITE_POOLS := {
	1: ["elite_house", "pit_boss_sentinel"],
	2: ["elite_house", "pit_boss_sentinel", "taxed_roulette_knight", "blacklist_notary"],
	3: ["pit_boss_sentinel", "taxed_roulette_knight", "blacklist_notary", "loaded_vault_keeper"]
}
const FLOOR_BOSS_IDS := {
	1: "final_house",
	2: "the_croupier",
	3: "the_red_seal"
}

static func get_monster(id: String) -> Dictionary:
	var monster: Dictionary = MONSTERS.get(id, MONSTERS["debt_collector"]).duplicate(true)
	var monster_id := str(monster.get("id", id))
	monster["pattern_role"] = str(monster.get("pattern_role", MONSTER_PATTERN_ROLES.get(monster_id, "attack")))
	monster["pattern_read"] = str(monster.get("pattern_read", MONSTER_PATTERN_READS.get(monster_id, "")))
	monster["pattern_tuning"] = (monster.get("pattern_tuning", MONSTER_PATTERN_TUNING.get(monster_id, {})) as Dictionary).duplicate(true)
	if UiText.current_locale() == "ko" and MONSTER_KO_NAMES.has(monster_id):
		monster["name"] = MONSTER_KO_NAMES[monster_id]
	var tier := str(monster.get("tier", "normal"))
	return ContentMetadata.apply(monster, ContentMetadata.build(
		monster_id,
		str(monster.get("image_id", monster_id)),
		true,
		true,
		ContentMetadata.runtime_monster_visual_ready(monster_id),
		_rarity_for_tier(tier),
		["monster", tier]
	))

static func has_monster(id: String) -> bool:
	return MONSTERS.has(id)

static func pattern_role(id: String) -> String:
	var monster_id := id if MONSTERS.has(id) else "debt_collector"
	return str(MONSTER_PATTERN_ROLES.get(monster_id, "attack"))

static func pattern_read(id: String) -> String:
	var monster_id := id if MONSTERS.has(id) else "debt_collector"
	return str(MONSTER_PATTERN_READS.get(monster_id, ""))

static func pattern_tuning(id: String) -> Dictionary:
	var monster_id := id if MONSTERS.has(id) else "debt_collector"
	return (MONSTER_PATTERN_TUNING.get(monster_id, {}) as Dictionary).duplicate(true)

static func id_for_node(node_type: String, node_index: int = 0, floor_index: int = 1, seed_text: String = "") -> String:
	if node_type == "boss":
		return boss_id_for_floor(floor_index)
	if node_type == "elite":
		return elite_id_for_floor(floor_index, seed_text + ":elite:" + str(node_index))
	return normal_id_for_floor(floor_index, node_index, seed_text + ":combat:" + str(node_index))

static func id_for_random_node(node_type: String, floor_index: int, step: int, row_index: int, seed_text: String = "") -> String:
	if node_type == "boss":
		return boss_id_for_floor(floor_index)
	if node_type == "elite":
		return elite_id_for_floor(floor_index, seed_text + ":elite:" + str(step) + ":" + str(row_index))
	if node_type == "combat":
		return normal_id_for_floor(floor_index, step, seed_text + ":combat:" + str(step) + ":" + str(row_index))
	return ""

static func normal_id_for_floor(floor_index: int, node_index: int = 0, seed_text: String = "") -> String:
	var floor: int = clamp(floor_index, 1, 3)
	if floor == 1 and node_index <= 0:
		return "debt_collector"
	var pool: Array = ALWAYS_NORMAL_POOL.duplicate()
	for monster_id in FLOOR_NORMAL_POOLS.get(floor, FLOOR_NORMAL_POOLS[1]):
		if not pool.has(monster_id):
			pool.append(monster_id)
	return _pick_from_pool(pool, "normal:" + str(floor) + ":" + str(node_index) + ":" + seed_text)

static func elite_id_for_floor(floor_index: int, seed_text: String = "") -> String:
	var floor: int = clamp(floor_index, 1, 3)
	return _pick_from_pool(FLOOR_ELITE_POOLS.get(floor, FLOOR_ELITE_POOLS[1]), "elite:" + str(floor) + ":" + seed_text)

static func boss_id_for_floor(floor_index: int) -> String:
	var floor: int = clamp(floor_index, 1, 3)
	return str(FLOOR_BOSS_IDS.get(floor, FLOOR_BOSS_IDS[1]))

static func normal_pool_for_floor(floor_index: int) -> Array[String]:
	var floor: int = clamp(floor_index, 1, 3)
	var result: Array[String] = []
	for monster_id in ALWAYS_NORMAL_POOL:
		result.append(str(monster_id))
	for monster_id in FLOOR_NORMAL_POOLS.get(floor, FLOOR_NORMAL_POOLS[1]):
		if not result.has(str(monster_id)):
			result.append(str(monster_id))
	return result

static func elite_pool_for_floor(floor_index: int) -> Array[String]:
	var floor: int = clamp(floor_index, 1, 3)
	var result: Array[String] = []
	for monster_id in FLOOR_ELITE_POOLS.get(floor, FLOOR_ELITE_POOLS[1]):
		result.append(str(monster_id))
	return result

static func all_runtime_monster_ids() -> Array[String]:
	var result: Array[String] = []
	for monster_id in MONSTERS.keys():
		result.append(str(monster_id))
	return result

static func build_encounter_fields(monster_id: String, turn: int = 1) -> Dictionary:
	var monster := get_monster(monster_id)
	var pattern: Array = []
	for item in monster.get("move_pattern", []):
		pattern.append(str(item))
	var current_move_id: String = MonsterMoveCatalog.move_for_turn(pattern, turn)
	var tuning: Dictionary = (monster.get("pattern_tuning", {}) as Dictionary).duplicate(true)
	return {
		"monster_id": str(monster.get("id", monster_id)),
		"monster_name": str(monster.get("name", monster_id)),
		"monster_tier": str(monster.get("tier", "normal")),
		"monster_image_id": str(monster.get("image_id", monster_id)),
		"monster_visual_ready": bool(monster.get("visual_ready", false)),
		"monster_pattern_role": str(monster.get("pattern_role", "")),
		"monster_pattern_read": str(monster.get("pattern_read", "")),
		"monster_pattern_tuning": tuning.duplicate(true),
		"enemy_hp": int(monster.get("hp", 18)),
		"enemy_max_hp": int(monster.get("hp", 18)),
		"combat_cash": int(monster.get("combat_cash", 18)),
		"move_pattern": pattern,
		"current_move_id": current_move_id,
		"enemy_intent": MonsterMoveCatalog.intent_text(current_move_id, tuning)
	}

static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result

static func _pick_from_pool(pool: Array, seed_text: String) -> String:
	if pool.is_empty():
		return "debt_collector"
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("monster_pool:" + seed_text)
	return str(pool[rng.randi_range(0, pool.size() - 1)])

static func _rarity_for_tier(tier: String) -> String:
	match tier:
		"elite":
			return ContentMetadata.RARITY_RARE
		"boss":
			return ContentMetadata.RARITY_SPECIAL
		_:
			return ContentMetadata.RARITY_COMMON
