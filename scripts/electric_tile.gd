extends StaticBody3D
class_name ElectricTile

const GOLD_COLOR := Color(1.0, 0.85, 0.1)

var _triggered: bool = false

func _ready() -> void:
	_apply_color()
	_setup_sparks()
	_setup_hum()
	$DetectionArea.body_entered.connect(_on_player_entered)

func _apply_color() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GOLD_COLOR
	$Mesh.set_surface_override_material(0, mat)

func _setup_sparks() -> void:
	var sparks := CPUParticles3D.new()
	sparks.name = "SparkParticles"
	sparks.emitting = true
	sparks.amount = 12
	sparks.lifetime = 0.4
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 0.9
	sparks.direction = Vector3(0, 1, 0)
	sparks.spread = 40.0
	sparks.gravity = Vector3.ZERO
	sparks.initial_velocity_min = 1.0
	sparks.initial_velocity_max = 2.5
	sparks.scale_amount_min = 0.2
	sparks.scale_amount_max = 0.3
	sparks.color = Color(0.8, 0.9, 1.0)
	add_child(sparks)
	sparks.position = Vector3(0, 0.3, 0)

func _setup_hum() -> void:
	if not ResourceLoader.exists("res://assets/audio/electric_hum_loop.ogg"):
		return
	var hum := AudioStreamPlayer3D.new()
	hum.name = "ElectricHum"
	hum.stream = load("res://assets/audio/electric_hum_loop.ogg")
	hum.volume_db = -20.0
	hum.max_distance = 4.0
	hum.unit_size = 0.5
	hum.autoplay = true
	add_child(hum)

func flash_arc_to(other_pos: Vector3, duration: float) -> void:
	var from := global_position + Vector3(0, 0.3, 0)
	var to := other_pos + Vector3(0, 0.3, 0)
	var dist := from.distance_to(to)
	if dist < 0.01:
		return
	var mid := (from + to) * 0.5

	var arc := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.15, 0.15, dist)
	arc.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.75, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.75, 1.0)
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc.set_surface_override_material(0, mat)
	get_tree().current_scene.add_child(arc)
	arc.global_position = mid
	arc.look_at(to, Vector3.UP)
	get_tree().create_timer(duration).timeout.connect(arc.queue_free)

func _on_player_entered(body: Node3D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	_electrocute(body)

func _electrocute(player: Node3D) -> void:
	# Blue burst on tile
	var burst := CPUParticles3D.new()
	burst.emitting = false
	burst.one_shot = true
	burst.amount = 30
	burst.lifetime = 0.6
	burst.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 0.5
	burst.direction = Vector3(0, 1, 0)
	burst.spread = 180.0
	burst.gravity = Vector3.ZERO
	burst.initial_velocity_min = 3.0
	burst.initial_velocity_max = 6.0
	burst.color = Color(0.4, 0.75, 1.0)
	get_tree().current_scene.add_child(burst)
	burst.global_position = global_position + Vector3(0, 0.5, 0)
	burst.restart()
	get_tree().create_timer(1.5).timeout.connect(burst.queue_free)

	# Blue light flash
	var flash := OmniLight3D.new()
	flash.light_color = Color(0.3, 0.6, 1.0)
	flash.light_energy = 5.0
	flash.omni_range = 8.0
	get_tree().current_scene.add_child(flash)
	flash.global_position = global_position + Vector3(0, 1.0, 0)
	var tween := flash.create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

	# Dust at player position
	var dust := CPUParticles3D.new()
	dust.emitting = false
	dust.one_shot = true
	dust.amount = 40
	dust.lifetime = 1.5
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = 0.3
	dust.direction = Vector3(0, 1, 0)
	dust.spread = 90.0
	dust.gravity = Vector3(0, -5.0, 0)
	dust.initial_velocity_min = 1.0
	dust.initial_velocity_max = 3.0
	dust.color = Color(0.5, 0.45, 0.35)
	get_tree().current_scene.add_child(dust)
	dust.global_position = player.global_position
	dust.restart()
	get_tree().create_timer(2.5).timeout.connect(dust.queue_free)

	player.die()
