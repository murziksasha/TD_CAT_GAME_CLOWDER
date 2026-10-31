# SPEC 01: Game Overview, Pillars & Modes

## 1. Concept & Scope

**Clowder: Alley Siege** (short name **Clowder**) is a free, single-player path tower defense game built with Godot 4 and GDScript. Cats defend a track through the alleyways and fish market from an encroaching mouse and rat tide.

### Locked Assumptions
- **View**: 2D, top-down 3/4 view, readable at a glance.
- **Engine**: Godot 4. PC (Windows) first. Web export is a post-launch consideration.
- **Single-player**: Single-player in v1. Co-op is post-launch.
- **Language**: English first.
- **Session Duration**: Sunny clear ~15–25 min at 2× speed; Round-100 clear ~35–50 min at 2× speed.
- **Monetization**: Strictly zero monetization surfaces. No ads, no premium currency, no loot boxes, no paid continues, no real-money transactions. A tip jar, if ever created, exists entirely outside the game and unlocks nothing.

---

## 2. Player Fantasy & Core Pillars

You are the Alley Keeper. A clowder of cats defends the fish market from waves of mice advancing in protective coats, bursting into smaller mice, followed by massive cart-sized rats, culminating in the terrifying Rat Matriarch.

### Five Core Pillars:
1. **Readable Defense**: A player can identify an enemy's coat, speed, and immunities directly from silhouette and markings, not just color.
2. **Build Identity**: Each cat features three distinct upgrade paths. Crosspathing is a consequential, irreversible strategic choice.
3. **Four Distinct Growth Vectors**:
   - *In-match Kibble*: Buys towers and upgrades during the round.
   - *In-match Feat XP*: Evolves the specific placed cat instance via between-round feat cards.
   - *Account XP*: Unlocks passive Insight skill points across account trees.
   - *Fishcoin*: Unlocks cosmetics (skins, trails, banners) and pre-equippable active Tricks.
4. **Fair and Free**: Every standard map can be conquered with zero tricks and zero passive skills. The shop never sells power required for mastery modes.
5. **Commitment**: Selling a cat refunds 70% of spent kibble and permanently deletes that unit's feats. Heroes cannot be sold.

---

## 3. Canonical Terminology

Always use the canonical Clowder terms in code, JSON files, documentation, and UI. Never use borrowed terms from other tower defense franchises.

| TD General Concept | Clowder Term | Description |
| :--- | :--- | :--- |
| Tower | **Cat** | Placed defenders with distinct footprints and upgrade paths. |
| Hero / Commander | **Hero Cat** | Unique commander (one per match) that levels up during battle (1–20). |
| Small Enemy | **Mouse** | Layered enemy with 12 distinct **coats**. |
| Boss / Heavy Enemy | **Rat** | High-health behemoths: Burrow, Bristle, Monarch, Dusk, Rat Matriarch. |
| In-Match Currency | **Kibble** | Earned by popping enemy HP layers; spent on cats, upgrades, tricks. |
| Meta Currency | **Fishcoin** | Earned by completing matches/challenges; spent on tricks and visuals. |
| Passive Skill Tree | **Insights** | Account-wide passive talent trees earned with Account XP. |
| Shop Active Ability | **Trick** | Equippable active ability with round cooldowns and kibble costs. |
| In-Match Choice | **Feat** | Experience-based perks drafted for individual cat instances. |
| Tower Meta XP | **Mastery** | Per-cat-type permanent XP earned across matches to unlock tiers 3–5. |

---

## 4. Match Modes & Rules

Matches are played across five distinct difficulty modes. Each mode awards a unique medal on first clear.

| Mode | Final Round (Medal) | Starting Lives | Starting Kibble | Price Multiplier | Continues Allowed | Insights Active? | Tricks Active? | Selling Allowed? |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Sunny** | 40 | 200 | 850 | ×0.85 | Up to 3 | Yes | Yes | Yes (70% refund) |
| **Alley** | 60 | 150 | 650 | ×1.00 | Up to 2 | Yes | Yes | Yes (70% refund) |
| **Night** | 80 | 100 | 550 | ×1.08 | 1 | Yes | Yes | Yes (70% refund) |
| **Last Whisker** | 100 | 1 | 650 | ×1.20 | 0 | Yes | Yes | Yes (70% refund) |
| **Bare Paw** | 100 | 1 | 650 | ×1.00 | 0 | **No (Disabled)** | **No (Disabled)** | **No (Disabled)** |

### Bare Paw (Mastery Benchmark)
Bare Paw is the absolute benchmark for game fairness. Continues, Insights, Tricks, and Selling are completely disabled. Heroes and Feats remain enabled because they are earned through gameplay within that specific match, not meta purchases.

### Map Modifiers
Each map features three unlockable modifiers that grant their own distinct medals:
- **Alternate Warrens**: Porcelain appears early on round 28 (instead of 32); every rat tier arrives 2 rounds early; Gnaw coat added to one group every 5 rounds.
- **Full Nets**: Pop kibble income ×2; round 40 sends 2 Burrow Rats.
- **Short Leash**: Starting lives halved (Last Whisker and Bare Paw remain at 1).

---

## 5. Round Flow & Win/Loss Mechanics

### Win and Loss Conditions
- Enemies traverse polyline tracks from entrance to exit.
- When an enemy reaches the exit, the player loses lives equal to its remaining **RBE** (Red-mouse Equivalent: total hit points inside it, including all prospective nested children).
- Reaching 0 lives immediately ends the match with a defeat.
- Reaching and clearing the final round of the mode awards victory and the mode's medal. Freeplay can continue indefinitely afterward.

### Round Controls & Hotkeys
- **Start / Send Wave**: Spacebar (or UI button). Auto-start delay is 0.4s between rounds when toggled on.
- **Game Speed**: Pause (`Esc`), 1× (`1`), 2× (`2`), 3× (`3`).
- **Feat Card Drafting**: Feat selection cards trigger **between rounds only**, never during combat. If multiple cats earned feats during the round, card offers are queued and resolved sequentially.
- **Continues**: On modes permitting continues, continuing restarts the failed round and deducts `250 + 25 × round` kibble from the in-match wallet. If the wallet cannot afford it, the continue cannot be used. Continues are never sold for real money or fishcoin.

### Sunny Round 40 Rat Adjustment
On Sunny mode only, the round-40 Burrow Rat spawns with **65% body HP** (130 HP instead of 200). Its inner Porcelain children remain unchanged. Its effective total RBE is 546 (instead of standard 616).

