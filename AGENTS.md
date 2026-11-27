# AGENTS.md — Clowder: Alley Siege

Rules for anyone changing this repo. The sim decides the match. Art lives in presentation. Design detail lives in `SPEC/`. This file is injected on every agent turn, so it stays short and it stays true to the tree.

---

## 1. Token safety

Spend context on the files the task touches. Do not tour the repo to get oriented.

- Search, then read a slice. Grep a tight pattern and read that function. `presentation/main.gd` and `sim/match.gd` are large. Read a line range. `SPEC/MASTER_DESIGN_PLAN.md` duplicates the numbered specs. Leave it closed.
- Open one spec. The index is `SPEC/README.md`. Open the single numbered file the task needs. Leave the rest closed.
- Leave binaries and caches unread: `presentation/art/**/*.png`, `*.import`, `*.uid`, `.godot/`, `__pycache__/`. For art, open the one sprite the task names.
- Keep the reply short. Do not paste this file, a spec, a JSON catalogue, or a test log. On a failure, quote the failing assertion and the file that owns it.
- One task, one layer. A look change stays in `presentation/`. A rules change stays in `sim/` and `content/`. Skip subagents when the change fits in one file. Skip a full art regen when one sprite is enough.
- When a doc and the tree disagree, follow the tree. `SPEC/11` still says 8 cats, 9 gates, and an old layout. `SPEC/13` is an unratified proposal. `content/`, `sim/`, and `tools/balance_runner.py` are what the game does. Do not reshape the repo to match a stale paragraph, and do not implement SPEC 13 because the file exists.
- Re-read a file in this turn only when an edit may have changed it. Do not restate the roster, the laws, or the commands unless the user asked.

---

## 2. What this game is

**Clowder: Alley Siege** (short name **Clowder**) is a free single-player path tower defense. Cats hold a track. Mice pop into smaller mice. Rats are the large late-wave enemies. No ads, no premium currency, no loot boxes, no real-money shop.

- **Engine**: Godot 4.3+ (`project.godot` features `4.3`), GDScript. Physics tick and sim tick are 30 Hz.
- **Simulation**: Headless and deterministic. `sim/` is `RefCounted` script logic. It makes no scene-tree calls.
- **Content**: JSON under `content/`. The sim, the almanac, and the balance harness read that same JSON.
- **Play**: `npm start`, `npm run game`, or `run_game.bat`. Editor: `npm run editor`.
- **Checks**:
  - `npm test` runs `tools/balance_runner.py`. Exit 0 is the pass. The banner says 14 gates, then the same process runs the Bub headless check.
  - `npm run test:sunny` runs `tools/sunny_scripted_match.py`.
  - `npm run test:expansion` runs the Testing Lab and Alley Crawl headless scripts through Godot.

---

## 3. Terminology

Use these words in code, JSON, docs, and UI.

| General TD idea | Clowder name |
| :--- | :--- |
| Tower | **Cat** |
| Commander | **Hero cat** (one per match, levels 1–20) |
| Small enemy | **Mouse** and its **coat** |
| Large enemy | **Rat** |
| In-match money | **Kibble** |
| Meta money for tricks and looks | **Fishcoin** |
| Mythic-look money | **Golden bones** (`content/prestige_shop.json`) |
| Passive tree | **Insights** |
| Shop active | **Trick** |
| In-match cat choice | **Feat** |
| Meta unlock XP | **Mastery** |

- **Launch cats**: Pip, Nibs, Pudding, Biscuit, Sable, Nim, Goldie, Miso.
- **Also in the playable roster** (`content/cats/index.json`): Marlow (Harbor, water, Bite) and Bub (Myth, Acid, brew).
- **Heroes** (`content/heroes/`): Mittens (`mittens`, starter), Duchess (`duchess`), Baron Salt (`baron`), Sister Pebble (`pebble`).
- **Mouse coats (12)**: Rust, Slate, Moss, Grain, Sugar, Soot, Frost, Ink, Iron, Marble, Prism, Porcelain.
- **Rats (5)**: Burrow, Bristle, Monarch, Dusk, Rat Matriarch.
- **Locales**: `content/locales/en.json` and `content/locales/uk.json`. Player-facing strings stay in parity. The balance harness checks that.

Do not put Bloons, MOAB, Monkey, or other borrowed proper nouns in the game.

---

## 4. Laws that must not drift

- **Crosspath law**: A cat spends on at most two upgrade paths. Tier 3 or higher on one path permanently caps the other at Tier 2. One Tier-5 per path per cat type on the map. Enforced in `sim/tower.gd`.
- **Damage and coats**: Claw stops on Iron. Blast stops on Soot. Magic stops on Ink. Bite, Acid, Void, and True stop on nothing by coat. Frost coats ignore freeze and chill.
- **Rat Matriarch control immunity**: Ignores stun, knockback, freeze, slow, and instant-kill. That immunity is one component, `sim/status.gd` (`is_matriarch`). Do not reimplement it inside each cat.
- **Pop overflow**: Overflow hits the first child in the same hit and does not consume extra pierce. It recurses. Other children need their own pierce.
- **Kibble and leaks**: Kibble pays for HP actually removed. Leaked HP pays nothing. Lives lost equals the remaining RBE of the escaping unit.
- **Money boundary**: Fishcoin buys looks and tricks. Golden bones buy mythic looks in the prestige shop. Neither buys cats, heroes, Insights, lives, or continues. Add no third currency.
- **Bare Paw**: Turns off Insights, tricks, continues, and selling. Every standard map must stay beatable on Bare Paw with mastery tiers earned by natural play.
- **Feat determinism**: Feat cards open between rounds only. The offer seed is `matchSeed + catInstanceId + featRank + pathBits`. A reload must not reroll it.
- **Content authority**: Prices, coats, rounds, upgrades, and map points come from `content/`. Do not hardcode those numbers in GDScript or scenes.
- **Testing Lab**: Unlimited kibble, pause, and scripted spawns stay inside `sim/testing_lab.gd` and its tests. A normal match never starts with those cheats on.
- **Alley Crawl**: Rules live in `sim/alley_crawl.gd`, `sim/alley_crawl_session.gd`, and `content/grand_expansion/alley_crawl.json`. A crawl result is not a standard-map medal and does not relax Bare Paw.
- **Co-op and network**: `network/network_manager.gd` and `presentation/coop_modal.gd` exist. They are not a license to change the single-player rules. SPEC 13 lockstep is still a proposal.

---

## 5. Where the project lives

| Path | Role |
| :--- | :--- |
| `SPEC/01`–`SPEC/12`, `SPEC/README.md` | Design canon. Open one file. |
| `SPEC/13_GRAND_EXPANSION_SYSTEMS.md`, `SPEC/GRAND_EXPANSION_IMPLEMENTATION_PLAN.md` | Proposal only. |
| `content/cats/*.json`, `content/cats/index.json` | Cat stats and roster order. |
| `content/heroes/*.json` | Hero kits. |
| `content/maps/<id>.json` | One file per map. Count is the files on disk, not the 100-map plan in SPEC 12. |
| `content/rounds/` | `sunny.json`, `campaign.json`, `bands.json`. |
| `content/mice.json`, `rats.json`, `tricks.json`, `shop.json`, `prestige_shop.json`, `insights.json`, `levels.json` | Shared catalogues. |
| `content/locales/` | `en.json`, `uk.json`. |
| `content/grand_expansion/alley_crawl.json` | Alley Crawl config. |
| `sim/` | `match`, `tower`, `unit`, `projectile`, `status`, `economy`, `feats`, `hero`, `constants`, `replay`, `save_manager`, `leaderboard_manager`, `testing_lab`, `alley_crawl`, `alley_crawl_session`. Class names use the `Sim` prefix. |
| `presentation/main.gd`, `main.tscn` | Match, HUD, art loading, wood theme. |
| `presentation/*_modal.gd`, `title_menu.gd` | Meta screens. |
| `presentation/world_draw.gd`, `actor_draw.gd`, `vfx.gd`, `audio.gd`, `localization.gd` | Draw, FX, audio, strings. |
| `tools/balance_runner.py` | `npm test`. |
| `tools/sunny_scripted_match.py` | `npm run test:sunny`. |
| `tools/run_expansion_tests.js` | `npm run test:expansion`. |
| `tools/test_*.gd` | Headless Godot checks. Add a check beside the behavior it locks. |

The sim may append plain dictionaries to `presentation_log`. It never reads that log, never calls `Time` or `OS`, and never touches the scene tree.

---

## 6. Art

Style anchor: `presentation/art/cats/`. Cozy painterly storybook, chunky silhouettes, warm amber and terracotta, teal shadow, soft even light. A new cat is edited from that set.

`presentation/main.gd` `_load_art()` loads by id:

- Cats: ids from `content/cats/index.json`, plus heroes `mittens`, `duchess`, `baron`, `pebble`. Sheet `<id>_sheet.png`, else `<id>.png`.
- Mice: `<coat>_walk.png`, else `<coat>.png`, for the 12 coats.
- Rats: `<id>_walk.png`, else `<id>.png`, for `burrow`, `bristle`, `monarch`, `dusk`, `matriarch`.
- Props: `stall`, `lantern`, `crates`, `puddle`. Tiles: `grass.png`, `cobble.png`.

A missing file falls back to a flat shape. A bad sprite must not crash the match.

- Sprites stay transparent. No baked ground, numbers, or words.
- Sheets are 128px cells: four idle frames, then six attack frames, 3/4 view facing right. Presentation flips toward the target.
- Health bars, feat stars, level text, kibble, and lives stay code-drawn.
- Shadow mice reuse the sprite at 50% alpha plus an overhead star. Plated is a code-drawn rim.
- Sunny Gutter points live in `content/maps/sunny_gutter.json`: `(40,100) → (640,100) → (640,400) → (340,400)`. Props stay off that ribbon.
- HUD chrome uses `_apply_wood_theme()` in `presentation/main.gd`. One wood skin per screen.
- Upgrade read is an overlay ornament at tiers 1, 3, and 5. Do not paint fifteen bodies per cat.
- Commit `*.import`. Never commit `.godot/`, `__pycache__/`, logs, export binaries, or `export_credentials.cfg`. `*.uid` is gitignored.

---

## 7. How to change it

- **New coat or rat**: an entry in `content/mice.json` or `content/rats.json`, plus a sprite whose filename is the id. Keep locale parity.
- **New cat**: a JSON file in `content/cats/`, an id appended in `content/cats/index.json`, and a sprite stem that matches the id. Data-only when the cat uses projectiles, auras, pulses, zones, income, beams, or sentries. A new verb needs a named component in `sim/` first, then the sprite. Follow with `npm test`.
- **New map**: one `content/maps/<id>.json`. Path points, masks, and obstacles live in that file. Wire it through the existing map load. Do not invent a second geometry format.
- **Player-facing copy**: edit `content/locales/en.json` and `content/locales/uk.json` together.
- **Determinism**: seeded RNG only inside `sim/`. No wall-clock calls there.
- **Engine**: Godot 4.3+ and GDScript. Do not propose another engine unless the user asks.

After the edit, run the check that covers it:

1. Any change under `sim/`, `content/`, maps, locales, or balance: `npm test`.
2. Sunny rounds or the Sunny Gutter ribbon: also `npm run test:sunny`.
3. Testing Lab or Alley Crawl: also `npm run test:expansion`.
4. A presentation change: `npm start`, place Pip, start a round. Mice walk the cobbles, the dock shows cat icons, the HUD responds, and a touched upgrade still shows its tier ornament.

Fix a red check before calling the work done. Say so if a check could not be run.
