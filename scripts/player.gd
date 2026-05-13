extends CharacterBody3D

const SPEED = 6.0
const JUMP_VELOCITY = 5.0
const MOUSE_SENS = 0.003
const RIGHT_STICK_SENS = 0.05
const RESPAWN_Y = -20.0
const CAMERA_Y_DAMP = 2.5  # lower = more lag behind the player's jump

var respawn_position: Vector3
var camera_y: float

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var _body_mesh: MeshInstance3D = $Mesh
var _camera_origin: Vector3
var _shake_timer := 0.0
var _shake_intensity := 0.0
var _shake_duration := 0.0
var _knockback_timer := 0.0

func _ready() -> void:
	camera_y = global_position.y
	_camera_origin = _camera.position
	ItemInventory.equipment_changed.connect(_on_equipment_changed)
	_apply_skin()

func _on_equipment_changed(slot: String, _id: String) -> void:
	if slot == "skin":
		_apply_skin()

func _apply_skin() -> void:
	var skin_id := ItemInventory.get_equipped("skin")
	if skin_id.is_empty():
		return
	var item := ItemInventory.get_item(skin_id)
	var col_arr = item.get("color", [1, 1, 1])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(col_arr[0], col_arr[1], col_arr[2])
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

func _physics_process(delta: float) -> void:
	if _knockback_timer > 0.0:
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

		move_and_slide()

	if global_position.y < RESPAWN_Y:
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
