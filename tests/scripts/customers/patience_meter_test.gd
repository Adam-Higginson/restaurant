extends GameTestSuite
## Tests for PatienceMeter: how long a customer keeps waiting.


func test_starts_full() -> void:
	var meter: PatienceMeter = PatienceMeter.new(120.0)
	assert_float(meter.fraction()).is_equal(1.0)
	assert_float(meter.seconds_left()).is_equal(120.0)
	assert_bool(meter.has_run_out()).is_false()


func test_drain_takes_seconds_off() -> void:
	var meter: PatienceMeter = PatienceMeter.new(120.0)
	meter.drain(30.0)
	assert_float(meter.seconds_left()).is_equal(90.0)
	assert_float(meter.fraction()).is_equal(0.75)


func test_drains_add_up() -> void:
	var meter: PatienceMeter = PatienceMeter.new(10.0)
	for i: int in 4:
		meter.drain(1.0)
	assert_float(meter.seconds_left()).is_equal(6.0)


func test_never_goes_below_zero() -> void:
	var meter: PatienceMeter = PatienceMeter.new(10.0)
	meter.drain(25.0)
	assert_float(meter.seconds_left()).is_equal(0.0)
	assert_float(meter.fraction()).is_equal(0.0)
	assert_bool(meter.has_run_out()).is_true()


func test_ran_out_fires_when_it_reaches_zero() -> void:
	var meter: PatienceMeter = PatienceMeter.new(10.0)
	var counter: Dictionary[String, int] = {"fired": 0}
	meter.ran_out.connect(func() -> void: counter["fired"] += 1)
	meter.drain(9.0)
	assert_int(counter["fired"]).is_equal(0)
	meter.drain(1.0)
	assert_int(counter["fired"]).is_equal(1)


func test_ran_out_fires_only_once() -> void:
	var meter: PatienceMeter = PatienceMeter.new(10.0)
	var counter: Dictionary[String, int] = {"fired": 0}
	meter.ran_out.connect(func() -> void: counter["fired"] += 1)
	meter.drain(15.0)
	meter.drain(5.0)
	meter.drain(5.0)
	assert_int(counter["fired"]).is_equal(1)


func test_zero_patience_counts_as_run_out() -> void:
	var meter: PatienceMeter = PatienceMeter.new(0.0)
	assert_float(meter.fraction()).is_equal(0.0)
	assert_bool(meter.has_run_out()).is_true()
