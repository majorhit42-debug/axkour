extends CanvasLayer

@onready var _coin_label: Label = $CoinCounter/Label

func _ready() -> void:
	CoinWallet.coin_count_changed.connect(_on_coin_count_changed)
	_on_coin_count_changed(CoinWallet.coins)

func _on_coin_count_changed(new_count: int) -> void:
	_coin_label.text = "Coins: %d" % new_count
