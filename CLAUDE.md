# Axkour — CLAUDE.md

> **Working title:** "Axkour" (Ax + parkour). Change this everywhere if you want a different name.

## Project Overview

**Axkour** is a 3rd-person 3D parkour platformer with quiz mechanics. The player runs and jumps across branching platforms while answering trivia questions; pick the wrong platform and it explodes, sending you back to the level's start. Inspired loosely by *Don't Touch Red*, with a quiz twist and an item-shop progression layer.

A father-son project — Todd builds and designs, Axel plays, designs, and helps execute prompts in Claude Code.

**Live URL:** https://axkour.vercel.app/
**Repository:** https://github.com/majorhit42-debug/axkour

---

## Tech Stack

- **Engine:** Godot 4.x
- **Language:** GDScript
  - C# is **not** an option — Godot 4's .NET runtime cannot export to HTML5, and web is a primary target.
- **Renderer:** Compatibility (OpenGL ES 3.0 / WebGL 2.0) — required for web export. **Do not** switch to Forward+ or Mobile.
- **Hosting:** Vercel (HTML5 static export)
- **Editor workflow:** Godot's visual editor used alongside Claude Code. `.tscn` scene files and `.gd` scripts are both human-readable text — Claude Code edits both, but big scene-graph rearrangements are usually faster done by hand in the editor.

---

## File Structure

```
axkour/
├── project.godot              # Godot 4.6, Compatibility renderer
├── export_presets.cfg         # Web export preset (builds/web/index.html)
├── scenes/
│   ├── main.tscn              # Entry scene — instances current level
│   ├── player/
│   │   └── player.tscn        # CharacterBody3D — capsule + spring-arm camera
│   ├── levels/
│   │   └── level_01.tscn      # Full level: jump platforms → quiz gates → hazard tiles → finish
│   ├── quiz/
│   │   └── quiz_gate.tscn     # Reusable fork gate with question/answer labels
│   └── hazard/
│       ├── hazard_tile.tscn   # 2×2 tile; red = lethal after 0.3s
│       └── red_tile_grid.tscn # Pattern-driven grid of HazardTiles
├── scripts/
│   ├── player.gd              # Movement, camera, respawn
│   ├── level.gd               # JSON loading, gate config, player spawn
│   ├── quiz_gate.gd           # Fork detection, wrong-answer explosion
│   ├── hazard_tile.gd         # Color assignment, fall-trigger logic
│   └── red_tile_grid.gd       # Pattern parser → HazardTile spawner
├── scenes/
│   └── effects/
│       └── explosion.tscn     # Reusable explosion: CPUParticles3D core+embers + OmniLight3D
├── assets/
│   ├── questions.json         # Question pool (edit here to add/change questions)
│   ├── audio/
│   ├── models/
│   └── textures/
└── prompts/
    ├── ready/                 # Queued prompts
    └── done/                  # Completed prompts (01, 02, 03)
```

---

## Current Features

### Bootstrap (prompt 01 — 2026-05-09)
- Godot 4 project configured with Compatibility renderer (GL ES 3.0 / WebGL 2.0)
- Input map: WASD movement, Space jump, LMB slap (registered only), Escape release mouse
- 3rd-person humanoid character (`CharacterBody3D`) — originally a white capsule placeholder, now Mixamo X Bot (see Humanoid Character section)
- Spring-arm camera: mouse yaw/pitch, vertical pitch clamped ±80°, Escape toggles mouse capture
- Physics movement: camera-relative WASD, jump, gravity
- Fall respawn: player respawns at level start when Y < −20
- Level 01: 6 platforms in a winding line with 2–3 unit gaps, sky environment, directional sun
- Level spawns the player dynamically; `respawn_position` set from `PlayerStart` Marker3D
- HTML5 export preset configured (Web, single-threaded, builds/web/index.html)

### Quiz Gates (prompt 02 — 2026-05-09)
- `assets/questions.json` question pool — JSON-driven, easy to edit
- Three seed questions: game creation date, Axel's favorite color, Axerooms creation date
- `QuizGate` scene: side-by-side fork platforms (8 units apart), billboarded question + answer labels
- Wrong platform: turns red, explodes after 1.5s — player falls and respawns via existing respawn logic
- Correct platform: no-op, player continues forward
- Three gates in level_01 (q01 → q02 → q03) with approach and reconverge platforms between each
- Green FINISH platform with "FINISH!" label after Gate 3
- Player node added to "player" group for gate detection

### Don't Touch Red (prompt 03 — 2026-05-09)
- `HazardTile` scene (2×0.5×2): `is_red` toggle; red tiles vanish after 0.3s on player contact, safe tiles pick a random color (blue/yellow/green/purple) at runtime
- `RedTileGrid` scene: spawns a grid of HazardTiles from an `@export_multiline` pattern string (`R`/`S`) — easy to redesign without code
- level_01 Don't Touch Red section: Reconverge3 → 10 stepping stones (zigzag winding, 4 red / 6 safe, navigable safe path) → MidPlatform → 6×6 tile grid → FinishPlatform
- FinishPlatform moved to end of full level (after tile grid)

### Deploy to Vercel (prompt 04 — 2026-05-10)
- Linux Godot 4.6.2 binary installed in WSL — headless exports work from the terminal
- `.gitignore` updated: `builds/web/` committed, editor cache and Zone.Identifier files excluded
- `vercel.json` added: serves `builds/web/`, correct `.wasm` MIME type
- Live at https://axkour.vercel.app/ — auto-deploys on every `git push`

### Post-deploy fixes & controller support (2026-05-10)
- Mouse capture fixed for web: click anywhere on the game canvas to lock, Escape to release (browser requires a user gesture before pointer lock)
- Camera Y damping: camera lags behind the player's vertical position during jumps (`CAMERA_Y_DAMP = 2.5` — low value = heavy lag)
- Controller support: left stick moves, right stick looks, A/Cross jumps, Start releases mouse — keyboard+mouse works simultaneously

### Explosion FX (prompt 05 — 2026-05-10)
- Reusable `Explosion` scene (`scenes/effects/explosion.tscn`) — spawned by both hazard tiles and wrong quiz platforms (0.3s delay each)
- Uses `CPUParticles3D` (not GPU — required for WebGL 2.0 / Compatibility renderer); particles fire via `restart()` not `emitting = true` (one-shot timing fix)
- Two particle emitters: red core (60 particles, zero gravity) + orange embers (80 particles, fall with gravity)
- `FlashSphere` (`MeshInstance3D`): orange emissive sphere, scales 0.2→5 in 0.15s then alpha fades to 0 over 0.3s — the primary "fireball" visual
- `OmniLight3D` flash: energy 8.0, range 12, fades to 0 over 0.4s via tween
- Camera shake: intensity 0.4 over 0.5s, fades linearly
- Player knockback: `KNOCKBACK_UP=40`, `KNOCKBACK_FORCE=30` launches player ~80m into the air; input locked for 5s so they can't fight gravity; falls to Y<-20 and respawns
- Explosion deferred one frame (`call_deferred`) so `global_position` is set before particles emit
- Explosion added to `current_scene` (not tile/platform) so `queue_free()` on parent doesn't kill it; self-destructs after 1.5s
- **Do not add CanvasLayer as child of Player** — breaks mouse input routing on web; screen flash was removed for this reason

### Golden Zone: Coins, Wallet, HUD (prompt 06 — 2026-05-12)
- `CoinWallet` autoload singleton (`scripts/coin_wallet.gd`) — global coin state with `add_coins()`, `lose_random_coins()`, `spend_coins()`, and `coin_count_changed` signal
- `Coin` scene (`scenes/coin/coin.tscn`) — `Area3D` with sphere collision; spins on Y axis; gold metallic material with emission glow; one-time collect (gone for the session after pickup)
- `Sparkle` effect (`scenes/effects/sparkle.tscn`) — 15 gold `CPUParticles3D` particles, one-shot, auto-destructs after 1s
- HUD (`scenes/ui/hud.tscn`) — `CanvasLayer` sibling in `main.tscn` (persists across level swaps); shows "Coins: N" top-right in gold with black outline, font size 32
- Player respawn now calls `CoinWallet.lose_random_coins()` — random 1–3 coin penalty on death, clamped at 0
- Golden zone in level_01: approach platform → 6 gold-tinted 3×3 platforms with 4–5 unit gaps, height variation (alternating Y=0.4/1.9), and lateral offsets — one coin above each platform
- FinishPlatform moved to z=192 to make room for the golden zone

### Shop: Pedestals, ItemInventory, Color Skins (prompt 07 — 2026-05-12)
- `ItemInventory` autoload singleton (`scripts/item_inventory.gd`) — tracks owned/equipped items per slot; `try_purchase()`, `grant()`, `equip()` APIs; loads catalog from `assets/shop_items.json`
- `assets/shop_items.json` — item catalog: White skin (free, owned by default), Red/Blue/Green skins (3 coins each)
- `Pedestal` scene (`scenes/shop/pedestal.tscn`) — `StaticBody3D` with dark stand, runtime-built display item, billboarded Label3D (hidden until player is within 1.5 units), `Area3D` proximity detection
- Press **E** (or gamepad A) near a pedestal to buy (if you can afford it) or equip (if owned) — sparkle effect on purchase
- Equipping a skin tints the player body mesh immediately via `set_surface_override_material`
- StartPlatform expanded to 14×10 for shop area; player spawns at back (z=−3) facing two rows of pedestals; gold "STORE" label floats above

### Hats + Label Proximity (2026-05-12)
- `HatBuilder` static class (`scripts/hat_builder.gd`) — generates hat geometry (CylinderMesh parts) by `hat_type`; called by both Pedestal and Player so display and worn hat always match
- 3 hat items in `shop_items.json`: Top Hat (5 coins, black, brim + tall crown), Party Hat (3 coins, magenta, cone), Cowboy Hat (4 coins, brown, wide brim + short crown)
- Hat mount: `BoneAttachment3D` (bone_idx=5, `mixamorig_Head`) with a child `Node3D` at y=0.18 as the actual `HatMount` — offset on child because skeleton overrides the BoneAttachment3D's own transform each frame
- Hat pedestal row at z=−1 (between spawn and skin row): Top Hat, Party Hat, Cowboy Hat at x=−3/0/3
- Pedestal labels are hidden by default and only appear when the player enters the interact sphere — no text clutter from a distance

### Hub Plaza + Shop Migration (prompt 08 — 2026-05-15)
- **Hub scene** (`scenes/hub/hub.tscn`) is now the game's entry scene — `main.tscn` loads hub instead of level_01
- Hub has a warm procedural sky, sandy ground (60×60), and a raised stone **ShopPavilion** (16×16 platform, 4 corner pillars, overhanging roof) at world center
- All skin and hat **pedestals migrated** from level_01 into the ShopPavilion — same layout, same behavior
- **Level01Portal** at z=20: stone archway (two pillars + lintel) with a glowing blue rectangle inside; walking in calls `change_scene_to_file("res://scenes/levels/level_01.tscn")`
- **ReturnToHubPortal** on level_01's FinishPlatform (at z=197): smaller orange archway with "RETURN TO HUB" label; walking in calls `change_scene_to_file("res://scenes/hub/hub.tscn")`
- Portal logic in `scripts/portal.gd` (Area3D, `@export target_scene`); hub player spawning in `scripts/hub.gd`
- `PlayerStart` in level_01 moved from z=−3 to z=0 so it lands on the new 4×4 start platform
- level_01's StartPlatform reverted to plain 4×4 (was 14×10); shop nodes and decorations stripped
- **CoinWallet** and **ItemInventory** autoloads persist across `change_scene_to_file` — coins and equipped items survive hub↔level transitions
- `ResurrectionPodSpot` Marker3D placed at (10, 1, 0) in hub — visual pod added in prompt 09

### Death Flow: You Died Screen + Resurrection Pod (prompt 09 — 2026-05-15)
- **`GameState` autoload** (`scripts/game_state.gd`) — singleton with `respawning_from_death: bool`; persists across scene changes to signal hub whether to use the pod spawn path
- **`DeathScreen` scene** (`scenes/ui/death_screen.tscn`) — `CanvasLayer` with dark-red 50% overlay + "YOU DIED" (font 96, bright red, fade-in 0.3s) + "Returning to hub..." subtitle; auto-advances to hub after 2s
- **`ResurrectionPod` scene** (`scenes/hub/resurrection_pod.tscn`) — dark metallic base + translucent blue chamber + dome cap + `OmniLight3D`; instanced at (10, 0, 0) in hub; `ResurrectionPodSpot` marker at (10, 1, 0) is the player spawn point (inside the chamber)
- **`die()` on player** — sets `is_dead = true`, calls `CoinWallet.lose_random_coins()`, sets `GameState.respawning_from_death = true`, instances death screen; `is_dead` suppresses all input and physics movement
- **Unified death trigger** — all death paths (fall below Y=-20, hazard tile explosion knockback, wrong quiz platform knockback) funnel through the fall check in `_physics_process`, which calls `die()`; no changes needed in explosion or quiz_gate scripts
- **Materialization effect in hub** — blue/white CPUParticles3D burst + pod light flash (1.5→6.0→1.5 energy tween) on arrival; player input locked for 0.5s post-materialization, then `unlock_input()` resets `is_dead`
- **Fresh start path unaffected** — `GameState.respawning_from_death` defaults false; first spawn goes to `PlayerStart` (z=−10 in hub), not the pod

### Humanoid Character — X Bot (2026-05-15)
- Mixamo X Bot FBX (`assets/models/x_bot.fbx`) replaces the white capsule visual; imported via `fbx/importer=0` (FBX2glTF) with `apply_root_scale=false` — the importer handles cm→m conversion internally
- FBX scene tree: `Skeleton3D` (65 bones, `mixamorig_` prefix with underscores) → `Beta_Surface` + `Beta_Joints` MeshInstance3D nodes
- `CharacterMesh` node in `player.tscn` instances the FBX at y=−0.9; collision capsule thinned to radius 0.35, height 1.8
- White default: `_apply_skin()` always applies a StandardMaterial3D override (targets `Beta_Surface`, first mesh found via `_find_first_mesh()`); skin tinting works the same way
- `_setup_body_mesh()` and `_setup_hat_mount()` use `_find_first_mesh()` / `_find_skeleton()` tree-walkers — no hardcoded paths into the FBX scene
- Hat mount: bone_idx set directly to 5 (`mixamorig_Head`); y=0.18 offset on child Node3D (not BoneAttachment3D itself, whose transform the skeleton overrides)
- X Bot faces +Z after FBX2glTF import; facing uses `atan2(move_dir.x, move_dir.z)` to align the +Z front with movement direction

### Electric Platforms (prompt 11 — 2026-05-16)
- **`ElectricTile` scene** (`scenes/hazard/electric_tile.tscn`) — same 2×0.5×2 footprint as HazardTile; always gold-colored so it blends into the golden zone
- **Hint 1 — Sparks:** looping `CPUParticles3D` child emits tiny blue sparks (amount=2, lifetime=0.3s, size=0.05) from the tile surface; subtle unless you look
- **Hint 2 — Hum:** `AudioStreamPlayer3D` auto-loads `assets/audio/electric_hum_loop.ogg` if present (max_distance=4, fades out quickly); silently skipped if file not supplied
- **Hint 3 — Arcs:** `flash_arc_to(other_pos, duration)` method spawns a thin blue emissive BoxMesh between the tile and a neighbor, lasting 0.1s
- **`ElectricTileGrid` scene** (`scenes/hazard/electric_tile_grid.tscn`) — `@export_multiline var pattern`; `E` = ElectricTile (gold, deadly), `S` = inline gold StaticBody3D (safe); 2-unit pitch
- **Arc firing:** grid script runs a random timer (0.5–1.5s interval) and fires arcs between adjacent electric tiles (≤2.5 units apart) only when the player is within 5 units of any electric tile
- **Death:** stepping on an electric tile triggers a blue CPUParticles3D burst on the tile, a brief blue OmniLight flash, a grey dust puff at the player's position, then calls `player.die()` — no knockback, instant death flow to hub
- **Level integration:** after the golden zone, a new golden section continues: GoldenApproachElectric (8×4 gold platform) → 4×6 ElectricTileGrid → ElectricMidPlatform (8×4 gold) → FinishPlatform (now at z=220); the electric grid tiles are gold, making dangerous tiles visually identical to safe ones
- Audio asset still needed: place a looping ogg at `assets/audio/electric_hum_loop.ogg` to enable the hum hint

### Debug Mode (2026-05-12)
- Type **axelrules** anywhere to toggle debug mode on/off (sliding buffer of last 9 keys, no Enter needed)
- While debug mode is active: **1** toggles fly mode (WASD horizontal, Space=rise, Shift=descend, no gravity, no respawn); **2** adds 1 coin

### Balloons (prompt 13 — 2026-05-16)
- **Consumable inventory** added to `ItemInventory` — `consumable_quantities` dict, `add_consumable()`, `use_consumable()`, `get_consumable_count()`, and `consumable_count_changed` signal; `try_purchase()` now routes consumables vs equippables by item `type` field
- **Balloon pedestal** in the hub ShopPavilion at (0, 0.5, -2) — displays a pink sphere; label reads "Balloons (10x) — 2 coins"; re-purchaseable anytime (refills to current + 10); sparkle effect on purchase
- **Balloon scene** (`scenes/items/balloon.tscn`) — `RigidBody3D`, mass 0.1, gravity_scale 0.3, floaty air resistance; random color from 7-color palette; `Area3D` PopTrigger pops on contact with any dynamic body (not `StaticBody3D`)
- **Pop effect** (`scenes/effects/balloon_pop.tscn`) — plays `assets/audio/pop.mp3`, 40-particle confetti burst with multi-color gradient, auto-destructs after 1.5s
- **Drop/Throw input** — **Q** (keyboard) or **RB** (gamepad) via new `drop_throw_balloon` action; tap = drop at feet (zero velocity); hold = charge throw (0.15s threshold, max 1.0s charge); throw arc forward + UP*0.4 at lerp(4, 12, charge) units/sec
- **HUD balloon counter** — pink "Balloons: N" label (font 28) appears top-right below coin counter when count > 0, hides when count reaches 0; subscribes to `consumable_count_changed` signal
- Audio asset: `assets/audio/pop.mp3` (Todd-supplied)

---

## Roadmap

### ~~v0.1 — Playable demo~~ ✓ Done
Movement, quiz gates, Don't Touch Red, deployed to Vercel.

### v0.2 — Economy (~3 prompts)
- Coins on golden-parkour platforms with HUD counter
- Item store as a physical zone at level start with purchase flow
- First cosmetics: basic humanoid model (replaces capsule), hat slot, body color tint

### v0.3 — Combat (~3 prompts)
- CPU opponent bots running the course (simple path-followers first)
- Slap mechanic — short-range push, lethal if target falls — unlocked via store
- Balloons as area attack item — balloon drop/throw is implemented (v1 toy); AOE damage to nearby characters is the v0.3 addition (uses the `placer` field on `balloon.gd`)

### v0.4 — Remaining store items (~1–2 prompts)
- Magic carpet — single-use section skip
- Powerups grab bag: jump boost, brief invincibility, TBD with Axel

### v0.5 — Local split-screen multiplayer (~1–2 prompts)
- Two `SubViewport`s side by side; P1 keyboard+mouse, P2 gamepad
- No networking — entirely local

### v0.6 — Audio pass (~1 prompt)
- Background music, jump/footstep/slap/balloon-pop SFX, store cha-ching
- Free SFX libraries; audio latency fix (50–80ms output latency for web)

### v0.7 — Real levels & level select (~3–5 prompts)
- level_01 stays the test bed; new levels introduce concepts gradually
- Level select screen

### v0.8 — Menus, polish, ship (~2–3 prompts)
- Main menu, pause, settings, level complete state
- Particle FX: tile explosions, balloon pop confetti, FINISH celebration
- Animation polish

---

## Planned / In-Progress Features

### Core Movement
- 3rd-person camera following a humanoid character
- Run + jump (WASD + Space, mouse to look)
- Fall below a Y threshold = death → respawn at level start
- **Slap button** — short-range melee that pushes NPCs/players off platforms; lethal if they fall

### Quiz / Branching Platforms
- ~~Basic gate mechanic (fork platforms, wrong explodes, JSON pool)~~ **Done — see Current Features**
- Variable answer counts (>2) — planned
- Audio / particle FX on explosion — planned
- Question types: about the game itself, real-world trivia, age-appropriate

### Golden Parkour
- ~~Coin pickups with wallet singleton, HUD counter, lose 1–3 coins on fall~~ **Done — see Current Features**
- Coins persist between deaths within a session (runtime only — no disk save yet)
- Save wallet to disk (for cross-session persistence) — planned
- ~~Shop integration (spending coins)~~ **Done — `CoinWallet.spend_coins()` used by ItemInventory**

### Item Store
- ~~Shop framework: pedestals at spawn, ItemInventory autoload, E to buy/equip, 4 color skins~~ **Done — see Current Features**
- Remaining buyable items (each needs its own prompt):
  - ~~**Hats** — equippable on the head~~ **Done — Top Hat, Party Hat, Cowboy Hat; see Current Features**
  - **Costumes** — full outfit swap (needs character model first)
  - **Balloons** — multiple colors; can be popped to hurt nearby characters' ears (offensive AOE) — tied to combat system
  - **Magic carpet** — single-use, lets you skip a parkour section
  - **Slap** — short-range push — tied to combat system
  - **Powerups** — TBD (jump boost? brief invincibility?)

### Character
- Default appearance: plain all-white humanoid
- Equippable: hats, costumes, color tint, balloons
- Balloons are an offensive item — popping deals area damage to opponents

### Death & Progression
- Fall below the void Y-threshold → respawn at level start (the item store)
- Unlimited respawns — no lives system in v1

### CPU / AI Opponents (v0.3)
- AI bots that run the same course as the player
- Slap-able / push-off-able
- Stretch goal: bots that try to slap back

### Local Split-Screen Multiplayer (v0.5)
- Two cameras, two viewports side by side (Godot supports this with `SubViewport`s)
- Player 1: keyboard + mouse
- Player 2: gamepad
- No networking — entirely local

---

## Web Export Notes (HTML5)

Real but manageable gotchas. Worth reading before deploying:

- **Audio autoplay** — browsers won't let audio start until the user has clicked something. Don't auto-play music on load; kick it off from the first menu click. Until then, expect silence and an `AudioContext was not allowed to start` warning in the console.
- **Audio crackling on single-threaded builds** (the default in Godot 4.3+). Godot's default 15ms output latency causes browser buffer underruns. Fix: Project Settings → Audio → Driver → Output Latency, try 50–80ms.
- **Threading is opt-in.** Single-threaded export is the right call for this game. Multi-threaded would require server-side COOP/COEP headers — or enabling Godot's "Enable PWA" export option, which adds a service worker that sets those headers itself. Stick with single-threaded unless we hit a wall.
- **C# is off the table for web.** GDScript only.
- **Build size** — HTML5 builds are larger than you'd expect (~20–40 MB). Vercel handles this fine.

---

## Development Principles

- **Plan Mode first** for any feature touching multiple systems (movement + camera, quiz + level gen, etc.). Review the plan before approving execution.
- **Build in chunks, commit between each one.** Don't pile features on uncommitted work.
- **Test in the running game after every change.** F5 is fast; use it.
- **No refactoring without a stated reason.** If Claude Code wants to restructure things, ask why before approving.
- **Use the editor for scene structure, scripts for logic.** Don't ask Claude Code to build complex scenes purely in code that should live in `.tscn` files; don't put logic in scenes that belongs in `.gd` scripts.
- **CLAUDE.md is the source of truth.** Update Current Features after every completed prompt.

---

## Prompt Workflow

(Same pattern as Axerooms.)

- `prompts/ready/` — queued prompts, ready to be picked up
- `prompts/done/` — completed prompts (moved here after finishing)

When Todd says "pick up the next prompt":
1. List files in `prompts/ready/`
2. Open and read the first one
3. Follow the instructions in the prompt
4. When complete, move the file to `prompts/done/`
5. Update Current Features and Planned Features in this file

---

## Git Workflow

```bash
git add .
git commit -m "Brief description of what was added"
git push
```

Vercel auto-deploys from main within ~30 seconds of every push. Every push goes live at https://axkour.vercel.app/

---

## Known Issues / Quirks

[TODO: fill in as the project develops. Anything Claude Code should know — fragile code, intentional weirdness, workarounds in place.]

---

## What Claude Code Should Not Do

- Don't switch the language to C# — web export doesn't support it.
- Don't switch the renderer away from Compatibility — web export requires it.
- Don't add npm packages or external bundlers — Godot exports a complete static bundle.
- Don't restructure the scene tree without flagging it.
- Don't build complex 3D scenes in pure GDScript when a `.tscn` file would be cleaner.
- Don't add a build pipeline (webpack/vite/etc.) — Godot's exporter is the build pipeline.
- Don't pull in 3D model assets or audio assets without first asking — Todd will source them.

---

## Session Startup Reminder

When starting a new Claude Code session, say:

> "Read CLAUDE.md before we start. Summarize the current feature state so I know you have context."

This confirms Claude Code loaded the file and understands where the project stands.
