extends Node3D

const LIFETIME := 1.0

func _ready() -> void:
	_setup_particles()
	await get_tree().create_timer(LIFETIME).timeout
	queue_free()

func _setup_particles() -> void:
	var p: CPUParticles3D = $Particles
	var sphere := SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	p.mesh = sphere
	p.amount = 15
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 90.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.0
	p.gravity = Vector3(0, -3, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	p.color = Color(1.0, 0.9, 0.3)
	p.emitting = true
