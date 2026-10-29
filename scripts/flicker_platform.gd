extends StaticBody3D
class_name FlickerPlatform
# A carpet platform that only exists while the fluorescent light above it is on.
#
# Every platform runs the same `period` cycle offset by `phase`: solid for `on_time`,
# then gone for the rest. For the last `warn_time` of the on-stretch the light stutters
# and buzzes so the drop is never a surprise. With two groups half a period apart and
# on_time > period/2, neighbours are both solid for a window each cycle — that overlap
# is when you jump.
#
# All platforms count from their own _ready, which runs on the same frame for every
# platform in the level, so the groups stay in step without a shared clock.

const CLEAR_MARGIN := 1.6  # bots only step on with at least this much light left

@export var phase: float = 0.0
@export var period: float = 4.0
@export var on_time: float = 3.0
@export var warn_time: float = 0.6

var _t: float = 0.0
var _solid: bool = true
var _carpet_mat: StandardMaterial3D
var _ghost_mat: StandardMaterial3D
var _tube_mat: StandardMaterial3D

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _shape: CollisionShape3D = $CollisionShape3D
@onready var _tube: MeshInstance3D = $Lamp/Tube
@onready var _glow: OmniLight3D = $Lamp/Glow

func _ready() -> void:
	_t = phase
	_carpet_mat = BackroomsProps.carpet_material()
	_ghost_mat = StandardMaterial3D.new()
	_ghost_mat.albedo_color = Color(0.9, 0.85, 0.6, 0.12)
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tube_mat = BackroomsProps.make_panel_material()
	_tube.material_override = _tube_mat
	_mesh.set_surface_override_material(0, _carpet_mat)
	_setup_hum()

func _setup_hum() -> void:
	if not ResourceLoader.exists("res://assets/audio/fluorescent_hum_loop.ogg"):
		return
	var hum := AudioStreamPlayer3D.new()
	hum.stream = load("res://assets/audio/fluorescent_hum_loop.ogg")
	hum.volume_db = -18.0
	hum.max_distance = 6.0
	hum.autoplay = true
	$Lamp.add_child(hum)

func _cycle_pos() -> float:
	return fposmod(_t, period)

func is_on() -> bool:
	return _cycle_pos() < on_time

# Seconds until the platform vanishes; 0 while it is already gone.
func time_until_off() -> float:
	var p := _cycle_pos()
	return on_time - p if p < on_time else 0.0

# Bot hook (see RacerRoute.wait_at): safe to commit to this platform right now?
func is_clear_for(_racer: Node3D) -> bool:
	return time_until_off() > CLEAR_MARGIN

func _physics_process(delta: float) -> void:
	_t += delta
	var on := is_on()
	if on != _solid:
		_solid = on
		_shape.set_deferred("disabled", not on)
		_mesh.set_surface_override_material(0, _carpet_mat if on else _ghost_mat)

	var energy := 0.0
	if on:
		energy = 2.5
		if time_until_off() < warn_time:
			# Stutter: irregular on/off so it reads as a dying tube, not a metronome.
			energy = 2.5 if fmod(_t * 23.0, 1.0) > 0.45 else 0.15
	_tube_mat.emission_energy_multiplier = energy
	_glow.light_energy = energy * 0.6
