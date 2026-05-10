extends Node3D

const SHAKE_INTENSITY := 0.1
const SHAKE_DURATION := 0.25
const LIFETIME := 1.5

func _ready() -> void:
	_setup_core()
	_setup_embers()
	_setup_light()
	_shake_camera()
	await get_tree().create_timer(LIFETIME).timeout
	queue_free()

func _setup_core() -> void:
	var core: CPUParticles3D = $Core
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	core.mesh = sphere
	core.amount = 30
	core.lifetime = 0.5
	core.one_shot = true
	core.explosiveness = 1.0
	core.direction = Vector3(0, 1, 0)
	core.spread = 180.0
	core.initial_velocity_min = 1.0
	core.initial_velocity_max = 3.0
	core.gravity = Vector3.ZERO
	core.scale_amount_min = 1.0
	core.scale_amount_max = 1.5
	core.color = Color(1.0, 0.2, 0.1)
	core.emitting = true

func _setup_embers() -> void:
	var embers: CPUParticles3D = $Embers
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	embers.mesh = sphere
	embers.amount = 50
	embers.lifetime = 1.0
	embers.one_shot = true
	embers.explosiveness = 1.0
	embers.direction = Vector3(0, 1, 0)
	embers.spread = 180.0
	embers.initial_velocity_min = 4.0
	embers.initial_velocity_max = 8.0
	embers.gravity = Vector3(0, -8, 0)
	embers.scale_amount_min = 0.5
	embers.scale_amount_max = 1.0
	embers.color = Color(1.0, 0.6, 0.0)
	embers.emitting = true

func _setup_light() -> void:
	var light: OmniLight3D = $Light
	light.omni_range = 8.0
	light.light_color = Color(1.0, 0.5, 0.2)
	light.light_energy = 4.0
	var tween := create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.4)

func _shake_camera() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("shake_camera"):
			p.shake_camera(SHAKE_INTENSITY, SHAKE_DURATION)
