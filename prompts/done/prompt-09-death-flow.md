# Prompt 09 — Death Flow: You Died Screen + Resurrection Pod

> **Depends on prompt 08** (the hub scene must exist with a `ResurrectionPodSpot` marker).

## Goal
Replace the current in-level respawn with a death-to-hub flow: every death shows a "YOU DIED" screen, then transitions to the hub where the player materializes inside a resurrection pod.

## Detailed Requirements

### What counts as "death"
All of these should now route through the new flow:
- Falling below Y=-20 in any level
- Hazard tile contact (explosion + knockback + fall)
- Wrong quiz platform (explosion + knockback + fall)
- Electric tile contact (added in prompt 11, but route is the same — just make sure the system is generic)

### You Died screen
- **New scene:** `scenes/ui/death_screen.tscn` (CanvasLayer root)
- Full-screen dark-red tinted overlay (ColorRect, dark red at 50% alpha)
- "YOU DIED" text centered, font size 96, bright red with thick black outline, slight fade-in over 0.3s
- Smaller text below: "Returning to hub...", font size 28, light grey
- Total visible duration: **2 seconds**
- Player input is locked while the screen is up — no movement, no looking, no actions
- After 2s: `get_tree().change_scene_to_file("res://scenes/hub/hub.tscn")`

### Resurrection pod
- **New scene:** `scenes/hub/resurrection_pod.tscn` (Node3D)
- Visual stack:
  - **Base:** dark metallic CylinderMesh, radius 1.2, height 0.3, dark grey StandardMaterial3D with metallic=0.8
  - **Chamber:** translucent blue CylinderMesh, radius 1.0, height 2.2, StandardMaterial3D with transparency on (alpha 0.4), albedo light blue, emission enabled (blue, energy 0.3)
  - **Top dome:** SphereMesh scaled to (1.2, 0.3, 1.2), same dark metallic material as base
  - **OmniLight3D** inside the chamber: color light blue, energy 1.5, range 4
- Instance the pod in `scenes/hub/hub.tscn` at the `ResurrectionPodSpot` marker created in prompt 08

### Materialization effect
When the player arrives in the hub via death (not a fresh game start):
1. Player teleports to the ResurrectionPodSpot position (inside the chamber)
2. Spawn a one-shot CPUParticles3D upward burst at the pod position:
   - 30 particles, blue/white sparkle, lifetime 1.0s, upward velocity, slight outward spread
   - Particle size ~0.1, additive blend
3. The pod's OmniLight3D tweens energy 1.5 → 6.0 → 1.5 over 0.4s
4. Player input is locked for 0.5s after materialization (so they don't accidentally bolt out during the effect)

### Coin penalty
- The existing `CoinWallet.lose_random_coins()` call should fire **once per death**, at the moment death is detected (before the You Died screen appears, so the new count shows up when the player gets back to hub)
- Player still loses a random 1–3 coins per death

### Tracking the respawn state across scene change
- **New autoload script:** `scripts/game_state.gd` (singleton name `GameState`)
- Properties:
  - `var respawning_from_death: bool = false`
- When death triggers anywhere: `GameState.respawning_from_death = true`
- Hub `_ready()` checks `GameState.respawning_from_death`:
  - If true: spawn player at `ResurrectionPodSpot`, trigger materialization effect, reset flag to false
  - If false: spawn at regular `PlayerStart` (fresh game start)
- Register the autoload in `project.godot`

### Death trigger refactor
- Currently player.gd handles fall respawn locally; explosion logic in explosion.tscn handles the knockback
- Centralize: add a `die()` method on the player (or a helper on GameState) that:
  1. Calls `CoinWallet.lose_random_coins()`
  2. Sets `GameState.respawning_from_death = true`
  3. Locks player input
  4. Instances the death screen as a child of the current scene
  5. The death screen handles the 2s delay and scene change
- All death sources call this one method

### Input lock during death screen
- Set a flag on Player like `is_dead: bool` that suppresses movement, look, and action input
- Reset when player materializes in hub (after the 0.5s pod lockout)

## Verification
1. Walk into a hazard tile → see "YOU DIED" → 2s later land in the hub with a blue particle burst and light flash from the pod, coin count reduced
2. Fall off a platform (Y < -20) → same flow
3. Step on a wrong quiz platform → same flow
4. Walk out of the pod, return to Level 01 portal, re-enter level → spawn at level_01's PlayerStart cleanly, no leftover state
5. Restart the game → first spawn is at hub `PlayerStart` (not the pod), since `respawning_from_death` starts false

## Do NOT
- Do not change the visual look of explosions or hazard tiles
- Do not remove the hub's `PlayerStart` marker — still used for fresh game starts
- Do not add a "Respawn now" button or skip — death screen is fully automatic
- Do not persist `respawning_from_death` to disk
- Do not change level transitions other than the death-respawn path

## Files Involved
- New: `scenes/ui/death_screen.tscn`
- New: `scripts/death_screen.gd`
- New: `scenes/hub/resurrection_pod.tscn`
- New: `scripts/game_state.gd` (autoload)
- Modified: `scenes/hub/hub.tscn` (add resurrection pod instance, conditional spawn logic)
- Modified: `scripts/player.gd` (replace local fall respawn with `die()` call)
- Modified: `scripts/explosion.gd` (or wherever knockback-death is detected — route to `die()`)
- Modified: `scripts/quiz_gate.gd` (wrong-answer death routes to `die()`)
- Modified: `project.godot` (register GameState autoload)

## Update CLAUDE.md
Add a "Death Flow" subsection under Current Features describing the You Died screen, hub respawn, resurrection pod, and the GameState autoload.
