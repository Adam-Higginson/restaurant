extends GameTestSuite
## Tests for how a bubble in the world sizes and fades with distance, and
## that it shows the words it's given.


func test_up_close_it_keeps_the_same_size_on_screen() -> void:
	assert_float(SpeechBubble3D.scale_at(SpeechBubble3D.NEAR / 2.0)).is_equal_approx(0.5, 0.001)
	assert_float(SpeechBubble3D.scale_at(SpeechBubble3D.NEAR)).is_equal_approx(1.0, 0.001)


func test_further_away_it_shrinks_on_screen_more_gently() -> void:
	var far: float = SpeechBubble3D.NEAR * 4.0

	# Twice its true size at four times the distance: half as big on screen,
	# not a quarter.
	assert_float(SpeechBubble3D.scale_at(far)).is_equal_approx(2.0, 0.001)


func test_it_fades_out_far_away() -> void:
	assert_float(SpeechBubble3D.fade_at(SpeechBubble3D.FADE_START - 1.0)).is_equal(1.0)
	assert_float(SpeechBubble3D.fade_at(SpeechBubble3D.FADE_END + 1.0)).is_equal(0.0)


func test_it_shows_the_words_its_given() -> void:
	var bubble: SpeechBubble3D = auto_free(SpeechBubble3D.new())
	var anchor: Node3D = auto_free(Node3D.new())

	bubble.say("Hm.", anchor, SpeechBubble.Style.THOUGHT)

	assert_str(bubble.text).is_equal("Hm.")


func test_it_isnt_smoothed_between_physics_ticks() -> void:
	var bubble: SpeechBubble3D = auto_free(SpeechBubble3D.new())

	# It's placed every frame; smoothing it between physics ticks too makes it shake.
	assert_int(bubble.physics_interpolation_mode).is_equal(Node.PHYSICS_INTERPOLATION_MODE_OFF)


func test_it_is_placed_after_the_camera_has_moved() -> void:
	var rig: CameraRig = (load("res://scenes/prototype/player.tscn") as PackedScene) \
			.instantiate().get_node("CameraRig") as CameraRig
	auto_free(rig.owner)
	var bubble: SpeechBubble3D = auto_free(SpeechBubble3D.new())

	assert_int(bubble.process_priority).is_greater(rig.process_priority)
