extends GameTestSuite
## Tests for supper at the galley's long table (#207): set a dish down (Use),
## pick it back up (Interact), ring the bell, and the lantern comes to eat.
## Well, any dish warms him (more for a better one) and leaves you the empty
## bowl; low, the spicy tomato soup plays the first meal, and anything else
## he eats sadly, with a hint.

## In the galley, on the long table's aft side, facing it (forward).
const AT_THE_TABLE: Vector3 = Vector3(1.0, 1.05, 6.35)


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_use_sets_a_dish_on_the_table_and_interact_picks_it_up() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_TABLE)
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var table: SupperTable = _table(rig)
	var bowl: ItemInstance = _bowl_of(&"tomato_soup", 2)
	await physics_ticks(runner, 3)
	player.toolbar.add(bowl)
	var detector: InteractionDetector3D = player.get_node("InteractionDetector") \
			as InteractionDetector3D
	await physics_ticks(runner, 3)
	assert_str(detector.tool_prompt()).is_equal("Set Tomato Soup on the table")

	await press(runner, "use_tool")

	assert_object(table.place).is_same(bowl)
	assert_bool(player.toolbar.get_items().has(bowl)).is_false()
	assert_int(table.plate_spot().get_child_count()).is_equal(1)
	assert_str(detector.interact_prompt()).is_equal("Pick up Bowl")

	await press(runner, "interact")

	assert_object(table.place).is_null()
	assert_object(player.toolbar.top()).is_same(bowl)


func test_an_empty_bowl_isnt_set_out() -> void:
	var table: SupperTable = _new_table()
	var hand: Toolbar = Toolbar.new()
	hand.add(ItemInstance.new(Catalog.load_default().find_item(&"bowl")))

	assert_str(table.use_prompt(hand)).is_empty()
	assert_bool(table.set_down(hand)).is_false()


func test_ringing_the_bell_brings_him_to_eat_and_warms_him() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_TABLE)
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var table: SupperTable = _table(rig)
	var spirit: LanternSpirit = _spirit(rig)
	await physics_ticks(runner, 2)
	spirit.warmth = 0.5
	var bowl: ItemInstance = _bowl_of(&"tomato_soup", 3)
	player.toolbar.add(bowl)
	table.set_down(player.arms)
	var expected: float = minf(0.5 + table.warmth_of(bowl.contents.get_contents()[0]), 1.0)

	assert_bool(_bell(rig).ring(player)).is_true()

	assert_float(spirit.warmth).is_equal_approx(expected, 0.01)
	assert_bool(spirit.is_visiting()).is_true()
	await physics_ticks(runner, int((table.eat_seconds + 1.0) * 60.0))
	# Eaten: the empty bowl's left on the table for you.
	assert_bool(bowl.contents.get_contents().is_empty()).is_true()
	assert_object(table.place).is_same(bowl)


func test_a_better_dish_warms_him_more() -> void:
	var table: SupperTable = _new_table()
	var rough: ItemInstance = ItemInstance.new(Catalog.load_default().find_item(&"tomato_soup"), 1)
	var fine: ItemInstance = ItemInstance.new(Catalog.load_default().find_item(&"tomato_soup"), 3)

	assert_float(table.warmth_of(fine)).is_greater(table.warmth_of(rough))


func test_ringing_with_nothing_on_the_table_feeds_nobody() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_TABLE)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)

	assert_bool(_bell(rig).ring(rig[1] as Player3D)).is_false()
	assert_bool(_spirit(rig).is_visiting()).is_false()


func test_plain_soup_keeps_lantern_cold_and_leaves_the_batch_to_finish() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_TABLE)
	var player: Player3D = rig[1] as Player3D
	var conversation: Conversation = new_conversation(player)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var table: SupperTable = _table(rig)
	await physics_ticks(runner, 2)
	Game.dialogue.set_flag(LanternSpirit.LOW_FLAG)
	var bowl: ItemInstance = _bowl_of(&"tomato_soup", 3)
	player.toolbar.add(bowl)
	table.set_down(player.arms)

	assert_bool(_bell(rig).ring(player)).is_true()

	await physics_ticks(runner, 2)
	assert_str(String(conversation.talking)).is_equal("supper_hint")
	for i: int in 1200:
		if not conversation.is_active():
			break
		await physics_ticks(runner, 1)
		if i % 10 == 0:
			conversation.press()
	await physics_ticks(runner, int(table.eat_seconds * 60.0) + 10)
	# Plain soup is returned after he gives the hint.
	assert_bool(Game.dialogue.is_set(LanternSpirit.LOW_FLAG)).is_true()
	assert_bool(Game.dialogue.is_set(&"served_plain_soup")).is_true()
	assert_int(bowl.contents.get_contents().size()).is_equal(1)
	assert_bool(table.pick_up(player.arms)).is_true()


func test_the_remedy_at_the_table_plays_the_first_meal() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_TABLE)
	var player: Player3D = rig[1] as Player3D
	var conversation: Conversation = new_conversation(player)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var table: SupperTable = _table(rig)
	var spirit: LanternSpirit = _spirit(rig)
	await physics_ticks(runner, 2)
	Game.dialogue.set_flag(LanternSpirit.LOW_FLAG)
	var bowl: ItemInstance = _bowl_of(&"spicy_tomato_soup", 1)
	player.toolbar.add(bowl)
	table.set_down(player.arms)
	var speakers: Array[StringName] = []
	conversation.line_said.connect(func(speaker: Person) -> void:
		speakers.append(speaker.id if speaker != null else &""))

	assert_bool(_bell(rig).ring(player)).is_true()

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
	# A one-star soup: warmer by a quarter.
	assert_float(spirit.warmth).is_greater(spirit.min_warmth + 0.2)
	# His questions and his joy, the captain looking in, and his thanks.
	var l: StringName = &"lantern"
	var h: StringName = &"heron"
	assert_array(speakers).is_equal([l, l, l, l, l, l, l, l, h, l, h, l, h, l, l, l])
	# The bowl's emptied as he takes it in, and waits for you to clear it.
	assert_bool(bowl.contents.get_contents().is_empty()).is_true()
	assert_object(table.place).is_same(bowl)


func test_every_mark_and_shot_supper_uses_is_in_the_ship() -> void:
	var ship: Node = (load("res://scenes/prototype/ship.tscn") as PackedScene).instantiate()
	auto_free(ship)
	var marks: Array[String] = []
	var shots: Array[String] = []
	for node: Node in ship.get_node("Marks").get_children():
		marks.append(String(node.name).to_snake_case())
	for node: Node in ship.get_node("Shots").get_children():
		shots.append(String(node.name).to_snake_case())
	var used: int = 0

	for scene: String in ["remedy", "supper_hint"]:
		var script: String = FileAccess.get_file_as_string("res://data/dialogue/%s.dlg" % scene)
		for line: String in script.split("\n"):
			var words: PackedStringArray = line.strip_edges().split(" ")
			if words[0] in ["@go", "@place"] and words.size() > 2:
				assert_array(marks).contains([words[2]])
				used += 1
			elif words[0] == "@shot" and words[1] != "free":
				assert_array(shots).contains([words[1]])
				used += 1

	assert_int(used).is_greater(9)


func test_the_bell_explains_what_to_do_with_an_empty_table() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_TABLE)
	scene_runner(rig[0].get_parent())
	var reach: Interactable3D = _bell(rig).get_node("Reach") as Interactable3D

	assert_str(reach.interact_prompt(rig[1] as Player3D)).is_equal(
			"Set a meal on the table first")


func _table(rig: Array[Node3D]) -> SupperTable:
	return rig[0].get_node("Galley/SupperTable") as SupperTable


func _bell(rig: Array[Node3D]) -> DinnerBell:
	return rig[0].get_node("Galley/ShipsBell") as DinnerBell


func _spirit(rig: Array[Node3D]) -> LanternSpirit:
	return rig[1].get_node("LanternSpirit") as LanternSpirit


func _new_table() -> SupperTable:
	var table: SupperTable = (load("res://scenes/prototype/props/supper_table.tscn") \
			as PackedScene).instantiate() as SupperTable
	auto_free(table)
	return table


func _bowl_of(dish: StringName, quality: int) -> ItemInstance:
	var bowl: ItemInstance = ItemInstance.new(Catalog.load_default().find_item(&"bowl"))
	bowl.contents.add_item(ItemInstance.new(Catalog.load_default().find_item(dish), quality))
	return bowl
