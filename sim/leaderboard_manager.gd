# Clowder: Alley Siege - Leaderboard & Rating Database Manager
class_name SimLeaderboardManager
extends RefCounted

const SAVE_PATH: String = "user://leaderboards.json"
const SALT: String = "clowder_whiskers_deterministic_salt_v1"

var entries: Array[Dictionary] = []

func _init() -> void:
	load_leaderboard()

static func calculate_score(rounds_cleared: int, max_rounds: int, remaining_lives: int, peak_kibble: int, won: bool, mode: int, difficulty: String, clean_sheet: bool) -> int:
	var mode_mults = {
		0: 1.0,  # SUNNY
		1: 1.5,  # ALLEY
		2: 2.0,  # NIGHT
		3: 3.0,  # LAST_WHISKER
		4: 4.0   # BARE_PAW
	}
	var diff_mults = {
		"beginner": 1.0,
		"beginner_plus": 1.15,
		"intermediate": 1.35,
		"advanced": 1.6,
		"expert": 2.0
	}
	var m_mult: float = mode_mults.get(mode, 1.0)
	var d_mult: float = diff_mults.get(difficulty.to_lower(), 1.0)

	var base_score: float = float(rounds_cleared) * 120.0
	base_score += float(remaining_lives) * 15.0
	base_score += float(peak_kibble) * 0.1
	if won:
		base_score += 1000.0
	if clean_sheet:
		base_score += 500.0

	return int(round(base_score * m_mult * d_mult))

func get_default_database() -> Array[Dictionary]:
	var authentic_rivals = [
		{"name": "Baron_Salt", "hero": "baron", "map": "grand_bazaar", "diff": "advanced", "mode": 4, "wave": 100, "won": true, "score": 98500, "date": "2026-10-12"},
		{"name": "Mittens_Protector", "hero": "mittens", "map": "the_warren", "diff": "expert", "mode": 3, "wave": 100, "won": true, "score": 94200, "date": "2026-10-15"},
		{"name": "Duchess_AlleyQueen", "hero": "duchess", "map": "night_onion", "diff": "advanced", "mode": 4, "wave": 100, "won": true, "score": 91800, "date": "2026-10-18"},
		{"name": "SisterPebble_Zen", "hero": "pebble", "map": "canal_night", "diff": "advanced", "mode": 4, "wave": 100, "won": true, "score": 88400, "date": "2026-10-20"},
		{"name": "Clowder_GrandMaster", "hero": "mittens", "map": "fishmarket_maze", "diff": "advanced", "mode": 3, "wave": 100, "won": true, "score": 85600, "date": "2026-10-22"},
		{"name": "FishMarket_Watcher", "hero": "baron", "map": "twin_gutters", "diff": "intermediate", "mode": 4, "wave": 100, "won": true, "score": 82900, "date": "2026-10-25"},
		{"name": "Whiskers_Vindicator", "hero": "duchess", "map": "basket_bridge", "diff": "intermediate", "mode": 4, "wave": 100, "won": true, "score": 79500, "date": "2026-10-27"},
		{"name": "AlleyProwler_99", "hero": "mittens", "map": "rooftop_crossing", "diff": "intermediate", "mode": 3, "wave": 98, "won": false, "score": 76200, "date": "2026-10-29"},
		{"name": "ShadowCatcher", "hero": "pebble", "map": "canopy_cross", "diff": "intermediate", "mode": 4, "wave": 100, "won": true, "score": 74100, "date": "2026-10-30"},
		{"name": "Tuna_Tycoon", "hero": "baron", "map": "two_purse_lane", "diff": "advanced", "mode": 2, "wave": 80, "won": true, "score": 71800, "date": "2026-11-01"},
		{"name": "VelvetPaw", "hero": "mittens", "map": "copper_scale", "diff": "intermediate", "mode": 3, "wave": 95, "won": false, "score": 69300, "date": "2026-11-02"},
		{"name": "CobbleRunner", "hero": "duchess", "map": "welcome_bridge", "diff": "intermediate", "mode": 4, "wave": 100, "won": true, "score": 67400, "date": "2026-11-03"},
		{"name": "MidnightCat", "hero": "mittens", "map": "chimney_step", "diff": "intermediate", "mode": 3, "wave": 92, "won": false, "score": 65200, "date": "2026-11-04"},
		{"name": "GutterSniper", "hero": "baron", "map": "sunny_gutter", "diff": "beginner", "mode": 4, "wave": 100, "won": true, "score": 63800, "date": "2026-11-05"},
		{"name": "AlleyKeeper_Prime", "hero": "pebble", "map": "stall_row", "diff": "beginner_plus", "mode": 4, "wave": 100, "won": true, "score": 62100, "date": "2026-11-05"},
		{"name": "Fishbone_Fighter", "hero": "mittens", "map": "fishbone_straight", "diff": "beginner", "mode": 4, "wave": 100, "won": true, "score": 59800, "date": "2026-11-06"},
		{"name": "SackCorner_Boss", "hero": "duchess", "map": "sack_corner", "diff": "beginner_plus", "mode": 3, "wave": 90, "won": false, "score": 57900, "date": "2026-11-06"},
		{"name": "HerringGuard", "hero": "baron", "map": "herring_square", "diff": "beginner_plus", "mode": 3, "wave": 88, "won": false, "score": 55400, "date": "2026-11-07"},
		{"name": "Lantern_Lookout", "hero": "pebble", "map": "lantern_stoop", "diff": "beginner", "mode": 3, "wave": 85, "won": false, "score": 53200, "date": "2026-11-07"},
		{"name": "PuddleJumper", "hero": "mittens", "map": "puddle_court", "diff": "beginner_plus", "mode": 2, "wave": 80, "won": true, "score": 51000, "date": "2026-11-08"},
		{"name": "Crabapple_Cat", "hero": "duchess", "map": "crabapple_bend", "diff": "beginner", "mode": 3, "wave": 82, "won": false, "score": 48900, "date": "2026-11-08"},
		{"name": "SpiceMercenary", "hero": "baron", "map": "spice_arcade", "diff": "beginner_plus", "mode": 2, "wave": 80, "won": true, "score": 46800, "date": "2026-11-09"},
		{"name": "MarketStroller", "hero": "pebble", "map": "market_lane", "diff": "beginner_plus", "mode": 2, "wave": 80, "won": true, "score": 44500, "date": "2026-11-09"},
		{"name": "MorningHerald", "hero": "mittens", "map": "morning_arch", "diff": "beginner", "mode": 2, "wave": 80, "won": true, "score": 42100, "date": "2026-11-10"},
		{"name": "FigTwine_Trader", "hero": "duchess", "map": "fig_and_twine", "diff": "beginner_plus", "mode": 1, "wave": 60, "won": true, "score": 39500, "date": "2026-11-10"},
		{"name": "WeighHouse_Scale", "hero": "baron", "map": "weigh_house", "diff": "intermediate", "mode": 1, "wave": 60, "won": true, "score": 37200, "date": "2026-11-11"},
		{"name": "SunnyDay_Defender", "hero": "mittens", "map": "sunny_gutter", "diff": "beginner", "mode": 0, "wave": 40, "won": true, "score": 35100, "date": "2026-11-11"},
		{"name": "NoviceWhisker", "hero": "mittens", "map": "lantern_stoop", "diff": "beginner", "mode": 0, "wave": 40, "won": true, "score": 31200, "date": "2026-11-12"}
	]

	var result: Array[Dictionary] = []
	for r in authentic_rivals:
		var d = r.duplicate()
		d["is_local_player"] = false
		result.append(d)

	# Generate filler authentic records to make a rich Top 100 ladder
	var heroes = ["mittens", "duchess", "baron", "pebble"]
	var maps = ["sunny_gutter", "twin_gutters", "grand_bazaar", "lantern_stoop", "market_lane", "rooftop_crossing"]
	var diffs = ["beginner", "beginner_plus", "intermediate", "advanced", "expert"]
	for i in range(result.size(), 100):
		var rank_val = 100 - i
		var score_val = 1500 + rank_val * 380 + (i % 5) * 45
		result.append({
			"name": "Keeper_%03d" % (i + 1),
			"hero": heroes[i % heroes.size()],
			"map": maps[i % maps.size()],
			"diff": diffs[i % diffs.size()],
			"mode": i % 5,
			"wave": 40 + (i % 61),
			"won": (i % 3) != 0,
			"score": score_val,
			"date": "2026-11-1%02d" % (1 + (i % 4)),
			"is_local_player": false
		})

	result.sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))
	return result

func load_leaderboard() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		entries = get_default_database()
		save_leaderboard()
		return true

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		entries = get_default_database()
		return false

	var content = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if parsed == null or not (parsed is Dictionary):
		entries = get_default_database()
		return false

	var payload: Array = parsed.get("payload", [])
	entries.clear()
	for item in payload:
		if item is Dictionary:
			entries.append(item)

	if entries.is_empty():
		entries = get_default_database()
		save_leaderboard()
		return true

	entries.sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))
	return true

func save_leaderboard() -> bool:
	entries.sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))
	if entries.size() > 100:
		entries = entries.slice(0, 100)

	var payload_json = JSON.stringify(entries)
	var checksum = (payload_json + SALT).sha256_text()

	var envelope = {
		"version": 1,
		"checksum": checksum,
		"payload": entries
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return false

	file.store_string(JSON.stringify(envelope, "  "))
	file.close()
	return true

func record_match(
	player_name: String,
	map_id: String,
	difficulty: String,
	mode: int,
	rounds_cleared: int,
	max_rounds: int,
	remaining_lives: int,
	peak_kibble: int,
	won: bool,
	hero_id: String,
	clean_sheet: bool
) -> Dictionary:
	var final_score = calculate_score(rounds_cleared, max_rounds, remaining_lives, peak_kibble, won, mode, difficulty, clean_sheet)
	var current_date = "2026-11-14"

	var entry = {
		"name": player_name if player_name != "" else "AlleyKeeper",
		"hero": hero_id if hero_id != "" else "mittens",
		"map": map_id,
		"diff": difficulty,
		"mode": mode,
		"wave": rounds_cleared,
		"won": won,
		"score": final_score,
		"date": current_date,
		"is_local_player": true
	}

	entries.append(entry)
	entries.sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))

	var rank = -1
	for i in range(entries.size()):
		if entries[i] == entry:
			rank = i + 1
			break

	save_leaderboard()

	return {
		"score": final_score,
		"rank": rank,
		"in_top_100": rank > 0 and rank <= 100
	}

func get_top_100(map_filter: String = "", mode_filter: int = -1) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for item in entries:
		if map_filter != "" and item.get("map", "") != map_filter:
			continue
		if mode_filter >= 0 and int(item.get("mode", 0)) != mode_filter:
			continue
		filtered.append(item)

	filtered.sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))
	if filtered.size() > 100:
		filtered = filtered.slice(0, 100)

	var result: Array[Dictionary] = []
	for i in range(filtered.size()):
		var copy = filtered[i].duplicate()
		copy["rank"] = i + 1
		result.append(copy)

	return result
