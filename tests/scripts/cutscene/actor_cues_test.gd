extends GameTestSuite
## Tests for putting people where a cutscene needs them: onto a mark, facing
## someone, out of the scene and back, and home to their usual spot.
##
## The player stands at the origin with the heron at their usual spot, 3 m
## ahead (at -Z).

const HERON: PackedScene = preload("res://scenes/prototype/people/heron.tscn")
const AHEAD: Vector3 = Vector3(0, 0, -3)
## The mark: 4 m to the right, turned a quarter turn left (facing -X).
const MARK: Transform3D = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(4, 0, 0))
const NEAR: Vector3 = Vector3(0.01, 0.01, 0.01)

var _player: Player3D
var _heron: Crewmate
var _conversation: Conversation
var _actors: ActorCues


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_place_stands_someone_on_the_mark_facing_its_way() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@place heron doorway\nheron: Hm.")

	assert_vector(_heron.global_position).is_equal_approx(MARK.origin, NEAR)
	assert_float(_heron.global_rotation.y).is_equal_approx(PI / 2.0, 0.01)


func test_place_moves_the_player_and_stops_them() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	_player.velocity = Vector3(3, 0, 0)

	play_cutscene(_conversation, _player, "@place player doorway\nheron: Hm.")

	assert_vector(_player.global_position).is_equal_approx(MARK.origin, NEAR)
	assert_vector(_player.velocity).is_equal(Vector3.ZERO)
	var model: Node3D = _player.get_node("Model") as Node3D
	assert_float(angle_difference(model.global_rotation.y, PI / 2.0)).is_equal_approx(0.0, 0.01)


func test_hide_takes_someone_out_of_the_scene_and_show_brings_them_back() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@hide heron\nheron: Gone.\n@show heron\nheron: Back.")
	await physics_ticks(runner, 3)
	assert_bool(_heron.is_present()).is_false()
	assert_bool(_heron.visible).is_false()
	# Out of the physics world too: nothing ahead to be stopped by.
	assert_bool(_ray_ahead_hits_something()).is_false()

	_conversation.press()
	await physics_ticks(runner, 3)
	assert_bool(_heron.is_present()).is_true()
	assert_bool(_ray_ahead_hits_something()).is_true()


func test_home_sends_someone_back_to_their_usual_spot_and_shows_them() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player,
			"@hide heron\n@place heron doorway\n@home heron\nheron: Hm.")

	assert_vector(_heron.global_position).is_equal_approx(AHEAD, NEAR)
	assert_bool(_heron.is_present()).is_true()


func test_face_turns_someone_towards_someone_else() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var model: Node3D = _heron.get_node("Model") as Node3D

	play_cutscene(_conversation, _player,
			"@place heron doorway\n@face heron player\nheron: Hm.")
	await physics_ticks(runner, 60)

	# From the mark (4 m to the right) the player is along -X: forward for a
	# quarter turn left, which is how the mark already faces.
	assert_float(angle_difference(model.global_rotation.y, PI / 2.0)).is_equal_approx(0.0, 0.02)


func test_face_turns_the_player_towards_a_mark() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var model: Node3D = _player.get_node("Model") as Node3D

	play_cutscene(_conversation, _player, "@face player doorway\nheron: Hm.")

	# The mark is along +X: a quarter turn right.
	assert_float(angle_difference(model.global_rotation.y, -PI / 2.0)).is_equal_approx(0.0, 0.01)


func test_a_prop_can_be_shown_hidden_and_placed_like_anyone_else() -> void:
	_build()
	var prop: Node3D = Node3D.new()
	prop.name = "ReachingBoathook"
	prop.visible = false
	prop.add_to_group(ActorCues.PROPS)
	_player.get_parent().add_child(prop)
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	assert_object(_actors.find_actor("reaching_boathook")).is_same(prop)

	play_cutscene(_conversation, _player,
			"@show reaching_boathook\n@place reaching_boathook doorway\nheron: There.\n"
			+ "@hide reaching_boathook\nheron: Gone.")
	assert_bool(prop.visible).is_true()
	assert_vector(prop.global_position).is_equal_approx(MARK.origin, NEAR)

	_conversation.press()
	assert_bool(prop.visible).is_false()


func test_someone_who_isnt_aboard_is_warned_about_and_nothing_happens() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	await assert_error(func() -> void:
		_actors.handle(&"hide", PackedStringArray(["nobody"]))) \
			.is_push_warning(any_string())

	assert_bool(_heron.is_present()).is_true()


func test_a_mark_that_isnt_there_is_warned_about_and_nobody_moves() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	await assert_error(func() -> void:
		_actors.handle(&"place", PackedStringArray(["heron", "nowhere"]))) \
			.is_push_warning(any_string())

	assert_vector(_heron.global_position).is_equal_approx(AHEAD, NEAR)


func test_it_finds_people_by_name_and_marks_in_snake_case() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 2)

	assert_object(_actors.find_actor("heron")).is_same(_heron)
	assert_object(_actors.find_actor("player")).is_same(_player)
	assert_object(_actors.find_actor("lantern")).is_null()
	assert_object(_actors.find_mark("doorway")).is_not_null()
	assert_object(_actors.find_mark("galley")).is_null()


# Whether a ray from above the player's feet straight ahead hits a body
# within 5 m: the heron, when they're about.
func _ray_ahead_hits_something() -> bool:
	var space: PhysicsDirectSpaceState3D = _player.get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			Vector3(0, 1, -0.6), Vector3(0, 1, -5))
	query.exclude = [_player.get_rid()]
	return not space.intersect_ray(query).is_empty()


# The player, the heron ahead at their usual spot, a mark to the right, a conversation and the actor cues. Called at the start of each
# test, so everything is made (and freed) inside it.
func _build() -> void:
	_player = new_player_3d_on_floor()
	var world: Node = _player.get_parent()
	_heron = HERON.instantiate() as Crewmate
	_heron.position = AHEAD
	world.add_child(_heron)
	var usual: Marker3D = Marker3D.new()
	usual.position = AHEAD
	world.add_child(usual)
	var station: CrewStation = CrewStation.new()
	station.night_spot = usual
	_heron.add_child(station)
	new_marker(world, ActorCues.GROUP, "Doorway", MARK)
	_conversation = new_conversation(_player)
	_actors = ActorCues.new()
	_actors.player = _player
	world.add_child(_actors)
