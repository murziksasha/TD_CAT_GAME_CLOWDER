# Clowder: Alley Siege — Design & Technical Specifications

Welcome to the canonical design and technical specifications for **Clowder: Alley Siege** (short name **Clowder**).

These specifications govern all simulation logic, data authorship in `content/`, presentation rendering, balance runner assertions, and gameplay architecture. Any code or data change must conform strictly to these specifications.

---

## Specification Index

1. **[01. Game Overview & Modes](01_GAME_OVERVIEW.md)**
   - Fantasy, pillars, glossary, win/loss rules, match modes (Sunny, Alley, Night, Last Whisker, Bare Paw), map modifiers, and round flow.
2. **[02. Combat & Simulation](02_COMBAT_AND_SIMULATION.md)**
   - 30 Hz fixed sim tick, spatial metrics, placement masks, damage types, status effects, pop overflow resolution, enemy properties, and Rat Matriarch immunity law.
3. **[03. Mice & Rats](03_MICE_AND_RATS.md)**
   - All 12 mouse coats (Rust through Porcelain), Super Porcelain mechanics (round 81+), and all 5 rat types (Burrow, Bristle, Monarch, Dusk, Rat Matriarch) with full RBE breakdowns.
4. **[04. Cats (Towers)](04_CATS_AND_TOWERS.md)**
   - Crosspath law (max 2 paths, 3+ caps other at 2, single T5 per path per type), targeting, complete 15-upgrade tables for all 8 launch cats (Pip, Nibs, Pudding, Biscuit, Sable, Nim, Goldie, Miso), future cats, and Alpha cats.
5. **[05. Heroes](05_HEROES.md)**
   - Hero rules, XP progression curve (levels 1–20), full ability kits and passives for Mittens, Duchess, Baron Salt, Sister Pebble, and future heroes (Obsidian, Velvet).
6. **[06. Economy & Progression](06_ECONOMY_AND_PROGRESSION.md)**
   - Kibble formula (sources, decay curves, sinks, selling rules, discount floor), Account XP and level curve (levels 1–40), unlock queue ceremony rules, and cat Mastery XP (ranks 1–10).
7. **[07. Feats & Insights](07_FEATS_AND_INSIGHTS.md)**
   - In-match Feat XP thresholds (100, 350, 900), seeded drafting, universal & path feat cards; Insights passive trees (Alley, Hunt, Myth, Den, Hero, Clowder), depth costs, and respec mechanics.
8. **[08. Shop, Tricks & Cosmetics](08_SHOP_TRICKS_AND_COSMETICS.md)**
   - Fishcoin currency rules, Trick power ceiling (≤ 1100 on Matriarch), complete trick specifications, hero volleys, cosmetic catalog, and daily/weekly challenges.
9. **[09. Maps & Rounds](09_MAPS_AND_ROUNDS.md)**
   - Map roster and coordinates, round scripting grammar, authored rounds 1–40, milestone rounds 41–100, RBE acceptance bands, freeplay (101–140), and Alternate Warrens delta.
10. **[10. UI/UX & Audio](10_UI_UX_AND_AUDIO.md)**
    - Screen structure, match HUD layout, keyboard/mouse controls, colorblind visual shapes, audio design, pop pitch escalation, and accessibility options.
11. **[11. Technical Architecture & Build Order](11_TECHNICAL_ARCHITECTURE.md)**
    - Godot 4 + GDScript architecture, sim/presentation separation, JSON content schemas, deterministic replay action format, save profile with checksum, test runner gates, and phased build order.
12. **[Master Design Plan](MASTER_DESIGN_PLAN.md)**
    - The complete unified source document encompassing all sections in a single canonical reference.

---

## Core Tenets That Must Never Drift

- **No Borrowed IP**: All terminology, names, lore, and artwork are original Clowder canon (Cats, Mice, Coats, Rats, Kibble, Fishcoin, Feats, Insights, Tricks, Mastery). Never borrow proper nouns from other tower defense titles.
- **Authoritative Headless Simulation**: All game rules, combat calculations, and economics reside in `sim/` and read from `content/`. The simulation must run headlessly without any Godot scene-tree or display server dependency.
- **Zero Monetization Surfaces**: Free and fair forever. No ads, no premium currencies, no loot boxes, no paid continues, no real-money transactions. Fishcoin is purely gameplay-earned.
- **Bare Paw as Mastery Truth**: Every map must be beatable on Bare Paw (no Insights, no tricks, no continues, no selling) using only mastery tiers available by natural play.
- **Deterministic Sim**: Seeded RNG; no wall-clock or asynchronous timing in `sim/`.

