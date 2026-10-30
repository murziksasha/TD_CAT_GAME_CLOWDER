# AGENTS.md — Project Directive & Agent Operational Rules

## 1. Project Context: Cat Tower Defense ("CTD")
This document defines core game mechanics and non-negotiable operational rules for all AI agents working in this repository.

### 1.1 Game Core Concept (BTD6-Style Adaptation)
* **Towers (Cats):** Base defense units replacing monkeys. Each cat class has 3 upgrade paths (5 tiers each), unique target priorities, and earning/attack styles (e.g., Archer Cat, Claw Brawler, Wizard Cat, Alchemist Cat, Farm Cat).
* **Cat Experience (XP) & Feats:** Towers earn XP through usage in rounds to unlock tier upgrades, special cross-path feats, and passive perk nodes.
* **Heroes (Hero Cats):** Deployable commander cats placed once per match. Level up automatically (1–20) via match XP. Feature 2 active abilities (e.g., Level 3 and Level 10 unlock) and multiple passive aura/combat perks.
* **Enemies (Mice & RATs):**
  * *Mice:* Equivalent to bloons (Standard, Fast/Field Mouse, Armored/Iron Mouse, Camo/Ghost Mouse, Lead/Shield Mouse, Swarm Mice, Ceramic/Vole equivalent).
  * *R.A.T.s (Radical Armored Titans):* MOAB-class blimp equivalents:
    * Light RAT (MOAB class)
    * Heavy RAT (BFB class)
    * Cyber/Fortified RAT (ZOMG class)
    * King RAT / Doomsday Rodent (BAD class)
    * Sub-bosses with mechanics: speed bursts, shield generation, minion spawning.
* **Currencies & Economy:**
  * *In-Match Cash (Yarn/Fishbits):* Earned per mouse popped and round end; used strictly for deploying/upgrading cats during the match.
  * *Fishcoin (Meta Currency):* 100% free; strictly earned via gameplay (victories, daily missions, achievements, mastery feats). Zero real-money microtransactions (no P2W).
* **The Fishcoin Shop:**
  * Visuals & Cosmetics: Skins for Cats & Heroes, custom projectile trails, custom pop/defeat VFX, UI themes, music tracks.
  * In-Game Actives & Powers: Single-use or cooldown field perks (e.g., Catnip Frenzy, Laser Pointer Strike, Tuna Feast boost).
* **Skill Tree / Masteries:**
  * Global passive skill tree unlocked via player account level and Fishcoin/Feat Points (e.g., +attack speed, cheaper tier-1 cats, extra starting cash).

---

## 2. Token-Saving & Communication Directives (STRICT)

All agents interacting with this project MUST adhere to these token-economy rules:

### 2.1 Zero-Fluff Communication Policy
* **No conversational filler:** Do not write greetings ("Hello!", "Sure, I'd be glad to help"), confirmations ("I understand your request"), or wrap-up pleasantries ("Let me know if you need anything else!").
* **No unsolicited architectural/stack preaching:** Never suggest alternative frameworks, game engines, or tech stacks unless the user explicitly asks: *"What stack should I use?"*.
* **Lead with action/deliverable:** Start responses immediately with the solution, artifact, code, or answer.

### 2.2 Maximum Token Efficiency Rules
1. **Compact Output:** Default to bullet points, structured tables, or condensed pseudo-code instead of verbose paragraphs.
2. **Surgical Diffs Over Full Dumps:** When editing files, output only changed sections, diffs, or specific functions. Never reprint untouched lines unless creating a file from scratch.
3. **No Redundant Explanations:** Do not explain self-evident code or re-quote user inputs. State *what* was done in 1–2 short sentences.
4. **Direct Ambiguity Resolution:** If a detail is missing, select the standard BTD6/Tower Defense convention, implement it, and note the assumption in a single bullet point. Do not stall execution with trivial questions.
5. **Keep Context Footprint Small:** Keep variable names descriptive but comments minimal and functional. Avoid boilerplate comment blocks in generated code.

---

## 3. Game Design Specification Anchor

When designing or coding modules, strictly follow this terminology and logic table:

| Bloons TD 6 Concept | Cat TD Equivalent | Description & Mechanic |
| :--- | :--- | :--- |
| Monkey Towers | **Cat Towers** | Deployable units, 3 upgrade paths, earns XP for unlock trees |
| Heroes | **Hero Cats** | Auto-levels 1–20, 2 active abilities + passives |
| Bloons | **Mice** | Standard wave units with speed, layer, and immunity variations |
| MOAB / BFB / ZOMG / BAD | **R.A.T.s** | High-health boss units that break down into smaller mice upon defeat |
| Monkey Money / Cash | **In-Match Yarn** | Tactical currency reset each match for towers/upgrades |
| Trophies / Premium Currencies | **Fishcoin** | 100% free meta-currency earned strictly through play |
| Monkey Knowledge | **Cat Instincts / Skill Tree** | Account-wide passive perk tree |
| Powers / Instas | **Catnip Toys & Treats** | Consumable or active match perks bought with Fishcoin |

---

## 4. Execution Protocol for Agents
* When asked for **plans**: Provide dense, milestone-based checklists with zero narrative filler.
* When asked for **code**: Provide production-ready, typed, modular code directly mapped to the Cat TD concept.
* When asked for **balance/math**: Provide compact formulas and tables (e.g., DPS = Damage × Pierce / AttackInterval).

