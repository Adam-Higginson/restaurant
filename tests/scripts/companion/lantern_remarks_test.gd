extends GameTestSuite
## Tests for what the lantern says when things happen (his lines are in
## data/dialogue/moments.dlg): he never repeats himself twice running, says
## a few lines in turn, and speaks up when you land
## a fish and when you stop the ship.


func test_he_never_says_the_same_thing_twice_running() -> void:
	var picker: RemarkPicker = RemarkPicker.new()
	var places: Dictionary[StringName, Vector3] = {&"lantern": Vector3.ZERO}
	var remarks: Array[Remark] = DialogueLibrary.remarks(LanternSpirit.MOMENTS)
	var last: Remark = null
	for i: int in 60:
		var picked: Remark = picker.pick(remarks, places, DialogueState.new(), i, &"morning")
		assert_object(picked).is_not_same(last)
		picker.said(picked, i)
		last = picked


func test_a_moment_with_one_thing_to_say_says_it_every_time() -> void:
	var picker: RemarkPicker = RemarkPicker.new()
	var places: Dictionary[StringName, Vector3] = {&"lantern": Vector3.ZERO}
	var tree: DialogueTree = DialogueScript.parse(
			"~ only_one [on landed]
lantern: Land!
~ other [on caught]
lantern: Fish!",
			&"test", true)
	var remarks: Array[Remark] = Remark.all_in(tree)
	for i: int in 3:
		var picked: Remark = picker.pick(remarks, places, DialogueState.new(), i, &"landed")
		assert_str(String(picked.section)).is_equal("only_one")
		picker.said(picked, i)


func test_the_lines_of_a_remark_come_one_after_another() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = lantern_at_shoulder(rig[1])
	var voice: Speaker = rig[1].get_node("LanternSpirit/Voice") as Speaker
	voice.base_seconds = 0.1
	voice.seconds_per_letter = 0.0
	voice.pause_seconds = 0.0
	voice.bubble.fade_seconds = 0.02
	var heard: PackedStringArray = PackedStringArray()
	voice.said.connect(func(line: String) -> void: heard.append(line))
	await physics_ticks(runner, 2)

	# He never says the same thing twice running, so two welcomes back are
	# both of them, one after the other: one is a single line, one is two.
	spirit.remark(&"returned")
	spirit.remark(&"returned")
	await physics_ticks(runner, 60)

	var short: PackedStringArray = _lines_of(&"returned_1")
	var long: PackedStringArray = _lines_of(&"returned_2")
	assert_int(long.size()).is_equal(2)
	assert_array(Array(heard)).contains_exactly_in_any_order(Array(short + long))
	assert_int(heard.find(long[1])).is_equal(heard.find(long[0]) + 1)
	assert_str(spirit.saying()).is_empty()


func test_he_cheers_when_you_land_a_fish() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(4.6, 5.35, 4.3))
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spot: FishingSpot = rig[0].get_node("Visuals/UpperDeck/Dressing/FishingSpot") as FishingSpot
	spot.line.min_wait = 0.1
	spot.line.max_wait = 0.1
	var spirit: LanternSpirit = lantern_at_shoulder(rig[1])
	await physics_ticks(runner, 5)
	await walk(runner, "move_right", 2)

	await press(runner, "interact")
	await physics_ticks(runner, 10)
	await press(runner, "interact")

	assert_bool(spirit.saying() in moment_lines(&"caught")).is_true()


func test_he_is_glad_when_you_stop_the_ship() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 6.25, -11.9))
	var ship: Ship = rig[0] as Ship
	ship.set_sail()
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var spirit: LanternSpirit = lantern_at_shoulder(rig[1])
	await physics_ticks(runner, 5)

	await walk(runner, "move_down", 2)
	await physics_ticks(runner, 3)
	await press(runner, "interact")

	assert_bool(spirit.saying() in moment_lines(&"hove_to")).is_true()


func _lines_of(section: StringName) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var tree: DialogueTree = DialogueLibrary.find(LanternSpirit.MOMENTS)
	for step: DialogueStep in Remark.steps_of(tree, section):
		if step.kind == DialogueStep.Kind.LINE:
			lines.append(step.text)
	return lines
