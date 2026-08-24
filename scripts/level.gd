extends Node3D

@export var player_scene: PackedScene

const COURSE_DIRECTION := Vector3(0, 0, 1)

func _ready() -> void:
	_spawn_player()

func _spawn_player() -> void:
	var player := player_scene.instantiate()
	add_child(player)
	player.global_position = $PlayerStart.global_position
	player.respawn_position = $PlayerStart.global_position
	player.set_spawn_facing(COURSE_DIRECTION)
