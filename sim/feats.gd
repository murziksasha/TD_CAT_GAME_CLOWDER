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

const CAT_CARDS: Dictionary = {
	"pip": [
		{"id": "pip_barbed_tip", "name": "Barbed Tip", "desc": "+1 damage vs Porcelain", "bonus_porcelain": 1, "weight": 12, "req_path": "path_a", "min_tier": 1},
		{"id": "pip_spool_rhythm", "name": "Spool Rhythm", "desc": "Burst fires every 4th shot", "burst_interval": 4, "weight": 10, "req_path": "path_a", "min_tier": 3},
		{"id": "pip_bright_pupil", "name": "Bright Pupil", "desc": "Mark duration +2s", "mark_duration_bonus": 2.0, "weight": 12, "req_path": "path_b", "min_tier": 2},
		{"id": "pip_night_drill", "name": "Night Drill", "desc": "+15% range against Shadow", "range_mult": 0.15, "weight": 10, "req_path": "path_b", "min_tier": 2},
		{"id": "pip_loose_thread", "name": "Loose Thread", "desc": "+1 needle fired", "extra_projectiles": 1, "weight": 12, "req_path": "path_c", "min_tier": 1},
		{"id": "pip_sticky_cloud", "name": "Sticky Cloud", "desc": "Yarn clouds last +3s", "cloud_duration_bonus": 3.0, "weight": 10, "req_path": "path_c", "min_tier": 3}
	],
	"nibs": [
		{"id": "nibs_extra_claws", "name": "Extra Claws", "desc": "+2 attack arcs", "extra_projectiles": 2, "weight": 12, "req_path": "path_a", "min_tier": 1},
		{"id": "nibs_razor_edge", "name": "Razor Edge", "desc": "+1 claw damage", "damage_add": 1, "weight": 10, "req_path": "path_a", "min_tier": 2},
		{"id": "nibs_fiery_fur", "name": "Fiery Fur", "desc": "+1s burn duration", "burn_duration_bonus": 1.0, "weight": 12, "req_path": "path_b", "min_tier": 1},
		{"id": "nibs_sparking_claws", "name": "Sparking Claws", "desc": "+1 burn DPS", "burn_dps_bonus": 1.0, "weight": 10, "req_path": "path_b", "min_tier": 2},
		{"id": "nibs_long_leap", "name": "Long Leap", "desc": "+20% pounce range", "range_mult": 0.20, "weight": 12, "req_path": "path_c", "min_tier": 1},
		{"id": "nibs_quake_pounce", "name": "Quake Pounce", "desc": "Shockwave every 4th attack", "burst_interval": 4, "weight": 10, "req_path": "path_c", "min_tier": 3}
	],
	"pudding": [
		{"id": "pudding_deep_chill", "name": "Deep Chill", "desc": "+0.5s freeze duration", "freeze_duration_bonus": 0.5, "weight": 12, "req_path": "path_a", "min_tier": 1},
		{"id": "pudding_cold_snap", "name": "Cold Snap", "desc": "+1 pulse damage", "damage_add": 1, "weight": 10, "req_path": "path_a", "min_tier": 2},
		{"id": "pudding_brittle_bite", "name": "Brittle Bite", "desc": "+1 damage vs brittle targets", "bonus_porcelain": 1, "weight": 12, "req_path": "path_b", "min_tier": 1},
		{"id": "pudding_rat_chiller", "name": "Rat Chiller", "desc": "+2 bonus damage vs rats", "bonus_rats": 2, "weight": 10, "req_path": "path_b", "min_tier": 2},
		{"id": "pudding_lingering_frost", "name": "Lingering Frost", "desc": "+1.5s post-freeze slow", "slow_duration_bonus": 1.5, "weight": 12, "req_path": "path_c", "min_tier": 1},
		{"id": "pudding_ice_splinter", "name": "Ice Splinter", "desc": "+15% pulse radius", "range_mult": 0.15, "weight": 10, "req_path": "path_c", "min_tier": 2}
	],
	"biscuit": [
		{"id": "biscuit_heavy_shell", "name": "Heavy Shell", "desc": "+1 blast damage", "damage_add": 1, "weight": 12, "req_path": "path_a", "min_tier": 1},
		{"id": "biscuit_bunker_buster", "name": "Bunker Buster", "desc": "+3 damage vs rats", "bonus_rats": 3, "weight": 10, "req_path": "path_a", "min_tier": 2},
		{"id": "biscuit_extra_shards", "name": "Extra Shards", "desc": "+2 cluster crumbs", "extra_projectiles": 2, "weight": 12, "req_path": "path_b", "min_tier": 1},
		{"id": "biscuit_fiery_shards", "name": "Fiery Shards", "desc": "+1s scorch duration", "burn_duration_bonus": 1.0, "weight": 10, "req_path": "path_b", "min_tier": 2},
		{"id": "biscuit_fast_fuse", "name": "Fast Fuse", "desc": "+12% attack speed", "speed_mult": 0.12, "weight": 12, "req_path": "path_c", "min_tier": 1},
		{"id": "biscuit_shrapnel_bloom", "name": "Shrapnel Bloom", "desc": "+15 explosion radius", "explosion_radius_bonus": 15.0, "weight": 10, "req_path": "path_c", "min_tier": 2}
	],
	"sable": [
		{"id": "sable_armor_piercer", "name": "Armor Piercer", "desc": "+2 damage vs Porcelain", "bonus_porcelain": 2, "weight": 12, "req_path": "path_a", "min_tier": 1},
		{"id": "sable_heavy_barrel", "name": "Heavy Barrel", "desc": "+3 damage vs rats", "bonus_rats": 3, "weight": 10, "req_path": "path_a", "min_tier": 2},
		{"id": "sable_flak_spread", "name": "Flak Spread", "desc": "+15 splash radius", "explosion_radius_bonus": 15.0, "weight": 12, "req_path": "path_b", "min_tier": 1},
		{"id": "sable_ricochet_tip", "name": "Ricochet Tip", "desc": "+1 ricochet bounce", "extra_projectiles": 1, "weight": 10, "req_path": "path_b", "min_tier": 2},
		{"id": "sable_hair_trigger", "name": "Hair Trigger", "desc": "+12% attack speed", "speed_mult": 0.12, "weight": 12, "req_path": "path_c", "min_tier": 1},
		{"id": "sable_steady_scope", "name": "Steady Scope", "desc": "+15% crit chance", "crit_chance": 0.15, "weight": 10, "req_path": "path_c", "min_tier": 2}
	],
	"nim": [
		{"id": "nim_focus_prism", "name": "Focus Prism", "desc": "+1 magic damage", "damage_add": 1, "weight": 12, "req_path": "path_a", "min_tier": 1},
		{"id": "nim_arcane_lance", "name": "Arcane Lance", "desc": "+3 spark pierce", "pierce_add": 3, "weight": 10, "req_path": "path_a", "min_tier": 2},
		{"id": "nim_warm_spark", "name": "Warm Spark", "desc": "+1 burn DPS", "burn_dps_bonus": 1.0, "weight": 12, "req_path": "path_b", "min_tier": 1},
		{"id": "nim_wide_cone", "name": "Wide Cone", "desc": "+15% cone range", "range_mult": 0.15, "weight": 10, "req_path": "path_b", "min_tier": 2},
		{"id": "nim_static_charge", "name": "Static Charge", "desc": "+1.5s hex duration", "hex_duration_bonus": 1.5, "weight": 12, "req_path": "path_c", "min_tier": 1},
		{"id": "nim_mana_burn", "name": "Mana Burn", "desc": "+1 hex DPS", "hex_dps_bonus": 1.0, "weight": 10, "req_path": "path_c", "min_tier": 2}
	],
	"goldie": [
		{"id": "goldie_big_catch", "name": "Big Catch", "desc": "+30 kibble per round", "extra_round_kibble": 30, "weight": 12, "req_path": "path_a", "min_tier": 1},
		{"id": "goldie_deep_net", "name": "Deep Net", "desc": "+50 kibble per round", "extra_round_kibble": 50, "weight": 10, "req_path": "path_a", "min_tier": 2},
		{"id": "goldie_swift_cast", "name": "Swift Cast", "desc": "Catch meter fills faster", "speed_mult": 0.20, "weight": 12, "req_path": "path_b", "min_tier": 1},
		{"id": "goldie_trophy_scale", "name": "Trophy Scale", "desc": "+40 kibble per round", "extra_round_kibble": 40, "weight": 10, "req_path": "path_b", "min_tier": 2},
		{"id": "goldie_merchant_eye", "name": "Merchant Eye", "desc": "Next cat placement 50 cheaper", "thrifty_discount": 0.10, "weight": 12, "req_path": "path_c", "min_tier": 1},
		{"id": "goldie_market_stall", "name": "Market Stall", "desc": "+25 kibble per round", "extra_round_kibble": 25, "weight": 10, "req_path": "path_c", "min_tier": 2}
	],
	"miso": [
		{"id": "miso_extra_roast", "name": "Extra Roast", "desc": "+5% attack speed in aura", "speed_mult": 0.05, "weight": 12, "req_path": "path_a", "min_tier": 1},
		{"id": "miso_sweet_syrup", "name": "Sweet Syrup", "desc": "+10% range in aura", "range_mult": 0.10, "weight": 10, "req_path": "path_a", "min_tier": 2},
		{"id": "miso_cozy_corner", "name": "Cozy Corner", "desc": "+20 aura radius", "range_mult": 0.15, "weight": 12, "req_path": "path_b", "min_tier": 1},
		{"id": "miso_warm_hearth", "name": "Warm Hearth", "desc": "+1 pierce in aura", "pierce_add": 1, "weight": 10, "req_path": "path_b", "min_tier": 2},
		{"id": "miso_loyal_customer", "name": "Loyal Customer", "desc": "5% higher aura discount", "thrifty_discount": 0.05, "weight": 12, "req_path": "path_c", "min_tier": 1},
		{"id": "miso_quick_whisk", "name": "Quick Whisk", "desc": "Bell cooldown -10%", "speed_mult": 0.10, "weight": 10, "req_path": "path_c", "min_tier": 2}
	],
	"bub": [
		{"id": "bub_thick_glass", "name": "Thick Glass", "desc": "+1 flask pierce", "pierce_add": 1, "weight": 12, "req_path": "path_a", "min_tier": 1},
		{"id": "bub_lingering_fizz", "name": "Lingering Fizz", "desc": "+1s corrosion duration", "corrosion_duration_bonus": 1.0, "weight": 10, "req_path": "path_a", "min_tier": 2},
		{"id": "bub_longer_ladle", "name": "Longer Ladle", "desc": "+15 range", "range_add": 15.0, "weight": 12, "req_path": "path_b", "min_tier": 1},
		{"id": "bub_extra_pinch", "name": "Extra Pinch", "desc": "+5% primary Brew speed", "brew_primary_speed_bonus": 0.05, "weight": 10, "req_path": "path_b", "min_tier": 2},
		{"id": "bub_fine_filter", "name": "Fine Filter", "desc": "+2% Midas conversion", "midas_ratio_bonus": 0.02, "weight": 12, "req_path": "path_c", "min_tier": 1},
		{"id": "bub_deep_pockets", "name": "Deep Pockets", "desc": "+75 Midas cap", "midas_cap_bonus": 75, "weight": 10, "req_path": "path_c", "min_tier": 2}
	]
}

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
	
	# Decode path tiers from path_bits
	var path_tiers = {
		"path_a": (path_bits >> 8) & 0xF,
		"path_b": (path_bits >> 4) & 0xF,
		"path_c": path_bits & 0xF
	}
	
	# Eligible pool
	var pool: Array[Dictionary] = []
	for card in UNIVERSAL_CARDS:
		if feat_rank >= card.get("min_rank", 1) and feat_rank <= card.get("max_rank", 3):
			pool.append(card)
			
	# Cat specific cards with path prerequisites
	if CAT_CARDS.has(cat_id):
		for card in CAT_CARDS[cat_id]:
			var req_path: String = card.get("req_path", "")
			var min_tier: int = int(card.get("min_tier", 0))
			if req_path == "" or path_tiers.get(req_path, 0) >= min_tier:
				pool.append(card)
	
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

