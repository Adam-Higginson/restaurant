class_name GameState
extends Node
## The game's central state: money, pantry, day number and phase.
##
## The game's instance is the [code]Game[/code] autoload, so any script can use
## [code]Game.money[/code] or [code]Game.pantry[/code]. Values only change through
## the methods below, which emit signals that UI listens to. Tests create their
## own instances instead of touching the autoload.

signal money_changed(money: int)
signal phase_changed(phase: Phase)
signal day_changed(day: int)

## The parts of each day. See the core loop in docs/GDD.md.
enum Phase { PREP, SERVICE, SUMMARY }

const STARTING_MONEY: int = 50

## Coins the player has. Never negative.
var money: int:
	get:
		return _money
var day: int:
	get:
		return _day
var phase: Phase:
	get:
		return _phase
## Created once and cleared by [method new_game], never replaced, so signal
## connections to it keep working.
var pantry: Pantry = Pantry.new()

var _money: int = STARTING_MONEY
var _day: int = 1
var _phase: Phase = Phase.PREP


## Puts everything back to the start: starting money, an empty pantry, day 1
## and the prep phase.
func new_game() -> void:
	pantry.clear()
	_set_money(STARTING_MONEY)
	_set_day(1)
	_set_phase(Phase.PREP)


func can_afford(amount: int) -> bool:
	return amount <= _money


## Adds [param amount] coins. [param amount] must be positive.
func earn(amount: int) -> void:
	if not _is_valid_amount(amount):
		return
	_set_money(_money + amount)


## Takes [param amount] coins. If the player can't afford it, changes nothing
## and returns false.
func spend(amount: int) -> bool:
	if not _is_valid_amount(amount) or not can_afford(amount):
		return false
	_set_money(_money - amount)
	return true


## Opens the restaurant: prep to service. Returns false if not in prep.
func start_service() -> bool:
	return _advance(Phase.PREP, Phase.SERVICE)


## Closes the restaurant: service to summary. Returns false if not in service.
func end_service() -> bool:
	return _advance(Phase.SERVICE, Phase.SUMMARY)


## Moves from the summary to the next day's prep. Returns false if not in the
## summary.
func start_next_day() -> bool:
	if not _advance(Phase.SUMMARY, Phase.PREP):
		return false
	_set_day(_day + 1)
	return true


func _advance(from: Phase, to: Phase) -> bool:
	if _phase != from:
		return false
	_set_phase(to)
	return true


func _set_money(value: int) -> void:
	if _money == value:
		return
	_money = value
	money_changed.emit(_money)


func _set_day(value: int) -> void:
	if _day == value:
		return
	_day = value
	day_changed.emit(_day)


func _set_phase(value: Phase) -> void:
	if _phase == value:
		return
	_phase = value
	phase_changed.emit(_phase)


func _is_valid_amount(amount: int) -> bool:
	if amount <= 0:
		push_error("GameState: amount must be positive, got %d" % amount)
		return false
	return true
