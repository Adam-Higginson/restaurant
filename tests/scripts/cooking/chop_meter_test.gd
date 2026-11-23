extends GameTestSuite
## Tests for the chop meter (#152): the marker sweeps and bounces, a cut is
## graded by where it is, and a wider sweet spot is more forgiving.

const KNIFE: HandTool = preload("res://data/tools/chefs_knife.tres")


func test_the_marker_starts_at_the_left_and_sweeps_right() -> void:
	var meter: ChopMeter = ChopMeter.new(0.1, 0.3, 1.0)

	meter.tick(0.25)

	assert_float(meter.position).is_equal_approx(0.25, 0.0001)
	assert_float(meter.direction()).is_equal(1.0)


func test_the_marker_bounces_off_the_right_end() -> void:
	var meter: ChopMeter = ChopMeter.new(0.1, 0.3, 1.0)

	meter.tick(1.25)

	assert_float(meter.position).is_equal_approx(0.75, 0.0001)
	assert_float(meter.direction()).is_equal(-1.0)


func test_the_marker_bounces_back_off_the_left_end() -> void:
	var meter: ChopMeter = ChopMeter.new(0.1, 0.3, 1.0)

	meter.tick(2.25)

	assert_float(meter.position).is_equal_approx(0.25, 0.0001)
	assert_float(meter.direction()).is_equal(1.0)


func test_a_cut_in_the_middle_is_perfect() -> void:
	var meter: ChopMeter = ChopMeter.new(0.1, 0.3, 1.0)
	meter.position = 0.52

	assert_int(meter.grade()).is_equal(ChopMeter.Grade.PERFECT)


func test_a_cut_just_off_the_middle_is_good() -> void:
	var meter: ChopMeter = ChopMeter.new(0.1, 0.3, 1.0)
	meter.position = 0.62

	assert_int(meter.grade()).is_equal(ChopMeter.Grade.GOOD)


func test_a_cut_far_from_the_middle_is_ragged() -> void:
	var meter: ChopMeter = ChopMeter.new(0.1, 0.3, 1.0)
	meter.position = 0.9

	assert_int(meter.grade()).is_equal(ChopMeter.Grade.RAGGED)


func test_a_wider_sweet_spot_is_more_forgiving() -> void:
	var narrow: ChopMeter = ChopMeter.new(0.1, 0.3, 1.0)
	var wide: ChopMeter = ChopMeter.new(0.3, 0.6, 1.0)
	narrow.position = 0.62
	wide.position = 0.62

	assert_int(narrow.grade()).is_equal(ChopMeter.Grade.GOOD)
	assert_int(wide.grade()).is_equal(ChopMeter.Grade.PERFECT)


func test_good_is_never_narrower_than_perfect() -> void:
	var meter: ChopMeter = ChopMeter.new(0.4, 0.2, 1.0)

	assert_float(meter.good_width).is_equal(0.4)


func test_the_meter_takes_its_zones_from_the_knife() -> void:
	var meter: ChopMeter = ChopMeter.new(0.5, 0.9, 1.0)

	meter.fit_to(KNIFE)

	assert_float(meter.perfect_width).is_equal(KNIFE.sweet_spot)
	assert_float(meter.good_width).is_equal(KNIFE.good_spot)


func test_reset_puts_the_marker_back_at_the_left_moving_right() -> void:
	var meter: ChopMeter = ChopMeter.new(0.1, 0.3, 1.0)
	meter.tick(1.5)

	meter.reset()

	assert_float(meter.position).is_equal(0.0)
	assert_float(meter.direction()).is_equal(1.0)
