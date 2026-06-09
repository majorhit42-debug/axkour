class_name CandylandProps
extends RefCounted

static func make_lollipop(color: Color) -> Node3D:
	var root := Node3D.new()

	var stick := MeshInstance3D.new()
	var stick_mesh := CylinderMesh.new()
	stick_mesh.top_radius = 0.12
	stick_mesh.bottom_radius = 0.12
	stick_mesh.height = 6.0
	stick.mesh = stick_mesh
	var stick_mat := StandardMaterial3D.new()
	stick_mat.albedo_color = Color(0.627, 0.376, 0.188)
	stick_mat.roughness = 0.7
	stick.set_surface_override_material(0, stick_mat)
	stick.position = Vector3(0, 3.0, 0)
	root.add_child(stick)

	var candy := MeshInstance3D.new()
	var candy_mesh := SphereMesh.new()
	candy_mesh.radius = 1.2
	candy_mesh.height = 2.4
	candy.mesh = candy_mesh
	var candy_mat := StandardMaterial3D.new()
	candy_mat.albedo_color = color
	candy_mat.roughness = 0.3
	candy_mat.emission_enabled = true
	candy_mat.emission = color
	candy_mat.emission_energy_multiplier = 0.1
	candy.set_surface_override_material(0, candy_mat)
	candy.position = Vector3(0, 7.2, 0)
	root.add_child(candy)

	return root

static func make_donut(base_color: Color, frosting_color: Color) -> Node3D:
	var root := Node3D.new()

	var body := MeshInstance3D.new()
	var body_mesh := TorusMesh.new()
	body_mesh.inner_radius = 0.6
	body_mesh.outer_radius = 1.5
	body.mesh = body_mesh
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = base_color
	body_mat.roughness = 0.5
	body.set_surface_override_material(0, body_mat)
	root.add_child(body)

	var frost := MeshInstance3D.new()
	var frost_mesh := TorusMesh.new()
	frost_mesh.inner_radius = 0.6
	frost_mesh.outer_radius = 1.4
	frost.mesh = frost_mesh
	var frost_mat := StandardMaterial3D.new()
	frost_mat.albedo_color = frosting_color
	frost_mat.roughness = 0.4
	frost_mat.emission_enabled = true
	frost_mat.emission = frosting_color
	frost_mat.emission_energy_multiplier = 0.08
	frost.set_surface_override_material(0, frost_mat)
	frost.position = Vector3(0, 0.15, 0)
	root.add_child(frost)

	var sprinkle_colors := [
		Color(1.0, 0.769, 0.847),
		Color(0.769, 0.941, 0.847),
		Color(0.769, 0.863, 0.941),
		Color(0.863, 0.769, 0.941),
		Color(1.0, 0.941, 0.769),
	]
	for i in 11:
		var angle := (float(i) / 11.0) * TAU
		var r := 1.0
		var sp := MeshInstance3D.new()
		var sp_mesh := BoxMesh.new()
		sp_mesh.size = Vector3(0.1, 0.05, 0.1)
		sp.mesh = sp_mesh
		var sp_mat := StandardMaterial3D.new()
		sp_mat.albedo_color = sprinkle_colors[i % sprinkle_colors.size()]
		sp.set_surface_override_material(0, sp_mat)
		sp.position = Vector3(cos(angle) * r, 0.22, sin(angle) * r)
		sp.rotation = Vector3(0, float(i) * 0.6, 0)
		root.add_child(sp)

	return root

static func make_cloud(color: Color) -> Node3D:
	var root := Node3D.new()
	var offsets := [
		Vector3(0.0, 0.0, 0.0),
		Vector3(1.2, 0.3, 0.3),
		Vector3(-1.0, 0.2, -0.2),
		Vector3(0.4, 0.5, -0.8),
		Vector3(-0.5, -0.1, 0.7),
	]
	var radii := [1.2, 0.9, 1.0, 0.8, 1.5]
	for i in offsets.size():
		var sphere := MeshInstance3D.new()
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = radii[i]
		sphere_mesh.height = radii[i] * 2.0
		sphere.mesh = sphere_mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.9
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.1
		sphere.set_surface_override_material(0, mat)
		sphere.position = offsets[i]
		root.add_child(sphere)
	return root
