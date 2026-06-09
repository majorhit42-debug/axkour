# Prompt 15 — Level 02: Frosting Falls

## Goal
Build the first "real" player-facing level: a 5-section candyland-themed parkour course called **Frosting Falls**. Uses the variable-answer quiz from prompt 14, the existing Don't Touch Red hazard tiles, and the existing platform/respawn systems. This is the level new players see first — it should be polished, cohesive, and progressively challenging.

## Prerequisites
- **Prompt 08** (Hub) — needed because this level is reached via a hub portal
- **Prompt 14** (N-answer quiz) — needed for the 4-answer Legos gate
- **Prompt 09** (Death flow) — strongly recommended so death routes through the hub
- **Prompt 12** (X Bot) — should be done first so platform sizing/gaps are tuned to the humanoid silhouette

## Theme

Pastel candyland — bright but not garish. Frosted cake with sprinkles, not neon arcade.

### Color palette
- Platforms cycle through: soft pink `#ffc4d8`, mint green `#c4f0d8`, baby blue `#c4dcf0`, lavender `#dcc4f0`, soft yellow `#fff0c4`
- **NEVER use red for decor** — all reds in this level signal danger (hazard tiles)
- Accents: cream, peach, dusty rose

### Sky
- WorldEnvironment with procedural sky in gradient mode
- Top: soft peach, horizon: pale pink, bottom: cream
- Bright DirectionalLight3D from above (warm white), slight pink-tinted ambient

### Platform material
- StandardMaterial3D, pastel albedo (rotate through palette per platform)
- Roughness 0.6, no metallic, slight emission (energy 0.15) for the "frosted/glowing" look

## Level Structure (All Sections Along +Z)

### Section 1 — Sweet Start (z=0 to z=40)
Welcome jumps. Easy. Teaches the camera and jump rhythm.
- `StartPlatform`: 4×4, position (0, 0, 0), soft pink
- `PlayerStart` Marker3D on StartPlatform
- 6 floating platforms in roughly a straight line, 4×4 each, alternating pastel colors
- Gaps between platforms: 3.5 units (comfortable reach)
- Slight vertical variation: alternate Y=0 and Y=0.5
- Z positions: 7, 14, 21, 28, 35, 40

### Section 2 — The Lego Gate (z=44 to z=64)
Single quiz gate using question id `q04` (added in prompt 14). 4 fork platforms via the new dynamic spawning.
- `ApproachPlatform`: 8×4, z=44, pastel cream — extra wide so player has room to read the question
- `QuizGate` instance (question_id = "q04"): question label at z=52, ForkContainer spawns 4 forks at x = ±7.5 and ±2.5 (handled by prompt 14)
- `ReconvergePlatform`: 6×4, z=60 — must be at least 6 wide to land from any fork

### Section 3 — Sprinkle Steps (z=68 to z=92)
Don't Touch Red intro. 8 stepping stones in a winding zigzag.
- Use existing `HazardTile` scene (2×0.5×2 each)
- 8 stones total: 3 red (lethal), 5 safe
- Place individually (not via grid) so the path winds
- Suggested layout — (z, x, is_red):
  - (68, 0, false)
  - (71, -2, false)
  - (74, 1, true)
  - (77, 2, false)
  - (80, -1, false)
  - (83, -2, true)
  - (86, 1, true)
  - (89, 0, false)
- Followed by `IntermediatePlatform`: 4×4, z=92, pastel blue (landing pad before the grid)

### Section 4 — The Sprinkle Floor (z=96 to z=120)
DTR grid challenge. Bigger, harder. Requires reading the pattern before stepping.
- `MidPlatform`: 6×4, z=96, pastel mint
- `RedTileGrid` instance at z=100 with this pattern (5 wide × 6 deep, ~8 red):
  ```
  S S S S S
  S R S R S
  S S S S R
  R S R S S
  S S S S S
  S R S S R
  ```
- `ExitPlatform`: 6×4, z=122, pastel pink

### Section 5 — Finish (z=128)
- `FinishPlatform`: 10×6, z=128, bright pastel blue with boosted emission (energy 0.4) — celebratory
- "FINISH!" Label3D, Billboard mode, font size 72, gold with thick black outline, floating above the platform
- `ReturnToHubPortal` Area3D on the platform — entering loads `scenes/hub/hub.tscn`
- Visual archway matching the style of prompt 08's hub portals, "RETURN TO HUB" label

## Candyland Props

Three prop types, built programmatically — no external models needed. Place as set dressing flanking the route.

### Giant Lollipop (~5 throughout the level)
- Stick: CylinderMesh, radius 0.12, height 6, brown/tan (#a06030)
- Candy: SphereMesh, radius 1.2, sitting on top of stick (sphere center at stick_top + 1.2)
- Color: random pick from pastel pink / blue / mint / lavender per lollipop
- Material: StandardMaterial3D, roughness 0.3 (glossy), slight emission (0.1)
- Suggested placements (x, z, y_base):
  - (-6, 14, 0) (+6, 28, 0) flanking Section 1
  - (-7, 78, 0) (+7, 88, 0) flanking Section 3
  - (0, 135, 0) — celebration lollipop behind FinishPlatform

### Giant Donut (~6 throughout the level)
- Body: TorusMesh, inner radius 0.6, outer radius 1.5, lying flat (axis = Y)
- Frosting: a slightly smaller TorusMesh on top (inner 0.6, outer 1.4, sitting ~0.15 above body), brighter pastel color
- Sprinkles: 10–12 tiny BoxMeshes (0.1 × 0.05 × 0.1) in random pastel colors and rotations, ring around the top of the frosting
- Suggested placements (x, z, y):
  - (-9, 48, 0.5), (+9, 48, 0.5), (-9, 58, 0.5), (+9, 58, 0.5) — corners of the quiz area
  - (-7, 108, 0.5), (+7, 108, 0.5) — flanking the DTR grid

### Cotton Candy Cloud (~6 floating above the level)
- 4-5 overlapping SphereMeshes at slightly different positions and scales (radius 0.8–1.5)
- All pastel pink OR pastel blue (one color per cloud, randomized)
- Roughness 0.9, no metallic, slight emission (0.1) for puffy glow
- **No collision shape** — purely decorative
- Suggested placements (x, y, z):
  - (-10, 10, 20) pink
  - (+12, 12, 35) blue
  - (0, 14, 55) pink
  - (-8, 11, 75) blue
  - (+9, 13, 100) pink
  - (0, 15, 130) blue (above finish)

## Builder Helper (Recommended)

Create `scripts/candyland_props.gd` as a static class with:
- `static func make_lollipop(color: Color) -> Node3D`
- `static func make_donut(base_color: Color, frosting_color: Color) -> Node3D`
- `static func make_cloud(color: Color) -> Node3D`

Then in a small `scripts/level_02.gd` attached to the level root, call these in `_ready()` and position them. Keeps the .tscn file clean and the prop geometry consistent.

(Alternative: build standalone scenes per prop and instance directly in the .tscn — either works. Pick whichever feels cleaner.)

## Hub Integration

In `scenes/hub/hub.tscn`, add a second portal for level_02:
- `Level02Portal`: place on a different perimeter edge from the existing Level 01 portal
- Same archway visual style as Level 01 portal, but with a pastel pink glowing rectangle inside (theme hint)
- Label3D: "LEVEL 02 — FROSTING FALLS", Billboard, font size 48
- Area3D entering loads `scenes/levels/level_02.tscn`

## Verification

1. From the hub, walk to the Level 02 portal — loads level_02 and spawns at Sweet Start facing +Z
2. Pastel sky visible, lollipops flanking the path, cotton candy clouds drifting overhead
3. Section 1: 6 platforms with comfortable gaps, alternating pastel colors
4. Section 2: 4 fork platforms (1932 / 1965 / 1908 / 1979 in shuffled order), question text reads "When were Legos invented?"
5. Step on 1932 → pass through; step on any other → explodes via existing flow → death screen → hub respawn at the pod
6. Section 3: 8 stepping stones, 3 red, find the safe path
7. Section 4: 5×6 grid with the specified pattern, navigate the safe path
8. Section 5: finish platform with FINISH! label and Return-to-Hub portal
9. Walk into Return-to-Hub portal → loads hub
10. Coin count and equipped skins/hats persist across hub → level_02 → hub transitions
11. Visit Level 01 portal afterward — level_01 still works unchanged (regression check)

## Do NOT
- Do not use red anywhere except hazard tiles (player must trust red = danger)
- Do not add gold coins or a golden zone (not part of this level's design)
- Do not add electric tiles or balloon spawners (not part of this level's design)
- Do not modify level_01 — it stays as the dev sandbox
- Do not require any new external asset files (props are built from Godot primitives)
- Do not modify HazardTile, RedTileGrid, QuizGate, or any other existing system scripts — use them as-is
- Do not increase platform sizes beyond what's specified — gaps are tuned for the X Bot humanoid

## Files Involved
- New: `scenes/levels/level_02.tscn`
- New: `scripts/level_02.gd` (level root script, programmatic prop placement)
- New: `scripts/candyland_props.gd` (static helper for prop geometry)
- Optional new: `scenes/props/lollipop.tscn`, `scenes/props/donut.tscn`, `scenes/props/cotton_candy_cloud.tscn` (if you prefer scene-based props over scripted ones)
- Modified: `scenes/hub/hub.tscn` (add Level 02 portal)

## Update CLAUDE.md
- Add a "Level 02 — Frosting Falls" subsection under Current Features with the section breakdown and theme summary
- Update Roadmap: v0.7 (Real levels) — note first real level shipped, remaining work is level select screen and additional levels
- Note the candyland prop helpers as reusable for any future sweet-themed content
