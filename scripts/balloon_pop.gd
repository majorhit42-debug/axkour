extends Node3D

func _ready() -> void:
	var stream = load("res://assets/audio/pop.mp3")
	if stream:
		$Sound.stream = stream
		$Sound.play()

	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(1, 0.3, 0.3), Color(0.3, 0.5, 1), Color(1, 1, 0.3),
		Color(0.3, 1, 0.4), Color(1, 0.4, 0.7)
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	$Confetti.color_ramp = gradient
	$Confetti.restart()

	$Timer.timeout.connect(queue_free)
