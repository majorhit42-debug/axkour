extends Node3D

const SHAKE_INTENSITY := 0.4
const SHAKE_DURATION := 0.5
const KNOCKBACK_FORCE := 30.0
const KNOCKBACK_UP := 40.0
const KNOCKBACK_RADIUS := 8.0
const LIFETIME := 1.5

func _ready() -> void:
	call_deferred("_start_explosion")

func _start_explosion() -> void:
	_setup_flash()
	_setup_core()
	_setup_embers()
	_setup_light()
	_shake_camera()
	_knockback_players()
	await get_tree().create_timer(LIFETIME).timeout
	queue_free()

func _setup_flash() -> void:
	var flash: MeshInstance3D = $FlashSphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.55, 0.1, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.0)
	mat.emission_energy_multiplier = 4.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	flash.material_override = mat
	flash.scale = Vector3.ONE * 0.2
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector3.ONE * 5.0, 0.15)
	tween.tween_property(mat, "albedo_color", Color(1.0, 0.55, 0.1, 0.0), 0.3)

func _setup_core() -> void:
	var core: CPUParticles3D = $Core
	core.amount = 60
	core.lifetime = 0.7
	core.one_shot = true
	core.explosiveness = 1.0
	core.direction = Vector3(0, 1, 0)
	core.spread = 180.0
	core.initial_velocity_min = 3.0
	core.initial_velocity_max = 7.0
	core.gravity = Vector3.ZERO
	core.scale_amount_min = 1.5
	core.scale_amount_max = 2.5
	core.color = Color(1.0, 0.2, 0.1)
	core.emitting = false
	core.restart()

func _setup_embers() -> void:
	var embers: CPUParticles3D = $Embers
	embers.amount = 80
	embers.lifetime = 1.2
	embers.one_shot = true
	embers.explosiveness = 1.0
	embers.direction = Vector3(0, 1, 0)
	embers.spread = 180.0
	embers.initial_velocity_min = 6.0
	embers.initial_velocity_max = 14.0
	embers.gravity = Vector3(0, -8, 0)
	embers.scale_amount_min = 0.8
	embers.scale_amount_max = 1.5
	embers.color = Color(1.0, 0.6, 0.0)
	embers.emitting = false
	embers.restart()

func _setup_light() -> void:
	var light: OmniLight3D = $Light
	light.omni_range = 12.0
	light.light_color = Color(1.0, 0.5, 0.2)
	light.light_energy = 8.0
	var tween := create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.4)

func _shake_camera() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("shake_camera"):
			p.shake_camera(SHAKE_INTENSITY, SHAKE_DURATION)

func _knockback_players() -> void:
	# "racer" not "player": CPU racers get launched by their own wrong answer too.
	# Camera shake above stays player-only.
	for p in get_tree().get_nodes_in_group("racer"):
		var dist := global_position.distance_to(p.global_position)
		if dist <= KNOCKBACK_RADIUS:
			var dir: Vector3 = (p.global_position - global_position).normalized()
			var force: Vector3 = Vector3(dir.x * KNOCKBACK_FORCE, KNOCKBACK_UP, dir.z * KNOCKBACK_FORCE)
			if p.has_method("apply_knockback"):
				p.apply_knockback(force)
