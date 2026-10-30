# SPEC 06: Economy, Progression & Mastery

## 1. In-Match Economy (Kibble)

Kibble is the tactical, in-match currency used to purchase units, upgrade paths, pay trick activation fees, and afford round continues.

### Kibble Income Sources
1. **Damage / Popping Income**:
   - **Rounds 1–50**: **1.00 Kibble** per enemy HP removed.
   - **Rounds 51–80**: **0.85 Kibble** per enemy HP removed.
   - **Rounds 81–100**: **0.50 Kibble** per enemy HP removed.
   - **Rounds 101+ (Freeplay Decay)**:
     $$\text{multiplier} = \max\left(0.05,\; 0.50 \times 0.96^{(\text{round} - 100)}\right)$$
2. **Super Porcelain Shell Bounty (Round 81+)**:
   - Popping a Super Porcelain shell awards a flat **48 Kibble** bounty directly into the wallet instead of 1 kibble per shell HP. (Inner coats pay standard post-round-80 rates).
3. **End-of-Round Clear Bonus**:
   - Awards a flat:
     $$\text{Bonus} = 1 \times \text{round}$$
   - This bonus is intentionally modest. Dedicated income cats (Goldie) provide the real economic scaling.
4. **Starting Kibble by Mode**:
   - Sunny: **850** | Alley: **650** | Night: **550** | Last Whisker: **650** | Bare Paw: **650**

### Kibble Sinks & Costs
- Purchasing cats and the hero.
- Buying upgrade tiers across paths A, B, and C.
- Activating equipped Tricks (e.g., Tuna Strike: 50, Catnip Frenzy: 80).
- Purchasing a Continue on allowed modes:
  $$\text{Continue Cost} = 250 + (25 \times \text{round})$$
- Feat Card Reroll: **150 Kibble** (capped at 1 reroll per cat per match).

### Selling Rules
- **Refund Rate**: Exactly **70%** of total kibble invested into that cat instance (base placement plus all upgrades purchased), rounded down.
- **Feat Wipe**: Selling a cat permanently deletes all accumulated Feat XP and earned feat cards on that instance. Re-buying starts fresh at 0 Feat XP.
- **Hero Restriction**: Heroes **cannot** be sold.
- **Bare Paw**: Selling is strictly disabled in Bare Paw mode.

### Discount Stacking & The Hard Price Floor
Discounts from Miso, Goldie, or Insight passives follow strict non-stacking rules:

$$\text{Effective Price} = \text{base} \times \text{modeMultiplier} \times (1 - \text{highestDiscount})$$

- **Hard Floor**: Effective price **never drops below 60%** of the mode-adjusted base price (55% if the Den Insight *Single Discount* is unlocked).
- **No Stacking**: Multiple discount sources do not add together; only the single highest discount applies.
- **Self-Discount Ban**: Miso cannot discount Miso.

### Balance Verification: Sunny Start Script
*Harness Acceptance Test*: Placing a single Pip on Round 1 must leave enough accumulated kibble by the end of Round 10 to purchase **Mittens (Hero, 600)**, **Nibs (Cat, 280)**, and **Nibs B1 Hot Claws (Upgrade, 200)**, with surplus kibble remaining. (Verified: ~1404 kibble accumulated vs 918 cost on Sunny).

---

## 2. Meta Progression: Account XP & Levels

Account XP increases player account level, granting Insight points to spend on the passive skill tree and unlocking new cats, heroes, and maps.

### Account XP Grant Formula
Awarded upon clearing each round:

$$\text{Account XP} = (20 + 2 \times \text{round}) \times \text{modeMultiplier}$$

| Mode | Multiplier | Notes |
| :--- | :---: | :--- |
| **Sunny** | ×0.70 | **×1.00 on first clear** of that map. |
| **Alley** | ×1.00 | Standard baseline. |
| **Night** | ×1.30 | High progression. |
| **Last Whisker** | ×1.60 | Expert reward. |
| **Bare Paw** | ×2.00 | Pure mastery reward. |

*Freeplay*: Rounds completed after the mode's medal round award a flat **15 XP** each (discourages endless idle farming).

### Level Up Curve
Cost to advance from Account Level $L$ to $L + 1$:

$$\text{XP Required} = 120 + (30 \times L)$$

A fresh player clearing Sunny rounds 1–40 on their first attempt accumulates:
$$\sum_{r=1}^{40} (20 + 2r) = 2,440\text{ XP}$$
This precisely lands the player at **Account Level 10**.

### Account Unlock Milestones

| Level | Cumulative XP | Unlocks & Milestones |
| :---: | :---: | :--- |
| **1** | 0 | Pip, Nibs, Mittens, Sunny Gutter map. |
| **2** | 150 | **Pudding** (Frostpaw). |
| **3** | 330 | **Biscuit** (Fishbone Lobber). |
| **4** | 540 | **Trick Slot 1**. |
| **5** | 780 | **Sable** (Rooftop Sniper). |
| **6** | 1,050 | **Goldie** (Fishercat). |
| **7** | 1,380 | **Duchess** (Hero), **Miso** (Cafe Cat). |
| **8** | 1,740 | **Honey** (Yarn Weaver). |
| **9** | 2,130 | **Nim** (Spark Apprentice). |
| **10** | 2,550 | **Baron Salt** (Hero), **Trick Slot 2**, **Market Lane** map. |
| **12** | 3,510 | Nine-Life Pulse trick permitted. |
| **14** | 4,630 | **Sister Pebble** (Hero). |
| **16** | 5,910 | **Fishmarket Maze** map. |
| **18** | 7,350 | **Obsidian** (Hero). |
| **22** | 10,710 | **Velvet** (Hero). |

### The Unlock Queue Ceremony Rule
If a single match triggers multiple level-ups, the post-match victory screen paces rewards:
- **Maximum reveals per match end**: At most **2 cats**, **1 hero**, and **1 map**.
- Any excess unlocks wait safely in the **Unlock Queue** and reveal following subsequent match completions.
- Insight points and Fishcoin are credited immediately without queueing.

---

## 3. Cat Mastery XP (Permanent Tower Ranks)

Mastery XP measures long-term player expertise with each individual cat type across all matches.

### Mastery XP Formula
Accumulated during gameplay:

$$\text{Mastery XP} = \text{damageDealtByThisCatType} \times 0.15 \times \text{modeMultiplier}$$

- Minimum grant of **20 Mastery XP** if at least one cat of that type was fielded during the match.

### Mastery Ranks & Unlocks

| Rank | Cumulative XP | Unlocked Features |
| :---: | :---: | :--- |
| **1** | 0 | The cat, Tiers 1 and 2 upgrades. |
| **2** | 400 | **Tier 3 upgrades**. |
| **3** | 900 | Dedicated Path Feat cards enter the draft pool. |
| **4** | 1,600 | Minor visual flourish. |
| **5** | 2,800 | **Tier 4 upgrades**. |
| **6** | 4,500 | Stat tracking badge. |
| **7** | 7,000 | Mastery title. |
| **8** | 11,000 | **Tier 5 upgrades**. |
| **9** | 16,000 | Complete feat card pool unlocked. |
| **10** | 23,000 | Non-stat Gold Mastery Frame cosmetic; enables Alpha Cat synthesis (post-v1). |

