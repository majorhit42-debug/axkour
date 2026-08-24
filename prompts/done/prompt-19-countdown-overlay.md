# Prompt 19 — Countdown overlay (and a HUD that survives level changes)

## Problem

The 5-second starting gate from prompt 18 held the player correctly, but the countdown
was invisible in game.

## Cause

`main.tscn` holds Hub + HUD as siblings, but `portal.gd` swaps levels with
`get_tree().change_scene_to_file()`, which replaces the **entire** current scene — HUD
included. So inside level_01 and level_02 there was no HUD at all: no coin counter, no
balloon counter, no elimination callouts, and no countdown. CLAUDE.md claimed the HUD
"persists across level swaps"; it never did.

## Fix

- Make the HUD an **autoload** (`HUD="*res://scenes/ui/hud.tscn"`) and remove it from
  `main.tscn`. Autoloads live under `/root` and survive `change_scene_to_file`.
- **Every Control in the HUD must set `mouse_filter = 2` (IGNORE).** The new countdown is
  a full-screen Control, and a Control that accepts the mouse will swallow the click that
  grabs pointer lock on web — the same class of bug as the "don't add a CanvasLayer under
  Player" note.

## Overlay

Give the countdown something to look at:

- Dimmed full-screen `ColorRect` behind it
- Race title (`FROSTING FALLS`), fed through `RaceState.start_countdown(seconds, title)`
- `GET READY` heading and a hint line explaining the camera works during the hold
- Big centred number, then `GO!` in green while the dim fades out and the overlay hides

Also delete the leftover `:Zone.Identifier` files in `prompts/ready/` — Windows copy
artifacts, nothing references them.
