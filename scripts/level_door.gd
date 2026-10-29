extends Node3D
class_name LevelDoor
# A free-standing door in a frame. It swings open as a racer approaches and emits
# `entered` when someone walks through the glowing doorway behind it. The door
# itself decides nothing: the level listens and makes it the finish line, the bonus
# room entrance, or anything else.
#
# Faces -Z: racers running along +Z walk straight through it. Frame and panel have no
# collision, so a bot that clips the edge doesn't snag.

signal entered(body: Node3D)

const OPEN_ANGLE := -1.75  # radians; swings away from the approaching racer

@export var sign_text: String = "EXIT"
@export var sign_color: Color = Color(0.3, 1.0, 0.45)
@export var glow_color: Color = Color(1.0, 1.0, 0.92)
@export var door_color: Color = Color(0.55, 0.42, 0.26)
@export var open_range: float = 7.0
@export var player_only: bool = false

var enabled: bool = true
var _glow_mat: StandardMaterial3D

@onready var _hinge: Node3D = $Hinge

func _ready() -> void:
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = door_color
	$Hinge/Panel.set_surface_override_material(0, door_mat)
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.albedo_color = glow_color
	_glow_mat.emission_enabled = true
	_glow_mat.emission = glow_color
	_glow_mat.emission_energy_multiplier = 3.0
	$Doorway.set_surface_override_material(0, _glow_mat)
	var sign := BackroomsProps.make_exit_sign(sign_text, sign_color)
	sign.position = Vector3(0, 3.6, 0)
	add_child(sign)
	$Area.body_entered.connect(_on_body_entered)

# A disabled door shuts, goes dark and stops reporting entries.
func set_enabled(on: bool) -> void:
	enabled = on
	_glow_mat.emission_energy_multiplier = 3.0 if on else 0.0
	_glow_mat.albedo_color = glow_color if on else Color(0.05, 0.05, 0.05)

func _process(delta: float) -> void:
	var target := 0.0
	if enabled and _nearest_racer_dist() < open_range:
		target = OPEN_ANGLE
	_hinge.rotation.y = lerp_angle(_hinge.rotation.y, target, 6.0 * delta)

func _nearest_racer_dist() -> float:
	var best := INF
	var group := "player" if player_only else "racer"
	for r in get_tree().get_nodes_in_group(group):
		best = minf(best, global_position.distance_to(r.global_position))
	return best

func _on_body_entered(body: Node3D) -> void:
	if not enabled or not body.is_in_group("racer"):
		return
	if player_only and not body.is_in_group("player"):
		return
	entered.emit(body)
