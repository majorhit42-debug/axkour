extends Node3D
class_name GoldRooms
# The Gold Rooms: a timed bonus stage reached through the gold door in level_03.
# It sits far off-course (hidden by fog) in the same scene, so entering it is a
# teleport, not a scene change, and the race keeps running while you're in here.
#
# The room only runs the clock and reports when the visit is over; level_03 owns
# moving the player in and out.

signal bonus_finished(reason: String)  # "time" or "fell"

@export var duration: float = 30.0

var active: bool = false
var _time_left: float = 0.0

func _ready() -> void:
	$CatchArea.body_entered.connect(_on_catch_entered)
	_spawn_props()

func _spawn_props() -> void:
	for side in [-12.0, 12.0]:
		_place(BackroomsProps.make_wall(42.0, 26.0, true), side, -4.0, 12.0)
	for z in [-6.0, 32.0]:
		var wall := BackroomsProps.make_wall(24.0, 26.0, true)
		wall.rotation.y = PI / 2
		_place(wall, 0.0, -4.0, z)
	_place(BackroomsProps.make_ceiling(38.0, 24.0, 5.0), 0.0, 22.0, 13.0)
	# Gold-wallpapered pillars holding up nothing in particular.
	for p in [Vector2(-8, 2), Vector2(8, 2), Vector2(-9, 26), Vector2(9, 26)]:
		var pillar := BackroomsProps.make_pillar(30.0)
		for child in pillar.get_children():
			child.material_override = BackroomsProps.gold_wallpaper_material()
		_place(pillar, p.x, -8.0, p.y)

func _place(node: Node3D, x: float, y: float, z: float) -> void:
	node.position = Vector3(x, y, z)
	add_child(node)

func entry_position() -> Vector3:
	return $EntryMarker.global_position

func start() -> void:
	active = true
	_time_left = duration
	HUD.show_bonus_timer(_time_left)

func _process(delta: float) -> void:
	if not active:
		return
	_time_left -= delta
	HUD.set_bonus_time(_time_left)
	if _time_left <= 0.0:
		_finish("time")

# Falling out of the bonus room isn't a death — it just ends the visit early.
func _on_catch_entered(body: Node3D) -> void:
	if active and body.is_in_group("player"):
		_finish("fell")

func _finish(reason: String) -> void:
	active = false
	HUD.hide_bonus_timer()
	bonus_finished.emit(reason)

func _exit_tree() -> void:
	# The player can die in here (electric tiles); don't leave the timer on screen in the hub.
	if active:
		HUD.hide_bonus_timer()
