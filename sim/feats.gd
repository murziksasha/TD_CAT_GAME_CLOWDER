# Clowder: Alley Siege - In-Match Feats System
class_name SimFeats
extends RefCounted

const THRESHOLD_I: int = 100
const THRESHOLD_II: int = 350
const THRESHOLD_III: int = 900

const UNIVERSAL_CARDS: Array[Dictionary] = [
	{"id": "long_whiskers", "name": "Long Whiskers", "desc": "+12% range", "range_mult": 0.12, "weight": 10, "min_rank": 1, "max_rank": 3},
	{"id": "quick_paw", "name": "Quick Paw", "desc": "+10% attack speed", "speed_mult": 0.10, "weight": 10, "min_rank": 1, "max_rank": 3},
	{"id": "deep_bite", "name": "Deep Bite", "desc": "+1 damage, -10% attack speed", "damage_add": 1, "speed_mult": -0.10, "weight": 8, "min_rank": 1, "max_rank": 3},
	{"id": "careful_aim", "name": "Careful Aim", "desc": "+2 pierce, -8% range", "pierce_add": 2, "range_mult": -0.08, "weight": 8, "min_rank": 1, "max_rank": 3},
	{"id": "night_snack", "name": "Night Snack", "desc": "Gain Night Eye", "grant_night_eye": true, "weight": 3, "min_rank": 2, "max_rank": 3},
	{"id": "thrifty", "name": "Thrifty", "desc": "Next upgrade 8% off, once", "thrifty_discount": 0.08, "weight": 10, "min_rank": 1, "max_rank": 3},
	{"id": "veteran", "name": "Veteran", "desc": "+15% feat XP", "feat_xp_mult": 0.15, "weight": 10, "min_rank": 1, "max_rank": 1}
]

static func calculate_feat_rank(xp: float) -> int:
	if xp >= THRESHOLD_III:
		return 3
	elif xp >= THRESHOLD_II:
		return 2
	elif xp >= THRESHOLD_I:
		return 1
	return 0

static func generate_feat_offer(
	match_seed: int,
	cat_instance_id: int,
	feat_rank: int,
	path_bits: int,
	reroll_count: int,
	cat_id: String = ""
) -> Array[Dictionary]:
	var seed_val = (match_seed * 31 + cat_instance_id * 17 + feat_rank * 7 + path_bits * 13 + reroll_count * 101) & 0x7FFFFFFF
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	# Eligible pool
	var pool: Array[Dictionary] = []
	for card in UNIVERSAL_CARDS:
		if feat_rank >= card.get("min_rank", 1) and feat_rank <= card.get("max_rank", 3):
			pool.append(card)
			
	# Cat specific cards
	if cat_id == "pip":
		pool.append({"id": "pip_barbed_tip", "name": "Barbed Tip", "desc": "+1 damage vs Porcelain", "bonus_porcelain": 1, "weight": 12})
		pool.append({"id": "pip_bright_pupil", "name": "Bright Pupil", "desc": "Mark duration +2s", "mark_duration_bonus": 2.0, "weight": 12})
	
	# Shuffle / weighted pick 3 unique cards
	var picked: Array[Dictionary] = []
	var available = pool.duplicate()
	
	while picked.size() < 3 and not available.is_empty():
		var total_weight = 0
		for c in available:
			total_weight += int(c.get("weight", 10))
		var roll = rng.randi_range(0, total_weight - 1)
		var current = 0
		var chosen_idx = 0
		for i in range(available.size()):
			current += int(available[i].get("weight", 10))
			if roll < current:
				chosen_idx = i
				break
		picked.append(available[chosen_idx])
		available.remove_at(chosen_idx)
		
	return picked

