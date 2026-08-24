extends CharacterBody3D
class_name CpuRacer
# A CPU-controlled racer that runs a level's RacerRoute alongside the player.
#
# Deliberately NOT a subclass of player.gd: that script is built around input and a
# camera, and its die() drives the human death flow (YOU DIED, coin loss, hub return).
# The shared part — the X Bot rig — lives in CharacterRig and is used by both.
#
# Navigation is waypoint steering, not NavigationAgent3D: a navmesh cannot express a
# jump across a void, and these levels are floating platforms with gaps.

const BASE_SPEED := 6.0
const JUMP_VELOCITY := 5.0
const FALL_Y := -20.0
const ARRIVE_DIST := 1.2          # how close counts as reaching a point
const GAP_PROBE_AHEAD := 0.45     # how far ahead to look for missing floor. Keep this
                                  # small: the bot launches from wherever it detects the
                                  # gap, so probing far ahead throws away jump range and
                                  # leaves it short on the widest gaps.
const GAP_PROBE_DEPTH := 2.5      # no floor within this distance below = jump
const MIN_JUMP_VELOCITY := 2.5
const JUMP_MARGIN := 1.15        # aim slightly past the target so short hops don't fall short
const STUCK_TIME := 2.5
const STUCK_DIST := 0.6
const BLUNDER_MAX_SPACING := 2.5  # only blunder on tightly-spaced points (tile fields)
const BLUNDER_OFFSET := 2.0
const FORK_EXIT_AHEAD := 2.6   # fork platforms are 6 deep; run to just inside the far edge
const FORK_COMMIT_DIST := 9.0  # commit to a fork only once this close to the gate

@export var racer_name: String = "CPU"
@export var quiz_accuracy: float = 0.75   # chance of picking the correct quiz fork
@export var hazard_awareness: float = 0.8 # chance of holding the safe line on tile fields
@export var speed_jitter: float = 0.0     # +/- units/sec, so a pack doesn't move in lockstep

var is_dead: bool = false
var finished: bool = false

var _route: RacerRoute
var _point_index: int = 0
var _target: Vector3
var _has_target: bool = false
var _speed: float = BASE_SPEED
var _body_mesh: MeshInstance3D
var _hat_mount: Node3D
var _character_mesh: Node3D
var _stuck_timer: float = 0.0
var _last_pos: Vector3
var _has_landed: bool = false  # spawn drop guard — see _physics_process
var _knockback_timer: float = 0.0
var _exit_target: Vector3
var _has_exit_target: bool = false
var _pending_fork: Vector3
var _has_pending_fork: bool = false
var _staging_for_fork: bool = false

func _ready() -> void:
	_character_mesh = $CharacterMesh
	_body_mesh = CharacterRig.find_first_mesh(_character_mesh)
	_hat_mount = CharacterRig.create_hat_mount(_character_mesh)
	_speed = BASE_SPEED + randf_range(-speed_jitter, speed_jitter)
	_last_pos = global_position
	$NameLabel.text = racer_name
	_apply_random_cosmetics()
	RaceState.register_racer(racer_name)

# Bots never read ItemInventory — that is the player's equipped gear. They pick
# their own look from the same catalog so a pack looks varied.
func _apply_random_cosmetics() -> void:
	var skins: Array = []
	var hats: Array = []
	for id in ItemInventory.item_data:
		var item: Dictionary = ItemInventory.item_data[id]
		match item.get("slot", ""):
			"skin": skins.append(item)
			"hat": hats.append(item)
	if not skins.is_empty():
		var c = skins[randi() % skins.size()].get("color", [1, 1, 1])
		CharacterRig.apply_skin_color(_body_mesh, Color(c[0], c[1], c[2]))
	# Not every bot wears a hat.
	if not hats.is_empty() and randf() < 0.7:
		var hat: Dictionary = hats[randi() % hats.size()]
		var hc = hat.get("color", [1, 1, 1])
		CharacterRig.apply_hat(_hat_mount, hat.get("hat_type", ""), Color(hc[0], hc[1], hc[2]))

# Mesh only — bots have no camera. Same signature as the player's so spawn code can
# treat every racer the same.
func set_spawn_facing(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length() < 0.01 or not _character_mesh:
		return
	dir = dir.normalized()
	_character_mesh.rotation.y = atan2(dir.x, dir.z)

func set_route(route: RacerRoute) -> void:
	_route = route
	# Start at the point *after* the nearest one. Point 0 sits on the start marker,
	# which is also where the player spawns — steering straight at it makes the bot
	# body-check the player on the start line instead of running the course.
	var nearest := 0
	var best := INF
	for i in route.point_count():
		var d: float = route.global_point(i).distance_to(global_position)
		if d < best:
			best = d
			nearest = i
	_advance_to(mini(nearest + 1, route.point_count() - 1))

func _advance_to(i: int) -> void:
	if _route == null or i >= _route.point_count():
		_has_target = false
		_on_route_complete()
		return
	_point_index = i
	_target = _route.global_point(i)

	# Quiz gate branch: pick a fork now, but keep steering down the centre line until
	# the bot is actually near the gate. Aiming at a fork 7.5 units off-centre from way
	# back walks it diagonally off the narrow approach platforms. Committed in
	# _physics_process once within FORK_COMMIT_DIST.
	var gate: Node = _route.gate_at(i)
	if gate and gate.has_method("choose_fork_position"):
		_pending_fork = gate.choose_fork_position(quiz_accuracy)
		_has_pending_fork = true

	# Blunders only on tightly-spaced points (stepping stones, tile grids), where
	# drifting off the safe line is a survivable-looking mistake rather than an
	# instant fall off a narrow platform.
	# Rolled once on ENTERING a tight-spaced section, not per point: a tile grid is a
	# dozen closely spaced points, and a per-point roll would make dying in it certain.
	if i > 1:
		var here: Vector3 = _route.global_point(i)
		var spacing: float = _route.global_point(i - 1).distance_to(here)
		var prev_spacing: float = _route.global_point(i - 2).distance_to(_route.global_point(i - 1))
		var entering_tight := spacing <= BLUNDER_MAX_SPACING and prev_spacing > BLUNDER_MAX_SPACING
		if entering_tight and randf() > hazard_awareness:
			_target.x += BLUNDER_OFFSET * (1.0 if randf() < 0.5 else -1.0)

	_has_target = true

func _on_route_complete() -> void:
	if finished or is_dead:
		return
	finished = true
	velocity = Vector3.ZERO
	RaceState.report_finished(racer_name)

func die() -> void:
	if is_dead or finished:
		return
	is_dead = true
	_spawn_elimination_puff()
	RaceState.report_eliminated(racer_name)
	queue_free()

# Bots take knockback like the player does. Steering is suspended while it plays out,
# otherwise the next frame's steering would cancel the launch horizontally.
func apply_knockback(force: Vector3) -> void:
	velocity = force
	_knockback_timer = 3.0

func shake_camera(_intensity: float, _duration: float) -> void:
	pass  # bots have no camera; hazards call this on whatever they hit

func _spawn_elimination_puff() -> void:
	var puff := CPUParticles3D.new()
	puff.emitting = false
	puff.one_shot = true
	puff.amount = 24
	puff.lifetime = 0.8
	puff.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	puff.emission_sphere_radius = 0.4
	puff.direction = Vector3(0, 1, 0)
	puff.spread = 180.0
	puff.gravity = Vector3(0, -2.0, 0)
	puff.initial_velocity_min = 2.0
	puff.initial_velocity_max = 4.0
	puff.scale_amount_min = 0.15
	puff.scale_amount_max = 0.3
	puff.color = Color(0.85, 0.85, 0.9)
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	scene_root.add_child(puff)
	puff.global_position = global_position + Vector3(0, 1.0, 0)
	puff.restart()
	scene_root.get_tree().create_timer(1.5).timeout.connect(puff.queue_free)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	else:
		_has_landed = true

	# Spawn markers sit slightly above the platform, so a racer is briefly airborne on
	# frame one. Running during that drop walks it off a small start platform before it
	# ever gets a grounded frame to jump from.
	if not _has_landed:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	# Starting gate: bots hold with the player.
	if RaceState.is_locked():
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	if _knockback_timer > 0.0:
		_knockback_timer -= delta
		move_and_slide()
		if global_position.y < FALL_Y:
			die()
		return

	if finished or not _has_target:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	if _has_pending_fork and global_position.distance_to(_target) <= FORK_COMMIT_DIST:
		_has_pending_fork = false
		_staging_for_fork = true
		# Head for the corner of the current platform nearest the chosen fork, staying
		# on floor. The switch to aiming at the fork itself happens at takeoff, in the
		# jump check below — aiming at it while still grounded would drag the bot off
		# the platform's side edge and into the gap between forks.
		_target = Vector3(_safe_lateral_x(_pending_fork.x), _target.y, _pending_fork.z)
		# Then run straight off the END of that fork before converging on the next point.
		# Steering for the (centred) reconverge point right away would walk the bot off
		# the narrow fork sideways into a diagonal jump that falls short of it.
		# Carry the fork's x across the gap instead of converging on the centred next
		# point mid-jump: the reconverge platform is far wider than the fork spread, so
		# landing straight ahead is safe, whereas a diagonal jump spends its range on
		# lateral travel and drops into the gap.
		var next_z: float = _target.z + FORK_EXIT_AHEAD
		if _point_index + 1 < _route.point_count():
			next_z = _route.global_point(_point_index + 1).z
		_exit_target = Vector3(_target.x, _target.y, next_z)
		_has_exit_target = true

	var to_target := _target - global_position
	to_target.y = 0.0

	# Only tick a waypoint off once actually standing on it (or practically on top of
	# it). Advancing mid-air lets the bot claim a stepping stone it hasn't landed on,
	# retarget the next one, curve away in flight and land in the gap between them.
	if to_target.length() <= ARRIVE_DIST and (is_on_floor() or to_target.length() <= 0.4):
		if _has_exit_target:
			# Finish crossing the current fork before heading for the next route point.
			_has_exit_target = false
			_target = _exit_target
		else:
			_advance_to(_point_index + 1)
		to_target = _target - global_position
		to_target.y = 0.0

	var move_dir := to_target.normalized() if to_target.length() > 0.01 else Vector3.ZERO
	velocity.x = move_dir.x * _speed
	velocity.z = move_dir.z * _speed

	if is_on_floor() and _should_jump(move_dir):
		if _staging_for_fork:
			# At the edge now: aim the actual jump at the fork so the arc carries the
			# remaining lateral distance too.
			_staging_for_fork = false
			_target = Vector3(_pending_fork.x, _target.y, _pending_fork.z)
			to_target = _target - global_position
			to_target.y = 0.0
			move_dir = to_target.normalized() if to_target.length() > 0.01 else move_dir
			velocity.x = move_dir.x * _speed
			velocity.z = move_dir.z * _speed
		velocity.y = _jump_velocity_for(to_target.length())

	if _character_mesh and move_dir.length() > 0.01:
		# X Bot faces +Z after FBX2glTF import, matching player.gd
		var target_angle := atan2(move_dir.x, move_dir.z)
		_character_mesh.rotation.y = lerp_angle(_character_mesh.rotation.y, target_angle, 10.0 * delta)

	move_and_slide()
	_check_stuck(delta)

	if global_position.y < FALL_Y:
		die()

# How far toward `desired_x` the bot can shift and still have floor under it.
# Keeps the fork approach geometry-agnostic — no platform sizes hardcoded.
func _safe_lateral_x(desired_x: float) -> float:
	var step := 0.3 * signf(desired_x - global_position.x)
	if is_zero_approx(step):
		return global_position.x
	var space := get_world_3d().direct_space_state
	var best := global_position.x
	var x := global_position.x
	for _i in 40:
		x += step
		if (step > 0.0 and x > desired_x) or (step < 0.0 and x < desired_x):
			return desired_x
		var from := Vector3(x, global_position.y + 0.2, global_position.z + 0.5)
		var query := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, -GAP_PROBE_DEPTH, 0))
		query.exclude = [get_rid()]
		if space.intersect_ray(query).is_empty():
			break
		best = x
	return best

# Scale the hop to the distance being cleared. Horizontal speed is constant, so
# airtime sets the range: range = speed * 2 * vy / g. A fixed-strength jump would
# overshoot the 3-unit stepping stones and land the bot two stones down the line.
func _jump_velocity_for(distance: float) -> float:
	var g: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var needed: float = distance * JUMP_MARGIN * g / (2.0 * maxf(_speed, 0.1))
	return clampf(needed, MIN_JUMP_VELOCITY, JUMP_VELOCITY)

# Jump when there is no floor just ahead (a gap), or when the next point is a step up.
func _should_jump(move_dir: Vector3) -> bool:
	if move_dir.length() < 0.01:
		return false
	if _target.y > global_position.y + 0.4:
		return true
	var space := get_world_3d().direct_space_state
	var from := global_position + move_dir * GAP_PROBE_AHEAD + Vector3(0, 0.2, 0)
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, -GAP_PROBE_DEPTH, 0))
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	return hit.is_empty()

func _check_stuck(delta: float) -> void:
	if global_position.distance_to(_last_pos) > STUCK_DIST:
		_last_pos = global_position
		_stuck_timer = 0.0
		return
	_stuck_timer += delta
	if _stuck_timer >= STUCK_TIME:
		_stuck_timer = 0.0
		_last_pos = global_position
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
