# Prompt 11 — Electric Platforms

> **Depends on prompt 09** (the death-to-hub flow must exist — electric tiles route through it).

## Goal
Add a new hazard type: electric platforms that look almost identical to safe tiles but kill the player on contact, turning them to dust. The danger is hinted at via three layered sensory cues (sparks, hum, arcs) so a careful player can identify the bad tiles.

## Design Philosophy
Red tiles are visually obvious. Electric tiles are **deliberately not obvious by color** — they wear a normal safe color. Skilled play means noticing the sparks, hearing the hum, and watching for arcs between adjacent dangerous tiles.

## Detailed Requirements

### Electric tile scene
- **New scene:** `scenes/hazard/electric_tile.tscn` — copy of hazard_tile.tscn as a starting point
- Same 2×0.5×2 footprint, same StaticBody3D + CollisionShape3D structure
- **Color:** picks from the existing safe palette (blue / yellow / green / purple) — visually indistinguishable from regular safe tiles
- **Hint 1 — Spark particles:**
  - CPUParticles3D child, looping (not one-shot)
  - Emission rate: ~5/s
  - Particle color: blue with white core
  - Particle size: 0.05 (tiny — visible only if you look)
  - Lifetime: 0.3s
  - Emission shape: box matching tile surface
  - Slight upward initial velocity, gravity zero
- **Hint 2 — Electric hum:**
  - AudioStreamPlayer3D child, looped, plays continuously
  - Source: looping low electric hum sound file (Todd needs to supply — see Asset Note below)
  - Unit DB: -80 by default
  - Max distance: 4 units, with attenuation curve so it ramps from inaudible at 4 units to ~-10dB on contact
- **Hint 3 — Arcs to adjacent electric tiles:**
  - Implemented in `electric_tile_grid.gd` (next section) because arcs need to know about neighbors
  - Each ElectricTile exposes a method `flash_arc_to(other_tile_position: Vector3, duration: float)` that briefly renders a line between its center and the given point

### Arc rendering
- Use a thin elongated MeshInstance3D (BoxMesh, ~0.05 wide, length = distance to neighbor) with a bright blue emissive unshaded material
- Or use ImmediateMesh + ORMMaterial3D for cleaner line rendering — pick whichever is more reliable in Compatibility renderer
- Arc lasts 0.1s, then mesh is freed

### Electric tile grid
- **New scene:** `scenes/hazard/electric_tile_grid.tscn` (Node3D)
- **New script:** `scripts/electric_tile_grid.gd`
- `@export_multiline var pattern: String` — each line is a row, `E` = electric, `S` = safe, space ignored
- Tile spacing: matches existing RedTileGrid (2-unit pitch)
- Spawns:
  - `E` → ElectricTile (with safe color)
  - `S` → HazardTile (with is_red=false, gets a random safe color)
- After spawning, the grid script:
  - Identifies all ElectricTile instances
  - On a timer (random interval 0.5–1.5s), picks a random pair of adjacent (≤2.5 units apart) electric tiles and triggers `flash_arc_to` on one of them toward the other's position
  - Only fires arcs when the player is within ~5 units of the grid (cheap distance check to current_scene's player)

### Death by electrocution
On player contact with an ElectricTile:
1. Trigger a localized blue burst effect on the tile:
   - One-shot CPUParticles3D: 30 particles, blue/white sparks, lifetime 0.6s, fast outward radial velocity, no gravity
   - Brief OmniLight3D flash on the tile (blue, energy 5, fades to 0 over 0.3s)
2. Trigger dust effect at the player's position:
   - One-shot CPUParticles3D: 40 particles, grey/brown color, lifetime 1.5s, low outward velocity, gravity enabled so dust falls
3. Call the death flow from prompt 09 (same `die()` method hazards already use)

No knockback. No flying through the air. Instant electrocution → dust → death screen → hub.

### Level integration
- Add a new section to level_01 **between the golden zone and FinishPlatform**
- Sequence: golden zone exit → ApproachPlatform → 4×6 ElectricTileGrid → MidPlatform → FinishPlatform (with Return-to-Hub portal added in prompt 08)
- Suggested 4×6 pattern (4 wide, 6 deep) with 5 electric tiles scattered, leaving a navigable safe path. Example:

```
S S S S
S E S S
S S S E
E S S S
S S E S
S S S S
```

Tune the pattern so a careful player can find a path but it requires watching for cues.

## Asset Note
**Todd needs to supply a looping electric hum sound file** before this prompt is run. Suggested specs: 1–3 second loop, low frequency, subtle (not a buzzing alarm). Free options on freesound.org. Place at `assets/audio/electric_hum_loop.ogg` and reference from electric_tile.tscn's AudioStreamPlayer3D.

## Verification
1. Walk toward the new electric section in level_01
2. **Hear:** faint electric hum increasing as you approach the dangerous tiles
3. **See:** occasional small blue sparks on the dangerous tiles
4. **See:** tiny arcs occasionally jumping between adjacent dangerous tiles when you're close
5. Step on an electric tile → blue burst on the tile, dust puff at your position, then You Died screen → hub respawn at the pod
6. Coin penalty applied (1–3 lost)
7. Step on a safe tile → nothing happens (same as existing safe HazardTile behavior)

## Do NOT
- Do not make electric tiles a distinct color from safe tiles — the whole point is subtlety
- Do not modify HazardTile, RedTileGrid, or their scripts — create new ones
- Do not implement the death-to-hub flow here — depend on prompt 09's `die()` method
- Do not add a stun mechanic or "second chance" — instant death only
- Do not place arcs that span across the whole grid (only between adjacent electric tiles, ≤2.5 units apart)

## Files Involved
- New: `scenes/hazard/electric_tile.tscn`
- New: `scripts/electric_tile.gd`
- New: `scenes/hazard/electric_tile_grid.tscn`
- New: `scripts/electric_tile_grid.gd`
- New asset (Todd supplies): `assets/audio/electric_hum_loop.ogg`
- Modified: `scenes/levels/level_01.tscn` (insert electric section between golden zone and FinishPlatform)

## Update CLAUDE.md
Add an "Electric Platforms" section under Current Features describing the visual/audio/arc hint system, the pattern-driven grid, and the dust death effect.
