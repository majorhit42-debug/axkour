extends Area3D
class_name BouncePad
# A springy gold mattress. Any racer standing on (or landing on) it is launched
# straight up; steering in the air is the player's normal air control.
#
# Polls overlapping bodies instead of using body_entered: a racer who lands back on
# the pad without ever leaving the area would otherwise never bounce again.

@export var launch_velocity: float = 13.0

var _squash: float = 0.0

func _physics_process(delta: float) -> void:
	for body in get_overlapping_bodies():
		if not body.is_in_group("racer") or not (body is CharacterBody3D):
			continue
		if body.velocity.y > 0.5:
			continue  # already on the way up
		body.velocity.y = launch_velocity
		_squash = 1.0
	_squash = move_toward(_squash, 0.0, delta * 4.0)
	$Cushion.scale = Vector3(1.0 + _squash * 0.15, 1.0 - _squash * 0.5, 1.0 + _squash * 0.15)
