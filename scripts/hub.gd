extends Node3D

@export var player_scene: PackedScene

func _ready() -> void:
	var player := player_scene.instantiate()
	add_child(player)
	player.global_position = $PlayerStart.global_position
	player.respawn_position = $PlayerStart.global_position
