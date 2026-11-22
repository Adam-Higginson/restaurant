extends GameTestSuite
## Tests for the lantern's voice: lines wait their turn and fade away, he
## never repeats himself twice running, and he speaks up when a memory comes
## back, when you land a fish, when you stop the ship, and when you look out
## from the bow (at the light at night, the island at dawn; not every time).

## Out on the bow, past the windlass.
const ON_THE_BOW: Vector3 = Vector3(0, 6.25, -16.2)


func before_test() -> void:
	Game.memories.clear()


func after_test() -> void:
	Game.memories.clear()


func test_lines_wait_their_turn_then_he_goes_quiet() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var voice: LanternVoice = rig[1].get_node("LanternSpirit/Voice") as LanternVoice
	voice.base_seconds = 0.1
	voice.seconds_per_letter = 0.0
	voice.fade_seconds = 0.05
	await physics_ticks(runner, 2)

	voice.say("One.")
	voice.say("Two.")
	assert_str(voice.saying).is_equal("One.")
	await physics_ticks(runner, 15)
	assert_str(voice.saying).is_equal("Two.")
	await physics_ticks(runner, 15)

	assert_str(voice.saying).is_empty()


func test_he_never_says_the_same_thing_twice_running() -> void:
	var last: String = ""
	for i: int in 60:
		var line: String = LanternLines.pick(LanternLines.MORNING)
		assert_str(line).is_not_equal(last)
		last = line


func test_he_speaks_up_when_a_memory_comes_back() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = rig[1].get_node("LanternSpirit") as LanternSpirit
	await physics_ticks(runner, 2)

	Game.memories.notice(Catalog.load_default().find_item(&"garden_salad"))

	assert_bool(spirit.saying() in LanternLines.REMEMBERED).is_true()


func test_he_cheers_when_you_land_a_fish() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(4.6, 5.35, 4.3))
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spot: FishingSpot = rig[0].get_node("Visuals/UpperDeck/Dressing/FishingSpot") as FishingSpot
	spot.line.min_wait = 0.1
	spot.line.max_wait = 0.1
	var spirit: LanternSpirit = rig[1].get_node("LanternSpirit") as LanternSpirit
	await physics_ticks(runner, 5)
	await walk(runner, "move_right", 2)

	await press(runner, "interact")
	await physics_ticks(runner, 10)
	await press(runner, "interact")

	assert_bool(spirit.saying() in LanternLines.CAUGHT).is_true()


func test_he_notices_the_far_light_from_the_bow_at_night() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 6.25, -11.8))
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = rig[1].get_node("LanternSpirit") as LanternSpirit
	await physics_ticks(runner, 5)

	place_player_3d(runner, (rig[0] as Ship).to_global(ON_THE_BOW))
	await physics_ticks(runner, 5)

	assert_bool(spirit.saying() in LanternLines.FAR_LIGHT).is_true()


func test_at_dawn_he_spots_the_island_instead() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 6.25, -11.8))
	var time: TimeOfDay = TimeOfDay.new()
	rig[0].get_parent().add_child(time)
	time.dawn = 1.0
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = rig[1].get_node("LanternSpirit") as LanternSpirit
	await physics_ticks(runner, 5)

	place_player_3d(runner, (rig[0] as Ship).to_global(ON_THE_BOW))
	await physics_ticks(runner, 5)

	assert_bool(spirit.saying() in LanternLines.ISLAND).is_true()


func test_he_has_a_think_between_guesses() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 6.25, -11.8))
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var lookout: Lookout = rig[0].get_node("Visuals/UpperDeck/Dressing/Lookout") as Lookout
	await physics_ticks(runner, 5)
	assert_bool(lookout.would_speak()).is_true()

	place_player_3d(runner, (rig[0] as Ship).to_global(ON_THE_BOW))
	await physics_ticks(runner, 5)

	assert_bool(lookout.would_speak()).is_false()


func test_he_is_glad_when_you_stop_the_ship() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 6.25, -11.9))
	var ship: Ship = rig[0] as Ship
	ship.set_sail()
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var spirit: LanternSpirit = rig[1].get_node("LanternSpirit") as LanternSpirit
	await physics_ticks(runner, 5)

	await walk(runner, "move_down", 2)
	await physics_ticks(runner, 3)
	await press(runner, "interact")

	assert_bool(spirit.saying() in LanternLines.HOVE_TO).is_true()
