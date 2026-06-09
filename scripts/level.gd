extends Node3D

@export var player_scene: PackedScene

func _ready() -> void:
	_spawn_player()

func _spawn_player() -> void:
	var player := player_scene.instantiate()
	add_child(player)
	player.global_position = $PlayerStart.global_position
	player.respawn_position = $PlayerStart.global_position
