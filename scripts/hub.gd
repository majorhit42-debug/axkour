extends Node3D

@export var player_scene: PackedScene

# The shop pavilion sits at the world origin; spawns face it.
const PAVILION_CENTER := Vector3(0, 1, 0)

func _ready() -> void:
	var player := player_scene.instantiate()
	add_child(player)

	if GameState.respawning_from_death:
		GameState.respawning_from_death = false
		var pod_spot: Marker3D = $ResurrectionPodSpot
		player.global_position = pod_spot.global_position
		player.respawn_position = $PlayerStart.global_position
		player.camera_y = pod_spot.global_position.y
		player.set_spawn_facing(PAVILION_CENTER - pod_spot.global_position)
		player.is_dead = true
		_trigger_materialization(pod_spot.global_position, player)
	else:
		player.global_position = $PlayerStart.global_position
		player.respawn_position = $PlayerStart.global_position
		player.camera_y = $PlayerStart.global_position.y
		player.set_spawn_facing(PAVILION_CENTER - $PlayerStart.global_position)

func _trigger_materialization(pos: Vector3, player: Node3D) -> void:
	_spawn_pod_burst(pos)

	var pod_light: OmniLight3D = $ResurrectionPod/PodLight
	var tween := create_tween()
	tween.tween_property(pod_light, "light_energy", 6.0, 0.2)
	tween.tween_property(pod_light, "light_energy", 1.5, 0.2)

	await get_tree().create_timer(0.5).timeout
	player.unlock_input()

func _spawn_pod_burst(pos: Vector3) -> void:
	var particles := CPUParticles3D.new()
	add_child(particles)
	particles.global_position = pos
	particles.amount = 30
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 40.0
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 5.0
	particles.gravity = Vector3(0, -3, 0)
	particles.scale_amount_min = 0.08
	particles.scale_amount_max = 0.12
	particles.color = Color(0.6, 0.9, 1.0, 1.0)
	particles.mesh = SphereMesh.new()
	particles.emitting = true
	get_tree().create_timer(1.5).timeout.connect(particles.queue_free)
