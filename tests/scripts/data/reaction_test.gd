extends GameTestSuite
## Tests for Reaction's own rules: which element drives it, and result quality.


func test_reaction_without_elements_is_immediate() -> void:
	var reaction: Reaction = Reaction.new()
	assert_object(reaction.driving_element()).is_null()
	assert_bool(reaction.is_immediate()).is_true()


func test_first_element_drives_the_reaction() -> void:
	var fire: Element = Element.new()
	var cold: Element = Element.new()
	var reaction: Reaction = Reaction.new()
	reaction.elements = [fire, cold]
	assert_object(reaction.driving_element()).is_same(fire)
	assert_bool(reaction.is_immediate()).is_false()


func test_proper_step_lifts_normal_inputs() -> void:
	# (1 + 3) / 2 = 2
	assert_int(_quality(3, [1])).is_equal(2)


func test_the_inputs_round_to_the_nearest_star() -> void:
	# A half rounds up: 1.5 is ★★, then made well (2) keeps it.
	assert_int(_quality(2, [1, 2])).is_equal(2)
	# 1.33 rounds down to ★.
	assert_int(_quality(2, [1, 1, 2])).is_equal(1)


func test_made_at_its_best_adds_a_star_and_badly_takes_one() -> void:
	assert_int(_quality(3, [2, 2])).is_equal(3)
	assert_int(_quality(2, [2, 2])).is_equal(2)
	assert_int(_quality(1, [2, 2])).is_equal(1)


func test_stars_stay_between_one_and_three() -> void:
	assert_int(_quality(3, [3])).is_equal(3)
	assert_int(_quality(1, [1])).is_equal(1)


func test_whole_numbers_are_not_rounded_up() -> void:
	# Exact answers must not be nudged up by float error.
	assert_int(_quality(1, [1, 1])).is_equal(1)
	assert_int(_quality(3, [3, 3, 3])).is_equal(3)
	assert_int(_quality(1, [3, 3, 3])).is_equal(2)


func test_shortcut_pulls_quality_down() -> void:
	assert_int(_quality(1, [3])).is_equal(2)
	assert_int(_quality(1, [1])).is_equal(1)


func test_no_inputs_gives_the_reaction_quality() -> void:
	assert_int(_quality(2, [])).is_equal(2)


func _quality(reaction_quality: int, inputs: Array[int]) -> int:
	var reaction: Reaction = Reaction.new()
	reaction.quality = reaction_quality
	return reaction.result_quality(inputs)


func test_how_well_it_was_made_can_stand_in_for_the_method() -> void:
	var reaction: Reaction = Reaction.new()
	reaction.quality = 3
	var inputs: Array[int] = [2]

	# Made raggedly (1) rather than properly (3): a star down, not up.
	assert_int(reaction.result_quality(inputs, 1)).is_equal(1)
	assert_int(reaction.result_quality(inputs)).is_equal(3)
