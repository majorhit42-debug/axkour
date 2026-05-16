# Prompt 13 — Loud Poppable Balloons

> **Best after prompt 12** (X Bot integration) so the throw can originate from the character's hand bone. Works without it — fall back to a position offset from the player.
>
> **Works regardless of prompt 08** (hub). The balloon pedestal goes "in the shop" — wherever the shop currently lives.

## Goal
Add balloons as a refillable consumable item: buy 10 at a time from the shop, carry them in inventory, tap a button to drop one at your feet, hold the same button to charge and release for an arcing throw. Balloons pop on contact with anything dynamic (player, other balloons, future slaps/bots) with a LOUD pop and a confetti burst. Static geometry (floor, walls, platforms) does NOT pop them — balloons rest on the ground when dropped.

## Detailed Requirements

### Consumable inventory support (`scripts/item_inventory.gd`)

The current ItemInventory handles equippable items (skins, hats). Extend it to track consumables (quantities).

Additions:
- New dictionary: `var consumable_quantities: Dictionary = {}` (e.g. `{"balloon": 7}`)
- New signal: `signal consumable_count_changed(item_id: String, new_count: int)`
- New methods:
  - `add_consumable(item_id: String, amount: int) -> void` — adds amount, emits signal
  - `use_consumable(item_id: String) -> bool` — decrements by 1 if available, returns success, emits signal
  - `get_consumable_count(item_id: String) -> int` — returns current count (0 if absent)

The existing `try_purchase()` should detect consumable items and call `add_consumable` instead of `grant` (see catalog change below).

### Shop catalog (`assets/shop_items.json`)

Add a balloon entry:
```json
{
  "id": "balloon",
  "display_name": "Balloons (10x)",
  "type": "consumable",
  "quantity_per_purchase": 10,
  "cost": 2,
  "color": "#ff66aa"
}
```

Add a `"type"` field to existing items: `"equippable"` for skins/hats (existing behavior), `"consumable"` for balloons. Default to "equippable" if absent so existing items don't break.

In `ItemInventory.try_purchase()`:
- If item is equippable → existing flow (grant ownership)
- If item is consumable → spend the cost, call `add_consumable(id, quantity_per_purchase)`. Allow re-purchase any time (refill).

### Balloon pedestal

Add a balloon pedestal to the shop area (current StartPlatform shop in level_01, OR the hub pavilion if prompt 08 has run — wherever existing pedestals live):
- Reuse the existing Pedestal scene
- Position: one new pedestal alongside the existing hat/skin rows
- Display item: a balloon mesh (built at runtime, same pattern as how skin/hat pedestals build their display items)
- Label format: "Balloons (10x) — 2 coins" (label should reflect consumable nature)
- E (or gamepad A) within proximity: deducts 2 coins, adds 10 balloons to inventory, plays the existing sparkle effect

### Balloon scene (`scenes/items/balloon.tscn`)

Root: `RigidBody3D` named `Balloon`

Children:
- `Body` (MeshInstance3D) — SphereMesh, radius 0.18, with StandardMaterial3D
  - Color: assigned at runtime from a palette (red, blue, yellow, green, pink, orange, purple)
  - Slight roughness (~0.4) so it has a sheen
- `Knot` (MeshInstance3D) — small ConeMesh (radius 0.06, height 0.04), positioned at bottom of body, same color as body
- `String` (MeshInstance3D) — CylinderMesh (top radius 0.002, bottom radius 0.002, height 0.4), hanging from knot, dark grey color
- `CollisionShape3D` — SphereShape3D, radius 0.18 (matches body)
- `Area3D` named `PopTrigger`
  - Larger SphereShape3D (radius 0.22) — slightly bigger than the physical collision so contact triggers reliably
  - `body_entered` connected to balloon's pop handler

### RigidBody3D physics tuning
- `mass`: 0.1
- `gravity_scale`: 0.3 (balloons fall slowly — light, floaty)
- `linear_damp`: 0.8 (air resistance)
- `angular_damp`: 1.0
- `continuous_cd`: true (prevents thrown balloons from tunneling through walls)
- `collision_layer`: bit 4 (new "balloons" layer)
- `collision_mask`: bit 1 (world geometry) + bit 4 (other balloons)

### Balloon script (`scripts/balloon.gd`)

```gdscript
extends RigidBody3D

@export var placer: Node3D = null  # the player who placed this — currently unused, future combat will respect this

var _popped: bool = false

func _ready() -> void:
    # Random color from palette
    var palette = [Color(1,0.3,0.3), Color(0.3,0.5,1), Color(1,1,0.3), 
                   Color(0.3,1,0.4), Color(1,0.4,0.7), Color(1,0.6,0.2), Color(0.7,0.3,1)]
    var c: Color = palette[randi() % palette.size()]
    # Apply to Body and Knot materials
    # ... (build StandardMaterial3D with albedo = c, assign as override)
    $PopTrigger.body_entered.connect(_on_pop_trigger)

func _on_pop_trigger(body: Node) -> void:
    if _popped:
        return
    # Pop on any RigidBody3D or CharacterBody3D (dynamic things) — NOT StaticBody3D (floor/walls)
    if body is StaticBody3D:
        return
    pop()

func pop() -> void:
    _popped = true
    # Spawn pop effect at this position
    var pop_fx = preload("res://scenes/effects/balloon_pop.tscn").instantiate()
    get_tree().current_scene.add_child(pop_fx)
    pop_fx.global_position = global_position
    queue_free()
```

### Pop effect (`scenes/effects/balloon_pop.tscn`)

Root: Node3D named `BalloonPop`
Children:
- `Sound` (AudioStreamPlayer3D) — loads `assets/audio/balloon_pop.ogg`, autoplay on, max_distance 30, unit_db 0
- `Confetti` (CPUParticles3D):
  - `emitting = false` initially, fire via `restart()` in `_ready()` (same one-shot fix as explosion)
  - 40 particles, lifetime 1.2s, one_shot = true
  - `direction` upward, `spread` 90°
  - `initial_velocity_min/max` = 2.0 / 5.0
  - `gravity` = (0, -9.8, 0)
  - `mesh`: small BoxMesh (0.04 × 0.04 × 0.01) for confetti squares
  - `color_ramp`: multi-color gradient cycling through party colors
  - `angular_velocity_min/max` = -360 / 360 (tumbling)
- Auto-destruct: `Timer` 1.5s → `queue_free()` (lets sound and particles finish)

### Audio asset (Todd supplies)

**A loud balloon pop sound** at `assets/audio/balloon_pop.ogg`. Suggested: short (under 1s), genuinely percussive, no excessive reverb. Freesound.org has many — search "balloon pop" and pick the one that sounds most like a real party balloon. Flag this BEFORE running the prompt.

### Input action

Add to `project.godot` input map:
- Action: `drop_throw_balloon`
- Keyboard: `Q`
- Gamepad: Right Bumper (joypad button index 5 on Xbox)

### Player drop/throw logic (`scripts/player.gd`)

State variables:
- `var _balloon_button_held_time: float = 0.0`
- `var _balloon_button_pressed: bool = false`
- Constant: `DROP_THRESHOLD = 0.15` (seconds — press shorter than this = drop, longer = throw with charge)
- Constant: `MAX_CHARGE_TIME = 1.0` (additional seconds beyond threshold to reach max throw strength)

Input handling (in `_process` or `_physics_process`):
```gdscript
if Input.is_action_just_pressed("drop_throw_balloon"):
    _balloon_button_pressed = true
    _balloon_button_held_time = 0.0
elif Input.is_action_pressed("drop_throw_balloon") and _balloon_button_pressed:
    _balloon_button_held_time += delta
elif Input.is_action_just_released("drop_throw_balloon") and _balloon_button_pressed:
    _balloon_button_pressed = false
    if ItemInventory.get_consumable_count("balloon") <= 0:
        return  # no balloons, do nothing
    if _balloon_button_held_time < DROP_THRESHOLD:
        _drop_balloon()
    else:
        var charge: float = clamp((_balloon_button_held_time - DROP_THRESHOLD) / MAX_CHARGE_TIME, 0.0, 1.0)
        _throw_balloon(charge)
    ItemInventory.use_consumable("balloon")
```

**Drop:**
- Spawn balloon scene
- Position: ~0.5 units in front of and slightly above the player (so it doesn't clip into the player capsule)
- Initial velocity: zero (lets gravity take over)
- Add to `current_scene`

**Throw:**
- Spawn balloon at the same starting position (or, ideally, at the player's hand bone if X Bot integration is done — use `BoneAttachment3D` on `mixamorig:RightHand` to get hand position)
- Compute throw vector:
  - Forward direction (from camera or player facing): horizontal component
  - Upward component: 0.4 of forward magnitude (arc shape)
  - Magnitude: `lerp(4.0, 12.0, charge)` (minimum throw is 4 units/sec forward, max is 12)
- Apply via `balloon.apply_central_impulse(throw_vector * balloon.mass)`

### HUD balloon counter

In `scenes/ui/hud.tscn` (and its script):
- Add a Label below or beside the existing coin counter: `🎈 N` (using a balloon emoji works; if rendering breaks, use "Balloons: N")
- Font size 28, pink/magenta tint with black outline (matches balloon theme)
- Subscribe to `ItemInventory.consumable_count_changed` signal — update label when balloon count changes
- Visible only when count > 0 (hide otherwise to reduce HUD clutter)

## Verification

1. Walk to the shop, find the balloon pedestal — label reads "Balloons (10x) — 2 coins"
2. Press E to buy → coin count drops by 2, sparkle effect plays, HUD shows "🎈 10"
3. Tap **Q** (or RB) → a colored balloon drops at your feet, falls slowly, comes to rest on the ground, doesn't pop. HUD shows "🎈 9"
4. Hold **Q** for ~0.5s and release → balloon arcs forward, lands further away. HUD shows "🎈 8"
5. Hold **Q** for ~1.5s and release → balloon throws much farther
6. Walk into a placed balloon → LOUD pop sound, confetti burst, balloon disappears
7. Throw a balloon at another placed balloon → both pop on contact
8. Drop several balloons in a pile (they don't pop each other on initial spawn since they're spaced apart by physics)
9. Try to drop when count is 0 → nothing happens (no balloon spawned, count stays 0, no error)
10. Re-purchase from pedestal → count refills to 10 + remaining

## Do NOT
- Do not pop on contact with `StaticBody3D` (floor, walls, platforms) — only dynamic bodies
- Do not implement damage to characters from popping — that's the v0.3 combat layer (Todd will add later via the `placer` field)
- Do not change skin or hat pedestal behavior — only ADD the balloon pedestal
- Do not make balloons float upward (helium) — they're party balloons, gentle fall
- Do not auto-pop balloons after a timer — only pop on contact
- Do not let the player throw if their balloon count is 0 (silent no-op)
- Do not add the balloon button to the existing E/interact action — use the new `drop_throw_balloon` action
- Do not modify CoinWallet
- Do not skip the audio asset check — confirm `assets/audio/balloon_pop.ogg` exists before running

## Files Involved

- New: `scenes/items/balloon.tscn`
- New: `scripts/balloon.gd`
- New: `scenes/effects/balloon_pop.tscn`
- New asset (Todd supplies): `assets/audio/balloon_pop.ogg`
- Modified: `scripts/item_inventory.gd` (consumable tracking)
- Modified: `assets/shop_items.json` (balloon entry, type field on existing items)
- Modified: `scripts/player.gd` (input handling, drop/throw)
- Modified: `scenes/ui/hud.tscn` and its script (balloon counter)
- Modified: `project.godot` (input action `drop_throw_balloon`)
- Modified: shop scene wherever pedestals currently live (add balloon pedestal instance)
- Modified: `scripts/pedestal.gd` if needed (handle consumable display vs equippable display)

## Update CLAUDE.md
- Add a "Balloons" section under Current Features describing the purchase flow, drop/throw mechanic, pop behavior, HUD counter
- Update the v0.3 Combat roadmap section: note balloons are now implemented as a v1 toy, AOE damage is the v0.3 addition
- If ItemInventory got a type/consumable API, document it briefly in the Tech / Key Patterns area
