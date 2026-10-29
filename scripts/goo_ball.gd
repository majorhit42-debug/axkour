extends Area3D
class_name GooBall
# The glob a MonsterCannon spits across the catwalk. Moves in a straight line and
# shoves the first racer it touches off the side with knockback — the fall does the
# killing, through the racer's normal fall-death path.

var direction: Vector3 = Vector3.FORWARD
var speed: float = 8.0
var max_range: float = 13.0
var knockback_side: float = 9.0
var knockback_up: float = 4.0

var _traveled: float = 0.0
var _hit: bool = false
var _wobble: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var step := speed * delta
	global_position += direction * step
	_traveled += step
	_wobble += delta * 14.0
	$Mesh.scale = Vector3.ONE * (1.0 + sin(_wobble) * 0.08)
	if _traveled >= max_range:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if _hit or not body.is_in_group("racer"):
		return
	_hit = true
	if body.has_method("apply_knockback"):
		body.apply_knockback(direction * knockback_side + Vector3.UP * knockback_up)
	if body.has_method("shake_camera"):
		body.shake_camera(0.3, 0.35)
	_splat()
	queue_free()

func _splat() -> void:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 30
	p.lifetime = 0.7
	p.direction = -direction
	p.spread = 70.0
	p.gravity = Vector3(0, -9.8, 0)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 6.0
	p.scale_amount_min = 0.1
	p.scale_amount_max = 0.22
	p.color = Color(0.8, 1.0, 0.3)
	var root := get_tree().current_scene
	root.add_child(p)
	p.global_position = global_position
	p.restart()
	root.get_tree().create_timer(1.2).timeout.connect(p.queue_free)
