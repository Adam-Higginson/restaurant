extends GameTestSuite
## Tests for the lantern's hum: the memory melody's notes and timing, a soft
## swell on each note, silence after, the recording it's rendered into, and
## that he hums after supper.


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


func test_the_hum_is_a_recording_of_the_melody() -> void:
	var recording: AudioStreamWAV = Hum.recording()

	assert_float(recording.get_length()).is_equal_approx(Hum.melody_seconds(), 0.001)
	for t: float in [0.1, 0.6, 1.5, 2.2]:
		var i: int = roundi(t * Hum.MIX_RATE)
		var expected: float = Hum.sample(i / Hum.MIX_RATE)
		assert_float(recording.data.decode_s16(i * 2) / 32767.0).is_equal_approx(expected, 0.001)


func test_every_lantern_shares_one_recording_and_never_a_generator() -> void:
	# A generator's playback keeps only a raw pointer to its generator, so
	# freeing a humming lantern could leave the audio thread stuck mixing.
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)
	var hum: Hum = rig[1].get_node("LanternSpirit/Hum") as Hum

	assert_object(hum.stream).is_same(Hum.recording())
	assert_bool(hum.stream is AudioStreamGenerator).is_false()


func test_a_quieter_lantern_turns_the_recording_down() -> void:
	var hum: Hum = auto_free(Hum.new())

	hum.loudness = 0.5

	assert_float(hum.volume_db).is_equal_approx(linear_to_db(0.5), 0.001)
