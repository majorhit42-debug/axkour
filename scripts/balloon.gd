extends RigidBody3D

@export var placer: Node3D = null  # player who placed this — reserved for future combat

var _popped: bool = false

func _ready() -> void:
	var palette := [
		Color(1, 0.3, 0.3), Color(0.3, 0.5, 1), Color(1, 1, 0.3),
		Color(0.3, 1, 0.4), Color(1, 0.4, 0.7), Color(1, 0.6, 0.2), Color(0.7, 0.3, 1)
	]
	var c: Color = palette[randi() % palette.size()]
	_build_meshes(c)
	$PopTrigger.body_entered.connect(_on_pop_trigger)

func _build_meshes(c: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.4

	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.18
	body_mesh.height = 0.36
	$Body.mesh = body_mesh
	$Body.set_surface_override_material(0, mat)

	var knot_mesh := CylinderMesh.new()
	knot_mesh.top_radius = 0.03
	knot_mesh.bottom_radius = 0.05
	knot_mesh.height = 0.05
	$Knot.mesh = knot_mesh
	$Knot.set_surface_override_material(0, mat)

	var string_mat := StandardMaterial3D.new()
	string_mat.albedo_color = Color(0.25, 0.25, 0.25)
	var string_mesh := CylinderMesh.new()
	string_mesh.top_radius = 0.002
	string_mesh.bottom_radius = 0.002
	string_mesh.height = 0.4
	$String.mesh = string_mesh
	$String.set_surface_override_material(0, string_mat)

func _on_pop_trigger(body: Node) -> void:
	if _popped:
		return
	if body is StaticBody3D:
		return
	if body == self:
		return
	pop()

func pop() -> void:
	_popped = true
	var pop_fx = preload("res://scenes/effects/balloon_pop.tscn").instantiate()
	get_tree().current_scene.add_child(pop_fx)
	pop_fx.global_position = global_position
	queue_free()
