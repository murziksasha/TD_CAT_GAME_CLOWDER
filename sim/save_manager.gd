# Clowder: Alley Siege - Save Profile & Meta-Progression Manager
class_name SimSaveManager
extends RefCounted

const SAVE_PATH: String = "user://save_profile.json"
const BACKUP_PATH: String = "user://save_profile.json.bak"
const TMP_PATH: String = "user://save_profile.json.tmp"
const SALT: String = "clowder_whiskers_deterministic_salt_v1"

# Mastery Ranks (Rank 1 to 10) Cumulative XP thresholds from SPEC 06
const MASTERY_RANK_XP: Array[int] = [
	0,      # Rank 1: The cat, Tiers 1-2
	400,    # Rank 2: Tier 3 upgrades
	900,    # Rank 3: Dedicated Path Feat cards
	1600,   # Rank 4: Minor visual flourish
	2800,   # Rank 5: Tier 4 upgrades
	4500,   # Rank 6: Stat tracking badge
	7000,   # Rank 7: Mastery title
	11000,  # Rank 8: Tier 5 upgrades
	16000,  # Rank 9: Complete feat card pool
	23000   # Rank 10: Gold frame + Golden Bones reward
]

var data: Dictionary = {}

func _init() -> void:
	data = get_default_profile()

func get_default_profile() -> Dictionary:
	return {
		"account": {
			"level": 1,
			"xp": 0,
			"insight_points": 0,
			"insight_purchases": []
		},
		"economy": {
			"fishcoin": 0,
			"golden_bones": 0,
			"owned_shop_ids": []
		},
		"mastery": {
			"pip": 0,
			"nibs": 0,
			"pudding": 0,
			"biscuit": 0,
			"sable": 0,
			"nim": 0,
			"goldie": 0,
			"miso": 0,
			"bub": 0
		},
		"mastery_rank10_claimed": {},
		"medals": {
			"sunny_gutter": {
				"sunny": false,
				"alley": false,
				"night": false,
				"last_whisker": false,
				"bare_paw": false,
				"alternate_warrens": false,
				"full_nets": false,
				"short_leash": false
			}
		},
		"unlocked_cats": ["pip", "nibs"],
		"unlocked_heroes": ["mittens"],
		"unlocked_maps": ["sunny_gutter"],
		"trick_slots": 0,
		"unlock_queue": [],
		"trials": {
			"last_daily_date": "",
			"claimed_daily": false,
			"last_weekly_id": "",
			"claimed_weekly": false,
			"claimed_trials": []
		},
		"settings": {
			"speed": 1,
			"auto_start": false,
			"screen_shake": "low",
			"vfx_reduced": false,
			"text_scale": 100,
			"colorblind_shapes": true,
			"audio_volume": 0.8,
			"language": "en"
		},
		"expansion_runs": {
			"alley_crawl": null,
			"claimed_alley_crawl_results": []
		},
		"current_match": null
	}

func store_alley_crawl_run(run_state: Dictionary) -> bool:
	if run_state.is_empty() or int(run_state.get("schema_version", 0)) != 1:
		return false
	var expansion_runs: Dictionary = data.get("expansion_runs", {})
	expansion_runs["alley_crawl"] = run_state.duplicate(true)
	data["expansion_runs"] = expansion_runs
	return true

func get_alley_crawl_run() -> Dictionary:
	var stored = data.get("expansion_runs", {}).get("alley_crawl", null)
	return stored.duplicate(true) if stored is Dictionary else {}

func clear_alley_crawl_run() -> void:
	var expansion_runs: Dictionary = data.get("expansion_runs", {})
	expansion_runs["alley_crawl"] = null
	data["expansion_runs"] = expansion_runs

func claim_alley_crawl_completion(run_state: Dictionary, crawl_config: Dictionary) -> Dictionary:
	if not bool(run_state.get("completed", false)):
		return {"success": false, "reason": "Run is not complete"}
	var result_id := "%d:%d" % [int(run_state.get("generator_version", 0)), int(run_state.get("seed", 0))]
	var expansion_runs: Dictionary = data.get("expansion_runs", {})
	var claimed: Array = expansion_runs.get("claimed_alley_crawl_results", [])
	if result_id in claimed:
		return {"success": false, "reason": "Result already claimed", "result_id": result_id}
	var curse_bonus := 0
	for curse_id in run_state.get("curses", []):
		curse_bonus += int(crawl_config.get("curses", {}).get(curse_id, {}).get("fishcoin", 0))
	curse_bonus = mini(curse_bonus, int(crawl_config.get("curse_fishcoin_cap", 0)))
	var reward := int(crawl_config.get("completion_fishcoin", 0)) + curse_bonus
	add_fishcoin(reward)
	claimed.append(result_id)
	expansion_runs["claimed_alley_crawl_results"] = claimed
	data["expansion_runs"] = expansion_runs
	return {"success": true, "result_id": result_id, "fishcoin": reward, "curse_bonus": curse_bonus}

static func canonical_serialize(val: Variant) -> String:
	if val is Dictionary:
		var d = val as Dictionary
		var keys = d.keys()
		keys.sort()
		var parts: Array[String] = []
		for k in keys:
			parts.append(JSON.stringify(str(k)) + ":" + canonical_serialize(d[k]))
		return "{" + ",".join(parts) + "}"
	elif val is Array:
		var a = val as Array
		var parts: Array[String] = []
		for item in a:
			parts.append(canonical_serialize(item))
		return "[" + ",".join(parts) + "]"
	elif val is float:
		var f: float = val
		if is_equal_approx(f, round(f)):
			return str(int(round(f)))
		return "%.4f" % f
	elif val is int:
		return str(val)
	elif val is bool:
		return "true" if val else "false"
	elif val == null:
		return "null"
	else:
		return JSON.stringify(val)

# Compute SHA-256 hash over canonical serialized payload
func compute_checksum(payload: Dictionary) -> String:
	var json_str = canonical_serialize(payload)
	return (json_str + SALT).sha256_text()

func verify_checksum(payload: Dictionary, expected_checksum: String) -> bool:
	return compute_checksum(payload) == expected_checksum

func load_profile() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		data = get_default_profile()
		save_profile()
		return true

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		data = get_default_profile()
		return false

	var content = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if parsed == null or not (parsed is Dictionary):
		data = get_default_profile()
		return false

	var payload = parsed.get("payload", {})
	var checksum = str(parsed.get("checksum", ""))

	if not verify_checksum(payload, checksum):
		push_warning("Profile checksum verification failed! Reverting to safe default.")
		data = get_default_profile()
		return false

	data = payload
	# Ensure all required top-level keys exist
	var def = get_default_profile()
	for k in def.keys():
		if not data.has(k):
			data[k] = def[k]
	var mastery: Dictionary = data.get("mastery", {})
	if not mastery.has("bub"):
		mastery["bub"] = 0
	data["mastery"] = mastery
	return true

func save_profile() -> bool:
	var checksum = compute_checksum(data)
	var root = {
		"version": 1,
		"checksum": checksum,
		"payload": data
	}
	var content = JSON.stringify(root, "  ")

	# Safe atomic write via temporary file
	var tmp = FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if not tmp:
		return false
	tmp.store_string(content)
	tmp.flush()
	tmp.close()

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
		DirAccess.remove_absolute(SAVE_PATH)

	DirAccess.rename_absolute(TMP_PATH, SAVE_PATH)
	return true

# ------------------------------------------------------------------------------
# ACCOUNT XP & LEVEL PROGRESSION
# ------------------------------------------------------------------------------

func get_xp_for_next_level(lvl: int, levels_data: Dictionary) -> int:
	var base = int(levels_data.get("base_cost", 120))
	var per_lvl = int(levels_data.get("cost_per_level", 30))
	return base + (per_lvl * lvl)

func add_account_xp(amount: int, levels_data: Dictionary) -> Dictionary:
	var acc: Dictionary = data.get("account", {})
	var cur_lvl = int(acc.get("level", 1))
	var cur_xp = int(acc.get("xp", 0)) + amount
	var levels_gained = 0
	var new_unlocks: Array = []

	var level_unlocks_table: Dictionary = levels_data.get("level_unlocks", {})

	while cur_lvl < 40:
		var req = get_xp_for_next_level(cur_lvl, levels_data)
		if cur_xp >= req:
			cur_xp -= req
			cur_lvl += 1
			levels_gained += 1
			acc["insight_points"] = int(acc.get("insight_points", 0)) + 1
			# Award +15 fishcoin per level up
			add_fishcoin(15)

			# Check level unlocks
			var l_str = str(cur_lvl)
			if level_unlocks_table.has(l_str):
				var unl = level_unlocks_table[l_str]
				new_unlocks.append(unl)
				_enqueue_unlocks(unl)
		else:
			break

	acc["level"] = cur_lvl
	acc["xp"] = cur_xp
	data["account"] = acc

	return {
		"new_level": cur_lvl,
		"levels_gained": levels_gained,
		"new_unlocks": new_unlocks
	}

func _enqueue_unlocks(unl: Dictionary) -> void:
	var queue: Array = data.get("unlock_queue", [])
	if unl.has("cats"):
		for c in unl["cats"]:
			queue.append({"type": "cat", "id": c})
	if unl.has("heroes"):
		for h in unl["heroes"]:
			queue.append({"type": "hero", "id": h})
	if unl.has("maps"):
		for m in unl["maps"]:
			queue.append({"type": "map", "id": m})
	if unl.has("trick_slots"):
		data["trick_slots"] = int(unl["trick_slots"])
	data["unlock_queue"] = queue

func drain_unlock_queue(max_cats: int = 2, max_heroes: int = 1, max_maps: int = 1) -> Dictionary:
	var queue: Array = data.get("unlock_queue", [])
	var revealed_cats: Array = []
	var revealed_heroes: Array = []
	var revealed_maps: Array = []
	var remaining_queue: Array = []

	var unlocked_cats: Array = data.get("unlocked_cats", [])
	var unlocked_heroes: Array = data.get("unlocked_heroes", [])
	var unlocked_maps: Array = data.get("unlocked_maps", [])

	for item in queue:
		var itype = item.get("type", "")
		var iid = item.get("id", "")
		if itype == "cat" and revealed_cats.size() < max_cats:
			revealed_cats.append(iid)
			if not unlocked_cats.has(iid):
				unlocked_cats.append(iid)
		elif itype == "hero" and revealed_heroes.size() < max_heroes:
			revealed_heroes.append(iid)
			if not unlocked_heroes.has(iid):
				unlocked_heroes.append(iid)
		elif itype == "map" and revealed_maps.size() < max_maps:
			revealed_maps.append(iid)
			if not unlocked_maps.has(iid):
				unlocked_maps.append(iid)
		else:
			remaining_queue.append(item)

	data["unlock_queue"] = remaining_queue
	data["unlocked_cats"] = unlocked_cats
	data["unlocked_heroes"] = unlocked_heroes
	data["unlocked_maps"] = unlocked_maps

	return {
		"cats": revealed_cats,
		"heroes": revealed_heroes,
		"maps": revealed_maps
	}

# ------------------------------------------------------------------------------
# ECONOMY & PRESTIGE CURRENCY (FISHCOIN & GOLDEN BONES)
# ------------------------------------------------------------------------------

func add_fishcoin(amount: int) -> int:
	var eco: Dictionary = data.get("economy", {})
	eco["fishcoin"] = int(eco.get("fishcoin", 0)) + amount
	data["economy"] = eco
	return int(eco["fishcoin"])

func add_golden_bones(amount: int) -> int:
	var eco: Dictionary = data.get("economy", {})
	eco["golden_bones"] = int(eco.get("golden_bones", 0)) + amount
	data["economy"] = eco
	return int(eco["golden_bones"])

func spend_fishcoin(amount: int) -> bool:
	var eco: Dictionary = data.get("economy", {})
	var cur = int(eco.get("fishcoin", 0))
	if cur >= amount:
		eco["fishcoin"] = cur - amount
		data["economy"] = eco
		return true
	return false

func spend_golden_bones(amount: int) -> bool:
	var eco: Dictionary = data.get("economy", {})
	var cur = int(eco.get("golden_bones", 0))
	if cur >= amount:
		eco["golden_bones"] = cur - amount
		data["economy"] = eco
		return true
	return false

func is_item_owned(item_id: String) -> bool:
	var eco: Dictionary = data.get("economy", {})
	var owned: Array = eco.get("owned_shop_ids", [])
	return owned.has(item_id)

func buy_shop_item(item_id: String, cost: int, is_prestige: bool = false) -> bool:
	if is_item_owned(item_id):
		return false
	var success = false
	if is_prestige:
		success = spend_golden_bones(cost)
	else:
		success = spend_fishcoin(cost)

	if success:
		var eco: Dictionary = data.get("economy", {})
		var owned: Array = eco.get("owned_shop_ids", [])
		owned.append(item_id)
		eco["owned_shop_ids"] = owned
		data["economy"] = eco
		save_profile()
	return success

# ------------------------------------------------------------------------------
# CAT MASTERY (RANKS 1 TO 10)
# ------------------------------------------------------------------------------

func get_mastery_rank(cat_id: String) -> int:
	var mdict: Dictionary = data.get("mastery", {})
	var xp = int(mdict.get(cat_id, 0))
	var rank = 1
	for r in range(MASTERY_RANK_XP.size()):
		if xp >= MASTERY_RANK_XP[r]:
			rank = r + 1
		else:
			break
	return rank

func is_tier_unlocked(cat_id: String, tier: int) -> bool:
	var rank = get_mastery_rank(cat_id)
	match tier:
		1, 2: return rank >= 1
		3: return rank >= 2
		4: return rank >= 5
		5: return rank >= 8
		_: return false

func add_cat_mastery_xp(cat_id: String, xp_amount: int) -> Dictionary:
	var mdict: Dictionary = data.get("mastery", {})
	var cur_xp = int(mdict.get(cat_id, 0))
	var old_rank = get_mastery_rank(cat_id)
	cur_xp += xp_amount
	mdict[cat_id] = cur_xp
	data["mastery"] = mdict

	var new_rank = get_mastery_rank(cat_id)
	var rank10_bonus = false

	# If rank 10 is reached, award +5 Golden Bones once
	var rank10_claimed: Dictionary = data.get("mastery_rank10_claimed", {})
	if new_rank >= 10 and not rank10_claimed.get(cat_id, false):
		rank10_claimed[cat_id] = true
		data["mastery_rank10_claimed"] = rank10_claimed
		add_golden_bones(5)
		rank10_bonus = true

	return {
		"old_rank": old_rank,
		"new_rank": new_rank,
		"gained_rank10": rank10_bonus
	}

# ------------------------------------------------------------------------------
# MATCH COMPLETION & MEDAL SYSTEM
# ------------------------------------------------------------------------------

func record_match_completion(
	map_id: String,
	mode_idx: int,
	rounds_cleared: int,
	is_victory: bool,
	fielded_cat_damages: Dictionary,
	levels_data: Dictionary,
	freeplay_rounds: int = 0
) -> Dictionary:
	var mode_keys = ["sunny", "alley", "night", "last_whisker", "bare_paw"]
	var mode_str = mode_keys[clampi(mode_idx, 0, mode_keys.size() - 1)]

	# 1. Calculate Account XP
	var mode_multipliers: Dictionary = levels_data.get("mode_multipliers", {})
	var mult = float(mode_multipliers.get(mode_str, 1.0))

	# First Sunny clear grants 1.00 instead of 0.70
	var map_medals: Dictionary = data.get("medals", {}).get(map_id, {})
	var is_first_clear = not map_medals.get(mode_str, false)
	if mode_str == "sunny" and is_first_clear:
		mult = float(mode_multipliers.get("sunny_first_clear", 1.0))

	var total_account_xp = 0
	for r in range(1, rounds_cleared + 1):
		total_account_xp += int(round((20.0 + 2.0 * float(r)) * mult))

	# Freeplay flat XP
	if freeplay_rounds > 0:
		total_account_xp += freeplay_rounds * int(levels_data.get("freeplay_flat_xp", 15))

	var xp_res = add_account_xp(total_account_xp, levels_data)

	# 2. Mastery XP for fielded cats
	var mastery_gains: Dictionary = {}
	for cat_id in fielded_cat_damages.keys():
		var dmg = int(fielded_cat_damages[cat_id])
		var m_xp = max(20, int(round(float(dmg) * 0.15 * mult)))
		var m_res = add_cat_mastery_xp(cat_id, m_xp)
		mastery_gains[cat_id] = {
			"xp": m_xp,
			"rank": m_res["new_rank"],
			"rank_up": m_res["new_rank"] > m_res["old_rank"],
			"rank10": m_res["gained_rank10"]
		}

	# 3. Currency rewards and Medals
	var fishcoin_awarded = 0
	var golden_bones_awarded = 0

	if is_victory:
		if not data["medals"].has(map_id):
			data["medals"][map_id] = {
				"sunny": false, "alley": false, "night": false,
				"last_whisker": false, "bare_paw": false
			}

		if is_first_clear:
			data["medals"][map_id][mode_str] = true
			# First-time rewards from SPEC 08 & Master Plan
			match mode_str:
				"sunny":
					fishcoin_awarded += 50
				"alley":
					fishcoin_awarded += 80
					golden_bones_awarded += 1
				"night":
					fishcoin_awarded += 110
					golden_bones_awarded += 2
				"last_whisker":
					fishcoin_awarded += 150
					golden_bones_awarded += 3
				"bare_paw":
					fishcoin_awarded += 200
					golden_bones_awarded += 5
		else:
			# Repeat clear rewards
			match mode_str:
				"sunny": fishcoin_awarded += 10
				"alley": fishcoin_awarded += 15
				"night": fishcoin_awarded += 20
				"last_whisker": fishcoin_awarded += 25
				"bare_paw": fishcoin_awarded += 40

		# Freeplay bonus: 1 Golden Bone every 10 waves cleared past round 100
		if freeplay_rounds >= 10:
			golden_bones_awarded += int(floor(float(freeplay_rounds) / 10.0))

		add_fishcoin(fishcoin_awarded)
		add_golden_bones(golden_bones_awarded)

	# 4. Drain unlock queue ceremony
	var revealed_unlocks = drain_unlock_queue(2, 1, 1)

	# 5. Persist profile
	save_profile()

	return {
		"account_xp_gained": total_account_xp,
		"new_level": xp_res["new_level"],
		"levels_gained": xp_res["levels_gained"],
		"fishcoin_gained": fishcoin_awarded,
		"golden_bones_gained": golden_bones_awarded,
		"is_first_clear": is_first_clear and is_victory,
		"mastery_gains": mastery_gains,
		"revealed_unlocks": revealed_unlocks
	}

# ------------------------------------------------------------------------------
# DETERMINISTIC DAILY CHALLENGES & WEEKLY TRIALS
# ------------------------------------------------------------------------------

func get_daily_challenge(date_str: String = "") -> Dictionary:
	if date_str.is_empty():
		date_str = Time.get_date_string_from_system()

	# Deterministic hash seed from date string
	var seed_val = int(("daily_" + date_str).sha256_text().substr(0, 8).hex_to_int())
	var maps = ["sunny_gutter", "market_lane", "rooftop_crossing", "stall_row", "canal_night"]
	var mods = ["alternate_warrens", "full_nets", "short_leash"]

	var map_pick = maps[seed_val % maps.size()]
	var mod_pick = mods[(seed_val >> 3) % mods.size()]

	var claimed_trials: Array = data.get("trials", {}).get("claimed_trials", [])
	var is_claimed = claimed_trials.has("daily_" + date_str)

	return {
		"id": "daily_" + date_str,
		"date": date_str,
		"map": map_pick,
		"mode": 1, # Alley difficulty
		"modifier": mod_pick,
		"reward_fishcoin": 30,
		"reward_golden_bones": 1,
		"claimed": is_claimed
	}

func claim_daily_challenge(date_str: String = "") -> Dictionary:
	var challenge = get_daily_challenge(date_str)
	var tid = challenge["id"]
	var trials: Dictionary = data.get("trials", {})
	var claimed: Array = trials.get("claimed_trials", [])

	if claimed.has(tid):
		return {"success": false, "reason": "already_claimed"}

	claimed.append(tid)
	trials["claimed_trials"] = claimed
	data["trials"] = trials

	add_fishcoin(challenge["reward_fishcoin"])
	add_golden_bones(challenge["reward_golden_bones"])
	save_profile()

	return {
		"success": true,
		"fishcoin": challenge["reward_fishcoin"],
		"golden_bones": challenge["reward_golden_bones"]
	}
