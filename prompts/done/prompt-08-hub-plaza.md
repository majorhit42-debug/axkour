# Prompt 08 — Hub Plaza + Shop Migration

## Goal
Refactor the shop from level_01's StartPlatform into a standalone 3D **hub** scene that serves as the game's main menu, shop, multiplayer waiting area, and respawn destination. Player now spawns in the hub on game start and enters levels via portals around the perimeter.

## Architecture
- **New scene:** `scenes/hub/hub.tscn` (becomes the game's entry scene — main.tscn loads hub instead of level_01)
- **Outdoor plaza:** open sky, large flat ground, plenty of empty space for multiplayer milling
- **Shop pavilion in the center:** raised platform with pillars and a roof, all existing pedestals migrated inside
- **Level portals around the perimeter:** archways the player walks through to load a level (start with just one for level_01)

## Detailed Requirements

### Hub scene structure
- `Hub` (Node3D) root
- `WorldEnvironment` — procedural sky, slightly warmer tint than level_01 (e.g. soft orange/gold) so the hub feels "home"
- `DirectionalLight3D` (sun) at a friendly angle
- `Ground` — flat 60×60 plane, neutral sand/grey color, StaticBody3D + CollisionShape3D so the player doesn't fall through
- `ShopPavilion` (Node3D) at world center:
  - Floor: 16×16 raised platform, 0.2 thick, slightly different color from ground
  - Four corner pillars: ~4 units tall, CylinderMesh or CSGBox3D, dark stone color
  - Roof: large flat slab on top of pillars, big enough to overhang the platform edges
  - All existing **skin pedestals** and **hat pedestals** migrated inside, keeping their current relative layout (two rows)
  - Gold "STORE" Label3D floating above the pavilion (Billboard mode, font size 64)
- `LevelPortals` (Node3D) around the perimeter:
  - `Level01Portal` at z=20 (far side of the plaza, opposite the spawn)
  - Visual: archway frame — two pillars + horizontal lintel + a glowing rectangle inside (PlaneMesh with emissive material, blue or purple tint)
  - Label3D above the archway: "LEVEL 01", Billboard, font size 48
  - `Area3D` inside the archway — entering it calls `get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")`
- `PlayerStart` (Marker3D) — near the pavilion entrance facing toward Level01Portal
- `ResurrectionPodSpot` (Marker3D) — separate location for respawn arrivals (the pod itself is added in prompt 09, just place the marker for now)

### Player spawning
- main.tscn now loads `scenes/hub/hub.tscn` instead of level_01
- Hub spawns the player at `PlayerStart` using the same dynamic-spawn pattern level.gd uses
- Player has full control immediately — no cutscene or fade

### Entering a level
- Walking into a portal Area3D loads the corresponding level scene
- Mouse stays captured across the transition

### Returning to the hub from a level
- Add a `ReturnToHubPortal` Area3D on level_01's FinishPlatform
- Visual: smaller archway with "RETURN TO HUB" Label3D
- Entering it calls `get_tree().change_scene_to_file("res://scenes/hub/hub.tscn")`

### Strip the shop out of level_01
- Remove the StartPlatform shop area: skin pedestal row, hat pedestal row, gold "STORE" label
- StartPlatform reverts to a plain 4×4 starting platform (it's no longer 14×10)
- Keep level_01's `PlayerStart` marker — that's where players spawn when entering from the hub portal

### Autoloads stay as-is
- CoinWallet and ItemInventory are autoloads — they persist across `change_scene_to_file` calls automatically
- Coin count and equipped items survive transitions naturally — no extra wiring needed

## Verification
1. Run the game — should spawn in the hub plaza facing the Level 01 portal, NOT on level_01's start platform
2. Walk into the shop pavilion — pedestals work normally, can buy and equip skins/hats with E
3. Walk into the Level 01 portal — should load level_01.tscn and spawn at its PlayerStart on a plain start platform (no shop)
4. Play through level_01 to FinishPlatform — walk into the "Return to Hub" archway, should load hub.tscn back
5. Coin count and equipped skin/hat should persist across both transitions

## Do NOT
- Do not touch `scripts/player.gd` or `scenes/player/player.tscn`
- Do not modify CoinWallet or ItemInventory scripts
- Do not delete level_01's PlayerStart marker — still needed
- Do not move the pedestal scene or script — just relocate the **instances** into the hub
- Do not add a 2D main menu UI — the hub IS the menu, all interaction is in-world
- Do not implement the resurrection pod visual or the death-to-hub flow — that's prompt 09
- Do not add multiplayer code yet — just leave the hub roomy

## Files Involved
- New: `scenes/hub/hub.tscn`
- Modified: `scenes/main.tscn` (load hub instead of level_01)
- Modified: `scenes/levels/level_01.tscn` (strip shop area, add return-to-hub portal)

## Update CLAUDE.md
Add a "Hub Plaza" section under Current Features describing the new architecture, the portal system, and that the shop now lives in the hub.
