extends Node3D
class_name MonsterCannon
# A Backrooms monster built into the wall whose mouth is a cannon. Fires a GooBall
# along its local -Z every `fire_interval` seconds, offset by `phase` so a row of them
# makes a rhythm instead of a volley.
#
# Tell (the fair warning): for the last `windup` seconds the eyes swell bright and the
# head draws back; on firing the head lunges forward and snaps back.

const GOO_BALL_SCENE := preload("res://scenes/hazard/goo_ball.tscn")
const CLEAR_FIRE_MARGIN := 0.8  # bots won't step into the lane closer than this to a shot
const PASSED_MARGIN := 1.2      # a ball this far past the racer no longer threatens it

@export var fire_interval: float = 3.0
@export var phase: float = 0.0
@export var windup: float = 0.7
@export var ball_speed: float = 8.0
@export var ball_range: float = 13.0

var _t: float = 0.0
var _balls: Array[Node3D] = []
var _eye_mat: StandardMaterial3D
var _lunge: float = 0.0
var _growled: bool = false

@onready var _head: Node3D = $HeadPivot
@onready var _muzzle: Marker3D = $HeadPivot/Muzzle

func _ready() -> void:
	_t = phase
	_eye_mat = $HeadPivot/EyeL.get_surface_override_material(0).duplicate()
	$HeadPivot/EyeL.set_surface_override_material(0, _eye_mat)
	$HeadPivot/EyeR.set_surface_override_material(0, _eye_mat)
	if ResourceLoader.exists("res://assets/audio/monster_growl.ogg"):
		$Growl.stream = load("res://assets/audio/monster_growl.ogg")

func time_until_fire() -> float:
	return fire_interval - fposmod(_t, fire_interval)

# Bot hook (see RacerRoute.wait_at): safe to cross this monster's lane right now?
func is_clear_for(racer: Node3D) -> bool:
	if time_until_fire() < CLEAR_FIRE_MARGIN:
		return false
	var dir := _fire_direction()
	for ball in _balls:
		if not is_instance_valid(ball):
			continue
		# Positive = the ball has yet to reach the racer's line of travel.
		if (racer.global_position - ball.global_position).dot(dir) > -PASSED_MARGIN:
			return false
	return true

func _fire_direction() -> Vector3:
	var d := -global_transform.basis.z
	d.y = 0.0
	return d.normalized()

func _process(delta: float) -> void:
	var before := fposmod(_t, fire_interval)
	_t += delta
	var after := fposmod(_t, fire_interval)
	if after < before:
		_fire()

	var until := time_until_fire()
	var charge := clampf(1.0 - until / windup, 0.0, 1.0) if until < windup else 0.0
	if charge > 0.0 and not _growled:
		_growled = true
		if $Growl.stream:
			$Growl.play()
	_eye_mat.emission_energy_multiplier = 1.0 + charge * 6.0
	# Draw back while charging, lunge on the shot, ease home.
	_lunge = move_toward(_lunge, 0.0, delta * 2.5)
	_head.position.z = charge * 0.35 - _lunge

func _fire() -> void:
	_growled = false
	_lunge = 0.45
	_balls = _balls.filter(func(b): return is_instance_valid(b))
	var ball := GOO_BALL_SCENE.instantiate()
	ball.direction = _fire_direction()
	ball.speed = ball_speed
	ball.max_range = ball_range
	get_tree().current_scene.add_child(ball)
	ball.global_position = _muzzle.global_position
	_balls.append(ball)
