extends CanvasLayer

const ANNOUNCE_TIME := 2.5
const GO_TIME := 0.8

@onready var _coin_label: Label = $CoinCounter/Label
@onready var _balloon_counter: Control = $BalloonCounter
@onready var _balloon_label: Label = $BalloonCounter/Label
@onready var _announce: Label = $RaceAnnounce/Label
@onready var _countdown_root: Control = $Countdown
@onready var _countdown_number: Label = $Countdown/Number
@onready var _countdown_title: Label = $Countdown/Title
@onready var _countdown_ready: Label = $Countdown/Ready
@onready var _countdown_hint: Label = $Countdown/Hint
@onready var _bonus_label: Label = $BonusTimer/Label
@onready var _fade: ColorRect = $Fade

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
	_countdown_root.visible = false

func _on_countdown_tick(seconds_left: int) -> void:
	_countdown_root.visible = true
	_countdown_root.modulate.a = 1.0
	_countdown_title.text = RaceState.race_title
	if seconds_left <= 0:
		# Gate opens: swap to GO!, drop the "get ready" copy and fade the dim out.
		_countdown_number.text = "GO!"
		_countdown_number.add_theme_color_override("font_color", Color(0.45, 1.0, 0.5))
		_countdown_ready.visible = false
		_countdown_hint.visible = false
		_go_timer = GO_TIME
		var tween := create_tween()
		tween.tween_property(_countdown_root, "modulate:a", 0.0, GO_TIME)
	else:
		_countdown_number.text = str(seconds_left)
		_countdown_number.add_theme_color_override("font_color", Color(1, 1, 1))
		_countdown_ready.visible = true
		_countdown_hint.visible = true

func _process(delta: float) -> void:
	if _go_timer > 0.0:
		_go_timer -= delta
		if _go_timer <= 0.0:
			_countdown_root.visible = false
	if _announce_timer <= 0.0:
		return
	_announce_timer -= delta
	if _announce_timer <= 0.0:
		$RaceAnnounce.visible = false

func announce(text: String, color: Color = Color(1, 0.85, 0.1)) -> void:
	_announce_text(text, color)

# --- Bonus stage timer (level_03 Gold Rooms) ---

func show_bonus_timer(seconds_left: float) -> void:
	$BonusTimer.visible = true
	set_bonus_time(seconds_left)

func set_bonus_time(seconds_left: float) -> void:
	_bonus_label.text = "GOLD ROOMS: %d" % int(ceil(maxf(seconds_left, 0.0)))
	# Last five seconds go red so the cutoff isn't a surprise.
	_bonus_label.add_theme_color_override("font_color", Color(1, 0.3, 0.2) if seconds_left <= 5.0 else Color(1, 0.85, 0.1))

func hide_bonus_timer() -> void:
	$BonusTimer.visible = false

# Fades to black, runs `midpoint` (a teleport or scene swap), then fades back in.
# The HUD is an autoload, so the fade survives a change_scene_to_file() in midpoint.
func fade_through_black(midpoint: Callable, out_time: float = 0.25, in_time: float = 0.4) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, out_time)
	tween.tween_callback(midpoint)
	tween.tween_interval(0.1)
	tween.tween_property(_fade, "color:a", 0.0, in_time)

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
