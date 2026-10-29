extends Area3D
class_name GoldenAlmondWater
# The Gold Rooms jackpot: a glowing bottle of Almond Water worth a pile of coins.

signal collected

const SPARKLE_SCENE := preload("res://scenes/effects/sparkle.tscn")

@export var coin_value: int = 10

var _collected: bool = false
var _t: float = 0.0
var _base_y: float

func _ready() -> void:
	_base_y = $Bottle.position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _collected:
		return
	_t += delta
	$Bottle.rotation.y = _t * 1.5
	$Bottle.position.y = _base_y + sin(_t * 2.0) * 0.15

func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	CoinWallet.add_coins(coin_value)
	HUD.announce("JACKPOT! +%d coins" % coin_value, Color(1, 0.85, 0.1))
	for i in 3:
		var sparkle := SPARKLE_SCENE.instantiate()
		get_tree().current_scene.add_child(sparkle)
		sparkle.global_position = global_position + Vector3(randf_range(-0.6, 0.6), randf_range(0.0, 1.0), randf_range(-0.6, 0.6))
	collected.emit()
	queue_free()
