extends GameTestSuite
## Tests for HomeWaters (#227): your sibling's call, the lantern's chatter
## paced by distance and landmarks, coming alongside the buoy, the wall round
## the island and the nudge back from far out.

const SCENE: String = "res://scenes/prototype/intro/home_waters.tscn"

## Where the boat is put for each test, flat across the water (x, z).
const BESIDE_THE_CHAIN: Vector2 = Vector2(-8, -85)
const NEAR_THE_BUOY: Vector2 = Vector2(-10, -132)
const ALONGSIDE: Vector2 = Vector2(-10, -126)
const FAR_OUT: Vector2 = Vector2(-5, -260)

var _runner: GdUnitSceneRunner = null
var _beat: HomeWaters = null


func before_test() -> void:
	_runner = scene_runner(SCENE)
	_beat = _runner.scene() as HomeWaters


func test_your_sibling_calls_once_at_the_start() -> void:
	var calls: Array[String] = []
	_beat.sibling.said.connect(func(line: String) -> void: calls.append(line))

	# It's the first thing said, straight away.
	assert_str(_beat.sibling.saying).is_equal("Back by supper. I'm doing the fish stew.")
	assert_array(_beat.played).is_equal([HomeWaters.SIBLING])

	# Long enough for the line to finish several times over.
	await physics_ticks(_runner, 900)

	assert_array(calls).is_equal(["Back by supper. I'm doing the fish stew."])
	assert_bool(_beat.sibling.is_busy()).is_false()


func test_the_lantern_waits_for_your_sibling_to_finish() -> void:
	_place(BESIDE_THE_CHAIN)
	await physics_ticks(_runner, 10)

	# Every moment has come, but your sibling is still speaking.
	assert_array(_beat.played).is_equal([HomeWaters.SIBLING])
	assert_array(_beat.waiting).contains([&"left_jetty", &"by_chain"])
	assert_bool(_beat.lantern.is_busy()).is_false()


func test_chatter_plays_each_moment_once_in_order_without_overlapping() -> void:
	_beat.sibling.hush()
	_quicken(_beat.lantern)
	var overlaps: Array[StringName] = []
	_beat.cue_played.connect(func(moment: StringName) -> void:
		# When a moment begins, its own first line is the one showing: the
		# last moment had finished.
		var first: String = HomeWaters.lines_for(moment)[0].text
		if _beat.lantern.saying != first or _beat.sibling.is_busy():
			overlaps.append(moment))

	# Row out by stages: off the jetty, past the chain, in sight of the buoy.
	_place(Vector2(28, 10))
	await physics_ticks(_runner, 5)
	_place(BESIDE_THE_CHAIN)
	await physics_ticks(_runner, 5)
	_place(NEAR_THE_BUOY)
	await physics_ticks(_runner, 600)
	# Back to the jetty and out again: nothing is said twice.
	_place(Vector2(28, 29))
	await physics_ticks(_runner, 5)
	_place(NEAR_THE_BUOY)
	await physics_ticks(_runner, 200)

	assert_array(_beat.played).is_equal([HomeWaters.SIBLING, &"left_jetty", &"out_quarter",
			&"out_half", &"by_chain", &"buoy_sighted", &"out_most"])
	assert_array(_beat.waiting).is_empty()
	assert_array(overlaps).is_empty()


func test_reached_buoy_fires_once_and_only_alongside() -> void:
	var arrivals: Array[bool] = []
	_beat.reached_buoy.connect(func() -> void: arrivals.append(true))

	_place(NEAR_THE_BUOY)
	await physics_ticks(_runner, 10)
	assert_array(arrivals).is_empty()
	assert_bool(_beat.ending.visible).is_false()

	_place(ALONGSIDE)
	await physics_ticks(_runner, 10)
	_place(NEAR_THE_BUOY)
	await physics_ticks(_runner, 10)
	_place(ALONGSIDE)
	await physics_ticks(_runner, 10)

	assert_array(arrivals).is_equal([true])
	assert_bool(_beat.at_buoy).is_true()
	assert_bool(_beat.ending.visible).is_true()
	assert_bool(_beat.boat.controls_enabled).is_false()


func test_the_island_wall_stops_the_boat() -> void:
	var island: Vector2 = Vector2(0, 70)
	# Just off the wall, bow towards the island.
	_place(Vector2(0, 24))
	_beat.boat.heading = PI

	await walk(_runner, "move_up", 420)

	var boat: Vector3 = _beat.boat.global_position
	var from_island: float = Vector2(boat.x, boat.z).distance_to(island)
	# It reached the wall and stopped there, rather than rowing ashore.
	assert_float(from_island).is_greater_equal(43.99)
	assert_float(from_island).is_less(45.0)


func test_the_wall_round_the_buoy_stops_the_boat() -> void:
	# Don't end the beat alongside, so the boat rows on into the buoy.
	_beat.alongside_distance = 0.0
	_place(Vector2(-10, -132))
	_beat.boat.heading = PI
	await walk(_runner, "move_up", 300)

	var boat: Vector3 = _beat.boat.global_position
	assert_float(Vector2(boat.x, boat.z).distance_to(Vector2(-10, -120))).is_greater_equal(4.19)


func test_far_out_the_fog_closes_in_and_the_lantern_nudges_you_back() -> void:
	_beat.sibling.hush()
	_beat.nudge_seconds = 0.5
	var home_fog: float = _beat.world.environment.fog_density

	_place(FAR_OUT)
	await physics_ticks(_runner, 60)

	assert_bool(_beat.played.has(HomeWaters.TOO_FAR) or _beat.waiting.has(HomeWaters.TOO_FAR)) \
			.is_true()
	assert_float(_beat.world.environment.fog_density).is_greater(home_fog * 4.0)


func test_near_the_buoy_there_is_no_nudge() -> void:
	_beat.sibling.hush()
	_beat.nudge_seconds = 0.5

	_place(NEAR_THE_BUOY)
	await physics_ticks(_runner, 120)

	assert_bool(_beat.played.has(HomeWaters.TOO_FAR) or _beat.waiting.has(HomeWaters.TOO_FAR)) \
			.is_false()
	assert_float(_beat.fog_at(_beat.boat.global_position)).is_equal(0.0)


func test_a_nudge_waiting_its_turn_is_dropped_once_you_turn_back() -> void:
	# The lantern is still talking when the nudge falls due, so it has to wait.
	_beat.sibling.hush()
	_beat.nudge_seconds = 0.5
	_beat.lantern.say("Something long to say, so the nudge has to wait.")
	_place(FAR_OUT)
	await physics_ticks(_runner, 60)
	assert_array(_beat.waiting).contains([HomeWaters.TOO_FAR])

	# You turn back before he finishes: the nudge no longer applies.
	_place(Vector2(28, 29))
	await physics_ticks(_runner, 5)
	assert_array(_beat.waiting).not_contains([HomeWaters.TOO_FAR])

	_beat.lantern.hush()
	await physics_ticks(_runner, 30)
	assert_bool(_beat.played.has(HomeWaters.TOO_FAR)).is_false()


func test_every_moment_has_lines() -> void:
	var moments: Array[StringName] = [&"left_jetty", &"by_chain", &"buoy_sighted", &"at_buoy",
			HomeWaters.TOO_FAR]
	moments.append_array(HomeWaters.DISTANCE_CUES.keys())
	for moment: StringName in moments:
		assert_array(HomeWaters.lines_for(moment)) \
				.override_failure_message("home_waters.dlg: nothing [on %s]" % moment) \
				.is_not_empty()


func test_the_nudges_take_turns() -> void:
	var first: Array[DialogueStep] = HomeWaters.lines_for(HomeWaters.TOO_FAR, 0)
	var second: Array[DialogueStep] = HomeWaters.lines_for(HomeWaters.TOO_FAR, 1)

	assert_str(first[0].text).is_not_equal(second[0].text)


# Puts the boat at [param spot] on the water, at rest.
func _place(spot: Vector2) -> void:
	_beat.boat.global_position = Vector3(spot.x, 0.0, spot.y)
	_beat.boat.velocity = Vector2.ZERO


# Makes [param speaker] say each line in a moment, so tests needn't wait.
func _quicken(speaker: Speaker) -> void:
	speaker.base_seconds = 0.05
	speaker.seconds_per_letter = 0.0
	speaker.pause_seconds = 0.02
	speaker.bubble.fade_seconds = 0.02
