# Axkour — CLAUDE.md

> **Working title:** "Axkour" (Ax + parkour). Change this everywhere if you want a different name.

## Project Overview

**Axkour** is a 3rd-person 3D parkour platformer with quiz mechanics. The player runs and jumps across branching platforms while answering trivia questions; pick the wrong platform and it explodes, sending you back to the level's start. Inspired loosely by *Don't Touch Red*, with a quiz twist and an item-shop progression layer.

A father-son project — Todd builds and designs, Axel plays, designs, and helps execute prompts in Claude Code.

**Live URL:** [TODO: deploy to Vercel and add URL]
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
├── project.godot              # Godot project file
├── scenes/
│   ├── main.tscn              # Entry scene (loads current level)
│   ├── player/
│   │   └── player.tscn        # Player character (CharacterBody3D)
│   └── levels/
│       └── level_01.tscn      # First test level
├── scripts/
│   ├── player.gd
│   └── level.gd
├── assets/
│   ├── audio/                 # [TODO: confirm folder layout]
│   ├── models/
│   └── textures/
├── prompts/
│   ├── ready/                 # Queued Claude Code prompts
│   └── done/                  # Completed prompts
└── export_presets.cfg         # Web + desktop export settings
```

This will evolve. Update after every completed prompt.

---

## Current Features

### Bootstrap (prompt 01 — 2026-05-09)
- Godot 4 project configured with Compatibility renderer (GL ES 3.0 / WebGL 2.0)
- Input map: WASD movement, Space jump, LMB slap (registered only), Escape release mouse
- 3rd-person humanoid character (`CharacterBody3D`) — white capsule placeholder
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
- Special platforms that carry coins
- Coins persist between deaths within a level (TBD whether they reset on level exit)

### Item Store
- Located at the **start** of every level — also where the player respawns after dying
- Buyable items (using collected coins):
  - **Skins** — change the character's body color
  - **Hats** — equippable on the head
  - **Costumes** — full outfit swap
  - **Balloons** — multiple colors; can be popped to hurt nearby characters' ears (offensive AOE)
  - **Magic carpet** — single-use, lets you skip a parkour section
  - **Powerups** — TBD (jump boost? brief invincibility?)

### Character
- Default appearance: plain all-white humanoid
- Equippable: hats, costumes, color tint, balloons
- Balloons are an offensive item — popping deals area damage to opponents

### Death & Progression
- Fall below the void Y-threshold → respawn at level start (the item store)
- Unlimited respawns — no lives system in v1

### CPU / AI Opponents (Phase 2)
- AI bots that run the same course as the player
- Slap-able / push-off-able
- Stretch goal: bots that try to slap back

### Local Split-Screen Multiplayer (Phase 3)
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

Vercel auto-deploys from main once we wire it up. Every push goes live.

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
