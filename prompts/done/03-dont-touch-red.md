# 03 — Don't Touch Red: Hazard Tiles + Tile Grid

> Before starting, read `CLAUDE.md` in the project root. The previous prompts (`01-bootstrap-character.md`, `02-quiz-gates.md` in `prompts/done/`) give you the existing player + level + quiz structure.

## Goal

Add the **"Don't Touch Red"** mechanic to `level_01`. Red tiles kill the player on contact (after a short 0.3s delay — quick enough to feel reflex-based, just enough escape window for skilled players). Safe tiles can be any non-red color. Two sub-sections are added after Gate 3:

1. **Stepping stones** — about 10 individual hazard tiles placed in a winding path with gaps between them. Player jumps tile-to-tile, avoiding reds.
2. **Tile grid** — a wider continuous floor of tiles in a 6×6 pattern. Player walks across, avoiding red squares.

The existing `FinishPlatform` moves to *after* the tile grid so it remains the final destination of the level.

---

## Design Summary

- A reusable **HazardTile** scene (2 × 0.5 × 2 units) with an `is_red` boolean toggle.
  - `is_red = true` → bright red, lethal on contact (0.3s delay, then `queue_free()`).
  - `is_red = false` → randomly picks one of 4 safe colors (blue, yellow, green, purple).
- Stepping stones use individually-placed HazardTile instances in the editor.
- The tile grid uses a **RedTileGrid** scene whose script auto-spawns HazardTiles from a multi-line pattern string. Pattern format: rows separated by newlines, cells separated by spaces, `R` = red, `S` = safe. Easy for Axel to redesign by editing one string.

---

## Files

**Create:**
- `scripts/hazard_tile.gd`
- `scenes/hazard/hazard_tile.tscn`
- `scripts/red_tile_grid.gd`
- `scenes/hazard/red_tile_grid.tscn`

**Modify:**
- `scenes/levels/level_01.tscn` — add Reconverge3, the stepping stones, MidPlatform, the RedTileGrid, and reposition FinishPlatform to be after the grid

---

## HazardTile Scene — `scenes/hazard/hazard_tile.tscn`

Tree:

- **HazardTile** (`StaticBody3D`) — root, attach `scripts/hazard_tile.gd`
  - **Mesh** (`MeshInstance3D`) — `BoxMesh`, size `(2, 0.5, 2)`. Default material is a plain white `StandardMaterial3D` (the script overrides it at runtime with the right color).
  - **CollisionShape3D** — `BoxShape3D`, size `(2, 0.5, 2)`
  - **DetectionArea** (`Area3D`) — at local position `(0, 0.75, 0)` (just above the tile top)
    - **CollisionShape3D** — `BoxShape3D`, size `(2, 1, 2)`

---

## HazardTile Script — `scripts/hazard_tile.gd`

```gdscript
extends StaticBody3D
class_name HazardTile

const RED_COLOR := Color(1.0, 0.15, 0.15)
const SAFE_COLORS := [
    Color(0.4, 0.6, 1.0),  # blue
    Color(1.0, 1.0, 0.3),  # yellow
    Color(0.4, 1.0, 0.4),  # green
    Color(0.7, 0.4, 1.0),  # purple
]

@export var is_red: bool = false
@export var fall_delay: float = 0.3

var _triggered: bool = false

func _ready() -> void:
    _apply_color()
    $DetectionArea.body_entered.connect(_on_player_entered)

func _apply_color() -> void:
    var mat := StandardMaterial3D.new()
    if is_red:
        mat.albedo_color = RED_COLOR
    else:
        mat.albedo_color = SAFE_COLORS[randi() % SAFE_COLORS.size()]
    $Mesh.set_surface_override_material(0, mat)

func _on_player_entered(body: Node3D) -> void:
    if _triggered or not is_red or not body.is_in_group("player"):
        return
    _triggered = true
    await get_tree().create_timer(fall_delay).timeout
    queue_free()
```

**Editor caveat:** because the color is applied in `_ready()` at runtime, tiles will all appear white in the editor regardless of `is_red`. Use the **Inspector** to verify each tile's `is_red` value. (We can add a `@tool` decorator for live editor preview later if it becomes a pain.)

---

## RedTileGrid Scene — `scenes/hazard/red_tile_grid.tscn`

Tree:

- **RedTileGrid** (`Node3D`) — root, attach `scripts/red_tile_grid.gd`

That's the entire scene — tiles are spawned dynamically from the pattern.

---

## RedTileGrid Script — `scripts/red_tile_grid.gd`

```gdscript
extends Node3D

const HAZARD_TILE := preload("res://scenes/hazard/hazard_tile.tscn")
const TILE_SIZE := 2.0

# Pattern: rows separated by newlines, cells separated by spaces.
# 'R' = red (lethal), 'S' (or anything else non-empty) = safe.
@export_multiline var pattern: String = """
S S R R S S
R S S R S S
R S R S S R
S S S S R S
S R R S S S
S S S R S S
"""

func _ready() -> void:
    _build_grid()

func _build_grid() -> void:
    var rows := pattern.strip_edges().split("\n", false)
    for z_idx in rows.size():
        var row_str: String = rows[z_idx].strip_edges()
        if row_str.is_empty():
            continue
        var cells := row_str.split(" ", false)
        for x_idx in cells.size():
            var ch: String = cells[x_idx].strip_edges().to_upper()
            if ch.is_empty():
                continue
            var tile := HAZARD_TILE.instantiate()
            tile.is_red = (ch == "R")
            add_child(tile)
            tile.position = Vector3(x_idx * TILE_SIZE, 0, z_idx * TILE_SIZE)
```

The default pattern above has a navigable path from top to bottom — verify you can solve it by hand before testing.

---

## Level Layout — `scenes/levels/level_01.tscn`

Keep everything from the previous prompts intact (start, bootstrap platforms, the three quiz gates and their reconverges). The new section goes **after Gate 3**. The existing `FinishPlatform` moves to the very end.

**Insert in this order, all roughly along the same forward axis the level already extends in:**

1. **Reconverge3** — `StaticBody3D` platform, size `(8, 0.5, 4)`, plain neutral color, ~6 units forward of Gate 3's origin so it's reachable from either Gate 3 platform.
2. **Stepping stones** — 10 instances of `hazard_tile.tscn`, arranged in a winding path forward from Reconverge3 with **2–3 unit gaps** between consecutive tiles. About **4 of them red, 6 safe**. Layout guidance:
   - The path should weave a bit (e.g., zigzag left-right) so it's not just a straight line of jumps.
   - There must be a navigable safe-only route through the section. Don't put a red tile in a position where the player has no choice but to land on it.
   - Vary which side the red tiles are on so the player has to look ahead and plan.
3. **MidPlatform** — `StaticBody3D` platform, size `(8, 0.5, 4)`, neutral color, placed so the last stepping stone lands the player on it after one more jump.
4. **RedTileGrid** — instance of `red_tile_grid.tscn`, positioned so its first row (z_idx 0) is reachable by walking straight off MidPlatform. The grid's 6×6 of 2-unit tiles spans 12×12 units total.
5. **FinishPlatform** — move from its previous position to right after the tile grid (~3 units forward of the grid's last row). Keep its existing size, green color, and "FINISH!" Label3D.

**Vertical alignment:** keep all of these at the same Y level as the existing platforms (top surface at Y = 0.25). No height variation in this section yet.

---

## Verification Checklist

- [ ] Project runs without errors
- [ ] Walking onto a red stepping stone: it stays solid for ~0.3s, then disappears. If the player is still on it, they fall and respawn at start.
- [ ] If the player jumps off a red stone in time (within 0.3s), they survive — confirms the escape window works.
- [ ] Walking onto a safe stepping stone: nothing happens, the player can continue.
- [ ] The 4 safe colors (blue, yellow, green, purple) appear randomly across safe tiles each time the level loads.
- [ ] At the tile grid: walking onto a red tile triggers the same 0.3s + vanish behavior.
- [ ] The default pattern has a navigable path from top to bottom — verify by playing through.
- [ ] Editing the `pattern` string on the RedTileGrid instance and re-running rebuilds the grid with the new layout.
- [ ] After the tile grid, FinishPlatform is reachable and "FINISH!" floats above it.
- [ ] No console errors or warnings.

---

## Do NOT
- Do **not** add particle effects, sound effects, screen shake, or animations to the falling tiles — keep it visually simple, polish comes later.
- Do **not** add a level-end UI / "Level Complete" screen yet.
- Do **not** add health, lives, or hurt-without-killing — for now any red tile fall-through respawns at the level start (the existing respawn-on-fall logic handles this; don't add new player code).
- Do **not** modify `player.gd` or the existing quiz gate code.
- Do **not** add the slap mechanic, store, or coins in this prompt.

---

## When Done

1. Commit with message: `Don't Touch Red: hazard tiles, stepping stones, and tile grid in level_01`
2. Update `CLAUDE.md`:
   - **Current Features**: add "Hazard tiles (Don't Touch Red mechanic) — stepping stones and pattern-based tile grids; red kills with 0.3s delay"
   - **Planned / In-Progress Features**: this section can move toward "done" status, but note that audio, particle FX, and difficulty progression remain planned.
3. Move this prompt file from `prompts/ready/` to `prompts/done/`
