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
	if not is_open:
		return 0

	var arrival_count: int = 0
	for arrival: Arrival in _arrivals:
		if _done.has(arrival):
			continue
		if minutes >= arrival.due_minutes and minutes < arrival.until_minutes:
			arrival_count += 1
			_done.append(arrival)

	return arrival_count


## Forgets who has come, for a new day.
func reset() -> void:
	_done.clear()
