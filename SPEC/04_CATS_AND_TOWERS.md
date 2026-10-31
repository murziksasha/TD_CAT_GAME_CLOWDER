# SPEC 04: Cats (Towers) & Upgrades

## 1. Core Mechanics & The Crosspath Law

### The Crosspath Law
- Every cat has three distinct upgrade paths: **Path A**, **Path B**, and **Path C**.
- A placed cat can invest kibble into **at most two paths**.
- **Tier 3 Restriction**: If one path reaches Tier 3, 4, or 5, the secondary path is permanently capped at **Tier 2** (e.g., 5-2-0, 0-4-2, 2-0-3).
- **Tier 5 Uniqueness**: Only **one** Tier-5 cat of any given path for that cat type may exist on the battlefield simultaneously. Selling a Tier-5 cat immediately re-opens the slot.

### Mastery Gates (Meta Progression)
Upgrades are gated by permanent cat Mastery XP across matches:
- **Tiers 1 and 2**: Mastery Rank 1 (immediately available upon unlocking the cat).
- **Tier 3**: Mastery Rank 2 (earned in the first 1–2 matches).
- **Tier 4**: Mastery Rank 5.
- **Tier 5**: Mastery Rank 8.

### Targeting Modes
Cats can be toggled through targeting options:
- **First**: Targets the enemy farthest along the track (`s`).
- **Last**: Targets the enemy closest to the map entrance (`s`).
- **Strong**: Targets the enemy with the **highest current RBE** in range (ties broken by distance `s`).
- **Close**: Targets the enemy physically nearest to the cat.
- *Specialized*: Certain cats unlock "Rats First" or "Mice First".

---

## 2. Launch Roster (8 Launch Cats)

*Costs listed below reflect baseline Alley (×1.00) prices. Sunny is ×0.85, Night is ×1.08, Last Whisker is ×1.20, Bare Paw is ×1.00.*

---

### Pip — The Yarn Tosser
- **Role**: Starter single-target physical sniper.
- **Category**: Alley | **Mask**: Land | **Base Cost**: 200 kibble.
- **Base Stats**: 1 Claw damage, 2 pierce, 0.95s cooldown, 130 range, 400 projectile speed. Cannot see Shadow. Cannot damage Iron.

| Tier | Path A: Needle | Path B: Eye | Path C: Multi |
| :---: | :--- | :--- | :--- |
| **1** | **Long Needle** (150): Pierce 4. | **Keen Whisker** (100): Range 160. | **Twin Spool** (180): Fires 2 needles. |
| **2** | **Sharp Needle** (250): Damage 2. | **Night Eye** (300): Can target Shadow. | **Triple Spool** (280): Fires 3 needles. |
| **3** | **Barbed Spool** (700): Damage 3, pierce 6. | **Hawk Focus** (800): +25% attack speed, 15% crit for 2× damage. | **Seeking Yarn** (900): Needles steer toward targets. |
| **4** | **Spool Burst** (3200): Every 5th shot fires 8 needles. | **Marked Prey** (3500): Crits apply Mark (+1 damage taken for 4s). | **Fivefold** (2800): Fires 5 needles. |
| **5** | **Spool Storm** (18000): Cooldown 0.45s. Every 5th shot fires 16 needles. +1 damage vs Porcelain and Rats. | **Hawkeye** (16000): Full-track range, 25% crit, Mark +2 for 6s (Rats marked 4s, Matriarch +1 for 3s). | **Yarn Tempest** (15000): 8 seeking needles, +4 pierce, creates a yarn cloud on track every 8s (1 dps, pierce 10, 6s). |

---

### Nibs — Circle Pouncer
- **Role**: Close-range 360-degree radial defense and DoT applier.
- **Category**: Alley | **Mask**: Land | **Base Cost**: 280 kibble.
- **Base Stats**: 8 short Claw arcs, 1 damage, 1 pierce, 75 range, 1.1s cooldown. Cannot see Shadow.

| Tier | Path A: More Paws | Path B: Hot Claws | Path C: Long Pounce |
| :---: | :--- | :--- | :--- |
| **1** | **More Claws** (150): 10 arcs. | **Hot Claws** (200): Burn 1 dps for 3s (Bite damage; pops Iron). | **Long Reach** (150): Range 110. |
| **2** | **Feral Swipes** (300): 12 arcs, damage 2. | **Searing Claws** (400): Burn 2 dps. Double burn vs Frost coats. | **Extended Arcs** (350): Range 140, arcs become short projectiles with pierce 2. |
| **3** | **Frenzy** (900): 16 arcs, cooldown 0.8s. | **Spreading Embers** (800): On enemy death, burn jumps to 3 nearby mice. | **Pounce Shockwave** (1200): Every 5th attack emits a 180-radius ring dealing 2 damage. |
| **4** | **Pounce Mastery** (4000): +2 damage vs Porcelain. | **Wildfire** (3000): Burn jumps to 6 mice on death. | **Tremor Ring** (3500): Ring pierce increased to 20. |
| **5** | **Blender** (22000): 24 claw hits/sec in range, 2 damage, pierce 2, +4 vs Porcelain. | **Chili Mittens** (19000): Burn 5 dps. Rats take 50% dps; Matriarch takes 25%. | **Alley Sweep** (17000): Every 6s, dashes along nearest 200 units of track: 8 Bite to mice, 30 to rats, 15 to Matriarch. |

---

### Pudding — Frostpaw
- **Role**: Crowd control, freeze, damage amplification.
- **Category**: Alley | **Mask**: Land | **Base Cost**: 400 kibble.
- **Base Stats**: Pulse every 1.5s, radius 90, freeze 1.0s. Frozen mice take +1 damage from Bite and Blast. Frost coats immune. Iron freezes 0.4s; Rats freeze 0.3s; Matriarch immune. Base pulse deals 0 damage.

| Tier | Path A: Whiteout | Path B: Brittle | Path C: Permafrost |
| :---: | :--- | :--- | :--- |
| **1** | **Deep Freeze** (200): Freeze 1.5s. | **Brittle Ice** (250): Frozen targets take +1 extra damage. | **Chilling Trail** (200): After freeze, 30% slow for 2s. |
| **2** | **Frost Bite** (400): Pulse deals 1 Bite damage. | **Porcelain Cracker** (500): +1 extra damage vs Porcelain. | **Lingering Frost** (450): Slow increased to 40% for 4s. |
| **3** | **Blizzard Pulse** (1500): Freeze 2.0s, pulse damage 2. | **Shatter Mark** (1600): Brittle damage buff persists 3s after freeze ends. | **Frost Patch** (1400): Leaves a 6s frost patch on track dealing 40% slow. |
| **4** | **Ice Shards** (4500): Popping frozen mice shatters for 2 Bite in 40 radius. | **Rat Cracker** (5000): Pulse applies +2 damage taken to rats for 4s even with short freeze. | **Sub-Zero Patches** (4000): Patches deal 1 Bite dps. |
| **5** | **Whiteout** (24000): Radius 160, freeze 2.5s, shatter deals 6 damage. Every 20s freezes track segment for 4s. Rats freeze 0.6s. Matriarch ignores control, takes 2 pulse damage. | **Brittle Crown** (26000): Mice take +4 damage while brittle. Rats take +3 for 5s. Matriarch takes +1 for 3s (damage amp permitted). | **Glacier Den** (20000): Permanent 120-radius zone: Mice 50% slow & 3 dps; Rats 30% slow & 5 dps; Matriarch takes 2 dps (no slow). |

---

### Biscuit — Fishbone Lobber
- **Role**: Artillery, area-of-effect Blast damage, crowd clearing.
- **Category**: Alley | **Mask**: Land | **Base Cost**: 525 kibble.
- **Base Stats**: 1 Blast damage, 16 pierce, 45 explosion radius, 1.45s cooldown, 160 range, ~0.4s travel time. Soot immune. Pops Iron.

| Tier | Path A: Heavy | Path B: Cluster | Path C: Rapid |
| :---: | :--- | :--- | :--- |
| **1** | **Bigger Bones** (300): Radius 60, damage 2. | **Bone Shards** (250): Releases 4 crumbs dealing 1 damage. | **Fast Loader** (250): Cooldown 1.1s. |
| **2** | **Heavy Spine** (600): Damage 3. | **Cluster Bones** (500): Releases 6 crumbs. | **Greased Paw** (500): Cooldown 0.85s. |
| **3** | **Concussive Blast** (1800): Damage 6. Stun mice 0.5s, rats 0.2s. | **Secondary Burst** (1600): Crumbs explode again for 2 damage. | **Scorched Ground** (1400): Burning patch dealing 2 dps for 3s. |
| **4** | **Siege Mortar** (5500): Damage 12, radius 80, +10 vs rats. | **Fish Flakes** (4000): Crumbs deal Bite damage (hits Soot). | **Alley Gatling** (4500): Cooldown 0.6s, damage 2. |
| **5** | **Whale Fall** (28000): Damage 20, +40 vs rats, radius 100, stuns rats 1.2s (Bristle 0.8s, Monarch 0.4s, Dusk 0.6s, Matriarch 0s). Cooldown 2.2s. | **Crumb Carpet** (22000): 12 crumbs dealing 3 Bite, creates 3s carpet zone. | **Barrage Basket** (20000): Cooldown 0.35s, damage 3, radius 50, burn patch deals 4 dps. |

---

### Sable — Rooftop Sniper
- **Role**: Global range, single-target hitscan, heavy rat assassin.
- **Category**: Hunt | **Mask**: Perch or Land | **Base Cost**: 450 kibble.
- **Base Stats**: Full-track hitscan, 2 Bite damage, 1 pierce, 1.35s cooldown, 0.15s tracer (visual only). Cannot see Shadow. Pops Iron.

| Tier | Path A: Hamstring | Path B: Shrapnel | Path C: Deadeye |
| :---: | :--- | :--- | :--- |
| **1** | **Heavy Caliber** (350): Damage 4. | **Shrapnel Shot** (300): Splash 2 Claw, radius 30, pierce 6. | **Hair Trigger** (400): Cooldown 1.0s. |
| **2** | **Pointed Lead** (700): Damage 8, +4 vs Porcelain. | **Wide Blast** (600): Splash radius 50. | **Quick Chamber** (800): Cooldown 0.75s. |
| **3** | **Crippling Shot** (2200): Stun non-Matriarch rats for 1.0s. | **Bouncing Shards** (2000): Splash bounces once. | **Priority Lens** (1500): Target priority: Rats → Porcelain → Progress. |
| **4** | **Tendon Tear** (7000): Damage 18, stun 1.5s. | **Flak Burst** (5000): 3 bounces. | **Rapid Fire** (6000): Damage 6, cooldown 0.55s. |
| **5** | **Hamstring** (32000): Damage 40, +30 vs rats. Stuns: Burrow 2.5s, Bristle 1.5s, Monarch 0.7s, Dusk 1.2s. Matriarch: Not stunned, gains Mark +3 for 2s. | **Ricochet** (24000): Main hit 8. Bounces to 6 targets for 6 Bite. Gains Night Eye. | **One-Shot Lane** (27000): Cooldown 0.4s, damage 8. Every 8th shot deals 80 damage to a single target. |

---

### Nim — Spark Apprentice
- **Role**: Magic attacker, line-piercing beams, hex DoT spreader.
- **Category**: Myth | **Mask**: Land | **Base Cost**: 475 kibble.
- **Base Stats**: 2 Magic damage, 4 pierce, 0.9s cooldown, 150 range. Cannot damage Ink until Path C. Pops Iron.

| Tier | Path A: Lance | Path B: Purr | Path C: Hex |
| :---: | :--- | :--- | :--- |
| **1** | **Arcane Bolt** (300): Damage 4. | **Flame Tongue** (350): Short cone, 3 magic dps for 0.5s. | **Ink Siphon** (250): Can hit Ink coats. |
| **2** | **Piercing Spark** (600): Pierce 8. | **Searing Purr** (700): Wider cone. | **Seeking Sparks** (500): Bolts steer and seek. |
| **3** | **Spark Beam** (2500): Becomes a continuous line beam dealing 4 damage. | **Fiery Breath** (2000): Cone applies Burn (3 dps for 2s). | **Curse of Static** (2200): Hex: 4 damage over 4s; spreads to 1 nearby mouse on death. |
| **4** | **Focus Lance** (8000): Beam damage 10. | **Overheat** (5500): Cone attack rate doubles. | **Contagion** (6000): Hex spreads to 4 mice on death. |
| **5** | **Void Hairball** (30000): Beam damage 18, unlimited pierce along beam, +12 vs rats, 0.7s cooldown. Damage type is Void (damages Ink). | **Purrnado** (26000): Every 12s a tornado walks track for 6s (12 magic dps, pulls non-rat mice back 80 units; Matriarch takes 4 dps, immune to pull). | **Grand Hex** (24000): Mice take 20 damage over 5s (spreads to 8); Rats take 40 over 5s; Matriarch takes 20 over 5s (hex does not spread off her). |

---

### Goldie — Fishercat
- **Role**: Economic generator and match funding.
- **Category**: Den | **Mask**: Land (Footprint: diameter 55) | **Base Cost**: 1250 kibble.
- **Base Stats**: Zero attack. Produces **140 kibble** automatically at the end of each round.

| Tier | Path A: Vault | Path B: Catch Meter | Path C: Night Market |
| :---: | :--- | :--- | :--- |
| **1** | **Full Basket** (400): Produces 200 kibble. | **Tackle Box** (300): Catch meter fills (~every 4 rounds); awards 150 kibble on full. | **Fish Stall** (350): Produces 160 kibble; next cat placement this round is 50 off. |
| **2** | **Deep Crate** (800): Produces 280 kibble. | **Fish Finder** (700): Meter fills faster, awards 200 kibble. | **Bulk Deal** (900): Next placement this round is 100 off. |
| **3** | **Fisherman's Keep** (1800): Produces 400 kibble. | **Live Well** (2000): Stores up to 2 payouts. | **Wholesale** (2500): Next placement 150 off; upgrades in aura range 5% off. |
| **4** | **Fish Vault** (5000): Production stored in vault. Generates +8% compound interest per round. Cap 4000 kibble. | **Trophy Catch** (4500): Meter payout averages ~180 extra/round, visible on cat. | **Harbor Guild** (6000): Produces 300 kibble; placement discount 200 kibble. |
| **5** | **Deep Vault** (18000): 12% interest, cap 15000, +200 flat/round. Optional auto-collect at round start. | **Trophy Fish** (16000): Every 5th round pays 1200 flat kibble (deterministic meter, no slot machine). | **Night Market** (22000): Produces 800/round; 10% off all upgrades on map; grants 1 free Tier-1 token per round. |

*Economic Rule*: Path B is deterministic; no random gambling. 2-0-0 Goldie returns cost in ~8 rounds on Alley.

---

### Miso — Cafe Cat
- **Role**: Support buffer, range/attack speed aura, cost discounts.
- **Category**: Den | **Mask**: Land | **Base Cost**: 700 kibble.
- **Base Stats**: Zero direct attack. Emits a 110-radius aura: cats in aura gain +10% range. Miso does not buff herself. Heroes gain half aura bonuses.

| Tier | Path A: Tempo | Path B: Menu | Path C: Bell |
| :---: | :--- | :--- | :--- |
| **1** | **Fresh Roast** (400): +10% attack speed to cats in aura. | **Night Roast** (500): Grants Night Eye to cats in aura. | **Happy Hour** (300): Placements and upgrades in aura are 5% off. |
| **2** | **High Roast** (800): Total range aura buff becomes +15%. | **Wide Table** (900): Aura radius increases to 150. | **Special Blend** (800): Discount increases to 10% off. |
| **3** | **Caffeine Rush** (2000): +18% attack speed in aura. | **Full Spread** (2500): +1 pierce to cats in aura. | **Loyalty Card** (3000): Discount increases to 15% off. |
| **4** | **Grand Cafe** (6000): Aura radius 160. Alley cats in aura gain +1 damage. | **Special Recipe** (4000): Night Eye and pierce buffs remain strictly aura-bound. | **Rallying Bell** (7000): Active ability: cats in aura gain +70% attack speed for 8s (50s cooldown). Discount stays 15%. |
| **5** | **Head Barista** (20000): Radius 200: +25% attack speed, +20% range, Alley cats +1 damage, Hunt cats with crit gain +10% crit rate. | **All-Seeing Menu** (18000): Radius 260, Night Eye, +2 pierce. Every 15s reveals all Shadow mice on map for 3s. | **Grand Bell** (22000): Active ability: +100% attack speed for 12s (45s cooldown); during buff Alley and Hunt cats gain +1 damage. |

---

## 3. Post-Launch Roster (v1.1 & v1.2 Roadmap)

Identities, base archetypes, and price bands follow the identical crosspath laws:
- **Honey (Yarn Weaver)**: Land, 250 kibble. Slows single targets with honey; Solvent Honey, Amber hard CC.
- **Marlow (Washtub Gunner)**: Water, 500 kibble. Rapid dart shooter; Harpoon anti-rat, Submarine Gutter Sonar radar.
- **Inky (Shadow Dancer)**: Land, 500 kibble. Caltrops & track traps, natural Night Eye; Blackout global slow.
- **Bub (Potion Cat)**: Land, 450 kibble. Acid pools popping Iron & Ink; Master Brew permanent buffs, Midas Mitt income.
- **Rip (Glider Cat)**: Air Lane, 550 kibble. Circular aerial patrols, bomb drops; tight orbit pinning dense packs.
- **Bramble (Thorn Cat)**: Land, 400 kibble. Thorn bursts; Denheart damage aura, chain lightning.
- **Sprocket (Contraption Cat)**: Land, 400 kibble. Sentry kitten builder; Grand Overclock, Rat Snare track traps.
- **Lumen (Sun Cat)**: Land, 2500 kibble. Ultra-fast magic bite beam (0.08s cooldown); Solstice beam, King's Roar stun.
- **Vesper (Pursuit Cat)**: Air Lane, 800 kibble. Interceptor aircraft patrol; supply drop calling temporary helper kittens.

---

## 4. Alpha Cats (Post-v1 Reserved Specification)

- **Definition**: An ultimate cat formed by sacrificing all three Tier-5 upgrade versions of the same cat type currently on the battlefield.
- **Prerequisite**: Cat Mastery Rank 10.
- **v1 Status**: Schema field `alpha: null` is reserved across all cat data schemas to guarantee save and balance tool compatibility without enabling Alphas in v1.

