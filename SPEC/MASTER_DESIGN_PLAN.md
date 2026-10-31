# Clowder: Alley Siege — Full Game Plan

Working title: **Clowder: Alley Siege** (short name **Clowder**).

A free, single-player path tower defense. Cats hold a track. Mice walk that track in coats that pop into smaller mice. Giant rats are the late-game bosses of a wave. The game never asks for real money. There are no ads, no premium currency, and no loot boxes.

This is original IP. The genre reference is modern path tower defense (the family of games people know from Bloons TD). Names, art, round lists, and numbers below are Clowder’s own. Do not copy Ninja Kiwi names, art, audio, or round files.

## Assumptions locked for this plan

These are the defaults. Change any of them before production and the rest of the plan still stands.

- 2D, top-down 3/4 view, readable at a glance.
- Engine: Godot 4. PC (Windows) first. Web export is a later port, not a v1 requirement.
- Single player in v1. Co-op is post-launch.
- Language: English first.
- Session targets: Sunny clear about 15–25 minutes at 2× speed. A round-100 clear about 35–50 minutes at 2× speed.
- Zero monetization surfaces. A tip jar, if it ever exists, lives outside the game and unlocks nothing.

---

## 1. Player fantasy and pillars

You are the alley keeper. A clowder of cats defends the fish market from a rising mouse tide. Early rounds are small coats. Later rounds are porcelain shells, then rats the size of carts, then the Rat Matriarch.

Pillars:

1. **Readable defense.** A player can tell coat, speed, and immunity from silhouette, not only color.
2. **Build identity.** Each cat has three upgrade paths. A crosspath is a real choice.
3. **Four kinds of growth.** In-match kibble buys upgrades. In-match feat XP grows the cat you actually placed. Account XP buys passive skills. Fishcoin buys looks and active tricks.
4. **Fair and free.** Every standard map can be beaten with no tricks and no passive skills. The shop never sells power that the mastery mode depends on.
5. **Commitment.** Selling a cat refunds kibble and deletes that cat’s feats. Heroes stay on the field.

---

## 2. Glossary (your words → game words)

| You asked for | In Clowder |
| --- | --- |
| Monkeys / towers | **Cats** |
| Hero with a special ability | **Hero cats** (one per match) |
| Different mice | **Mice**, twelve coats |
| MOAB-class | **Rats**: Burrow, Bristle, Monarch, Dusk, Rat Matriarch |
| In-match game money | **Kibble** |
| Shop money | **Fishcoin** |
| Skills | **Insights**, the passive skill trees |
| Experience for a new passive | **Account XP** → Insight points. Passives are never sold. |
| Cats need XP for feats in a match | **Feat XP** on each placed cat, spent between rounds on a feat card |
| Cats need XP for features over time | **Mastery XP** per cat type, unlocks higher upgrade tiers |
| Shop: visuals | Skins, trails, banners, emotes |
| Shop: active in-game ability | **Tricks**, equipped before the match, fired during it |

---

## 3. The match

### Win and loss

- Mice and rats follow a path from entrance to exit.
- If a unit reaches the exit, you lose lives equal to its remaining **RBE** (red-mouse equivalent: total hit points still inside it, including children it would spawn).
- Lives at 0 ends the match.
- You win by clearing the mode’s final round. You may keep going into freeplay.

| Mode | Final round for the medal | Lives | Start kibble | Shop prices | Continues | Insights | Tricks | Selling |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Sunny | 40 | 200 | 850 | ×0.85 | up to 3 | on | on | yes, 70% |
| Alley | 60 | 150 | 650 | ×1.00 | up to 2 | on | on | yes, 70% |
| Night | 80 | 100 | 550 | ×1.08 | 1 | on | on | yes, 70% |
| Last Whisker | 100 | 1 | 650 | ×1.20 | 0 | on | on | yes, 70% |
| Bare Paw | 100 | 1 | 650 | ×1.00 | 0 | off | off | no |

Bare Paw is the mastery mode. It is the proof that a map is fair. Continues, Insights, Tricks, and selling are all off. Heroes and in-match feats stay on, because those are played, not bought.

Map modifiers, each with its own medal:

- **Alternate Warrens** — porcelain arrives on round 32, the first rat arrives two rounds early, more Gnaw coats.
- **Full Nets** — pop income ×2, and round 40 sends two Burrow Rats.
- **Short Leash** — lives halved (Last Whisker and Bare Paw stay at 1).

### Round flow

- Between rounds the player places cats, upgrades, changes targeting, and picks feat cards.
- The next round starts on a button, or on auto-start after a 0.4s beat.
- Speed: pause, 1×, 2×, 3×. Hotkeys: Space start, 1/2/3 speed, Esc pause.
- Feat cards open **between rounds**, never mid-leak. If several cats feat in the same round, the cards come in order.
- A continue, on modes that allow it, restarts the failed round and costs `250 + 25 × round` kibble. If the wallet cannot pay, the continue is unavailable. Continues are not a shop item.

### Sunny round 40 rat

On Sunny only, the round-40 Burrow Rat has 65% body health (130 instead of 200). Children are unchanged. RBE is 546 instead of 616.

---

## 4. Combat rules (implement these exactly)

### Space

- Sim tick: 30 Hz fixed. Rendering interpolates.
- A path is a polyline with distance `s` from 0 to length `L`.
- Standard test lane: **Sunny Gutter is 1200 units**. A Rust mouse at 40 units/second crosses it in 30.0 seconds. All balance refers to that ruler.
- Expert lane **The Warren is 700 units**.
- Cats stand on placement masks: Land, Water, or Perch. Footprints are circles and cannot overlap. Most cats are diameter 40. Goldie is 55.
- Obstacles block placement and block line-of-sight projectiles. Lobs and full-track shots ignore obstacles.

### Damage types

| Type | Stopped by |
| --- | --- |
| Claw | Iron coats |
| Bite | nothing by coat |
| Blast | Soot coats |
| Magic | Ink coats |
| Acid | nothing by coat |
| Void | nothing by coat (rare, late upgrades) |
| True | nothing |

### Status

| Status | Effect | Rule |
| --- | --- | --- |
| Chill / Honey | speed multiplier below 1 | the strongest slow wins. Slows do not multiply together |
| Freeze | speed 0 for a duration | refresh uses the longer remaining time. Cannot chain into a permanent freeze |
| Burn | damage over time, Bite-typed | a new burn refreshes duration. Damage per second does not stack |
| Stun | speed 0, and the unit cannot be pushed | duration is shortened on larger rats (see each upgrade) |
| Knockback | moves `s` backward | has a per-unit cap per second |
| Mark | target takes extra damage from all sources | durations do not stack; the stronger mark wins |
| Hex / Bleed | damage over time that can spread | spread rules are per upgrade |

**Rat Matriarch control immunity (one component, not per-cat exceptions):** she ignores stun, knockback, freeze, slow, amber, and instant-kill. She can still take damage, Mark, Hex, and Burn, at the reduced numbers written on each upgrade.

### Pop resolution

1. A projectile hits a target and removes `min(layer HP, damage)` from the current coat.
2. At 0 layer HP, children spawn at the same path position.
3. Overflow damage (`damage − HP removed`) applies to the **first** child in the same hit and does not cost extra pierce. It recurses.
4. Other children are separate targets. Pierce `P` means `P` targets. The overflow chain on the first child is part of the same target.
5. An explosion hits each unit in its radius once.
6. Overkill past the last child pays nothing extra and leaks nothing extra.

### Properties

- **Shadow** — cannot be targeted unless the attacker has Night Eye, or the mouse is inside a reveal pulse.
- **Gnaw (regrow)** — if 2.8 seconds pass without losing a coat, the mouse regrows one coat, up to its spawn coat. Cap: 3 regrows per mouse. Regrow only happens while speed is at least 80% (chill, honey, and freeze all suppress regrow).
- **Plated** — outermost layer HP ×2. Children of a plated **mouse** stay normal. Children of a plated **rat** are plated.
- Rats are not coats. They have a body HP bar. At 75%, 50%, and 25% they change sprite. On death they spill their children.

### Leaks and money from damage

- Kibble is paid for HP actually removed.
- Leaked HP pays nothing.
- Lives lost equals remaining RBE of the leaking unit.

---

## 5. Mice

Layer HP is 1 except Porcelain, whose shell has 10. RBE includes children.

| Coat | Speed | Child | RBE | Immunity |
| --- | --- | --- | --- | --- |
| Rust | ×1.00 (40 u/s) | none | 1 | — |
| Slate | ×1.40 | Rust | 2 | — |
| Moss | ×1.80 | Slate | 3 | — |
| Grain | ×3.20 | Moss | 4 | — |
| Sugar | ×3.50 | Grain | 5 | — |
| Soot | ×1.80 | 2 Sugar | 11 | Blast |
| Frost | ×1.80 | 2 Sugar | 11 | Freeze and Chill |
| Ink | ×1.80 | 2 Sugar | 11 | Magic |
| Iron | ×1.00 | 2 Soot | 23 | Claw |
| Marble | ×1.80 | 1 Soot + 1 Frost | 23 | Blast, Freeze, Chill |
| Prism | ×2.20 | 2 Marble | 47 | — |
| Porcelain | ×2.50 | 2 Prism | 104 | shell has 10 HP |

Plated outermost HP doubles. Plated Porcelain shell is 20, RBE 114. Plated Iron is RBE 24.

Shape language (colorblind, always on, not a shop item):

- Rust — round ears
- Slate — notched ear
- Moss — leaf tail
- Grain — stripe tail
- Sugar — heart tail tip
- Soot — square body
- Frost — white ruff, even on colorblind palette
- Ink — dripping tail
- Iron — bucket helmet
- Marble — split face
- Prism — scarf
- Porcelain — cracked jar carried on the back
- Any Shadow — translucent plus a star mark
- Any Gnaw — green chew mark
- Any Plated — metal rim

Health bars are for rats only. Mice communicate by coat flashes. Porcelain and above also show a small pip count.

### Super Porcelain, from round 81 onward

- Shell HP becomes 60 (Plated 120).
- Every non-rat mouse spawns **one** child, the primary child (Marble’s primary child is Soot).
- Super Porcelain RBE = 68. Plated super Porcelain RBE = 128.
- Popping the shell pays a flat **Shell Bounty of 48 kibble** instead of 1 per shell HP, so income survives and pierce matters less than single-target damage.
- Inner coats still pay 1 kibble per HP.

---

## 6. Rats

| Rat | First round | Body HP | Speed | On death | Notes |
| --- | --- | --- | --- | --- | --- |
| Burrow Rat | 40 | 200 | ×1.00 | 4 Porcelain | the first “blimp” |
| Bristle Rat | 60 | 700 | ×0.55 | 4 Burrow Rats | |
| Monarch Rat | 80 | 4000 | ×0.30 | 4 Bristle Rats | knockback immune; stun duration ×0.5 |
| Dusk Rat | 90 | 700 | ×3.20 | 4 Shadow Plated Porcelain | Claw immune, Blast immune, Shadow. Chill effect ×0.5 |
| Rat Matriarch | 100 | 22000 | ×0.18 | 2 Monarch + 3 Dusk | full control immunity |

RBE:

| Unit | RBE |
| --- | --- |
| Burrow | 616 |
| Plated Burrow | 856 |
| Bristle | 3164 |
| Plated Bristle | 4824 |
| Monarch | 16656 |
| Plated Monarch | 27296 |
| Dusk (round 90+, super children) | 1212 |
| Rat Matriarch | 58948 |

One Burrow leak on Alley (150 lives) is a loss. That is intentional. Small coats are the recoverable leaks.

---

## 7. Economy inside a match

### Kibble sources

- 1 kibble per HP removed on rounds 1–50.
- ×0.85 on rounds 51–80.
- ×0.50 on rounds 81–100, plus the Porcelain shell bounty.
- Rounds 101+: `0.50 × (0.96 ^ (round − 100))`, floor 0.05, plus shell bounty.
- End-of-round bonus: `1 × round` kibble. Small on purpose. Farms are the real income engine.
- Sunny start 850, Alley and the prestige modes 650, Night 550.

### Kibble sinks

- Place cats and the hero.
- Buy upgrade tiers.
- Pay trick activation costs.
- Pay a continue.
- One feat reroll per cat per match: 150 kibble.

### Selling and prices

- Sell refund is 70% of kibble spent on that unit, rounded down.
- Selling wipes feats. Rebuying starts at feat XP 0.
- Heroes cannot be sold. A hero can be moved once for free before round 20. After that, a move costs 200 kibble and then waits 5 rounds.
- Discount formula when Cafe or Fishercat discounts apply:

`price = base × modePriceMultiplier × (1 − highestDiscount)`

The result never drops below 60% of the mode-adjusted base. Two discounts do not add. Miso does not discount Miso.

### What a Sunny start should feel like

Acceptance test, scripted, no leaks: place one Pip on round 1. After round 10 the wallet can buy Mittens, Nibs, and one tier-1 upgrade, with kibble left over. Early-round RBE is authored to make this true (about 1100 total RBE across rounds 1–10, plus 850 start).

---

## 8. Cats (towers)

### Crosspath law

- Three paths: A, B, C.
- A cat can spend kibble on at most two paths.
- If one path reaches tier 3 or higher, the other path stops at tier 2.
- Only one tier-5 of a given path of a given cat type can exist on the map. Selling it frees the slot.

### Mastery locks (meta XP, per cat type)

| Upgrade | Required mastery |
| --- | --- |
| Tiers 1 and 2 | rank 1 (the cat is unlocked) |
| Tier 3 | rank 2 |
| Tier 4 | rank 5 |
| Tier 5 | rank 8 |

The first match uses only tiers 1 and 2, because mastery rank 2 is earned by playing. That keeps the first game teachable.

### Targeting

First, Last, Strong, Close. Some cats add Rats First or Mice First.

**Strong** = highest RBE inside range. Tie goes to the unit farther along the path.

### Launch roster (8 cats, full upgrade sheets)

Costs below are Alley (×1.00) prices. Sunny ×0.85, Night ×1.08, Last Whisker ×1.20. Bare Paw uses ×1.00.

#### Pip — Yarn Tosser — Alley — Land — 200 kibble

Base: 1 Claw damage, pierce 2, cooldown 0.95s, range 130, projectile speed 400. Cannot see Shadow. Cannot pop Iron.

| Tier | Path A Needle | Path B Eye | Path C Multi |
| --- | --- | --- | --- |
| 1 | Long Needle, 150. Pierce 4 | Keen Whisker, 100. Range 160 | Twin Spool, 180. Fires 2 |
| 2 | Sharp Needle, 250. Damage 2 | Night Eye, 300. Sees Shadow | Triple Spool, 280. Fires 3 |
| 3 | Barbed Spool, 700. Damage 3, pierce 6 | Hawk Focus, 800. +25% attack speed, 15% crit for double damage | Seeking Yarn, 900. Needles steer toward a target with a limited turn rate |
| 4 | Spool Burst, 3200. Every 5th shot fires 8 needles | Marked Prey, 3500. Crits apply Mark +1 damage taken for 4s | Fivefold, 2800. Fires 5 |
| 5 | Spool Storm, 18000. Cooldown 0.45s. Every 5th shot fires 16 needles. +1 damage vs Porcelain and rats | Hawkeye, 16000. Full-track range, 25% crit, Mark +2 for 6s. Rats stay marked 4s. Matriarch mark is +1 for 3s | Yarn Tempest, 15000. 8 seeking needles, +4 pierce, and every 8s a yarn cloud on the track (1 dps, pierce 10, 6s) |

First-match answer to Iron is **not** Pip. See Nibs.

#### Nibs — Circle Pouncer — Alley — Land — 280

Base: 8 short Claw arcs, 1 damage, pierce 1, range 75, cooldown 1.1s. Cannot see Shadow.

| Tier | Path A More Paws | Path B Hot Claws | Path C Long Pounce |
| --- | --- | --- | --- |
| 1 | 10 arcs, 150 | Burn 1 dps for 3s (Bite). 200. This is how a first match pops Iron | Range 110, 150 |
| 2 | 12 arcs, damage 2. 300 | Burn 2 dps. Frost coats take double burn. 400 | Range 140. Arcs become short projectiles, pierce 2. 350 |
| 3 | 16 arcs, cooldown 0.8s. 900 | On death, burn jumps to 3 nearby mice. 800 | Every 5th attack emits a ring to range 180, 2 damage. 1200 |
| 4 | +2 damage vs Porcelain. 4000 | Jump to 6 on death. 3000 | Ring pierce 20. 3500 |
| 5 | Blender, 22000. 24 claw hits per second in range, 2 damage, pierce 2, +4 vs Porcelain | Chili Mittens, 19000. Burn 5 dps. Rats take 50%. Matriarch takes 25% | Alley Sweep, 17000. Every 6s, dash along the nearest 200 units of track: 8 Bite to mice, 30 to rats, 15 to the Matriarch |

#### Pudding — Frostpaw — Alley — Land — 400

Base: pulse every 1.5s, radius 90, freeze 1.0s. Frozen mice take +1 damage from Bite and Blast. Frost coats are immune. Iron freezes for 0.4s. Rats freeze for 0.3s. The Matriarch is not frozen. Base pulse deals no damage.

| Tier | Path A Whiteout | Path B Brittle | Path C Permafrost |
| --- | --- | --- | --- |
| 1 | Freeze 1.5s. 200 | Frozen targets take +1 more damage. 250 | After freeze, 30% slow for 2s. 200 |
| 2 | Pulse deals 1 Bite. 400 | +1 more vs Porcelain. 500 | Slow 40% for 4s. 450 |
| 3 | Freeze 2.0s, pulse damage 2. 1500 | Brittle lasts 3s after freeze ends. 1600 | Leaves a 6s frost patch, 40% slow. 1400 |
| 4 | Popping a frozen mouse shatters for 2 Bite in radius 40. 4500 | A pulse applies +2 damage taken to rats for 4s even when the freeze is short. 5000 | Patches deal 1 Bite dps. 4000 |
| 5 | Whiteout, 24000. Radius 160, freeze 2.5s, shatter 6. Every 20s, freeze a lane segment for 4s. Rats freeze 0.6s. The Matriarch ignores the control and can still take the 2-damage pulse | Brittle Crown, 26000. Mice +4 damage taken while brittle. Rats +3 for 5s. Matriarch +1 for 3s. This is damage amp, which she allows | Glacier Den, 20000. Permanent zone radius 120. Mice 50% slow and 3 dps. Rats 30% slow and 5 dps. Matriarch: 2 dps, no slow |

#### Biscuit — Fishbone Lobber — Alley — Land — 525

Base: Blast 1, pierce 16, radius 45, cooldown 1.45s, range 160, travel about 0.4s. Soot immune. Iron is popped (Blast cracks Iron).

| Tier | Path A Heavy | Path B Cluster | Path C Rapid |
| --- | --- | --- | --- |
| 1 | Radius 60, damage 2. 300 | 4 crumbs of 1 damage. 250 | Cooldown 1.1s. 250 |
| 2 | Damage 3. 600 | 6 crumbs. 500 | Cooldown 0.85s. 500 |
| 3 | Damage 6. Stun mice 0.5s, rats 0.2s. 1800 | Crumbs explode again for 2. 1600 | Burning patch 2 dps for 3s. 1400 |
| 4 | Damage 12, radius 80, +10 vs rats. 5500 | Crumbs become Bite, so they damage Soot. 4000 | Cooldown 0.6s, damage 2. 4500 |
| 5 | Whale Fall, 28000. Damage 20, +40 vs rats, radius 100, stun rats 1.2s (Bristle 0.8, Monarch 0.4, Dusk 0.6, Matriarch 0). Cooldown 2.2s | Crumb Carpet, 22000. 12 crumbs of 3 Bite, plus a 3s carpet zone | Barrage Basket, 20000. Cooldown 0.35s, damage 3, radius 50, burn patch 4 dps |

#### Sable — Rooftop Sniper — Hunt — Perch or Land — 450

Base: full-track hitscan, 2 Bite, pierce 1, cooldown 1.35s, tracer is visual only (0.15s). Cannot see Shadow. Pops Iron.

| Tier | Path A Hamstring | Path B Shrapnel | Path C Deadeye |
| --- | --- | --- | --- |
| 1 | Damage 4. 350 | Splash 2 Claw, radius 30, pierce 6. 300 | Cooldown 1.0s. 400 |
| 2 | Damage 8, +4 vs Porcelain. 700 | Splash radius 50. 600 | Cooldown 0.75s. 800 |
| 3 | Stun non-Matriarch rats 1.0s. 2200 | Splash bounces once. 2000 | Prefers rats, then Porcelain, then path progress. 1500 |
| 4 | Damage 18, stun 1.5s. 7000 | 3 bounces. 5000 | Damage 6, cooldown 0.55s. 6000 |
| 5 | Hamstring, 32000. Damage 40, +30 vs rats. Stun: Burrow 2.5s, Bristle 1.5s, Monarch 0.7s, Dusk 1.2s. Matriarch is not stunned and gains Mark +3 for 2s | Ricochet, 24000. Main hit 8. Bounce to 6 targets for 6 Bite. Gains Night Eye | One-Shot Lane, 27000. Cooldown 0.4s, damage 8. Every 8th shot deals 80 to one target |

#### Nim — Spark Apprentice — Myth — Land — 475

Base: Magic 2, pierce 4, cooldown 0.9s, range 150. Cannot hit Ink until path C. Pops Iron.

| Tier | Path A Lance | Path B Purr | Path C Hex |
| --- | --- | --- | --- |
| 1 | Damage 4. 300 | A short flame cone, 3 magic dps for 0.5s. 350 | Can hit Ink. 250 |
| 2 | Pierce 8. 600 | Wider cone. 700 | Bolts seek. 500 |
| 3 | Becomes a line beam, damage 4. 2500 | Cone applies Burn 3 dps for 2s. 2000 | Hex: 4 damage over 4s. If the target dies hexed, spread to 1 nearby mouse. 2200 |
| 4 | Beam damage 10. 8000 | The cone’s rate doubles. 5500 | Spread to 4. 6000 |
| 5 | Void Hairball, 30000. Beam damage 18, unlimited pierce along the beam, +12 vs rats, cooldown 0.7s. Damage type Void, so Ink is hit | Purrnado, 26000. Every 12s a tornado walks the path for 6s, 12 magic dps, and pulls non-rat mice back 80 units. Rats are not pulled. Matriarch takes 4 dps and is not pulled | Grand Hex, 24000. Mice: 20 damage over 5s, spread to 8. Rats: 40 over 5s. Matriarch: 20 over 5s, and the hex does not spread off her |

#### Goldie — Fishercat — Den — Land — 1250

No attack. At the end of each round, adds 140 kibble to the wallet.

| Tier | Path A Vault | Path B Catch Meter | Path C Night Market |
| --- | --- | --- | --- |
| 1 | Produce 200. 400 | Meter fills. At full, pay 150. About every 4 rounds at this tier. 300 | Produce 160, and the next placement this round is 50 off. 350 |
| 2 | Produce 280. 800 | Meter pays 200, fills faster. 700 | Next placement is 100 off. 900 |
| 3 | Produce 400. 1800 | Two payouts can be stored. 2000 | Next placement 150 off, and upgrades in range are 5% off. 2500 |
| 4 | Vault, 5000. Production is stored. +8% of the stored amount per round as interest. Cap 4000. At the cap, production pauses until you collect | Meter payout averages about 180 extra per round and is shown on the cat. 4500 | Produce 300. Placement discount 200. 6000 |
| 5 | Deep Vault, 18000. Interest 12%, cap 15000, plus 200 flat per round. Optional auto-collect at round start | Trophy Fish, 16000. Every 5th round pays 1200. Deterministic. The meter is visible. No random jackpot | Night Market, 22000. Produce 800 per round. 10% off all upgrades on the map. One free tier-1 token per round, applied to a cat you pick. The 10% follows the global discount rule |

Design rule: income upgrades are readable. Path B is a filling meter, never a slot machine.

Payback target: a 2-0-0 Goldie returns its cost in about 8 rounds on Alley. A tier-5 bought before round 30 pays off by the mode’s final round. A tier-5 bought after round 60 is a luxury, not a requirement.

#### Miso — Cafe Cat — Den — Land — 700

Aura radius 110. Cats with their center in the aura gain +10% range. Miso does not buff herself. Heroes take half of any aura bonus.

| Tier | Path A Tempo | Path B Menu | Path C Bell |
| --- | --- | --- | --- |
| 1 | +10% attack speed in the aura. 400 | Night Eye for cats in the aura. 500 | Upgrades and placements in the aura are 5% off. 300 |
| 2 | Total range bonus becomes +15%. 800 | Aura radius 150. 900 | 10% off. 800 |
| 3 | +18% attack speed. 2000 | +1 pierce in the aura. 2500 | 15% off. 3000 |
| 4 | Aura radius 160. Alley cats in range gain +1 damage. 6000 | Night Eye and pierce stay aura-only, so placement still matters. 4000 | Rallying Bell: cats in the aura gain +70% attack speed for 8s. Cooldown 50s. Discount stays 15%. 7000 |
| 5 | Head Barista, 20000. +25% attack speed, +20% range, Alley cats +1 damage, Hunt cats with a crit stat gain +10% crit chance. Radius 200 | All-Seeing Menu, 18000. Radius 260, Night Eye, +2 pierce, and every 15s reveal all Shadow mice on the map for 3s | Grand Bell, 22000. Ability becomes +100% attack speed for 12s, cooldown 45s, and during it Alley and Hunt cats gain +1 damage. Discount stays 15% |

### Later cats (v1.1–v1.2)

Same crosspath law, same mastery locks, same price bands (T1 100–400, T2 200–900, T3 800–2500, T4 2500–8000, T5 15000–32000). Full 15-row sheets get written in production using the launch tables as the template. Identities are locked now so code can reserve behavior components.

| Cat | Cat. | Place | Cost | Base behavior | Path fantasies | Tier-5 signatures |
| --- | --- | --- | --- | --- | --- | --- |
| Honey, Yarn Weaver | Den | Land | 250 | Splats one mouse to 50% speed for 8s | A corrosive honey, B soak groups, C hard stop | Solvent Honey (5 dps, soaks 8). Honey Flood (a zone). Amber (mice held 4s; rats slowed 40%; Matriarch untouched) |
| Marlow, Washtub Gunner | Hunt | Water | 500 | Spits darts, 1 Bite, pierce 3, cooldown 0.7s | A twin spit, B harpoon for rats, C dive | Gutter Sonar: while dived, Night Eye radar. Every 10s, reveal all Shadow on the map briefly |
| Inky, Shadow Dancer | Myth | Land | 500 | Fast caltrops, has Night Eye, 1 Claw, pierce 2 | A fan of claws, B track traps, C flash step | Blackout: ability, all mice move at 50% for 8s. Matriarch moves at 70%. Cooldown 40s |
| Bub, Potion Cat | Myth | Land | 450 | Acid flask, damage over time, pops Iron and Ink | A stronger acid, B brew a neighbor cat, C kibble flask | Meltdown puddle. Master Brew: a strong permanent buff on one cat and a weaker splash. Midas Mitt: a capped slice of damage becomes kibble, with a per-round ceiling |
| Rip, Glider Cat | Hunt | Air lane (any) | 550 | Circles the map, drops claw darts | A rapid dives, B fishbone drops (Blast), C tight orbit over a chosen point | Pinwheel: the orbit sticks to the densest group |
| Bramble, Thorn Cat | Myth | Land | 400 | Throws thorns, 1 Claw, pierce 2 | A heavier thorns, B damage aura for neighbors, C lightning | Thorn Emperor (track storm). Denheart (+1 damage aura). Alley Tempest (chain lightning) |
| Sprocket, Contraption Cat | Den | Land | 400 | Builds a sentry kitten every 8s, max 3, each lives 25s | A more sentries, B overclock another cat, C nets on the track | Sentry Parade (8 sentries). Grand Overclock (+100% attack speed on one cat for 30s, and a permanent +10% while pinned). Rat Snare (holds a Burrow 2s, larger rats 0.5s, Matriarch immune) |
| Lumen, Sun Cat | Myth | Land | 2500 | Very fast magic bites, 1 damage, pierce 1, cooldown 0.08s, medium range | A beam, B seeking sparks, C roar | Solstice (a ramping beam). Eclipse (anti-Shadow sparks). King’s Roar (periodic stun in range; Matriarch immune) |
| Vesper, Pursuit Cat | Hunt | Air lane | 800 | Flies to a target or patrols | A chase, B damage trail, C supply drop | Clowder Drop: calls 3 temporary kittens for 15s |

v1 ships the launch 8 plus Mittens. v1.1 adds Honey, Marlow, Inky, Bub, and two heroes. v1.2 adds the rest.

### Alpha cats (post-v1, schema reserved)

An Alpha is one cat made by sacrificing all three tier-5 versions of the same type on the field, and it requires mastery 10. v1 data sets `alpha: null` on every cat. Do not build Alphas in v1. The field exists so saves and content tools do not break later.

---

## 9. In-match feats

This is the “cats need experience during the game” system.

Each placed cat has its own feat XP.

- `featXP += damageDealt × 0.4`
- `+ 3` per coat fully removed
- Support cats (Goldie, Miso, Pudding, and any cat whose main job is a buff) also gain `0.25 × damage dealt by cats currently inside their effect`

Thresholds (cumulative): Feat I at 100, Feat II at 350, Feat III at 900.

A cat that is doing the real work reaches Feat II by about round 40 and Feat III between rounds 50 and 70. Three feats together are about half of one tier-3 upgrade. They reward keeping a cat. They do not replace the upgrade tree.

When a threshold is crossed, the card waits until the round ends. The player picks 1 of 3. The offer is seeded by `matchSeed + catInstanceId + featRank + pathBits`, so reloading the save does not reroll. One reroll per cat per match costs 150 kibble and advances a reroll counter in that seed.

Universal cards (any cat can roll these):

| Card | Effect | Weight note |
| --- | --- | --- |
| Long Whiskers | +12% range | common |
| Quick Paw | +10% attack speed | common |
| Deep Bite | +1 damage, −10% attack speed | common |
| Careful Aim | +2 pierce, −8% range | common |
| Night Snack | gain Night Eye | Feat II+ only, low weight |
| Thrifty | the next upgrade on this cat is 8% off, once | common |
| Veteran | +15% feat XP | Feat I only |

Each launch cat also has two path cards per path. Examples for Pip:

- A: **Barbed Tip** — +1 damage vs Porcelain.
- A: **Spool Rhythm** — the “every 5th shot” counter starts at 3, so the burst comes sooner.
- B: **Bright Pupil** — Mark duration +2s.
- B: **Night Drill** — Night Eye range is full track even before tier 5. Only if the cat already has Night Eye.
- C: **Loose Thread** — +1 projectile.
- C: **Sticky Cloud** — yarn clouds last +3s. Only if the cat has Yarn Tempest; otherwise this card is not in the offer.

Production writes the same two-card pair for every path of every launch cat before feat shipping. Cards that require a tier you do not own are filtered out.

Auto-pick exists in settings for players who want no cards. The recommended auto-pick is the highest-weight card that matches the cat’s highest path.

---

## 10. Heroes

One hero per match. Placed like a cat. Cannot be sold. Levels from 1 to 20 during the match from hero XP.

End-of-round hero XP if the hero was on the field that round:

`20 + 3 × round + 0.02 × heroDamageThatRound`

The damage term is small. The curve is carried by the round term, so a hero placed late still grows, and a hero placed on round 1 stays ahead.

Cumulative XP to **be** that level:

| Level | XP | What happens |
| --- | --- | --- |
| 1 | 0 | base stats |
| 2 | 80 | stat growth |
| 3 | 200 | first active. Reached around round 7 |
| 4 | 380 | stat growth. Mittens learns Night Eye here |
| 5 | 620 | stat growth |
| 6 | 920 | Mittens’ shots become Bite, so she pops Iron |
| 7 | 1300 | signature passive. Around round 22 |
| 8 | 1750 | stat growth |
| 9 | 2300 | stat growth |
| 10 | 2950 | second active. Around round 38 |
| 11 | 3700 | stat growth |
| 12 | 4550 | stat growth |
| 13 | 5500 | stat growth |
| 14 | 6550 | stat growth |
| 15 | 7700 | stat growth |
| 16 | 9000 | stat growth |
| 17 | 10400 | stat growth |
| 18 | 11900 | stat growth |
| 19 | 13500 | stat growth |
| 20 | 15200 | capstone passive. Around round 94 if placed on round 1 |

Stat growth per level, unless a hero section says otherwise: +3% damage, +1.5% attack speed, and on even levels +4 range.

Heroes unlock from **account level**, never from fishcoin. Fishcoin buys their skins.

Activating a hero ability is free of kibble. Tricks are the ones that cost kibble.

### Mittens — Yarn Warden — starter — place cost 600 — range 160

Fires 1 needle every 0.8s, 1 Claw damage, pierce 3. Level 4: Night Eye. Level 6: damage type becomes Bite.

- Level 3 active, **Pin Cushion**, cooldown 40s: 10 needles around Mittens, each 2 damage, pierce 4.
- Level 7 passive, **Soft Paws**: Mittens attacks 20% faster. Alley cats in her range gain +5% attack speed.
- Level 10 active, **Spool Barrage**, cooldown 50s: for 6s she fires 5 seeking needles per shot.
- Level 20 passive, **Last Thread**: the first time a leak would remove lives, prevent up to 20 lives of that leak, once per match, then Mittens gains +1 damage for the rest of the match.

### Duchess — Hearth Cat — place cost 750 — unlock account level 7

Flame lick, Magic plus Burn. Cannot hit Ink until level 8, when her flame becomes Void-tinged and Ink loses its immunity to her only.

- Level 3, **Heatwave**, cooldown 35s: Burn everything in radius 100 for 4 dps over 4s.
- Level 7, **Hearth**: Burn from Duchess lasts 2s longer. Blast cats in range gain +15 explosion radius.
- Level 10, **Chili Heart**, cooldown 50s: a fire zone on the nearest track point for 8s, 8 dps.
- Level 20, **Banked Coals**: her burn on a rat deals extra damage equal to 2% of that rat’s current HP per second, capped at 40 dps. The Matriarch’s cap is 15 dps.

### Baron Salt — Harbor Cat — place cost 700 — unlock account level 10

Throws fishbone bombs, Blast, similar pacing to a slow Biscuit.

- Level 3, **Depth Charge**, cooldown 40s: an explosion along 180 units of track, 6 Blast.
- Level 7, **Harbor Drill**: Biscuit and other Blast cats in range gain +1 Blast damage.
- Level 10, **Broadside**, cooldown 55s: three bombs of 15 Blast.
- Level 20, **Keelhaul**: every 8s his next bomb strips Plated from one target. The Matriarch’s Plated, if she ever has it, is stripped for 5s and then returns.

### Sister Pebble — Ledger Cat — place cost 900 — unlock account level 14

Weak poke, 1 Bite every 1.2s. She is the economy hero. Strong on long maps, weak on short expert maps that demand damage.

- End of every round: grant `10 + 2 × level` kibble.
- Level 3, **Skim**, cooldown 45s: the next round’s pop income is +20%.
- Level 7, **Ledger**: Fishercats in range produce +10%.
- Level 10, **Audit**, cooldown 60s: gain `500 + 30 × level` kibble immediately.
- Level 20, **Balanced Books**: the end-of-round grant becomes `40 + 4 × level`. The first leak each round has its life loss reduced by 5 (minimum 1 if the leak was larger than 1).

### Later heroes (kits locked, numbers tuned in their patch)

- **Obsidian**, myth buffer. Unlocks at account level 18. Level 3 plants a thorn totem on the track. Level 10 buffs Magic damage in a wide aura. Level 20 lets Myth cats in range ignore the Ink immunity for 10s on a cooldown.
- **Velvet**, short-range assassin. Unlocks at account level 22. Very high Bite damage, small range, no projectile. Level 3 is a dash along the path. Level 10 is a stealth window where she can see Shadow and gains crit. Level 20 lets one dash per cooldown strike a rat for a large Bite hit. She is the hero you place in a bend, and she is bad on open maps.

---

## 11. Account XP, levels, and the unlock queue

Account XP is granted at the end of a cleared round:

`grant = (20 + 2 × round) × modeMultiplier`

| Mode | Multiplier |
| --- | --- |
| Sunny | 0.70, and **1.00 on the first clear of that map** |
| Alley | 1.00 |
| Night | 1.30 |
| Last Whisker | 1.60 |
| Bare Paw | 2.00 |

Freeplay rounds after the mode’s medal round grant a flat 15 XP each. The best account growth is finishing harder modes, not idling to round 300.

A first Sunny clear of rounds 1–40 grants `sum(20 + 2r) = 2440` XP. Combined with the level costs below, that lands on account level 10. This is intentional.

Cost to go from level L to L+1: `120 + 30 × L`

| Reach level | Cumulative XP | Ceremony highlights (see queue rule) |
| --- | --- | --- |
| 2 | 150 | Pudding |
| 3 | 330 | Biscuit |
| 4 | 540 | Trick slot 1 |
| 5 | 780 | Sable |
| 6 | 1050 | Goldie |
| 7 | 1380 | Duchess, Miso |
| 8 | 1740 | Honey |
| 9 | 2130 | Nim |
| 10 | 2550 | Baron Salt, trick slot 2, Market Lane if not already opened by medal |
| 12 | — | Nine-Life Pulse becomes allowed (also costs fishcoin) |
| 14 | — | Sister Pebble |
| 16 | — | Fishmarket Maze |
| 18 | — | Obsidian |
| 22 | — | Velvet |

Exact cumulative XP past level 10 is `cost(L) = 120 + 30L` summed. The table above is the design target for the first session. A harness asserts that a no-leak Sunny clear ends at level 9, 10, or 11.

**Unlock queue.** New cats, heroes, and maps apply next match, not mid-round. If one match crosses many levels, the end screen reveals at most **2 cats, 1 hero, and 1 map**. The rest wait in a queue and reveal at later match ends. Points and fishcoin do not wait. This keeps match 2 from dumping the whole toybox on a new player.

Difficulty medals are gated by clearing the previous difficulty on that map, not by account level.

---

## 12. Insight skills (passives)

Passives come only from experience. Fishcoin cannot buy them, respec them, or shortcut them.

You start at level 1 with 0 Insight points. Each level-up grants 1 point. Levels 10, 20, 30, and 40 grant 1 extra point.

At level 40 that is 43 points. Finishing one tree costs 15. A dedicated player finishes two trees and starts a third. Nobody owns every passive. That is the point.

Respec is free, any time you are not in a match.

Node costs by depth: 1, 1, 1, 2, 2, 2, 3, 3.

Some deep nodes also require a mastery rank. That is the second experience gate.

### Alley tree

1. Extra Starting Kibble — +50 start kibble on Sunny and Alley. (1)
2. Soft Landings — the first leak of a match removes 10 fewer lives, once. (1)
3. Pip Practice — Pip gains +5% attack speed. (1)
4. Hot Start — Nibs burn lasts +1s. Requires Nibs mastery 2. (2)
5. Thick Ruff — Pudding freeze lasts +0.3s on mice. Requires Pudding mastery 2. (2)
6. Bigger Bones — Biscuit explosion radius +8. Requires Biscuit mastery 3. (2)
7. Alley Drill — all Alley cats gain +1 pierce. (3)
8. Veteran Tosser — you may own a second copy of one Alley tier-5. Requires any Alley cat at mastery 8. (3)

### Hunt tree

1. Perch Discount — Sable costs 50 less. (1)
2. Steady Aim — Sable cooldown −5%. (1)
3. Gutter Maps — water cats gain +10% range. (1)
4. Harpoon Drill — anti-rat bonus damage on Hunt cats +10%. Requires Sable mastery 3. (2)
5. Long Patrol — air cats move 10% faster. (2)
6. Deadeye Drill — Sable’s every-Nth shot counter is one shorter. Requires Sable mastery 5. (2)
7. Hunt Pack — Hunt cats gain +1 damage vs rats. (3)
8. Second Perch — a second copy of one Hunt tier-5 is allowed. Requires a Hunt cat at mastery 8. (3)

### Myth tree

1. Ink Study — Nim’s path C tier 1 costs 100 less. (1)
2. Warm Spark — burn dps from Myth cats +1. (1)
3. Hex Reach — hex spread radius +20%. (1)
4. Brew Loyalty — Bub’s brew lasts 20% longer. Requires Bub mastery 2. (2)
5. Thorn Pact — Myth cats gain +5% range. Requires any Myth mastery 3. (2)
6. Void Lesson — one chosen Myth cat treats Ink as a normal target. Requires that cat’s mastery 5. (2)
7. Myth Chorus — Magic damage +1. (3)
8. Second Star — a second copy of one Myth tier-5 is allowed. Requires a Myth cat at mastery 8. (3)

### Den tree

1. First Catch — Goldie produces +20 kibble per round. (1)
2. Wider Cafe — Miso radius +15. (1)
3. Honey Lesson — Honey slow lasts +2s. (1)
4. Interest — vault interest +2 percentage points. Requires Goldie mastery 4. (2)
5. Single Discount — the global discount floor moves from 60% to 55%. Requires Miso mastery 5. (2)
6. Sentry Oil — sentry lifetime +5s. Requires Sprocket mastery 2. (2)
7. Den Network — support auras also grant +5% attack speed. (3)
8. Market Day — start each match with one free tier-1 token. Requires Goldie or Miso mastery 8. (3)

### Hero tree

1. Early Bowl — hero place cost −100. (1)
2. Fast Growth — hero XP +8%. (1)
3. Level Head Start — the hero starts at level 2. (1)
4. Pin Cushion Drill — Mittens’ level-3 cooldown −5s. Requires 3 matches with Mittens. (2)
5. Hearth Drill — Duchess burn cap vs normal rats +5 dps. (2)
6. Hero Start 3 — the hero starts at level 3. Requires the previous head-start node. (2)
7. Ability Fuel — hero active cooldowns −10%. (3)
8. Beloved — the hero’s level-20 passive is 20% stronger (durations and flat numbers, never the Matriarch dps cap). Requires any hero used to clear a Night medal. (3)

### Clowder tree (general)

1. Keen Wallet — +25 start kibble on every mode except Bare Paw. (1)
2. Clean Sell — sell refund becomes 75% on modes that allow selling. (1)
3. Third Trick — unlocks trick slot 3. (1)
4. Pre-round Peek — the next round’s mouse list is always visible. On by default after this node; before it, only the next round’s icons show, not counts. (2)
5. Feat Focus — feat XP +10%. (2)
6. Reroll Saver — the first feat reroll of a match is free. (2)
7. Long Memory — mastery XP +10%. (3)
8. Keeper’s Bell — once per match, all cats gain +20% attack speed for 10s. This is the only “active” that lives in the passive tree, and it is small on purpose. (3)

Bare Paw turns every node off, including Pre-round Peek’s extra counts and Keeper’s Bell.

---

## 13. Mastery XP

Per cat type, across matches:

`masteryXP += damageDealtByThisType × 0.15 × modeMultiplier`

Minimum 20 if at least one cat of that type was placed.

| Rank | Cumulative XP | Unlocks |
| --- | --- | --- |
| 1 | 0 | the cat, tiers 1–2 |
| 2 | 400 | tier 3 |
| 3 | 900 | a new path feat card enters the pool |
| 4 | 1600 | — |
| 5 | 2800 | tier 4 |
| 6 | 4500 | — |
| 7 | 7000 | — |
| 8 | 11000 | tier 5 |
| 9 | 16000 | that cat’s feat pool is complete |
| 10 | 23000 | a non-stat mastery frame cosmetic, and later the right to build an Alpha |

Heroes do not use this track. Their meta growth is account level plus in-match levels. Hero skins are fishcoin.

---

## 14. Fishcoin and the shop

Fishcoin is the only meta currency. It is earned by playing. It buys visuals and tricks. It does not buy cats, heroes, passives, lives, or continues.

### Earn

| Source | Fishcoin |
| --- | --- |
| First Sunny / Alley / Night / Last Whisker / Bare Paw clear on a map | 50 / 80 / 110 / 150 / 200 |
| Repeat clear | 10 / 15 / 20 / 25 / 40 |
| Daily first match | 30 |
| Weekly challenge first clear | 80 |
| Each account level-up | 15 |
| Small achievements | 20 to 100, one time |

First Sunny clear plus reaching level 10 pays about `50 + 9×15 = 185` fishcoin. The cheapest cosmetic is 80. The cheapest trick is 250. The first shop purchase is a look. The first trick takes another clear or two. That is the intended lesson.

### Spend rules

- Direct prices. No random crates.
- Cosmetics resell for 50% of the price.
- Tricks resell for 40%.
- A visual changes no number: not range, not hitbox, not the gameplay pitch of a pop. Skin sounds are an extra layer under the base cue.
- Colorblind shapes, subtitles, and screen-shake toggles are settings, not products.

### Tricks

A trick is a permanent unlock. Equip up to 2, or 3 if the Clowder insight is owned. Each use has a round cooldown and a kibble cost. There is no ammo.

**Power ceiling:** one trick activation removes at most 5% of a Rat Matriarch’s max HP (1100 damage) and cannot skip a round. A test asserts this on every trick.

Tricks above 500 fishcoin also require an account level.

| Trick | Price | Level | Cooldown | Kibble | Effect |
| --- | --- | --- | --- | --- | --- |
| Tuna Strike | 250 | slot only | 15 rounds | 50 | 12 Bite in radius 60 |
| Night Lantern | 280 | slot only | 10 rounds | 40 | reveal all Shadow for 12s |
| Yarn Snare | 300 | slot only | 12 rounds | 40 | hold non-rat mice at a point for 6s. Rats at 80% speed for 3s. Matriarch immune |
| Hairball Volley | 350 | slot only | 16 rounds | 60 | the hero immediately fires their personal volley (defined per hero, about one extra level-3 cast) |
| Catnip Frenzy | 400 | slot only | 18 rounds | 80 | all your cats +50% attack speed for 8s |
| Fish Rain | 450 | 8 | 20 rounds | 0 | gain `400 + 10 × round` kibble |
| Ratwhistle | 600 | 10 | 16 rounds | 100 | all rats on screen take 100 Bite. This deletes a wounded Burrow and chips a Bristle |
| Nine-Life Pulse | 900 | 12 | once per match | 0 | restore 25 lives, up to the mode’s starting lives. On Last Whisker and Bare Paw the starting lives are 1, so this trick is refused there |

Bare Paw refuses every trick even if equipped.

Hero volleys for Hairball Volley:

- Mittens — 8 needles, 2 damage, pierce 3.
- Duchess — a 4s burn zone, 4 dps.
- Baron — one bomb, 10 Blast, radius 70.
- Pebble — 300 kibble. This is allowed because Fish Rain already exists and Pebble’s volley is smaller.

### Launch cosmetics (all mechanical stats identical)

| Item | Price |
| --- | --- |
| Red collar, Pip | 80 |
| Striped scarf, Nibs | 80 |
| Any “plain dye” cat recolor | 100 |
| Mittens winter coat | 600 |
| Duchess ember eyes | 700 |
| Projectile trail, yarn | 150 |
| Projectile trail, fishbones | 150 |
| Pop flourish, confetti (extra VFX only) | 200 |
| Alley banner, 6 designs | 120 each |
| Victory pose, 4 | 250 each |
| UI frame, wood / brass / night | 180 each |
| Mastery frames | not sold. Mastery 10 only |

Weekly cosmetic: one item at a 20% discount that week, then it joins the normal shop at full price four weeks later. Missing a week loses nothing unique.

### Daily and weekly play

- **Daily Alley:** one seeded map and modifier. First clear that day pays 30 extra fishcoin on top of the repeat-clear amount. The reward is only fishcoin.
- **Weekly puzzle:** a fixed loadout (named cats, a named hero, tricks banned). Clear pays 80 fishcoin and that week’s cosmetic if you want it for free by playing. The same cosmetic is in the shop the next month.
- No limited-time power. No battle pass.

---

## 15. Maps

| Map | Band | Length | Paths | Masks | Teaching |
| --- | --- | --- | --- | --- | --- |
| Sunny Gutter | beginner | 1200 | 1 loop | land, one puddle, a few perches | the whole first game |
| Market Lane | beginner+ | 1100 | 1, with a long straight and a tight corner | land, perches | Sable on the straight, Nibs in the corner |
| Rooftop Crossing | intermediate | 1000 | 2 paths that merge | land, many perches, little water | targeting and split attention |
| Fishmarket Maze | advanced | 1400 | 1 path that crosses itself | land, blockers that stop line of sight | lobs and full-track shots matter |
| Canal Night | advanced | 1300 | 2 | lots of water, night lighting | Marlow, Shadow mice show up earlier as a map rule |
| The Warren | expert | 700 | 3 short paths, one active at a time, the active path swaps every round on a published pattern | cramped land | short lanes, Dusk rats are a 5.5s problem |

Each map ships with the three modifiers (Alternate Warrens, Full Nets, Short Leash).

Canal Night’s map rule: the first Shadow mice arrive on round 18 instead of round 28. The pre-round hint is louder here.

The Warren’s active-path pattern is data, authored per round, not random.

---

## 16. Round authorship

Rounds are data, not code. Group syntax:

`count coat [shadow] [gnaw] [plated] @ spacing`

Example: `20 rust @0.45s ; 8 slate @0.40s`

Duration is the time from the first spawn to the last spawn, not the time to clear.

### Rounds 1–40 (Sunny’s whole medal, and everyone’s early game)

RBE is computed from the coats. These counts are the v1 script. The harness may nudge counts by ±10% if wallet tests fail. It may not add Iron before round 24, Shadow before round 28, or Ink on Sunny at all.

| R | Duration | Groups | Intent |
| --- | --- | --- | --- |
| 1 | 14s | 15 rust @0.9s | place Pip |
| 2 | 16s | 25 rust @0.6s | a second cat or an upgrade |
| 3 | 16s | 12 rust @0.5s ; 10 slate @0.5s | layered coats |
| 4 | 18s | 20 slate @0.5s | |
| 5 | 18s | 18 moss @0.55s | |
| 6 | 18s | 12 moss @0.4s ; 15 rust @0.3s | mixed speeds |
| 7 | 16s | 16 grain @0.45s | first real speed |
| 8 | 20s | 14 grain @0.4s ; 12 moss @0.4s | |
| 9 | 18s | 24 grain @0.35s | |
| 10 | 16s | 40 sugar @0.35s | speed check. Hint text once |
| 11 | 18s | 20 sugar @0.3s ; 15 grain @0.3s | |
| 12 | 20s | 15 moss @0.4s ; 10 soot @0.6s | Blast immunity arrives. Claw cats are fine |
| 13 | 20s | 12 soot @0.5s ; 12 frost @0.5s | freeze immunity arrives |
| 14 | 22s | 20 sugar @0.25s ; 8 soot @0.5s | |
| 15 | 20s | 10 frost @0.4s ; 10 soot @0.4s ; 20 grain @0.3s | |
| 16 | 22s | 25 sugar @0.25s | |
| 17 | 24s | 8 soot gnaw @0.7s ; 20 slate @0.3s | Gnaw tutorial. Hint: slow stops regrow |
| 18 | 24s | 10 frost gnaw @0.6s ; 15 sugar @0.3s | |
| 19 | 22s | 30 sugar @0.25s ; 10 moss @0.3s | |
| 20 | 20s | 15 soot @0.35s ; 15 frost @0.35s | milestone pack |
| 21 | 24s | 12 marble @0.5s | both immunities in one coat |
| 22 | 24s | 10 marble @0.45s ; 20 sugar @0.25s | |
| 23 | 26s | 8 iron @0.8s ; 15 grain @0.3s | Iron tutorial. Hint points at Nibs Hot Claws or Mittens if she is level 6 |
| 24 | 26s | 12 iron @0.6s | punish if ignored, survivable on Sunny (12 × 23 lives is lethal only if the whole pack leaks) |
| 25 | 24s | 10 prism @0.55s | |
| 26 | 28s | 8 prism @0.5s ; 8 iron @0.6s | |
| 27 | 28s | 12 marble gnaw @0.45s | |
| 28 | 26s | 15 sugar shadow @0.3s | Shadow tutorial. Pip B2 or Mittens level 4 |
| 29 | 28s | 10 prism @0.5s ; 12 sugar shadow @0.3s | |
| 30 | 24s | 20 prism @0.4s | |
| 31 | 30s | 8 iron shadow @0.7s | both answers at once |
| 32 | 30s | 6 porcelain @1.2s | multi-HP shells |
| 33 | 30s | 8 porcelain @1.0s ; 20 sugar @0.25s | |
| 34 | 32s | 6 porcelain gnaw @1.2s | |
| 35 | 30s | 10 porcelain @0.8s | |
| 36 | 34s | 8 porcelain shadow @1.0s ; 10 iron @0.5s | |
| 37 | 34s | 6 plated porcelain @1.3s | Plated tutorial |
| 38 | 36s | 12 porcelain @0.7s ; 15 prism @0.35s | |
| 39 | 40s | 8 plated porcelain @1.0s ; 10 prism shadow @0.4s ; 20 sugar @0.2s | the pressure round before the rat |
| 40 | 8s | 1 burrow | the first rat. On Sunny, body HP ×0.65 |

Ink is absent from this list on purpose. Sunny’s starter-to-mid cats are not required to field Magic. Ink first appears on Rooftop Crossing, round 26, after Nim or Duchess can be in the loadout.

### Milestone rounds 41–100

These are fully specified because they are the mode finals and the difficulty spikes. Rounds not listed are filled by the production sheet inside the RBE bands in the next section, using the same group syntax. The bands are the acceptance test.

| R | Duration | Groups |
| --- | --- | --- |
| 45 | 35s | 15 porcelain @0.6s ; 10 iron shadow @0.5s |
| 50 | 40s | 2 burrow @8s ; 12 plated porcelain @0.8s |
| 55 | 45s | 3 burrow @6s ; 20 prism gnaw @0.3s |
| 59 | 30s | 4 burrow @5s ; 10 plated porcelain shadow @0.7s |
| 60 | 10s | 1 bristle |
| 65 | 40s | 1 bristle @0s ; 6 burrow @4s |
| 75 | 50s | 2 bristle @12s ; 8 burrow @3s ; 15 plated porcelain @0.5s |
| 79 | 45s | 2 plated bristle @10s ; 10 porcelain gnaw @0.4s |
| 80 | 12s | 1 monarch |
| 85 | 40s | 1 monarch @0s ; 4 bristle @8s |
| 89 | 35s | 2 monarch @15s ; 8 plated burrow @3s |
| 90 | 20s | 3 dusk @4s ; 30 iron shadow gnaw @0.35s |
| 95 | 40s | 6 dusk @3s ; 2 bristle @10s |
| 99 | 45s | 1 monarch @0s ; 4 dusk @4s ; 4 plated bristle @8s |
| 100 | 15s | 1 matriarch |

From round 81, Porcelain in these groups is Super Porcelain.

### RBE bands the filler rounds must hit

| Round window | RBE of that round |
| --- | --- |
| 10 | 250–400 |
| 20 | 500–900 |
| 30 | 1500–2500 |
| 39 | 3000–5000 |
| 40 | 616 (546 on Sunny) |
| 50 | 4000–7000 |
| 60 | 3164 plus up to 1500 extra |
| 80 | 16656 plus up to 4000 extra |
| 90 | the listed send, about 3600 from the Dusk trio plus the iron pack |
| 100 | 58948 |

### Freeplay 101–140

- Each round spawns the round-100 set, plus `round − 100` extra groups chosen from: 1 plated bristle, 2 dusk, 4 plated burrow, 20 super porcelain.
- Round 120 adds a second Matriarch at the halfway point.
- Round 140 adds a third.
- Past 140 the same pattern continues, and pop income is already on the decay curve so this is a score attack, not a farm.

### Alternate Warrens delta

- Porcelain first appears on round 32 in the base list; Alternate moves the first porcelain group to round 28 and adds 4 porcelain to round 32.
- Burrow / Bristle / Monarch / Dusk / Matriarch arrive on 38 / 58 / 78 / 88 / 98.
- Add Gnaw to one group every 5 rounds.

---

## 17. First session script

Minute by minute, for the tutorial on Sunny Gutter. The tutorial can be replayed from the menu. It is the normal Sunny rules plus hint cards. Skipping hints is allowed after the first clear. Skipping the first match is not, until Sunny is cleared once or the player turns “I already know path defense” on in settings. That toggle still uses the real rules. It only hides cards.

1. Round 1 pauses before the start and asks for a Pip on the marked pad. Targeting is explained in one sentence: First hits the front of the line.
2. After round 3, a card shows a Slate mouse splitting into a Rust mouse.
3. After round 5, the player is asked to buy any tier-1 on Pip.
4. Before round 7, Mittens is offered if the wallet can afford her. If not, the game spots the difference once, as a tutorial grant, and never again.
5. Round 10’s speed is called out before it starts.
6. Round 12 explains Blast immunity and that Pip still works.
7. Round 17 explains Gnaw and that Pudding or Honey (if owned) stops it. If the player has neither, the card says Gnaw regrows only when the mouse is moving near full speed, and killing it quickly also works.
8. Round 23 explains Iron and highlights Nibs path B.
9. Round 28 explains Shadow and highlights Pip path B or Mittens.
10. Round 32 explains shells with more than 1 HP.
11. Round 40 shows the Burrow Rat’s health bar and children before the round starts.
12. On the win screen: fishcoin earned, account level, the unlock queue (at most the ceremony caps), and a button to the shop. The shop tutorial highlights a cosmetic. It does not auto-buy. If the player buys nothing, that is fine.

---

## 18. Screens and HUD

Screens:

- Title. Buttons: Play, Cats, Heroes, Insights, Shop, Almanac, Settings.
- Map select with medals per mode and modifier.
- Loadout: hero, trick slots, a note of which Insights are on. Bare Paw shows them struck through and off.
- Match.
- Results: lives left, leaks, kibble peak, feat cards picked, XP, fishcoin, queue ceremony.
- Shop tabs: Looks, Tricks. A wallet. A resell control.
- Almanac: every coat, every rat, every cat, every trick, with the real numbers from the data files. The almanac reads the same JSON the sim uses, so it cannot drift.

Match HUD:

- Lives, kibble, round number, mode name.
- Start / speed.
- Hero portrait and ability buttons, with cooldown rings.
- Trick buttons, with round-cooldown pips and the kibble cost on the button.
- Selected cat panel: sell, targeting, next upgrade on each open path, feat progress, footprint.
- Next-round preview strip.
- Pause menu: resume, settings, almanac, abandon.

Input for v1: mouse and keyboard. UI focus order is explicit so a controller port does not require a rewrite. Controller support itself is post-v1.

---

## 19. Feel, audio, and accessibility

- Cats read by silhouette: ears, tail, and the prop (spool, fishbone basket, frost bowl, rifle, spark, net, cafe sign).
- Attack animation is 4–8 frames. Placement is a single pose family in 3/4 view.
- Rats are 3× to 4× a Porcelain mouse. The Matriarch is larger than a Monarch and has a unique entrance sting.
- Pop pitch rises with coat tier. A rat death uses a different sting. A leak is a low thud.
- Screen shake has a three-step setting: off, low, full. Default low.
- Flash from Whiteout and abilities is capped and can be turned down.
- Text scale: 100 / 125 / 150.
- The colorblind coat shapes are always on.
- Pause is instant and freezes the sim tick.

---

## 20. Technical plan

### Stack

- Godot 4.3, GDScript.
- Simulation is a plain object with no scene-tree calls, so a headless test runner can execute matches.
- Content is JSON in `content/`. The almanac and the sim load the same files.
- Match RNG is a seeded counter. Seed is stored in the save and the replay.

### Suggested layout

```text
content/mice.json
content/rats.json
content/cats/*.json
content/heroes/*.json
content/rounds/sunny.json
content/rounds/bands.json
content/maps/*.json
content/insights.json
content/tricks.json
content/shop.json
content/levels.json
sim/match.gd
sim/projectile.gd
sim/status.gd
sim/economy.gd
sim/feats.gd
sim/replay.gd
presentation/ the scenes, HUD, animation
tools/balance_runner.gd
```

### Save

One profile JSON plus a checksum so a truncated write is detectable. This is a single-player game. The checksum is for corruption, not for punishing the player. Fields:

- account level, account XP, insight points, insight purchases
- fishcoin, owned shop ids
- per-cat mastery XP
- map medals
- settings
- daily and weekly seed timestamps
- unlock queue
- current match, if mid-match: full sim state, seed, action log

### Replay

An action is `{tick, type, payload}`. Types: place, upgrade, sell, target, hero ability, trick, feat pick, feat reroll, speed, start round. Given the seed and the action list, the sim reproduces the match. Bare Paw leaderboards, when they exist, accept a replay and re-sim it. v1 stores replays locally and does not ship the board.

### Adding a cat

Data-only if the cat uses existing components: projectile, aura, pulse, zone, income, beam, sentry.

Code only when a new verb appears (for example “dash along the path”). The verb is then a named component other cats can reuse.

### Balance harness (must exist before the first public build)

Headless checks:

- Pop overflow, pierce, immunities, and leak RBE match the tables in this plan for every coat and every rat.
- Matriarch ignores every control component.
- No trick exceeds 1100 damage on a full-HP Matriarch.
- Discounts never go below the floor, and they do not stack.
- Gnaw cannot regrow while slowed, and cannot regrow more than 3 times.
- A scripted Sunny build (Pip, Nibs path B, Mittens, one Pudding) clears rounds 1–40 with lives remaining.
- Goldie 2-0-0 payback is between 7 and 10 rounds.
- Feat offers for a fixed seed are stable across two runs.
- A first Sunny clear ends between account levels 9 and 11.

---

## 21. Build order

Each phase is playable on its own. Do not start a phase by adding content the sim cannot represent yet.

1. **Greybox sim.** Path follower, Rust mice, one Pip, lives, 30 Hz tick.
2. **Pop law.** All damage types, children, overflow pierce, immunities. Unit tests before art.
3. **Sunny 1–40, four cats.** Pip, Nibs, Pudding, Biscuit. Real kibble. Real crosspaths through tier 2 only.
4. **The Burrow Rat** and a results screen. Sunny medal.
5. **Sable, Nim, Goldie, Miso.** Tiers 3–5 implemented. Mastery XP saved, but locks can stay off until phase 7.
6. **Mittens** through level 20, then Duchess, Baron, Pebble.
7. **Mastery locks** turned on for new profiles. Existing dev profiles get a one-time mastery grant so test saves do not soft-lock.
8. **Feats** between rounds, including the seeded offer and the reroll.
9. **Account level, unlock queue, Insight trees.**
10. **Fishcoin, shop, tricks, cosmetics.**
11. **The other five maps, modes, modifiers.**
12. **Tutorial cards, almanac, accessibility, audio.**
13. **Harness green** on the list in section 20. Then playtest. Then the v1.1 cats.

Public v1 content: 8 cats, 4 heroes, 6 maps, 5 modes, 8 tricks, the launch cosmetics, rounds through 100 plus freeplay.

---

## 22. Test gates before calling v1 done

- A new player can clear Sunny with the tutorial and without opening the shop.
- That same player can clear Sunny Bare Paw with no Insights and no tricks, using only tiers the first hours of mastery allow. If Bare Paw requires a tier-5, the round or the tier-4 power is wrong. Adjust content, not the rule.
- Alley is clearable with tier 4s and no tricks.
- Night wants one tier-5 or a sharp synergy, and is clearable without tricks.
- Last Whisker and Bare Paw are clearable without tricks. They are allowed to demand a tier-5 and a hero.
- No shop item changes a Sunny clear from “possible” to “required”.
- Two cats cannot occupy the same footprint. Water cats cannot stand on land. Sable can stand on perch or land.
- Selling never increases total kibble spent-and-refunded above the 70% rule (no refund loop).
- The Matriarch on The Warren (700 units, about 97 seconds on the map) is killable by a Night-legal defense in a scripted test. If she is not, lower her HP in data. Do not give the player a trick that exists only to delete her.

---

## 23. Explicitly not in v1

- Real-money purchases, ads, premium currency, loot boxes, paid continues.
- Co-op.
- Alpha cats.
- Boss events, races, user-made maps.
- Mobile port and controller-first UI.
- A second language.
- Mid-round feat pauses.
- Random fishcoin rewards.

Post-v1, in order: v1.1 cats and heroes, v1.2 cats, then a weekly boss rat called the **Grey Muster** (one extra rat with a published mechanic, fishcoin and a cosmetic as the reward), then Alpha cats, then co-op.

---

## 24. Key decisions

1. **Two currencies with hard jobs.** Kibble is the match. Fishcoin is looks and tricks. Passives are XP. Mixing these was the main way a “free” shop would have become the real progression.
2. **Heroes and cats unlock by playing, not by shopping.** The shop stays optional for winning.
3. **Bare Paw exists and bans the shop’s power.** It is the balance target, not a side mode.
4. **Feats are chosen between rounds** and are seeded. They add attachment to a placed cat without becoming a second upgrade tree or a reload exploit.
5. **The Matriarch’s immunities live in one component.** Individual cats do not invent exceptions.
6. **Super Porcelain starts at round 81** so late rounds are a damage check, with a shell bounty so the wallet does not fall off a cliff.
7. **The first match teaches eight cats’ worth of rules with three units**, and the unlock queue stops level 10 from spilling the whole roster onto the results screen.
8. **Godot 4, data-driven sim, headless harness.** The round list and the prices will change. The pop law should not.

## Open questions for you

Defaults are already written into the plan. Answer only if you want a different one.

1. Engine and camera: Godot 4, 2D. If you want Unity, 3D, or a browser build first, say so before phase 1.
2. Match length: Sunny ends at 40, Alley at 60, Night at 80, Last Whisker and Bare Paw at 100. If you want every mode to run all 100 rounds, the economy and the first-session script need a rewrite.
3. In-match feats: on, between rounds. If you only wanted meta XP for unlocking upgrades, feats can be cut and mastery XP stays.
4. Name: Clowder: Alley Siege.
