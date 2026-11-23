extends GameTestSuite
## Tests for holding up a gift without a chest (#152): the captain's frying
## pan. "@hold_up frying_pan" holds it over your head, "@put_away" lowers it
## and puts the camera back on the shot it had, and the camera for it never
## ends up through a wall.


func test_a_gift_is_held_up_without_a_chest() -> void:
	var setup: Array = _build()
	var player: Player3D = setup[0]
	var conversation: Conversation = setup[1]
	var cues: ChestCues = setup[2]
	var runner: GdUnitSceneRunner = setup[3]
	await physics_ticks(runner, 2)

	play_cutscene(conversation, player, "~ start\n@hold_up frying_pan\nnarrator: You got it!")
	await physics_ticks(runner, 80)

	assert_object(cues.treasure()).is_not_null()


func test_putting_it_away_goes_back_to_the_shot_before() -> void:
	var setup: Array = _build()
	var player: Player3D = setup[0]
	var conversation: Conversation = setup[1]
	var cues: ChestCues = setup[2]
	var runner: GdUnitSceneRunner = setup[3]
	var before: Marker3D = new_marker(player.get_parent(), &"shots", "Before",
			Transform3D(Basis.IDENTITY, Vector3(0, 2, 4)))
	await physics_ticks(runner, 2)
	player.camera_rig.hold_shot(before, true)

	play_cutscene(conversation, player,
			"~ start\n@hold_up frying_pan\n@put_away\nnarrator: Anyway.")
	await physics_ticks(runner, 80)

	assert_object(cues.treasure()).is_null()
	assert_object(player.camera_rig.held_shot()).is_same(before)


func test_the_gift_camera_stops_short_of_a_wall() -> void:
	var setup: Array = _build()
	var player: Player3D = setup[0]
	var cues: ChestCues = setup[2]
	var runner: GdUnitSceneRunner = setup[3]
	player.get_parent().add_child(static_box(Vector3(4, 4, 0.2), Vector3(0, 2, -1.5)))
	await physics_ticks(runner, 2)

	var at: Vector3 = cues.clear_of_walls(Vector3(0, 1.75, 0), Vector3(0, 1.75, -3))

	assert_float(at.z).is_greater(-1.4)


func test_nothing_in_the_way_leaves_the_camera_where_it_wants() -> void:
	var setup: Array = _build()
	var cues: ChestCues = setup[2]
	var runner: GdUnitSceneRunner = setup[3]
	await physics_ticks(runner, 2)

	var at: Vector3 = cues.clear_of_walls(Vector3(0, 1.75, 0), Vector3(0, 1.75, -3))

	assert_object(at).is_equal(Vector3(0, 1.75, -3))


# A player on a floor with a conversation and the chest cues. Returns
# [player, conversation, cues, runner].
func _build() -> Array:
	var player: Player3D = new_player_3d_on_floor()
	var conversation: Conversation = new_conversation(player)
	var cues: ChestCues = ChestCues.new()
	cues.player = player
	player.get_parent().add_child(cues)
	return [player, conversation, cues, scene_runner(player.get_parent())]
