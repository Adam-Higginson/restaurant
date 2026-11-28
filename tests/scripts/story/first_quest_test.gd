extends GameTestSuite
## Tests for the first quest's opening half (#158): the lantern home from the
## sea low and silent (his glass whole), his flame leaning toward the galley; the
## captain going up for a drink at the water butt and back to his fire; the
## water butt remembering you've fetched water; and the captain's hints,
## which never say "the rain".


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_low_he_is_dim_tired_and_silent_with_his_glass_whole() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)
	var spirit: LanternSpirit = player.get_node("LanternSpirit") as LanternSpirit
	Game.dialogue.set_flag(LanternSpirit.LOW_FLAG)
	await physics_ticks(runner, 5)

	assert_bool(spirit.is_low()).is_true()
	assert_int(spirit.everyday_expression()).is_equal(LanternFace.Look.TIRED)
	assert_bool(spirit.face().cracked).is_false()
	assert_float(spirit.warmth).is_equal(spirit.min_warmth)
	assert_bool(spirit.tell(&"caught", &"news_fish")).is_false()
	assert_bool(Game.dialogue.is_set(&"news_fish")).is_false()
	spirit.remark(&"caught")
	assert_str(spirit.saying()).is_empty()
	assert_bool((spirit.get_node("Voice") as Speaker).muted).is_true()


func test_low_his_flame_leans_toward_the_galley() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	var spirit: LanternSpirit = player.get_node("LanternSpirit") as LanternSpirit
	var hob: Node3D = ship.get_node("Galley/SoupHob") as Node3D
	assert_vector(spirit.face().lean).is_equal(Vector3.ZERO)

	Game.dialogue.set_flag(LanternSpirit.LOW_FLAG)
	await physics_ticks(runner, 3)

	var lean: Vector3 = spirit.face().lean
	assert_float(lean.length()).is_equal_approx(LanternSpirit.LOW_LEAN, 0.01)
	var toward: Vector3 = spirit.face().global_basis * lean
	var to_hob: Vector3 = hob.global_position - spirit.global_position
	toward.y = 0.0
	to_hob.y = 0.0
	assert_float(toward.normalized().dot(to_hob.normalized())).is_greater(0.95)


func test_fed_and_well_again_the_lean_goes() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	Game.dialogue.set_flag(LanternSpirit.LOW_FLAG)
	await physics_ticks(runner, 3)
	var spirit: LanternSpirit = player.get_node("LanternSpirit") as LanternSpirit
	assert_vector(spirit.face().lean).is_not_equal(Vector3.ZERO)

	Game.dialogue.set_flag(LanternSpirit.LOW_FLAG, 0)
	await physics_ticks(runner, 3)

	assert_bool(spirit.face().cracked).is_false()
	assert_vector(spirit.face().lean).is_equal(Vector3.ZERO)
	assert_bool((spirit.get_node("Voice") as Speaker).muted).is_false()


func test_the_captain_goes_up_to_the_helm() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(2, 1.05, 4))
	var ship: Ship = rig[0] as Ship
	var quest: FirstQuest = FirstQuest.new()
	ship.get_parent().add_child(quest)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 3)
	var heron: Crewmate = ship.get_node("Crew/Heron") as Crewmate
	var wheel: Node3D = ship.get_node("SternWatch/Marks/Wheel") as Node3D

	assert_bool(quest.go_to_helm()).is_true()
	assert_bool(quest.is_heading_to_helm).is_true()
	# Up the hatch ramp, along the deck and up the quarterdeck stairs.
	for i: int in 60 * 60:
		await physics_ticks(runner, 1)
		if quest.is_at_helm:
			break

	assert_bool(quest.is_at_helm).is_true()
	assert_bool(quest.is_heading_to_helm).is_false()
	assert_vector(heron.global_position).is_equal_approx(wheel.global_position,
			Vector3(0.02, 0.02, 0.02))


func test_every_so_often_he_goes_for_a_drink_and_back_to_the_wheel() -> void:
	Game.dialogue.set_flag(LanternSpirit.LOW_FLAG)
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(2, 1.05, 4))
	var ship: Ship = rig[0] as Ship
	var quest: FirstQuest = FirstQuest.new()
	quest.linger_seconds = 0.5
	quest.drink_every = 1.0
	ship.get_parent().add_child(quest)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 3)
	var heron: Crewmate = ship.get_node("Crew/Heron") as Crewmate
	var butt: Node3D = ship.get_node("Marks/WaterButt") as Node3D
	var wheel: Node3D = ship.get_node("SternWatch/Marks/Wheel") as Node3D
	var done: Array[int] = [0]
	quest.errand_done.connect(func() -> void: done[0] += 1)
	var said: Array[String] = []
	heron.head.said.connect(func(words: String) -> void: said.append(words))

	assert_bool(quest.go_to_helm()).is_true()
	var reached_butt: bool = false
	for i: int in 120 * 60:
		await physics_ticks(runner, 1)
		if heron.global_position.distance_to(butt.global_position) < 0.05:
			reached_butt = true
		if done[0] > 0:
			break

	# He said he was thirsty, went to the butt, drank, and came back up.
	assert_bool(said.size() > 0 and quest.thirsty_lines.has(said[0])).is_true()
	# After the drink he says how good the rain is (#207).
	assert_bool(said.size() > 1 and quest.drunk_lines.has(said[1])).is_true()
	assert_bool(reached_butt).is_true()
	assert_int(done[0]).is_equal(1)
	assert_bool(quest.is_on_errand).is_false()
	assert_bool(quest.is_at_helm).is_true()
	assert_vector(heron.global_position).is_equal_approx(wheel.global_position,
			Vector3(0.02, 0.02, 0.02))


func test_once_hes_well_again_no_more_drinks() -> void:
	var quest: FirstQuest = FirstQuest.new()
	quest.drink_every = 0.1
	add_child(quest)
	auto_free(quest)
	# At the helm, but the lantern isn't low: he stays put.
	quest.set("_at_helm", true)
	await get_tree().create_timer(0.3).timeout

	assert_bool(quest.is_on_errand).is_false()


func test_filling_a_pan_at_the_butt_remembers_you_fetched_water() -> void:
	var butt: WaterButt = (load("res://scenes/prototype/props/water_butt.tscn") as PackedScene) \
			.instantiate() as WaterButt
	add_child(butt)
	auto_free(butt)
	var toolbar: Toolbar = Toolbar.new()
	toolbar.add(ItemInstance.new(Catalog.load_default().find_item(&"saucepan")))

	assert_bool(butt.fill(toolbar)).is_true()

	assert_bool(Game.dialogue.is_set(WaterButt.FETCHED_FLAG)).is_true()
	# The rain drums into it when the recording is there (it's gitignored).
	assert_bool(butt.is_drumming()).is_equal(Ambience.has_sound(butt.drumming_path))


func test_the_captain_sends_you_to_the_books_then_hints_at_the_water() -> void:
	var state: DialogueState = DialogueState.new()
	state.set_flag(&"met_heron")
	state.set_flag(LanternSpirit.LOW_FLAG)

	var before_reading: String = " ".join(_said(&"heron", state)).to_lower()
	assert_str(before_reading).contains("cookbook")
	state.set_flag(&"read_fire_spirits")
	var after_reading: String = " ".join(_said(&"heron", state)).to_lower()
	assert_str(after_reading).contains("soup")
	assert_str(after_reading).not_contains("rain")
	state.set_flag(WaterButt.FETCHED_FLAG)
	var after_fetching: String = " ".join(_said(&"heron", state)).to_lower()
	assert_str(after_fetching).not_contains("seawater")


func test_low_the_lantern_talks_weakly_but_keeps_the_clue_to_himself() -> void:
	var state: DialogueState = DialogueState.new()
	state.set_fact(&"night", func() -> int: return 1)
	state.set_flag(LanternSpirit.LOW_FLAG)

	var said: PackedStringArray = _said(&"lantern", state)
	# He talks (#184), not "...": weak, and wrong about feeling better.
	assert_array(Array(said)).is_equal(["Oh, hello again!", "I'm feeling a little better. I think.",
			"Well, perhaps not."])
	assert_str(" ".join(said).to_lower()).not_contains("spic")
	for line: String in _said(&"heron", state):
		assert_str(line).not_contains("I pulled")


func test_low_once_youve_read_the_old_book_he_thinks_of_spicy_food() -> void:
	var state: DialogueState = DialogueState.new()
	state.set_fact(&"night", func() -> int: return 1)
	state.set_flag(LanternSpirit.LOW_FLAG)
	state.set_flag(&"read_fire_spirits")

	assert_array(Array(_said(&"lantern", state))).is_equal(["Oh, hello again!", "Spicy food?",
			"I do like spicy food.", "I don't think I've ever had any, though."])


func test_overheard_chatter_leaves_out_a_muted_speaker() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var player: Player3D = rig[1] as Player3D
	var chatter: Chatter = Chatter.new()
	chatter.player = player
	rig[0].get_parent().add_child(chatter)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 3)
	var voice: Speaker = Speaker.new()
	voice.who = &"lantern"
	player.get_parent().add_child(voice)
	voice.global_position = Speaker.eye_of(player) - player.global_basis.z * 1.5
	await physics_ticks(runner, 2)
	assert_bool(chatter.audible().has(voice.who)).is_true()

	voice.muted = true

	assert_bool(chatter.audible().has(voice.who)).is_false()


# The lines [param id].dlg says from its start with [param state], up to the
# first choice.
func _said(id: StringName, state: DialogueState) -> PackedStringArray:
	var path: String = "%s/%s%s" % [DialogueLibrary.FOLDER, id, DialogueLibrary.ENDING]
	var tree: DialogueTree = DialogueScript.parse(FileAccess.get_file_as_string(path), id)
	var runner: DialogueRunner = DialogueRunner.new()
	var said: PackedStringArray = PackedStringArray()
	runner.line_shown.connect(func(line: DialogueStep) -> void:
		said.append(line.text)
		runner.advance())
	runner.start(tree, state)
	runner.stop()
	return said
