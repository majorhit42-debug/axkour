extends Node
# Autoloaded as "CoinWallet" — see project.godot

signal coin_count_changed(new_count: int)

const MIN_LOSS_ON_DEATH := 1
const MAX_LOSS_ON_DEATH := 3

var coins: int = 0

func add_coins(amount: int) -> void:
	coins += amount
	coin_count_changed.emit(coins)

func lose_random_coins() -> int:
	if coins <= 0:
		return 0
	var loss := randi_range(MIN_LOSS_ON_DEATH, MAX_LOSS_ON_DEATH)
	loss = min(loss, coins)
	coins -= loss
	coin_count_changed.emit(coins)
	return loss

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coin_count_changed.emit(coins)
	return true

func reset() -> void:
	coins = 0
	coin_count_changed.emit(coins)
