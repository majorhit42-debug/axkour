# Prompt 14 — Variable-Answer Quiz Gates

## Goal
Extend the QuizGate system to support N answer choices (currently hardcoded to 2 forks). Specifically support 2, 3, or 4 fork platforms per gate, configurable per-question in the JSON pool. Existing 2-answer questions in level_01 must continue to work without modification — this is a backwards-compatible enhancement, not a rewrite.

## Question JSON Format

### New shape
Extend `assets/questions.json` to support an array of wrong answers:

```json
{
  "id": "q04",
  "question": "When were Legos invented?",
  "correct_answer": "1932",
  "wrong_answers": ["1965", "1908", "1979"]
}
```

`wrong_answers` array length determines how many wrong fork platforms are spawned. Total platforms = 1 (correct) + N (wrong).

### Backwards compatibility
Existing questions use the singular `wrong_answer` field. The loader must treat:
```json
{ "correct_answer": "X", "wrong_answer": "Y" }
```
as if it were:
```json
{ "correct_answer": "X", "wrong_answers": ["Y"] }
```

This means q01, q02, q03 in the existing pool must work as 2-platform gates without any JSON edits.

### Validation
- 0 wrong answers → log a warning and skip the gate (player would have nothing to fail on)
- More than 3 wrong answers (5+ platforms total) → log a warning but still spawn (might look cramped)

## QuizGate Scene & Script Changes

### Scene changes (`scenes/quiz/quiz_gate.tscn`)
- Remove the hardcoded left and right fork platform children
- Add a `ForkContainer` Node3D as a child of the gate root — this is where the fork platforms get parented at runtime
- Keep the question Label3D, approach platform, and reconverge platform as-is

### Script changes (`scripts/quiz_gate.gd`)
On `_ready()`:
1. Load the question by `question_id` (existing behavior)
2. Read both formats: `wrong_answers` array preferred, fall back to `wrong_answer` singular
3. Build the answer list: [correct_answer] + wrong_answers
4. **Shuffle the list** so the correct answer isn't always in the same position across runs
5. Compute X positions for N total platforms (N = answer list length):
   - N=2 → x positions [-4, +4] (existing 8-unit spacing maintained)
   - N=3 → x positions [-6, 0, +6] (6-unit spacing)
   - N=4 → x positions [-7.5, -2.5, +2.5, +7.5] (5-unit spacing)
6. For each answer, build a fork platform under ForkContainer:
   - Position at computed X, same Z as the existing fork was
   - Add a billboarded Label3D above showing the answer text (font size 28, same style as before)
   - Store `is_correct` as metadata via `set_meta("is_correct", bool)` on the platform node
7. Reuse existing collision/explosion logic — on player contact, read `get_meta("is_correct")`; if false, trigger the existing explosion + death flow

### Reconverge platform
The reconverge platform after the fork must be wide enough to land on from any fork position. For N=4 at ±7.5 spread, the reconverge needs at least 6 units wide (centered on x=0). Update the existing reconverge platform width in level_01 from 4 to 6 to be safe — affects all gates uniformly.

## Add the Lego question

Add to `assets/questions.json`:
```json
{
  "id": "q04",
  "question": "When were Legos invented?",
  "correct_answer": "1932",
  "wrong_answers": ["1965", "1908", "1979"]
}
```

This question is used by level_02 in the next prompt.

## Verification

1. Boot level_01 — existing q01, q02, q03 gates still render with 2 fork platforms each, no visual or behavioral regression
2. Wrong-answer platforms still explode via the existing flow
3. Correct-answer platforms still pass through normally
4. Re-launch level_01 several times → the position of the correct answer should vary across runs (shuffling works)
5. Quick test: temporarily edit q01 in the JSON to have `wrong_answers: ["A", "B", "C"]` instead of singular — should spawn 4 platforms. Revert after testing.
6. Same test with a 3-answer version → 3 platforms.

## Do NOT
- Do not break the existing 3 quiz gates in level_01
- Do not change the explosion or death flow
- Do not store `is_correct` in the JSON file (it's runtime metadata on the platform nodes)
- Do not hardcode N anywhere — it must be derived from the JSON
- Do not introduce new question types (true/false, image-based, etc.) — just N-way fork
- Do not migrate the existing q01–q03 questions to the new array format — the loader handles both shapes

## Files Involved
- Modified: `assets/questions.json` (add q04, no migration of existing entries)
- Modified: `scenes/quiz/quiz_gate.tscn` (remove fixed forks, add ForkContainer)
- Modified: `scripts/quiz_gate.gd` (dynamic spawning, shuffle, both JSON shapes)
- Modified: `scenes/levels/level_01.tscn` (reconverge platforms widened from 4 to 6)

## Update CLAUDE.md
Under Current Features → Quiz Gates: note variable-answer support (2/3/4 fork platforms), updated JSON format with backwards compat, mention the shuffle so the correct answer position varies per run.
