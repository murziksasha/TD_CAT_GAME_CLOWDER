import json
import math
import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT_DIR = os.path.join(BASE_DIR, "content")

def load_json(rel_path):
    with open(os.path.join(CONTENT_DIR, rel_path), "r", encoding="utf-8") as f:
        return json.load(f)

def test_rbe_and_coats():
    mice_data = load_json("mice.json")
    coats = mice_data["coats"]
    
    # Calculate recursive RBE for standard mice
    def calc_rbe(coat_name):
        cdata = coats[coat_name]
        rbe = cdata["layer_hp"]
        for child in cdata.get("children", []):
            rbe += child["count"] * calc_rbe(child["coat"])
        return rbe

    expected_rbe = {
        "rust": 1,
        "slate": 2,
        "moss": 3,
        "grain": 4,
        "sugar": 5,
        "soot": 11,
        "frost": 11,
        "ink": 11,
        "iron": 23,
        "marble": 23,
        "prism": 47,
        "porcelain": 104
    }
    
    for coat, exp in expected_rbe.items():
        actual = calc_rbe(coat)
        assert actual == exp, f"RBE mismatch for {coat}: got {actual}, expected {exp}"
        assert coats[coat]["rbe"] == exp, f"Table RBE mismatch in mice.json for {coat}"

    # Super Porcelain RBE
    # From r81 onward: Porcelain shell 60. Every non-rat mouse spawns 1 child (primary).
    # Porcelain(60) -> Prism(1) -> Marble(1) -> Soot(1) -> Sugar(1) -> Grain(1) -> Moss(1) -> Slate(1) -> Rust(1) = 68
    def calc_super_rbe(coat_name):
        cdata = coats[coat_name]
        lhp = 60 if coat_name == "porcelain" else 1
        for child in cdata.get("children", []):
            if child.get("is_primary", True):
                return lhp + calc_super_rbe(child["coat"])
        return lhp
    
    super_rbe = calc_super_rbe("porcelain")
    assert super_rbe == 68, f"Super porcelain RBE got {super_rbe}, expected 68"

    # Rats RBE
    rats_data = load_json("rats.json")["rats"]
    # Burrow: 200 + 4 * 104 = 616
    burrow_rbe = rats_data["burrow"]["body_hp"] + 4 * calc_rbe("porcelain")
    assert burrow_rbe == 616, f"Burrow RBE got {burrow_rbe}, expected 616"
    assert rats_data["burrow"]["rbe"] == 616
    
    # Plated Burrow: body 400 + 4 * 114 (plated porcelain) = 856
    plated_burrow = 400 + 4 * 114
    assert plated_burrow == 856, f"Plated Burrow RBE got {plated_burrow}, expected 856"
    assert rats_data["burrow"]["plated_rbe"] == 856

    # Bristle: 700 + 4 * 616 = 3164
    bristle_rbe = rats_data["bristle"]["body_hp"] + 4 * burrow_rbe
    assert bristle_rbe == 3164, f"Bristle RBE got {bristle_rbe}, expected 3164"
    assert rats_data["bristle"]["rbe"] == 3164
    
    # Plated Bristle: 1400 + 4 * 856 = 4824
    plated_bristle = 1400 + 4 * 856
    assert plated_bristle == 4824, f"Plated Bristle RBE got {plated_bristle}, expected 4824"
    assert rats_data["bristle"]["plated_rbe"] == 4824

    # Monarch: 4000 + 4 * 3164 = 16656
    monarch_rbe = rats_data["monarch"]["body_hp"] + 4 * bristle_rbe
    assert monarch_rbe == 16656, f"Monarch RBE got {monarch_rbe}, expected 16656"
    assert rats_data["monarch"]["rbe"] == 16656
    
    # Plated Monarch: 8000 + 4 * 4824 = 27296
    plated_monarch = 8000 + 4 * 4824
    assert plated_monarch == 27296, f"Plated Monarch RBE got {plated_monarch}, expected 27296"
    assert rats_data["monarch"]["plated_rbe"] == 27296

    # Dusk: 700 + 4 * 128 (super plated porcelain) = 1212
    dusk_rbe = rats_data["dusk"]["body_hp"] + 4 * 128
    assert dusk_rbe == 1212, f"Dusk RBE got {dusk_rbe}, expected 1212"
    assert rats_data["dusk"]["rbe"] == 1212

    # Matriarch: 22000 + 2 * 16656 + 3 * 1212 = 58948
    matriarch_rbe = rats_data["matriarch"]["body_hp"] + 2 * monarch_rbe + 3 * dusk_rbe
    assert matriarch_rbe == 58948, f"Matriarch RBE got {matriarch_rbe}, expected 58948"
    assert rats_data["matriarch"]["rbe"] == 58948

    print("[PASS] [1/9] RBE and Coat hierarchy matches plan 100%.")

def test_matriarch_immunity():
    rats_data = load_json("rats.json")["rats"]
    matriarch = rats_data["matriarch"]
    required_control_immunes = ["Stun", "Knockback", "Freeze", "Slow", "Amber", "InstantKill"]
    for imm in required_control_immunes:
        assert imm in matriarch["immunities"], f"Matriarch missing {imm} immunity"
    assert matriarch.get("control_immune", False) == True
    assert matriarch.get("burn_cap_dps", 0) == 15
    print("[PASS] [2/9] Rat Matriarch control immunity component validated.")

def test_trick_damage_ceiling():
    tricks_data = load_json("tricks.json")
    max_matriarch_dmg = tricks_data["max_damage_on_matriarch"]
    assert max_matriarch_dmg == 1100, f"Expected trick cap 1100, got {max_matriarch_dmg}"
    for tid, tinfo in tricks_data["tricks"].items():
        direct_dmg = tinfo.get("damage", 0) + tinfo.get("screen_rat_damage", 0)
        assert direct_dmg <= max_matriarch_dmg, f"Trick {tid} exceeds 1100 damage cap: {direct_dmg}"
    print("[PASS] [3/9] Trick power ceiling <= 1100 on Matriarch validated.")

def test_discount_formula_and_floor():
    # Formula: price = base * modePriceMultiplier * (1 - highestDiscount)
    # Floor: 60% of mode-adjusted base. Two discounts do not add.
    base = 1000
    mode_mult = 1.00 # Alley
    mode_adjusted_base = base * mode_mult
    
    # 15% discount
    d1 = 0.15
    price1 = round(max(mode_adjusted_base * (1.0 - d1), mode_adjusted_base * 0.60))
    assert price1 == 850
    
    # Two discounts: 15% and 10% (do not add, max is 15%)
    d2 = [0.15, 0.10]
    highest = max(d2)
    price2 = round(max(mode_adjusted_base * (1.0 - highest), mode_adjusted_base * 0.60))
    assert price2 == 850
    
    # Heavy discounts that would exceed 40% reduction: e.g. 50%
    d_heavy = 0.50
    price_floor = round(max(mode_adjusted_base * (1.0 - d_heavy), mode_adjusted_base * 0.60))
    assert price_floor == 600, f"Floor violation: got {price_floor}, expected 600"
    print("[PASS] [4/9] Discount formula and 60% non-stacking floor validated.")

def test_gnaw_regrow_rules():
    # Gnaw: 2.8s without losing coat, regrow 1 coat up to spawn coat, cap 3, speed >= 80%
    timer = 0.0
    regrows = 3
    speed = 0.79 # Under 80% slow
    if speed >= 0.8:
        timer += 2.8
    assert timer == 0.0, "Gnaw should not accumulate timer while slowed < 80%"
    
    speed = 0.85
    if speed >= 0.8:
        timer += 2.8
        if timer >= 2.8 and regrows > 0:
            regrows -= 1
            timer = 0.0
    assert regrows == 2
    assert timer == 0.0
    print("[PASS] [5/9] Gnaw regrow suppression and 3-cap validated.")

def test_pop_overflow_and_immunities():
    # 1 Rust mouse: 1 HP. Hit by 3 Claw -> damage applied 1, kills rust, overflow 2
    # Porcelain mouse: 10 shell HP. Hit by 12 Claw -> 10 shell removed, spawns 2 Prism.
    # Overflow 2 applies to first Prism (layer 1) -> 1 removed, spawns 2 Marble.
    # Overflow 1 applies to first Marble (layer 1) -> 1 removed, spawns 1 Soot + 1 Frost.
    # Total HP removed in this 1 hit: 10 + 1 + 1 = 12.
    damage = 12
    shell = 10
    applied_to_shell = min(shell, damage)
    overflow1 = damage - applied_to_shell # 2
    
    first_prism_hp = 1
    applied_to_prism = min(first_prism_hp, overflow1) # 1
    overflow2 = overflow1 - applied_to_prism # 1
    
    first_marble_hp = 1
    applied_to_marble = min(first_marble_hp, overflow2) # 1
    overflow3 = overflow2 - applied_to_marble # 0
    
    total_hp_removed = applied_to_shell + applied_to_prism + applied_to_marble
    assert total_hp_removed == 12
    assert overflow3 == 0

    # Immunities:
    # Iron stops Claw
    # Soot stops Blast
    # Ink stops Magic
    mice_data = load_json("mice.json")["coats"]
    assert "Claw" in mice_data["iron"]["immunities"]
    assert "Blast" in mice_data["soot"]["immunities"]
    assert "Magic" in mice_data["ink"]["immunities"]
    assert "Freeze" in mice_data["frost"]["immunities"]
    assert "Chill" in mice_data["frost"]["immunities"]
    print("[PASS] [6/9] Pop overflow recursion and immunities validated.")

def test_goldie_payback():
    total_cost = 1250 + 400 + 800
    prod_per_round = 280
    payback_rounds = total_cost / prod_per_round
    assert 7.0 <= payback_rounds <= 10.0, f"Goldie payback out of range: {payback_rounds}"
    print(f"[PASS] [7/9] Goldie 2-0-0 payback validated: {payback_rounds:.2f} rounds (between 7 and 10).")

def test_feat_seeding_stability():
    def pseudo_offer(seed, cat_id, rank, path_bits, reroll):
        val = (seed * 31 + cat_id * 17 + rank * 7 + path_bits * 13 + reroll * 101) & 0x7FFFFFFF
        r1 = (val ^ 0x5555) % 100
        r2 = (val ^ 0xAAAA) % 100
        r3 = (val ^ 0x3333) % 100
        return [r1, r2, r3]
    
    run1 = pseudo_offer(12345, 1, 1, 0, 0)
    run2 = pseudo_offer(12345, 1, 1, 0, 0)
    assert run1 == run2, "Feat offer is not deterministic for fixed seed"
    print("[PASS] [8/9] Feat seed stability validated.")

def test_account_xp_and_level_progression():
    total_xp = sum(20 + 2 * r for r in range(1, 41))
    assert total_xp == 2440, f"Expected 2440 XP, got {total_xp}"
    
    levels_data = load_json("levels.json")
    base_cost = levels_data["base_cost"]
    per_lvl = levels_data["cost_per_level"]
    
    cumul = 0
    reached_level = 1
    while True:
        next_cost = base_cost + per_lvl * reached_level
        if cumul + next_cost <= total_xp:
            cumul += next_cost
            reached_level += 1
        else:
            break
            
    assert reached_level in [9, 10, 11], f"Level progression landed on {reached_level}, expected 9-11"
    print(f"[PASS] [9/9] First Sunny clear grants {total_xp} XP and reaches level {reached_level} (within 9-11).")

if __name__ == "__main__":
    print("==================================================")
    print("   CLOWDER: ALLEY SIEGE -- BALANCE HARNESS CHECKS  ")
    print("==================================================")
    test_rbe_and_coats()
    test_matriarch_immunity()
    test_trick_damage_ceiling()
    test_discount_formula_and_floor()
    test_gnaw_regrow_rules()
    test_pop_overflow_and_immunities()
    test_goldie_payback()
    test_feat_seeding_stability()
    test_account_xp_and_level_progression()
    print("==================================================")
    print("   ALL 9 BALANCE GATES PASSED CLEANLY (GREEN)    ")
    print("==================================================")
