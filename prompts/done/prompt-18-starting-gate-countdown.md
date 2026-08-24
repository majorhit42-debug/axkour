# Prompt 18 — Starting gate countdown

## Goal

A 5-second countdown at the start of a race so players can get oriented — look around,
see the course and the bots — before anything moves. Fall Guys starting gate.

## Behaviour

- On entering a level with a race, everyone is held for 5 seconds
- Big centred countdown on the HUD: `5 · 4 · 3 · 2 · 1 · GO!`, with `GO!` held briefly
- **The camera still works during the countdown** — that's the whole point. Mouse/right
  stick look is free; only movement and jumping are locked.
- CPU racers hold at the start line too, then go on the same signal

## Implementation

Put the clock in the `RaceState` autoload, since both the player and the bots need to
read it and the HUD (which lives in `main.tscn`) needs to render it:

- `countdown_remaining: float`, `start_countdown(duration)`, `is_locked() -> bool`
- signals `countdown_tick(seconds_left: int)` and `race_started`
- ticks down in `_process`; emits `race_started` when it hits zero

Then:

- `player.gd` — while `RaceState.is_locked()`, zero horizontal velocity and skip the jump
  input. Gravity, camera look, and `move_and_slide` still run.
- `cpu_racer.gd` — hold position while locked
- `hud.gd` / `hud.tscn` — centred countdown label, hidden when not counting
- `level_02.gd` — `RaceState.start_countdown(5.0)` after spawning the racers

`is_locked()` must return false when no countdown is running, so level_01 and the hub —
which have no race — are completely unaffected.
