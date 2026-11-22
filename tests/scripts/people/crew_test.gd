extends GameTestSuite
## Tests for the crew aboard: the heron stands by the stove at night and at
## the wheel in the morning, swapping when the time does; the lantern lives
## at the round table instead of following you, and what he doesn't see
## becomes news for later; and the facts scripts can ask about.

## By the bunk room stove, near the round table.
const BY_THE_STOVE: Vector3 = Vector3(-1.0, 1.05, 9.9)
## On the main deck, a long way from the bunk room.
const ON_DECK: Vector3 = Vector3(0, 6.25, -16.2)


func before_test() -> void:
	Game.dialogue.reset()
	Game.memories.clear()


func after_test() -> void:
	Game.dialogue.reset()
	Game.memories.clear()


func test_the_heron_is_by_the_stove_at_night() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_STOVE)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 3)
	var heron: Crewmate = rig[0].get_node("Crew/Heron") as Crewmate
	var night: Node3D = rig[0].get_node("Crew/HeronNight") as Node3D

	assert_vector(heron.global_position).is_equal_approx(night.global_position,
			Vector3(0.01, 0.01, 0.01))


func test_the_heron_is_at_the_wheel_in_the_morning_and_back_at_night() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_STOVE)
	var time: TimeOfDay = TimeOfDay.new()
	rig[0].get_parent().add_child(time)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 3)
	var heron: Crewmate = rig[0].get_node("Crew/Heron") as Crewmate
	var wheel: Node3D = rig[0].get_node("Crew/HeronMorning") as Node3D
	var stove: Node3D = rig[0].get_node("Crew/HeronNight") as Node3D

	time.dawn = 1.0
	assert_vector(heron.global_position).is_equal_approx(wheel.global_position,
			Vector3(0.01, 0.01, 0.01))

	time.dawn = 0.0
	assert_vector(heron.global_position).is_equal_approx(stove.global_position,
			Vector3(0.01, 0.01, 0.01))


func test_a_station_with_no_spots_leaves_its_crewmate_alone() -> void:
	var body: Node3D = Node3D.new()
	auto_free(body)
	body.position = Vector3(3, 0, 3)
	var station: CrewStation = CrewStation.new()
	body.add_child(station)

	station.place(true)

	assert_vector(body.position).is_equal(Vector3(3, 0, 3))


func test_the_heron_stands_clear_of_the_table_and_the_stove() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_STOVE)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 3)
	var heron: Node3D = rig[0].get_node("Crew/Heron") as Node3D
	var table: Node3D = rig[0].get_node("BunkRoom/RoundTable") as Node3D
	var stove: Node3D = rig[0].get_node("BunkRoom/Stove") as Node3D

	assert_float(_flat_distance(heron, table)).is_greater(0.9)
	assert_float(_flat_distance(heron, stove)).is_greater(1.2)


func test_the_lantern_lives_at_the_round_table_and_doesnt_follow() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_STOVE)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var player: Player3D = rig[1] as Player3D
	var spirit: LanternSpirit = player.get_node("LanternSpirit") as LanternSpirit
	await physics_ticks(runner, 5)
	var perch: Node3D = rig[0].get_node("BunkRoom/SupperSpot/Perch") as Node3D
	assert_object(spirit.home).is_same(perch)

	place_player_3d(runner, ON_DECK)
	await physics_ticks(runner, 60)

	var here: Vector3 = spirit.global_position
	here.y = perch.global_position.y
	assert_float(here.distance_to(perch.global_position)).is_less(0.05)


func test_at_home_he_rides_along_as_the_ship_sails() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_STOVE)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var ship: Ship = rig[0] as Ship
	var spirit: LanternSpirit = rig[1].get_node("LanternSpirit") as LanternSpirit
	var perch: Node3D = ship.get_node("BunkRoom/SupperSpot/Perch") as Node3D
	await physics_ticks(runner, 5)

	ship.set_sail()
	await physics_ticks(runner, 240)

	assert_float(ship.global_position.z).is_less(-2.0)
	var here: Vector3 = spirit.global_position
	here.y = perch.global_position.y
	assert_float(here.distance_to(perch.global_position)).is_less(0.3)


func test_near_him_he_says_it_and_far_from_him_its_news_for_later() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_STOVE)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = rig[1].get_node("LanternSpirit") as LanternSpirit
	await physics_ticks(runner, 5)

	assert_bool(spirit.is_in_earshot()).is_true()
	assert_bool(spirit.tell(&"caught", &"news_fish")).is_true()
	var said: String = spirit.saying()
	assert_bool(said in moment_lines(&"caught")).is_true()
	assert_bool(Game.dialogue.is_set(&"news_fish")).is_false()

	place_player_3d(runner, ON_DECK)
	await physics_ticks(runner, 5)
	assert_bool(spirit.is_in_earshot()).is_false()
	assert_bool(spirit.tell(&"hove_to", &"news_bell")).is_false()
	assert_str(spirit.saying()).is_equal(said)
	assert_bool(Game.dialogue.is_set(&"news_bell")).is_true()


func test_a_memory_that_comes_back_far_from_him_is_news() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(ON_DECK)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 5)

	Game.memories.notice(Catalog.load_default().find_item(&"herring"))

	assert_bool(Game.dialogue.is_set(&"news_memory")).is_true()


func test_told_to_leave_home_he_follows_at_your_shoulder() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(ON_DECK)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var player: Player3D = rig[1] as Player3D
	var spirit: LanternSpirit = lantern_at_shoulder(player)

	await physics_ticks(runner, 30)

	assert_object(spirit.home).is_null()
	assert_float(spirit.global_position.distance_to(player.global_position)).is_less(2.5)
	assert_bool(spirit.is_in_earshot()).is_true()


func test_with_nothing_to_share_the_round_table_talks_to_the_lantern() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_STOVE)
	var conversation: Conversation = Conversation.new()
	rig[0].get_parent().add_child(conversation)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var player: Player3D = rig[1] as Player3D
	var supper: SupperSpot = rig[0].get_node("BunkRoom/SupperSpot") as SupperSpot
	await physics_ticks(runner, 3)

	assert_str(supper.prompt(player.arms)).is_equal("Talk to the lantern")
	supper.use(player)

	assert_str(String(conversation.talking)).is_equal("lantern")
	conversation.stop()


func test_without_a_conversation_in_the_scene_the_table_offers_nothing() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_STOVE)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var player: Player3D = rig[1] as Player3D
	var supper: SupperSpot = rig[0].get_node("BunkRoom/SupperSpot") as SupperSpot
	await physics_ticks(runner, 3)

	assert_str(supper.prompt(player.arms)).is_empty()


func test_scripts_can_ask_about_the_time_the_weather_and_the_ship() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_STOVE)
	var ship: Ship = rig[0] as Ship
	var world: Node = ship.get_parent()
	var time: TimeOfDay = TimeOfDay.new()
	world.add_child(time)
	var weather: Weather = Weather.new()
	world.add_child(weather)
	var facts: DialogueFacts = DialogueFacts.new()
	facts.ship = ship
	facts.weather = weather
	world.add_child(facts)
	var runner: GdUnitSceneRunner = scene_runner(world)
	await physics_ticks(runner, 3)
	var state: DialogueState = Game.dialogue

	time.dawn = 0.0
	time.day = 3
	weather.intensity = 0.8
	assert_bool(state.is_set(&"night")).is_true()
	assert_bool(state.is_set(&"morning")).is_false()
	assert_int(state.value(&"day")).is_equal(3)
	assert_bool(state.is_set(&"raining")).is_true()
	assert_bool(state.is_set(&"sailing")).is_false()

	time.dawn = 1.0
	weather.intensity = 0.1
	assert_bool(state.is_set(&"morning")).is_true()
	assert_bool(state.is_set(&"raining")).is_false()

	facts.free()
	assert_bool(state.is_fact(&"night")).is_false()


func _flat_distance(a: Node3D, b: Node3D) -> float:
	var apart: Vector3 = a.global_position - b.global_position
	apart.y = 0.0
	return apart.length()


func test_by_the_stove_at_night_you_can_overhear_the_heron_and_the_lantern() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_STOVE)
	var chatter: Chatter = Chatter.new()
	chatter.player = rig[1]
	rig[0].get_parent().add_child(chatter)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 5)

	assert_array(chatter.audible().keys()).contains_exactly_in_any_order([&"heron", &"lantern"])


func test_up_on_deck_you_cant_overhear_them_through_the_deck() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_STOVE + Vector3(0, 5.2, 0))
	var chatter: Chatter = Chatter.new()
	chatter.player = rig[1]
	rig[0].get_parent().add_child(chatter)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 5)

	assert_array(chatter.audible().keys()).is_empty()
