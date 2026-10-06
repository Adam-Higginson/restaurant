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


func test_half_stars_round_up() -> void:
	# (2 + 3) / 2 = 2.5
	assert_int(_quality(3, [2, 2])).is_equal(3)
	# (5/3 + 1) / 2 = 1.33
	assert_int(_quality(1, [2, 2, 1])).is_equal(2)


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
