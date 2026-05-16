extends CharacterBody3D

const SPEED = 6.0
const JUMP_VELOCITY = 5.0
const MOUSE_SENS = 0.003
const RIGHT_STICK_SENS = 0.05
const RESPAWN_Y = -20.0
const CAMERA_Y_DAMP = 2.5  # lower = more lag behind the player's jump
const FLY_SPEED = 10.0
const _CHEAT_CODE := "axelrules"

var respawn_position: Vector3
var camera_y: float
var _cheat_buffer: String = ""
var _debug_mode: bool = false
var _fly_mode: bool = false

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
var _body_mesh: MeshInstance3D
var _hat_mount: Node3D
var _character_mesh: Node3D
var _camera_origin: Vector3
var _shake_timer := 0.0
var _shake_intensity := 0.0
var _shake_duration := 0.0
var _knockback_timer := 0.0

func _ready() -> void:
	camera_y = global_position.y
	_camera_origin = _camera.position
	_character_mesh = $CharacterMesh
	_setup_body_mesh()
	_setup_hat_mount()
	ItemInventory.equipment_changed.connect(_on_equipment_changed)
	_apply_skin()
	_apply_hat()

func _setup_body_mesh() -> void:
	_body_mesh = _find_first_mesh(_character_mesh)
	if not _body_mesh:
		push_warning("Player: MeshInstance3D not found in CharacterMesh")

func _setup_hat_mount() -> void:
	var skeleton := _find_skeleton(_character_mesh)
	if not skeleton:
		push_warning("Player: Skeleton3D not found in CharacterMesh")
		return
	var bone_attach := BoneAttachment3D.new()
	bone_attach.name = "HatMount"
	skeleton.add_child(bone_attach)
	# Godot replaces ':' with '_' in bone names; try both variants
	for candidate in ["mixamorig_Head", "mixamorig:Head", "Head"]:
		if skeleton.find_bone(candidate) != -1:
			bone_attach.bone_name = candidate
			break
	if bone_attach.bone_name.is_empty():
		push_warning("Player: head bone not found — hat will not follow head")
	bone_attach.position.y = 0.18
	_hat_mount = bone_attach

func _find_first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _find_first_mesh(child)
		if found:
			return found
	return null

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null

func _on_equipment_changed(slot: String, _id: String) -> void:
	if slot == "skin":
		_apply_skin()
	elif slot == "hat":
		_apply_hat()

func _apply_hat() -> void:
	if not _hat_mount:
		return
	for child in _hat_mount.get_children():
		child.queue_free()
	var hat_id := ItemInventory.get_equipped("hat")
	if hat_id.is_empty():
		return
	var item := ItemInventory.get_item(hat_id)
	var col_arr = item.get("color", [1, 1, 1])
	var hat_type: String = item.get("hat_type", "")
	for mi in HatBuilder.make_meshes(hat_type, Color(col_arr[0], col_arr[1], col_arr[2]), 1.0):
		_hat_mount.add_child(mi)

func _apply_skin() -> void:
	if not _body_mesh:
		return
	var col := Color(1, 1, 1)
	var skin_id := ItemInventory.get_equipped("skin")
	if not skin_id.is_empty():
		var item := ItemInventory.get_item(skin_id)
		var col_arr = item.get("color", [1, 1, 1])
		col = Color(col_arr[0], col_arr[1], col_arr[2])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.7
	_body_mesh.set_surface_override_material(0, mat)

func apply_knockback(force: Vector3) -> void:
	velocity = force
	_knockback_timer = 5.0

func shake_camera(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_duration = duration
	_shake_timer = duration

func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var t: float = clamp(_shake_timer / _shake_duration, 0.0, 1.0)
		var amount: float = _shake_intensity * t
		_camera.position = _camera_origin + Vector3(
			randf_range(-amount, amount),
			randf_range(-amount, amount),
			0.0
		)
	elif _camera.position != _camera_origin:
		_camera.position = _camera_origin

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion:
		camera_pivot.rotate_y(-event.relative.x * MOUSE_SENS)
		spring_arm.rotate_x(-event.relative.y * MOUSE_SENS)
		spring_arm.rotation.x = clamp(
			spring_arm.rotation.x,
			deg_to_rad(-80),
			deg_to_rad(80)
		)

	if event.is_action_pressed("release_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventKey and event.pressed and not event.echo and event.unicode > 0:
		_cheat_buffer += char(event.unicode).to_lower()
		if _cheat_buffer.length() > _CHEAT_CODE.length():
			_cheat_buffer = _cheat_buffer.right(_CHEAT_CODE.length())
		if _cheat_buffer == _CHEAT_CODE:
			_debug_mode = not _debug_mode
			_cheat_buffer = ""
			if not _debug_mode:
				_fly_mode = false

	if _debug_mode and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_1:
			_fly_mode = not _fly_mode
			if not _fly_mode:
				velocity = Vector3.ZERO
		elif event.physical_keycode == KEY_2:
			CoinWallet.add_coins(1)

func _physics_process(delta: float) -> void:
	if _fly_mode:
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var cam_basis := camera_pivot.global_transform.basis
		var forward := -cam_basis.z
		var right := cam_basis.x
		forward.y = 0.0
		right.y = 0.0
		if forward.length() > 0.0:
			forward = forward.normalized()
		if right.length() > 0.0:
			right = right.normalized()
		var move_dir := forward * -input_dir.y + right * input_dir.x
		velocity.x = move_dir.x * FLY_SPEED
		velocity.z = move_dir.z * FLY_SPEED
		if Input.is_action_pressed("jump"):
			velocity.y = FLY_SPEED
		elif Input.is_key_pressed(KEY_SHIFT):
			velocity.y = -FLY_SPEED
		else:
			velocity.y = 0.0
		move_and_slide()
	elif _knockback_timer > 0.0:
		_knockback_timer -= delta
		if not is_on_floor():
			velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
		move_and_slide()
	else:
		if not is_on_floor():
			velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

		var cam_basis := camera_pivot.global_transform.basis
		var forward := -cam_basis.z
		var right := cam_basis.x
		forward.y = 0.0
		right.y = 0.0
		if forward.length() > 0.0:
			forward = forward.normalized()
		if right.length() > 0.0:
			right = right.normalized()

		var move_dir := forward * -input_dir.y + right * input_dir.x

		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED

		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		if _character_mesh and move_dir.length() > 0.01:
			var target_angle := atan2(-move_dir.x, -move_dir.z)
			_character_mesh.rotation.y = lerp_angle(_character_mesh.rotation.y, target_angle, 10.0 * delta)

		move_and_slide()

	if not _fly_mode and global_position.y < RESPAWN_Y:
		CoinWallet.lose_random_coins()
		global_position = respawn_position
		camera_y = respawn_position.y
		velocity = Vector3.ZERO
		_knockback_timer = 0.0

	camera_y = lerp(camera_y, global_position.y, CAMERA_Y_DAMP * delta)
	camera_pivot.global_position.y = camera_y

	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look.length() > 0.0:
		camera_pivot.rotate_y(-look.x * RIGHT_STICK_SENS)
		spring_arm.rotate_x(-look.y * RIGHT_STICK_SENS)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-80), deg_to_rad(80))
