# Prompt 17 — Fix backwards spawn facing

## Problem

Every time the player enters a level through a portal (and in the hub, and out of the
resurrection pod) they spawn facing **backwards** — looking back up the course instead
of down it.

## Cause

In `player.tscn` the `Camera3D` sits at the `SpringArm3D`'s local **+Z** (position
`(0, 0, 4)`) and, like every Godot camera, looks down its own **−Z**. So with
`CameraPivot.rotation.y == 0` — which is what every spawn leaves it at, because spawn
code only ever sets `global_position` — the view points along global −Z. All three
levels run toward **+Z**, so the player starts looking the wrong way and has to spin the
mouse before they can move.

The character mesh has the mirrored half of the same problem: the X Bot faces +Z and
`_character_mesh.rotation.y` stays 0 until the player moves, so you spawn looking at its
face rather than its back.

## Fix

Add `set_spawn_facing(dir: Vector3)` to `player.gd` and call it from every spawn site.

- Camera pivot yaw: `atan2(-dir.x, -dir.z)` — the camera looks along the pivot's −Z, so
  this is what makes it look along `dir`.
- Character mesh yaw: `atan2(dir.x, dir.z)` — matches the existing facing code in
  `_physics_process` (X Bot faces +Z after FBX2glTF import).

Call sites:

- `level.gd` (level_01) — face `Vector3(0, 0, 1)`, the course direction
- `level_02.gd` — same, and give CPU racers the same treatment so bots don't start
  moonwalking either
- `hub.gd` — fresh spawn faces `+Z` (toward the shop pavilion); the resurrection-pod
  spawn faces the pavilion from where the pod actually is

Keep it data-driven off the spawn point rather than hardcoding a magic 180° rotation, so
a level that runs in another direction just passes a different vector.
