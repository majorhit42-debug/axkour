extends Node3D
class_name QuizGate

const EXPLOSION_SCENE := preload("res://scenes/effects/explosion.tscn")
const QUESTIONS_PATH := "res://assets/questions.json"

@export var question_id: String = ""
@export var explode_delay: float = 0.3

func _ready() -> void:
	var q := _load_question()
	if q.is_empty():
		return
	_build_forks(q)

func _load_question() -> Dictionary:
	var file := FileAccess.open(QUESTIONS_PATH, FileAccess.READ)
	if file == null:
		push_error("QuizGate: cannot open %s" % QUESTIONS_PATH)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("QuizGate: cannot parse questions JSON")
		return {}
	for q in parsed.get("questions", []):
		if q.get("id", "") == question_id:
			return q
	push_error("QuizGate: no question found for id: %s" % question_id)
	return {}

func _normalize(q: Dictionary) -> Dictionary:
	# New format: question + correct_answer + wrong_answers[]
	if q.has("correct_answer") and q.has("wrong_answers"):
		return {"text": q.get("question", ""), "correct": q.correct_answer, "wrong": Array(q.wrong_answers)}
	# Compat: correct_answer + wrong_answer (singular)
	if q.has("correct_answer") and q.has("wrong_answer"):
		return {"text": q.get("question", ""), "correct": q.correct_answer, "wrong": [q.wrong_answer]}
	# Original format: text + answers[] + correct_index
	if q.has("text") and q.has("answers") and q.has("correct_index"):
		var answers: Array = q.answers
		var idx: int = int(q.correct_index)
		var wrong: Array = []
		for i in answers.size():
			if i != idx:
				wrong.append(answers[i])
		return {"text": q.text, "correct": answers[idx], "wrong": wrong}
	push_error("QuizGate: unrecognized question format for id: %s" % question_id)
	return {}

func _build_forks(q: Dictionary) -> void:
	var norm := _normalize(q)
	if norm.is_empty():
		return
	var wrong: Array = norm.wrong
	if wrong.size() == 0:
		push_warning("QuizGate: %s has 0 wrong answers — skipping gate" % question_id)
		return
	if wrong.size() > 3:
		push_warning("QuizGate: %s has %d wrong answers (>3) — spawning anyway" % [question_id, wrong.size()])

	$QuestionLabel.text = norm.text

	var answers: Array = [{"text": norm.correct, "is_correct": true}]
	for w in wrong:
		answers.append({"text": w, "is_correct": false})
	answers.shuffle()

	var x_positions := _x_positions(answers.size())
	var width := _platform_width(answers.size())
	for i in answers.size():
		_build_platform(answers[i], x_positions[i], width)

func _x_positions(n: int) -> Array:
	match n:
		2: return [-4.0, 4.0]
		3: return [-6.0, 0.0, 6.0]
		4: return [-7.5, -2.5, 2.5, 7.5]
		_:
			var spacing := 5.0
			var total := (n - 1) * spacing
			var out := []
			for i in n:
				out.append(-total / 2.0 + i * spacing)
			return out

# Fork width must stay narrower than the gap between _x_positions entries,
# or neighbouring platforms overlap and a player on the correct fork also
# stands inside a wrong fork's trigger area.
func _platform_width(n: int) -> float:
	match n:
		2: return 6.0  # spacing 8 -> 2.0 gap
		3: return 5.0  # spacing 6 -> 1.0 gap
		4: return 4.0  # spacing 5 -> 1.0 gap
		_: return 4.0  # fallback spacing 5 -> 1.0 gap

func _build_platform(answer_data: Dictionary, x: float, width: float) -> void:
	var platform := StaticBody3D.new()
	platform.position = Vector3(x, 0, 0)
	platform.set_meta("is_correct", answer_data.is_correct)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(width, 0.5, 6)
	mesh_inst.mesh = box_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mesh_inst.set_surface_override_material(0, mat)
	platform.add_child(mesh_inst)

	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(width, 0.5, 6)
	col.shape = box_shape
	platform.add_child(col)

	var area := Area3D.new()
	area.position = Vector3(0, 0.75, 0)
	var area_col := CollisionShape3D.new()
	var area_shape := BoxShape3D.new()
	# Inset from the platform edges so a player at the rim can't clip a neighbour.
	area_shape.size = Vector3(width - 0.6, 1, 5.4)
	area_col.shape = area_shape
	area.add_child(area_col)
	area.body_entered.connect(_on_platform_entered.bind(platform))
	platform.add_child(area)

	var label := Label3D.new()
	label.position = Vector3(0, 3, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.012
	label.font_size = 64
	label.outline_size = 8
	label.outline_modulate = Color(0, 0, 0, 1)
	label.text = answer_data.text
	platform.add_child(label)

	$ForkContainer.add_child(platform)

func _on_platform_entered(body: Node3D, platform: StaticBody3D) -> void:
	if not body.is_in_group("racer"): return
	if platform.get_meta("is_correct", false): return
	_trigger_wrong(platform)

# Picks a fork for a CPU racer: the correct one with probability `accuracy`,
# otherwise a random wrong one. Returns the fork's global position.
func choose_fork_position(accuracy: float) -> Vector3:
	var forks := $ForkContainer.get_children()
	if forks.is_empty():
		return global_position
	var correct: Array = []
	var wrong: Array = []
	for f in forks:
		if f.get_meta("is_correct", false):
			correct.append(f)
		else:
			wrong.append(f)
	var pool: Array = correct if (randf() < accuracy and not correct.is_empty()) else wrong
	if pool.is_empty():
		pool = forks
	return pool[randi() % pool.size()].global_position

func _trigger_wrong(platform: StaticBody3D) -> void:
	# Per-platform, not gate-wide: with more than one racer, a bot setting off
	# its fork must not stop another racer's fork from exploding.
	if platform.get_meta("triggered", false): return
	platform.set_meta("triggered", true)
	for child in platform.get_children():
		if child is MeshInstance3D:
			var red_mat := StandardMaterial3D.new()
			red_mat.albedo_color = Color.RED
			child.set_surface_override_material(0, red_mat)
			break
	await get_tree().create_timer(explode_delay).timeout
	_spawn_explosion(platform.global_position)
	platform.queue_free()

func _spawn_explosion(pos: Vector3) -> void:
	var explosion := EXPLOSION_SCENE.instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = pos + Vector3(0, 0.5, 0)
