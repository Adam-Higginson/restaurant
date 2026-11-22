extends GameTestSuite
## Tests for reading remarks from a file of them: each section's header tags,
## guard and speakers, with sensible defaults.

const REMARKS: String = """
? night
~ stove [weight 3] [cooldown 30] [priority 2]
heron: Hm.
lantern: Warm!
heron: Hm. [thought]

~ hum
lantern: La la. [sound]

~ caught_1 [on caught]
lantern: A fish!
"""


func test_a_remark_reads_its_header() -> void:
	var stove: Remark = _remarks()[0]

	assert_str(String(stove.section)).is_equal("stove")
	assert_int(stove.weight).is_equal(3)
	assert_float(stove.cooldown).is_equal(30.0)
	assert_int(stove.priority).is_equal(2)
	assert_str(stove.guard).is_equal("night")
	assert_str(String(stove.moment)).is_empty()
	assert_str(stove.key).is_equal("t/stove")


func test_its_speakers_are_everyone_in_it_once_each_in_order() -> void:
	var stove: Remark = _remarks()[0]

	assert_array(stove.speakers).is_equal([&"heron", &"lantern"])


func test_a_plain_remark_has_the_defaults() -> void:
	var hum: Remark = _remarks()[1]

	assert_int(hum.weight).is_equal(1)
	assert_float(hum.cooldown).is_equal(Remark.DEFAULT_COOLDOWN)
	assert_int(hum.priority).is_equal(0)
	assert_str(hum.guard).is_empty()


func test_a_reaction_can_be_said_again_straight_away() -> void:
	var caught: Remark = _remarks()[2]

	assert_str(String(caught.moment)).is_equal("caught")
	assert_float(caught.cooldown).is_equal(0.0)


func test_a_sections_steps_stop_where_the_next_section_starts() -> void:
	var tree: DialogueTree = DialogueScript.parse(REMARKS, &"t", true)

	var texts: PackedStringArray = PackedStringArray()
	for step: DialogueStep in Remark.steps_of(tree, &"stove"):
		if step.kind == DialogueStep.Kind.LINE:
			texts.append(step.text)

	assert_array(Array(texts)).is_equal(["Hm.", "Warm!", "Hm."])


func _remarks() -> Array[Remark]:
	var tree: DialogueTree = DialogueScript.parse(REMARKS, &"t", true)
	assert_array(tree.errors).is_empty()
	return Remark.all_in(tree)
