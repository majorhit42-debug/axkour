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
