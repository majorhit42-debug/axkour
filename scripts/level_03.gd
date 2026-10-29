extends Node3D
# Level 03 — The Axerooms. Backrooms Level 0 broken apart and floating in fog.
#
# Course along +Z: Lobby -> Backrooms quiz gate -> Flicker Hall -> trivia gate ->
# Monster Cannon gauntlet -> junction (gold door to the Gold Rooms bonus) -> EXIT door.
# The finish line is the EXIT door itself, not a z threshold.

@export var player_scene: PackedScene

const CPU_RACER_SCENE := preload("res://scenes/racer/cpu_racer.tscn")
const PLAYER_RACER_NAME := "You"
const COURSE_DIRECTION := Vector3(0, 0, 1)
const COUNTDOWN_SECONDS := 5.0
const RACE_TITLE := "THE AXEROOMS"
const HUB_SCENE := "res://scenes/hub/hub.tscn"
const EXIT_TO_HUB_DELAY := 2.0

const BOTS := [
	{"name": "Turbo",   "quiz_accuracy": 0.80, "hazard_awareness": 0.85, "speed_jitter": 0.4, "x": -6.0},
	{"name": "Smiler",  "quiz_accuracy": 0.65, "hazard_awareness": 0.70, "speed_jitter": 0.5, "x": -4.0},
	{"name": "Almond",  "quiz_accuracy": 0.90, "hazard_awareness": 0.60, "speed_jitter": 0.4, "x": -2.0},
	{"name": "Wobbles", "quiz_accuracy": 0.55, "hazard_awareness": 0.50, "speed_jitter": 0.6, "x": 2.0},
	{"name": "Buzz",    "quiz_accuracy": 0.75, "hazard_awareness": 0.90, "speed_jitter": 0.3, "x": 4.0},
]

var _player: Node3D
var _player_finished: bool = false
var _bonus_used: bool = false
var _flicker_lamps: Array[StandardMaterial3D] = []
var _flicker_timer: float = 2.0

func _ready() -> void:
	RaceState.reset_race()
	BackroomsProps.dress_groups(get_tree())
	_spawn_player()
	_spawn_bots()
	_spawn_props()
	$ExitDoor.entered.connect(_on_exit_door_entered)
	$GoldDoor.entered.connect(_on_gold_door_entered)
	$GoldRooms.bonus_finished.connect(_on_bonus_finished)
	RaceState.start_countdown(COUNTDOWN_SECONDS, RACE_TITLE)

func _spawn_player() -> void:
	var player := player_scene.instantiate()
	# Position BEFORE add_child — see level_02.gd: a body parented at the origin
	# overlaps the bots for a physics frame and gets launched.
	player.position = $PlayerStart.position
	add_child(player)
	player.respawn_position = $PlayerStart.global_position
	player.set_spawn_facing(COURSE_DIRECTION)
	_player = player
	RaceState.register_racer(PLAYER_RACER_NAME)

func _spawn_bots() -> void:
	var route: RacerRoute = $RacerRoute
	var bots: Array[Node] = []
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
		bots.append(racer)
	# Bots pass through each other. Five of them steer for the same centre-line points,
	# and bot-on-bot collisions on the 3-wide catwalk or a 4x4 flicker platform turn into
	# pile-ups that shove each other into the void. They still collide with the player.
	for a in bots:
		for b in bots:
			if a != b:
				a.add_collision_exception_with(b)

# --- Finish door ---

func _on_exit_door_entered(body: Node3D) -> void:
	if body == _player:
		if _player_finished:
			return
		_player_finished = true
		RaceState.report_finished(PLAYER_RACER_NAME)
		get_tree().create_timer(EXIT_TO_HUB_DELAY).timeout.connect(_return_to_hub)
	elif body.has_method("exit_level"):
		body.exit_level()

func _return_to_hub() -> void:
	HUD.fade_through_black(func(): get_tree().change_scene_to_file(HUB_SCENE))

# --- Gold Rooms bonus ---

func _on_gold_door_entered(body: Node3D) -> void:
	if body != _player or _bonus_used:
		return
	_bonus_used = true
	$GoldDoor.set_enabled(false)
	HUD.fade_through_black(func():
		_teleport_player($GoldRooms.entry_position())
		$GoldRooms.start()
		HUD.announce("THE GOLD ROOMS! Grab what you can!", Color(1, 0.85, 0.1)))

func _on_bonus_finished(reason: String) -> void:
	if _player == null or not is_instance_valid(_player) or _player.is_dead:
		return
	HUD.announce("TIME'S UP!" if reason == "time" else "The Gold Rooms spat you out!", Color(1, 0.85, 0.1))
	HUD.fade_through_black(func(): _teleport_player($GoldReturn.global_position), 0.4, 0.5)

func _teleport_player(pos: Vector3) -> void:
	_player.global_position = pos
	_player.velocity = Vector3.ZERO
	_player.camera_y = pos.y
	_player.set_spawn_facing(COURSE_DIRECTION)

# --- Decoration ---

func _process(delta: float) -> void:
	# Now and then a random ceiling lamp stutters, because it's the Backrooms.
	_flicker_timer -= delta
	if _flicker_timer <= 0.0 and not _flicker_lamps.is_empty():
		_flicker_timer = randf_range(0.8, 2.5)
		_stutter(_flicker_lamps.pick_random())

func _stutter(mat: StandardMaterial3D) -> void:
	var tween := create_tween()
	for i in randi_range(2, 4):
		tween.tween_property(mat, "emission_energy_multiplier", 0.1, 0.04)
		tween.tween_interval(randf_range(0.03, 0.12))
		tween.tween_property(mat, "emission_energy_multiplier", 2.5, 0.03)
		tween.tween_interval(randf_range(0.05, 0.2))

func _spawn_props() -> void:
	# Drop ceiling over the course, with the Flicker Hall left dark so its own lamps
	# carry the section.
	_place(BackroomsProps.make_ceiling(68, 32), 0, 8.5, 25)
	_place(BackroomsProps.make_ceiling(40, 32, 1000.0), 0, 8.5, 79)
	_place(BackroomsProps.make_ceiling(96, 32), 0, 8.5, 147)

	# Endless pillars dropping into the fog below.
	for z in range(-4, 196, 16):
		for x in [-11.0, 11.0]:
			_place(BackroomsProps.make_pillar(40.0), x, -31.5, z)

	# Broken chunks of wall drifting beside the course.
	var walls := [
		[-14, 8, 10], [14, 22, 14], [-15, 40, 8], [15, 58, 10], [-14, 78, 16],
		[14, 96, 8], [-15, 108, 12], [15, 112, 6], [-14, 178, 10], [14, 184, 12],
	]
	for w in walls:
		_place(BackroomsProps.make_wall(w[2], 9.0), w[0], -0.5, w[1])

	# Gauntlet walls the monsters burst out of.
	for side in [-7.3, 7.3]:
		_place(BackroomsProps.make_wall(50.0, 10.0), side, -3.0, 144.5)

	# Lobby back wall, and the title hanging over the first jump.
	var back := BackroomsProps.make_wall(16.0, 9.0)
	back.rotation.y = PI / 2
	_place(back, 0, -0.5, -5.5)
	var title := Label3D.new()
	title.text = "THE AXEROOMS"
	title.font_size = 128
	title.pixel_size = 0.02
	title.outline_size = 12
	title.outline_modulate = Color(0, 0, 0)
	title.modulate = Color(1.0, 0.95, 0.6)
	title.rotation.y = PI
	_place(title, 0, 5.6, 14)

	# Hanging lamps that stutter at random.
	for pos in [Vector3(-4, 6.5, 2), Vector3(4, 6.5, 24), Vector3(0, 6.5, 54), Vector3(0, 6.5, 115), Vector3(0, 6.2, 174)]:
		var lamp := BackroomsProps.make_lamp()
		_place(lamp, pos.x, pos.y, pos.z)
		_flicker_lamps.append(lamp.get_node("Tube").material_override)

	var exit_sign := BackroomsProps.make_exit_sign("BONUS ->", Color(1, 0.85, 0.2))
	_place(exit_sign, -4, 2.5, 168)

func _place(node: Node3D, x: float, y: float, z: float) -> void:
	node.position = Vector3(x, y, z)
	add_child(node)
