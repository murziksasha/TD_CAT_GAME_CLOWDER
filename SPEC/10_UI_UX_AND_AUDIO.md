# SPEC 10: UI, HUD, Audio & Accessibility

## 1. Screen Architecture

The UI is built as modular Godot Control hierarchies adhering to a unified wood-and-brass theme:

- **Title Screen**: Core navigation: *Play*, *Cats*, *Heroes*, *Insights*, *Shop*, *Almanac*, *Settings*.
- **Map Selection Screen**: Displays map cards with earned difficulty medals (Sunny, Alley, Night, Last Whisker, Bare Paw) and modifier badges (Alternate Warrens, Full Nets, Short Leash).
- **Match Loadout Screen**: Pre-match loadout configuration: hero selector, trick slots (1–3), and an active Insights overview panel. (In Bare Paw, Insights and Tricks appear visibly struck through and disabled).
- **Match Viewport & HUD**: In-game battle view, cat placement previews, particle layer, and overlay HUD.
- **Results Screen**: Detailed performance metrics: remaining lives, leaks count, peak kibble, feat cards chosen, Account XP gained, Fishcoin awarded, and the animated **Unlock Queue Ceremony**.
- **Shop Screen**: Tabbed views for *Looks* (skins, trails, banners) and *Tricks*, featuring player Fishcoin wallet balance and item resell buttons.
- **The Almanac**: In-game encyclopedia rendering detailed stats, immunities, and upgrade cards for every cat, enemy coat, rat boss, and trick.
  > [!IMPORTANT]
  > The Almanac reads directly from the canonical JSON files in `content/` to guarantee stats never drift out of sync.

---

## 2. Match HUD Layout

- **Top Left Status Bar**:
  - Current Lives (heart icon).
  - Current In-Match Kibble (fish-bowl icon).
  - Current Round and Total Mode Target (e.g., `Round 24 / 40`).
  - Active Mode Badge.
- **Top Right Round Controls**:
  - Start / Send Round button (Spacebar).
  - Speed toggle buttons: Pause (`Esc`), 1× (`1`), 2× (`2`), 3× (`3`).
  - Auto-start toggle.
- **Bottom Left Commander Panel**:
  - Hero portrait with active level pip (1–20) and circular cooldown overlays for active abilities.
  - Equipped Trick buttons showing remaining round-cooldown pips and in-match kibble cost on the button face.
- **Bottom Center Wave Preview**:
  - Upcoming enemy coat icons with count previews (when unlocked via the Clowder Insight tree).
- **Right / Selection Sidebar (Inspector Panel)**:
  - Selected cat portrait and name.
  - Targeting dropdown / toggle buttons (*First, Last, Strong, Close*).
  - Path A, B, and C upgrade cards showing name, description, cost, and locked/purchased states.
  - Feat progress meter with current Feat rank stars.
  - Sell Button displaying exact 70% refund value.
- **Board Display**:
  - Range footprint circle rendered around selected or hover-dragged cats.
  - Cat footprints rendered as clean circular zones (diameter 40; Goldie 55).

---

## 3. Audio Direction & Sound Cues

Audio provides critical, glance-free tactical feedback:

- **Pop Pitch Escalation**: Enemy pop audio pitches ascend progressively with coat tier. A Rust mouse pop is low-frequency, scaling upward through Sugar and Iron to an unmistakable high ceramic pop for Porcelain.
- **Rat Stings**:
  - Boss entrance sound cue alerts players to a rat entering the lane.
  - The Rat Matriarch features a unique, ominous musical entrance sting.
  - Rat body destruction produces a heavy wooden/metallic crunch distinct from mouse pops.
- **Leak Warning**: When an enemy escapes the exit, a low-frequency resonant thud triggers, accompanied by a brief red screen-border pulse.
- **Skin Sounds**: Cosmetic skins only add secondary layered acoustic flourishes under the base sound effect; they never alter the core gameplay pitch or timing cue.

---

## 4. Visual Polish & Silhouette Clarity

- **Silhouette Identity**: Every cat is instantly distinguishable by silhouette:
  - Pip: Yarn ball and needle.
  - Nibs: Curved claw stance.
  - Pudding: Frost bowl.
  - Biscuit: Fishbone mortar basket.
  - Sable: Rooftop rifle silhouette.
  - Nim: Crackling apprentice spark orb.
  - Goldie: Fishing net and crate.
  - Miso: Cafe signboard and serving apron.
- **Animation Standards**: Basic attacks use crisp 4–8 frame animations. Cat placement uses a uniform 3/4 top-down pose family.
- **Rat Scale**: Standard rats are rendered 3× to 4× the physical size of a Porcelain mouse. The Rat Matriarch is the largest entity on the map.
- **UI Skin Consistency**: HUD chrome strictly adheres to the wood and brass theme implemented in `_apply_wood_theme()`. Multiple clashing UI styles on a single screen are forbidden.

---

## 5. Accessibility & Comfort Settings

- **Permanent Colorblind Shape Language**: All 12 coats and modifiers feature distinct physical anatomical markings (notched ears, leaf tails, scarf silhouettes, metal bucket helmets, chew marks) that remain permanently active across all color palettes.
- **Screen Shake Slider**: Configurable in settings with three steps: *Off*, *Low* (default), and *Full*.
- **VFX & Flash Limiter**: High-intensity full-screen flashes (such as Whiteout or active abilities) are capped and can be reduced or toggled off in settings.
- **Dynamic Text Scaling**: Support for 100%, 125%, and 150% UI font scaling.
- **Hard Pause**: Opening the pause menu instantly freezes the 30 Hz simulation tick with zero background leakage.

