# SPEC 05: Hero Cats

## 1. Hero Rules & Mechanics

- **One Hero Per Match**: Exactly one hero cat can be placed per match.
- **Permanent Placement**: Heroes **cannot be sold**.
- **Repositioning**: A hero may be relocated **once for free before Round 20**. After Round 20, relocating costs **200 kibble** and incurs a **5-round relocation cooldown**.
- **Zero Ability Kibble Cost**: Activating a hero's active ability costs **0 kibble** (unlike Tricks, which cost kibble).
- **Meta Acquisition**: Heroes unlock via permanent **Account Level**, never through Fishcoin. Fishcoin is used exclusively for cosmetic hero skins.
- **Aura Interactions**: Heroes receive **half** of any buff aura bonuses provided by support cats (such as Miso).

---

## 2. In-Match Hero XP & Level Curve

A placed hero earns Hero XP at the end of each round they were present on the field:

$$\text{heroXP\_grant} = 20 + (3 \times \text{round}) + (0.02 \times \text{heroDamageThatRound})$$

The round term ensures heroes placed slightly later can still grow, while heroes placed on Round 1 steadily reach capstone levels by late game.

### Cumulative Level Thresholds (1–20)

| Level | Cumulative XP Required | Key Milestones & Capabilities |
| :---: | :---: | :--- |
| **1** | 0 | Base starting stats and attack. |
| **2** | 80 | General stat growth. |
| **3** | 200 | **First Active Ability unlocked** (~Round 7). |
| **4** | 380 | Stat growth. Mittens learns Night Eye. |
| **5** | 620 | Stat growth. |
| **6** | 920 | Mittens converts to Bite damage (pops Iron). |
| **7** | 1,300 | **Signature Passive unlocked** (~Round 22). |
| **8** | 1,750 | Duchess flame becomes Void-tinged (hits Ink). |
| **9** | 2,300 | Stat growth. |
| **10** | 2,950 | **Second Active Ability unlocked** (~Round 38). |
| **11** | 3,700 | Stat growth. |
| **12** | 4,550 | Stat growth. |
| **13** | 5,500 | Stat growth. |
| **14** | 6,550 | Stat growth. |
| **15** | 7,700 | Stat growth. |
| **16** | 9,000 | Stat growth. |
| **17** | 10,400 | Stat growth. |
| **18** | 11,900 | Stat growth. |
| **19** | 13,500 | Stat growth. |
| **20** | 15,200 | **Capstone Passive unlocked** (~Round 94 if placed Round 1). |

*Standard Per-Level Stat Growth*: +3% damage, +1.5% attack speed, and on even levels +4 range.

---

## 3. Launch Heroes (Detailed Kits)

### Mittens — Yarn Warden
- **Role**: Starter versatile frontline commander.
- **Cost**: 600 kibble | **Range**: 160 | **Damage**: 1 Claw | **Pierce**: 3 | **Cooldown**: 0.8s.
- **Progression Upgrades**:
  - **Level 4**: Gains **Night Eye** (targets Shadow).
  - **Level 6**: Attack damage type permanently converts from Claw to **Bite** (damages Iron).
- **Abilities & Passives**:
  - **Level 3 Active — Pin Cushion** (40s CD): Mittens fires a ring of 10 needles outward, each dealing 2 damage with 4 pierce.
  - **Level 7 Passive — Soft Paws**: Mittens attacks +20% faster. Alley cats in her range gain +5% attack speed.
  - **Level 10 Active — Spool Barrage** (50s CD): For 6s, Mittens fires 5 seeking needles per basic attack.
  - **Level 20 Passive — Last Thread**: The first time a leak would remove player lives, prevents up to 20 lives of that leak (once per match); Mittens then gains +1 permanent damage for the remainder of the match.

---

### Duchess — Hearth Cat
- **Role**: Flame mage, group burn, percentage-based rat melter.
- **Unlock**: Account Level 7 | **Cost**: 750 kibble | **Attack**: Flame lick dealing Magic + Burn.
- **Progression Upgrades**:
  - **Level 8**: Flame acquires a Void-tinged aspect; Ink coats lose their immunity to Duchess only.
- **Abilities & Passives**:
  - **Level 3 Active — Heatwave** (35s CD): Ignites all enemies within 100 radius for 4 dps Burn over 4s.
  - **Level 7 Passive — Hearth**: Burn durations applied by Duchess last +2s longer. Blast cats in range gain +15 explosion radius.
  - **Level 10 Active — Chili Heart** (50s CD): Creates a scorched fire zone on the nearest track point for 8s, dealing 8 dps.
  - **Level 20 Passive — Banked Coals**: Burn applied to rats deals bonus damage equal to 2% of the rat's current HP per second (capped at 40 dps on standard rats; capped at **15 dps** on the Rat Matriarch).

---

### Baron Salt — Harbor Cat
- **Role**: Heavy ordnance artillery commander and armor stripper.
- **Unlock**: Account Level 10 | **Cost**: 700 kibble | **Attack**: Throws heavy fishbone bombs dealing Blast damage.
- **Abilities & Passives**:
  - **Level 3 Active — Depth Charge** (40s CD): Creates a rolling concussion explosion along 180 units of track dealing 6 Blast damage.
  - **Level 7 Passive — Harbor Drill**: Biscuit and all other Blast cats in range gain +1 Blast damage.
  - **Level 10 Active — Broadside** (55s CD): Launches three massive artillery bombs dealing 15 Blast damage each.
  - **Level 20 Passive — Keelhaul**: Every 8s, Baron Salt's next bomb completely strips the Plated property from its target. (If the Matriarch has Plated, it is stripped for 5s and then returns).

---

### Sister Pebble — Ledger Cat
- **Role**: Financial optimizer and life insurance.
- **Unlock**: Account Level 14 | **Cost**: 900 kibble | **Attack**: Weak poke dealing 1 Bite damage every 1.2s.
- **Passive Income**: Grants `10 + (2 × level)` bonus kibble at the end of every round.
- **Abilities & Passives**:
  - **Level 3 Active — Skim** (45s CD): Increases pop kibble income by +20% during the following round.
  - **Level 7 Passive — Ledger**: Fishercats (Goldie) within her range produce +10% kibble.
  - **Level 10 Active — Audit** (60s CD): Instantly awards `500 + (30 × level)` kibble into the in-match wallet.
  - **Level 20 Passive — Balanced Books**: End-of-round income grant increases to `40 + (4 × level)`. The first leak each round has its life loss reduced by 5 (minimum 1 life lost if leak exceeded 1).

---

## 4. Post-Launch Heroes (Roadmap)

- **Obsidian**: Myth aura commander (Unlock: Account Level 18).
  - L3: Places thorn totems on track.
  - L10: Massively amplifies Magic damage in wide aura.
  - L20: Grants Myth cats in range ability to ignore Ink immunity for 10s on cooldown.
- **Velvet**: High-burst alley assassin (Unlock: Account Level 22).
  - High single-target Bite damage at short range.
  - L3: Path dash strike.
  - L10: Stealth window granting Night Eye and critical strikes.
  - L20: High-velocity rat execute strike. Optimal placed in sharp bends.

