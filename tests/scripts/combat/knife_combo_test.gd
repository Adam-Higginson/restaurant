extends GameTestSuite
## Tests for KnifeCombo: which cut the knife makes from how Use tool is
## pressed. Time is moved on by hand with tick(), so every change is exact.

var _combo: KnifeCombo
var _started: Array[StringName] = []


func before_test() -> void:
	_combo = KnifeCombo.new()
	_combo.chain = [_cut(&"chop", 0.25), _cut(&"slice", 0.25), _cut(&"cleave", 0.35)]
	_combo.fillet = _cut(&"fillet", 0.4)
	_combo.weak_spin = _cut(&"weak_spin", 0.5)
	_started = []
	_combo.cut_started.connect(func(cut: KnifeCut) -> void: _started.append(cut.id))


func test_taps_chain_chop_slice_and_cleave() -> void:
	for i: int in 3:
		_tap()
		_combo.tick(0.4)

	assert_array(_started).contains_exactly([&"chop", &"slice", &"cleave"])


func test_after_the_last_cut_the_chain_starts_again() -> void:
	for i: int in 4:
		_tap()
		_combo.tick(0.4)

	assert_array(_started).contains_exactly([&"chop", &"slice", &"cleave", &"chop"])


func test_a_pause_resets_the_chain() -> void:
	_tap()
	_combo.tick(0.25 + _combo.chain_window_seconds + 0.01)
	_tap()

	assert_array(_started).contains_exactly([&"chop", &"chop"])


func test_a_tap_inside_the_window_carries_on() -> void:
	_tap()
	_combo.tick(0.25 + _combo.chain_window_seconds - 0.05)
	_tap()

	assert_array(_started).contains_exactly([&"chop", &"slice"])


func test_a_tap_mid_cut_waits_for_it_to_end() -> void:
	_tap()
	_combo.tick(0.1)
	assert_bool(_combo.press()).is_false()
	_combo.release()
	assert_array(_started).contains_exactly([&"chop"])

	_combo.tick(0.16)

	assert_array(_started).contains_exactly([&"chop", &"slice"])
	assert_object(_combo.current).is_not_null()


func test_a_cut_lasts_its_seconds() -> void:
	_tap()
	_combo.tick(0.24)
	assert_bool(_combo.is_cutting()).is_true()

	_combo.tick(0.02)

	assert_bool(_combo.is_cutting()).is_false()


func test_holding_charges_after_the_delay() -> void:
	var charges: Array[int] = [0]
	_combo.charge_started.connect(func() -> void: charges[0] += 1)
	_combo.press()
	_combo.tick(_combo.charge_delay_seconds - 0.01)
	assert_bool(_combo.is_charging()).is_false()

	_combo.tick(0.02)

	assert_bool(_combo.is_charging()).is_true()
	assert_int(charges[0]).is_equal(1)


func test_a_full_charge_released_fillets() -> void:
	_combo.press()
	_combo.tick(_combo.charge_full_seconds + 0.01)
	assert_bool(_combo.is_charged()).is_true()

	var spin: KnifeCut = _combo.release()

	assert_str(spin.id).is_equal("fillet")
	assert_array(_started).contains_exactly([&"chop", &"fillet"])
	assert_bool(_combo.is_charging()).is_false()


func test_an_early_release_gives_the_weak_spin() -> void:
	_combo.press()
	_combo.tick(_combo.charge_delay_seconds + 0.1)
	assert_bool(_combo.is_charged()).is_false()

	var spin: KnifeCut = _combo.release()

	assert_str(spin.id).is_equal("weak_spin")


func test_a_tap_released_before_charging_spins_nothing() -> void:
	_combo.press()
	_combo.tick(0.1)

	assert_object(_combo.release()).is_null()
	_combo.tick(1.0)
	assert_bool(_combo.is_charging()).is_false()
	assert_array(_started).contains_exactly([&"chop"])


func test_the_charge_fills_from_zero_to_one() -> void:
	_combo.press()
	_combo.tick(_combo.charge_delay_seconds + 0.01)
	assert_float(_combo.charge()).is_less(0.1)

	_combo.tick(_combo.charge_full_seconds)

	assert_float(_combo.charge()).is_equal(1.0)


func test_a_cancelled_charge_spins_nothing() -> void:
	var cancels: Array[int] = [0]
	_combo.charge_cancelled.connect(func() -> void: cancels[0] += 1)
	_combo.press()
	_combo.tick(_combo.charge_full_seconds + 0.01)

	_combo.cancel_charge()

	assert_int(cancels[0]).is_equal(1)
	assert_object(_combo.release()).is_null()
	assert_array(_started).contains_exactly([&"chop"])


func test_after_a_spin_the_chain_starts_from_the_chop() -> void:
	_tap()
	_combo.tick(0.3)
	_combo.press()
	_combo.tick(1.2)
	_combo.release()
	_combo.tick(0.5)

	_tap()

	assert_array(_started).contains_exactly([&"chop", &"slice", &"fillet", &"chop"])


func test_reset_forgets_the_chain() -> void:
	_tap()
	_combo.tick(0.3)

	_combo.reset()
	_tap()

	assert_array(_started).contains_exactly([&"chop", &"chop"])


func _tap() -> void:
	_combo.press()
	_combo.release()


static func _cut(id: StringName, seconds: float) -> KnifeCut:
	var cut: KnifeCut = KnifeCut.new()
	cut.id = id
	cut.seconds = seconds
	return cut
