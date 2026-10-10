class_name GameState
extends Node
## The game's central state: money, pantry, day number and whether the
## restaurant is open.
##
## The game's instance is the [code]Game[/code] autoload, so any script can use
## [code]Game.money[/code]. Values only change through the methods below,
## which emit signals that UI listens to. Tests create their
## own instances instead of touching the autoload.

signal money_changed(money: int)
signal day_changed(day: int)
signal open_changed(is_open: bool)

const STARTING_MONEY: int = 50

# These are read-only. Without a setter, Godot would quietly accept an
# assignment into hidden storage that the getter never reads.

## Coins the player has. Never negative.
var money: int:
	get:
		return _money
	set(_value):
		push_error("GameState: money is read-only, use earn() or spend()")
var day: int:
	get:
		return _day
	set(_value):
		push_error("GameState: day is read-only, use start_next_day()")
## Created once and cleared by [method new_game], never replaced, so signal
## connections to it keep working.
var pantry: Pantry:
	get:
		return _pantry
	set(_value):
		push_error("GameState: pantry can't be replaced, use pantry.clear()")
var is_open: bool:
	get:
		return _is_open
	set(_value):
		push_error("GameState: is_open is read-only, use set_open()")

var _money: int = STARTING_MONEY
var _day: int = 1
var _pantry: Pantry = Pantry.new()
var _is_open: bool = false


## Puts everything back to the start: starting money, an empty pantry, day 1
## and the restaurant closed.
func new_game() -> void:
	_pantry.clear()
	_set_money(STARTING_MONEY)
	_set_day(1)
	set_open(false)


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


## Opens or closes the restaurant. Emits [signal open_changed] only when it
## actually changes.
func set_open(value: bool) -> void:
	if _is_open == value:
		return
	_is_open = value
	open_changed.emit(_is_open)


## Closes the restaurant and moves to the next day.
func start_next_day() -> void:
	set_open(false)
	_set_day(_day + 1)


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


func _is_valid_amount(amount: int) -> bool:
	if amount <= 0:
		push_error("GameState: amount must be positive, got %d" % amount)
		return false
	return true