class_name ArrivalPlanner
extends RefCounted
## Decides when today's scheduled customers walk in, with no nodes, so it's
## tested on its own. The customer spawner asks it on every clock step and
## when the restaurant opens.
##
## An [Arrival] is due from its [member Arrival.due_minutes] until (not
## including) its [member Arrival.until_minutes], but only while the
## restaurant is open, and only once a day.

var _arrivals: Array[Arrival] = []
## Arrivals that have already come today.
var _done: Array[Arrival] = []


func _init(arrivals: Array[Arrival]) -> void:
	_arrivals = arrivals


## How many customers should walk in now, at [param minutes]. Counts each one
## as having come, so asking again at the same time returns 0.
func check(minutes: int, is_open: bool) -> int:
	# TODO 1:
	#   a. While closed, nobody is due: return 0.
	#   b. For each arrival in `_arrivals` that isn't in `_done` yet: if
	#      `minutes` is at or after its due time and before its until time,
	#      add it to `_done` and count it.
	#   c. Return the count.
	return 0


## Forgets who has come, for a new day.
func reset() -> void:
	# TODO 2: Empty `_done`.
	pass
