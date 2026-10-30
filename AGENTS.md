# AGENTS.md — Clowder: Alley Siege

Rules for anyone changing this repo. The design canon is fixed. The sim stays authoritative. Art lives in presentation. All detailed specifications reside in `SPEC/`.

---

## 1. What this game is

**Clowder: Alley Siege** (short name **Clowder**) is a free single-player path tower defense. Cats hold a track. Mice pop into smaller mice. Rats are the large late-wave enemies. No ads, no premium currency, no loot boxes, no real-money shop.

- **Engine**: Godot 4 (4.3+), GDScript.
- **Simulation**: Fixed sim tick is 30 Hz. Headless, deterministic, zero scene-tree calls.
- **Content**: Data-driven JSON in `content/`. The sim and almanac read the identical JSON.
- **Commands**:
  - Run the game: `npm start` or `run_game.bat`
  - Godot Editor: `npm run editor`
  - Balance checks: `npm test`
  - Sunny acceptance script: `npm run test:sunny`

---

## 2. Terminology

Use these words in code, JSON, documentation, and UI. Never use borrowed terms from other tower defense titles.

| General TD Idea | Clowder Canonical Name |
| :--- | :--- |
| Tower | **Cat** |
| Commander | **Hero cat** (one per match, levels 1–20) |
| Small enemy | **Mouse** and its **coat** |
| Large enemy / Boss | **Rat** |
| In-match money | **Kibble** |
| Meta money | **Fishcoin** |
| Passive tree | **Insights** |
| Shop active | **Trick** |
| In-match cat choice | **Feat** |
| Meta unlock XP | **Mastery** |

- **Launch Cats**: Pip, Nibs, Pudding, Biscuit, Sable, Nim, Goldie, Miso.
- **Launch Heroes**: Mittens, Duchess, Baron Salt, Sister Pebble.
- **Mouse Coats (12)**: Rust, Slate, Moss, Grain, Sugar, Soot, Frost, Ink, Iron, Marble, Prism, Porcelain.
- **Rats (5)**: Burrow, Bristle, Monarch, Dusk, Rat Matriarch.

Do not put Bloons, MOAB, Monkey, or other borrowed proper nouns in the game.

---

## 3. Rules that code must not drift

- **Crosspath Law**: A cat spends on at most two upgrade paths. Tier 3 or higher on one path permanently caps the other at Tier 2. One Tier-5 per path per cat type on the map.
- **Damage Types & Immunities**:
  - Claw (stopped by Iron)
  - Blast (stopped by Soot)
  - Magic (stopped by Ink)
  - Bite, Acid, Void, True (stop on nothing by coat)
  - Frost coats ignore freeze and chill.
- **Rat Matriarch Control Immunity**: Ignores stun, knockback, freeze, slow, and instant-kill. That immunity is **one central component** in `sim/status.gd`, never a special case scattered inside each cat.
- **Pop Overflow**: Damage overflow applies to the **first child** in the same hit and **does not consume extra pierce**. It recurses. Other children require separate pierce.
- **Kibble & Leaks**: Kibble pays for HP actually removed. Leaked HP pays nothing. Lives lost equals remaining RBE of the escaping unit.
- **Fishcoin Boundary**: Fishcoin buys looks and tricks. It does not buy cats, heroes, passives, lives, or continues.
- **Bare Paw Truth**: Bare Paw mode turns off Insights, tricks, continues, and selling. Every map must be beatable on Bare Paw using naturally available mastery tiers.
- **Feat Determinism**: Feat cards open **between rounds only**. The offer is seeded (`matchSeed + catInstanceId + featRank + pathBits`). Reloading must not reroll it.
- **Content Authority**: Prices, coats, rounds, and upgrades come strictly from `content/*.json`. Do not hardcode numbers into GDScript or UI scenes.

---

## 4. Where things live

| Directory / File | Role |
| :--- | :--- |
| `SPEC/` | Canonical design and technical specifications (`SPEC/README.md` index, 11 domain specs, master plan). |
| `sim/` | Headless match simulation. Pure GDScript (`RefCounted`). No textures, no scenes, no `get_node()`. |
| `content/` | Authoritative JSON files that both `sim/` and the presentation almanac read. |
| `presentation/` | Godot 2D scene (`main.tscn`), HUD, animations, particle effects, and drawing. |
| `presentation/art/` | PNG sprites, tiles, props, and Godot `.import` files. |
| `tools/` | Automated test runner (`balance_runner.py`), sunny acceptance test, and `extract_art.py`. |

If a change only affects how the match looks, stay in `presentation/`. If a change affects mechanics, stats, or who wins, edit `sim/` and `content/`, then run `npm test`.

---

## 5. Art direction

Style anchor: the cat sprites in `presentation/art/cats/`. Cozy painterly storybook, chunky silhouettes, warm amber and terracotta, teal shadow, soft even light. New cats are edited from that set, not regenerated from a fresh prompt.

| Folder | Files |
| :--- | :--- |
| `presentation/art/cats/` | `pip`, `nibs`, `pudding`, `biscuit`, `sable`, `nim`, `goldie`, `miso`, `mittens` |
| `presentation/art/mice/` | one PNG per coat id (`rust` … `porcelain`) |
| `presentation/art/rats/` | `burrow`, `bristle`, `monarch`, `dusk`, `matriarch` |
| `presentation/art/props/` | `stall`, `lantern`, `crates`, `puddle` |
| `presentation/art/tiles/` | `grass.png`, `cobble.png` |

`presentation/main.gd` loads those paths. A missing file falls back to a flat geometric shape, so a bad sprite never crashes the match.

### Drawing Rules:
- Sprites stay transparent. No baked ground, no baked health numbers, no words.
- Health bars, feat stars, level text, kibble, and lives stay drawn in code so they remain accurate.
- Shadow mice are the same sprite rendered at lower alpha (50%), plus an overhead star mark.
- Plated is a code-drawn metallic rim, not a second painting.
- The Sunny Gutter path is `(40,100) → (640,100) → (640,400) → (340,400)`. Props and houses must stay completely off that ribbon.
- HUD chrome uses the wood theme in `_apply_wood_theme()`. Do not put a second UI skin on one screen.

`tools/extract_art.py` keys the green lineup sheets and writes this folder. Source lineup sheets are not committed as runtime art.

---

## 6. Specifications and Canon Reference (`SPEC/`)

All canonical game design parameters, formulas, and balance rules are preserved in the `SPEC/` directory:

- **[SPEC/01_GAME_OVERVIEW.md](SPEC/01_GAME_OVERVIEW.md)**: Modes (Sunny, Alley, Night, Last Whisker, Bare Paw), modifiers, win/loss rules.
- **[SPEC/02_COMBAT_AND_SIMULATION.md](SPEC/02_COMBAT_AND_SIMULATION.md)**: 30 Hz tick, polyline paths, damage types, status effects, pop overflow recursion, Matriarch immunity component.
- **[SPEC/03_MICE_AND_RATS.md](SPEC/03_MICE_AND_RATS.md)**: 12 coats, Super Porcelain (R81+), 5 rats, full RBE tables.
- **[SPEC/04_CATS_AND_TOWERS.md](SPEC/04_CATS_AND_TOWERS.md)**: Crosspath law, mastery locks, complete 15-upgrade tables for all 8 launch cats, future cats, Alpha cats.
- **[SPEC/05_HEROES.md](SPEC/05_HEROES.md)**: Hero XP curve (levels 1–20), full kits for Mittens, Duchess, Baron Salt, Sister Pebble.
- **[SPEC/06_ECONOMY_AND_PROGRESSION.md](SPEC/06_ECONOMY_AND_PROGRESSION.md)**: Kibble income and decay, selling 70%, discount floor (60%), Account XP curve, Unlock Queue, Mastery XP.
- **[SPEC/07_FEATS_AND_INSIGHTS.md](SPEC/07_FEATS_AND_INSIGHTS.md)**: In-match Feat XP thresholds, universal and path feat cards, 6 Insight trees.
- **[SPEC/08_SHOP_TRICKS_AND_COSMETICS.md](SPEC/08_SHOP_TRICKS_AND_COSMETICS.md)**: Fishcoin earnings, Trick ceiling (<= 1100 on Matriarch), 8 tricks, cosmetics.
- **[SPEC/09_MAPS_AND_ROUNDS.md](SPEC/09_MAPS_AND_ROUNDS.md)**: 6 maps, round syntax, authored waves 1–40, milestone waves 41–100, RBE acceptance bands, freeplay 101–140.
- **[SPEC/10_UI_UX_AND_AUDIO.md](SPEC/10_UI_UX_AND_AUDIO.md)**: Screens, match HUD, hotkeys, colorblind shapes, pop pitch escalation, audio direction.
- **[SPEC/11_TECHNICAL_ARCHITECTURE.md](SPEC/11_TECHNICAL_ARCHITECTURE.md)**: Godot 4 architecture, save profile schema, deterministic replay format, 9 balance gates, 13-phase build order.
- **[SPEC/MASTER_DESIGN_PLAN.md](SPEC/MASTER_DESIGN_PLAN.md)**: Full canonical design plan document.

---

## 7. How to change the game & Agent Guidelines

- **New Coat or Rat**: A JSON entry in `content/mice.json` or `content/rats.json` plus a sprite whose filename matches the ID.
- **New Cat**: Data-only if the cat uses existing components (projectiles, auras, pulses, zones, income, beams, sentries). A new verb (e.g. "dash along the path") requires a named sim component in `sim/`, then a sprite.
- **Engine Stack**: Godot 4.3+, GDScript. Do not suggest a different engine unless explicitly requested.
- **Deterministic Sim**: Seeded RNG; no wall-clock (`OS` or `Time`) calls inside `sim/`.
- **Git Hygiene**: Best practices configured in `.gitignore`. Cache files (`.godot/`, `__pycache__/`, logs, binaries) must never be committed. Asset `.import` files MUST be committed.
- **Verification Routine**:
  1. After any sim, content, or balance change: run `npm test` and `npm run test:sunny`.
  2. Ensure all 9 balance gates pass cleanly.
  3. After a presentation change: launch the game (`npm start`), place Pip, start a round, and confirm mice walk the cobbles, the dock displays cat icons, and HUD interactions function properly.
