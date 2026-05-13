# 07 — The Shop: Pedestals, Inventory, Color Skins

> Before starting, read `CLAUDE.md` in the project root.

## Goal

Build the **item shop** at the spawn area: an open zone with 4 pedestals, each displaying a buyable color skin. Player walks up to a pedestal, presses **E** (or the gamepad A button) to **buy** (if not owned) or **equip** (if owned). Owning and equipping flow through a new `ItemInventory` autoload singleton.

First items: **4 color skins** — White (free, owned by default), Red, Blue, Green (3 coins each). Equipping a skin tints the player's capsule body.

This prompt establishes the entire shop architecture. Future items (slap, hats, balloons, etc.) plug into the same system.

---

## Design Summary

- **`ItemInventory`** — new autoload singleton, parallel to `CoinWallet`. Tracks owned items, equipped items per slot, and provides purchase/equip APIs. Loads item data from `assets/shop_items.json`.
- **`shop_items.json`** — catalog of all buyable items. Each item has an id, name, slot, price, optional "owned_by_default" flag, and per-type fields (e.g., `color` for skins). Easy for Axel to edit prices, add colors, etc.
- **`Pedestal`** scene — a low plinth with a display item on top and a Label3D showing the item's state (`Buy [Name] — N coins` / `Equip [Name]` / `[Name] (Equipped)`). Detects player proximity via Area3D, listens for the `interact` action.
- **Player** subscribes to `ItemInventory.equipment_changed` and recolors its body mesh when the equipped skin changes.
- **Spawn area becomes the shop**: the StartPlatform expands to fit pedestals plus walking room. PlayerStart moves to the back of the platform so the player spawns facing the pedestals and the level beyond.
- **New input action** `interact` — E (keyboard) and Joypad Button 0 (A/South on Xbox).
- **Sparkle effect on purchase** — reuses the existing `scenes/effects/sparkle.tscn` from the coin pickup prompt.

---

## Files

**Create:**
- `scripts/item_inventory.gd` (new autoload)
- `assets/shop_items.json`
- `scripts/pedestal.gd`
- `scenes/shop/pedestal.tscn`

**Modify:**
- `project.godot` — register `ItemInventory` autoload, add `interact` input action
- `scripts/coin_wallet.gd` — add `spend_coins(amount: int) -> bool` method
- `scripts/player.gd` — subscribe to skin equipment changes, apply skin color to body mesh
- `scenes/levels/level_01.tscn` — expand StartPlatform, reposition PlayerStart, place 4 pedestals, add a "STORE" Label3D

---

## CoinWallet Update — `scripts/coin_wallet.gd`

Add a new method (do not modify existing methods):

```gdscript
func spend_coins(amount: int) -> bool:
    if coins < amount:
        return false
    coins -= amount
    coin_count_changed.emit(coins)
    return true
```

This is the only API the shop should use to deduct coins — never modify `coins` directly from outside.

---

## ItemInventory Autoload — `scripts/item_inventory.gd`

```gdscript
extends Node
# Autoloaded as "ItemInventory" — see project.godot

signal items_changed
signal equipment_changed(slot: String, item_id: String)

const ITEMS_PATH := "res://assets/shop_items.json"

var item_data: Dictionary = {}     # id -> item dict (raw JSON)
var owned_items: Dictionary = {}    # id -> true
var equipped: Dictionary = {}       # slot -> item_id

func _ready() -> void:
    _load_items()
    _grant_default_items()
    _equip_defaults()

func _load_items() -> void:
    var file := FileAccess.open(ITEMS_PATH, FileAccess.READ)
    if file == null:
        push_error("Could not open shop items JSON at %s" % ITEMS_PATH)
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("Could not parse shop items JSON")
        return
    for item in parsed.get("items", []):
        item_data[item.id] = item

func _grant_default_items() -> void:
    for id in item_data:
        if item_data[id].get("owned_by_default", false):
            owned_items[id] = true

func _equip_defaults() -> void:
    var slots_seen := {}
    for id in item_data:
        var item = item_data[id]
        var slot: String = item.get("slot", "")
        if slot.is_empty() or slots_seen.has(slot):
            continue
        if owns(id):
            equip(slot, id)
            slots_seen[slot] = true

func get_item(id: String) -> Dictionary:
    return item_data.get(id, {})

func owns(item_id: String) -> bool:
    return owned_items.get(item_id, false)

func grant(item_id: String) -> void:
    if not owns(item_id):
        owned_items[item_id] = true
        items_changed.emit()

func equip(slot: String, item_id: String) -> void:
    equipped[slot] = item_id
    equipment_changed.emit(slot, item_id)

func get_equipped(slot: String) -> String:
    return equipped.get(slot, "")

func try_purchase(item_id: String) -> bool:
    var item := get_item(item_id)
    if item.is_empty():
        return false
    if owns(item_id):
        return false
    var price: int = int(item.get("price", 0))
    if not CoinWallet.spend_coins(price):
        return false
    grant(item_id)
    return true
```

---

## Project.godot Updates

### 1. Add ItemInventory autoload

In the `[autoload]` section (already has `CoinWallet` from prompt 06), add:

```
ItemInventory="*res://scripts/item_inventory.gd"
```

The `*` makes it globally accessible. **Order matters**: `CoinWallet` must come before `ItemInventory` because ItemInventory references CoinWallet.

### 2. Add `interact` input action

In Project Settings → Input Map (or directly in `project.godot`'s `[input]` section), add a new action `interact` with these events:
- Keyboard: **E**
- Joypad Button 0 (A button on Xbox, X on PlayStation)

---

## Shop Items JSON — `assets/shop_items.json`

```json
{
  "items": [
    {
      "id": "skin_white",
      "name": "White",
      "slot": "skin",
      "price": 0,
      "owned_by_default": true,
      "color": [1.0, 1.0, 1.0]
    },
    {
      "id": "skin_red",
      "name": "Red",
      "slot": "skin",
      "price": 3,
      "owned_by_default": false,
      "color": [0.9, 0.2, 0.2]
    },
    {
      "id": "skin_blue",
      "name": "Blue",
      "slot": "skin",
      "price": 3,
      "owned_by_default": false,
      "color": [0.2, 0.4, 0.95]
    },
    {
      "id": "skin_green",
      "name": "Green",
      "slot": "skin",
      "price": 3,
      "owned_by_default": false,
      "color": [0.2, 0.85, 0.3]
    }
  ]
}
```

---

## Pedestal Scene — `scenes/shop/pedestal.tscn`

Tree:

- **Pedestal** (`StaticBody3D`) — root, attach `scripts/pedestal.gd`. Add to group `"pedestal"`.
  - **Stand** (`MeshInstance3D`) — `BoxMesh`, size `(1.5, 0.8, 1.5)`, plain dark-gray `StandardMaterial3D`. Position at `(0, 0.4, 0)` (so its bottom sits at floor level).
  - **StandCollision** (`CollisionShape3D`) — matching `BoxShape3D`, same position
  - **DisplayItem** (`MeshInstance3D`) — empty mesh, populated at runtime by the script. Position at `(0, 1.3, 0)` (centered above stand top).
  - **Label3D** — at position `(0, 2.4, 0)`. Properties:
    - `billboard = BILLBOARD_ENABLED`
    - `pixel_size = 0.012`
    - `outline_size = 8`, `outline_modulate = Color.BLACK`
    - `modulate = Color.WHITE`
    - `text = ""` (set by script)
  - **InteractArea** (`Area3D`) — at position `(0, 0.8, 0)`
    - `CollisionShape3D` with `SphereShape3D`, radius `1.5`

---

## Pedestal Script — `scripts/pedestal.gd`

```gdscript
extends StaticBody3D
class_name Pedestal

const SPARKLE_SCENE := preload("res://scenes/effects/sparkle.tscn")

@export var item_id: String = ""

var _player_near: bool = false

func _ready() -> void:
    $InteractArea.body_entered.connect(_on_body_entered)
    $InteractArea.body_exited.connect(_on_body_exited)
    ItemInventory.items_changed.connect(_refresh_label)
    ItemInventory.equipment_changed.connect(_on_equipment_changed)
    _setup_display()
    _refresh_label()

func _setup_display() -> void:
    var item := ItemInventory.get_item(item_id)
    if item.is_empty():
        push_error("Pedestal references unknown item id: %s" % item_id)
        return
    # For skin items, show a small colored capsule on the pedestal
    var slot: String = item.get("slot", "")
    if slot == "skin":
        var capsule := CapsuleMesh.new()
        capsule.radius = 0.3
        capsule.height = 0.9
        $DisplayItem.mesh = capsule
        var col_arr = item.get("color", [1, 1, 1])
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(col_arr[0], col_arr[1], col_arr[2])
        $DisplayItem.set_surface_override_material(0, mat)

func _refresh_label() -> void:
    var item := ItemInventory.get_item(item_id)
    if item.is_empty():
        return
    var item_name: String = item.get("name", "?")
    var price: int = int(item.get("price", 0))
    var slot: String = item.get("slot", "")
    var is_owned := ItemInventory.owns(item_id)
    var is_equipped := ItemInventory.get_equipped(slot) == item_id

    if is_equipped:
        $Label3D.text = "%s (Equipped)" % item_name
    elif is_owned:
        $Label3D.text = "Equip %s\n[E]" % item_name
    else:
        $Label3D.text = "Buy %s — %d coins\n[E]" % [item_name, price]

func _on_equipment_changed(_slot: String, _id: String) -> void:
    _refresh_label()

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        _player_near = true

func _on_body_exited(body: Node3D) -> void:
    if body.is_in_group("player"):
        _player_near = false

func _unhandled_input(event: InputEvent) -> void:
    if not _player_near:
        return
    if not event.is_action_pressed("interact"):
        return
    _interact()

func _interact() -> void:
    var item := ItemInventory.get_item(item_id)
    if item.is_empty():
        return
    var slot: String = item.get("slot", "")
    if ItemInventory.owns(item_id):
        # Toggle equip — re-pressing E on an equipped item is a no-op, on an owned-but-not-equipped item it equips
        if ItemInventory.get_equipped(slot) != item_id:
            ItemInventory.equip(slot, item_id)
    else:
        if ItemInventory.try_purchase(item_id):
            # Equip immediately on purchase
            ItemInventory.equip(slot, item_id)
            _spawn_sparkle()

func _spawn_sparkle() -> void:
    var sparkle := SPARKLE_SCENE.instantiate()
    get_tree().current_scene.add_child(sparkle)
    sparkle.global_position = $DisplayItem.global_position
```

---

## Player Script Changes — `scripts/player.gd`

### Add at the top of the script (after existing properties from prompt 05):

```gdscript
@onready var _body_mesh: MeshInstance3D = $Mesh
```

### Add to existing `_ready()`:

After the existing setup lines (camera origin, mouse capture, etc.), add:

```gdscript
ItemInventory.equipment_changed.connect(_on_equipment_changed)
_apply_skin()
```

### Add two new methods:

```gdscript
func _on_equipment_changed(slot: String, _id: String) -> void:
    if slot == "skin":
        _apply_skin()

func _apply_skin() -> void:
    var skin_id := ItemInventory.get_equipped("skin")
    if skin_id.is_empty():
        return
    var item := ItemInventory.get_item(skin_id)
    var col_arr = item.get("color", [1, 1, 1])
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(col_arr[0], col_arr[1], col_arr[2])
    _body_mesh.set_surface_override_material(0, mat)
```

Do not modify any other player code.

---

## Level Layout — `scenes/levels/level_01.tscn`

### Expand StartPlatform

Change `StartPlatform` size from `(6, 0.5, 6)` to **`(14, 0.5, 10)`**. Keep it at the origin. Update both its `BoxMesh.size` and its `CollisionShape3D` `BoxShape3D.size`.

### Reposition PlayerStart

Move the `PlayerStart` Marker3D from its previous center position to **`(0, 1.5, -3)`** within the expanded StartPlatform — this puts the spawn at the back of the shop area, facing forward (+Z) toward the pedestals and the rest of the level.

### Add the 4 pedestals

Instance `scenes/shop/pedestal.tscn` 4 times under the Level root (sibling of StartPlatform). Position and configure:

| Pedestal | Position | item_id |
|---|---|---|
| Pedestal_White | `(-4.5, 0.5, 1)` | `skin_white` |
| Pedestal_Red | `(-1.5, 0.5, 1)` | `skin_red` |
| Pedestal_Blue | `(1.5, 0.5, 1)` | `skin_blue` |
| Pedestal_Green | `(4.5, 0.5, 1)` | `skin_green` |

(Y of 0.5 puts the stand's bottom on the platform top at Y=0.25 — adjust slightly if there's clipping.)

Set each pedestal's `item_id` export property to match the table.

### Add the STORE label

Add a Label3D as a child of the Level root:
- Position: `(0, 4, 1)` (above and between the pedestals)
- `text = "STORE"`
- `billboard = BILLBOARD_ENABLED`
- `pixel_size = 0.02`
- `outline_size = 12`, `outline_modulate = Color.BLACK`
- `modulate = Color(1.0, 0.85, 0.1)` (gold)

### Confirm the rest of the level is intact

All other platforms, quiz gates, red tiles, golden zone, FinishPlatform should remain unchanged. The shop area replaces only the StartPlatform; everything from the bootstrap jumps onward stays where it is.

---

## Verification Checklist

- [ ] On launch, player spawns at the back of the shop area facing the pedestals
- [ ] 4 pedestals are visible: White, Red, Blue, Green — each with a colored capsule on top matching the item color
- [ ] "STORE" floats in gold text above the pedestal row
- [ ] Each pedestal's label reflects state correctly:
  - White pedestal initially: `White (Equipped)` (since white is owned-by-default and auto-equipped)
  - Red/Blue/Green pedestals initially: `Buy [Color] — 3 coins\n[E]`
- [ ] Walking near a pedestal and pressing E with insufficient coins: no-op (label doesn't change, no purchase)
- [ ] Walking near a pedestal with enough coins and pressing E: coin counter decreases by 3, label changes to `[Color] (Equipped)`, gold sparkle plays at the pedestal, player capsule body tints to the new color
- [ ] Previously equipped pedestal's label changes from `(Equipped)` to `Equip [Color]`
- [ ] Pressing E on an already-equipped pedestal: no-op (already equipped)
- [ ] Pressing E on an owned-but-not-equipped pedestal: equips it (player color changes), no coins spent
- [ ] Collect coins in the golden zone, walk back to start, buy a different color — wallet and inventory work end-to-end
- [ ] Falling and respawning: coin loss still works (from prompt 06), but **purchased skins remain owned** (inventory is independent of wallet)
- [ ] Gamepad A button works as an alternative to E for interaction
- [ ] No errors or warnings in the Output panel
- [ ] Vercel deploy works — test in browser

---

## Do NOT

- Do **not** add a UI menu / popup for shopping in this prompt — the in-world pedestal + Label3D approach is the design.
- Do **not** save inventory or coins to disk yet — runtime-only state is fine.
- Do **not** add hats, costumes, balloons, slap, magic carpet, or powerups in this prompt — each needs its own setup and will come in future prompts.
- Do **not** add a "Not enough coins" error message yet — the silent no-op is fine; we can add feedback later if needed.
- Do **not** modify the level structure beyond the shop area at the start. The rest of level_01 (jumps, quiz, red tiles, golden zone, finish) stays exactly as it is.
- Do **not** add visual changes to indicate "this skin is purchased" other than the label state — no glowing pedestals or trophy badges.

---

## When Done

1. Commit with message: `Shop: pedestals, ItemInventory autoload, color skin items, interact action`
2. Update `CLAUDE.md`:
   - **Current Features**: add "Shop with pedestals at spawn area; ItemInventory autoload; 4 color skins; press E to buy/equip"
   - **Planned / In-Progress Features → Item Store**: mark the framework as done; remaining items (slap, hats, costumes, balloons, magic carpet, powerups) tied to their dependent systems.
3. Move this prompt file from `prompts/ready/` to `prompts/done/`
4. Re-export the web build and `git push` to trigger the auto-deploy.
