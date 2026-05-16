extends Area3D

@export var target_scene: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and target_scene != "":
		get_tree().change_scene_to_file(target_scene)
