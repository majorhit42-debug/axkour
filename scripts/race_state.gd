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

var active_racers: Array[String] = []
var finish_order: Array[String] = []

func reset_race() -> void:
	active_racers.clear()
	finish_order.clear()
	race_reset.emit()

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
