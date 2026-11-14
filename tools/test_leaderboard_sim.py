import json
import math
import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE_DIR)

def calc_score(rounds_cleared, max_rounds, remaining_lives, peak_kibble, won, mode, difficulty, clean_sheet):
    mode_mults = {
        0: 1.0,  # SUNNY
        1: 1.5,  # ALLEY
        2: 2.0,  # NIGHT
        3: 3.0,  # LAST_WHISKER
        4: 4.0   # BARE_PAW
    }
    diff_mults = {
        "beginner": 1.0,
        "beginner_plus": 1.15,
        "intermediate": 1.35,
        "advanced": 1.6,
        "expert": 2.0
    }
    m_mult = mode_mults.get(mode, 1.0)
    d_mult = diff_mults.get(difficulty.lower(), 1.0)

    base_score = float(rounds_cleared) * 120.0
    base_score += float(remaining_lives) * 15.0
    base_score += float(peak_kibble) * 0.1
    if won:
        base_score += 1000.0
    if clean_sheet:
        base_score += 500.0

    return int(round(base_score * m_mult * d_mult))

def test_rating_formula():
    print("Testing Rating Formula calculations...")
    # Sunny Beginner Clear: 40 rounds, 200 lives, 1200 peak kibble, won, clean sheet
    s_sunny = calc_score(40, 40, 200, 1200, True, 0, "beginner", True)
    # (4800 + 3000 + 120 + 1000 + 500) * 1.0 * 1.0 = 9420
    assert s_sunny == 9420, f"Expected 9420, got {s_sunny}"

    # Bare Paw Expert Clear: 100 rounds, 1 life, 5000 peak kibble, won, clean sheet
    s_barepaw = calc_score(100, 100, 1, 5000, True, 4, "expert", True)
    # (12000 + 15 + 500 + 1000 + 500) * 4.0 * 2.0 = 14015 * 8 = 112120
    assert s_barepaw == 112120, f"Expected 112120, got {s_barepaw}"

    # Intermediate Alley Clear: 60 rounds, 150 lives, 2500 peak kibble, won
    s_alley = calc_score(60, 60, 150, 2500, True, 1, "intermediate", False)
    # (7200 + 2250 + 250 + 1000) * 1.5 * 1.35 = 10700 * 2.025 = 21668
    assert s_alley == 21668, f"Expected 21668, got {s_alley}"

    print("[PASS] Rating and score formulas validated across all tiers.")

def test_top_100_structure():
    print("Testing Top 100 structure and sorting...")
    entries = []
    for i in range(120):
        entries.append({
            "name": f"Keeper_{i}",
            "score": (i * 350) + 1000,
            "map": "sunny_gutter" if i % 2 == 0 else "the_warren",
            "mode": i % 5
        })

    # Sort descending
    entries.sort(key=lambda x: x["score"], reverse=True)
    # Cap 100
    top_100 = entries[:100]
    assert len(top_100) == 100
    assert top_100[0]["score"] > top_100[-1]["score"]
    assert top_100[0]["score"] == 119 * 350 + 1000

    # Test filtering by map
    sunny_entries = [e for e in top_100 if e["map"] == "sunny_gutter"]
    assert len(sunny_entries) == 50
    print("[PASS] Top 100 cap and filtering validated.")

if __name__ == "__main__":
    print("==================================================")
    print("   CLOWDER: LEADERBOARD & RATING SIM TESTS")
    print("==================================================")
    test_rating_formula()
    test_top_100_structure()
    print("==================================================")
    print("   ALL LEADERBOARD UNIT TESTS PASSED CLEANLY")
    print("==================================================")
