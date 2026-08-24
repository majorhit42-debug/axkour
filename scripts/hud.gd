extends CanvasLayer

const ANNOUNCE_TIME := 2.5
const GO_TIME := 0.8

@onready var _coin_label: Label = $CoinCounter/Label
@onready var _balloon_counter: Control = $BalloonCounter
@onready var _balloon_label: Label = $BalloonCounter/Label
@onready var _announce: Label = $RaceAnnounce/Label
@onready var _countdown: Label = $Countdown/Label

var _announce_timer: float = 0.0
var _go_timer: float = 0.0

func _ready() -> void:
	CoinWallet.coin_count_changed.connect(_on_coin_count_changed)
	_on_coin_count_changed(CoinWallet.coins)
	ItemInventory.consumable_count_changed.connect(_on_consumable_count_changed)
	_on_consumable_count_changed("balloon", ItemInventory.get_consumable_count("balloon"))
	RaceState.countdown_tick.connect(_on_countdown_tick)
	RaceState.racer_eliminated.connect(_on_racer_eliminated)
	RaceState.racer_finished.connect(_on_racer_finished)
	$RaceAnnounce.visible = false
	$Countdown.visible = false

func _on_countdown_tick(seconds_left: int) -> void:
	$Countdown.visible = true
	if seconds_left <= 0:
		_countdown.text = "GO!"
		_countdown.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_go_timer = GO_TIME
	else:
		_countdown.text = str(seconds_left)
		_countdown.add_theme_color_override("font_color", Color(1, 1, 1))

func _process(delta: float) -> void:
	if _go_timer > 0.0:
		_go_timer -= delta
		if _go_timer <= 0.0:
			$Countdown.visible = false
	if _announce_timer <= 0.0:
		return
	_announce_timer -= delta
	if _announce_timer <= 0.0:
		$RaceAnnounce.visible = false

func _announce_text(text: String, color: Color) -> void:
	_announce.text = text
	_announce.add_theme_color_override("font_color", color)
	$RaceAnnounce.visible = true
	_announce_timer = ANNOUNCE_TIME

func _on_racer_eliminated(racer_name: String) -> void:
	if racer_name == "You":
		return  # the YOU DIED screen already covers this
	_announce_text("%s was eliminated!" % racer_name, Color(1, 0.35, 0.3))

func _on_racer_finished(racer_name: String, place: int) -> void:
	var suffix: String = ["st", "nd", "rd"][place - 1] if place <= 3 else "th"
	if racer_name == "You":
		_announce_text("You finished %d%s!" % [place, suffix], Color(1, 0.85, 0.1))
	else:
		_announce_text("%s finished %d%s" % [racer_name, place, suffix], Color(0.8, 0.9, 1))

func _on_coin_count_changed(new_count: int) -> void:
	_coin_label.text = "Coins: %d" % new_count

func _on_consumable_count_changed(item_id: String, new_count: int) -> void:
	if item_id != "balloon":
		return
	_balloon_counter.visible = new_count > 0
	_balloon_label.text = "Balloons: %d" % new_count
