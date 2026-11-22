extends GameTestSuite
## Tests for a sound whose recording may not be there: with the file it
## plays (round and round, if it's a loop, but only while it's allowed to
## run), and without it stays silent and nothing goes wrong.

const RECORDING: String = "res://assets/audio/combat/cloth1.ogg"
const MISSING: String = "res://assets/third_party/audio/not_recorded_yet.ogg"


func test_with_its_file_there_it_has_a_recording() -> void:
	var sound: OptionalSound = _new_sound(RECORDING, false)

	assert_bool(sound.has_recording()).is_true()
	assert_bool(sound.playing).is_false()


func test_with_no_file_it_stays_silent_and_nothing_goes_wrong() -> void:
	var sound: OptionalSound = _new_sound(MISSING, true)

	assert_bool(sound.has_recording()).is_false()
	assert_bool(sound.playing).is_false()


func test_a_loop_plays_round_and_round_as_soon_as_it_can() -> void:
	var sound: OptionalSound = _new_sound(RECORDING, true)

	assert_bool(sound.playing).is_true()
	assert_bool((sound.stream as AudioStreamOggVorbis).loop).is_true()


func test_a_loop_holds_its_breath_while_it_cant_run() -> void:
	var sound: OptionalSound = _new_sound(RECORDING, true)

	sound.process_mode = Node.PROCESS_MODE_DISABLED
	assert_bool(sound.stream_paused).is_true()

	sound.process_mode = Node.PROCESS_MODE_INHERIT
	assert_bool(sound.stream_paused).is_false()
	assert_bool(sound.playing).is_true()


func test_a_loop_that_starts_out_unable_to_run_waits() -> void:
	var holder: Node = Node.new()
	auto_free(holder)
	holder.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(holder)
	var sound: OptionalSound = OptionalSound.new()
	sound.recording = RECORDING
	sound.loop = true
	sound.volume_db = -80.0
	holder.add_child(sound)

	assert_bool(sound.playing).is_false()

	holder.process_mode = Node.PROCESS_MODE_INHERIT
	assert_bool(sound.playing).is_true()


func _new_sound(path: String, loop: bool) -> OptionalSound:
	var sound: OptionalSound = OptionalSound.new()
	auto_free(sound)
	sound.recording = path
	sound.loop = loop
	sound.volume_db = -80.0
	add_child(sound)
	return sound
