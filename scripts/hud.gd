extends CanvasLayer

@onready var _coin_label: Label = $CoinCounter/Label
@onready var _balloon_counter: Control = $BalloonCounter
@onready var _balloon_label: Label = $BalloonCounter/Label

func _ready() -> void:
	CoinWallet.coin_count_changed.connect(_on_coin_count_changed)
	_on_coin_count_changed(CoinWallet.coins)
	ItemInventory.consumable_count_changed.connect(_on_consumable_count_changed)
	_on_consumable_count_changed("balloon", ItemInventory.get_consumable_count("balloon"))

func _on_coin_count_changed(new_count: int) -> void:
	_coin_label.text = "Coins: %d" % new_count

func _on_consumable_count_changed(item_id: String, new_count: int) -> void:
	if item_id != "balloon":
		return
	_balloon_counter.visible = new_count > 0
	_balloon_label.text = "Balloons: %d" % new_count
