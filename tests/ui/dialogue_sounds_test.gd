extends GameTestSuite
## Tests for the sounds of a conversation: which letters blip, and the blip
## itself being a short sound made on the spot.


func test_the_blip_is_a_short_sound() -> void:
	var blip: AudioStreamWAV = DialogueSounds.make_blip()

	assert_int(blip.mix_rate).is_equal(DialogueSounds.MIX_RATE)
	assert_float(blip.get_length()).is_between(0.02, 0.1)
	# It fades to nothing, so it doesn't click at its end.
	assert_int(absi(blip.data.decode_s16(blip.data.size() - 2))).is_less(400)


func test_it_blips_on_every_other_letter_and_never_on_spaces() -> void:
	var sounds: DialogueSounds = DialogueSounds.new()
	add_child(sounds)
	auto_free(sounds)
	sounds.letters_per_blip = 2
	var blipped: Array[bool] = []

	for letter: String in ["H", "m", " ", "o", "k"]:
		blipped.append(sounds.on_letter(letter))

	assert_array(blipped).contains_exactly([true, false, false, true, false])


func test_each_speaker_has_their_own_pitch() -> void:
	var catalog: Catalog = Catalog.load_default()

	assert_float(catalog.find_person(&"heron").voice_pitch) \
			.is_less(catalog.find_person(&"lantern").voice_pitch)
