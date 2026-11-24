extends GameTestSuite
## Tests for putting people where a cutscene needs them: onto a mark, facing
## someone, out of the scene and back, and home to their usual spot. And the
## lantern: put on a mark, floated to another, and let go.
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


func test_walk_waits_until_they_get_there() -> void:
	_build()
	_add_walkways()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var lines: Array[int] = [0]
	_conversation.line_said.connect(func(_speaker: Person) -> void: lines[0] += 1)

	play_cutscene(_conversation, _player, "@walk heron doorway\nheron: Hm.")
	await physics_ticks(runner, 60)
	assert_int(lines[0]).is_equal(0)
	assert_float(_heron.global_position.distance_to(MARK.origin)).is_greater(1.0)

	await physics_ticks(runner, 6 * 60)
	assert_vector(_heron.global_position).is_equal_approx(MARK.origin, NEAR)
	assert_int(lines[0]).is_equal(1)


func test_send_sets_them_off_and_the_script_goes_on() -> void:
	_build()
	_add_walkways()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var lines: Array[int] = [0]
	_conversation.line_said.connect(func(_speaker: Person) -> void: lines[0] += 1)
	var walker: CrewWalker = _heron.get_node("Walker") as CrewWalker

	play_cutscene(_conversation, _player, "@send heron doorway\nheron: Off I go.")

	assert_int(lines[0]).is_equal(1)
	assert_bool(walker.is_walking).is_true()


func test_walk_home_walks_back_to_their_usual_spot() -> void:
	_build()
	_add_walkways()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@place heron doorway\n@walk heron home\nheron: Back.")

	await physics_ticks(runner, 7 * 60)

	assert_vector(_heron.global_position).is_equal_approx(AHEAD, NEAR)


func test_placing_someone_who_was_walking_stops_their_walk() -> void:
	_build()
	_add_walkways()
	var stage: Vector3 = Vector3(-3, 0, 0)
	new_marker(_player.get_parent(), ActorCues.GROUP, "Stage", Transform3D(Basis(), stage))
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var walker: CrewWalker = _heron.get_node("Walker") as CrewWalker

	# On his way to the door when the cutscene wants him elsewhere.
	play_cutscene(_conversation, _player,
			"@send heron doorway
@wait 0.3
@place heron stage
heron: Here.")
	await physics_ticks(runner, 90)

	assert_bool(walker.is_walking).is_false()
	assert_vector(_heron.global_position).is_equal_approx(stage, NEAR)


func test_skipping_a_walk_puts_them_there_at_once() -> void:
	_build()
	_add_walkways()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@walk heron doorway\nheron: Hm.")
	_conversation.skip()
	await physics_ticks(runner, 2)

	assert_vector(_heron.global_position).is_equal_approx(MARK.origin, NEAR)
	assert_bool(_conversation.is_active()).is_false()


func test_someone_who_cant_walk_is_warned_about_and_stays_put() -> void:
	_build()
	_add_walkways()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@walk player doorway\nheron: Hm.")

	assert_vector(_player.global_position).is_equal_approx(Vector3.ZERO, Vector3(0.1, 0.2, 0.1))


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
	assert_object(_actors.find_actor("lantern")).is_same(_player.get_node("LanternSpirit"))
	assert_object(_actors.find_actor("albatross")).is_null()
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


func test_the_lantern_can_be_put_beside_you_floated_off_and_let_go() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	var spirit: LanternSpirit = _player.get_node("LanternSpirit") as LanternSpirit
	var middle: Marker3D = new_marker(_player.get_parent(), ActorCues.GROUP, "RoomMiddle",
			Transform3D(Basis.IDENTITY, Vector3(1, 1.5, 2)))
	await physics_ticks(runner, 3)

	# Placed, he's simply there, and stays.
	play_cutscene(_conversation, _player,
			"@place lantern doorway
heron: Hm.
@go lantern room_middle
heron: Go on.
"
			+ "@home lantern
heron: Off you go.")
	assert_object(spirit.held).is_not_null()
	assert_float(spirit.global_position.distance_to(MARK.origin)).is_less(0.15)
	await physics_ticks(runner, 30)
	assert_float(spirit.global_position.distance_to(MARK.origin)).is_less(0.15)

	# Sent on, he floats there: not at once, but soon.
	_conversation.press()
	await physics_ticks(runner, 1)
	assert_object(spirit.held).is_same(middle)
	assert_float(spirit.global_position.distance_to(middle.global_position)).is_greater(2.0)
	await physics_ticks(runner, 90)
	assert_float(spirit.global_position.distance_to(middle.global_position)).is_less(0.2)

	# Let go, he's back to your shoulder.
	_conversation.press()
	await physics_ticks(runner, 90)
	assert_object(spirit.held).is_null()
	var shoulder: Vector3 = LanternSpirit.follow_spot(_player.global_position, _player.facing,
			spirit.follow_offset)
	assert_float(spirit.global_position.distance_to(shoulder)).is_less(0.3)


func test_only_the_lantern_can_be_floated_somewhere() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var was: Vector3 = _heron.global_position

	play_cutscene(_conversation, _player, "@go heron doorway
heron: Hm.")

	assert_vector(_heron.global_position).is_equal_approx(was, NEAR)


func test_hiding_the_player_hides_their_body_but_not_the_lantern() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	var body: Node3D = _player.get_node("Model") as Node3D
	var spirit: LanternSpirit = _player.get_node("LanternSpirit") as LanternSpirit
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@hide player
heron: Asleep.
@show player
heron: Up.")
	await physics_ticks(runner, 3)
	assert_bool(body.visible).is_false()
	assert_bool(spirit.is_visible_in_tree()).is_true()

	_conversation.press()
	await physics_ticks(runner, 3)
	assert_bool(body.visible).is_true()


func test_when_it_ends_your_body_shows_and_the_lantern_is_let_go() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	var spirit: LanternSpirit = _player.get_node("LanternSpirit") as LanternSpirit
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@hide player
@place lantern doorway
heron: Hm.")
	_conversation.press()
	await physics_ticks(runner, 3)

	assert_bool(_conversation.is_active()).is_false()
	assert_bool((_player.get_node("Model") as Node3D).visible).is_true()
	assert_object(spirit.held).is_null()


# The player, the heron ahead at their usual spot, a mark to the right, a conversation and the actor cues. Called at the start of each
# test, so everything is made (and freed) inside it.
# Walkways from the heron's usual spot straight to the mark, so he can walk.
func _add_walkways() -> void:
	var walkways: Walkways = Walkways.new()
	var start: Waypoint = Waypoint.new()
	start.name = "Usual"
	start.position = AHEAD
	start.links = [&"Mark"]
	walkways.add_child(start)
	var end: Waypoint = Waypoint.new()
	end.name = "Mark"
	end.position = MARK.origin
	walkways.add_child(end)
	_player.get_parent().add_child(walkways)


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
