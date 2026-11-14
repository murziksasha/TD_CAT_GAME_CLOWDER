# SPEC/12 — Ward Atlas (100 New Maps for Clowder)

Canonical specification for the post-launch Ward Atlas expansion. The six launch maps (**Sunny Gutter**, **Market Lane**, **Rooftop Crossing**, **Fishmarket Maze**, **Canal Night**, **The Warren**) remain authoritative and unchanged. The one hundred maps in this atlas are new neighboring districts across ten thematic wards.

---

## 1. Tenets and Design Rules

1. **Fixed Resolution & Ribbon**: All maps fold into the fixed 1280×720 playfield. A longer track is a longer folded ribbon, never a scrolling camera or world.
2. **Readability**: Entrances (paw-arch), exits (fish-crate), splits, and merges must read visually within one second before the first mouse moves. Path material is always lighter than the ground.
3. **One Idea Rule**: Every standard map teaches exactly one new idea or mechanical nuance. Signature maps (one per ward) may combine two.
4. **Recovery Pocket**: A recovery segment sits after the most dangerous zone or merge point, allowing players to respond to leaks.
5. **Land Placement Primacy**: Land placement alone must always be sufficient to beat the map on Bare Paw mode. Water, perch, and air tiles are tactical advantages, never mandatory paywalls.
6. **No Secret Counters**: Any early appearance of specialized coats (Iron before Round 23, Shadow before Round 28, Ink on beginner maps, Frost before Round 30) must be explicitly noted on the pre-round map card and hint box.
7. **The Picture is the Rule**: Visuals reflect simulation rules directly. Flooded tiles look submerged, sight blockers are visible props (stalls, pews, chimneys), and closed lines show visual barriers. The HUD does not duplicate what the art already communicates.
8. **Stat Invariance**: Map verbs alter geometry, timing, sightlines, placement masks, or spawn distances. They **never** multiply mouse or rat base HP or shield health.
9. **Round Boundary Transitions**: Tides, polyline rewrites, schedule shifts, and eclipse pulses are announced 3 rounds ahead and trigger strictly on round boundaries. No mid-round polyline swaps.
10. **Time-to-Exit Floor**: First mouse of any spawned group must remain on the track for:
    - **Beginner (B) / Beginner+ (B+)**: $\ge 8.0$ seconds.
    - **Intermediate (I) / Advanced (A)**: $\ge 6.0$ seconds.
    - **Expert (E)**: $\ge 5.0$ seconds (Floor length $\ge 700$ units, matching The Warren's 700-unit dusk crossing).
11. **Crossing Geometrics**: Projectiles crossing intersecting paths hit only targets within their true physical collision circle, never ghost-hitting both lanes without spatial contact.

---

## 2. Shared Machinery

### 2.1 Round Families
Maps do not use private custom round files for 1–100. Each map selects one of six canonical families. Boss milestones (Burrow R40, Bristle R60, Monarch R80, Dusk R90, Matriarch R100) remain fixed on their canon rounds. All rounds adhere to the RBE acceptance bands in `SPEC/09`.

| Family | Role | Delta from Sunny Canon Script |
| :--- | :--- | :--- |
| **Standard** | Default | Sunny rounds 1–40 and milestone table unchanged. |
| **Sprint** | Short ribbons ($\le 900$) | Fewer mice per wave, wider spacing, identical total RBE band. Maintains the time-to-exit floor. |
| **Siege** | Rat classrooms | Introduces early "teacher" rats at 50% body HP. Full HP applies only on the canon boss round. Inner children are unchanged. |
| **Ink Night** | Stealth & magic lessons | Shadow and Ink coats appear earlier than canon; group counts drop proportionally to preserve RBE. Card displays an explicit warning. |
| **Procession** | Priority training | Identical RBE, extended quiet intervals, followed by extremely dense mouse knots. |
| **Harbor** | Water districts | Standard enemy counts and coats; preserves canal atmosphere without forcing coat changes. |

### 2.2 The Eight Map Verbs
All map-specific simulation interactions are governed by eight discrete, deterministic sim components:

| Verb | Sim Implementation | Behavior & Rules |
| :--- | :--- | :--- |
| **Schedule** | `sim/verbs/schedule.gd` | Authored round-to-path lookup table. Previews active paths 3 rounds ahead. Mice spawn only on scheduled paths for that round. |
| **Sight** | `sim/verbs/sight.gd` | Authored obstruction polygons/rectangles. Linear projectiles (Pip needles, Nibs claws, Nim sparks) are blocked by line-of-sight collision. Lobs (Biscuit) and full-track hitscan (Sable) bypass sight blockers. |
| **Tide** | `sim/verbs/tide.gd` | Lowland zones submerge on authored round intervals. Warns 3 rounds ahead. Cats placed on flooded tiles are lifted and refunded at **100% total invested kibble** (including upgrades). Feats reset. High docks never submerge. |
| **Lever** | `sim/verbs/lever.gd` | Player-activated interactive mechanism with kibble cost and round cooldown. Modifies sim state (drops awning, drains canal cut, triggers water wheel slow). |
| **Lantern** | `sim/verbs/lantern.gd` | Stationary circular zone that removes Shadow concealment while lit. Fuel burns out over rounds; relighting costs kibble. Night Eye upgrade always functions independently. |
| **Zone** | `sim/verbs/zone.gd` | Spatial radius applying a constant status or modifier: mouse haste (+15–20%), mouse slow (20–30%), cat range reduction (fog), gnaw ground, or thorn damage (1 Bite/sec). Matriarch is immune to control zones; Frost ignores chill zones. |
| **Rewrite** | `sim/verbs/rewrite.gd` | Replaces active path polyline with an alternative authored ribbon on specified round boundaries. Previewed 3 rounds ahead. |
| **Offset** | `sim/verbs/offset.gd` | Published enemy groups emerge from a burrow entrance at an offset distance $s > 0$ along the track instead of the main entrance ($s = 0$). Remaining track distance must satisfy the time-to-exit floor. |

---

## 3. Progression, Medals & Trials

### 3.1 Medals
- **Alley Medal**: Awarded for clearing the map on Alley mode (Rounds 1–60).
- **Night Medal**: Awarded for clearing the map on Night mode (Rounds 1–80).
- **Sunny Medal**: Available on Beginner and Beginner+ maps (Rounds 1–40).
- **Last Whisker Medal**: Available on Advanced and Expert maps (1 life, Rounds 1–100).
- **Bare Paw Medals**: Exclusive to the **10 signature maps** (Maps 10, 20, 30, 40, 50, 60, 70, 80, 90, 100) and the 6 launch maps.
- **Modifier Ward Ribbons**: Awarded once per ward for beating any map in that ward with a modifier active (Alternate Warrens, Full Nets, Short Leash).

### 3.2 Trial Contracts
Each map offers two optional contract trials from eight templates. Completing a trial rewards Fishcoin and exclusive cosmetic accents. Trials never award cats, heroes, lives, or Insights.

| Trial Template | Condition |
| :--- | :--- |
| **Small Clowder** | Maximum 4 cats deployed simultaneously (Hero counts as one). |
| **Poverty** | Starting kibble reduced to 70% of standard mode allowance. |
| **Named Paw** | Match locked to one specific hero and three named cat types. Tricks disabled. |
| **Clean Whisker** | Total lives lost capped at a strict threshold ($\le 20$, or 0 on Expert). |
| **Quiet Paw** | No Tier-5 upgrades allowed. |
| **District Bench** | One entire cat class banned (Alley, Hunt, Myth, or Den). |
| **Long Watch** | Play Rounds 1–100 from scratch on a map whose default is Siege Watch. |
| **Siege Watch** | Start directly at Round 60 with a standardized stipend (12,000 kibble, normal mode lives). Hero begins at Level 1. Default mode for Map 100 (Matriarch's Hall). |

### 3.3 Ward Unlocks
- A ward unlocks when the player holds **5 Alley medals** in the preceding ward.
- Sunwash Gutters unlocks immediately upon unlocking Market Lane.
- Inside an unlocked ward, all 10 maps are visible. Expert maps display a difficulty caution until 3 medals are earned within that ward.

---

## 4. Expansion Heroes, Tricks & Muster Rats

### 4.1 Post-Launch Heroes
*Prerequisite*: Obsidian (Account Lv 18) and Velvet (Account Lv 22) kits must be completed before adding new heroes.

1. **Sister Wick** (Chapel Keeper):
   - *Level 3 Active*: Illuminates all active Shadow mice on screen for 6.0 seconds.
   - *Level 7 Passive*: Grants Night Eye to all cats within her aura range.
   - *Level 10 Active*: Plants a temporary lantern for 15.0 seconds.
   - *Level 20 Passive*: Automatically reignites one extinguished lantern at the end of every round.
2. **Skipper Brine** (Lock Keeper):
   - *Level 3 Active*: Churns canal water to slow mice on one track segment by 40% for 6.0s (Matriarch control immunity applies).
   - *Level 7 Passive*: Cats placed in water masks gain +10% attack range.
   - *Level 10 Active*: Drops a lock gate, holding back one enemy group for up to 5.0s.
   - *Level 20 Passive*: Provides tide warnings 4 rounds in advance (1 round earlier than default).

### 4.2 Expansion Tricks
Respects the 1,100 maximum damage ceiling on the Rat Matriarch:
- **Relight**: Instantly reignites all dark lanterns on the map. Long cooldown. Ineffective on maps without lanterns.
- **Sandbag**: Designates one land cat to resist the next tide flood. While submerged, the cat cannot attack, but its position and upgrades are preserved without being lifted.

### 4.3 Muster Rats
Weekly challenge rat variants built on existing rat bodies with one added mechanic:
- **Tide Muster** (Burrow body): Floods one low-lying terrain pool for 5 rounds upon defeat.
- **Cog Muster** (Bristle body): Advances the map schedule track selection by one step upon defeat.
- **Eclipse Muster** (Dusk body): Emits a pulse every 15 seconds cloaking nearby mice in Shadow for 4 seconds.
- **Kiln Muster** (Bristle body): Enforces a permanent haste aura on the kiln segment until slain.

---

## 5. The Complete Atlas: 100 Maps Across 10 Wards

### Ward 1: Sunwash Gutters (Maps 1–10)
*Theme*: Bright morning amber, wet cobbles, pale plaster. Introduces placement masks, hairpins, and the first lever.

| # | Map Name | Band | Shape | Length | Family | Verb | Design & Learning Objective |
| ---: | :--- | :---: | :--- | :---: | :--- | :--- | :--- |
| **1** | Lantern Stoop | B | Loop | 1200 | Standard | — | One puddle and two perches. Demonstrates water and perch masks. |
| **2** | Crabapple Bend | B | Bend | 1100 | Standard | — | Broad elbow for Nibs, straight approach for Pip. |
| **3** | Twin Gutters | B+ | Split-merge | 1150 / 900 | Standard | — | Two entrance paths converging into a single shared exit ribbon. |
| **4** | Stall Row | B+ | Line | 1300 | Standard | Sight | Market stalls obstruct direct needle fire. Lobs and perch shots pass. |
| **5** | Puddle Court | B+ | Loop | 1200 | Harbor | — | Moat-like ponds with peripheral docks. Water cat placement practice. |
| **6** | Chimney Step | I | Bend | 1050 | Standard | — | Perch platforms overlooking a tight hairpin curve. |
| **7** | Fishbone Straight | B | Line | 1500 | Standard | — | Long, forgiving straightaway. Goldie economy investment lesson. |
| **8** | Sack Corner | B+ | Bend | 1000 | Standard | Sight | Crates hug the inner curve; rewards close-range burst cats. |
| **9** | Welcome Bridge | I | Loop | 1250 | Standard | Lever | 150 Kibble lever lowers a drawbridge, diverting mice onto an extended loop. |
| **10** | **Morning Arch** | B | Loop | 1200 | Standard | — | **Signature Map**. Diorama featuring every terrain mask. Trial: Pip & Nibs only. |

### Ward 2: Copper Market (Maps 11–20)
*Theme*: Polished brass, striped canvas canopies, crate stacks. Teaches line-of-sight obstruction, crossings, and early lanterns.

| # | Map Name | Band | Shape | Length | Family | Verb | Design & Learning Objective |
| ---: | :--- | :---: | :--- | :---: | :--- | :--- | :--- |
| **11** | Spice Arcade | B+ | Line | 1200 | Standard | Sight | Covered colonnade with pillars obstructing linear targeting. |
| **12** | Herring Square | B+ | Loop | 1300 | Standard | — | Open plaza permitting concentric interior or exterior defensive lines. |
| **13** | Copper Scale | I | Cross | 1400 | Standard | Sight | Orthogonal intersection. Proves projectiles do not hit both arms without collision. |
| **14** | Basket Bridge | I | Split-merge | 1000 / 1000 | Standard | — | Elevated bridge path and lower street lane merging at central market stall. |
| **15** | Fig and Twine | B+ | Bend | 1150 | Standard | Sight | Dense crate clusters leave only narrow, tactical placement pockets. |
| **16** | Weigh House | I | Loop | 1350 | Standard | Sight | Central warehouse blocks vision across the circle; favors Biscuit lob shots. |
| **17** | Two-Purse Lane | I | Dual | 900 / 1100 | Standard | — | Parallel dual lanes with asymmetric pacing, sharing a single life pool. |
| **18** | Canopy Cross | I | Split-merge | 1050 | Standard | Sight | Hanging fabric awnings obscure firing lines. |
| **19** | Night Onion | A | Loop | 1200 | Ink Night | Lantern | Shadow coats emerge Round 22. Three relightable lanterns reveal stealth. |
| **20** | **Grand Bazaar** | A | Cross | 1500 | Standard | Sight + Lever | **Signature Map**. Lever drops central awning: clears vision but removes build tile. |

### Ward 3: Rooftop Parish (Maps 21–30)
*Theme*: Terracotta tiles, soot-blackened chimneys, billowing linen. Teaches perch-dominated layouts and dynamic line-of-sight.

| # | Map Name | Band | Shape | Length | Family | Verb | Design & Learning Objective |
| ---: | :--- | :---: | :--- | :---: | :--- | :--- | :--- |
| **21** | Tile River | I | Line | 1100 | Standard | — | Elevated roofline bordering a sunken gutter path. |
| **22** | Laundry Reach | I | Bend | 1000 | Standard | Sight | Laundry sheets flap across lanes, intermittently blocking vision for 10s. |
| **23** | Chimney Choir | I | Loop | 1200 | Standard | — | Abundant chimney perches with minimal ground-level land. |
| **24** | Gutter Below | A | Line | 900 | Sprint | — | Deep trench gutter; high-angle perches required for optimal coverage. |
| **25** | Pigeon Loft | I | Bend | 1050 | Standard | — | Perch cluster concentrated on a single critical corner. |
| **26** | Slate Switchback | I | Bend | 1400 | Standard | — | Triple zig-zag along a sloped slate mansard roof. |
| **27** | Bellwalk | A | Line | 800 | Sprint | — | Extremely narrow roof ridge with tight footprint budget. |
| **28** | Crossing Leads | A | Dual | 1000 / 800 | Standard | — | High roof route and street gutter running in parallel, merging late. |
| **29** | Awning Row | I | Line | 1200 | Standard | Zone | Open gutter grants +15% mouse haste; covered segments run at normal speed. |
| **30** | **Parish Spine** | E | Line | 1600 | Standard | Sight | **Signature Map**. Sweeping bell-tower shadow blocks line-of-sight on a fixed clock. |

### Ward 4: Canal Borough (Maps 31–40)
*Theme*: Teal rippling water, damp weathered timber, moonlight reflections. Teaches tides, lock gates, and aquatic defense.

| # | Map Name | Band | Shape | Length | Family | Verb | Design & Learning Objective |
| ---: | :--- | :---: | :--- | :---: | :--- | :--- | :--- |
| **31** | Lock One | I | Line | 1300 | Harbor | — | Broad canal basin running parallel to a cobble towpath. |
| **32** | Stillwater | I | Loop | 1250 | Harbor | — | Central land island surrounded by a navigable water moat. |
| **33** | Barge Turn | I | Bend | 1100 | Harbor | Sight | Moored cargo vessel blocks line-of-sight through the canal bend. |
| **34** | Twin Locks | A | Dual | 1000 / 1000 | Harbor | — | Dual stepped water lock channels with shared exit pool. |
| **35** | Tide Step | A | Loop | 1200 | Harbor | Tide | Low-lying shoals submerge during rounds 20–30 and 50–60 (100% lift refund). |
| **36** | Reed Cut | I | Bend | 1150 | Harbor | Zone | Dense reed bed slows mice by 20% but disallows cat placement. |
| **37** | Night Wharf | A | Loop | 1200 | Ink Night | Lantern | Stealth coats from Round 18; wharf lanterns provide illumination. |
| **38** | Eel Bend | A | Bend | 850 | Sprint | — | Short high-velocity canal curve testing rapid crowd control. |
| **39** | Dry Dock | E | Loop | 1400 | Harbor | Lever | Pump lever drains basin into land; reroutes mice onto a shortcut (-300 length). |
| **40** | **Moon Canal** | E | Dual | 1300 / 1200 | Ink Night | Tide + Lantern | **Signature Map**. Dual canal with tidal lowland inundation and dark lanterns. |

### Ward 5: The Pantry (Maps 41–50)
*Theme*: Warm brickwork, spilled white flour, glistening berry jam. Teaches hazardous/helpful zones and coat counter classrooms.

| # | Map Name | Band | Shape | Length | Family | Verb | Design & Learning Objective |
| ---: | :--- | :---: | :--- | :---: | :--- | :--- | :--- |
| **41** | Flour Drift | I | Loop | 1200 | Standard | Zone | Flour cloud reduces cat attack range by 20% within its bounds. |
| **42** | Oven Mouth | I | Bend | 1000 | Standard | Zone | Heated oven stretch grants mice +20% movement haste. |
| **43** | Crumb Parade | B+ | Line | 1300 | Standard | — | Straightforward pacing map introducing warm bakery palette. |
| **44** | Yeast Rise | A | Loop | 1200 | Standard | Rewrite | Dough rise at rounds 25 & 55 expands ribbon into longer loop variants. |
| **45** | Jam Cellar | I | Bend | 1050 | Standard | Zone | Sticky jam puddle slows mice by 30% and blocks tower construction. |
| **46** | Rolling Pin | B+ | Line | 1600 | Standard | — | Expansive worktable straightaway; pierce and economy classroom. |
| **47** | Frosted Tray | A | Loop | 1100 | Standard | — | Frost coats arrive early on Round 8 (hinted on card). Tests Claw & Bite counters. |
| **48** | Proofing Rack | A | Scheduled trio | 800 / 900 / 1000 | Sprint | Schedule | Three rack tiers cycling sequentially; upcoming three rounds displayed on card. |
| **49** | Sugar Rush | E | Line | 720 | Sprint | Zone | Ultra-short track with terminal haste strip; sugar-heavy enemy compositions. |
| **50** | **Night Bake** | E | Cross | 1300 | Procession | Sight + Zone | **Signature Map**. Cycling steam curtains, haste oven mouths, and heavy clumps. |

### Ward 6: Garden Cloister (Maps 51–60)
*Theme*: Verdant leaves, blooming flowerbeds, mossy stone walls. Teaches automated damage zones, gnaw ground, and trellis adjustments.

| # | Map Name | Band | Shape | Length | Family | Verb | Design & Learning Objective |
| ---: | :--- | :---: | :--- | :---: | :--- | :--- | :--- |
| **51** | Herb Spiral | I | Loop | 1500 | Standard | — | Winding circular garden path offering deep central sightlines. |
| **52** | Thorn Gate | I | Bend | 1100 | Standard | Zone | Briar patch deals 1 Bite damage per second to crossing mice. Unbuildable. |
| **53** | Koi Run | I | Loop | 1250 | Harbor | — | Tranquil garden pond with wide, stable lawn perimeters. |
| **54** | Trellis Maze | A | Cross | 1400 | Standard | Sight + Lever | Pruning trellis opens clear vision lines but removes a turn, shortening the track. |
| **55** | Pollen Court | I | Loop | 1200 | Standard | Zone | Every 4th round, releases pollen cloud slowing mice by 25% for 6s (Frost immune). |
| **56** | Glasshouse | A | Loop | 1300 | Standard | Sight + Zone | Glass partitions block direct projectiles; interior mist creates mild fog. |
| **57** | Compost Heap | A | Bend | 1000 | Standard | Zone | Mice traversing heap gain Gnaw property. Does not double-stack with innate Gnaw. |
| **58** | Moonflower Walk | A | Loop | 1150 | Ink Night | Lantern | Night-blooming flora function as organic lanterns. Stealth starts Round 16. |
| **59** | Walled Orchard | E | Scheduled trio | 900 / 1000 / 1100 | Standard | Schedule | Three orchard paths sharing one portal; follows published rotation. |
| **60** | **Briar Heart** | E | Scheduled dual | 1000 / 850 | Standard | Schedule + Lever | **Signature Map**. Nature selects live path; lever forces secondary path for 3 rounds. |

### Ward 7: Clock & Coil (Maps 61–70)
*Theme*: Polished brass gears, blued clockmaker steel, amber lantern glow. Teaches transparent scheduling mechanisms and mechanical track shifts.

| # | Map Name | Band | Shape | Length | Family | Verb | Design & Learning Objective |
| ---: | :--- | :---: | :--- | :---: | :--- | :--- | :--- |
| **61** | Pendulum Walk | A | Scheduled dual | 1100 / 1000 | Standard | Schedule | Track toggles cleanly between left and right swings every round. |
| **62** | Gear Garden | I | Loop | 1200 | Standard | Sight | Central drive housing creates a massive sight blocker in the hub. |
| **63** | Three-Face Clock | A | Scheduled trio | 900 / 1000 / 1100 | Sprint | Schedule | Clock face indicator reveals active path assignment for next 3 rounds. |
| **64** | Spring Alley | I | Line | 1400 | Standard | — | Winding, spiral street; pure spatial efficiency layout with no tricks. |
| **65** | Counterweight | E | Dual | 1200 / 800 | Standard | Lever | Sets active path for next 5 rounds. First pull free, subsequent pulls 100 kibble. |
| **66** | Lantern Cog | A | Loop | 1100 | Ink Night | Lantern + Schedule | Mild two-track alternation coupled with relightable lantern pads. |
| **67** | Overflow Pipe | A | Scheduled dual | 800 / 1400 | Sprint | Schedule | Swaps between a short emergency bypass and a long labyrinthine drain. |
| **68** | Catwalk Rail | I | Line | 1200 | Standard | — | Continuous perch gantry suspended above a straight industrial track. |
| **69** | Escapement | E | Rewrite trio | 1000 / 1200 / 900 | Standard | Rewrite | Ribbon transitions into subsequent mechanical layout every 10 rounds. |
| **70** | **Twelfth Hour** | E | Rewrite + dual | 1300, then +1100 | Siege | Rewrite + Schedule | **Signature Map**. At Round 41, clock wing opens as a permanent parallel route. |

### Ward 8: Undertown (Maps 71–80)
*Theme*: Sweating sewer brick, iron grates, deep green runoff. Teaches compact track geometries while rigorously observing the time-to-exit floor.

| # | Map Name | Band | Shape | Length | Family | Verb | Design & Learning Objective |
| ---: | :--- | :---: | :--- | :---: | :--- | :--- | :--- |
| **71** | First Grate | I | Line | 900 | Sprint | — | First genuinely compact sprint track; tests rapid frontline burst. |
| **72** | Elbow Drain | A | Bend | 780 | Sprint | — | Severe hairpin corner; remains strictly above the 5.0s expert floor. |
| **73** | Triple Culvert | E | Trio | 720 / 760 / 800 | Sprint | — | Three simultaneously active sewer outflows. RBE target -10% to balance split. |
| **74** | Sump | A | Loop | 1000 | Harbor | Tide | Sump basin fills with effluent; surrounding perimeter ledge stays dry. |
| **75** | Rust Cascade | A | Bend | 1100 | Sprint | — | Stepped switchback descent; pure polyline sim styled as vertical drops. |
| **76** | Echo Pipe | I | Line | 1500 | Procession | — | Wide unobstructed conduit; sanctuary map emphasizing pierce vs clumps. |
| **77** | Blackwater | E | Loop | 900 | Ink Night | Lantern | Stagnant runoff channel; early stealth mice arrive on Round 18. |
| **78** | Gnaw Nest | E | Bend | 1000 | Standard | Zone | One additional group every 3 rounds acquires Gnaw without stacking regen. |
| **79** | Dusk Cut | E | Line | 720 | Siege | — | Exact straight-line equivalent of The Warren's 5.6s dusk crossing. |
| **80** | **Antehall** | E | Scheduled dual | 800 / 860 | Siege | Schedule | **Signature Map**. Cramped vestibules take turns. Half-HP teacher rats. |

### Ward 9: Moon Chapel (Maps 81–90)
*Theme*: Flickering candlelight, deep indigo stained glass, marble sepulchers. Teaches early Ink counters, reliquary slows, and the global eclipse pulse.

| # | Map Name | Band | Shape | Length | Family | Verb | Design & Learning Objective |
| ---: | :--- | :---: | :--- | :---: | :--- | :--- | :--- |
| **81** | Candle Nave | I | Line | 1400 | Standard | Sight | Heavy timber pews obstruct direct line-of-sight across the central nave. |
| **82** | Ink Well | A | Loop | 1200 | Ink Night | — | Ink coats arrive Round 20 (hinted). Magic immune; Nim and Claw shine. |
| **83** | Whisper Gallery | I | Line | 1600 | Standard | — | Long cathedral corridor; optimal for chained Miso aura formations. |
| **84** | Stained Glass | A | Cross | 1300 | Procession | Sight | High glass mullions block projectiles; card names forthcoming coat family. |
| **85** | Reliquary | A | Loop | 1250 | Standard | Lever | 200 kibble lever releases incense: 30% slow on nave for 8s (once per 5 rounds). |
| **86** | Processional | I | Line | 1500 | Procession | — | Solemn quiet followed by high-density clumps; targeting priority practice. |
| **87** | Quiet Cloister | A | Loop | 1100 | Standard | — | Clean, symmetrical courtyard layout designed for trial challenges. |
| **88** | Shadow Pew | E | Loop | 1150 | Ink Night | Lantern | Stealth arrives Round 12. Six distributed pew lanterns must be managed. |
| **89** | Bell and Bone | A | Split-merge | 1000 / 900 | Standard | — | Belfry perches overlooking converging crypt pathways. |
| **90** | **Eclipse Court** | E | Loop | 1300 | Ink Night | Zone + Lantern | **Signature Map**. Rounds ending in 0 shroud mice in Shadow for first 12s. |

### Ward 10: Deep Warren (Maps 91–100)
*Theme*: Packed earth, subterranean terracotta pipes, distant glowing eyes. Teaches burrow offset spawns, progressive rewrites, and grand boss gauntlets.

| # | Map Name | Band | Shape | Length | Family | Verb | Design & Learning Objective |
| ---: | :--- | :---: | :--- | :---: | :--- | :--- | :--- |
| **91** | Burrow Lip | A | Loop | 1100 | Siege | Offset | Starting Round 30, one group emerges from glowing burrow mouth at $s = 0.30L$. |
| **92** | Bristle Run | A | Line | 1000 | Siege | — | Extended straightaway built to test Bristle Rat crowd control. |
| **93** | Three Mouths | E | Trio | 900 / 900 / 900 | Siege | Offset | Three active routes; center lane spawns via offset burrow. |
| **94** | Porcelain Kiln | E | Bend | 1200 | Standard | Zone | Early Porcelain from Round 26 (hinted). Kiln mouth grants +20% mouse speed. |
| **95** | Monarch Carpet | E | Loop | 1500 | Siege | Zone | Grand ceremonial approach; fog zones confined strictly to side shrines. |
| **96** | Long Vigil | A | Line | 1700 | Standard | — | Longest endurance layout in the atlas; folded serpentine within the 720p frame. |
| **97** | Dusk Gallery | E | Line | 780 | Siege | — | High-speed sprint gallery tailored for Dusk Rat confrontation. |
| **98** | Throne Approach | E | Rewrite | 1100+ | Siege | Rewrite | Polyline adds an extra loop after each canon rat round to accommodate bosses. |
| **99** | Whisker Vault | E | Loop | 900 | Sprint | — | Severely restricted build pads; spatial placement mask is the entire puzzle. |
| **100** | **Matriarch's Hall**| E | Line | 1400 | Siege | — | **Grand Signature Map**. Exactly 14 build pads. **Default: Siege Watch** (starts Round 60). Trial: Long Watch (Rounds 1–100). |

---

## 6. Fairness Gates & Validation

All nine launch balance gates in `tools/balance_runner.py` must stay strictly green. The atlas introduces seven additional automated verification gates:

1. **Travel Floor Gate**: Automated content validation asserting that no wave on any map allows its leading mouse to reach the exit faster than the band threshold (B/B+ $\ge 8.0$s, I/A $\ge 6.0$s, E $\ge 5.0$s).
2. **RBE Invariance Gate**: Ensures round family variations (Sprint, Procession, Siege, Triple Culvert -10%) remain within the canonical RBE band boundaries of `SPEC/09`.
3. **Early Threat Hint Gate**: Asserts that any map introducing Iron ($< 23$), Shadow ($< 28$), Ink ($< 20$), Porcelain ($< 32$), or Frost ($< 30$) possesses an explicit non-empty `hint` string in its JSON configuration.
4. **Land Footprint Witness Gate**: Every map JSON must contain valid land masks accommodating at least eight non-overlapping standard cat footprints ($r = 24$) outside the path clearance ribbon.
5. **Headless Reference Replay Gate**: Headless runner execution of verified reference replays for all 10 signature maps (or Siege Watch for Map 100), plus 15-round pacing smoke replays for the remaining 90 maps.
6. **100% Lift Refund Gate**: Automated sim unit test verifying that cats lifted by tidal flooding return 100% of purchase and upgrade kibble to the bank and scrub feat tracking.
7. **Three-Round Advance Notice Gate**: Asserts that sim state exposes upcoming schedules, tidal floods, polylines rewrites, and eclipse triggers at least 3 rounds in advance via clean data queries.

---

## 7. Phased Implementation Roadmap

- **Phase 0 (Spec & Indexing)**: Author `SPEC/12_WARD_ATLAS.md`, link from `SPEC/README.md` and `SPEC/09_MAPS_AND_ROUNDS.md`.
- **Phase 1 (Ribbons & Multi-Path Sim)**: Implement multi-path routing, sight line occlusion, schedule querying, and the travel floor harness. Author greybox data for Maps 1–10. Verify leak on Path B of Twin Gutters.
- **Phase 2 (Sunwash & Copper Kits)**: Presentation support for multi-path rendering, sight obstruction props, and maps 1–20.
- **Phase 3 (Environmental Verbs)**: Tide, Lever, Lantern, and Zone simulation modules. Author Maps 21–40 (Rooftop Parish & Canal Borough).
- **Phase 4 (Classrooms & Custom Zones)**: Author Maps 41–60 (Pantry & Garden Cloister). Implement fog and gnaw zones.
- **Phase 5 (Clocks & Drains)**: Author Maps 61–80 (Clock & Coil, Undertown). Implement 3-round schedule HUD and Triple Culvert -10% RBE tuning.
- **Phase 6 (Chapel, Deep Warren & Rewrite)**: Author Maps 81–100. Implement polyline rewrite, offset spawn mouths, eclipse pulses, and Siege Watch stipend.
- **Phase 7 (Medals, Trials & Almanac)**: Implement ward progression unlocks, 2 trial contracts per map, ward modifier ribbons, and Relight/Sandbag shop tricks.
