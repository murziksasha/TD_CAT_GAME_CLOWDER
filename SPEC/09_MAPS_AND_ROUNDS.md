# SPEC 09: Maps, Modifiers & Round Scripting

## 1. Map Roster

| Map | Tier | Track Length | Paths | Terrain Masks | Tactical Teaching & Map Rules |
| :--- | :---: | :---: | :---: | :--- | :--- |
| **Sunny Gutter** | Beginner | 1,200 | 1 loop | Land, 1 puddle, perches | Foundational tutorial map. Balances all core metrics. |
| **Market Lane** | Beginner+ | 1,100 | 1 path | Land, perches | Long straightaway (Sable) and a sharp hairpin bend (Nibs). |
| **Rooftop Crossing** | Intermediate | 1,000 | 2 merging | Land, heavy perches, little water | Split-lane coverage. First appearance of **Ink coats** (Round 26). |
| **Fishmarket Maze** | Advanced | 1,400 | 1 looping/crossing | Land, LOS blockers | Line-of-sight sightline blocks; rewards lobs (Biscuit) and full-track attacks. |
| **Canal Night** | Advanced | 1,300 | 2 paths | Heavy water, night lighting | Water placement (Marlow). Map rule: **Shadow mice arrive early on Round 18** (instead of 28). |
| **The Warren** | Expert | 700 | 3 short paths | Cramped land | Ultra-short lane. One active path per round on an authored schedule. Dusk rats cross in ~5.5s. |

### Sunny Gutter Canonical Path Polyline
```text
(40, 100) -> (640, 100) -> (640, 400) -> (340, 400)
```
Props, market stalls, and houses must remain completely outside this ribbon.

---

## 2. Round Scripting Grammar

Rounds are authored as structured data in `content/rounds/*.json` using a concise group syntax:

$$\text{Group Format: } \texttt{[count] [coat] [shadow] [gnaw] [plated] @ [spacing]s}$$

- Multiple simultaneous or sequential groups within a round are separated by semicolons (`;`).
- `Duration` is the elapsed time from first spawn to last spawn, not time to pop.

*Example*: `20 rust @0.45s ; 8 slate @0.40s`

---

## 3. Authored Rounds 1–40 (Sunny Campaign)

*Authoring Constraint*: Iron never appears before Round 23; Shadow never appears before Round 28; Ink is omitted entirely from Sunny Gutter.

| Round | Duration | Spawn Groups | Strategic Intent & Teaching |
| :---: | :---: | :--- | :--- |
| **1** | 14s | `15 rust @0.9s` | Place Pip at entrance. |
| **2** | 16s | `25 rust @0.6s` | Afford a second cat or an upgrade. |
| **3** | 16s | `12 rust @0.5s ; 10 slate @0.5s` | Introduction to layered coat splitting. |
| **4** | 18s | `20 slate @0.5s` | Sustained density check. |
| **5** | 18s | `18 moss @0.55s` | Moderate speed increase. |
| **6** | 18s | `12 moss @0.4s ; 15 rust @0.3s` | Mixed enemy travel speeds. |
| **7** | 16s | `16 grain @0.45s` | First high-speed check (128 u/s). |
| **8** | 20s | `14 grain @0.4s ; 12 moss @0.4s` | Fast scouts overtaking slower coats. |
| **9** | 18s | `24 grain @0.35s` | High-volume speed rush. |
| **10** | 16s | `40 sugar @0.35s` | Severe speed gate (140 u/s). |
| **11** | 18s | `20 sugar @0.3s ; 15 grain @0.3s` | Continuous swift stream. |
| **12** | 20s | `15 moss @0.4s ; 10 soot @0.6s` | **Blast immunity arrives** (Biscuit fails; Claw works). |
| **13** | 20s | `12 soot @0.5s ; 12 frost @0.5s` | **Freeze immunity arrives** (Pudding fails; Claw/Bite works). |
| **14** | 22s | `20 sugar @0.25s ; 8 soot @0.5s` | Split target prioritization. |
| **15** | 20s | `10 frost @0.4s ; 10 soot @0.4s ; 20 grain @0.3s` | Multi-immunity combined with swift coats. |
| **16** | 22s | `25 sugar @0.25s` | Pierce capacity benchmark. |
| **17** | 24s | `8 soot gnaw @0.7s ; 20 slate @0.3s` | **Gnaw tutorial**: Slows suppress regrowth. |
| **18** | 24s | `10 frost gnaw @0.6s ; 15 sugar @0.3s` | Gnaw combined with freeze immunity. |
| **19** | 22s | `30 sugar @0.25s ; 10 moss @0.3s` | Sustained swarm. |
| **20** | 20s | `15 soot @0.35s ; 15 frost @0.35s` | Milestone immunity wave. |
| **21** | 24s | `12 marble @0.5s` | Dual immunity (Blast + Freeze immune). |
| **22** | 24s | `10 marble @0.45s ; 20 sugar @0.25s` | High HP dual immunity + speed. |
| **23** | 26s | `8 iron @0.8s ; 15 grain @0.3s` | **Iron tutorial**: Claw immune (Nibs Hot Claws or Mittens). |
| **24** | 26s | `12 iron @0.6s` | Heavy Iron punish wave if unaddressed. |
| **25** | 24s | `10 prism @0.55s` | Dense coat splitting (47 RBE each). |
| **26** | 28s | `8 prism @0.5s ; 8 iron @0.6s` | Mixed physical immunities. |
| **27** | 28s | `12 marble gnaw @0.45s` | Dual immunity with active coat regrowth. |
| **28** | 26s | `15 sugar shadow @0.3s` | **Shadow tutorial**: Requires Night Eye (Pip B2 / Mittens L4). |
| **29** | 28s | `10 prism @0.5s ; 12 sugar shadow @0.3s` | Target diversion by Shadow scouts. |
| **30** | 24s | `20 prism @0.4s` | Massive RBE wave (940 total RBE). |
| **31** | 30s | `8 iron shadow @0.7s` | Iron + Shadow simultaneously. |
| **32** | 30s | `6 porcelain @1.2s` | **Porcelain arrives**: Multi-hit shells (10 HP shell). |
| **33** | 30s | `8 porcelain @1.0s ; 20 sugar @0.25s` | Heavy shells shielding speed swarms. |
| **34** | 32s | `6 porcelain gnaw @1.2s` | Regenerating porcelain shells. |
| **35** | 30s | `10 porcelain @0.8s` | Dense porcelain barrage. |
| **36** | 34s | `8 porcelain shadow @1.0s ; 10 iron @0.5s` | Stealth heavy shells. |
| **37** | 34s | `6 plated porcelain @1.3s` | **Plated tutorial**: 20 HP outer shell. |
| **38** | 36s | `12 porcelain @0.7s ; 15 prism @0.35s` | Extreme swarm density check. |
| **39** | 40s | `8 plated porcelain @1.0s ; 10 prism shadow @0.4s ; 20 sugar @0.2s` | The final test before the first rat. |
| **40** | 8s | `1 burrow` | **The First Rat**: Burrow Rat (200 HP; 130 on Sunny). |

---

## 4. Milestone Rounds 41–100

| Round | Duration | Spawn Groups | Major Milestone Threat |
| :---: | :---: | :--- | :--- |
| **45** | 35s | `15 porcelain @0.6s ; 10 iron shadow @0.5s` | Reinforced porcelain line. |
| **50** | 40s | `2 burrow @8s ; 12 plated porcelain @0.8s` | Multi-rat test. |
| **55** | 45s | `3 burrow @6s ; 20 prism gnaw @0.3s` | Sustained siege pressure. |
| **59** | 30s | `4 burrow @5s ; 10 plated porcelain shadow @0.7s` | Pre-Bristle escalation. |
| **60** | 10s | `1 bristle` | **The Bristle Rat arrives** (700 body HP). |
| **65** | 40s | `1 bristle @0s ; 6 burrow @4s` | Heavy combined vanguard. |
| **75** | 50s | `2 bristle @12s ; 8 burrow @3s ; 15 plated porcelain @0.5s` | Multi-dreadnought assault. |
| **79** | 45s | `2 plated bristle @10s ; 10 porcelain gnaw @0.4s` | Armored heavy siege. |
| **80** | 12s | `1 monarch` | **The Monarch Rat arrives** (4000 body HP, knockback immune). |
| **85** | 40s | `1 monarch @0s ; 4 bristle @8s` | Dual tier rat vanguard. |
| **89** | 35s | `2 monarch @15s ; 8 plated burrow @3s` | High-health endurance gate. |
| **90** | 20s | `3 dusk @4s ; 30 iron shadow gnaw @0.35s` | **Dusk Rats arrive** (700 HP, 128 u/s, Claw & Blast immune). |
| **95** | 40s | `6 dusk @3s ; 2 bristle @10s` | High-speed boss rush. |
| **99** | 45s | `1 monarch @0s ; 4 dusk @4s ; 4 plated bristle @8s` | Grand siege prior to the Matriarch. |
| **100** | 15s | `1 matriarch` | **The Rat Matriarch** (22000 HP, full control immunity). |

*Note*: From Round 81 onward, all Porcelain enemies spawn as **Super Porcelain** (60 HP shell, single-child cascade, 48-kibble shell bounty).

---

## 5. RBE Acceptance Bands for Filler Waves

Non-milestone rounds are procedurally filled by content generators and must adhere strictly to these total RBE bounds:

| Round Window | Target RBE Range | Balance Check Role |
| :---: | :---: | :--- |
| **Round 10** | 250 – 400 | Starter pacing validation. |
| **Round 20** | 500 – 900 | Mid-tier upgrade affordability test. |
| **Round 30** | 1,500 – 2,500 | Area-of-effect requirement check. |
| **Round 39** | 3,000 – 5,000 | Pre-boss defense stability test. |
| **Round 40** | 616 (546 Sunny) | Burrow Rat check. |
| **Round 50** | 4,000 – 7,000 | Early multi-rat scaling. |
| **Round 60** | 3,164 (+ up to 1,500 extra) | Bristle Rat check. |
| **Round 80** | 16,656 (+ up to 4,000 extra) | Monarch Rat check. |
| **Round 90** | ~3,600 | Dusk Rat sprint check. |
| **Round 100** | 58,948 | Rat Matriarch check. |

---

## 6. Freeplay Waves (Rounds 101–140+)

- Base spawn: Round-100 composition.
- Plus $(\text{round} - 100)$ bonus groups randomly drafted from: `1 plated bristle`, `2 dusk`, `4 plated burrow`, or `20 super porcelain`.
- **Round 120**: A second Rat Matriarch spawns at the wave halfway mark.
- **Round 140**: A third Rat Matriarch spawns.
- Beyond Round 140, exponential health scaling and kibble decay transform the mode into an endurance score attack.

---

## 7. Alternate Warrens Delta Rules

- Porcelain arrives early on **Round 28** (instead of 32); Round 32 receives 4 bonus Porcelain.
- Boss arrival schedule accelerates by 2 rounds:
  - Burrow: **Round 38**
  - Bristle: **Round 58**
  - Monarch: **Round 78**
  - Dusk: **Round 88**
  - Rat Matriarch: **Round 98**
- **Gnaw Mutation**: Exactly one enemy group every 5 rounds gains the Gnaw property.

