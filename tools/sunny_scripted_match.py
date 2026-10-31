import json
import os
import math

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT_DIR = os.path.join(BASE_DIR, "content")

def load_json(rel_path):
    with open(os.path.join(CONTENT_DIR, rel_path), "r", encoding="utf-8") as f:
        return json.load(f)

mice_data = load_json("mice.json")
rats_data = load_json("rats.json")
sunny_rounds = load_json("rounds/sunny.json")["rounds"]

# Simulate income across rounds 1-10 to test:
# "place one Pip on round 1. After round 10 the wallet can buy Mittens, Nibs, and one tier-1 upgrade, with kibble left over."
start_kibble = 850
pip_cost = round(200 * 0.85) # 170
kibble = start_kibble - pip_cost

total_rbe_1_to_10 = 0
for r in range(1, 11):
    r_groups = sunny_rounds[str(r)]
    round_rbe = 0
    for grp in r_groups:
        coat = grp["coat"]
        count = grp["count"]
        coat_rbe = mice_data["coats"][coat]["rbe"]
        round_rbe += count * coat_rbe
    total_rbe_1_to_10 += round_rbe
    # Pop income is 1:1 on r1-50
    kibble += round_rbe
    # End of round bonus: 1 * round
    kibble += 1 * r

print(f"Rounds 1-10 Total RBE: {total_rbe_1_to_10}")
print(f"Kibble after round 10: {kibble}")

# Mittens cost: 600 * 0.85 = 510
# Nibs cost: 280 * 0.85 = 238
# T1 upgrade (e.g. Nibs B1 Hot Claws 200 * 0.85 = 170)
total_purchase = round(600 * 0.85) + round(280 * 0.85) + round(200 * 0.85)
print(f"Total purchase cost for Mittens + Nibs + Nibs B1: {total_purchase}")
assert kibble >= total_purchase, f"Wallet could not afford build! Has {kibble}, needed {total_purchase}"
kibble_leftover = kibble - total_purchase
print(f"[PASS] Sunny start acceptance test: {kibble_leftover} kibble left over after buying Mittens, Nibs, and B1 upgrade!")

