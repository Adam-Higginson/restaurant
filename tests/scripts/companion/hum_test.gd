extends GameTestSuite
## Tests for the lantern's hum: the memory melody's notes and timing, a soft
## swell on each note, silence after, and that he hums when a memory comes
## back and after supper.


func before_test() -> void:
	Game.memories.clear()


func after_test() -> void:
	Game.memories.clear()


func test_the_notes_are_in_tune() -> void:
	assert_float(Hum.pitch(69)).is_equal_approx(440.0, 0.001)
	assert_float(Hum.pitch(81)).is_equal_approx(880.0, 0.001)
	assert_float(Hum.pitch(72)).is_equal_approx(523.25, 0.01)


func test_the_melody_plays_its_notes_in_order() -> void:
	assert_int(int(Hum.note_at(0.1).x)).is_equal(0)
	assert_int(int(Hum.note_at(0.7).x)).is_equal(1)
	assert_int(int(Hum.note_at(1.5).x)).is_equal(2)
	assert_int(int(Hum.note_at(Hum.melody_seconds() + 0.1).x)).is_equal(-1)


func test_each_note_swells_in_and_the_end_is_silent() -> void:
	# The very start of a note is near silence; a moment later it's sounding.
	var loudest_early: float = 0.0
	var loudest_later: float = 0.0
	for i: int in 40:
		loudest_early = maxf(loudest_early, absf(Hum.sample(i * 0.00005)))
		loudest_later = maxf(loudest_later, absf(Hum.sample(0.2 + i * 0.00005)))
	assert_float(loudest_early).is_less(0.05)
	assert_float(loudest_later).is_greater(0.3)
	assert_float(Hum.sample(Hum.melody_seconds() + 0.5)).is_equal(0.0)


func test_he_hums_when_a_memory_comes_back() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = rig[1].get_node("LanternSpirit") as LanternSpirit
	await physics_ticks(runner, 2)
	assert_bool(spirit.is_humming()).is_false()

	Game.memories.notice(Catalog.load_default().find_item(&"garden_salad"))
	await physics_ticks(runner, 2)

	assert_bool(spirit.is_humming()).is_true()
	await physics_ticks(runner, int(Hum.melody_seconds() * 60.0) + 10)
	assert_bool(spirit.is_humming()).is_false()
