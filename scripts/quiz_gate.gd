extends Node3D
class_name QuizGate

@export var question_id: String = ""
@export var explode_delay: float = 1.5

var correct_side: String = "left"
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
