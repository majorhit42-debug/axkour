extends Node3D

@export var player_scene: PackedScene

const PINK    := Color(1.0,   0.769, 0.847)
const MINT    := Color(0.769, 0.941, 0.847)
const BLUE    := Color(0.769, 0.863, 0.941)
const LAVENDER := Color(0.863, 0.769, 0.941)
const YELLOW  := Color(1.0,   0.941, 0.769)

func _ready() -> void:
	_spawn_player()
	_spawn_props()

func _spawn_player() -> void:
	var player := player_scene.instantiate()
	add_child(player)
	player.global_position = $PlayerStart.global_position
	player.respawn_position = $PlayerStart.global_position

func _spawn_props() -> void:
	# Lollipops
	_place(CandylandProps.make_lollipop(PINK),     -6, 0, 14)
	_place(CandylandProps.make_lollipop(BLUE),      6, 0, 28)
	_place(CandylandProps.make_lollipop(MINT),     -7, 0, 78)
	_place(CandylandProps.make_lollipop(LAVENDER),  7, 0, 88)
	_place(CandylandProps.make_lollipop(YELLOW),    0, 0, 135)

	# Donuts — corners of quiz area and flanking DTR grid
	var donut_pos := [
		Vector3(-9, 0.5, 48), Vector3(9, 0.5, 48),
		Vector3(-9, 0.5, 58), Vector3(9, 0.5, 58),
		Vector3(-7, 0.5, 108), Vector3(7, 0.5, 108),
	]
	var donut_bases  := [YELLOW, PINK,     MINT,     LAVENDER, BLUE,     YELLOW]
	var donut_frosts := [PINK,   LAVENDER, BLUE,     MINT,     LAVENDER, MINT  ]
	for i in donut_pos.size():
		var d := CandylandProps.make_donut(donut_bases[i], donut_frosts[i])
		d.position = donut_pos[i]
		add_child(d)

	# Cotton candy clouds
	_place(CandylandProps.make_cloud(PINK),    -10, 10,  20)
	_place(CandylandProps.make_cloud(BLUE),     12, 12,  35)
	_place(CandylandProps.make_cloud(PINK),      0, 14,  55)
	_place(CandylandProps.make_cloud(BLUE),     -8, 11,  75)
	_place(CandylandProps.make_cloud(PINK),      9, 13, 100)
	_place(CandylandProps.make_cloud(BLUE),      0, 15, 130)

func _place(node: Node3D, x: float, y: float, z: float) -> void:
	node.position = Vector3(x, y, z)
	add_child(node)
