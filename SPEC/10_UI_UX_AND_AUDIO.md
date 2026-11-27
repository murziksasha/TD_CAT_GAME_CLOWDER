# SPEC 10: UI, HUD, Audio & Accessibility

## 1. Screen Architecture

The UI is built as modular Godot Control hierarchies adhering to a unified wood-and-brass theme (`WoodTheme` in `presentation/wood_theme.gd`, applied via `_apply_wood_theme()`):

- **Title Screen (`presentation/title_menu.gd`)**: Illustrated alley backdrop using the Stage 2 prop set (`stoop`, `awning`, `lantern`, `hanging_wash`, `crate_stack`, `mouse_hole`, `fish_basket`), profile card (Account Level, XP bar, Fishcoin, Golden Bones), and wood buttons for *Play*, *Almanac*, *Insights*, *Alley Shop*, *Collector's Vault*, *Leaderboards*, *Co-op*, and *Settings*.
- **Map Selection Screen (`presentation/map_select_modal.gd`)**: Map card grid displaying map name, difficulty band, and medal pips for Sunny, Alley, Night, Last Whisker, and Bare Paw (filled pip when earned in `save_mgr.data["medals"]`, empty pip when unearned), plus mode selection before starting a match.
- **Match Loadout Screen (`presentation/loadout_modal.gd`)**: Pre-match loadout configuration: hero portraits, equipped trick slots (1–3), and an Insights summary. In Bare Paw mode, Insights and Tricks are visibly struck through and disabled from mode/sim rules.
- **Match Viewport & HUD (`presentation/main.tscn`, `presentation/main.gd`)**: Tiled grass and cobble alley (`WorldDraw`), wordless entrance (`mouse_hole`) and exit (`fish_basket`), placement decals (teal when legal, terracotta when blocked), streamlined TopBar, WaveStrip, BottomDock, and Inspector sidebar.
- **Pause Sheet (`presentation/pause_modal.gd`)**: Opened via `Esc` or Pause/Den. Freezes the 30 Hz sim tick (`match_paused = true`) and provides *Resume*, *Settings*, *Return to Title*, Den shortcuts (*Almanac*, *Insights*, *Alley Shop*, *Collector's Vault*, *Leaderboards*, *Co-op*), and the match keybind summary.
- **Results Screen**: Performance metrics: win/loss, remaining lives, leaks count, peak kibble, feats taken, Account XP gained, and Fishcoin awarded. The unlock line renders only when the save has queued unlocks (or Testing Lab / Alley Crawl status).
- **Shop & Collector's Vault (`presentation/shop_modal.gd`)**: Tabbed views for *Looks & Tricks* (Fishcoin) and *Collector's Vault* (Golden Bones), with wallet display and resell buttons. Prices stay in `content/`.
- **Insights (`presentation/insights_modal.gd`)**: Passive trees rendered as wood medallions with clear highlighting for the next purchasable node in each path. Costs stay in `content/insights.json`.
- **The Almanac (`presentation/almanac_modal.gd`)**: In-game encyclopedia rendering portraits, permanent coat/cat shape notes, upgrade paths, and immunity lines directly from `content/`.
  > [!IMPORTANT]
  > The Almanac reads directly from the canonical JSON files in `content/` to guarantee stats never drift out of sync.

---

## 2. Match HUD Layout

- **Top Bar (`TopBar`)**:
  - Code-drawn Lives heart icon + number.
  - Code-drawn Kibble bowl icon + number.
  - `Round n / target` and active Mode badge.
  - Pause toggle, Speed toggles (`1×`, `2×`, `3×`), `Start` round button (`Space`), and `Den` / Pause sheet button. Map and mode selectors live on the Map Card flow rather than the match bar.
- **Incoming Wave Strip (`WaveStrip`)**:
  - Compact strip directly beneath `TopBar` (ending above `y = 80` so it never overlaps the Sunny Gutter ribbon at 100%–150% text scale) showing sprite chips + counts for the upcoming wave, with full threat details in its tooltip and localized screen-reader string.
- **Bottom Cat Dock (`BottomDock`)**:
  - Roster cells in `content/cats/index.json` order (including Marlow and Bub) plus Heroes, showing frame 0 of the cat sheet, name, and placement cost. Unaffordable cats dim their portrait while keeping the cost readable.
- **Right Sidebar (`InspectorPanel` / `RightInfoPanel`)**:
  - **Empty Inspector**: Shows map/mode header and a single prompt line (`"Choose a cat, or tap a cat on the alley."`). On a profile's first match (`settings["coach_seen"] == false`), hosts the three sequential coach beats (place Pip, send round, buy highlighted path), plus one-time crosspath and sell hints.
  - **Selected Cat**: Frame 0 portrait, name, category/damage type, compact stats, segmented target control (*First*, *Last*, *Strong*, *Close*), three upgrade path cards (name, one-line description from content, cost, tier pips, and one-line crosspath lock reason), Sell button (70% refund), and Deselect.
  - **Selected Hero**: Portrait, code-drawn level badge (`LV 1–20`), and two ability buttons with cooldowns.
- **Feat Modal (`FeatModal`)**:
  - Appears between rounds only; subtitle notes between-round timing and keyboard shortcuts `1`, `2`, `3` for picking cards, with Reroll shown only where allowed and displaying its 150 Kibble cost.

---

## 3. Audio Direction & Sound Cues

Audio (`presentation/audio.gd`) provides glance-free tactical feedback respecting `audio_volume`:

- **Pop Pitch Escalation**: Enemy pop audio pitches ascend progressively with coat tier (`rust_pop` through `porcelain_pop`).
- **Rat Stings & Entrances**:
  - `rat_enter` triggers `rat_entrance` for Burrow, Bristle, and Dusk, `monarch_fanfare` for Monarch, and `matriarch_sting` for the Rat Matriarch.
  - Rat body destruction produces a heavy crunch distinct from mouse pops.
- **Leak Warning**: Escaping units trigger the low-frequency `leak` thud, border pulse, and exit fish-basket pulse.
- **Skin Sounds**: Cosmetic skins add a quiet secondary `skin_flourish` under the base cue without altering core pitch or timing.

---

## 4. Visual Polish & Silhouette Clarity

- **Alley Environment & Props (`presentation/world_draw.gd`)**:
  - Tiled grass (`grass.png`) and tiled cobbles (`cobble.png`) with a soft grass-to-cobble transition ribbon.
  - Map-keyed storybook prop layouts (`stoop`, `awning`, `crate_stack`, `hanging_wash`, `lantern`, `puddle`, `stall`) clear of every map's path ribbon, water, perches, and obstacles, plus wordless `mouse_hole` entrance and `fish_basket` exit marks.
  - Placement preview renders a teal ground decal on legal cells and a terracotta decal on blocked cells. Selected cats show a faint range fill (`0.08` alpha) that leaves mice readable.
- **Silhouette Identity**: Every cat is distinguishable by silhouette and attack animation (yarn, claw, frost bowl, mortar, rifle, spark, net, apron, bite, brew). Code-drawn tier ornaments use a brass, yarn, and frost vocabulary at tiers 1, 3, and 5.
- **Damage Family Streaks & Material Block Marks**: Linear projectiles draw distinct unnumbered streaks per damage family (Claw, Bite, Blast, Magic, Acid, Void, True). Blocked hits draw material marks in `presentation/vfx.gd`: iron clang sparks, soot ash puffs, ink splashes, and frost crystals. Hero abilities pulse a telegraph ring from exposed cooldown timing.
- **Rat Scale**: Rats render 3×–4× a Porcelain mouse (`32px` Porcelain vs `102px–128px` Burrow/Dusk/Bristle/Monarch), with Rat Matriarch largest (`156px`).
- **UI Skin Consistency**: All match HUD panels and Den modals share `WoodTheme` (`_apply_wood_theme()`).

---

## 5. Accessibility & Comfort Settings

- **Permanent Colorblind Shape Language**: All 12 coats feature permanent physical shapes (notched ear + chew marks, flat cap, leaf hat + leaf tail, satchel, lollipop, chimney brush, knit scarf, wizard hat, bucket helmet, stone slab, crystal prism, ceramic shell) active in every match and previewed in a 12-coat strip inside Settings. Shadow mice render at 50% alpha with a code-drawn star; Plated adds a code-drawn rim.
- **Screen Shake (`screen_shake`)**: *Off*, *Low* (default), and *Full*, applied to `world_camera.offset`.
- **VFX & Flash Limiter (`vfx_reduced`)**: Shortens effect lifetimes and drops full-screen/area fills while preserving pop bursts, material block marks, and leak border pulses.
- **Dynamic Text Scaling (`text_scale`)**: 100%, 125%, and 150% scaling applied across match HUD and Den modals, wrapping within fixed panel footprints so 150% never covers the Sunny Gutter ribbon.
- **Hard Pause**: Opening the Pause sheet freezes the 30 Hz simulation tick with zero background leakage.
