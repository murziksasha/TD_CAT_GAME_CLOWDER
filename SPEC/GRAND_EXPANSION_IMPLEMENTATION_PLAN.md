# Grand Expansion Implementation Plan

Status: planning document, 2026-11-14. This is a work checklist, not a claim that the expansion is implemented, balanced, or ratified. [SPEC 13](13_GRAND_EXPANSION_SYSTEMS.md) describes the proposed systems; existing canon and `AGENTS.md` govern conflicts. Implement incrementally behind separate mode entry points and do not label a feature complete until its acceptance checks pass.

## Scope and non-negotiable rules

Deliver the onboarding triad, Clowder Patrol, Alley Crawl, Testing Lab, Rat Gauntlet, Alley Invaders, 25 puzzles, Alley Duel, map editor, expanded mastery and prestige, Alpha Cats, veteran Feats, dialogue and four campaign acts, Alley Ledger, bestiary, statistics, achievements, and seasonal events. Provide the content, UI, persistence, accessibility, automated verification, and balance work required to make each feature usable; a placeholder menu is not completion.

The game remains free with no ads, premium tiers, loot boxes or real-money purchases. Fishcoin buys only cosmetics and Tricks. Five existing modes, standard medals and authored rounds retain their rules. Bare Paw disables Insights, Tricks, continues and selling; expansion rewards must not be required to clear official maps with naturally available Mastery. Keep the 30 Hz deterministic headless simulation in `sim/`; load gameplay values from versioned `content/` JSON, use seeded randomness and stable ordering, and keep scene-tree, wall-clock, transport and artwork in their respective layers. Enforce the canonical crosspath law, HP-based income, leak RBE, recursive overflow, coat immunities and centralized Matriarch control immunity in every applicable mode.

## Current baseline and decisions

- [x] SPEC 13 proposal and SPEC 11 proposed interface examples exist; SPEC README indexes the proposal. They do not ratify changes to existing canon.
- [x] `sim/testing_lab.gd` provides an initial headless wrapper for unlimited Kibble, round selection, enemy spawning, pause and stepping; `tools/test_testing_lab.gd` exercises it. It is not yet a player-facing or complete Sandbox, and replay playback/progression isolation are not established.
- [ ] Inventory the existing `network/network_manager.gd`, `presentation/coop_modal.gd`, `tools/test_coop_sim.gd`, save/replay flows and local uncommitted changes. Reuse only behavior verified against the final contract; do not assume existing networking is lockstep.
- [ ] Record decisions and amend all affected canon before implementing conflicting behavior: starter Mittens/Duchess choice versus the existing Duchess level-7 unlock; Sentry Scout versus authored Sunny round 5, early Iron and the existing enemy hierarchy; two-cat Alpha synthesis versus SPEC 04's three same-type Tier-5 recipe. Specify profile migration and preserve existing player progress. Until resolved, retain existing rules.
- [ ] Resolve multiplayer transport, supported platforms, host/relay and identity model; map-editor target UI and share-code format; Alpha costs, recipes and exact effects. Set measurable balance, reward and session-duration targets before tuning.
- [ ] Confirm actual runtime content and supported roster when authoring counts: six original plus 100 Atlas maps are a planned roster, not proof of shipped maps; 12 coats plus five rats are named types, not a linear tier sequence. Scope 24 veteran cards to the eight launch cats and explicitly decide treatment of later cats.

## Delivery order and dependencies

1. Shared contracts, content validation, persistence and replay foundations.
2. Isolated mode harness and complete Testing Lab.
3. Alley Crawl plus reusable modifier and draft machinery.
4. Determinism audit and lockstep transport, then Clowder Patrol and Alley Duel.
5. Map editor, with import validation before share codes.
6. Other authored modes, progression, narrative and collection systems; build their UI alongside each feature rather than deferring all presentation to the end.
7. Cross-system balance, accessibility, compatibility and release verification.

This order allows independent authored content and presentation to proceed after shared interfaces settle. Each feature can ship only when its own prerequisite decisions and checks are satisfied; multiplayer requires demonstrated cross-platform determinism rather than assuming fixed ticks imply it.

## Phase 1 — Shared mode, content and save foundation

- [ ] Define versioned mode descriptors: ID, ruleset/content version, eligible maps, starting resources, round source, legal actions, progression/reward eligibility, win/loss and replay metadata. Keep existing mode IDs and saves compatible.
- [ ] Build a headless mode lifecycle for setup, action validation, tick, round transitions, win/loss, results and teardown; expose immutable presentation snapshots/events. Route all commands through one deterministic action path.
- [ ] Add explicit mode and result identity to replays, canonical serialization, stable IDs, deterministic action ordering, seed/PRNG version, map revision and content digest. Define rejection, replay compatibility, old versions and migration behavior; log and replay mode-specific actions.
- [ ] Audit numerical operations and unordered iteration, including floats, PRNG, collision ordering, damage/status ownership and serialization. Establish golden per-tick state hashes and supported-platform fixtures; adopt fixed-point or another verified deterministic representation where needed. Never hash JSON formatting or presentation data as authoritative state.
- [ ] Version and validate JSON content, references, ranges, duplicate IDs, modifiers, action payloads and save extensions. Make missing or incompatible content fail clearly rather than silently altering gameplay.
- [ ] Create atomic, checksummed profile migrations and idempotent match-result commits. Preserve XP, Mastery, currencies, Insight purchases, unlocks, medals and settings; include backup/recovery and downgrade behavior.
- [ ] Define central reward eligibility so debug/custom/aborted sessions cannot grant unintended Account XP, Mastery, Fishcoin, achievements or official medals. Cover repeated commits and reconnects.
- **Accept:** old profiles and standard replays load or fail with a clear compatibility message; duplicate result commits grant once; identical recorded actions reproduce tick hashes on every supported build; existing standard behavior and all regression gates pass.

## Phase 2 — Testing Lab

- [x] Integrate the current headless wrapper into an isolated, explicitly labeled mode, with a navigation entry and a return path. Ensure switching away disposes of it; no profile, leaderboard or achievement writes occur.
- [x] Add player controls for unlimited Kibble, selecting any authored round, spawning a chosen coat/rat and path, global freeze/resume and single-tick step. Disable invalid IDs, illegal paths and actions after termination; display why actions fail.
- [ ] Implement replay playback for lab commands, including ordering of multiple actions at one tick, pause and stepping. Record the mode identity so a lab replay cannot be interpreted as a normal match.
- [x] Add observed actual-HP damage counters and DPS over elapsed simulation ticks, resettable sampling and a defined zero-time display. Add Land, Water, Perch, Blocker and path mask overlays.
- [ ] Test spawned units, arbitrary valid/invalid rounds, affordability toggles, paused stepping, normal-match isolation, replay equivalence and zero persistent rewards. A global pause must never apply a status or bypass Matriarch immunity.
- **Accept:** the complete lab can be used through the UI, matches replay headlessly, and leaves a profile byte-equivalent except for explicitly allowed non-progression settings.

## Phase 3 — Alley Crawl

- [x] Define a versioned expedition run state, 5–7-district seeded branching graph, eligible certified map pool, district waves, lives, starting Kibble, ruleset and result policy. Generate with a specified PRNG and stable sorted IDs; persist seed, generator version, graph and choices.
- [x] Implement district selection, clear/loss transitions, resume and final victory. Carry `floor(remaining Kibble / 4)` into the next district in addition to its defined starting amount; specify all other reset/carry rules.
- [ ] Author and validate 12 named environmental modifiers, including Dense Fog, Greased Cobbles, Ink Tide and Frenzy Clock, with exact effects, applicability, caps, stacking/order and incompatible combinations. Draw zero to two distinct eligible modifiers per district.
- [ ] Author Relics including Golden Whisker and Catnip Satchel, plus optional Risk Curses, numerical effects, stacking, duration, exclusions and bounded Fishcoin rewards. Offer three distinct eligible Relics between cleared districts; persist offers and choices so reload cannot reroll.
- [ ] Build the node map, modifier explanations, draft UI, run summary and accessible feedback. Apply modifiers in the sim, not the UI; keep standard medals separate.
- [ ] Test seed fixtures, graph reachability, every modifier combination, drafts with small pools, reload at each transition, Kibble rounding, curse rewards and idempotency. Tune published seed corpus against declared targets.
- **Accept:** a complete run survives save/reload at every boundary with identical choices and results, and all encounters and rewards are authored and validated.

## Phase 4 — Lockstep and multiplayer infrastructure

- [ ] Finalize protocol and transport choice, session IDs, authenticated player identities, threat model, host/relay discovery, bandwidth/size limits and supported connection paths. Treat NAT traversal and availability as explicit features, not consequences of lockstep.
- [ ] Implement handshake checking protocol, build, ruleset, content digest, map revision, player roster, seed and integer input delay. Reject mismatches; exchange one explicit action frame per player per tick, including empty frames.
- [ ] Validate bounded payloads and ownership; sort actions by `(player_id, sequence)`; deduplicate identical frames and reject conflicts. Simultaneous illegal actions must resolve deterministically without mutation. Synchronize pause, start and Feat choices; keep UI speed local.
- [ ] Hash complete canonical authoritative state at agreed ticks, including PRNG and future-affecting state. Halt and surface diagnostics on mismatch. Implement validated snapshots plus input history for reconnect; define timeout, cancellation and resync failure. Never award a result twice.
- [ ] Test latency, jitter, loss, duplication, reordering, malicious frames, simultaneous actions, invalid owners, disconnect/reconnect and cross-platform tick hashes. Test both peer-hosted and relay paths if both are supported.
- **Accept:** identical sessions match tick-for-tick across supported platforms; mismatches and content incompatibility stop cleanly; reconnect restores a verified state without duplicate rewards.

## Phase 5 — Clowder Patrol and Alley Duel

### Clowder Patrol

- [ ] Author validated split placement regions for supported maps, including path flow, boundary tie-break and blocked footprints. Implement owner-only cat actions, separate starting wallets and owner attribution for direct damage, statuses, overflow and all income sources.
- [ ] Duplicate each authored enemy spawn once at `t + 5` ticks (the 30 Hz approximation to 0.15 seconds), preserving deterministic IDs and order. Define all non-pop income, rounding and rewards in content; use a shared life pool `ceil(base lives * 1.5)` in this separate ruleset.
- [ ] Support cross-boundary valid auras and debuffs. Implement one shared hero per match, ownership of Feat choices, both-player round-start votes, co-op results and disconnected-session behavior.
- [ ] Build lobby, region visualization, wallet and lives HUD, player identity, vote/Feat prompts and reconnect/error UI. Co-op results do not grant standard solo medals.
- [ ] Test pop attribution through overflow and status ticks, ownerless income, simultaneous purchases, region edges, 2x spawn count, auras, hero restriction and shared lives; balance across supported maps and difficulty modes.
- **Accept:** two players complete and replay a match with identical state and correctly attributed resources under adverse network conditions.

### Alley Duel

- [ ] Define two separate synchronized tracks, equal loadout rules and versioned send catalog: prices, enemy composition, scheduling, permanent eco increments, round timing, starting resources, lives, anti-stall limit and reward eligibility.
- [ ] Implement atomic send/spend/eco transactions, separate defenses, deterministic enemy scheduling and round-end income. Resolve same-tick losses as a draw; no unilateral action changes an opponent's state outside the validated protocol.
- [ ] Build dual-track and send/eco UI, match setup, accessibility and post-match summary. Test symmetry, simultaneous losses, repeated frames, invalid sends and bounded matches; tune using declared balance targets.
- **Accept:** both perspectives reproduce the same result, sends cannot produce free units or duplicate eco, and valid games terminate.

## Phase 6 — Map editor and safe sharing

- [ ] Finalize a versioned map interchange schema and adapter to the existing runtime format, including canvas bounds, polylines, spawn/exit routes, Land/Water/Perch masks, Blockers, decorative props, IDs and map revision.
- [ ] Implement a shared validator before the editor or importer loads content: integer bounds, route connectivity, nonzero segments, legal polygons and overlaps, track clearance, resource limits, unique IDs and allowlisted assets. Reject scripts, external fetches, corrupt data and unsupported versions.
- [ ] Build grid/polyline editing, mask painting, blocker and prop tools, undo/redo, validation feedback, save/load, test-play and accessible controls. Decorations remain visual unless explicitly represented by a blocker.
- [ ] Specify bounded share-code encoding, compression, version and checksum, with deterministic round trips and rejection of oversized or malformed input; a checksum is not authentication.
- [ ] Keep imported maps separate from official content and medals; require the existing Atlas fairness and Bare Paw gates before any map becomes official. Fuzz JSON, polygons and codes and test replay map-revision mismatches.
- **Accept:** users can create, export, import, share and play a valid map; unsafe/invalid input fails without code execution or progression abuse.

## Phase 7 — Additional modes and authored challenges

### Rat Gauntlet

- [ ] Author 5,000 starting Kibble, lives, income, five stages in Burrow → Bristle → Monarch → Dusk → Matriarch order, escalation modifiers, timing, rewards and between-stage rules. Implement stage clear only after all relevant enemies and children are gone.
- [ ] Build mode entry, stage HUD and results; test loss, final clear, stage transitions, immunity, save/reload and reward eligibility. Tune all stages against published targets.

### Alley Invaders

- [ ] Specify the grain economy, legal coat send catalog and prices, spawn cadence, deterministic seeded AI cat loadouts and upgrades, Fish Vault RBE capacity, deadline, outcome and rewards; author them in JSON.
- [ ] Implement player sends, AI decisions and vault breaches in the headless sim; provide resource, path and AI-defense UI. Test determinism, affordability, capacity, timeouts and balance across scripted strategies.

### Challenge puzzles

- [ ] Author 25 distinct puzzles, each with map revision, waves, exact starting Kibble, locked cat inventory and quantities, legal actions, objective, win/loss and reward rules. Include Ink Paradox and Sniper's Narrow Alley if their designs pass review.
- [ ] Record an independently replayable solution for each puzzle; verify legal actions and final outcome in automation. Build puzzle browser, constraints, retry and results UI. Test corrupted definitions, unaffordable actions and no standard medal leakage.
- **Accept:** each mode has its own complete rules/content, headless tests, accessible entry and playable victory/loss path; all 25 puzzle proofs pass.

## Phase 8 — Mastery, prestige, Alpha Cats and veteran Feats

- [ ] Author cumulative Mastery 11–20 thresholds and cosmetic-only badges, frames and sound flairs. Preserve existing XP and unlocks through migration; no additional combat power from these ranks.
- [ ] Specify Account Prestige eligibility, reversible confirmation flow, point refund/reallocation, crest, cosmetic-only shop discount, floor and cap. Preserve Account XP, levels, unlocked content and purchases; exclude Tricks from the discount. Test repeated resets and insufficient/invalid states.
- [ ] After the Alpha canon decision, author complete recipes, costs, input tiers/types/ownership, one-per-match constraint, position, Feat and stat inheritance, slot accounting, sell/refund behavior, exact combat components, UI, content IDs and replay/save migration. Enforce crosspath and Tier-5 uniqueness. Never require Alpha power for Bare Paw.
- [ ] Author three veteran Feat cards for each of the eight launch cats, with eligibility after round 80, seeded offer rules, stacking and exact numerical effects. Fit the existing between-round draft and thresholds unless a canon amendment changes them.
- [ ] Test XP migration, prestige point conservation, discount boundaries, all recipes and rejected synthesis actions, deterministic Feat offers and each card's mechanics. Balance separately from standard Bare Paw.
- **Accept:** all intended progression has content and clear UI, survives migration, cannot duplicate points or currency, and respects standard-mode fairness.

## Phase 9 — Onboarding and story

- [ ] Create a skippable, replayable three-panel North Fish Pier prologue, text alternatives, subtitles and contextual Pip/range/path/upgrade/pierce guidance. Preserve normal authored rounds unless the Sentry decision explicitly changes canon.
- [ ] Implement the approved starter-hero choice and unlock migration only after its canon decision; otherwise keep Mittens starter and Duchess at level 7. Implement the Sentry encounter only after enemy hierarchy, timing, RBE, payout and placement are approved.
- [ ] Create and validate data-driven dialogue scripts with speaker, emotion, line, optional SFX and deterministic event triggers. Presentation renders and skips dialogue without modifying or waiting on simulation ticks; mechanical choices require recorded actions.
- [ ] Author all four Alley Chronicles acts, map/encounter references, boss dialogues, unlock rules and results, covering the Matriarch, Baron Salt and Sister Pebble. Provide fallback text and audio controls.
- [ ] Test new and migrated profiles, skipped/replayed tutorials, missing assets, all story triggers, localization, accessibility and replay equivalence.
- **Accept:** first contact and all four acts are playable and skippable, and canonical unlocks and round pacing remain correct.

## Phase 10 — Ledger, almanac, stats, achievements and events

- [ ] Author a 50-tier free Alley Ledger with published XP thresholds, cosmetic/audio/Fishcoin rewards and track IDs. Copy eligible Account XP into one selected track without consuming or duplicating Account XP; atomically claim each tier once. Retain unclaimed and archived tracks and define offline/calendar reconciliation.
- [ ] Extend the almanac/bestiary to read actual sim JSON for coats, rats, armor, damage and immunities; add lore, kill milestones and a feasible layered 2D rotation/viewer. Provide clear fallback when art is missing and never obscure combat-critical information.
- [ ] Record versioned, idempotent match results for Kibble spent, actual RBE popped, compositions, ward attempts/wins and explicitly defined efficiency metrics. Exclude Sandbox and other ineligible sessions; expose a lifetime dashboard.
- [ ] Author at least 50 achievements with stable IDs, Bronze/Silver/Gold/Onyx thresholds, eligibility and cosmetic title rewards. Track and claim each tier exactly once; test replay and reconnect deduplication.
- [ ] Author Harvest Feast, Winter Lantern Festival and Midnight Alley schedules, visual themes, contracts, rules and bounded rewards. Keep calendar time outside `sim/`; specify offline trust/reconciliation and ensure missed cosmetics are obtainable through archived play or a Fishcoin cosmetic catalog.
- [ ] Build free-track, archive, almanac, dashboard, achievements and event UI with accessible text and feedback. Test old-save migration, repeat claims, offline use, season rollover and the Fishcoin boundary.
- **Accept:** content and UI are complete, rewards are auditable and idempotent, and there are no premium or permanently inaccessible rewards.

## Phase 11 — Verification and release readiness

- [ ] Run `npm test` and `npm run test:sunny` after each sim/content/balance change; investigate failures rather than weakening existing nine balance gates. Run targeted headless tests for each added feature and include them in an automated runner.
- [ ] Test standard and expansion replays, migration from representative old saves, seed fixtures, network determinism and hostile input, map imports, all authored puzzle solutions, full progression paths, reward deduplication and disabled-debug boundaries.
- [ ] Run official-map and Ward Atlas Bare Paw fairness checks using naturally available Mastery without expansion power; validate combat immunities, overflow, Kibble and leaks across modes. Record seeds, builds and measurable balance outcomes; do not claim mathematical balance without evidence.
- [ ] Launch with `npm start` after presentation changes; place Pip, start a round, verify mice on the cobbles, dock icons, HUD interactions and a tier ornament. Manually exercise each new screen, keyboard/navigation, text scaling, colorblind cues, subtitles, reduced effects and asset fallbacks.
- [ ] Verify single-player offline functionality, no real-money surface, no premium currency or paywalls, no restricted Fishcoin spending, no standard medals from uncertified maps, and no profile rewards in Sandbox.
- [ ] Update the relevant canonical SPEC files, content schemas, save/replay compatibility notes and release notes only after decisions and tests; clearly label unfinished or unvalidated features. Review scope and ship each mode only after its acceptance criteria pass.
