class_name HatBuilder

# Returns an Array of MeshInstance3D nodes representing the hat.
# scale=1.0 is player-size; use ~0.7 for pedestal display.
static func make_meshes(hat_type: String, color: Color, scale: float) -> Array:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	match hat_type:
		"tophat":
			return [
				_cyl(0.40, 0.40, 0.05, 0.025, mat, scale),
				_cyl(0.20, 0.20, 0.45, 0.275, mat, scale),
			]
		"cone":
			return [_cyl(0.02, 0.30, 0.60, 0.30, mat, scale)]
		"cowboy":
			return [
				_cyl(0.50, 0.50, 0.04, 0.020, mat, scale),
				_cyl(0.22, 0.25, 0.30, 0.190, mat, scale),
			]
	return []

static func _cyl(top_r: float, bot_r: float, h: float, y_center: float,
		mat: StandardMaterial3D, s: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r * s
	mesh.bottom_radius = bot_r * s
	mesh.height = h * s
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.set_surface_override_material(0, mat)
	mi.position = Vector3(0, y_center * s, 0)
	return mi
