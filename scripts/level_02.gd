extends Node3D

@export var player_scene: PackedScene

const CPU_RACER_SCENE := preload("res://scenes/racer/cpu_racer.tscn")
const PLAYER_RACER_NAME := "You"
const FINISH_Z := 126.0
const COURSE_DIRECTION := Vector3(0, 0, 1)
const COUNTDOWN_SECONDS := 5.0

# One entry per CPU racer. A list from day one so growing the pack is a data change.
# quiz_accuracy is deliberately high on a solo bot: a bad roll at the Lego gate would
# otherwise eliminate it seconds in and leave the player racing alone.
const BOTS := [
	{"name": "Turbo", "quiz_accuracy": 0.75, "hazard_awareness": 0.8, "speed_jitter": 0.4, "x": 1.5},
]

var _player: Node3D
var _player_finished: bool = false

const PINK    := Color(1.0,   0.769, 0.847)
const MINT    := Color(0.769, 0.941, 0.847)
const BLUE    := Color(0.769, 0.863, 0.941)
const LAVENDER := Color(0.863, 0.769, 0.941)
const YELLOW  := Color(1.0,   0.941, 0.769)

func _ready() -> void:
	RaceState.reset_race()
	_spawn_player()
	_spawn_bots()
	_spawn_props()
	RaceState.start_countdown(COUNTDOWN_SECONDS)

func _spawn_player() -> void:
	var player := player_scene.instantiate()
	# Position BEFORE add_child: a body parented at the origin is registered there for
	# one physics frame, and with a bot spawning alongside, the server resolves that
	# shared-origin overlap by launching one racer on top of the other.
	player.position = $PlayerStart.position
	add_child(player)
	player.respawn_position = $PlayerStart.global_position
	player.set_spawn_facing(COURSE_DIRECTION)
	_player = player
	RaceState.register_racer(PLAYER_RACER_NAME)

func _spawn_bots() -> void:
	var route: RacerRoute = $RacerRoute
	for bot in BOTS:
		var racer := CPU_RACER_SCENE.instantiate()
		racer.racer_name = bot.name
		racer.quiz_accuracy = bot.quiz_accuracy
		racer.hazard_awareness = bot.hazard_awareness
		racer.speed_jitter = bot.speed_jitter
		racer.position = $PlayerStart.position + Vector3(bot.x, 0, 0)
		add_child(racer)
		racer.set_spawn_facing(COURSE_DIRECTION)
		racer.set_route(route)

func _process(_delta: float) -> void:
	_check_player_finish()

func _check_player_finish() -> void:
	if _player_finished or _player == null or not is_instance_valid(_player):
		return
	if _player.global_position.z >= FINISH_Z:
		_player_finished = true
		RaceState.report_finished(PLAYER_RACER_NAME)

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
