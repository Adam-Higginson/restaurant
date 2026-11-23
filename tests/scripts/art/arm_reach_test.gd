extends GameTestSuite
## Tests for lifting one arm towards a point: the upper arm and then the
## forearm turn so the hand lies on the line to the target, part-way if
## asked, and nothing else in the body moves.
##
## The skeleton here is a small made-up one with the characters' arm bones,
## hanging straight down at rest.

const NEAR: Vector3 = Vector3(0.01, 0.01, 0.01)


func test_the_arm_swings_to_point_at_the_target() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	var target: Vector3 = Vector3(-2.0, 1.5, 0.0)

	ArmReach.aim(skeleton, &"upperarm_l", &"lowerarm_l", target, 1.0)
	ArmReach.aim(skeleton, &"lowerarm_l", &"hand_l", target, 1.0)

	# Shoulder, elbow and wrist now lie along the line to the target.
	var shoulder: Vector3 = _joint(skeleton, "upperarm_l")
	var towards: Vector3 = (target - shoulder).normalized()
	assert_vector((_joint(skeleton, "lowerarm_l") - shoulder).normalized()) \
			.is_equal_approx(towards, NEAR)
	assert_vector((_joint(skeleton, "hand_l") - shoulder).normalized()) \
			.is_equal_approx(towards, NEAR)
	# And it's still the same arm: nothing has stretched.
	assert_float(_joint(skeleton, "hand_l").distance_to(shoulder)).is_equal_approx(0.55, 0.001)


func test_asked_for_half_it_goes_half_way() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	var shoulder: Vector3 = _joint(skeleton, "upperarm_l")
	# Straight out to the side: a quarter turn from hanging straight down.
	var target: Vector3 = shoulder + Vector3(-1.0, 0.0, 0.0)

	ArmReach.aim(skeleton, &"upperarm_l", &"lowerarm_l", target, 0.5)

	var arm: Vector3 = (_joint(skeleton, "lowerarm_l") - shoulder).normalized()
	assert_float(arm.angle_to(Vector3.DOWN)).is_equal_approx(PI * 0.25, 0.01)


func test_asked_for_nothing_the_arm_stays_where_the_animation_put_it() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	var before: Vector3 = _joint(skeleton, "hand_l")

	ArmReach.aim(skeleton, &"upperarm_l", &"lowerarm_l", Vector3(-2, 2, 1), 0.0)

	assert_vector(_joint(skeleton, "hand_l")).is_equal_approx(before, NEAR)


func test_only_the_arm_moves() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	var chest: Vector3 = _joint(skeleton, "spine_03")
	var other_hand: Vector3 = _joint(skeleton, "hand_r")

	ArmReach.aim(skeleton, &"upperarm_l", &"lowerarm_l", Vector3(-2, 2, 1), 1.0)
	ArmReach.aim(skeleton, &"lowerarm_l", &"hand_l", Vector3(-2, 2, 1), 1.0)

	assert_vector(_joint(skeleton, "spine_03")).is_equal_approx(chest, NEAR)
	assert_vector(_joint(skeleton, "hand_r")).is_equal_approx(other_hand, NEAR)
	assert_vector(_joint(skeleton, "upperarm_l")).is_equal_approx(Vector3(-0.2, 1.4, 0), NEAR)


func test_a_bone_that_isnt_there_is_left_alone() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	var before: Vector3 = _joint(skeleton, "hand_l")

	ArmReach.aim(skeleton, &"tail", &"hand_l", Vector3(-2, 2, 1), 1.0)
	ArmReach.aim(skeleton, &"upperarm_l", &"wing", Vector3(-2, 2, 1), 1.0)

	assert_vector(_joint(skeleton, "hand_l")).is_equal_approx(before, NEAR)


func test_it_knows_how_far_the_arm_can_reach() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	var reach: ArmReach = ArmReach.new()
	skeleton.add_child(reach)

	assert_float(reach.arm_length(skeleton)).is_equal_approx(0.55, 0.001)


func test_as_part_of_a_skeleton_it_lifts_the_arm_each_frame() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	var reach: ArmReach = ArmReach.new()
	skeleton.add_child(reach)
	var shoulder: Vector3 = _joint(skeleton, "upperarm_l")
	reach.target = skeleton.to_global(shoulder + Vector3(-1.0, 1.0, 0.0))
	reach.amount = 1.0
	# The skeleton says when it has finished posing itself for the frame,
	# modifiers and all: that's the moment to look.
	var seen: Array[Vector3] = []
	skeleton.skeleton_updated.connect(func() -> void:
		seen.append((_joint(skeleton, "hand_l") - shoulder).normalized()))

	# Anything that moves a bone makes the skeleton pose itself again.
	skeleton.set_bone_pose_position(0, Vector3(0, 1.4, 0.0001))
	await get_tree().process_frame
	await get_tree().process_frame

	assert_bool(seen.is_empty()).is_false()
	assert_vector(seen[0]).is_equal_approx(Vector3(-1.0, 1.0, 0.0).normalized(),
			Vector3(0.02, 0.02, 0.02))


# Where [param bone]'s joint is, in the skeleton's own space.
func _joint(skeleton: Skeleton3D, bone: String) -> Vector3:
	return skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin


# A chest with two arms hanging straight down: each upper arm 0.3 long and
# each forearm 0.25.
func _new_skeleton() -> Skeleton3D:
	var skeleton: Skeleton3D = Skeleton3D.new()
	auto_free(skeleton)
	add_child(skeleton)
	var chain: Array[Array] = [["spine_03", "", Vector3(0, 1.4, 0)]]
	for side: String in ["l", "r"]:
		var out: float = -1.0 if side == "l" else 1.0
		chain.append(["upperarm_" + side, "spine_03", Vector3(0.2 * out, 0, 0)])
		chain.append(["lowerarm_" + side, "upperarm_" + side, Vector3(0, -0.3, 0)])
		chain.append(["hand_" + side, "lowerarm_" + side, Vector3(0, -0.25, 0)])
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
