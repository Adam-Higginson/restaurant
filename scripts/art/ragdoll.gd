class_name Ragdoll
extends RefCounted
## Builds the physics that lets a character's body go limp: a ragdoll.
##
## A skeleton's bones are normally posed by an animation. A
## [PhysicalBoneSimulator3D] can take some of them over instead: each gets
## a [PhysicalBone3D], a small physics body jointed to the one above it, and
## while it's "simulating" the physics engine decides where it hangs, not
## the animation. The bones we don't simulate (the hips and chest, here)
## still follow the animation and whatever moves the character, and the
## limp limbs are jointed to them, so they trail after wherever the body is
## taken: sinking, or hauled up by one arm.
##
## It's made for bodies in water: the limbs are almost weightless and
## heavily damped, so they stay roughly as they were when the body went
## limp, drift a little, and lag behind when it's moved, instead of dropping.

## The bones the limbs hang from, each with the bone at its far end. These
## get a physics body but are never simulated: they stay where the
## animation puts them.
const ANCHORS: Dictionary[StringName, StringName] = {
	&"pelvis": &"spine_01",
	&"spine_03": &"neck_01",
}
## The bones that go limp, each with the bone at its far end, parents before
## children.
const LIMBS: Dictionary[StringName, StringName] = {
	&"neck_01": &"Head",
	&"upperarm_l": &"lowerarm_l",
	&"lowerarm_l": &"hand_l",
	&"upperarm_r": &"lowerarm_r",
	&"lowerarm_r": &"hand_r",
	&"thigh_l": &"calf_l",
	&"calf_l": &"foot_l",
	&"thigh_r": &"calf_r",
	&"calf_r": &"foot_r",
}
## The bones of the arm that can be kept posed while the rest is limp: the
## one that's holding on to something.
const HOLDING_ARM: Array[StringName] = [&"upperarm_l", &"lowerarm_l"]
## How far a limp joint can swing and twist, in degrees.
const SWING_DEGREES: float = 80.0
const TWIST_DEGREES: float = 35.0
## How strongly a limb falls (1 is as on land) and how quickly its movement
## dies away: slow and heavy, as in water.
const GRAVITY_SCALE: float = 0.025
const LINEAR_DAMP: float = 4.0
const ANGULAR_DAMP: float = 6.0


## Gives [param skeleton] the physics for going limp, as a child of it, and
## returns it. Bones the skeleton doesn't have are left out. Nothing is
## limp until its [method PhysicalBoneSimulator3D.physical_bones_start_simulation]
## is called with [method limp_bones].
static func build(skeleton: Skeleton3D) -> PhysicalBoneSimulator3D:
	var simulator: PhysicalBoneSimulator3D = PhysicalBoneSimulator3D.new()
	simulator.name = "Ragdoll"
	skeleton.add_child(simulator)
	for bone: StringName in ANCHORS:
		_add_bone(skeleton, simulator, bone, ANCHORS[bone])
	for bone: StringName in LIMBS:
		_add_bone(skeleton, simulator, bone, LIMBS[bone])
	return simulator


## The bones to simulate: all the limp ones, or all but the arm that's
## holding on if [param holding_on].
static func limp_bones(holding_on: bool) -> Array[StringName]:
	var bones: Array[StringName] = []
	for bone: StringName in LIMBS:
		if holding_on and HOLDING_ARM.has(bone):
			continue
		bones.append(bone)
	return bones


## The physics body made for [param bone] in [param simulator], or null.
static func body_of(simulator: PhysicalBoneSimulator3D, bone: StringName) -> PhysicalBone3D:
	for child: Node in simulator.get_children():
		var body: PhysicalBone3D = child as PhysicalBone3D
		if body == null:
			continue
		# The name is a property Godot adds as it runs, so it's asked for by name.
		var its_bone: String = body.get(&"bone_name")
		if its_bone == String(bone):
			return body
	return null


# A physics body for [param bone]: a capsule lying along it, from its own
# joint to the joint of [param tip], jointed to whatever body is above it.
static func _add_bone(skeleton: Skeleton3D, simulator: PhysicalBoneSimulator3D,
		bone: StringName, tip: StringName) -> void:
	var tip_index: int = skeleton.find_bone(tip)
	if skeleton.find_bone(bone) < 0 or tip_index < 0:
		return
	# Where the far end is, from this bone's own joint.
	var reach: Vector3 = skeleton.get_bone_rest(tip_index).origin
	var half_length: float = maxf(reach.length() * 0.5, 0.01)
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.height = half_length * 2.0
	capsule.radius = minf(half_length * 0.25, half_length)
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.shape = capsule
	# A capsule stands along Y; the body's own forward is -Z, along the bone.
	shape.transform = Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)),
			Vector3.ZERO)
	var up: Vector3 = Vector3.UP
	if up.cross(reach).is_zero_approx():
		up = Vector3.BACK
	var along: Basis = Basis.looking_at(reach, up)
	var body: PhysicalBone3D = PhysicalBone3D.new()
	body.name = "Limp %s" % bone
	body.add_child(shape)
	body.set(&"bone_name", String(bone))
	# The body sits half-way along the bone, and its joint back at the bone's start.
	body.body_offset = Transform3D(along, along * Vector3(0, 0, -half_length))
	body.joint_offset = Transform3D(Basis.IDENTITY, Vector3(0, 0, half_length))
	body.joint_type = PhysicalBone3D.JOINT_TYPE_CONE
	body.set(&"joint_constraints/swing_span", SWING_DEGREES)
	body.set(&"joint_constraints/twist_span", TWIST_DEGREES)
	body.gravity_scale = GRAVITY_SCALE
	body.linear_damp = LINEAR_DAMP
	body.angular_damp = ANGULAR_DAMP
	body.mass = 1.0
	# Limbs pass through everything: only their joints hold them.
	body.collision_layer = 0
	body.collision_mask = 0
	simulator.add_child(body)
