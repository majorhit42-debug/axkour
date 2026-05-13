# 06 — Golden Zone: Coin Pickups, Wallet, HUD, Lose-on-Death

> Before starting, read `CLAUDE.md` in the project root.

## Goal

Add a **golden zone** to `level_01` — a challenging parkour section just before the FinishPlatform. Six gold-tinted platforms with bigger gaps between them, each carrying one spinning gold coin. Collecting coins fills a wallet (shown in the HUD); falling and respawning loses **1–3 random coins** from the wallet (capped to current balance so it never goes negative).

This is the foundation for the entire economy (store, cosmetics, slap, balloons, etc., all come later).

---

## Design Summary

- **CoinWallet** as a Godot autoload singleton — global state, persists across deaths and level reloads.
- Each **Coin** is an `Area3D` that detects player overlap, plays a small gold sparkle effect, increments the wallet, and queue_frees. **One-time collect** — once grabbed, gone from the world for the session.
- Coins look like classic spinning gold discs (thin `CylinderMesh`, gold material, rotating around Y axis).
- On player death (fall below `RESPAWN_Y`), the wallet loses a random 1–3 coins (clamped at 0).
- **HUD** lives in `main.tscn` as a `CanvasLayer` sibling of the level — persists when levels swap later. Shows "Coins: N" in the corner.
- **Sparkle** effect uses one `CPUParticles3D` — reusable for future celebrations (level complete, store purchase, etc.).
- Golden zone platforms are **3×0.5×3** (smaller than other platforms), tinted gold to visually mark the zone.
- Gaps between golden platforms are **4–5 units** with height variation — requires real jumping skill.

---

## Files

**Create:**
- `scripts/coin_wallet.gd` (autoload)
- `scripts/coin.gd`
- `scenes/coin/coin.tscn`
- `scripts/sparkle.gd`
- `scenes/effects/sparkle.tscn`
- `scripts/hud.gd`
- `scenes/ui/hud.tscn`

**Modify:**
- `project.godot` — register CoinWallet autoload
- `scripts/player.gd` — call `CoinWallet.lose_random_coins()` on respawn
- `scenes/main.tscn` — add HUD as a sibling of the level instance
- `scenes/levels/level_01.tscn` — insert golden zone between tile grid and FinishPlatform; reposition FinishPlatform

---

## CoinWallet — `scripts/coin_wallet.gd` (Autoload Singleton)

```gdscript
extends Node
# Autoloaded as "CoinWallet" — see project.godot

signal coin_count_changed(new_count: int)

const MIN_LOSS_ON_DEATH := 1
const MAX_LOSS_ON_DEATH := 3

var coins: int = 0

func add_coins(amount: int) -> void:
    coins += amount
    coin_count_changed.emit(coins)

func lose_random_coins() -> int:
    if coins <= 0:
        return 0
    var loss := randi_range(MIN_LOSS_ON_DEATH, MAX_LOSS_ON_DEATH)
    loss = min(loss, coins)
    coins -= loss
    coin_count_changed.emit(coins)
    return loss

func reset() -> void:
    coins = 0
    coin_count_changed.emit(coins)
```

### Register the autoload

In `project.godot`, add (or merge into) an `[autoload]` section:

```
[autoload]
CoinWallet="*res://scripts/coin_wallet.gd"
```

The `*` makes it globally accessible. After this, `CoinWallet.coins`, `CoinWallet.add_coins(1)`, etc. work from any script.

---

## Coin Scene — `scenes/coin/coin.tscn`

Tree:

- **Coin** (`Area3D`) — root, attach `scripts/coin.gd`
  - **CollisionShape3D** — `SphereShape3D`, radius `0.5` (pickup detection volume)
  - **Mesh** (`MeshInstance3D`) — Mesh and material configured by script; rotation set in script to orient the disc edge-on

---

## Coin Script — `scripts/coin.gd`

```gdscript
extends Area3D
class_name Coin

const SPARKLE_SCENE := preload("res://scenes/effects/sparkle.tscn")
const ROTATION_SPEED := 4.0  # radians per second

var _collected: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    _setup_visual()

func _setup_visual() -> void:
    var cyl := CylinderMesh.new()
    cyl.height = 0.1
    cyl.top_radius = 0.4
    cyl.bottom_radius = 0.4
    $Mesh.mesh = cyl
    # Orient the cylinder so its flat face is visible from the side (coin "stands up")
    $Mesh.rotation = Vector3(0, 0, PI / 2)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(1.0, 0.85, 0.1)
    mat.metallic = 1.0
    mat.roughness = 0.2
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.7, 0.1)
    mat.emission_energy_multiplier = 0.4
    $Mesh.set_surface_override_material(0, mat)

func _process(delta: float) -> void:
    if _collected:
        return
    rotate_y(ROTATION_SPEED * delta)

func _on_body_entered(body: Node3D) -> void:
    if _collected or not body.is_in_group("player"):
        return
    _collected = true
    CoinWallet.add_coins(1)
    _spawn_sparkle()
    queue_free()

func _spawn_sparkle() -> void:
    var sparkle := SPARKLE_SCENE.instantiate()
    get_tree().current_scene.add_child(sparkle)
    sparkle.global_position = global_position
```

---

## Sparkle Scene — `scenes/effects/sparkle.tscn`

Tree:

- **Sparkle** (`Node3D`) — root, attach `scripts/sparkle.gd`
  - **Particles** (`CPUParticles3D`) — properties configured by script in `_ready()`

---

## Sparkle Script — `scripts/sparkle.gd`

```gdscript
extends Node3D

const LIFETIME := 1.0

func _ready() -> void:
    _setup_particles()
    await get_tree().create_timer(LIFETIME).timeout
    queue_free()

func _setup_particles() -> void:
    var p: CPUParticles3D = $Particles
    var sphere := SphereMesh.new()
    sphere.radius = 0.05
    sphere.height = 0.1
    p.mesh = sphere
    p.amount = 15
    p.lifetime = 0.6
    p.one_shot = true
    p.explosiveness = 1.0
    p.direction = Vector3(0, 1, 0)
    p.spread = 90.0
    p.initial_velocity_min = 2.0
    p.initial_velocity_max = 4.0
    p.gravity = Vector3(0, -3, 0)
    p.scale_amount_min = 0.5
    p.scale_amount_max = 1.0
    p.color = Color(1.0, 0.9, 0.3)
    p.emitting = true
```

---

## HUD Scene — `scenes/ui/hud.tscn`

Tree:

- **HUD** (`CanvasLayer`) — root, attach `scripts/hud.gd`
  - **CoinCounter** (`Control`)
    - Set `anchors_preset` to "Top Right Wide" or anchor it to top-right corner
    - **Label** (`Label`)
      - `text = "Coins: 0"`
      - Position so it appears with ~20px margin from top and right
      - Add a theme override or font color: gold (`Color(1.0, 0.85, 0.1)`)
      - Add an outline override (`outline_size = 4`, `outline_color = BLACK`) so it's readable on any background
      - `font_size = 32`

The exact `Control` layout details matter less than: the label needs to be in the top-right corner, readable on any background, and large enough to glance at while playing.

---

## HUD Script — `scripts/hud.gd`

```gdscript
extends CanvasLayer

@onready var _coin_label: Label = $CoinCounter/Label

func _ready() -> void:
    CoinWallet.coin_count_changed.connect(_on_coin_count_changed)
    _on_coin_count_changed(CoinWallet.coins)

func _on_coin_count_changed(new_count: int) -> void:
    _coin_label.text = "Coins: %d" % new_count
```

---

## Main Scene Update — `scenes/main.tscn`

Add an instance of `hud.tscn` as a **sibling** of the level instance under the Main root.

Result:

- **Main** (`Node`)
  - level_01 (existing instance)
  - HUD (new instance of `hud.tscn`)

The HUD persists when levels swap later, because it lives in Main, not in the level.

---

## Player Script Changes — `scripts/player.gd`

In `_physics_process`, the existing respawn block looks roughly like:

```gdscript
if global_position.y < RESPAWN_Y:
    global_position = respawn_position
    velocity = Vector3.ZERO
```

**Add one line** at the start of that block to lose coins on death:

```gdscript
if global_position.y < RESPAWN_Y:
    CoinWallet.lose_random_coins()
    global_position = respawn_position
    velocity = Vector3.ZERO
```

Do not change anything else in `player.gd`.

---

## Level Layout — `scenes/levels/level_01.tscn`

Currently after the RedTileGrid is the FinishPlatform. **Move FinishPlatform back to make room for the Golden Zone between the tile grid and the finish.**

Insert in this order, after the tile grid, before the FinishPlatform:

1. **GoldenApproach** — a normal platform (size `(6, 0.5, 4)`, neutral color), placed so the player can transition from the tile grid onto it.

2. **6 golden platforms**, each `(3, 0.5, 3)`, tinted gold (`Color(1.0, 0.85, 0.1)`):
   - **Gaps of 4–5 units** between consecutive platforms (challenging — requires running jumps).
   - **Height variation**: alternate between two Y levels (e.g., `Y=0` and `Y=1.5`), or step up then back down. Avoid making the jumps impossible — a player who's good at jumping should be able to clear them.
   - **Some lateral offset** (left/right by 1–2 units) on a few jumps to make them diagonal — adds challenge.
   - Layout doesn't have to be perfectly linear; it can curve or zigzag to make the section feel like a real parkour challenge.

3. **6 coins**, one per golden platform. Each coin is an instance of `coin.tscn`, positioned centered above its platform's top surface (`platform_position + Vector3(0, 1.0, 0)` works — puts the coin about 0.75 units above the platform top, where the player will easily walk through it).

4. **FinishPlatform** — moved to after the last golden platform, ~5 units forward. Keep its existing size, green color, and "FINISH!" Label3D.

---

## Verification Checklist

- [ ] On launch, the HUD shows "Coins: 0" in the top-right corner.
- [ ] Coins spin smoothly above each golden platform.
- [ ] Coins are tinted gold with a slight emission glow.
- [ ] Walking through a coin: it disappears, a small gold sparkle plays, HUD increments by 1.
- [ ] Collected coins do **not** respawn on death — they stay gone for the session.
- [ ] Falling into the void: HUD decrements by 1–3 (random). If wallet is 0, stays at 0 (no negative).
- [ ] The golden platforms feel challenging — gaps require real jumps. Test by deliberately failing some jumps to confirm the lose-coins-on-death loop.
- [ ] FinishPlatform is reachable after the golden zone.
- [ ] No errors or warnings in the Output panel.
- [ ] Test the Vercel deploy after pushing — HUD renders in browser, coins collect, wallet decrements on death.

---

## Do NOT
- Do **not** make collected coins respawn after death — Todd specifically chose one-time collect.
- Do **not** add a store / spending mechanic in this prompt — that's the next prompt in v0.2.
- Do **not** add coin pickup sound effects — audio pass is a later prompt.
- Do **not** add "Lost X coins" toast messages on death — keep the HUD simple for now; can add visual feedback later if it feels needed.
- Do **not** save the wallet to disk yet — runtime-only state is fine for v0.2.
- Do **not** add coins to non-golden platforms (no coins on bootstrap, quiz, red tile, or finish platforms).

---

## When Done

1. Commit with message: `Golden zone: coin pickups, wallet singleton, HUD counter, lose-coins-on-death`
2. Update `CLAUDE.md`:
   - **Current Features**: add "Coin pickups with wallet singleton, HUD counter, lose 1–3 coins on fall; golden parkour zone with challenging jumps"
   - **Planned / In-Progress Features → Golden Parkour**: mark the basics as done; coin persistence-across-sessions (save to disk) and shop integration remain planned.
3. Move this prompt file from `prompts/ready/` to `prompts/done/`
4. Re-export the web build and `git push` to trigger the auto-deploy.
