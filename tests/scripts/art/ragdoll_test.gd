extends GameTestSuite
## Tests for the physics that lets a body go limp: every limb the skeleton
## has gets a physics body lying along it and jointed to the one above, the
## hips and chest get one to hang the limbs from, bones that aren't there
## are left out, and the arm that's holding on can be kept out of it.
##
## The skeleton here is a small made-up one with the same bone names as the
## characters', so the test runs without the art packs.


func test_every_limb_and_both_anchors_get_a_body() -> void:
	var skeleton: Skeleton3D = _new_skeleton()

	var ragdoll: PhysicalBoneSimulator3D = Ragdoll.build(skeleton)

	assert_object(ragdoll.get_parent()).is_same(skeleton)
	for bone: StringName in Ragdoll.ANCHORS:
		assert_object(Ragdoll.body_of(ragdoll, bone)).override_failure_message(
				"no body for %s" % bone).is_not_null()
	for bone: StringName in Ragdoll.LIMBS:
		assert_object(Ragdoll.body_of(ragdoll, bone)).override_failure_message(
				"no body for %s" % bone).is_not_null()
	assert_int(ragdoll.get_child_count()).is_equal(Ragdoll.ANCHORS.size() + Ragdoll.LIMBS.size())


func test_a_limbs_body_is_as_long_as_the_bone_and_drifts_like_something_in_water() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	var ragdoll: PhysicalBoneSimulator3D = Ragdoll.build(skeleton)

	var thigh: PhysicalBone3D = Ragdoll.body_of(ragdoll, &"thigh_l")
	var capsule: CapsuleShape3D = (thigh.get_child(0) as CollisionShape3D).shape as CapsuleShape3D

	# The made-up thigh is 0.4 long.
	assert_float(capsule.height).is_equal_approx(0.4, 0.001)
	assert_float(thigh.gravity_scale).is_less(0.1)
	assert_float(thigh.linear_damp).is_greater(1.0)
	assert_float(thigh.angular_damp).is_greater(1.0)
	# It passes through everything: only its joint holds it.
	assert_int(thigh.collision_layer).is_equal(0)
	assert_int(thigh.collision_mask).is_equal(0)
	assert_int(thigh.joint_type).is_equal(PhysicalBone3D.JOINT_TYPE_CONE)


func test_bones_the_skeleton_doesnt_have_are_left_out() -> void:
	var skeleton: Skeleton3D = Skeleton3D.new()
	auto_free(skeleton)
	add_child(skeleton)
	var hips: int = skeleton.add_bone("pelvis")
	var spine: int = skeleton.add_bone("spine_01")
	skeleton.set_bone_parent(spine, hips)
	skeleton.set_bone_rest(spine, Transform3D(Basis.IDENTITY, Vector3(0, 0.2, 0)))

	var ragdoll: PhysicalBoneSimulator3D = Ragdoll.build(skeleton)

	assert_int(ragdoll.get_child_count()).is_equal(1)
	assert_object(Ragdoll.body_of(ragdoll, &"pelvis")).is_not_null()
	assert_object(Ragdoll.body_of(ragdoll, &"thigh_l")).is_null()


func test_limp_is_every_limb_and_never_the_hips_or_chest() -> void:
	var bones: Array[StringName] = Ragdoll.limp_bones(false)

	assert_int(bones.size()).is_equal(Ragdoll.LIMBS.size())
	assert_bool(bones.has(&"thigh_r")).is_true()
	assert_bool(bones.has(&"upperarm_l")).is_true()
	assert_bool(bones.has(&"pelvis")).is_false()
	assert_bool(bones.has(&"spine_03")).is_false()


func test_the_arm_thats_holding_on_stays_posed() -> void:
	var bones: Array[StringName] = Ragdoll.limp_bones(true)

	assert_bool(bones.has(&"upperarm_l")).is_false()
	assert_bool(bones.has(&"lowerarm_l")).is_false()
	# The other arm, and everything else, is still limp.
	assert_bool(bones.has(&"upperarm_r")).is_true()
	assert_bool(bones.has(&"calf_l")).is_true()
	assert_int(bones.size()).is_equal(Ragdoll.LIMBS.size() - 2)


func test_going_limp_and_back_starts_and_stops_the_physics() -> void:
	var skeleton: Skeleton3D = _new_skeleton()
	var ragdoll: PhysicalBoneSimulator3D = Ragdoll.build(skeleton)
	assert_bool(ragdoll.is_simulating_physics()).is_false()

	ragdoll.physical_bones_start_simulation(Ragdoll.limp_bones(false))
	assert_bool(ragdoll.is_simulating_physics()).is_true()

	ragdoll.physical_bones_stop_simulation()
	assert_bool(ragdoll.is_simulating_physics()).is_false()


# A skeleton with the characters' bone names: hips, a spine up to a head,
# two arms and two legs, each bone a little way from its parent.
func _new_skeleton() -> Skeleton3D:
	var skeleton: Skeleton3D = Skeleton3D.new()
	auto_free(skeleton)
	add_child(skeleton)
	var chain: Array[Array] = [
		["pelvis", "", Vector3(0, 1.0, 0)],
		["spine_01", "pelvis", Vector3(0, 0.15, 0)],
		["spine_03", "spine_01", Vector3(0, 0.3, 0)],
		["neck_01", "spine_03", Vector3(0, 0.2, 0)],
		["Head", "neck_01", Vector3(0, 0.1, 0)],
	]
	for side: String in ["l", "r"]:
		var out: float = -1.0 if side == "l" else 1.0
		chain.append(["upperarm_" + side, "spine_03", Vector3(0.2 * out, 0.15, 0)])
		chain.append(["lowerarm_" + side, "upperarm_" + side, Vector3(0.3 * out, 0, 0)])
		chain.append(["hand_" + side, "lowerarm_" + side, Vector3(0.25 * out, 0, 0)])
		chain.append(["thigh_" + side, "pelvis", Vector3(0.1 * out, -0.05, 0)])
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
