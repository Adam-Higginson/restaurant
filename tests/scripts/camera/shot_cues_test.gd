extends GameTestSuite
## Tests for camera work in conversations: a script's @shot glides the camera
## to a named shot and holds it, @shot free or the conversation ending gives
## it back, and a conversation without one never moves the camera.

const NEAR: Vector3 = Vector3(0.05, 0.05, 0.05)
## The shot: 3 m up, a quarter turn left (looking along -X).
const SHOT: Transform3D = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(0, 3, 0))

var _player: Player3D
var _rig: CameraRig
var _conversation: Conversation
var _cues: ShotCues
var _marker: Marker3D


func test_hold_shot_glides_to_the_shot_and_release_glides_back() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var camera: Camera3D = _rig.get_node("Camera3D") as Camera3D
	var free: Vector3 = camera.global_position

	_rig.hold_shot(_marker)
	await physics_ticks(runner, 30)
	assert_bool(_rig.is_fixed).is_true()
	assert_vector(camera.global_position).is_equal_approx(SHOT.origin, NEAR)

	_rig.release_shot()
	await physics_ticks(runner, 30)
	assert_bool(_rig.is_fixed).is_false()
	assert_vector(camera.global_position).is_equal_approx(free, NEAR)


func test_the_camera_cant_be_turned_while_a_shot_is_held() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	_rig.hold_shot(_marker)
	var yaw: float = _rig.yaw

	await walk(runner, "camera_right", 20)

	assert_float(_rig.yaw).is_equal_approx(yaw, 0.001)


func test_a_held_shot_wins_over_a_zone_and_gives_way_to_it_after() -> void:
	_build()
	var zone_shot: Transform3D = Transform3D(Basis.IDENTITY, Vector3(5, 4, 5))
	var zone: CameraZone = new_camera_zone(Vector3(2, 2, 2), Vector3(15, 1, 15), zone_shot)
	_player.get_parent().add_child(zone)
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var camera: Camera3D = _rig.get_node("Camera3D") as Camera3D
	_rig.enter_zone(zone)
	await physics_ticks(runner, 30)

	_rig.hold_shot(_marker)
	await physics_ticks(runner, 5)
	assert_vector(camera.global_position).is_equal_approx(SHOT.origin, NEAR)

	_rig.release_shot()
	await physics_ticks(runner, 5)
	assert_vector(camera.global_position).is_equal_approx(zone.shot.global_position, NEAR)


func test_a_scripts_shot_cue_holds_the_named_shot_until_the_talk_ends() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var camera: Camera3D = _rig.get_node("Camera3D") as Camera3D

	_begin("@shot stove_nook\nheron: Hm.")
	await physics_ticks(runner, 30)
	assert_vector(camera.global_position).is_equal_approx(SHOT.origin, NEAR)

	_conversation.stop()
	assert_bool(_rig.is_fixed).is_false()


func test_shot_free_gives_the_camera_back_mid_talk() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	_begin("@shot stove_nook\nheron: One.\n@shot free\nheron: Two.")
	assert_bool(_rig.is_fixed).is_true()

	_conversation.press()

	assert_bool(_conversation.is_active()).is_true()
	assert_bool(_rig.is_fixed).is_false()


func test_a_cut_goes_straight_to_the_shot_and_straight_back() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var camera: Camera3D = _rig.get_node("Camera3D") as Camera3D
	var free: Vector3 = camera.global_position

	# Two ticks is far too short for a glide (12 ticks here): only a cut
	# gets there.
	_begin("@shot stove_nook cut
heron: One.
@shot free cut
heron: Two.")
	await physics_ticks(runner, 2)
	assert_vector(camera.global_position).is_equal_approx(SHOT.origin, NEAR)

	_conversation.press()
	await physics_ticks(runner, 2)
	assert_bool(_rig.is_fixed).is_false()
	assert_vector(camera.global_position).is_equal_approx(free, NEAR)


func test_without_cut_the_camera_is_still_gliding_two_ticks_later() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var camera: Camera3D = _rig.get_node("Camera3D") as Camera3D

	_begin("@shot stove_nook
heron: One.")
	await physics_ticks(runner, 2)

	assert_float(camera.global_position.distance_to(SHOT.origin)).is_greater(0.5)


func test_a_talk_with_no_shot_never_touches_the_camera() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var camera: Camera3D = _rig.get_node("Camera3D") as Camera3D
	var before: Transform3D = camera.global_transform

	_begin("heron: One.\nheron: Two.")
	await physics_ticks(runner, 20)

	assert_bool(_rig.is_fixed).is_false()
	assert_vector(camera.global_position).is_equal_approx(before.origin, NEAR)


func test_you_can_still_turn_the_camera_in_an_ordinary_talk() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	_begin("heron: One.\nheron: Two.")

	await walk(runner, "camera_right", 20)

	assert_float(_rig.yaw).is_less(-0.1)


func test_a_shot_that_isnt_there_is_warned_about_and_does_nothing() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	await assert_error(func() -> void:
		_cues.handle(ShotCues.CUE, PackedStringArray(["nowhere"]))) \
			.is_push_warning(any_string())

	assert_bool(_rig.is_fixed).is_false()


func test_other_cues_are_ignored() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	_cues.handle(&"music", PackedStringArray(["stove_nook"]))

	assert_bool(_rig.is_fixed).is_false()


func test_find_shot_matches_a_markers_name_in_snake_case() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 2)

	assert_object(_cues.find_shot("stove_nook")).is_same(_marker)
	assert_object(_cues.find_shot("galley")).is_null()


func _begin(script: String) -> void:
	var tree: DialogueTree = DialogueScript.parse(script, &"test")
	assert_array(tree.errors).is_empty()
	assert_bool(_conversation.begin_tree(tree, _player)).is_true()


# The player, a conversation, the shot cues and one shot marker. Called at
# the start of each test, so everything is made (and freed) inside it.
func _build() -> void:
	_player = new_player_3d_on_floor()
	_rig = _player.get_node("CameraRig") as CameraRig
	_rig.blend_seconds = 0.2
	var world: Node = _player.get_parent()
	_conversation = Conversation.new()
	world.add_child(_conversation)
	_cues = ShotCues.new()
	_cues.player = _player
	world.add_child(_cues)
	_marker = Marker3D.new()
	_marker.name = "StoveNook"
	_marker.transform = SHOT
	_marker.add_to_group(ShotCues.GROUP)
	world.add_child(_marker)
