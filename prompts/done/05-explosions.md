# 05 — Explosions: Particle Burst + Light Flash + Camera Shake

> Before starting, read `CLAUDE.md` in the project root.

## Goal

Replace the silent `queue_free()` on **wrong quiz platforms** and **red hazard tiles** with a satisfying explosion: a burst of particles (red core + orange embers), a brief bright light flash, and a quick camera shake. Same explosion scene triggered from both places.

This is purely visual feedback — no gameplay changes.

---

## Design Summary

- One reusable **Explosion** scene (`scenes/effects/explosion.tscn`) used by both hazard tiles and quiz wrong platforms.
- Two `CPUParticles3D` emitters inside the explosion:
  - **Core** — slower, larger red particles for the fireball center
  - **Embers** — fast, small orange particles that fly outward and fall with gravity
- Brief **OmniLight3D** flash that tweens from bright down to 0 over 0.4s.
- **Camera shake** triggered on the player — small position offset on the Camera3D node, fades out over 0.25s.
- Explosion self-destroys after 1.5s (after particles have fully completed).
- Use `CPUParticles3D` not `GPUParticles3D` — GPU particles can be unreliable in the Compatibility renderer used for web export.

---

## Files

**Create:**
- `scripts/explosion.gd`
- `scenes/effects/explosion.tscn`

**Modify:**
- `scripts/player.gd` — add `shake_camera()` method and per-frame shake update
- `scripts/hazard_tile.gd` — spawn an Explosion before `queue_free()`
- `scripts/quiz_gate.gd` — spawn an Explosion before `queue_free()` on the wrong platform

---

## Explosion Scene — `scenes/effects/explosion.tscn`

Tree:

- **Explosion** (`Node3D`) — root, attach `scripts/explosion.gd`
  - **Core** (`CPUParticles3D`) — properties configured by script in `_ready()`
  - **Embers** (`CPUParticles3D`) — properties configured by script in `_ready()`
  - **Light** (`OmniLight3D`) — properties configured by script in `_ready()`

The scene only needs the node tree — all particle/light properties are set in script so the configuration is visible and tweakable in code.

---

## Explosion Script — `scripts/explosion.gd`

```gdscript
extends Node3D

const SHAKE_INTENSITY := 0.1
const SHAKE_DURATION := 0.25
const LIFETIME := 1.5

func _ready() -> void:
    _setup_core()
    _setup_embers()
    _setup_light()
    _shake_camera()
    await get_tree().create_timer(LIFETIME).timeout
    queue_free()

func _setup_core() -> void:
    var core: CPUParticles3D = $Core
    var sphere := SphereMesh.new()
    sphere.radius = 0.3
    sphere.height = 0.6
    core.mesh = sphere
    core.amount = 30
    core.lifetime = 0.5
    core.one_shot = true
    core.explosiveness = 1.0
    core.direction = Vector3(0, 1, 0)
    core.spread = 180.0
    core.initial_velocity_min = 1.0
    core.initial_velocity_max = 3.0
    core.gravity = Vector3.ZERO
    core.scale_amount_min = 1.0
    core.scale_amount_max = 1.5
    core.color = Color(1.0, 0.2, 0.1)  # deep red
    core.emitting = true

func _setup_embers() -> void:
    var embers: CPUParticles3D = $Embers
    var sphere := SphereMesh.new()
    sphere.radius = 0.08
    sphere.height = 0.16
    embers.mesh = sphere
    embers.amount = 50
    embers.lifetime = 1.0
    embers.one_shot = true
    embers.explosiveness = 1.0
    embers.direction = Vector3(0, 1, 0)
    embers.spread = 180.0
    embers.initial_velocity_min = 4.0
    embers.initial_velocity_max = 8.0
    embers.gravity = Vector3(0, -8, 0)  # embers fall
    embers.scale_amount_min = 0.5
    embers.scale_amount_max = 1.0
    embers.color = Color(1.0, 0.6, 0.0)  # orange
    embers.emitting = true

func _setup_light() -> void:
    var light: OmniLight3D = $Light
    light.omni_range = 8.0
    light.light_color = Color(1.0, 0.5, 0.2)
    light.light_energy = 4.0
    var tween := create_tween()
    tween.tween_property(light, "light_energy", 0.0, 0.4)

func _shake_camera() -> void:
    for p in get_tree().get_nodes_in_group("player"):
        if p.has_method("shake_camera"):
            p.shake_camera(SHAKE_INTENSITY, SHAKE_DURATION)
```

---

## Player Script Changes — `scripts/player.gd`

**Add** (do not replace existing code) the following:

### At the top of the script (after existing constants/properties):

```gdscript
@onready var _camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
var _camera_origin: Vector3
var _shake_timer := 0.0
var _shake_intensity := 0.0
var _shake_duration := 0.0
```

### One line added to existing `_ready()`:

```gdscript
_camera_origin = _camera.position
```

(Add this after the existing `Input.mouse_mode = ...` line.)

### New public method:

```gdscript
func shake_camera(intensity: float, duration: float) -> void:
    _shake_intensity = intensity
    _shake_duration = duration
    _shake_timer = duration
```

### New `_process()` function (does not exist yet — add it):

```gdscript
func _process(delta: float) -> void:
    if _shake_timer > 0.0:
        _shake_timer -= delta
        var t := clamp(_shake_timer / _shake_duration, 0.0, 1.0)
        var amount := _shake_intensity * t
        _camera.position = _camera_origin + Vector3(
            randf_range(-amount, amount),
            randf_range(-amount, amount),
            0.0  # keep Z fixed so distance to player doesn't pulse
        )
    elif _camera.position != _camera_origin:
        _camera.position = _camera_origin
```

Do **not** modify `_unhandled_input` or `_physics_process` — they stay exactly as they are.

---

## HazardTile Script Changes — `scripts/hazard_tile.gd`

### At the top, add the preload constant:

```gdscript
const EXPLOSION_SCENE := preload("res://scenes/effects/explosion.tscn")
```

### Modify `_on_player_entered`:

Spawn the explosion **before** `queue_free()`:

```gdscript
func _on_player_entered(body: Node3D) -> void:
    if _triggered or not is_red or not body.is_in_group("player"):
        return
    _triggered = true
    await get_tree().create_timer(fall_delay).timeout
    _spawn_explosion()
    queue_free()
```

### New helper:

```gdscript
func _spawn_explosion() -> void:
    var explosion := EXPLOSION_SCENE.instantiate()
    get_tree().current_scene.add_child(explosion)
    explosion.global_position = global_position + Vector3(0, 0.5, 0)
```

**Critical:** add the explosion to `get_tree().current_scene`, not as a child of the tile — the tile is about to `queue_free()` and would take its children with it.

---

## QuizGate Script Changes — `scripts/quiz_gate.gd`

### At the top, add the preload constant:

```gdscript
const EXPLOSION_SCENE := preload("res://scenes/effects/explosion.tscn")
```

### Modify `_trigger_wrong`:

Spawn explosion at the platform's position **before** `queue_free()`:

```gdscript
func _trigger_wrong(platform: StaticBody3D) -> void:
    if _wrong_triggered: return
    _wrong_triggered = true
    var mesh: MeshInstance3D = platform.get_node("Mesh")
    var red_mat := StandardMaterial3D.new()
    red_mat.albedo_color = Color.RED
    mesh.set_surface_override_material(0, red_mat)
    await get_tree().create_timer(explode_delay).timeout
    _spawn_explosion(platform.global_position)
    platform.queue_free()
```

### New helper:

```gdscript
func _spawn_explosion(pos: Vector3) -> void:
    var explosion := EXPLOSION_SCENE.instantiate()
    get_tree().current_scene.add_child(explosion)
    explosion.global_position = pos + Vector3(0, 0.5, 0)
```

---

## Verification Checklist

- [ ] Walking onto a red hazard tile: tile vanishes after 0.3s **and** an explosion plays (red core + orange embers fanning out, brief flash of light, camera shakes)
- [ ] Embers fall with gravity (you can see them arc downward), core particles linger briefly then fade
- [ ] OmniLight3D lights up nearby surfaces orange for ~0.4s then fades
- [ ] Camera shake is brief (~0.25s) and noticeable but not nauseating — try standing right next to a tile when it explodes vs across the level
- [ ] Same effect plays when landing on a wrong quiz platform after the 1.5s warning
- [ ] No leftover Explosion nodes in the scene tree after a few seconds — they self-destroy
- [ ] No errors or warnings in the Output panel
- [ ] Test on the Vercel deploy (push after this prompt is done) — particles still work in browser. If particles don't render in WebGL, that's the GPU vs CPU particle gotcha; confirm we're using `CPUParticles3D`.

---

## Do NOT
- Do **not** use `GPUParticles3D` — they have known issues in the Compatibility renderer / WebGL 2.0.
- Do **not** add particle textures or 3D models for debris yet — `SphereMesh` is fine, keeping it simple.
- Do **not** add explosion sound effects in this prompt — that comes in the audio pass later.
- Do **not** modify the existing detection logic on hazard tiles or quiz gates — only add the explosion spawn before `queue_free()`.
- Do **not** add explosions to safe tiles, correct quiz platforms, or any other surface.

---

## When Done

1. Commit with message: `Explosions: particle burst, light flash, camera shake on red tiles and wrong quiz platforms`
2. Update `CLAUDE.md`:
   - **Current Features**: add "Explosion FX (CPU particles + light + camera shake) on red tile and wrong quiz triggers"
3. Move this prompt file from `prompts/ready/` to `prompts/done/`
4. Re-export the web build and `git push` to trigger the auto-deploy (`godot --headless --export-release "Web" builds/web/index.html`, then `git add . && git commit && git push`)
