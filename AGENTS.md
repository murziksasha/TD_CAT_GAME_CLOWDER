# AGENTS.md — Clowder: Alley Siege

Rules for anyone changing this repo. The design canon is fixed. The sim stays authoritative. Art lives in presentation.

## 1. What this game is

**Clowder: Alley Siege** (short name **Clowder**) is a free single-player path tower defense. Cats hold a track. Mice pop into smaller mice. Rats are the large late-wave enemies. No ads, no premium currency, no loot boxes, no real-money shop.

Engine: Godot 4, GDScript. Fixed sim tick is 30 Hz. Content is JSON in `content/`. The balance runner can play a match without opening a window.

Run the game: `npm start` or `run_game.bat`. Editor: `npm run editor`. Sim checks: `npm test` and `npm run test:sunny`.

## 2. Terminology

Use these words in code, JSON, and UI.

| Idea | Clowder name |
| --- | --- |
| Tower | **Cat** |
| Commander | **Hero cat** (one per match) |
| Small enemy | **Mouse** and its **coat** |
| Large enemy | **Rat** |
| In-match money | **Kibble** |
| Meta money | **Fishcoin** |
| Passive tree | **Insights** |
| Shop active | **Trick** |
| In-match cat choice | **Feat** |
| Meta unlock XP | **Mastery** |

Launch cats: Pip, Nibs, Pudding, Biscuit, Sable, Nim, Goldie, Miso.
Launch heroes: Mittens, Duchess, Baron Salt, Sister Pebble.
Mouse coats: Rust, Slate, Moss, Grain, Sugar, Soot, Frost, Ink, Iron, Marble, Prism, Porcelain.
Rats: Burrow, Bristle, Monarch, Dusk, Rat Matriarch.

Do not put Bloons, MOAB, or other borrowed proper nouns in the game.

## 3. Rules that code must not drift

- A cat spends on at most two upgrade paths. Tier 3 or higher on one path caps the other at tier 2. One tier-5 per path per cat type on the map.
- Damage types: Claw, Bite, Blast, Magic, Acid, Void, True. Claw stops on Iron. Blast stops on Soot. Magic stops on Ink. Frost coats ignore freeze and chill.
- The Rat Matriarch ignores stun, knockback, freeze, slow, and instant-kill. That immunity is one component, not a special case inside each cat.
- Pop overflow applies to the first child in the same hit and does not cost extra pierce.
- Kibble pays for HP removed. Leaked HP pays nothing. Lives lost equals remaining RBE.
- Fishcoin buys looks and tricks. It does not buy cats, heroes, passives, lives, or continues.
- Bare Paw turns off Insights, tricks, continues, and selling.
- Feat cards open between rounds. The offer is seeded. Reloading must not reroll it.
- Prices, coats, rounds, and upgrades come from `content/`. Do not hardcode a second copy of those numbers in the UI.

## 4. Where things live

| Path | Role |
| --- | --- |
| `sim/` | Headless match. No textures, no scenes, no `get_node`. |
| `content/` | JSON the sim and the almanac both read. |
| `presentation/` | Godot scene, HUD, and drawing. |
| `presentation/art/` | PNG sprites and tiles. |
| `tools/` | Balance runner and `extract_art.py`. |

If a change only affects how the match looks, stay in `presentation/`. If a change affects who wins, edit `sim/` and `content/`, then run `npm test`.

## 5. Art direction

Style anchor: the cat sprites in `presentation/art/cats/`. Cozy painterly storybook, chunky silhouettes, warm amber and terracotta, teal shadow, soft even light. New cats are edited from that set, not regenerated from a fresh prompt.

| Folder | Files |
| --- | --- |
| `presentation/art/cats/` | `pip`, `nibs`, `pudding`, `biscuit`, `sable`, `nim`, `goldie`, `miso`, `mittens` |
| `presentation/art/mice/` | one PNG per coat id (`rust` … `porcelain`) |
| `presentation/art/rats/` | `burrow`, `bristle`, `monarch`, `dusk`, `matriarch` |
| `presentation/art/props/` | `stall`, `lantern`, `crates`, `puddle` |
| `presentation/art/tiles/` | `grass.png`, `cobble.png` |

`presentation/main.gd` loads those paths. A missing file falls back to a flat shape, so a bad sprite does not stop the match.

Drawing rules:

- Sprites stay transparent. No baked ground, no baked health numbers, no words.
- Health bars, feat stars, level text, kibble, and lives stay drawn in code so they stay accurate.
- Shadow mice are the same sprite at lower alpha, plus the star mark.
- Plated is a code rim, not a second painting.
- The Sunny Gutter path is `(40,100) → (640,100) → (640,400) → (340,400)`. Props and houses stay off that ribbon.
- HUD chrome is the wood theme in `_apply_wood_theme()`. Do not put a second UI skin on one screen.

Known crop limits, left on purpose until a repaint: Dusk and the Monarch share a few edge pixels, the fish stall has a tiny unreadable sign, and the mice/rats are a rounder render than the cats. The cat set is the one to match next time.

`tools/extract_art.py` keys the green lineup sheets and writes this folder. Sheets are not committed as the runtime art.

## 6. How to change the game

- A new coat or rat is a JSON entry plus a sprite whose file name is the id.
- A new cat that only uses projectiles, auras, pulses, zones, income, beams, or sentries is data. A new verb (a dash along the path, for example) is a named sim component, then a sprite.
- Do not suggest a different engine unless the request is explicitly about the stack.
- Keep the sim deterministic: seeded RNG, no wall-clock in `sim/`.
- After a sim change, run `npm test`. After a presentation change, launch the game and place Pip, start a round, and confirm mice walk the cobbles and the dock shows cat icons.
