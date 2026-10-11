extends GameTestSuite
## Tests for ArrivalPlanner: when today's scheduled customers walk in.

## Lunch: due 12:30, still coming until 14:00.
const DUE: int = 12 * 60 + 30
const UNTIL: int = 14 * 60

var _lunch: Arrival
var _planner: ArrivalPlanner


func before_test() -> void:
	_lunch = _arrival(DUE, UNTIL)
	_planner = ArrivalPlanner.new([_lunch])


# --- On time --------------------------------------------------------------------

func test_due_at_its_time_while_open() -> void:
	assert_int(_planner.check(DUE, true)).is_equal(1)


func test_not_due_before_its_time() -> void:
	assert_int(_planner.check(DUE - 10, true)).is_equal(0)


func test_not_due_while_closed() -> void:
	assert_int(_planner.check(DUE, false)).is_equal(0)


# --- Opening late ---------------------------------------------------------------

func test_opening_late_brings_them_straight_away() -> void:
	_planner.check(DUE, false)
	_planner.check(DUE + 30, false)
	assert_int(_planner.check(DUE + 40, true)).is_equal(1)


func test_still_due_just_before_the_end() -> void:
	assert_int(_planner.check(UNTIL - 10, true)).is_equal(1)


func test_not_due_from_the_end_onwards() -> void:
	assert_int(_planner.check(UNTIL, true)).is_equal(0)
	assert_int(_planner.check(UNTIL + 10, true)).is_equal(0)


func test_closed_for_the_whole_window_means_nobody_comes() -> void:
	for minutes: int in range(DUE, UNTIL, 10):
		assert_int(_planner.check(minutes, false)).is_equal(0)
	assert_int(_planner.check(UNTIL, true)).is_equal(0)


# --- Once a day -------------------------------------------------------------------

func test_comes_only_once() -> void:
	_planner.check(DUE, true)
	assert_int(_planner.check(DUE, true)).is_equal(0)
	assert_int(_planner.check(DUE + 10, true)).is_equal(0)


func test_reset_lets_them_come_again_the_next_day() -> void:
	_planner.check(DUE, true)
	_planner.reset()
	assert_int(_planner.check(DUE, true)).is_equal(1)


# --- Several arrivals ------------------------------------------------------------------

func test_lunch_and_dinner_come_at_their_own_times() -> void:
	var dinner: Arrival = _arrival(19 * 60, 21 * 60)
	var planner: ArrivalPlanner = ArrivalPlanner.new([_lunch, dinner])
	assert_int(planner.check(DUE, true)).is_equal(1)
	assert_int(planner.check(18 * 60, true)).is_equal(0)
	assert_int(planner.check(19 * 60, true)).is_equal(1)


func test_two_arrivals_due_together_both_count() -> void:
	var planner: ArrivalPlanner = ArrivalPlanner.new([_lunch, _arrival(DUE, UNTIL)])
	assert_int(planner.check(DUE, true)).is_equal(2)


func test_no_arrivals_means_nobody_comes() -> void:
	var planner: ArrivalPlanner = ArrivalPlanner.new([])
	assert_int(planner.check(DUE, true)).is_equal(0)


func _arrival(due: int, until: int) -> Arrival:
	var arrival: Arrival = Arrival.new()
	arrival.due_minutes = due
	arrival.until_minutes = until
	return arrival
