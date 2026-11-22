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

	assert_int(_cycle.damage_taken).is_equal(1)


func test_an_idle_crab_cant_be_struck() -> void:
	assert_bool(_cycle.take_strike()).is_false()
	assert_int(_cycle.damage_taken).is_equal(0)


func test_enough_damage_clears_its_fog() -> void:
	var cleared: Array[int] = [0]
	_cycle.cleared.connect(func() -> void: cleared[0] += 1)
	_cycle.engage()
	_cycle.tick(_cycle.windup_seconds + _cycle.attack_seconds)

	for i: int in _cycle.fog - 1:
		_cycle.take_strike()
	assert_int(_cycle.state).is_equal(CrabCycle.State.OPENING)
	_cycle.take_strike()

	assert_int(_cycle.state).is_equal(CrabCycle.State.CLEARED)
	assert_int(cleared[0]).is_equal(1)


func test_a_cleared_crab_never_fights_again() -> void:
	_cycle.fog = 1
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


func test_disengaging_keeps_its_damage() -> void:
	_cycle.engage()
	_cycle.tick(_cycle.windup_seconds + _cycle.attack_seconds)
	_cycle.take_strike()

	_cycle.disengage()

	assert_int(_cycle.state).is_equal(CrabCycle.State.IDLE)
	assert_int(_cycle.damage_taken).is_equal(1)


func test_reset_forgets_its_damage() -> void:
	_cycle.engage()
	_cycle.tick(_cycle.windup_seconds + _cycle.attack_seconds)
	_cycle.take_strike()

	_cycle.reset()

	assert_int(_cycle.state).is_equal(CrabCycle.State.IDLE)
	assert_int(_cycle.damage_taken).is_equal(0)


func test_a_strike_does_its_damage() -> void:
	_open()

	_cycle.take_strike(2)

	assert_int(_cycle.damage_taken).is_equal(2)


func test_its_fog_is_eight() -> void:
	assert_int(_cycle.fog).is_equal(8)


func test_a_big_enough_blow_clears_it_at_once() -> void:
	_open()

	_cycle.take_strike(_cycle.fog)

	assert_int(_cycle.state).is_equal(CrabCycle.State.CLEARED)


func test_it_commits_for_the_end_of_its_windup() -> void:
	_cycle.engage()
	_cycle.tick(_cycle.windup_seconds - _cycle.commit_seconds - 0.01)
	assert_bool(_cycle.is_committed()).is_false()

	_cycle.tick(0.02)

	assert_bool(_cycle.is_committed()).is_true()


func test_a_perfect_parry_flips_it() -> void:
	_cycle.engage()
	_cycle.tick(_cycle.windup_seconds)

	_cycle.parry(true)

	assert_int(_cycle.state).is_equal(CrabCycle.State.FLIPPED)


func test_a_lunging_crab_can_be_flipped() -> void:
	_cycle.engage()
	_cycle.tick(_cycle.windup_seconds)

	assert_bool(_cycle.flip()).is_true()

	assert_int(_cycle.state).is_equal(CrabCycle.State.FLIPPED)


func test_only_a_lunging_crab_can_be_flipped() -> void:
	_cycle.engage()
	assert_bool(_cycle.flip()).is_false()

	_cycle.tick(_cycle.windup_seconds + _cycle.attack_seconds)

	assert_bool(_cycle.flip()).is_false()
	assert_int(_cycle.state).is_equal(CrabCycle.State.OPENING)


func test_flipped_it_stays_open_for_its_full_time() -> void:
	_cycle.engage()
	_cycle.tick(_cycle.windup_seconds)
	_cycle.flip()

	_cycle.tick(_cycle.flip_seconds - 0.01)
	assert_int(_cycle.state).is_equal(CrabCycle.State.FLIPPED)
	assert_bool(_cycle.take_strike()).is_true()
	_cycle.tick(0.02)

	assert_int(_cycle.state).is_equal(CrabCycle.State.WINDUP)


func test_flipped_lasts_longer_than_a_stagger_or_an_opening() -> void:
	assert_float(_cycle.flip_seconds).is_greater(_cycle.stagger_seconds)
	assert_float(_cycle.flip_seconds).is_greater(_cycle.opening_seconds)


# Moves the crab on to its opening after its first attack.
func _open() -> void:
	_cycle.engage()
	_cycle.tick(_cycle.windup_seconds + _cycle.attack_seconds)
