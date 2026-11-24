extends GameTestSuite
## Tests for the end of the Prologue (#187): the deck talk after the
## lantern's soup, which sends you to bed; your bunk then sailing on to the
## island; the passage at sea ending with the game going to the cove; the
## ship sailing into the cove and anchoring; and arriving keeping the voyage.

const COVE: String = "res://scenes/prototype/islands/cove.tscn"
const SHIP: String = "res://scenes/prototype/ship.tscn"


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_the_deck_talk_waits_for_the_soup_and_plays_once() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var player: Player3D = rig[1] as Player3D
	var conversation: Conversation = new_conversation(player)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 3)
	var trigger: StoryTrigger = rig[0].get_node("DeckTalk") as StoryTrigger
	var started: Array[StringName] = []
	conversation.started.connect(func(tree_id: StringName) -> void: started.append(tree_id))

	# Before the soup, nothing.
	assert_bool(trigger.play_for(player)).is_false()
	Game.dialogue.set_flag(&"warmed_lantern")
	assert_bool(trigger.play_for(player)).is_true()
	assert_array(started).is_equal([&"deck_talk"])
	conversation.skip()
	await physics_ticks(runner, 5)

	assert_bool(conversation.is_active()).is_false()
	assert_bool(Game.dialogue.is_set(Bedside.BOUND_FLAG)).is_true()
	assert_bool(trigger.play_for(player)).is_false()


func test_coming_up_on_deck_starts_the_deck_talk() -> void:
	Game.dialogue.set_flag(&"warmed_lantern")
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var conversation: Conversation = new_conversation(player)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 3)
	assert_bool(conversation.is_active()).is_false()

	# The top of the hatch ramp.
	place_player_3d(runner, ship.to_global(Vector3(-4.6, 5.4, 0.0)))
	await physics_ticks(runner, 5)

	assert_bool(conversation.is_active()).is_true()


func test_the_deck_talk_has_the_scripts_lines_and_sends_you_to_bed() -> void:
	var text: String = _script_of(&"deck_talk")

	for line: String in ["lantern: Much better, isn't it?", "heron: Yes. Much.",
			"heron: We're still heading for the island.", "heron: Probably wet.",
			"lantern: Everything's wet!", "heron: Get some sleep. We'll make land by morning."]:
		assert_str(text).contains(line)
	assert_str(text).contains("set deck_talk")
	assert_str(text).contains("@rain")


func test_every_scene_of_the_voyage_reads_cleanly() -> void:
	for id: StringName in [&"deck_talk", &"voyage", &"arrival", &"remedy", &"chest"]:
		var tree: DialogueTree = DialogueScript.parse(_script_of(id), id)
		assert_array(tree.errors).override_failure_message("%s: %s" % [id, tree.errors]) \
				.is_empty()


func test_every_mark_and_shot_the_voyage_names_is_there() -> void:
	var ship: Node = auto_free((load(SHIP) as PackedScene).instantiate())
	var cove: Node = auto_free((load(COVE) as PackedScene).instantiate())
	var aboard: Array[String] = _names_in(ship)
	var ashore: Array[String] = aboard + _names_in(cove)
	var used: int = 0

	for id: StringName in [&"deck_talk", &"voyage", &"arrival", &"remedy"]:
		var known: Array[String] = ashore if id == &"arrival" else aboard
		for line: String in _script_of(id).split("\n"):
			var words: PackedStringArray = line.strip_edges().split(" ")
			var wanted: String = ""
			if words[0] in ["@go", "@place", "@walk", "@send"] and words.size() > 2:
				wanted = words[2]
			elif words[0] == "@face" and words.size() > 2 and words[2] not in ["player", "lantern"]:
				wanted = words[2]
			elif words[0] == "@shot" and words[1] != "free":
				wanted = words[1]
			if wanted == "" or wanted == "home":
				continue
			assert_array(known).override_failure_message("%s names '%s'" % [id, wanted]) \
					.contains([wanted])
			used += 1

	assert_int(used).is_greater(20)


func test_after_the_deck_talk_your_bunk_sails_on_to_the_island() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(3.3, 1.05, 12.0))
	var player: Player3D = rig[1] as Player3D
	var conversation: Conversation = new_conversation(player)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 3)
	var bunk: Bedside = rig[0].get_node("BunkRoom/Bedside") as Bedside
	var started: Array[StringName] = []
	conversation.started.connect(func(tree_id: StringName) -> void: started.append(tree_id))
	assert_str(bunk.prompt()).is_not_equal("Sleep until we make land")

	Game.dialogue.set_flag(Bedside.BOUND_FLAG)
	assert_str(bunk.prompt()).is_equal("Sleep until we make land")
	bunk.sleep(player)
	assert_bool(await wait_for_signal(bunk.voyage_began, 5.0)).is_true()
	await physics_ticks(runner, 3)

	assert_array(started).is_equal([&"voyage"])
	conversation.stop()


func test_once_youve_arrived_your_bunk_is_just_a_bunk_again() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(3.3, 1.05, 12.0))
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 3)
	var bunk: Bedside = rig[0].get_node("BunkRoom/Bedside") as Bedside
	Game.dialogue.set_flag(Bedside.BOUND_FLAG)

	Game.dialogue.set_flag(Bedside.ARRIVED_FLAG)

	assert_bool(bunk.is_bound_for_land()).is_false()
	assert_str(bunk.prompt()).is_not_equal("Sleep until we make land")


func test_the_passage_at_sea_ends_by_going_to_the_cove() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var conversation: Conversation = new_conversation(player)
	var travel: TravelCues = TravelCues.new()
	travel.change_scene = false
	player.get_parent().add_child(travel)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 3)
	var went: Array[StringName] = []
	travel.travelling.connect(func(place: StringName) -> void: went.append(place))

	assert_bool(conversation.play(&"voyage", player)).is_true()
	conversation.skip()
	await physics_ticks(runner, 10)

	assert_bool(conversation.is_active()).is_false()
	assert_array(went).is_equal([&"cove"])
	assert_bool(Game.dialogue.is_set(CoveArrival.ARRIVING_FLAG)).is_true()
	assert_bool(FileAccess.file_exists(travel.scene_of(&"cove"))).is_true()


func test_somewhere_unknown_is_warned_about_and_goes_nowhere() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var conversation: Conversation = new_conversation(player)
	var travel: TravelCues = TravelCues.new()
	travel.change_scene = false
	player.get_parent().add_child(travel)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 3)
	var went: Array[StringName] = []
	travel.travelling.connect(func(place: StringName) -> void: went.append(place))

	play_cutscene(conversation, player, "@travel atlantis\nheron: Off we go.")
	conversation.press()
	await physics_ticks(runner, 3)

	assert_array(went).is_empty()


func test_arriving_she_sails_in_and_anchors_and_the_voyage_is_kept() -> void:
	Game.dialogue.set_flag(CoveArrival.ARRIVING_FLAG)
	if FileAccess.file_exists(SaveGame.path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	var runner: GdUnitSceneRunner = scene_runner(COVE)
	var arrival: CoveArrival = runner.find_child("Arrival") as CoveArrival
	var ship: Ship = runner.find_child("Ship") as Ship
	var player: Player3D = runner.find_child("Player") as Player3D
	await physics_ticks(runner, 60)
	var anchorage: Vector3 = arrival.anchorage().origin

	# Out at sea and coming in, you aboard.
	assert_bool(arrival.is_sailing_in).is_true()
	assert_float(ship.global_position.distance_to(anchorage)).is_greater(40.0)
	assert_float(player.global_position.distance_to(ship.global_position)).is_less(15.0)
	assert_bool(Game.dialogue.is_set(CoveArrival.ARRIVING_FLAG)).is_false()
	await physics_ticks(runner, 120)
	var conversation: Conversation = Conversation.find(arrival)
	assert_bool(conversation.is_active()).is_true()
	var nearer: float = ship.global_position.distance_to(anchorage)
	assert_float(nearer).is_less(88.0)
	var arrived: Array[bool] = [false]
	arrival.arrived.connect(func() -> void: arrived[0] = true)
	conversation.skip()
	for i: int in 120:
		if arrived[0]:
			break
		await physics_ticks(runner, 1)
	assert_bool(arrived[0]).is_true()
	await physics_ticks(runner, 5)

	assert_vector(ship.global_position).is_equal_approx(anchorage, Vector3(0.01, 0.01, 0.01))
	var start: Node3D = runner.find_child("DeckStart") as Node3D
	assert_float(player.global_position.distance_to(start.global_position)).is_less(0.3)
	assert_bool(Game.dialogue.is_set(Bedside.ARRIVED_FLAG)).is_true()
	var saved: Dictionary = SaveGame.read()
	var flags: Dictionary = saved.get("flags", {})
	assert_bool(flags.has(String(Bedside.ARRIVED_FLAG)) or flags.has(Bedside.ARRIVED_FLAG)) \
			.is_true()


func test_visiting_the_cove_otherwise_she_is_simply_at_anchor() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COVE)
	var ship: Ship = runner.find_child("Ship") as Ship
	var anchorage: Vector3 = ship.global_position
	await physics_ticks(runner, 30)

	assert_bool((runner.find_child("Arrival") as CoveArrival).is_sailing_in).is_false()
	assert_vector(ship.global_position).is_equal(anchorage)
	assert_bool(Conversation.find(ship).is_active()).is_false()


# The marks and shots in [param scene], as a script names them.
func _names_in(scene: Node) -> Array[String]:
	var names: Array[String] = []
	for node: Node in scene.find_children("*", "Marker3D", true, false):
		if node.is_in_group(ActorCues.GROUP) or node.is_in_group(ShotCues.GROUP):
			names.append(String(node.name).to_snake_case())
	return names


func _script_of(id: StringName) -> String:
	return FileAccess.get_file_as_string("%s/%s%s" % [DialogueLibrary.FOLDER, id,
			DialogueLibrary.ENDING])
