# SPEC 02: Combat Rules, Simulation & Pop Resolution

## 1. Simulation Architecture & Spatial Rules

### Fixed Tick Rate
- **30 Hz Fixed Simulation**: All physics, movement, status ticks, attacks, cooldowns, and pop resolutions run strictly at 30 ticks per second (`dt = 1/30 = 0.0333...s`).
- **Headless & Deterministic**: The sim does not invoke scene tree nodes, UI elements, or system clocks. All randomness uses a seeded linear congruential generator or MT counter.
- **Rendering Interpolation**: Presentation draws interpolated positions between previous and current simulation ticks for smooth visual display at arbitrary monitor refresh rates.

### Tracks and Distance
- Tracks are defined as 2D polylines.
- Unit progress along a path is quantified by distance `s` along polyline from `s = 0.0` (entrance) to `s = L` (exit).
- **Standard Baseline Ruler**: Sunny Gutter has a length of **1200 units**. A standard Rust mouse moving at 40 units/second traverses the track in exactly 30.0 seconds (900 sim ticks).
- **Expert Lane Ruler**: The Warren has a length of **700 units**.

### Placement Masks & Footprints
- Cats must be placed entirely on valid terrain masks:
  - `Land`: Standard cats (Pip, Nibs, Pudding, Biscuit, Nim, Goldie, Miso).
  - `Water`: Water cats (Marlow).
  - `Perch`: High perches or rooftops (Sable can stand on Perch or Land).
- Footprint collisions are circular:
  - Standard cat diameter: **40 units** (radius 20).
  - Goldie (Fishercat) diameter: **55 units** (radius 27.5).
  - Footprints of placed cats cannot intersect or overlap.
- **Obstacles**: Line-of-sight obstacles block cat placement and block line-of-sight linear projectiles. Lobbed projectiles (Biscuit) and full-track hitscan shots (Sable) bypass obstacles.

---

## 2. Damage Types and Immunity Matrix

Damage interactions are determined strictly by damage type versus enemy coat immunities:

| Damage Type | Stopped By / Immune Coats | Notes |
| :--- | :--- | :--- |
| **Claw** | **Iron** coats | Basic physical slashing attacks (Pip needles, Nibs paws). |
| **Bite** | *None* | Physical puncturing/crushing (Nibs Hot Claws, Sable sniper). |
| **Blast** | **Soot** coats | Explosive, area-of-effect damage (Biscuit fishbones). |
| **Magic** | **Ink** coats | Arcane and spark attacks (Nim apprentice bolts). |
| **Acid** | *None* | Corrosive DoT and pools (Bub potion attacks). |
| **Void** | *None* | Rare endgame magic (Nim Tier-5, Duchess Void Flame). |
| **True** | *None* | Irresistible damage that ignores all immunities and reductions. |

---

## 3. Status Effects

| Status | Effect | Stacking & Expiry Rules |
| :--- | :--- | :--- |
| **Chill / Honey** | Speed multiplier below 1.0 | **Highest slow wins**. Slows never multiply together (e.g., 40% slow + 30% slow = 40% slow). Frost coats are 100% immune to Chill. |
| **Freeze** | Unit speed reduced to 0.0 | Refreshing applies the longer remaining duration. **Cannot chain into an infinite/permanent freeze**. Frost coats are immune. Iron freeze duration is capped at 0.4s. Normal rats freeze for 0.3s. |
| **Burn** | Damage over time (Bite damage) | Reapplying refreshes duration. DPS does **not** stack. |
| **Stun** | Unit speed reduced to 0.0; cannot be knocked back or pushed | Duration is dynamically reduced on larger rats (see specific upgrade data). |
| **Knockback** | Displaces progress `s` backward along the track | Has a maximum per-unit displacement cap per second to prevent infinite stalling loops. |
| **Mark** | Affected unit takes bonus damage from all sources | Durations do not stack; the stronger mark value takes precedence. |
| **Hex / Bleed** | Damage over time with spreading capabilities | Spreads to nearby units upon target death according to upgrade specifications. |

---

## 4. Rat Matriarch Control Immunity Component

> [!IMPORTANT]
> The Rat Matriarch's immunity is governed by a **single authoritative component** in `sim/status.gd`, never by scattered exceptions inside individual cat files.

### Component Rules:
- **Absolute Immunity**: The Rat Matriarch completely ignores:
  - `Stun`
  - `Knockback`
  - `Freeze`
  - `Slow` (Chill, Honey, Amber, etc.)
  - `Instant-Kill` mechanics
- **Permitted Afflictions**: The Matriarch **can** be afflicted with:
  - Direct Damage
  - `Mark` (at explicitly documented reduced durations and values, e.g., Hawkeye +1 for 3s)
  - `Hex` (at reduced damage and without spreading off her)
  - `Burn` (capped at specified DPS limits, e.g., Duchess Banked Coals capped at 15 dps)

---

## 5. Pop Resolution & Overflow Recursion Algorithm

Pop resolution must be implemented exactly according to these algorithmic steps:

```
Function ResolveHit(projectile, target):
    layer_hp = target.current_layer_hp
    applied_damage = min(layer_hp, projectile.remaining_damage)
    
    target.current_layer_hp -= applied_damage
    projectile.remaining_damage -= applied_damage
    AwardKibble(applied_damage)
    
    If target.current_layer_hp <= 0:
        children = SpawnChildren(target)
        
        If projectile.remaining_damage > 0 and len(children) > 0:
            // OVERFLOW RECURSION:
            // Overflow damage applies to the FIRST child in the same hit.
            // It DOES NOT consume extra projectile pierce.
            ResolveHit(projectile, children[0])
            
    // Pierce consumption:
    // Hitting a target (including the initial target and its entire overflow cascade)
    // consumes exactly 1 pierce from the projectile.
    projectile.pierce -= 1
    If projectile.pierce <= 0:
        DestroyProjectile(projectile)
```

### Key Pop Rules:
1. **Overflow Damage**: `damage − HP removed` cascades directly into the **first child** at the exact same path position `s`.
2. **Pierce Conservation**: Cascading overflow into children costs **0 additional pierce**.
3. **Subsequent Children**: Sibling children require independent projectile collisions and each consumes separate pierce.
4. **Radius Explosions**: Explosions deal damage once to every eligible unit within their circular blast radius.
5. **Overkill**: Overkill damage that exceeds the final child's HP yields no kibble and causes no negative leaks.

---

## 6. Enemy Modifiers & Properties

- **Shadow**: Cannot be targeted by cats unless the cat has `Night Eye` or the mouse is within an active reveal pulse (e.g., Miso B5, Night Lantern trick).
- **Gnaw (Regrowth)**: If a mouse avoids losing a coat for 2.8 consecutive seconds, it regrows one coat layer, up to its initial spawn coat.
  - **Caps**: Maximum 3 regrows per individual mouse.
  - **Suppression**: Regrowth is completely suppressed while current movement speed is below 80% (i.e., Chill, Honey, and Freeze freeze regrowth).
- **Plated**: Doubles the outermost layer's HP.
  - For a **mouse**, only the outermost coat HP is doubled; spawned children are standard unplated mice.
  - For a **rat**, body HP is doubled, and spawned children emerge **Plated**.
- **Rats**: Heavy multi-stage enemies with designated body HP bars. Rats display visual damage states at 75%, 50%, and 25% remaining HP. On death, they instantly spill their nested children onto the track.

