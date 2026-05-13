extends Node
# Autoloaded as "ItemInventory" — see project.godot

signal items_changed
signal equipment_changed(slot: String, item_id: String)

const ITEMS_PATH := "res://assets/shop_items.json"

var item_data: Dictionary = {}     # id -> item dict (raw JSON)
var owned_items: Dictionary = {}    # id -> true
var equipped: Dictionary = {}       # slot -> item_id

func _ready() -> void:
	_load_items()
	_grant_default_items()
	_equip_defaults()

func _load_items() -> void:
	var file := FileAccess.open(ITEMS_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open shop items JSON at %s" % ITEMS_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Could not parse shop items JSON")
		return
	for item in parsed.get("items", []):
		item_data[item.id] = item

func _grant_default_items() -> void:
	for id in item_data:
		if item_data[id].get("owned_by_default", false):
			owned_items[id] = true

func _equip_defaults() -> void:
	var slots_seen := {}
	for id in item_data:
		var item = item_data[id]
		var slot: String = item.get("slot", "")
		if slot.is_empty() or slots_seen.has(slot):
			continue
		if owns(id):
			equip(slot, id)
			slots_seen[slot] = true

func get_item(id: String) -> Dictionary:
	return item_data.get(id, {})

func owns(item_id: String) -> bool:
	return owned_items.get(item_id, false)

func grant(item_id: String) -> void:
	if not owns(item_id):
		owned_items[item_id] = true
		items_changed.emit()

func equip(slot: String, item_id: String) -> void:
	equipped[slot] = item_id
	equipment_changed.emit(slot, item_id)

func get_equipped(slot: String) -> String:
	return equipped.get(slot, "")

func try_purchase(item_id: String) -> bool:
	var item := get_item(item_id)
	if item.is_empty():
		return false
	if owns(item_id):
		return false
	var price: int = int(item.get("price", 0))
	if not CoinWallet.spend_coins(price):
		return false
	grant(item_id)
	return true
