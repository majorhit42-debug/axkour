extends Area3D
class_name Coin

const SPARKLE_SCENE := preload("res://scenes/effects/sparkle.tscn")
const ROTATION_SPEED := 4.0  # radians per second

var _collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_visual()

func _setup_visual() -> void:
	var cyl := CylinderMesh.new()
	cyl.height = 0.1
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.4
	$Mesh.mesh = cyl
	# Orient the cylinder so its flat face is visible from the side (coin "stands up")
	$Mesh.rotation = Vector3(0, 0, PI / 2)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.1)
	mat.metallic = 1.0
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.1)
	mat.emission_energy_multiplier = 0.4
	$Mesh.set_surface_override_material(0, mat)

func _process(delta: float) -> void:
	if _collected:
		return
	rotate_y(ROTATION_SPEED * delta)

func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	CoinWallet.add_coins(1)
	_spawn_sparkle()
	queue_free()

func _spawn_sparkle() -> void:
	var sparkle := SPARKLE_SCENE.instantiate()
	get_tree().current_scene.add_child(sparkle)
	sparkle.global_position = global_position
