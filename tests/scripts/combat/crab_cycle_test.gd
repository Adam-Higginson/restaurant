extends GameTestSuite
## Tests for CrabCycle: a fog-crab's fight as a state machine. Time is moved
## on by hand with tick(), so every change of state is exact.

var _cycle: CrabCycle
var _states: Array[CrabCycle.State] = []


func before_test() -> void:
	_cycle = CrabCycle.new()
	_states = []
	_cycle.state_changed.connect(func(state: CrabCycle.State) -> void: _states.append(state))


func test_it_starts_idle_and_stays_idle_until_engaged() -> void:
	_cycle.tick(10.0)

	assert_int(_cycle.state).is_equal(CrabCycle.State.IDLE)
	assert_array(_states).is_empty()


func test_engaged_it_cycles_windup_attack_opening_and_round_again() -> void:
	_cycle.engage()
	assert_int(_cycle.state).is_equal(CrabCycle.State.WINDUP)

	_cycle.tick(_cycle.windup_seconds)
	assert_int(_cycle.state).is_equal(CrabCycle.State.ATTACK)

	_cycle.tick(_cycle.attack_seconds)
	assert_int(_cycle.state).is_equal(CrabCycle.State.OPENING)

	_cycle.tick(_cycle.opening_seconds)
	assert_int(_cycle.state).is_equal(CrabCycle.State.WINDUP)

	assert_array(_states).contains_exactly([
		CrabCycle.State.WINDUP, CrabCycle.State.ATTACK, CrabCycle.State.OPENING,
		CrabCycle.State.WINDUP,
	])


func test_the_windup_lasts_its_full_time() -> void:
	_cycle.engage()

	_cycle.tick(_cycle.windup_seconds - 0.01)

	assert_int(_cycle.state).is_equal(CrabCycle.State.WINDUP)
	assert_float(_cycle.progress).is_greater(0.9)


func test_the_attack_lands_as_the_windup_ends() -> void:
	var hits: Array[int] = [0]
	_cycle.attacked.connect(func() -> void: hits[0] += 1)
	_cycle.engage()

	_cycle.tick(_cycle.windup_seconds - 0.01)
	assert_int(hits[0]).is_equal(0)
	_cycle.tick(0.02)

	assert_int(hits[0]).is_equal(1)


func test_one_long_tick_runs_through_several_states() -> void:
	_cycle.engage()

	_cycle.tick(_cycle.windup_seconds + _cycle.attack_seconds + 0.1)

	assert_int(_cycle.state).is_equal(CrabCycle.State.OPENING)


func test_strikes_only_count_while_it_is_open() -> void:
	_cycle.engage()
	assert_bool(_cycle.take_strike()).is_false()

	_cycle.tick(_cycle.windup_seconds)
	assert_bool(_cycle.take_strike()).is_false()

	_cycle.tick(_cycle.attack_seconds)
	assert_bool(_cycle.is_open()).is_true()
	assert_bool(_cycle.take_strike()).is_true()

	assert_int(_cycle.strikes).is_equal(1)


func test_an_idle_crab_cant_be_struck() -> void:
	assert_bool(_cycle.take_strike()).is_false()
	assert_int(_cycle.strikes).is_equal(0)


func test_enough_strikes_clear_its_fog() -> void:
	var cleared: Array[int] = [0]
	_cycle.cleared.connect(func() -> void: cleared[0] += 1)
	_cycle.engage()
	_cycle.tick(_cycle.windup_seconds + _cycle.attack_seconds)

	for i: int in _cycle.strikes_to_clear - 1:
		_cycle.take_strike()
	assert_int(_cycle.state).is_equal(CrabCycle.State.OPENING)
	_cycle.take_strike()

	assert_int(_cycle.state).is_equal(CrabCycle.State.CLEARED)
	assert_int(cleared[0]).is_equal(1)


func test_a_cleared_crab_never_fights_again() -> void:
	_cycle.strikes_to_clear = 1
	_cycle.engage()
	_cycle.tick(_cycle.windup_seconds + _cycle.attack_seconds)
	_cycle.take_strike()

	_cycle.engage()
	_cycle.tick(30.0)
	_cycle.reset()

	assert_int(_cycle.state).is_equal(CrabCycle.State.CLEARED)
	assert_bool(_cycle.take_strike()).is_false()


func test_a_parry_staggers_it_and_strikes_count() -> void:
	_cycle.engage()
	_cycle.tick(_cycle.windup_seconds)

	_cycle.parry()

	assert_int(_cycle.state).is_equal(CrabCycle.State.STAGGERED)
	assert_bool(_cycle.take_strike()).is_true()


func test_a_stagger_lasts_its_time_then_it_rears_up_again() -> void:
	_cycle.engage()
	_cycle.tick(_cycle.windup_seconds)
	_cycle.parry()

	_cycle.tick(_cycle.stagger_seconds - 0.01)
	assert_int(_cycle.state).is_equal(CrabCycle.State.STAGGERED)
	_cycle.tick(0.02)

	assert_int(_cycle.state).is_equal(CrabCycle.State.WINDUP)


func test_a_parry_only_works_on_an_attack() -> void:
	_cycle.engage()

	_cycle.parry()

	assert_int(_cycle.state).is_equal(CrabCycle.State.WINDUP)


func test_disengaging_keeps_its_strikes() -> void:
	_cycle.engage()
	_cycle.tick(_cycle.windup_seconds + _cycle.attack_seconds)
	_cycle.take_strike()

	_cycle.disengage()

	assert_int(_cycle.state).is_equal(CrabCycle.State.IDLE)
	assert_int(_cycle.strikes).is_equal(1)


func test_reset_forgets_its_strikes() -> void:
	_cycle.engage()
	_cycle.tick(_cycle.windup_seconds + _cycle.attack_seconds)
	_cycle.take_strike()

	_cycle.reset()

	assert_int(_cycle.state).is_equal(CrabCycle.State.IDLE)
	assert_int(_cycle.strikes).is_equal(0)
