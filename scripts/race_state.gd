extends Node
# Autoloaded as "RaceState" — see project.godot
#
# Minimal race bookkeeping: who is still running, who got eliminated, who finished
# and in what order. Autoloaded so the HUD (which lives in main.tscn and persists
# across level swaps) can subscribe without any cross-scene wiring.
#
# This is deliberately not a round manager — voting, brackets and multi-round play
# build on top of it later.

signal racer_eliminated(racer_name: String)
signal racer_finished(racer_name: String, place: int)
signal race_reset
signal countdown_tick(seconds_left: int)
signal race_started

var active_racers: Array[String] = []
var finish_order: Array[String] = []

var countdown_remaining: float = 0.0
var _last_tick: int = -1

func reset_race() -> void:
	active_racers.clear()
	finish_order.clear()
	countdown_remaining = 0.0
	_last_tick = -1
	race_reset.emit()

# Holds every racer at the start line for `duration` seconds. Camera look stays free —
# the point is to let players get oriented before anything moves.
func start_countdown(duration: float) -> void:
	countdown_remaining = duration
	_last_tick = int(ceil(duration))
	countdown_tick.emit(_last_tick)

# False whenever no countdown is running, so level_01 and the hub are unaffected.
func is_locked() -> bool:
	return countdown_remaining > 0.0

func _process(delta: float) -> void:
	if countdown_remaining <= 0.0:
		return
	countdown_remaining -= delta
	if countdown_remaining <= 0.0:
		countdown_remaining = 0.0
		_last_tick = 0
		countdown_tick.emit(0)
		race_started.emit()
		return
	var secs := int(ceil(countdown_remaining))
	if secs != _last_tick:
		_last_tick = secs
		countdown_tick.emit(secs)

func register_racer(racer_name: String) -> void:
	if racer_name in active_racers:
		return
	active_racers.append(racer_name)

func report_eliminated(racer_name: String) -> void:
	if racer_name not in active_racers:
		return
	active_racers.erase(racer_name)
	racer_eliminated.emit(racer_name)

func report_finished(racer_name: String) -> void:
	if racer_name in finish_order or racer_name not in active_racers:
		return
	active_racers.erase(racer_name)
	finish_order.append(racer_name)
	racer_finished.emit(racer_name, finish_order.size())

func place_of(racer_name: String) -> int:
	var idx := finish_order.find(racer_name)
	return idx + 1 if idx >= 0 else 0
