extends StaticBody3D
class_name HazardTile

const RED_COLOR := Color(1.0, 0.15, 0.15)
const SAFE_COLORS := [
	Color(0.4, 0.6, 1.0),  # blue
	Color(1.0, 1.0, 0.3),  # yellow
	Color(0.4, 1.0, 0.4),  # green
	Color(0.7, 0.4, 1.0),  # purple
]

@export var is_red: bool = false
@export var fall_delay: float = 0.3

var _triggered: bool = false

func _ready() -> void:
	_apply_color()
	$DetectionArea.body_entered.connect(_on_player_entered)

func _apply_color() -> void:
	var mat := StandardMaterial3D.new()
	if is_red:
		mat.albedo_color = RED_COLOR
	else:
		mat.albedo_color = SAFE_COLORS[randi() % SAFE_COLORS.size()]
	$Mesh.set_surface_override_material(0, mat)

func _on_player_entered(body: Node3D) -> void:
	if _triggered or not is_red or not body.is_in_group("player"):
		return
	_triggered = true
	await get_tree().create_timer(fall_delay).timeout
	queue_free()
