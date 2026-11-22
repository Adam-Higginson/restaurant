extends GameTestSuite
## Tests for Clang: it has recordings to play, never plays the same one
## twice running, and rings when a parry lands and only then.

const PAN: Item = preload("res://data/items/frying_pan.tres")
const CLOSE: Vector3 = Vector3(0, 0, -1.3)


func test_it_has_several_recordings_and_each_one_loaded() -> void:
	assert_int(Clang.SOUNDS.size()).is_greater(1)
	for sound: AudioStream in Clang.SOUNDS:
		assert_object(sound).is_not_null()
		# A knock, not a loop or a long ring.
		assert_float(sound.get_length()).is_between(0.05, 2.0)


func test_the_recordings_come_with_their_licence() -> void:
	var licence: String = FileAccess.get_file_as_string(
			"res://assets/audio/combat/LICENSE-Kenney.txt")

	assert_str(licence).contains("Creative Commons Zero")


func test_the_same_recording_never_plays_twice_running() -> void:
	# Rolled a different one: that's what plays.
	assert_int(Clang.next_index(0, 3, 5)).is_equal(3)
	# Rolled the same one again: the next one plays, wrapping at the end.
	assert_int(Clang.next_index(3, 3, 5)).is_equal(4)
	assert_int(Clang.next_index(4, 4, 5)).is_equal(0)
	# Nothing has played yet.
	assert_int(Clang.next_index(-1, 2, 5)).is_equal(2)
	# With only one recording there's no choice.
	assert_int(Clang.next_index(0, 0, 1)).is_equal(0)


func test_a_parry_that_lands_rings_the_pan() -> void:
	var player: Player3D = new_player_3d_on_floor()
	new_fog_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.toolbar.add(ItemInstance.new(PAN))
	# The crab's first hit lands at 0.8 s: raise the pan at 0.67 s.
	await physics_ticks(runner, 40)

	duellist_of(player).raise_pan()
	assert_int(_clang(player).times_rung).is_equal(0)
	await physics_ticks(runner, 16)

	assert_int(_clang(player).times_rung).is_equal(1)
	assert_array(Clang.SOUNDS).contains([_clang(player).stream])


func test_raising_the_pan_at_nothing_makes_no_sound() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.toolbar.add(ItemInstance.new(PAN))
	await physics_ticks(runner, 2)

	duellist_of(player).raise_pan()
	await physics_ticks(runner, 30)

	assert_int(_clang(player).times_rung).is_equal(0)


func test_a_hit_that_lands_makes_no_clang() -> void:
	var player: Player3D = new_player_3d_on_floor()
	new_fog_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	await physics_ticks(runner, 56)

	assert_int(duellist_of(player).hearts.halves).is_equal(5)
	assert_int(_clang(player).times_rung).is_equal(0)


func _clang(player: Player3D) -> Clang:
	return player.get_node("Clang") as Clang
