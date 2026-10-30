# SPEC 07: Feats & Insights

## 1. In-Match Feats (Instance Perks)

Feats represent personal tactical veterancy for a specific placed cat on the board. They reward keeping placed cats rather than constantly selling and swapping them.

### Feat XP Formula
Every placed cat accumulates Feat XP individually:

$$\text{featXP} += (\text{damageDealt} \times 0.4) + (3 \times \text{coatsFullyRemoved})$$

- **Support Cat Contribution**: Cats whose primary function is support/buffing (Goldie, Miso, Pudding) also gain:
  $$\text{supportBonus} = 0.25 \times \text{damage dealt by cats inside their active aura/effect}$$

### Thresholds & Progression
- **Feat I**: 100 Feat XP (~Round 15–20 for a primary attacker).
- **Feat II**: 350 Feat XP (~Round 35–45).
- **Feat III**: 900 Feat XP (~Round 55–70).

*Power Budget*: All three feats combined equal approximately half of a Tier-3 upgrade. They enhance performance without overshadowing the core upgrade tree.

### Drafting & Deterministic Offer Seeding
- **Between-Round Drafting**: When a cat crosses a feat threshold, the card offer opens **exclusively between rounds**, never during a leak or wave.
- **Seeded Offer**: Cards offered (pick 1 of 3) are derived deterministically:
  $$\text{CardSeed} = \text{hash}(\text{matchSeed}, \text{catInstanceId}, \text{featRank}, \text{crosspathBits})$$
  Exiting to menu or reloading a saved match **never rerolls** the offered cards.
- **Feat Reroll**: A player may pay **150 kibble** for one reroll per cat per match. This advances a deterministic reroll counter within that cat's seed.
- **Auto-Pick Setting**: Players who prefer uninterrupted wave flow can toggle Auto-Pick in settings (defaults to the highest-weight card matching the cat's highest upgrade path).

### Universal Feat Card Pool
Cards that can appear in any cat's draft:

| Feat Card | Mechanical Effect | Drafting Rules & Rarity |
| :--- | :--- | :--- |
| **Long Whiskers** | +12% Range | Common |
| **Quick Paw** | +10% Attack Speed | Common |
| **Deep Bite** | +1 Damage, −10% Attack Speed | Common |
| **Careful Aim** | +2 Pierce, −8% Range | Common |
| **Night Snack** | Grants **Night Eye** (targets Shadow) | Feat II or III only; Low weight |
| **Thrifty** | The next upgrade on this cat is 8% off (one-time) | Common |
| **Veteran** | +15% Feat XP earned | Feat I only |

### Path-Specific Feat Cards
Each launch cat features 2 custom path-specific cards per upgrade path. Cards requiring a tier not yet owned are excluded from the draft pool.

*Example (Pip — Yarn Tosser)*:
- **Path A**: *Barbed Tip* (+1 damage vs Porcelain); *Spool Rhythm* (burst counter starts at 3 instead of 0).
- **Path B**: *Bright Pupil* (Mark duration +2s); *Night Drill* (Night Eye gains full-track range; requires Night Eye).
- **Path C**: *Loose Thread* (+1 needle fired); *Sticky Cloud* (Yarn clouds last +3s; requires Yarn Tempest).

---

## 2. Insights (Account Passive Skill Trees)

Insights are account-wide passive perks unlocked using Insight points. They represent permanent player expertise and are funded strictly through Account XP. **Fishcoin cannot buy or shortcut Insights.**

### Point Budget & Respec
- Players earn **1 Insight point** per Account Level up to level 40.
- Milestone levels (10, 20, 30, 40) grant **+1 bonus point** (43 points total at Level 40).
- **Depth Point Costs**: Tier 1: 1 pt | Tier 2: 1 pt | Tier 3: 1 pt | Tier 4: 2 pts | Tier 5: 2 pts | Tier 6: 2 pts | Tier 7: 3 pts | Tier 8: 3 pts (Total to complete one tree = 15 points).
- A player can max out at most two full trees and partially invest in a third. **No player can own every node.**
- **Free Respec**: Freely respec points at any time while outside an active match.
- **Bare Paw Ban**: Bare Paw mode forcefully disables all Insights.

---

### Tree 1: Alley Tree
1. **Extra Starting Kibble** (1): +50 starting kibble on Sunny and Alley modes.
2. **Soft Landings** (1): The first leak of a match removes 10 fewer lives (once per match).
3. **Pip Practice** (1): Pip gains +5% attack speed.
4. **Hot Start** (2): Nibs' burn duration +1s. *(Requires Nibs Mastery 2)*.
5. **Thick Ruff** (2): Pudding freeze lasts +0.3s on mice. *(Requires Pudding Mastery 2)*.
6. **Bigger Bones** (2): Biscuit explosion radius +8. *(Requires Biscuit Mastery 3)*.
7. **Alley Drill** (3): All Alley-category cats gain +1 pierce.
8. **Veteran Tosser** (3): You may field a second copy of one Alley Tier-5 cat on the board. *(Requires any Alley cat at Mastery 8)*.

---

### Tree 2: Hunt Tree
1. **Perch Discount** (1): Sable costs 50 less kibble.
2. **Steady Aim** (1): Sable attack cooldown reduced by 5%.
3. **Gutter Maps** (1): Water-mask cats gain +10% range.
4. **Harpoon Drill** (2): Anti-rat bonus damage on Hunt cats +10%. *(Requires Sable Mastery 3)*.
5. **Long Patrol** (2): Air-lane cats move 10% faster.
6. **Deadeye Drill** (2): Sable's every-Nth shot counter requires 1 fewer shot. *(Requires Sable Mastery 5)*.
7. **Hunt Pack** (3): Hunt cats gain +1 flat damage vs rats.
8. **Second Perch** (3): A second copy of one Hunt Tier-5 cat is permitted. *(Requires any Hunt cat at Mastery 8)*.

---

### Tree 3: Myth Tree
1. **Ink Study** (1): Nim's Path C Tier-1 upgrade costs 100 less kibble.
2. **Warm Spark** (1): Burn dps from Myth cats +1.
3. **Hex Reach** (1): Hex spread radius increased by 20%.
4. **Brew Loyalty** (2): Bub's potion buffs last 20% longer. *(Requires Bub Mastery 2)*.
5. **Thorn Pact** (2): Myth cats gain +5% range. *(Requires any Myth cat at Mastery 3)*.
6. **Void Lesson** (2): One chosen Myth cat treats Ink as a normal target. *(Requires that cat's Mastery 5)*.
7. **Myth Chorus** (3): Magic damage across all Myth cats +1.
8. **Second Star** (3): A second copy of one Myth Tier-5 cat is permitted. *(Requires any Myth cat at Mastery 8)*.

---

### Tree 4: Den Tree
1. **First Catch** (1): Goldie produces +20 bonus kibble per round.
2. **Wider Cafe** (1): Miso aura radius +15 units.
3. **Honey Lesson** (1): Honey slow lasts +2s.
4. **Interest** (2): Goldie vault interest +2 percentage points (8% -> 10%). *(Requires Goldie Mastery 4)*.
5. **Single Discount** (2): Global discount price floor drops from 60% to 55%. *(Requires Miso Mastery 5)*.
6. **Sentry Oil** (2): Sentry lifetime +5s. *(Requires Sprocket Mastery 2)*.
7. **Den Network** (3): Support auras also grant +5% attack speed.
8. **Market Day** (3): Start every match with one free Tier-1 upgrade token. *(Requires Goldie or Miso Mastery 8)*.

---

### Tree 5: Hero Tree
1. **Early Bowl** (1): Hero placement cost reduced by 100 kibble.
2. **Fast Growth** (1): Hero XP gain rate increased by +8%.
3. **Level Head Start** (1): The hero begins the match at Level 2.
4. **Pin Cushion Drill** (2): Mittens' Level-3 active cooldown reduced by 5s. *(Requires 3 matches played with Mittens)*.
5. **Hearth Drill** (2): Duchess burn DPS cap vs standard rats increased by +5 dps.
6. **Hero Start 3** (2): The hero begins the match at Level 3. *(Requires Level Head Start)*.
7. **Ability Fuel** (3): Hero active ability cooldowns reduced by 10%.
8. **Beloved** (3): Hero Level-20 passives become 20% stronger (durations and flat values; never the Matriarch DPS cap). *(Requires clearing a Night medal with any hero)*.

---

### Tree 6: Clowder Tree (General)
1. **Keen Wallet** (1): +25 starting kibble on all modes except Bare Paw.
2. **Clean Sell** (1): Sell refund increased to 75% on modes permitting selling.
3. **Third Trick** (1): Unlocks **Trick Slot 3**.
4. **Pre-round Peek** (2): The upcoming round's exact mouse counts are revealed in the HUD preview.
5. **Feat Focus** (2): Feat XP gain rate increased by +10%.
6. **Reroll Saver** (2): The first feat reroll of each match is free of charge.
7. **Long Memory** (3): Mastery XP gain rate increased by +10%.
8. **Keeper's Bell** (3): Active perk: Once per match, all cats gain +20% attack speed for 10s.

