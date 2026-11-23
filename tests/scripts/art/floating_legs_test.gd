extends GameTestSuite
## Tests for legs that hang as they do in water instead of standing
## ([FloatingLegs]): thighs swing, knees bend, it all drifts slowly, and
## nothing above the hips moves.
##
## The skeleton is a small made-up one: hips, a chest, a head, and two
## legs hanging straight down.

const NEAR: Vector3 = Vector3(0.01, 0.01, 0.01)


func test_a_swung_thigh_carries_the_leg_backwards() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	var hip: Vector3 = _joint(skeleton, "thigh_l")

	FloatingLegs.swing(skeleton, &"thigh_l", 0.5)

	# The knee has gone back (-Z: the body faces +Z) and come up a little.
	var knee: Vector3 = _joint(skeleton, "calf_l")
	assert_float(knee.z).is_less(hip.z - 0.1)
	assert_float(knee.y).is_greater(hip.y - 0.4)
	assert_float(knee.distance_to(hip)).is_equal_approx(0.4, 0.001)


func test_a_bent_knee_lifts_the_foot_behind() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	var before: Vector3 = _joint(skeleton, "foot_l")

	FloatingLegs.swing(skeleton, &"calf_l", 0.7)

	var foot: Vector3 = _joint(skeleton, "foot_l")
	assert_float(foot.z).is_less(before.z - 0.1)
	assert_float(foot.y).is_greater(before.y)
	# The knee itself hasn't moved.
	assert_vector(_joint(skeleton, "calf_l")).is_equal_approx(Vector3(-0.1, 0.5, 0), NEAR)


func test_the_legs_drift_slowly_one_way_and_back() -> void:
	var legs: FloatingLegs = auto_free(FloatingLegs.new())
	legs.drift = 0.1
	legs.drift_seconds = 4.0

	assert_float(legs.drift_now(0.0)).is_equal_approx(0.0, 0.001)
	assert_float(legs.drift_now(1.0)).is_equal_approx(0.1, 0.001)
	assert_float(legs.drift_now(3.0)).is_equal_approx(-0.1, 0.001)
	legs.drift_seconds = 0.0
	assert_float(legs.drift_now(1.0)).is_equal(0.0)


func test_afloat_the_legs_no_longer_hang_straight_and_the_body_is_untouched() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	var legs: FloatingLegs = FloatingLegs.new()
	skeleton.add_child(legs)
	var chest: Vector3 = _joint(skeleton, "spine_03")
	var seen: Array[Vector3] = []
	var chests: Array[Vector3] = []
	skeleton.skeleton_updated.connect(func() -> void:
		seen.append(_joint(skeleton, "foot_r") - _joint(skeleton, "thigh_r"))
		chests.append(_joint(skeleton, "spine_03")))

	# Anything that moves a bone makes the skeleton pose itself again.
	skeleton.set_bone_pose_position(0, Vector3(0, 0.9, 0.0001))
	await get_tree().process_frame
	await get_tree().process_frame

	assert_bool(seen.is_empty()).is_false()
	# A standing leg is straight down from the hip; this one isn't.
	assert_float(seen[0].normalized().angle_to(Vector3.DOWN)).is_greater(0.1)
	assert_vector(chests[0]).is_equal_approx(chest, NEAR)


# Where [param bone]'s joint is, in the skeleton's own space.
func _joint(skeleton: Skeleton3D, bone: String) -> Vector3:
	return skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin


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
