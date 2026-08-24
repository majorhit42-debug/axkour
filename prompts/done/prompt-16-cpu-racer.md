# Prompt 16 — CPU Racer (first step toward Fall Guys rounds)

## Goal

Add a CPU-controlled racer that runs the course alongside the player. This is the
foundation for the larger Fall Guys direction (rounds, multiple bots, level voting),
so the structures built here must scale to several bots without a rewrite.

## Design decisions (agreed with Todd)

- **Bot death = eliminated for the round.** No respawn. The bot plays an elimination
  puff and despawns.
- **Bots are solid.** You can bump into a bot and jostle for platform space. No slapping —
  combat stays in v0.3.
- Bots are a *list* from day one so raising the count is a number change.
- The first bot's `quiz_accuracy` is high (~0.75) so a bad roll doesn't eliminate it
  fifteen seconds into the level and leave the player racing alone.

## Step 1 — The `racer` group refactor (do this first, it's the risky part)

Every hazard currently gates on `is_in_group("player")`, so a bot would be immune to
all of them. But simply adding bots to the `"player"` group is worse: `electric_tile.gd`
calls `player.die()`, and the player's `die()` shows YOU DIED, drains the coin wallet,
and sends you to the hub — a bot touching an electric tile would yank the player out
of the level.

Split the concept:

- `"racer"` — any character hazards should affect (player **and** bots)
- `"player"` — the human only (coins, portals, pedestals stay player-only)

Both racer types implement `die()`, with different behavior. Update:

- `scenes/player/player.tscn` — add the `racer` group alongside `player`
- `hazard_tile.gd`, `electric_tile.gd`, `quiz_gate.gd` — detect `"racer"`
- `coin.gd`, `portal.gd` — leave on `"player"`

Also fix `quiz_gate.gd`'s gate-wide `_wrong_triggered` flag: with two racers it would let
the first triggered fork block the other racer's fork from ever exploding. Make it
per-platform.

**Verification checkpoint:** normal single-player runs of level_01 and level_02 must
behave exactly as before after this step.

## Step 2 — Extract `character_rig.gd`

`player.gd` owns the rig plumbing a bot needs verbatim (`_find_first_mesh`,
`_find_skeleton`, hat-mount construction, skin material). Pull it into a static
`CharacterRig` helper — same pattern as the existing `HatBuilder` — and have both
`player.gd` and `cpu_racer.gd` call it. Do not restructure anything else in `player.gd`.

Bots must **not** read `ItemInventory` for cosmetics — that is the player's equipped
gear. Bots pick a random skin colour and hat from the catalog so the pack looks varied.

## Step 3 — `cpu_racer.tscn` + `cpu_racer.gd`

- `CharacterBody3D`, same capsule collider and X Bot mesh as the player, **no camera**
- Group `racer` only (never `player`)
- Billboarded `Label3D` name tag above the head
- Per-bot personality: `racer_name`, `quiz_accuracy`, `hazard_awareness`, small speed jitter
- `die()` → elimination puff, report to `RaceState`, despawn

### Navigation

Do **not** use `NavigationAgent3D` — a navmesh cannot express a jump across a void, and
these levels are entirely floating platforms with gaps. The agent would walk to a ledge
and stop.

Instead: a `RacerRoute` node per level holding an exported `PackedVector3Array` of points.
The bot steers toward the next point and advances when close.

**Jumping is geometry-driven, not authored** — raycast down from a point ~1.3 units ahead
of the bot; if there's no floor within ~2.5 units below, jump. This handles platform gaps,
stepping stones and rising ledges without per-waypoint flags, and means route points can sit
at platform centres without the bot trying to jump the full centre-to-centre distance.

### Branch points

- **Quiz gates** — the route names its gates by index + `NodePath`. On reaching a gate point
  the bot asks the gate to choose a fork, correct with probability `quiz_accuracy`, and steers
  to that fork's position. A bot picking wrong and exploding next to Axel is the whole appeal.
- **Red tiles** — the authored route already follows a safe path through the grid.
  `hazard_awareness` is the probability the bot follows it; on a failed roll it drifts
  laterally off the safe line and probably dies. This is what produces visible mistakes.

## Step 4 — Routes

Author a `RacerRoute` for level_02 (start platforms → Lego gate → sprinkle steps →
sprinkle floor safe path → finish). level_01 can follow later.

## Step 5 — Minimal `RaceState` autoload

Not voting, not rounds — just enough to make elimination mean something:

- Tracks who is still running
- `racer_eliminated(name)` and `racer_finished(name, place)` signals
- HUD listens and shows a short callout ("Turbo was eliminated!") plus the player's placement
  at the finish

Autoload so the HUD (which lives in `main.tscn` and persists across level swaps) can
subscribe without cross-scene wiring.

## Out of scope

Round manager, level voting, multiple simultaneous bots, elimination brackets, slapping.
