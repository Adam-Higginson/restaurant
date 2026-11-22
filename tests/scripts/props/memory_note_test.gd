extends GameTestSuite
## Tests for the note by your pillow: it replays the memories you've got back,
## or says "Don't forget" before you have any; and the note and the bunk can
## each be reached, at the head and the foot of the bunk.

## By your bunk, at its head (the note) and its foot (to sleep).
const AT_THE_HEAD: Vector3 = Vector3(4.0, 1.05, 12.85)
const AT_THE_FOOT: Vector3 = Vector3(4.0, 1.05, 13.95)


func before_test() -> void:
	Game.memories.clear()


func after_test() -> void:
	Game.memories.clear()


func test_before_anything_comes_back_it_says_dont_forget() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_HEAD)
	var hud: Hud3D = new_hud_3d(rig[1] as Player3D)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)

	var shown: int = _note(rig[0] as Ship).read()

	assert_int(shown).is_equal(1)
	assert_str(_card(hud).showing.title).is_equal(MemoryNote.BLANK_TITLE)


func test_it_replays_your_memories_in_order() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_HEAD)
	var hud: Hud3D = new_hud_3d(rig[1] as Player3D)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var catalog: Catalog = Catalog.load_default()
	await physics_ticks(runner, 2)
	Game.memories.notice(catalog.find_item(&"herring"))
	Game.memories.notice(catalog.find_item(&"sliced_tomato"))
	_card(hud).hide()

	var shown: int = _note(rig[0] as Ship).read()

	assert_int(shown).is_equal(2)
	assert_array(Game.memories.remembered_memories().map(
			func(memory: Memory) -> String: return memory.title)).contains_exactly(
			["A cold jetty", "Warm from the vine"])


func test_you_read_the_note_at_the_head_of_your_bunk() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_HEAD)
	var hud: Hud3D = new_hud_3d(rig[1] as Player3D)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)

	await walk(runner, "move_right", 2)
	await press(runner, "interact")

	assert_object(_card(hud).showing).is_not_null()


func test_you_sleep_at_the_foot_of_your_bunk() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_FOOT)
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)

	await walk(runner, "move_right", 2)
	await physics_ticks(runner, 2)

	var detector: InteractionDetector3D = player.get_node("InteractionDetector") \
			as InteractionDetector3D
	assert_object(detector.focused).is_not_null()
	assert_str(detector.focused.interact_prompt(player)).is_equal("Sleep until morning")


func _note(ship: Ship) -> MemoryNote:
	return ship.get_node("BunkRoom/MemoryNote") as MemoryNote


func _card(hud: Hud3D) -> MemoryCard:
	return hud.get_node("%MemoryCard") as MemoryCard
