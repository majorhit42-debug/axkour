class_name BackroomsProps
# Static factory for The Axerooms (level_03) decoration, same idea as CandylandProps.
# Everything is Godot primitives plus small textures painted in code, so there are no
# external assets. Materials are cached: every carpet platform shares one material,
# which keeps draw-call state changes down on WebGL.

const WALLPAPER_A := Color(0.86, 0.79, 0.45)
const WALLPAPER_B := Color(0.78, 0.71, 0.38)
const CARPET      := Color(0.62, 0.55, 0.36)
const CEILING     := Color(0.80, 0.76, 0.60)
const PANEL_LIGHT := Color(1.0, 0.97, 0.82)
const GOLD        := Color(1.0, 0.80, 0.25)

static var _carpet_mat: StandardMaterial3D
static var _wallpaper_mat: StandardMaterial3D
static var _gold_wallpaper_mat: StandardMaterial3D
static var _gold_carpet_mat: StandardMaterial3D
static var _ceiling_mat: StandardMaterial3D
static var _panel_mat: StandardMaterial3D
static var _trim_mat: StandardMaterial3D

# --- Materials -------------------------------------------------------------------

static func carpet_material() -> StandardMaterial3D:
	if _carpet_mat == null:
		_carpet_mat = _textured(_speckle_texture(CARPET, 0.06), 0.25)
	return _carpet_mat

static func wallpaper_material() -> StandardMaterial3D:
	if _wallpaper_mat == null:
		_wallpaper_mat = _textured(_stripe_texture(WALLPAPER_A, WALLPAPER_B), 0.5)
	return _wallpaper_mat

static func gold_wallpaper_material() -> StandardMaterial3D:
	if _gold_wallpaper_mat == null:
		_gold_wallpaper_mat = _textured(_stripe_texture(GOLD, GOLD.darkened(0.18)), 0.5)
		_gold_wallpaper_mat.metallic = 0.6
		_gold_wallpaper_mat.emission_enabled = true
		_gold_wallpaper_mat.emission = GOLD
		_gold_wallpaper_mat.emission_energy_multiplier = 0.15
	return _gold_wallpaper_mat

static func gold_carpet_material() -> StandardMaterial3D:
	if _gold_carpet_mat == null:
		_gold_carpet_mat = _textured(_speckle_texture(GOLD.darkened(0.1), 0.08), 0.25)
		_gold_carpet_mat.emission_enabled = true
		_gold_carpet_mat.emission = GOLD
		_gold_carpet_mat.emission_energy_multiplier = 0.12
	return _gold_carpet_mat

static func ceiling_material() -> StandardMaterial3D:
	if _ceiling_mat == null:
		_ceiling_mat = StandardMaterial3D.new()
		_ceiling_mat.albedo_color = CEILING
		_ceiling_mat.roughness = 1.0
	return _ceiling_mat

static func panel_material() -> StandardMaterial3D:
	if _panel_mat == null:
		_panel_mat = make_panel_material()
	return _panel_mat

# Each flickering light needs its own copy so dimming one doesn't dim them all.
static func make_panel_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = PANEL_LIGHT
	m.emission_enabled = true
	m.emission = PANEL_LIGHT
	m.emission_energy_multiplier = 2.5
	return m

static func trim_material() -> StandardMaterial3D:
	if _trim_mat == null:
		_trim_mat = StandardMaterial3D.new()
		_trim_mat.albedo_color = Color(0.45, 0.38, 0.22)
	return _trim_mat

# Triplanar so one small texture tiles at the same scale on a 4x4 platform and a
# 50-unit catwalk without per-mesh UV work.
static func _textured(tex: Texture2D, uv_scale: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * uv_scale
	m.roughness = 1.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m

static func _stripe_texture(a: Color, b: Color) -> ImageTexture:
	var img := Image.create(64, 64, true, Image.FORMAT_RGB8)
	for x in 64:
		# Wide stripe, thin stripe, and a faint dotted line between them — the
		# classic mono-yellow office wallpaper read from a distance.
		var c := a if (x % 16) < 11 else b
		for y in 64:
			var px := c
			if (x % 16) == 13 and (y % 4) < 2:
				px = a.lerp(b, 0.5)
			img.set_pixel(x, y, px)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func _speckle_texture(base: Color, amount: float) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7  # same carpet every run
	var img := Image.create(64, 64, true, Image.FORMAT_RGB8)
	for x in 64:
		for y in 64:
			var v := rng.randf_range(-amount, amount)
			img.set_pixel(x, y, Color(base.r + v, base.g + v, base.b + v * 0.6))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

# Swaps the material on every MeshInstance3D under nodes in the "carpet" /
# "wallpaper" / "gold_carpet" / "gold_wallpaper" groups. Platforms are laid out in
# the .tscn with a flat colour so they read in the editor; this dresses them at runtime.
static func dress_groups(tree: SceneTree) -> void:
	_dress(tree, "carpet", carpet_material())
	_dress(tree, "wallpaper", wallpaper_material())
	_dress(tree, "gold_carpet", gold_carpet_material())
	_dress(tree, "gold_wallpaper", gold_wallpaper_material())

static func _dress(tree: SceneTree, group: String, mat: Material) -> void:
	for node in tree.get_nodes_in_group(group):
		for child in node.get_children():
			if child is MeshInstance3D:
				child.set_surface_override_material(0, mat)

# --- Props -----------------------------------------------------------------------

static func _box(size: Vector3, mat: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	return mi

# A free-standing chunk of wallpapered wall with a baseboard. Visual only — walls
# float beside the course, and colliding with them would just snag players.
static func make_wall(length: float, height: float, gold := false) -> Node3D:
	var root := Node3D.new()
	var mat := gold_wallpaper_material() if gold else wallpaper_material()
	root.add_child(_box(Vector3(0.3, height, length), mat, Vector3(0, height * 0.5, 0)))
	root.add_child(_box(Vector3(0.36, 0.25, length), trim_material(), Vector3(0, 0.12, 0)))
	return root

# A long strip of drop ceiling with fluorescent panels set into it. Panels are one
# MultiMesh, so 60+ lights cost a single draw call. Visual only: a solid ceiling
# would stop the quiz-explosion knockback and make the spring-arm camera clip.
static func make_ceiling(length: float, width: float, spacing: float = 6.0) -> Node3D:
	var root := Node3D.new()
	root.add_child(_box(Vector3(width, 0.2, length), ceiling_material()))
	var columns := [-width * 0.25, width * 0.25]
	var rows := int(length / spacing)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var panel := BoxMesh.new()
	panel.size = Vector3(1.4, 0.06, 2.6)
	mm.mesh = panel
	mm.instance_count = rows * columns.size()
	var i := 0
	for r in rows:
		for cx in columns:
			var z := -length * 0.5 + spacing * (r + 0.5)
			mm.set_instance_transform(i, Transform3D(Basis(), Vector3(cx, -0.12, z)))
			i += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = panel_material()
	root.add_child(mmi)
	return root

# A single hanging fluorescent fixture. Returns the root; the glowing tube is the
# child named "Tube" so callers can flicker it via its own material.
static func make_lamp() -> Node3D:
	var root := Node3D.new()
	root.add_child(_box(Vector3(1.6, 0.12, 0.5), trim_material()))
	var tube := _box(Vector3(1.4, 0.08, 0.3), make_panel_material(), Vector3(0, -0.09, 0))
	tube.name = "Tube"
	root.add_child(tube)
	root.add_child(_box(Vector3(0.03, 1.5, 0.03), trim_material(), Vector3(0, 0.8, 0)))
	return root

static func make_pillar(height: float) -> Node3D:
	var root := Node3D.new()
	root.add_child(_box(Vector3(1.0, height, 1.0), wallpaper_material(), Vector3(0, height * 0.5, 0)))
	root.add_child(_box(Vector3(1.06, 0.25, 1.06), trim_material(), Vector3(0, 0.12, 0)))
	return root

# A glowing EXIT sign — green, so it is the one colour in the level that isn't yellow.
static func make_exit_sign(text: String = "EXIT", color := Color(0.3, 1.0, 0.45)) -> Node3D:
	var root := Node3D.new()
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.05, 0.08, 0.05)
	root.add_child(_box(Vector3(2.2, 0.8, 0.15), back_mat))
	var label := Label3D.new()
	label.text = text
	label.font_size = 96
	label.pixel_size = 0.006
	label.modulate = color
	label.outline_size = 0
	label.position = Vector3(0, 0, -0.09)
	label.rotation.y = PI  # read from the -Z side, i.e. by racers approaching along +Z
	root.add_child(label)
	return root
