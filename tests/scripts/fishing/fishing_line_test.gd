extends GameTestSuite
## Tests for a fishing line's patience: casting, waiting in still water, a
## bite, striking in time, and the fish getting away.


func test_a_cast_line_waits_for_a_bite() -> void:
	var line: FishingLine = _line()

	line.cast()

	assert_int(line.state).is_equal(FishingLine.State.WAITING)


func test_a_fish_bites_after_a_wait_in_still_water() -> void:
	var line: FishingLine = _line()
	var bites: Array[int] = [0]
	line.bitten.connect(func() -> void: bites[0] += 1)
	line.cast()

	line.step(0.9, true)
	assert_int(line.state).is_equal(FishingLine.State.WAITING)
	line.step(0.2, true)

	assert_int(line.state).is_equal(FishingLine.State.BITING)
	assert_int(bites[0]).is_equal(1)


func test_nothing_bites_while_the_ship_is_under_way() -> void:
	var line: FishingLine = _line()
	line.cast()

	for i: int in 100:
		line.step(0.5, false)

	assert_int(line.state).is_equal(FishingLine.State.WAITING)


func test_striking_while_it_bites_lands_the_fish() -> void:
	var line: FishingLine = _line()
	line.cast()
	line.step(1.1, true)

	assert_bool(line.reel()).is_true()
	assert_int(line.state).is_equal(FishingLine.State.REELED_IN)


func test_reeling_in_too_early_catches_nothing() -> void:
	var line: FishingLine = _line()
	line.cast()
	line.step(0.5, true)

	assert_bool(line.reel()).is_false()


func test_too_slow_and_it_gets_away_then_another_may_come() -> void:
	var line: FishingLine = _line()
	var escapes: Array[int] = [0]
	line.got_away.connect(func() -> void: escapes[0] += 1)
	line.cast()
	line.step(1.1, true)

	line.step(0.6, true)

	assert_int(escapes[0]).is_equal(1)
	assert_int(line.state).is_equal(FishingLine.State.WAITING)


# A line with a one-second wait for a bite and half a second to strike.
func _line() -> FishingLine:
	var line: FishingLine = FishingLine.new(7)
	line.min_wait = 1.0
	line.max_wait = 1.0
	line.bite_window = 0.5
	return line
