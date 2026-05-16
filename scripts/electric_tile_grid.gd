extends Node3D

const ELECTRIC_TILE := preload("res://scenes/hazard/electric_tile.tscn")
const TILE_SIZE := 2.0
const ARC_NEIGHBOR_DIST := 2.5
const ARC_PLAYER_DIST := 10.0
const ARC_DURATION := 0.3

# E = electric (deadly, gold), S = safe (gold, harmless)
# Adjacent E pairs arc to each other. Safe path: right side of row 1, left side of row 3.
@export_multiline var pattern: String = """
S S S S
E E S S
S S S S
S S E E
S S S S
S S S S
"""

var _electric_tiles: Array = []
var _arc_timer: float = 1.0

func _ready() -> void:
	_build_grid()

func _build_grid() -> void:
	var rows := pattern.strip_edges().split("\n", false)
	for z_idx in rows.size():
		var row_str: String = rows[z_idx].strip_edges()
		if row_str.is_empty():
			continue
		var cells := row_str.split(" ", false)
		for x_idx in cells.size():
			var ch: String = cells[x_idx].strip_edges().to_upper()
			if ch.is_empty():
				continue
			var pos := Vector3(x_idx * TILE_SIZE, 0, z_idx * TILE_SIZE)
			if ch == "E":
				var tile := ELECTRIC_TILE.instantiate()
				add_child(tile)
				tile.position = pos
				_electric_tiles.append(tile)
			else:
				_spawn_safe_tile(pos)

func _spawn_safe_tile(pos: Vector3) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = pos

	var mesh_inst := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2, 0.5, 2)
	mesh_inst.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.1)
	mesh_inst.set_surface_override_material(0, mat)
	body.add_child(mesh_inst)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 0.5, 2)
	col.shape = shape
	body.add_child(col)

func _process(delta: float) -> void:
	if _electric_tiles.is_empty():
		return
	if not _is_player_near():
		return
	_arc_timer -= delta
	if _arc_timer <= 0.0:
		_fire_random_arc()
		_arc_timer = randf_range(0.5, 1.5)

func _is_player_near() -> bool:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return false
	var player: Node3D = players[0]
	for tile in _electric_tiles:
		if is_instance_valid(tile) and tile.global_position.distance_to(player.global_position) <= ARC_PLAYER_DIST:
			return true
	return false

func _fire_random_arc() -> void:
	var pairs: Array = []
	for i in _electric_tiles.size():
		for j in range(i + 1, _electric_tiles.size()):
			var a = _electric_tiles[i]
			var b = _electric_tiles[j]
			if not is_instance_valid(a) or not is_instance_valid(b):
				continue
			if a.global_position.distance_to(b.global_position) <= ARC_NEIGHBOR_DIST:
				pairs.append([a, b])
	if pairs.is_empty():
		return
	var pair: Array = pairs[randi() % pairs.size()]
	var tile_a = pair[0]
	var tile_b = pair[1]
	if is_instance_valid(tile_a) and is_instance_valid(tile_b):
		tile_a.flash_arc_to(tile_b.global_position, ARC_DURATION)
