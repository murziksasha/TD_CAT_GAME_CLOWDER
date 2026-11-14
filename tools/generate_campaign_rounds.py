import json
import random

def generate_campaign():
    with open("content/rounds/sunny.json", "r", encoding="utf-8") as f:
        sunny = json.load(f)
    
    with open("content/rounds/bands.json", "r", encoding="utf-8") as f:
        bands = json.load(f)

    campaign_rounds = {}
    
    # 1. Rounds 1-40 from sunny.json
    for r_str, groups in sunny["rounds"].items():
        campaign_rounds[r_str] = groups

    milestones = bands.get("milestones", {})
    
    # Seeded RNG for reproducible filler rounds
    rng = random.Random(42)

    # 2. Rounds 41-100
    for r in range(41, 101):
        r_str = str(r)
        if r_str in milestones:
            campaign_rounds[r_str] = milestones[r_str]
            continue
        
        # Authored / balanced filler logic based on wave tiers
        groups = []
        if 41 <= r <= 44:
            groups.append({"count": 12 + (r - 40) * 2, "coat": "porcelain", "spacing": 0.7})
            groups.append({"count": 8 + (r - 40), "coat": "iron", "shadow": True, "spacing": 0.6})
        elif 46 <= r <= 49:
            groups.append({"count": 1, "rat": "burrow", "spacing": 1.0})
            groups.append({"count": 10 + (r - 45) * 2, "coat": "porcelain", "plated": True, "spacing": 0.8})
            groups.append({"count": 15, "coat": "sugar", "shadow": True, "spacing": 0.25})
        elif 51 <= r <= 54:
            groups.append({"count": 2, "rat": "burrow", "spacing": 6.0})
            groups.append({"count": 14 + (r - 50) * 2, "coat": "prism", "gnaw": True, "spacing": 0.35})
            groups.append({"count": 8, "coat": "marble", "spacing": 0.5})
        elif 56 <= r <= 58:
            groups.append({"count": 3, "rat": "burrow", "spacing": 5.0})
            groups.append({"count": 12, "coat": "porcelain", "plated": True, "spacing": 0.7})
            groups.append({"count": 10, "coat": "iron", "shadow": True, "gnaw": True, "spacing": 0.5})
        elif 61 <= r <= 64:
            groups.append({"count": 1, "rat": "bristle", "spacing": 1.0})
            groups.append({"count": 4, "rat": "burrow", "spacing": 4.0})
            groups.append({"count": 15, "coat": "porcelain", "spacing": 0.6})
        elif 66 <= r <= 74:
            groups.append({"count": 1, "rat": "bristle", "plated": (r % 2 == 0), "spacing": 2.0})
            groups.append({"count": 4 + (r - 65), "rat": "burrow", "spacing": 3.5})
            groups.append({"count": 15, "coat": "prism", "shadow": True, "spacing": 0.35})
        elif 76 <= r <= 78:
            groups.append({"count": 2, "rat": "bristle", "spacing": 8.0})
            groups.append({"count": 6, "rat": "burrow", "plated": True, "spacing": 3.0})
            groups.append({"count": 16, "coat": "porcelain", "gnaw": True, "spacing": 0.4})
        elif 81 <= r <= 84:
            # Super Porcelain era begins!
            groups.append({"count": 1, "rat": "monarch", "spacing": 1.0})
            groups.append({"count": 2, "rat": "bristle", "spacing": 6.0})
            groups.append({"count": 12, "coat": "porcelain", "spacing": 0.5})
        elif 86 <= r <= 88:
            groups.append({"count": 1, "rat": "monarch", "spacing": 1.0})
            groups.append({"count": 3, "rat": "bristle", "plated": True, "spacing": 7.0})
            groups.append({"count": 15, "coat": "porcelain", "plated": True, "spacing": 0.5})
        elif 91 <= r <= 94:
            groups.append({"count": 3, "rat": "dusk", "spacing": 3.5})
            groups.append({"count": 2, "rat": "monarch", "spacing": 12.0})
            groups.append({"count": 20, "coat": "iron", "shadow": True, "gnaw": True, "spacing": 0.3})
        elif 96 <= r <= 98:
            groups.append({"count": 4, "rat": "dusk", "spacing": 3.0})
            groups.append({"count": 2, "rat": "monarch", "spacing": 10.0})
            groups.append({"count": 3, "rat": "bristle", "plated": True, "spacing": 6.0})
            groups.append({"count": 15, "coat": "porcelain", "plated": True, "shadow": True, "spacing": 0.4})

        campaign_rounds[r_str] = groups

    out_data = {
        "mode": "campaign",
        "max_round": 100,
        "rounds": campaign_rounds
    }

    with open("content/rounds/campaign.json", "w", encoding="utf-8") as f:
        json.dump(out_data, f, indent=2)

    print(f"Generated content/rounds/campaign.json with {len(campaign_rounds)} rounds.")

if __name__ == "__main__":
    generate_campaign()
