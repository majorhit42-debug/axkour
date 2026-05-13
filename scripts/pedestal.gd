extends StaticBody3D
class_name Pedestal

const SPARKLE_SCENE := preload("res://scenes/effects/sparkle.tscn")

@export var item_id: String = ""

var _player_near: bool = false

func _ready() -> void:
	$InteractArea.body_entered.connect(_on_body_entered)
	$InteractArea.body_exited.connect(_on_body_exited)
	ItemInventory.items_changed.connect(_refresh_label)
	ItemInventory.equipment_changed.connect(_on_equipment_changed)
	_setup_display()
	_refresh_label()

func _setup_display() -> void:
	var item := ItemInventory.get_item(item_id)
	if item.is_empty():
		push_error("Pedestal references unknown item id: %s" % item_id)
		return
	var slot: String = item.get("slot", "")
	var col_arr = item.get("color", [1, 1, 1])
	var color := Color(col_arr[0], col_arr[1], col_arr[2])

	if slot == "skin":
		var mi := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.3
		capsule.height = 0.9
		mi.mesh = capsule
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mi.set_surface_override_material(0, mat)
		$DisplayItem.add_child(mi)
	elif slot == "hat":
		var hat_type: String = item.get("hat_type", "")
		for mi in HatBuilder.make_meshes(hat_type, color, 0.7):
			$DisplayItem.add_child(mi)

func _refresh_label() -> void:
	var item := ItemInventory.get_item(item_id)
	if item.is_empty():
		return
	var item_name: String = item.get("name", "?")
	var price: int = int(item.get("price", 0))
	var slot: String = item.get("slot", "")
	var is_owned := ItemInventory.owns(item_id)
	var is_equipped := ItemInventory.get_equipped(slot) == item_id

	if is_equipped:
		$Label3D.text = "%s (Equipped)" % item_name
	elif is_owned:
		$Label3D.text = "Equip %s\n[E]" % item_name
	else:
		$Label3D.text = "Buy %s — %d coins\n[E]" % [item_name, price]

func _on_equipment_changed(_slot: String, _id: String) -> void:
	_refresh_label()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		$Label3D.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		$Label3D.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_near:
		return
	if not event.is_action_pressed("interact"):
		return
	_interact()

func _interact() -> void:
	var item := ItemInventory.get_item(item_id)
	if item.is_empty():
		return
	var slot: String = item.get("slot", "")
	if ItemInventory.owns(item_id):
		if ItemInventory.get_equipped(slot) != item_id:
			ItemInventory.equip(slot, item_id)
	else:
		if ItemInventory.try_purchase(item_id):
			ItemInventory.equip(slot, item_id)
			_spawn_sparkle()

func _spawn_sparkle() -> void:
	var sparkle := SPARKLE_SCENE.instantiate()
	get_tree().current_scene.add_child(sparkle)
	sparkle.global_position = $DisplayItem.global_position
