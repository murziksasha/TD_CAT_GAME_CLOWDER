# Grill: Map camera controls
Date: 2026-11-14

## Intent
Make returning to the standard map view obvious and allow exploring the enlarged map with keyboard arrows.

## Constraints
- Presentation-only change; use the existing wood theme.
- Keep camera movement within map bounds.

## Key decisions
- Minimum zoom is the initial 1.0 view; reaching it restores the original center and clears rotation.
- Reset and Home restore that same view at any time.
- Arrow keys smoothly pan while zoomed in; they do not pan at the standard view.
- Always show slightly transparent +, minus, and Reset buttons; hovering makes them opaque.
- The plus button zooms toward the current view center; the wheel zooms toward the cursor.

## Surfaced assumptions
- The initial view is the player's expected full-map view, despite the old wheel allowing zoom below it.
- Arrow movement refers to the direction of the camera's view across the map.
