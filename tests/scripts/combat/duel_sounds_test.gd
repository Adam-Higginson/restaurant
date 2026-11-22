extends GameTestSuite
## Tests for DuelSounds and CrabSounds: each thing that happens in a duel
## plays its sound, and nothing else does. (What they sound like isn't
## tested.)
##
## The player stands at the origin facing -Z with the crab just ahead. Its
## first hit lands about tick 49, and it's open from about tick 64.

const PAN: Item = preload("res://data/items/frying_pan.tres")
const SOUND_DIR: String = "res://assets/audio/combat/"
const SOUND_SETS: Array[String] = ["swing", "slice", "tink", "pan_up", "clang", "hurt",
		"crab_click", "crab_lunge", "fog_clear"]
const CLOSE: Vector3 = Vector3(0, 0, -1.3)
const FIRST_HIT: int = 56
const FIRST_OPENING: int = 70 + HitStop.HURT_TICKS


# --- The recordings --------------------------------------------------------------

func test_every_sound_has_recordings_to_pick_from() -> void:
	for set_name: String in SOUND_SETS:
		var sound: AudioStreamRandomizer = load(SOUND_DIR + set_name + ".tres") \
				as AudioStreamRandomizer
		assert_object(sound).override_failure_message("%s.tres didn't load" % set_name) \
				.is_not_null()
		assert_int(sound.streams_count).is_greater(1)
		for i: int in sound.streams_count:
			assert_object(sound.get_stream(i)).override_failure_message(
					"%s.tres: recording %d is missing" % [set_name, i]).is_not_null()
		# Never the same recording twice running.
		assert_int(sound.playback_mode).is_equal(
				AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS)


func test_the_recordings_come_with_their_licences() -> void:
	for licence: String in ["LICENSE-Kenney-Impact-Sounds.txt", "LICENSE-Kenney-RPG-Audio.txt"]:
		assert_str(FileAccess.get_file_as_string(SOUND_DIR + licence)) \
				.contains("Creative Commons Zero")


func test_every_sound_node_has_its_stream() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: FogCrab = new_fog_crab(player, Vector3(0, 0, -20))
	scene_runner(player.get_parent())

	for sound: StringName in [DuelSounds.SWING, DuelSounds.SLICE, DuelSounds.TINK,
			DuelSounds.PAN_UP, DuelSounds.CLANG, DuelSounds.HURT] as Array[StringName]:
		var node: AudioStreamPlayer = _sounds(player).get_node(NodePath(sound)) \
				as AudioStreamPlayer
		assert_object(node.stream).override_failure_message("%s has no stream" % sound) \
				.is_not_null()
	for sound: StringName in [CrabSounds.CLICK, CrabSounds.LUNGE, CrabSounds.CLEAR] \
			as Array[StringName]:
		var node: AudioStreamPlayer3D = _crab_sounds(crab).get_node(NodePath(sound)) \
				as AudioStreamPlayer3D
		assert_object(node.stream).override_failure_message("%s has no stream" % sound) \
				.is_not_null()


# --- The player's sounds ---------------------------------------------------------

func test_a_swing_at_nothing_whooshes_and_no_more() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	duellist_of(player).strike()

	assert_int(_sounds(player).times_played(DuelSounds.SWING)).is_equal(1)
	assert_int(_sounds(player).times_played(DuelSounds.SLICE)).is_equal(0)
	assert_int(_sounds(player).times_played(DuelSounds.TINK)).is_equal(0)


func test_a_strike_that_counts_slices() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	new_fog_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, FIRST_OPENING)

	duellist_of(player).strike()

	assert_int(_sounds(player).times_played(DuelSounds.SWING)).is_equal(1)
	assert_int(_sounds(player).times_played(DuelSounds.SLICE)).is_equal(1)
	assert_int(_sounds(player).times_played(DuelSounds.TINK)).is_equal(0)


func test_a_strike_on_a_crab_that_isnt_open_tinks() -> void:
	var player: Player3D = new_player_3d_on_floor()
	new_fog_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 20)

	duellist_of(player).strike()

	assert_int(_sounds(player).times_played(DuelSounds.SWING)).is_equal(1)
	assert_int(_sounds(player).times_played(DuelSounds.TINK)).is_equal(1)
	assert_int(_sounds(player).times_played(DuelSounds.SLICE)).is_equal(0)


func test_a_hit_that_lands_thumps_and_doesnt_clang() -> void:
	var player: Player3D = new_player_3d_on_floor()
	new_fog_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	await physics_ticks(runner, FIRST_HIT)

	assert_int(duellist_of(player).hearts.halves).is_equal(5)
	assert_int(_sounds(player).times_played(DuelSounds.HURT)).is_equal(1)
	assert_int(_sounds(player).times_played(DuelSounds.CLANG)).is_equal(0)


func test_a_parry_that_lands_clangs_and_doesnt_thump() -> void:
	var player: Player3D = new_player_3d_on_floor()
	new_fog_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.toolbar.add(ItemInstance.new(PAN))
	# The crab's first hit lands at 0.8 s: raise the pan at 0.67 s.
	await physics_ticks(runner, 40)

	duellist_of(player).raise_pan()
	assert_int(_sounds(player).times_played(DuelSounds.PAN_UP)).is_equal(1)
	assert_int(_sounds(player).times_played(DuelSounds.CLANG)).is_equal(0)
	await physics_ticks(runner, FIRST_HIT - 40)

	assert_int(_sounds(player).times_played(DuelSounds.CLANG)).is_equal(1)
	assert_int(_sounds(player).times_played(DuelSounds.HURT)).is_equal(0)


func test_raising_the_pan_at_nothing_never_clangs() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.toolbar.add(ItemInstance.new(PAN))
	await physics_ticks(runner, 2)

	duellist_of(player).raise_pan()
	await physics_ticks(runner, 30)

	assert_int(_sounds(player).times_played(DuelSounds.PAN_UP)).is_equal(1)
	assert_int(_sounds(player).times_played(DuelSounds.CLANG)).is_equal(0)


func test_without_a_pan_the_parry_button_is_silent() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	duellist_of(player).raise_pan()

	assert_int(_sounds(player).times_played(DuelSounds.PAN_UP)).is_equal(0)


# --- The crab's sounds -----------------------------------------------------------

func test_the_crabs_claws_rattle_faster_as_it_rears_up() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: FogCrab = new_fog_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	# The first half of the windup, then the second.
	await physics_ticks(runner, 24)
	var early: int = _crab_sounds(crab).times_played(CrabSounds.CLICK)
	await physics_ticks(runner, 23)
	var late: int = _crab_sounds(crab).times_played(CrabSounds.CLICK) - early

	assert_int(crab.cycle.state).is_equal(CrabCycle.State.WINDUP)
	assert_int(early).is_greater(0)
	assert_int(late).is_greater(early)


func test_the_rattle_stops_when_it_lunges_and_the_lunge_is_heard() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: FogCrab = new_fog_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 47)
	assert_int(_crab_sounds(crab).times_played(CrabSounds.LUNGE)).is_equal(0)

	await physics_ticks(runner, 5)
	var clicks: int = _crab_sounds(crab).times_played(CrabSounds.CLICK)
	await physics_ticks(runner, 40)

	assert_int(_crab_sounds(crab).times_played(CrabSounds.LUNGE)).is_equal(1)
	# Lunging and open, it's quiet.
	assert_bool(crab.cycle.is_open()).is_true()
	assert_int(_crab_sounds(crab).times_played(CrabSounds.CLICK)).is_equal(clicks)


func test_a_far_off_crab_is_silent() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: FogCrab = new_fog_crab(player, Vector3(0, 0, -20))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	await physics_ticks(runner, 120)

	assert_int(_crab_sounds(crab).times_played(CrabSounds.CLICK)).is_equal(0)
	assert_int(_crab_sounds(crab).times_played(CrabSounds.LUNGE)).is_equal(0)


func test_clearing_the_fog_chimes_once_and_it_ticks_away() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	var crab: FogCrab = new_fog_crab(player, CLOSE)
	crab.strikes_to_clear = 1
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, FIRST_OPENING)

	duellist_of(player).strike()
	var clicks: int = _crab_sounds(crab).times_played(CrabSounds.CLICK)
	# It shakes itself off for a second, then wanders.
	await physics_ticks(runner, 180)

	assert_bool(crab.is_cleared()).is_true()
	assert_int(_crab_sounds(crab).times_played(CrabSounds.CLEAR)).is_equal(1)
	assert_int(_crab_sounds(crab).times_played(CrabSounds.CLICK)).is_greater(clicks)


func test_the_wandering_tick_is_quieter_than_the_rattle() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	var crab: FogCrab = new_fog_crab(player, CLOSE)
	crab.strikes_to_clear = 1
	var click: AudioStreamPlayer3D = _crab_sounds(crab).get_node("Click") as AudioStreamPlayer3D
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 40)
	var rattle_db: float = click.volume_db
	await physics_ticks(runner, FIRST_OPENING - 40)

	duellist_of(player).strike()
	await physics_ticks(runner, 180)

	assert_float(click.volume_db).is_less(rattle_db)


func _sounds(player: Player3D) -> DuelSounds:
	return player.get_node("DuelSounds") as DuelSounds


func _crab_sounds(crab: FogCrab) -> CrabSounds:
	return crab.get_node("Sounds") as CrabSounds
