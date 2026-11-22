extends GameTestSuite
## Tests for Clang: the pan's ring is loud at the knock and dies away, and
## it rings when a parry lands and only then.

const PAN: Item = preload("res://data/items/frying_pan.tres")
const CLOSE: Vector3 = Vector3(0, 0, -1.3)


func test_it_is_loud_at_the_knock_and_quiet_by_the_end() -> void:
	assert_float(_loudest(0.0, 0.05)).is_greater(0.5)
	assert_float(_loudest(Clang.SECONDS - 0.05, Clang.SECONDS)).is_less(0.05)
	assert_float(_loudest(0.0, 0.05)).is_greater(_loudest(0.3, 0.35) * 2.0)


func test_it_is_silent_before_and_after() -> void:
	assert_float(Clang.sample(-0.1)).is_equal(0.0)
	assert_float(Clang.sample(Clang.SECONDS)).is_equal(0.0)
	assert_float(Clang.sample(Clang.SECONDS + 1.0)).is_equal(0.0)


func test_it_never_clips() -> void:
	assert_float(_loudest(0.0, Clang.SECONDS)).is_less_equal(1.0)


func test_the_sound_is_as_long_as_it_says() -> void:
	var clang: AudioStreamWAV = Clang.make()

	assert_float(clang.get_length()).is_equal_approx(Clang.SECONDS, 0.01)
	assert_int(clang.mix_rate).is_equal(Clang.MIX_RATE)


func test_a_parry_that_lands_rings_the_pan() -> void:
	var player: Player3D = new_player_3d_on_floor()
	new_fog_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.toolbar.add(ItemInstance.new(PAN))
	# The crab's first hit lands at 0.8 s: raise the pan at 0.67 s.
	await physics_ticks(runner, 40)

	duellist_of(player).raise_pan()
	assert_int(_clang(player).times_rung).is_equal(0)
	await physics_ticks(runner, 16)

	assert_int(_clang(player).times_rung).is_equal(1)
	assert_object(_clang(player).stream).is_not_null()


func test_raising_the_pan_at_nothing_makes_no_sound() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.toolbar.add(ItemInstance.new(PAN))
	await physics_ticks(runner, 2)

	duellist_of(player).raise_pan()
	await physics_ticks(runner, 30)

	assert_int(_clang(player).times_rung).is_equal(0)


func test_a_hit_that_lands_makes_no_clang() -> void:
	var player: Player3D = new_player_3d_on_floor()
	new_fog_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	await physics_ticks(runner, 56)

	assert_int(duellist_of(player).hearts.halves).is_equal(5)
	assert_int(_clang(player).times_rung).is_equal(0)


func _clang(player: Player3D) -> Clang:
	return player.get_node("Clang") as Clang


# The loudest the clang gets between [param from] and [param to] seconds.
func _loudest(from: float, to: float) -> float:
	var loudest: float = 0.0
	var t: float = from
	while t < to:
		loudest = maxf(loudest, absf(Clang.sample(t)))
		t += 1.0 / Clang.MIX_RATE
	return loudest
