class_name GameState
extends Node
## The game's central state: money, day number and whether the restaurant
## is open.
##
## The game's instance is the [code]Game[/code] autoload, so any script can use
## [code]Game.money[/code]. Values only change through the methods below,
## which emit signals that UI listens to. Tests create their
## own instances instead of touching the autoload.

signal money_changed(money: int)
signal day_changed(day: int)
signal open_changed(is_open: bool)
## Emitted once when [param day] ends, by bed or by the clock, after the
## restaurant has closed.
signal day_ended(day: int)

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
## The time of day. Created once and never replaced, so signal connections to
## it keep working. The day cycle ticks it; reaching 2:00 am
## ends the day.
var clock: GameClock:
	get:
		return _clock
	set(_value):
		push_error("GameState: clock can't be replaced, use start_next_day()")
## Today's customers and takings. Like the clock, created once and never
## replaced; [method start_next_day] clears it.
var stats: DayStats:
	get:
		return _stats
	set(_value):
		push_error("GameState: stats can't be replaced, use stats.reset()")
var is_open: bool:
	get:
		return _is_open
	set(_value):
		push_error("GameState: is_open is read-only, use set_open()")
var is_day_over: bool:
	get:
		return _is_day_over
	set(_value):
		push_error("GameState: is_day_over is read-only, use end_day()")

var _money: int = STARTING_MONEY
var _day: int = 1
var _clock: GameClock = GameClock.new()
var _stats: DayStats = DayStats.new()
var _is_open: bool = false
var _is_day_over: bool = false


func _init() -> void:
	_clock.reached_end.connect(end_day)


## Puts everything back to the start: starting money, day 1 at 6:00 am with
## the clock running, and the restaurant closed.
func new_game() -> void:
	_stats.reset()
	_set_money(STARTING_MONEY)
	_is_day_over = false
	# Clock first, so day_changed listeners already see 6:00 am.
	_clock.reset()
	_clock.resume(self)
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


## Opens or closes the restaurant. Ignored once the day is over.
## Emits [signal open_changed] only when it actually changes.
func set_open(value: bool) -> void:
	if _is_open == value or _is_day_over:
		return
	_is_open = value
	open_changed.emit(_is_open)


## Ends the day: closes the restaurant, then emits [signal day_ended].
## Calling it again before [method start_next_day] does nothing.
func end_day() -> void:
	if _is_day_over:
		return
	_clock.pause(self)
	set_open(false)
	_is_day_over = true
	day_ended.emit(_day)


## Moves on to the next day, which starts closed. Returns false, changing
## nothing, if the day isn't over yet.
func start_next_day() -> bool:
	if not _is_day_over:
		return false
	_is_day_over = false
	_stats.reset()
	_clock.reset()
	_clock.resume(self)
	_set_day(_day + 1)
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


func _is_valid_amount(amount: int) -> bool:
	if amount <= 0:
		push_error("GameState: amount must be positive, got %d" % amount)
		return false
	return true
