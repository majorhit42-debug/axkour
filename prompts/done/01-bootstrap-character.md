# 01 — Bootstrap: Movable Character + First Platforms

> Before starting, read `CLAUDE.md` in the project root. Confirm you understand the tech stack (Godot 4, GDScript, Compatibility renderer, web export target) before writing any code.

## Goal

Stand up the smallest possible playable scene: a 3rd-person humanoid character standing on a platform, able to walk and jump across a few platforms with gaps between them. Falling off respawns the character at the starting position.

**No** menus, **no** UI, **no** quiz, **no** items, **no** enemies, **no** slap, **no** coins, **no** balloons. Just movement, gravity, and respawn. This is the foundation; every later feature gets layered on top.

---

## Project Setup

If `project.godot` doesn't already exist, create it for Godot 4.x. Then:

1. Set the renderer to **Compatibility** — Project Settings → Rendering → Renderer → Rendering Method = `gl_compatibility`. (This is required for HTML5 export later.)
2. Create folders if missing: `scenes/`, `scenes/player/`, `scenes/levels/`, `scripts/`, `assets/`, `prompts/ready/`, `prompts/done/`.
3. Set the main scene to `scenes/main.tscn` (we'll create it below) — Project Settings → Application → Run → Main Scene.

---

## Input Map

Add these actions in Project Settings → Input Map:

| Action | Key |
|--------|-----|
| `move_forward` | W |
| `move_back` | S |
| `move_left` | A |
| `move_right` | D |
| `jump` | Space |
| `slap` | Mouse Button Left *(register only — wired up in a later prompt)* |
| `release_mouse` | Escape |

---

## Player Scene — `scenes/player/player.tscn`

Tree:

- **Player** (`CharacterBody3D`) — root
  - **CollisionShape3D** — `CapsuleShape3D`, radius 0.4, height 1.8
  - **Mesh** (`MeshInstance3D`) — `CapsuleMesh`, radius 0.4, height 1.8, plain white `StandardMaterial3D`
  - **CameraPivot** (`Node3D`) — positioned at the head, local Y ≈ 1.6. This node yaws (rotates around Y) with horizontal mouse movement.
    - **SpringArm3D** — `spring_length` = 4.0, pointing along negative Z. This pitches (rotates around X) with vertical mouse movement.
      - **Camera3D** — `current = true`

Attach `scripts/player.gd` to the Player root.

### `scripts/player.gd` requirements

- `extends CharacterBody3D`
- Exported or constant: `SPEED = 6.0`, `JUMP_VELOCITY = 5.0`, `MOUSE_SENS = 0.003`, `RESPAWN_Y = -20.0`
- A property `respawn_position: Vector3` set externally by the level (not hardcoded)
- `_ready()`:
  - `Input.mouse_mode = Input.MOUSE_MODE_CAPTURED`
- `_unhandled_input(event)`:
  - On `MouseMotion`: rotate `CameraPivot` around Y by `-event.relative.x * MOUSE_SENS`; rotate `SpringArm3D` around X by `-event.relative.y * MOUSE_SENS`, then clamp the SpringArm's X rotation between `deg_to_rad(-80)` and `deg_to_rad(80)`.
  - On `release_mouse` action: toggle `Input.mouse_mode` between `CAPTURED` and `VISIBLE`. (Recapture on next click is optional this prompt.)
- `_physics_process(delta)`:
  - Apply gravity: `velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta` if not on floor
  - Read input vector from the four `move_*` actions
  - Convert input from local (camera-relative) to world: take the CameraPivot's basis, project onto XZ plane, normalize
  - Set `velocity.x` and `velocity.z` from input × SPEED (preserve `velocity.y`)
  - On `jump` action AND `is_on_floor()`: `velocity.y = JUMP_VELOCITY`
  - `move_and_slide()`
  - If `global_position.y < RESPAWN_Y`: set `global_position = respawn_position`, zero out `velocity`

---

## Level Scene — `scenes/levels/level_01.tscn`

Tree:

- **Level** (`Node3D`) — root
- **WorldEnvironment** — new `Environment` resource with a `ProceduralSkyMaterial` background (otherwise the world is black)
- **Sun** (`DirectionalLight3D`) — angled ~45° down, energy 1.0
- **StartPlatform** (`StaticBody3D`)
  - `MeshInstance3D` with `BoxMesh`, size (6, 0.5, 6)
  - `CollisionShape3D` with matching `BoxShape3D`
  - Position at world origin
- **Platforms** — 4–5 more `StaticBody3D` platforms of similar size at varying X and Z positions, with **2–3 unit gaps** between them so the player has to jump. Lay them out roughly in a winding line away from the start. Vary heights slightly (±0.5 units) for visual interest, but not enough to make jumps impossible.
- **PlayerStart** (`Marker3D`) — positioned at the center of StartPlatform, ~1m above its top surface

Attach `scripts/level.gd` to the Level root.

### `scripts/level.gd` requirements

- `extends Node3D`
- `@export var player_scene: PackedScene` — drag `player.tscn` onto this in the editor
- `_ready()`:
  - Instance `player_scene`
  - Set the new player's `respawn_position` to `$PlayerStart.global_position`
  - Set the new player's `global_position` to `$PlayerStart.global_position`
  - `add_child(player)`

---

## Main Scene — `scenes/main.tscn`

Just a thin wrapper that loads the current level. This gives us a single seam to swap levels later.

- **Main** (`Node`) — root
  - Instance of `level_01.tscn` as a child

---

## HTML5 Export Preset

Configure (don't run) an HTML5 export preset:

- **Name:** `Web`
- **Export Path:** `builds/web/index.html`
- **Variant:** Regular (single-threaded — the default in 4.3+)
- **VRAM Texture Compression:** check "For Mobile"
- Save the preset. Don't worry if the actual export errors due to missing templates — we just want the preset configured for later.

---

## Verification Checklist

Run the project (F5) and confirm:

- [ ] Project opens in Godot 4.x without errors
- [ ] F5 launches the main scene
- [ ] Mouse is captured on launch; moving the mouse rotates the camera around the character
- [ ] Vertical mouse pitch is clamped (can't flip upside down)
- [ ] WASD moves the character relative to camera direction (W = away from camera, S = toward camera)
- [ ] Space jumps; gravity pulls the character back down
- [ ] Walking off a platform makes the character fall
- [ ] Falling far enough (Y < -20) respawns the character at the start platform with zero velocity
- [ ] Escape releases the mouse cursor
- [ ] No errors or warnings in the Output panel

---

## Do NOT
- Do **not** add a quiz, item store, slap mechanic, NPCs, coins, or balloons in this prompt — those are separate later prompts.
- Do **not** add a menu screen.
- Do **not** switch the renderer away from Compatibility.
- Do **not** import any external 3D models or audio files. White capsule placeholder is fine.
- Do **not** put player movement logic in the level script, or level-spawning logic in the player script. Keep responsibilities separated.

---

## When Done

1. Commit with message: `Bootstrap: 3rd-person character, first platforms, respawn-on-fall`
2. Update `CLAUDE.md` → **Current Features** section to reflect what now works
3. Move this prompt file from `prompts/ready/` to `prompts/done/`
