extends GameTestSuite
## Tests for the head turning to look at a point after the animation has
## posed it ([HeadLook]): all the way, part-way, never past what a neck
## manages, and moving nothing else.
##
## The skeleton is a small made-up one: hips, a chest, a head facing +Z,
## and two legs hanging straight down.

const NEAR: Vector3 = Vector3(0.01, 0.01, 0.01)


func test_the_head_turns_to_face_what_it_watches() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	var up_and_left: Vector3 = _joint(skeleton, "Head") + Vector3(-1.0, 1.0, 1.0)

	HeadLook.look(skeleton, &"Head", up_and_left, 1.0)

	assert_vector(_facing(skeleton)).is_equal_approx(Vector3(-1.0, 1.0, 1.0).normalized(), NEAR)


func test_asked_for_half_the_head_turns_half_way() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	# Straight up: a quarter turn from facing forwards.
	var above: Vector3 = _joint(skeleton, "Head") + Vector3(0.0, 1.0, 0.0)

	HeadLook.look(skeleton, &"Head", above, 0.5)

	assert_float(_facing(skeleton).angle_to(Vector3.BACK)).is_equal_approx(PI * 0.25, 0.01)


func test_a_neck_only_turns_so_far() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	# Directly behind and a little up: more than any neck manages.
	var behind: Vector3 = _joint(skeleton, "Head") + Vector3(0.0, 0.2, -1.0)

	HeadLook.look(skeleton, &"Head", behind, 1.0, Vector3.BACK, 1.0)

	assert_float(_facing(skeleton).angle_to(Vector3.BACK)).is_equal_approx(1.0, 0.01)


func test_turning_the_head_moves_nothing_else() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	var foot: Vector3 = _joint(skeleton, "foot_l")
	var head: Vector3 = _joint(skeleton, "Head")

	HeadLook.look(skeleton, &"Head", Vector3(-3, 3, 1), 1.0)

	assert_vector(_joint(skeleton, "foot_l")).is_equal_approx(foot, NEAR)
	assert_vector(_joint(skeleton, "Head")).is_equal_approx(head, NEAR)


func test_a_head_that_isnt_there_is_left_alone() -> void:
	var skeleton: Skeleton3D = _new_skeleton()

	HeadLook.look(skeleton, &"antenna", Vector3(-3, 3, 1), 1.0)

	assert_vector(_facing(skeleton)).is_equal_approx(Vector3.BACK, NEAR)


# Where [param bone]'s joint is, in the skeleton's own space.
func _joint(skeleton: Skeleton3D, bone: String) -> Vector3:
	return skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin


# Which way the head faces, in the skeleton's own space.
func _facing(skeleton: Skeleton3D) -> Vector3:
	return skeleton.get_bone_global_pose(skeleton.find_bone("Head")).basis * Vector3.BACK


# Hips at 0.9 with a chest and head above, and two legs straight down:
# thighs 0.4 long, shins 0.4.
func _new_skeleton() -> Skeleton3D:
	var skeleton: Skeleton3D = Skeleton3D.new()
	auto_free(skeleton)
	add_child(skeleton)
	var chain: Array[Array] = [
		["pelvis", "", Vector3(0, 0.9, 0)],
		["spine_03", "pelvis", Vector3(0, 0.4, 0)],
		["Head", "spine_03", Vector3(0, 0.3, 0)],
	]
	for side: String in ["l", "r"]:
		var out: float = -1.0 if side == "l" else 1.0
		chain.append(["thigh_" + side, "pelvis", Vector3(0.1 * out, 0, 0)])
		chain.append(["calf_" + side, "thigh_" + side, Vector3(0, -0.4, 0)])
		chain.append(["foot_" + side, "calf_" + side, Vector3(0, -0.4, 0)])
	for entry: Array in chain:
		var bone_name: String = entry[0]
		var parent_name: String = entry[1]
		var offset: Vector3 = entry[2]
		var bone: int = skeleton.add_bone(bone_name)
		if not parent_name.is_empty():
			skeleton.set_bone_parent(bone, skeleton.find_bone(parent_name))
		skeleton.set_bone_rest(bone, Transform3D(Basis.IDENTITY, offset))
	skeleton.reset_bone_poses()
	return skeleton
