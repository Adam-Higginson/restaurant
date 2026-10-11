class_name DayStats
extends RefCounted
## Today's tally: customers served and lost, and what they paid. The
## end-of-day summary reads it, and [GameState] starts a fresh one each day.

# Read-only from outside, like GameState's money: the getter returns the
# private variable, and the setter refuses, so only the methods below change it.
var served: int:
	get:
		return _served
	set(_value):
		push_error("DayStats: served is read-only, use record_served()")
## Customers who left without being served.
var lost: int:
	get:
		return _lost
	set(_value):
		push_error("DayStats: lost is read-only, use record_lost()")
## Everything customers paid, tips included.
var earnings: int:
	get:
		return _earnings
	set(_value):
		push_error("DayStats: earnings is read-only, use record_served()")
var tips: int:
	get:
		return _tips
	set(_value):
		push_error("DayStats: tips is read-only, use record_served()")

var _served: int = 0
var _lost: int = 0
var _earnings: int = 0
var _tips: int = 0


## Counts a customer who was served and paid [param bill].
func record_served(bill: Bill) -> void:
	_served += 1
	_earnings += bill.total()
	_tips += bill.tips()


## Counts a customer who left without being served.
func record_lost() -> void:
	_lost += 1


## Starts the tally again from zero.
func reset() -> void:
	_served = 0
	_lost = 0
	_earnings = 0
	_tips = 0
