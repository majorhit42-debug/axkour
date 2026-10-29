class_name CostumeBuilder
# The middle (torso) and bottom (feet) pieces of each costume. The top piece is the
# hat, still built by HatBuilder. A costume is keyed by its hat_type in shop_items.json:
#   cowboy -> leather vest + belt buckle, boots with spurs
#   tophat -> tux jacket, bow tie and tails, shiny dress shoes
#   cone   -> confetti party shirt, giant rainbow sneakers
#
# Pieces are authored in character space (Y up, +Z = the way the X Bot faces):
#   torso pieces relative to the chest mount (Spine2 bone, ~0.34 above body centre)
#   foot pieces relative to an ankle mount (Left/RightFoot bone)
# CharacterRig.create_bone_mount() cancels each bone's rest rotation so those axes hold
# on the real skeleton. `s` scales everything (1.0 on a racer, ~0.7 on a pedestal).

# Torso shell dimensions, sized to the X Bot's chest with a little clearance.
const HALF_W := 0.19
const FRONT_Z := 0.155
const BACK_Z := -0.165
const SHELL_H := 0.47
const SHELL_Y := -0.035  # shell centre, relative to the chest mount
const WAIST_Y := -0.245  # belt line, at the bottom of the shell

static func make_torso(costume: String, s: float = 1.0) -> Array:
	match costume:
		"cowboy":
			var leather := _mat(Color(0.45, 0.27, 0.12))
			var out := _shell(leather, 0.09, s)
			out.append(_disc(0.035, Vector3(0.12, 0.08, FRONT_Z + 0.02), _mat(Color(1, 0.8, 0.2), 0.8), s))  # sheriff star
			out.append(_box(Vector3(0.28, 0.05, 0.31), Vector3(0, WAIST_Y, -0.005), _mat(Color(0.2, 0.12, 0.06)), s))  # belt
			out.append(_box(Vector3(0.08, 0.06, 0.02), Vector3(0, WAIST_Y, 0.16), _mat(Color(0.95, 0.8, 0.3), 0.9), s))  # buckle
			return out
		"tophat":
			var black := _mat(Color(0.06, 0.06, 0.08))
			var out := _shell(black, 0.05, s)
			out.append(_box(Vector3(0.1, SHELL_H - 0.02, 0.02), Vector3(0, SHELL_Y, FRONT_Z - 0.01), _mat(Color(0.97, 0.97, 0.97)), s))  # shirt front
			var red := _mat(Color(0.85, 0.08, 0.1))
			out.append(_box(Vector3(0.05, 0.06, 0.03), Vector3(-0.035, 0.16, FRONT_Z + 0.02), red, s))  # bow tie
			out.append(_box(Vector3(0.05, 0.06, 0.03), Vector3(0.035, 0.16, FRONT_Z + 0.02), red, s))
			out.append(_box(Vector3(0.025, 0.035, 0.035), Vector3(0, 0.16, FRONT_Z + 0.025), red, s))
			for y in [0.0, -0.07]:
				out.append(_box(Vector3(0.025, 0.025, 0.02), Vector3(0.06, y, FRONT_Z + 0.015), _mat(Color(0.8, 0.8, 0.8), 0.8), s))  # buttons
			out.append(_box(Vector3(0.3, 0.3, 0.03), Vector3(0, WAIST_Y - 0.12, BACK_Z - 0.01), black, s))  # tails
			return out
		"cone":
			var out := _shell(_mat(Color(0.2, 0.8, 0.95)), 0.0, s)
			var confetti := [Color(1, 0.2, 0.6), Color(1, 0.9, 0.1), Color(0.5, 0.2, 1), Color(0.2, 1, 0.4), Color(1, 0.5, 0.1)]
			var rng := RandomNumberGenerator.new()
			rng.seed = 42  # same confetti on every party shirt
			for i in 14:
				var front := i % 2 == 0
				var pos := Vector3(rng.randf_range(-0.15, 0.15), SHELL_Y + rng.randf_range(-0.18, 0.18),
						(FRONT_Z + 0.012) if front else (BACK_Z - 0.012))
				var bit := _box(Vector3(0.035, 0.035, 0.01), pos, _mat(confetti[i % confetti.size()]), s)
				bit.rotation.z = rng.randf_range(0, PI)
				out.append(bit)
			return out
	return []

# One foot's piece; both feet use the same shape.
static func make_foot(costume: String, s: float = 1.0) -> Array:
	match costume:
		"cowboy":
			var boot := _mat(Color(0.3, 0.17, 0.07))
			return [
				_cyl(0.075, 0.07, 0.26, Vector3(0, 0.1, -0.02), boot, s),  # shaft
				_box(Vector3(0.13, 0.14, 0.3), Vector3(0, -0.045, 0.06), boot, s),  # foot
				_box(Vector3(0.11, 0.06, 0.07), Vector3(0, -0.1, -0.06), _mat(Color(0.15, 0.08, 0.03)), s),  # heel
				_cyl(0.022, 0.022, 0.02, Vector3(0, -0.06, -0.11), _mat(Color(0.85, 0.85, 0.9), 0.9), s, true),  # spur
			]
		"tophat":
			var shiny := _mat(Color(0.03, 0.03, 0.04))
			shiny.metallic = 0.4
			shiny.roughness = 0.1
			return [
				_box(Vector3(0.125, 0.12, 0.29), Vector3(0, -0.05, 0.06), shiny, s),
				_box(Vector3(0.1, 0.03, 0.12), Vector3(0, 0.005, -0.02), _mat(Color(0.95, 0.95, 0.95)), s),  # spats
			]
		"cone":
			# Comedy-sized sneakers: wider and longer than the foot.
			return [
				_box(Vector3(0.13, 0.13, 0.36), Vector3(0, -0.045, 0.08), _mat(Color(1, 0.9, 0.15)), s),
				_box(Vector3(0.135, 0.04, 0.38), Vector3(0, -0.12, 0.08), _mat(Color(1, 0.2, 0.6)), s),  # sole
				_box(Vector3(0.135, 0.06, 0.08), Vector3(0, -0.04, 0.23), _mat(Color(0.2, 0.8, 0.95)), s),  # toe cap
				_box(Vector3(0.09, 0.02, 0.1), Vector3(0, 0.025, 0.06), _mat(Color(0.5, 0.2, 1)), s),  # laces
			]
	return []

# Open-fronted shell around the chest: back, two sides, and two front panels leaving
# `gap` of the body showing down the middle (0 = closed shirt).
static func _shell(mat: StandardMaterial3D, gap: float, s: float) -> Array:
	var t := 0.03
	var depth := FRONT_Z - BACK_Z
	var mid_z := (FRONT_Z + BACK_Z) * 0.5
	var out := [
		_box(Vector3(HALF_W * 2.0, SHELL_H, t), Vector3(0, SHELL_Y, BACK_Z), mat, s),
		_box(Vector3(t, SHELL_H, depth), Vector3(-HALF_W, SHELL_Y, mid_z), mat, s),
		_box(Vector3(t, SHELL_H, depth), Vector3(HALF_W, SHELL_Y, mid_z), mat, s),
	]
	var panel_w := HALF_W - gap * 0.5
	for sx in [-1.0, 1.0]:
		out.append(_box(Vector3(panel_w, SHELL_H, t), Vector3(sx * (gap * 0.5 + panel_w * 0.5), SHELL_Y, FRONT_Z), mat, s))
	# Shoulders: a cap over the top so the shell doesn't read as a hollow box.
	out.append(_box(Vector3(HALF_W * 2.0, t, depth), Vector3(0, SHELL_Y + SHELL_H * 0.5, mid_z), mat, s))
	return out

static func _mat(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.35 if metallic > 0.0 else 0.8
	return m

static func _box(size: Vector3, pos: Vector3, mat: Material, s: float) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size * s
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos * s
	return mi

static func _cyl(top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, s: float, sideways := false) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = top_r * s
	cm.bottom_radius = bot_r * s
	cm.height = h * s
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.set_surface_override_material(0, mat)
	mi.position = pos * s
	if sideways:
		mi.rotation.z = PI / 2
	return mi

# A flat disc facing +Z (badges).
static func _disc(r: float, pos: Vector3, mat: Material, s: float) -> MeshInstance3D:
	var mi := _cyl(r, r, 0.01, pos, mat, s)
	mi.rotation.x = PI / 2
	return mi
