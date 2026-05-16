# Prompt 12 — X Bot Humanoid Character Integration

## Goal
Replace the white capsule player visual with the Mixamo X Bot humanoid character. The character should be white by default (red is the imported material color — needs to be overridden). Keep all existing player physics (CharacterBody3D, capsule collision shape, movement script) unchanged. The existing skin tinting and hat systems must continue to work, with hats now attaching to the head bone instead of a static Y position.

## Asset Setup

### File placement
- Todd will place `X_Bot.fbx` at `assets/models/x_bot.fbx` in the project root
- Confirm it's there before proceeding; if not, ask Todd

### Godot import settings for the FBX
- Select the FBX in the FileSystem panel → Import tab
- Set the following and click Reimport:
  - **Root scale:** `0.01` (Mixamo exports in cm; Godot uses meters)
  - **Optimize mesh:** on
  - **Generate tangents:** on
  - **Create skeleton:** on (should be the default)
  - **Import animations:** off (no animations in scope yet)
- After import, open the imported scene briefly to confirm:
  - Mesh appears upright (Y up)
  - Skeleton bones use the `mixamorig:` prefix (e.g. `mixamorig:Hips`, `mixamorig:Spine`, `mixamorig:Head`)
  - Character is ~1.8 units tall (human-scale)
  - There's a single mesh surface (called something like "Alpha_Surface" or "Body") — note its surface index, you'll need it for material override

## Player Scene Modifications

### Open `scenes/player/player.tscn` and:

**1. Remove the old visual capsule**
- Delete the existing CapsuleMesh node (the white pill that currently represents the player)
- Do NOT delete the CollisionShape3D — physics collision stays as a capsule, the visual changes only

**2. Add the X Bot mesh**
- Add a new node as a child of the CharacterBody3D root: instance `assets/models/x_bot.fbx` (Scene → Instantiate Child Scene)
- Name the instance `CharacterMesh`
- Position it so the **feet sit at the bottom of the collision capsule**:
  - The CharacterBody3D origin is the capsule center
  - For a 2m-tall capsule centered at origin (top at y=1, bottom at y=-1), the mesh origin (which is at feet for Mixamo) should be at local y=-1
  - Adjust `CharacterMesh` transform: position (0, -1, 0)
  - If the capsule is sized differently in the scene, calculate accordingly: `mesh_y = -(capsule_height / 2)`
- Rotation: Mixamo characters face -Z by default (same as Godot's camera-forward). Should not need rotation. If the character faces backwards on first run, rotate 180° around Y on the CharacterMesh.

**3. Tune the collision capsule (if needed)**
- The existing CapsuleShape3D may be wider than the humanoid silhouette
- Suggested: radius 0.35, height 1.8 (matches a thin human profile)
- Adjust the CharacterBody3D's CollisionShape3D position if needed so the bottom touches y=feet

**4. Replace the static HatMount with a bone attachment**
- Delete the existing HatMount Node3D (the one at y=1.3)
- Find the Skeleton3D inside the imported CharacterMesh
- Add a `BoneAttachment3D` as a child of that Skeleton3D
- Name it `HatMount`
- In the BoneAttachment3D inspector, set **Bone Name** to `mixamorig:Head`
- This makes the hat follow the head bone correctly — automatically aligned, will follow head movement if/when animations are added
- Add a small Y offset on HatMount's transform (~0.18) so hats sit ON TOP of the head, not at the head bone's pivot (which is roughly the neck)

## White Default Material

The imported FBX has a red albedo on its material. We want white by default.

**Approach: override at the player scene level (not at import — keeps the asset clean)**
- In `scenes/player/player.tscn`, select the CharacterMesh's mesh node (the MeshInstance3D inside the imported scene — you may need to enable "Editable Children" on the CharacterMesh instance to access it)
- In the inspector, expand `Surface Material Override`
- For surface 0, click the slot and add a new StandardMaterial3D
- Set:
  - Albedo Color: white (1, 1, 1, 1)
  - Metallic: 0
  - Roughness: 0.7
  - Keep everything else default

Now the character renders white regardless of the FBX's embedded material.

## Skin Tinting Integration

The existing skin system in `ItemInventory` + `scripts/player.gd` calls `set_surface_override_material()` on the player's mesh to tint it (white/red/blue/green). It currently targets the capsule. Update it to target the new mesh.

### In `scripts/player.gd`
- Find the `_apply_skin()` method (or wherever skin equip is handled)
- Update the mesh reference from the deleted CapsuleMesh to the new CharacterMesh's surface
- Path will look like: `$CharacterMesh/<imported_scene_root>/<MeshInstance3D>` — use the actual path after import
- Tip: cache the MeshInstance3D reference in `_ready()` so you don't traverse the tree on every skin change:
  ```gdscript
  @onready var _body_mesh: MeshInstance3D = $CharacterMesh.find_child("MeshInstance3D_name_here", true, false)
  ```
- When applying a skin color: build a StandardMaterial3D with that color and call `_body_mesh.set_surface_override_material(0, mat)`
- Default skin (White) should produce a pure-white tint identical to the override material above — so calling apply_skin("white") on a fresh player should look the same as no equip

### Default skin on game start
- In `_ready()`, after caching the mesh reference, call the skin-equip method with the currently equipped skin (which defaults to "white" from ItemInventory)
- This ensures the player loads with the correct color even if the override material wasn't set correctly

## Verification

1. Run the game — should spawn with the X Bot humanoid character (white) instead of the capsule
2. Character feet should touch the ground (not float or sink) when standing on a platform
3. Character should face the direction the camera looks when moving
4. Walk into a colored skin pedestal (Red/Blue/Green), press E to equip → character body tints to that color
5. Equip "White" skin → character returns to white
6. Equip a hat from the hat pedestals → hat sits on top of the character's HEAD (not floating, not clipping into the head)
7. Jump and move around with hat equipped — hat stays anchored to the head, no floating or lag
8. Walk through level_01 — no physics weirdness, collision still works (you can't walk through walls, you bump into the right edges of platforms)
9. Die (fall off, hazard, etc.) — death/respawn flow still works (prompt 09 should already be done)

## Do NOT
- Do not modify `scripts/player.gd` movement code (gravity, jump, WASD, camera) — visual swap only
- Do not import animations from the FBX (none needed yet)
- Do not change CoinWallet or ItemInventory
- Do not update the shop pedestals to use the humanoid mesh in this prompt — that's a follow-up (pedestals can keep displaying capsules for now even if it's a slight visual mismatch with the player)
- Do not edit the imported FBX file directly or in Blender — all overrides happen at the Godot scene level so the asset stays clean
- Do not delete `scripts/hat_builder.gd` — it still generates the hat geometries; only the mount mechanism changed (Marker3D → BoneAttachment3D)

## Files Involved
- New: `assets/models/x_bot.fbx` (Todd uploads)
- New: `assets/models/x_bot.fbx.import` (auto-generated on import)
- Modified: `scenes/player/player.tscn` (mesh swap, HatMount becomes BoneAttachment3D, white material override)
- Modified: `scripts/player.gd` (cache mesh reference, update skin-apply target)

## Update CLAUDE.md
- Under Current Features, add a "Humanoid Character" section: Mixamo X Bot mesh, white by default with material override, skin tinting now targets the body mesh, HatMount is a BoneAttachment3D on `mixamorig:Head`
- Remove or update the old "white capsule placeholder" mention
- Add to "Known Issues / Quirks" if anything weird surfaces during import (rotation, scale, etc.)
