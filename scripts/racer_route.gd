extends Node3D
class_name RacerRoute
# The path CPU racers follow through a level, as an ordered list of local-space points.
#
# Points only steer — jumping is decided by the bot from geometry (raycast for missing
# floor ahead), so points can sit at platform centres without the bot trying to jump the
# full centre-to-centre distance. See cpu_racer.gd.
#
# Quiz gates are branch points: gate_indices[n] is the index into `points` where the bot
# should ask gate_paths[n] to choose a fork.
#
# Timed hazards are hold points: wait_indices[n] is a point the bot must not head for
# until wait_paths[n].is_clear_for(bot) says so (a flicker platform about to vanish, a
# monster cannon about to fire). The bot waits where it stands, on the previous point.

@export var points: PackedVector3Array = PackedVector3Array()
@export var gate_indices: PackedInt32Array = PackedInt32Array()
@export var gate_paths: Array[NodePath] = []
@export var wait_indices: PackedInt32Array = PackedInt32Array()
@export var wait_paths: Array[NodePath] = []

func point_count() -> int:
	return points.size()

func global_point(i: int) -> Vector3:
	return to_global(points[i])

# Returns the QuizGate the bot should consult at this point index, or null.
func gate_at(i: int) -> Node:
	var slot := gate_indices.find(i)
	if slot < 0 or slot >= gate_paths.size():
		return null
	return get_node_or_null(gate_paths[slot])

# Returns the hazard the bot must wait on before heading for this point, or null.
func wait_at(i: int) -> Node:
	var slot := wait_indices.find(i)
	if slot < 0 or slot >= wait_paths.size():
		return null
	return get_node_or_null(wait_paths[slot])
