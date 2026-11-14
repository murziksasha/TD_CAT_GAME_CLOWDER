# Grill: Grand Expansion Design (Deep & Engaging Clowder TD)
Date: 2026-11-14T19:05:00+02:00

## Intent
The user wants to expand *Clowder: Alley Siege* into a comprehensive, deeply engaging, and highly replayable tower defense masterpiece. The goal is to eliminate player churn across all lifecycle stages (early game hook, midgame retention, endgame mastery) through new game modes, rich progression systems, co-op multiplayer, creative tools, roguelike loops, narrative depth, and meta-features, all without violating the core canon (no real-money monetization, headless deterministic sim, 30 Hz tick, original IP).

## Constraints
- **Strictly Zero Monetization**: No ads, no paywalls, no real-money transactions, no pay-to-win. All rewards (including Season Pass and cosmetics) are unlocked purely through gameplay and Fishcoin.
- **Engine & Architecture**: Godot 4 (4.3+), GDScript. Deterministic 30 Hz headless simulation (`sim/`) separated from presentation (`presentation/`). Data-driven JSON in `content/`.
- **Canon & Terminology**: Original terminology strictly enforced (Cats, Mice, Coats, Rats, Kibble, Fishcoin, Feats, Insights, Tricks, Mastery). No borrowed IP terms.
- **Design Alignment**: All new features must be designed to integrate seamlessly with existing specifications (SPEC/01 through SPEC/12) without contradictory rules.

## Key decisions
- Decision: **First 5 Minutes Triad Hook (Choice + Surprise + Lore)**. New players get an interactive cinematic prologue, a choice of starter hero (Mittens vs Duchess), and an early wave surprise (e.g. Round 5 mini-rat bursting into a chaotic swarm). Reason: Hooks strategic autonomy and curiosity immediately. Alternative considered: Standard linear tutorial with fixed Mittens.
- Decision: **Real-Time 2-Player Co-op (Split-Map + 2x Enemy Spawns)**. Players each defend half the board with independent placement boundaries and independent kill-based kibble earnings, while enemy waves are doubled. Reason: Fosters deep tactical cooperation (support vs DPS) and leverages the 30 Hz deterministic simulation lockstep cleanly without complex resource fighting. Alternative considered: Shared map / shared wallet.
- Decision: **Roguelike Mode ("Alley Crawl")**. Multi-map expedition (5–7 sequential maps) with procedural modifiers, drafting of relics/curses between maps, and partial kibble/resource banking. Reason: Provides endless emergent variety and high midgame retention. Alternative considered: Single-map endless roguelike.
- Decision: **Expanded Modes Suite**. Implement Sandbox / Testing Lab, Boss Rush, Reverse TD ("Alley Invaders" playing as rodents against AI cats), Thematic Challenge Puzzles, In-game Map Editor, and 1v1 PvP Battles (eco/assault). Reason: Caters to all player archetypes (casual, speedrunner, puzzle-solver, creator, competitive). Alternative considered: Staged incremental rollouts.
- Decision: **Endgame Prestige & Deep Progression**. Extend cat progression beyond Mastery 10 with Prestige ranks, Alpha Cat synthesis, Account Prestige, cosmetic titles/frames, and specialized passive paths. Reason: Prevents endgame stagnation for veteran players. Alternative considered: Hard cap at Mastery 10.
- Decision: **Narrative & Lore Integration**. Comic-style dialogues between campaign acts, distinct hero/cat personalities, and environmental worldbuilding. Reason: Creates emotional investment in the cats and the Alley. Alternative considered: Dry flavor-text only.
- Decision: **Engagement Ecosystem**. Free Season Pass (purely gameplay-driven, zero monetization), Almanac/Bestiary with lore entries, detailed player statistics, achievements with rare cosmetics, and seasonal thematic events. Reason: Long-term retention and completionist satisfaction. Alternative considered: Daily/Weekly challenges only.

## Surfaced assumptions
- Real-time co-op and PvP netcode can be built using deterministic lockstep (since `sim/` is already a 30 Hz headless deterministic simulation driven by seeded actions and replays).
- The map editor can output standard `content/maps/*.json` schemas, making community maps fully compatible with the sim and replay runner.
- The free Battle Pass operates entirely on in-game XP/Fishcoin without creating pressure or FOMO.

## Open questions
- Precise network transport protocol for co-op/PvP (ENet / WebRTC / Godot High-Level Multiplayer).
- Exact formula for Alpha Cat synthesis combinations and balance limits.
- Scope and UI layout for the in-game map editor on 1280x720 canvas.

## Out of scope
- Guilds / Clans / MMO-style social hubs (explicitly rejected by user).
- Real-money shops, premium currencies, gacha, loot boxes.
- Direct control or twitch-reflex action gameplay (remains pure path tower defense).
