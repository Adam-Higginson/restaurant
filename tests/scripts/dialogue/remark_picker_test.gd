extends GameTestSuite
## Tests for choosing what to say in passing: who's there and how near, the
## guard, cooldowns, not repeating the last one, priority, and weight.

const REMARKS: String = """
~ solo
heron: Hm.

? night
~ at_night
heron: Dark.

~ pair
heron: Lamp.
lantern: Captain!

~ urgent [priority 1]
heron: Fire!

~ heavy [weight 9]
heron: Heavy.

~ caught_1 [on caught]
lantern: A fish!

~ caught_2 [on caught]
lantern: Another fish!
"""

var _state: DialogueState


func before_test() -> void:
	_state = DialogueState.new()


func test_everyone_in_it_must_be_there() -> void:
	var picker: RemarkPicker = RemarkPicker.new()
	var heron_only: Dictionary[StringName, Vector3] = {&"heron": Vector3.ZERO}
	var both: Dictionary[StringName, Vector3] = {&"heron": Vector3.ZERO, &"lantern": Vector3.ONE}

	assert_bool(picker.can_say(_find(&"pair"), heron_only, _state, 0.0)).is_false()
	assert_bool(picker.can_say(_find(&"pair"), both, _state, 0.0)).is_true()


func test_everyone_in_it_must_be_near_each_other() -> void:
	var picker: RemarkPicker = RemarkPicker.new()
	picker.near = 5.0
	var apart: Dictionary[StringName, Vector3] = {
		&"heron": Vector3.ZERO, &"lantern": Vector3(6, 0, 0)}

	assert_bool(picker.can_say(_find(&"pair"), apart, _state, 0.0)).is_false()


func test_its_guard_must_hold() -> void:
	var picker: RemarkPicker = RemarkPicker.new()
	var here: Dictionary[StringName, Vector3] = {&"heron": Vector3.ZERO}

	assert_bool(picker.can_say(_find(&"at_night"), here, _state, 0.0)).is_false()
	_state.set_flag(&"night")
	assert_bool(picker.can_say(_find(&"at_night"), here, _state, 0.0)).is_true()


func test_it_waits_out_its_cooldown_and_isnt_said_twice_running() -> void:
	var picker: RemarkPicker = RemarkPicker.new()
	var here: Dictionary[StringName, Vector3] = {&"heron": Vector3.ZERO}
	var solo: Remark = _find(&"solo")

	picker.said(solo, 10.0)

	assert_bool(picker.can_say(solo, here, _state, 10.0 + solo.cooldown - 1.0)).is_false()
	# Off cooldown, but still the last one said.
	assert_bool(picker.can_say(solo, here, _state, 10.0 + solo.cooldown)).is_false()
	picker.said(_find(&"heavy"), 20.0)
	assert_bool(picker.can_say(solo, here, _state, 10.0 + solo.cooldown)).is_true()


func test_the_highest_priority_that_fits_comes_first() -> void:
	var picker: RemarkPicker = RemarkPicker.new()
	var here: Dictionary[StringName, Vector3] = {&"heron": Vector3.ZERO}

	for i: int in 10:
		assert_str(String(picker.pick(_all(), here, _state, 0.0).section)).is_equal("urgent")


func test_a_heavier_remark_is_picked_more_often() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 94
	var picker: RemarkPicker = RemarkPicker.new(rng)
	var here: Dictionary[StringName, Vector3] = {&"heron": Vector3.ZERO}
	var choices: Array[Remark] = [_find(&"solo"), _find(&"heavy")]
	var heavy: int = 0

	for i: int in 200:
		if picker.pick(choices, here, _state, 0.0).section == &"heavy":
			heavy += 1

	# Nine times as likely: about 180 of 200.
	assert_int(heavy).is_between(160, 196)


func test_the_same_seed_picks_the_same_way() -> void:
	var here: Dictionary[StringName, Vector3] = {&"heron": Vector3.ZERO}
	var choices: Array[Remark] = [_find(&"solo"), _find(&"heavy")]
	var picks: Array[PackedStringArray] = []
	for run: int in 2:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 7
		var picker: RemarkPicker = RemarkPicker.new(rng)
		var sections: PackedStringArray = PackedStringArray()
		for i: int in 20:
			sections.append(String(picker.pick(choices, here, _state, 0.0).section))
		picks.append(sections)

	assert_array(Array(picks[0])).is_equal(Array(picks[1]))


func test_chatter_never_picks_a_reaction_and_a_reaction_only_its_own() -> void:
	var picker: RemarkPicker = RemarkPicker.new()
	var lantern: Dictionary[StringName, Vector3] = {&"lantern": Vector3.ZERO}

	assert_object(picker.pick(_all(), lantern, _state, 0.0)).is_null()
	var caught: Remark = picker.pick(_all(), lantern, _state, 0.0, &"caught")
	assert_str(String(caught.moment)).is_equal("caught")


func test_a_reaction_repeats_rather_than_say_nothing() -> void:
	var picker: RemarkPicker = RemarkPicker.new()
	var lantern: Dictionary[StringName, Vector3] = {&"lantern": Vector3.ZERO}
	var only_one: Array[Remark] = [_find(&"caught_1")]

	picker.said(only_one[0], 0.0)

	assert_object(picker.pick(only_one, lantern, _state, 1.0, &"caught")).is_same(only_one[0])


func test_nothing_fits_so_nothing_is_picked() -> void:
	var picker: RemarkPicker = RemarkPicker.new()
	var nobody: Dictionary[StringName, Vector3] = {}

	assert_object(picker.pick(_all(), nobody, _state, 0.0)).is_null()


func _all() -> Array[Remark]:
	var tree: DialogueTree = DialogueScript.parse(REMARKS, &"t", true)
	assert_array(tree.errors).is_empty()
	return Remark.all_in(tree)


func _find(section: StringName) -> Remark:
	for remark: Remark in _all():
		if remark.section == section:
			return remark
	return null
