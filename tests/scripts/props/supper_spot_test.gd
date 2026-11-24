extends GameTestSuite
## Tests for the lantern's warmth and supper by the stove: he fades slowly
## (never out), says so when he's low, and a dish shared at the nook's table
## warms him again (more for a better dish), leaving you the empty bowl.

## In the bunk room, just short of the nook's round table, facing it (aft).
const BY_THE_TABLE: Vector3 = Vector3(-1.0, 1.05, 10.25)


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_he_fades_slowly_but_never_goes_out() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_TABLE)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = _spirit(rig)
	var light: OmniLight3D = spirit.get_node("Light") as OmniLight3D
	await physics_ticks(runner, 2)
	var full_reach: float = light.omni_range

	spirit.warmth_per_minute = 120.0
	await physics_ticks(runner, 60)

	assert_float(spirit.warmth).is_equal_approx(spirit.min_warmth, 0.001)
	assert_float(light.omni_range).is_less(full_reach)


func test_he_says_so_when_he_is_getting_low() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_TABLE)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = _spirit(rig)
	await physics_ticks(runner, 2)

	spirit.warmth = 0.39
	await physics_ticks(runner, 2)

	assert_bool(spirit.saying() in moment_lines(&"dim")).is_true()


func test_sharing_a_bowl_of_soup_at_the_table_warms_him() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_TABLE)
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = _spirit(rig)
	await physics_ticks(runner, 2)
	spirit.warmth = 0.5
	var bowl: ItemInstance = _bowl_of(&"tomato_soup", 3)
	player.toolbar.add(bowl)
	var spot: SupperSpot = (rig[0] as Ship).get_node("BunkRoom/SupperSpot") as SupperSpot
	var expected: float = minf(0.5 + spot.warmth_of(bowl.contents.get_contents()[0]), 1.0)

	await walk(runner, "move_down", 2)
	await press(runner, "interact")

	assert_bool(bowl.contents.get_contents().is_empty()).is_true()
	assert_float(spirit.warmth).is_equal_approx(expected, 0.01)
	assert_bool(spirit.saying() in moment_lines(&"supper")).is_true()
	assert_bool(spirit.is_visiting()).is_true()


func test_an_empty_bowl_has_nothing_to_share() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_TABLE)
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spot: SupperSpot = (rig[0] as Ship).get_node("BunkRoom/SupperSpot") as SupperSpot
	await physics_ticks(runner, 2)
	player.toolbar.add(ItemInstance.new(Catalog.load_default().find_item(&"bowl")))

	assert_str(spot.prompt(player.arms)).is_empty()
	assert_bool(spot.share(player)).is_false()


func test_a_better_dish_warms_him_more() -> void:
	var spot: SupperSpot = (load("res://scenes/prototype/props/supper_spot.tscn") as PackedScene) \
			.instantiate() as SupperSpot
	auto_free(spot)
	var rough: ItemInstance = ItemInstance.new(Catalog.load_default().find_item(&"tomato_soup"), 1)
	var fine: ItemInstance = ItemInstance.new(Catalog.load_default().find_item(&"tomato_soup"), 3)

	assert_float(spot.warmth_of(fine)).is_greater(spot.warmth_of(rough))


func test_low_he_only_stirs_for_the_remedy() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_TABLE)
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)
	Game.dialogue.set_flag(LanternSpirit.LOW_FLAG)
	var bowl: ItemInstance = _bowl_of(&"tomato_soup", 3)
	player.toolbar.add(bowl)
	var spot: SupperSpot = (rig[0] as Ship).get_node("BunkRoom/SupperSpot") as SupperSpot

	assert_bool(spot.can_share(player.arms)).is_false()
	assert_bool(spot.share(player)).is_false()
	assert_int(bowl.contents.get_contents().size()).is_equal(1)
	assert_str(spot.prompt(player.arms)).is_not_equal("Share Tomato Soup with the lantern")


func test_the_remedy_brings_him_back_and_warms_him() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_TABLE)
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = _spirit(rig)
	await physics_ticks(runner, 2)
	Game.dialogue.set_flag(LanternSpirit.LOW_FLAG)
	await physics_ticks(runner, 3)
	assert_float(spirit.warmth).is_equal(spirit.min_warmth)
	var bowl: ItemInstance = _bowl_of(&"spicy_tomato_soup", 3)
	player.toolbar.add(bowl)
	var spot: SupperSpot = (rig[0] as Ship).get_node("BunkRoom/SupperSpot") as SupperSpot
	assert_str(spot.prompt(player.arms)).is_equal("Share Spicy Tomato Soup with the lantern")

	assert_bool(spot.share(player)).is_true()
	# Still low while he has it...
	assert_bool(spirit.is_low()).is_true()
	assert_bool(await wait_for_signal(spot.mended, spot.eat_seconds + 2.0)).is_true()
	await physics_ticks(runner, 3)

	# ...and then he's back, warm, the crack gone. (No conversation here to
	# play the cutscene in, so he simply comes back.)
	assert_bool(spirit.is_low()).is_false()
	assert_float(spirit.warmth).is_greater(spirit.min_warmth + 0.3)
	assert_bool(spirit.face().cracked).is_false()


func test_the_first_meal_plays_as_you_set_it_down() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_TABLE)
	var player: Player3D = rig[1] as Player3D
	var conversation: Conversation = new_conversation(player)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)
	Game.dialogue.set_flag(LanternSpirit.LOW_FLAG)
	player.toolbar.add(_bowl_of(&"spicy_tomato_soup", 1))
	var spot: SupperSpot = (rig[0] as Ship).get_node("BunkRoom/SupperSpot") as SupperSpot
	var speakers: Array[StringName] = []
	conversation.line_said.connect(func(speaker: Person) -> void:
		speakers.append(speaker.id if speaker != null else &""))

	assert_bool(spot.share(player)).is_true()
	# At once, not after he's eaten: he asks what it is first.
	await physics_ticks(runner, 2)
	assert_bool(conversation.is_active()).is_true()
	assert_bool(Game.dialogue.is_set(LanternSpirit.LOW_FLAG)).is_true()
	for i: int in 2400:
		if not conversation.is_active():
			break
		await physics_ticks(runner, 1)
		if i % 10 == 0:
			conversation.press()

	assert_bool(conversation.is_active()).is_false()
	assert_bool(Game.dialogue.is_set(LanternSpirit.LOW_FLAG)).is_false()
	# His questions and his joy, the captain at the door, and his thanks.
	var l: StringName = &"lantern"
	var h: StringName = &"heron"
	assert_array(speakers).is_equal([l, l, l, l, l, l, l, l, h, l, h, l, h, l, l, l])


func test_every_mark_and_shot_the_first_meal_uses_is_in_the_ship() -> void:
	var ship: Node = (load("res://scenes/prototype/ship.tscn") as PackedScene).instantiate()
	auto_free(ship)
	var script: String = FileAccess.get_file_as_string("res://data/dialogue/remedy.dlg")
	var marks: Array[String] = []
	var shots: Array[String] = []
	for node: Node in ship.get_node("Marks").get_children():
		marks.append(String(node.name).to_snake_case())
	for node: Node in ship.get_node("Shots").get_children():
		shots.append(String(node.name).to_snake_case())
	var used: int = 0

	for line: String in script.split("
"):
		var words: PackedStringArray = line.strip_edges().split(" ")
		if words[0] in ["@go", "@place"] and words.size() > 2:
			assert_array(marks).contains([words[2]])
			used += 1
		elif words[0] == "@shot" and words[1] != "free":
			assert_array(shots).contains([words[1]])
			used += 1

	assert_int(used).is_greater(8)


func test_the_first_meals_bowl_waits_on_the_table_until_hes_well() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_TABLE)
	var player: Player3D = rig[1] as Player3D
	new_conversation(player)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)
	Game.dialogue.set_flag(LanternSpirit.LOW_FLAG)
	player.toolbar.add(_bowl_of(&"spicy_tomato_soup", 1))
	var spot: SupperSpot = (rig[0] as Ship).get_node("BunkRoom/SupperSpot") as SupperSpot
	var plate_spot: Node3D = spot.get_node("PlateSpot") as Node3D

	assert_bool(spot.share(player)).is_true()
	# The scene waits on his first line (nobody presses): longer than a
	# supper takes, and the bowl's still there.
	await get_tree().create_timer(spot.eat_seconds + 0.5).timeout
	assert_int(plate_spot.get_child_count()).is_equal(1)

	Game.dialogue.clear(LanternSpirit.LOW_FLAG)
	await physics_ticks(runner, 2)

	assert_int(plate_spot.get_child_count()).is_equal(0)


func _spirit(rig: Array[Node3D]) -> LanternSpirit:
	return rig[1].get_node("LanternSpirit") as LanternSpirit


func _bowl_of(dish: StringName, quality: int) -> ItemInstance:
	var bowl: ItemInstance = ItemInstance.new(Catalog.load_default().find_item(&"bowl"))
	bowl.contents.add_item(ItemInstance.new(Catalog.load_default().find_item(dish), quality))
	return bowl
