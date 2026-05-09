extends Node3D

@export var player_scene: PackedScene

func _ready() -> void:
	var player = player_scene.instantiate()
	var spawn_point: Marker3D = $PlayerStart
	player.respawn_position = spawn_point.global_position
	player.global_position = spawn_point.global_position
	add_child(player)
