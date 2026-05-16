extends CanvasLayer

func _ready() -> void:
	var label: Label = $YouDiedLabel
	label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/hub/hub.tscn")
