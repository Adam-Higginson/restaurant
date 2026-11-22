extends GameTestSuite
## Tests for the ship's sound spots: silent without recordings (as on CI),
## and waits between sounds that stay in range.


func test_it_stays_silent_without_its_recordings() -> void:
	var spot: SoundSpot = SoundSpot.new()
	spot.recordings = ["res://assets/third_party/audio/ship/not_here.ogg"]
	add_child(spot)
	auto_free(spot)

	spot._process(60.0)

	assert_bool(spot.is_audible()).is_false()
	assert_bool(spot.playing).is_false()


func test_gaps_between_sounds_stay_in_range() -> void:
	var spot: SoundSpot = SoundSpot.new()
	spot.min_gap = 3.0
	spot.max_gap = 7.0
	auto_free(spot)

	for i: int in 50:
		assert_float(spot.next_gap()).is_between(3.0, 7.0)


func test_it_plays_on_the_ambience_bus() -> void:
	var spot: SoundSpot = SoundSpot.new()
	add_child(spot)
	auto_free(spot)

	assert_str(String(spot.bus)).is_equal(String(Ambience.BUS))
