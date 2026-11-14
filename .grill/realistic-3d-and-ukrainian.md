# Realistic alley and Ukrainian UI — implementation record

## Intent

The match presentation should feel like an inhabited alley rather than a board of tokens, while the 30 Hz headless simulator remains the sole gameplay authority. The player can play the complete match in Ukrainian or English; character names and the word `Clowder` stay Latin-script.

## Decisions carried into this build

- Keep simulation coordinates, deterministic ticks, and content identifiers unchanged.
- Add explicit land, water, and perch placement validation in the simulator. Water is no longer decorative: ordinary land cats cannot be placed there and Marlow is water-only.
- Add Marlow as the ninth cat, including the named water verbs in content: harpoon, dive, and sonar. The first implementation keeps those verbs data-driven and safely falls back to the normal projectile renderer where a bespoke effect is not yet available.
- Add the five named maps to the same map menu and reuse the Sunny wave set, with map-level night/shadow and path scheduling metadata.
- Add paired `en`/`uk` catalogues plus a runtime fallback to English. Key parity is tested.
- The existing painterly 2D renderer stays as the safe fallback while the presentation is upgraded incrementally; no simulation code calls the scene tree.

## Deferred asset work

The requested bespoke 3D meshes and the full 135 tier animation grids require authored source art and are not generated as a substitute for the established cat art direction. Missing visual assets remain non-fatal by design.
