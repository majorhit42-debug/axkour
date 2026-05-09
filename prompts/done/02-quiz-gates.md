# 02 — Quiz Gates: Branching Platforms with 3D Question Text

> Before starting, read `CLAUDE.md` in the project root. The previous prompt (`01-bootstrap-character.md` in `prompts/done/`) gives you the existing player + level structure.

## Goal

Add the core quiz mechanic: **side-by-side fork platforms** where the player has to land on the platform showing the correct answer to a floating question. Wrong answer → platform turns red and explodes after 1.5s, dropping the player into the void.

Three quiz gates in `level_01`, in order, each backed by an entry in a JSON question pool. After Gate 3, a "FINISH!" marker (no level-end UI yet — that's a later prompt).

---

## Design Summary

- A **QuizGate** is a reusable scene with two parallel platforms (`LeftPlatform`, `RightPlatform`) about 4 units apart.
- A `Label3D` floats above the center of the gate showing the question.
- A `Label3D` floats above each platform showing that platform's answer.
- Player lands on the wrong platform → it tints red, waits 1.5s, then `queue_free()`s. If the player is still on it, they fall into the void and respawn (uses the existing respawn-on-fall logic from prompt 01).
- Player lands on the right platform → no-op. They continue forward.
- After each gate, **both** platforms can launch the player forward to a "reconverge" platform that leads to the next gate. (This means a quick player can escape a wrong choice by jumping forward in time, which is fine — it's a skill recovery, not a bug.)
- After Gate 3: a finish platform with a "FINISH!" floating label. No special behavior on contact yet.

---

## Files

**Create:**
- `assets/questions.json`
- `scenes/quiz/quiz_gate.tscn`
- `scripts/quiz_gate.gd`

**Modify:**
- `scenes/levels/level_01.tscn` — add three quiz gates, reconverge platforms, and the finish platform after the existing jump platforms
- `scripts/level.gd` — load questions JSON on ready and configure each gate
- `scenes/player/player.tscn` — add the Player node to the `"player"` group (needed for gate detection)

---

## Question Pool — `assets/questions.json`

```json
{
  "questions": [
    {
      "id": "q01_game_created",
      "text": "When was this game created?",
      "answers": ["May 9, 2026", "August 2025"],
      "correct_index": 0
    },
    {
      "id": "q02_axels_color",
      "text": "What is Axel's favorite color?",
      "answers": ["Blue", "Red"],
      "correct_index": 0
    },
    {
      "id": "q03_axerooms_created",
      "text": "When was Axerooms created?",
      "answers": ["March 2026", "October 2024"],
      "correct_index": 0
    }
  ]
}
```

Format notes for future expansion:
- `answers` is an array (always 2 entries for now since we're using side-by-side forks; the format is flexible enough to support more options later).
- `correct_index` is the zero-based index of the right answer in `answers`.
- The wrong-answer distractors above are placeholders — Todd will tune them.

---

## QuizGate Scene — `scenes/quiz/quiz_gate.tscn`

Tree:

- **QuizGate** (`Node3D`) — root, attach `scripts/quiz_gate.gd`. Add to group `"quiz_gate"`.
  - **QuestionLabel** (`Label3D`) — at local position `(0, 5, 0)`. Properties:
    - `billboard = BILLBOARD_ENABLED`
    - `pixel_size = 0.012`
    - `outline_size = 8`
    - `outline_modulate = Color.BLACK`
    - `modulate = Color.WHITE`
    - `text = ""` (set by configure())
  - **LeftPlatform** (`StaticBody3D`) — at local position `(-4, 0, 0)`
    - `Mesh` (`MeshInstance3D`) — `BoxMesh`, size `(6, 0.5, 6)`, plain white `StandardMaterial3D`
    - `CollisionShape3D` — matching `BoxShape3D`, size `(6, 0.5, 6)`
    - `DetectionArea` (`Area3D`) — at local position `(0, 0.75, 0)` (just above platform top)
      - `CollisionShape3D` — `BoxShape3D`, size `(6, 1, 6)`
    - `AnswerLabel` (`Label3D`) — at local position `(0, 3, 0)`. Same Label3D properties as QuestionLabel above.
  - **RightPlatform** (`StaticBody3D`) — at local position `(4, 0, 0)`. Same internal structure as LeftPlatform (mesh, collision, DetectionArea, AnswerLabel).

The 8-unit spacing between platforms means a side-jump between them is *possible* but not trivial — exactly the recovery option we want.

---

## QuizGate Script — `scripts/quiz_gate.gd`

```gdscript
extends Node3D
class_name QuizGate

@export var question_id: String = ""
@export var explode_delay: float = 1.5

var correct_side: String = "left"  # "left" or "right" — set by configure()
var _wrong_triggered: bool = false

func _ready() -> void:
    $LeftPlatform/DetectionArea.body_entered.connect(_on_left_entered)
    $RightPlatform/DetectionArea.body_entered.connect(_on_right_entered)

func configure(question_text: String, left_answer: String, right_answer: String, correct: String) -> void:
    $QuestionLabel.text = question_text
    $LeftPlatform/AnswerLabel.text = left_answer
    $RightPlatform/AnswerLabel.text = right_answer
    correct_side = correct

func _on_left_entered(body: Node3D) -> void:
    if not body.is_in_group("player"): return
    if correct_side == "left": return
    _trigger_wrong($LeftPlatform)

func _on_right_entered(body: Node3D) -> void:
    if not body.is_in_group("player"): return
    if correct_side == "right": return
    _trigger_wrong($RightPlatform)

func _trigger_wrong(platform: StaticBody3D) -> void:
    if _wrong_triggered: return
    _wrong_triggered = true
    var mesh: MeshInstance3D = platform.get_node("Mesh")
    var red_mat := StandardMaterial3D.new()
    red_mat.albedo_color = Color.RED
    mesh.set_surface_override_material(0, red_mat)
    await get_tree().create_timer(explode_delay).timeout
    platform.queue_free()
```

---

## Level Script — `scripts/level.gd`

Replace the existing script. It now also loads questions and configures gates:

```gdscript
extends Node3D

@export var player_scene: PackedScene
const QUESTIONS_PATH := "res://assets/questions.json"

func _ready() -> void:
    var questions := _load_questions()
    _configure_quiz_gates(questions)
    _spawn_player()

func _load_questions() -> Dictionary:
    var file := FileAccess.open(QUESTIONS_PATH, FileAccess.READ)
    if file == null:
        push_error("Could not open questions JSON at %s" % QUESTIONS_PATH)
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("Could not parse questions JSON")
        return {}
    return parsed

func _configure_quiz_gates(data: Dictionary) -> void:
    var lookup := {}
    for q in data.get("questions", []):
        lookup[q.id] = q
    for gate in get_tree().get_nodes_in_group("quiz_gate"):
        var q = lookup.get(gate.question_id)
        if q == null:
            push_error("No question found for gate id: %s" % gate.question_id)
            continue
        var correct: String = "left" if int(q.correct_index) == 0 else "right"
        gate.configure(q.text, q.answers[0], q.answers[1], correct)

func _spawn_player() -> void:
    var player := player_scene.instantiate()
    add_child(player)
    player.global_position = $PlayerStart.global_position
    player.respawn_position = $PlayerStart.global_position
```

---

## Level Layout — `scenes/levels/level_01.tscn`

Keep all existing nodes (StartPlatform, the original jump platforms, PlayerStart, sun, environment). After the final existing platform, build out the quiz section:

1. **Approach1** — a normal `StaticBody3D` platform (size `8 × 0.5 × 4`), placed ~3 units past the last existing platform. This is the launch pad for Gate 1.
2. **Gate1** — instance of `quiz_gate.tscn`, placed so its origin is ~6 units forward of Approach1. Set `question_id = "q01_game_created"`.
3. **Reconverge1** — a normal platform `8 × 0.5 × 4`, placed ~6 units forward of Gate1's origin (i.e. accessible from either Gate1 platform via a forward jump).
4. **Gate2** — instance of `quiz_gate.tscn`, ~6 units forward of Reconverge1. Set `question_id = "q02_axels_color"`.
5. **Reconverge2** — same as Reconverge1 but in front of Gate2.
6. **Gate3** — instance of `quiz_gate.tscn`, ~6 units forward of Reconverge2. Set `question_id = "q03_axerooms_created"`.
7. **FinishPlatform** — a `StaticBody3D` platform `8 × 0.5 × 8`, ~6 units forward of Gate3. Material: bright green StandardMaterial3D.
8. **FinishLabel** — `Label3D` 4 units above FinishPlatform's center, text `"FINISH!"`. Same billboard / outline / pixel_size settings as gate labels but `pixel_size = 0.02` (bigger).

All gate instances must be in the `"quiz_gate"` group (group is set on the QuizGate scene root, so this should be automatic when instancing — verify in the editor).

Vertical alignment: keep all of these at roughly the same Y as the existing platforms. Don't introduce height variation in the quiz section yet; that's a later difficulty knob.

---

## Player Update — `scenes/player/player.tscn`

Add the **Player** root node to the group `"player"`. In the editor: select Player → Node panel → Groups tab → add `player`. (Alternative: add `add_to_group("player")` to the top of `_ready()` in `player.gd`.)

Without this, the gates' detection won't fire — the gate scripts filter on `body.is_in_group("player")`.

---

## Verification Checklist

- [ ] Project runs without errors and without console warnings about JSON or missing questions
- [ ] At Gate 1, the question "When was this game created?" floats in 3D above the platforms
- [ ] Each platform has its answer floating above it (e.g. "May 9, 2026" above one, "August 2025" above the other)
- [ ] Labels remain readable from any camera angle (billboarding is working)
- [ ] Landing on the wrong platform: it turns red, waits ~1.5s, then disappears
- [ ] If the player is still on the wrong platform when it vanishes: they fall and respawn at the start
- [ ] If the player jumps off the wrong platform forward (to the reconverge) before it explodes: they survive
- [ ] Landing on the correct platform: nothing happens visually; the player can continue forward
- [ ] All three gates work in sequence: q01 → q02 → q03
- [ ] After Gate 3, the green Finish platform with "FINISH!" floating text is reachable
- [ ] Editing `assets/questions.json` (e.g. swapping correct_index from 0 to 1) and re-running flips which platform is the right one — confirms the gates are reading from JSON

---

## Do NOT
- Do **not** add particle effects, sound effects, screen shake, or end-of-level UI yet — those are separate prompts.
- Do **not** add the slap mechanic, store, coins, or any other features in this prompt.
- Do **not** hard-code questions inside `quiz_gate.gd` or `level.gd`. Questions live in JSON, period.
- Do **not** alter the player movement script unless absolutely necessary. The only allowed player change is adding it to the `"player"` group.
- Do **not** change the renderer or any project-level settings.

---

## When Done

1. Commit with message: `Quiz gates: side-by-side forks, JSON question pool, three seed questions`
2. Update `CLAUDE.md`:
   - **Current Features**: add "Quiz gates with side-by-side fork platforms, JSON-driven question pool, wrong-answer explosion"
   - **Planned / In-Progress Features → Quiz / Branching Platforms**: mark the basic gate as done; leave variable answer counts, audio, and particle FX as still planned
3. Move this prompt file from `prompts/ready/` to `prompts/done/`
