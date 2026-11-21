extends GameTestSuite
## Tests for Flicker: firelight that wavers within its range and keeps moving.


func test_stays_within_its_range() -> void:
	var fire: Flicker = _new_flicker(2.0, 0.3)
	for step: int in 400:
		var energy: float = fire.energy_at(step * 0.031)
		assert_float(energy).is_between(2.0 * 0.7 - 0.0001, 2.0 * 1.3 + 0.0001)


func test_wavers_rather_than_holding_still() -> void:
	var fire: Flicker = _new_flicker(2.0, 0.3)
	var lowest: float = INF
	var highest: float = -INF
	for step: int in 200:
		var energy: float = fire.energy_at(step * 0.05)
		lowest = minf(lowest, energy)
		highest = maxf(highest, energy)
	assert_float(highest - lowest).is_greater(0.2)


func test_holds_steady_with_no_waver() -> void:
	var fire: Flicker = _new_flicker(1.5, 0.0)
	assert_float(fire.energy_at(3.7)).is_equal_approx(1.5, 0.0001)


func test_changes_its_light_as_time_passes() -> void:
	var fire: Flicker = _new_flicker(2.0, 0.3)
	var runner: GdUnitSceneRunner = scene_runner(fire)
	var first: float = fire.light_energy
	var changed: bool = false
	for frame: int in 10:
		await physics_ticks(runner, 3)
		changed = changed or not is_equal_approx(fire.light_energy, first)
	assert_bool(changed).is_true()


func _new_flicker(base: float, amount: float) -> Flicker:
	var fire: Flicker = Flicker.new()
	fire.base_energy = base
	fire.amount = amount
	auto_free(fire)
	return fire
