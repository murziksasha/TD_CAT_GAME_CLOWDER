# SPEC 03: Enemies — Mice and Rats

## 1. Mouse Coats (12 Tiers)

Mice are layered enemies. Each coat tier possesses distinct speed, health, spawned children, and immunities. Layer HP is **1** for all coats except **Porcelain**, whose outer shell possesses **10 HP**.

### Coat Data Table

| Coat | Speed Multiplier (Units/s) | Children Spawned | Layer HP | RBE | Immunities & Vulnerabilities |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Rust** | ×1.00 (40 u/s) | *None* | 1 | 1 | — |
| **Slate** | ×1.40 (56 u/s) | 1 Rust | 1 | 2 | — |
| **Moss** | ×1.80 (72 u/s) | 1 Slate | 1 | 3 | — |
| **Grain** | ×3.20 (128 u/s) | 1 Moss | 1 | 4 | — |
| **Sugar** | ×3.50 (140 u/s) | 1 Grain | 1 | 5 | — |
| **Soot** | ×1.80 (72 u/s) | 2 Sugar | 1 | 11 | **Blast Immune** |
| **Frost** | ×1.80 (72 u/s) | 2 Sugar | 1 | 11 | **Freeze & Chill Immune** |
| **Ink** | ×1.80 (72 u/s) | 2 Sugar | 1 | 11 | **Magic Immune** |
| **Iron** | ×1.00 (40 u/s) | 2 Soot | 1 | 23 | **Claw Immune** |
| **Marble** | ×1.80 (72 u/s) | 1 Soot + 1 Frost | 1 | 23 | **Blast, Freeze & Chill Immune** |
| **Prism** | ×2.20 (88 u/s) | 2 Marble | 1 | 47 | — |
| **Porcelain** | ×2.50 (100 u/s) | 2 Prism | **10** (Shell) | 104 | Shell absorbs 10 damage |

*Note on Plated Mice*: Plated doubles outermost layer HP only. Plated Porcelain shell is 20 HP (RBE 114). Plated Iron is RBE 24. Children spawned from a plated mouse are standard unplated mice.

---

## 2. Accessible Visual Identification (Shape Language)

To ensure colorblind accessibility and immediate readability at high speeds, each coat features a unique anatomical silhouette:

- **Rust**: Classic round mouse ears.
- **Slate**: Notched left ear.
- **Moss**: Leaf-shaped tail tip.
- **Grain**: Striped tail pattern.
- **Sugar**: Heart-shaped tail tip.
- **Soot**: Square, stocky body profile.
- **Frost**: White fur ruff around the neck (high contrast).
- **Ink**: Wet, dripping tail tip.
- **Iron**: Metal bucket helmet silhouette.
- **Marble**: Vertically split two-tone face mark.
- **Prism**: Flowing neck scarf silhouette.
- **Porcelain**: Cracked ceramic jar carried strapped to back.
- **Shadow Modifier**: Translucent body render (50% opacity) plus an overhead 4-pointed star mark.
- **Gnaw Modifier**: Bright green chewed tooth-mark outline on flank.
- **Plated Modifier**: Metallic reflective rim rendered around the unit circumference in code.

Health bars are reserved exclusively for Rats. Mice communicate damage via coat pop flashes and pip counts for Porcelain.

---

## 3. Super Porcelain (Round 81+)

Starting at **Round 81**, standard mice scaling changes dramatically to prevent late-game projectile lag and emphasize single-target burst over pure pierce:

1. **Massive Shell**: Porcelain shell HP increases from 10 to **60 HP** (Plated Super Porcelain: **120 HP**).
2. **Singular Child Spawning**: Every non-rat mouse spawns **exactly one child** (its primary child).
   - Super Porcelain spawns 1 Prism.
   - Prism spawns 1 Marble.
   - Marble spawns 1 Soot (its primary child).
   - Soot/Frost/Ink spawn 1 Sugar.
3. **Super Porcelain RBE**:
   - Super Porcelain RBE = 60 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 = **68 RBE**.
   - Plated Super Porcelain RBE = 120 + 8 = **128 RBE**.
4. **Shell Bounty Income**: Popping a Super Porcelain shell awards a flat **48 Kibble Shell Bounty** instead of 1 kibble per shell HP. Inner coats still award standard 1 kibble per HP removed.

---

## 4. Rat Bosses

Rats are massive, cart-sized siege units. They feature body health bars with distinct visual damage states at 75%, 50%, and 25% HP, and burst into nested units upon death.

| Rat | First Round | Body HP | Speed Multiplier | Spawns On Death | Distinct Mechanics & Resistances |
| :--- | :---: | :---: | :---: | :--- | :--- |
| **Burrow Rat** | 40 | 200 | ×1.00 (40 u/s) | 4 Porcelain | The initial heavy siege boss. (*Sunny Mode: 130 body HP*). |
| **Bristle Rat** | 60 | 700 | ×0.55 (22 u/s) | 4 Burrow Rats | Armored dreadnought. |
| **Monarch Rat** | 80 | 4000 | ×0.30 (12 u/s) | 4 Bristle Rats | **Knockback immune**; Stun duration halved (×0.5). |
| **Dusk Rat** | 90 | 700 | ×3.20 (128 u/s) | 4 Shadow Plated Porcelain | **Claw Immune, Blast Immune, Shadow**. Chill effectiveness halved (×0.5). |
| **Rat Matriarch** | 100 | 22000 | ×0.18 (7.2 u/s) | 2 Monarchs + 3 Dusk Rats | **Full Control Immunity** (ignores stun, freeze, slow, knockback, instant-kill). |

---

## 5. RBE (Red-Mouse Equivalent) Reference Table

RBE represents the total effective hit points inside an enemy, defining the lives deducted if it leaks into the alley:

| Enemy Unit | Base RBE | Plated RBE | Notes |
| :--- | :---: | :---: | :--- |
| **Rust** | 1 | 2 | Base unit. |
| **Slate** | 2 | 3 | |
| **Moss** | 3 | 4 | |
| **Grain** | 4 | 5 | |
| **Sugar** | 5 | 6 | |
| **Soot** | 11 | 12 | 1 + 2×5 |
| **Frost** | 11 | 12 | 1 + 2×5 |
| **Ink** | 11 | 12 | 1 + 2×5 |
| **Iron** | 23 | 24 | 1 + 2×11 |
| **Marble** | 23 | 24 | 1 + 11 + 11 |
| **Prism** | 47 | 48 | 1 + 2×23 |
| **Porcelain** | 104 | 114 | 10 + 2×47 (Plated: 20 + 2×47) |
| **Super Porcelain (R81+)** | 68 | 128 | 60 + 8 (Plated: 120 + 8) |
| **Burrow Rat** | 616 | 856 | 200 + 4×104 (Plated: 400 + 4×114) |
| *Sunny Burrow Rat (R40)* | 546 | — | 130 body HP + 4×104 |
| **Bristle Rat** | 3,164 | 4,824 | 700 + 4×616 (Plated: 1400 + 4×856) |
| **Monarch Rat** | 16,656 | 27,296 | 4000 + 4×3164 (Plated: 8000 + 4×4824) |
| **Dusk Rat (R90+)** | 1,212 | — | 700 + 4×128 (Super Porcelain Plated) |
| **Rat Matriarch** | 58,948 | — | 22000 + (2 × 16656) + (3 × 1212) |

> [!WARNING]
> Leaking even a single Burrow Rat on Alley difficulty (150 starting lives) causes an instant game over (616 life penalty). Small coats are the only recoverable leaks.

