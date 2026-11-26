class_name CharacterModel
extends Node3D
## The player's body: a Quaternius character put together from pack files
## and animated, standing in for the greybox capsule when the files are there.
## Or, when the look has one ([member CharacterParts.whole]), a whole Meshy
## character in its outfit, playing its own clips ([method _build_whole]).
##
## Which character depends on who the player is ([member GameState.look]):
## [member boy] or [member girl], each a [CharacterParts] list of files. They
## all share one humanoid skeleton, so this
## - loads the outfit, which brings the skeleton,
## - adds the head (cut off a base character's body, as the outfits want),
##   the hair and the eyebrows onto that same skeleton,
## - copies the animations from the [member animation_files] onto it
##   (rotations only, so the animation library's mannequin doesn't stretch our
##   proportions), and
## - makes them younger: a bigger head on a shorter body.
## Then each frame it picks what to play from what the player is doing: idle,
## walk, charge or parry ([method pose_for]). A cut of the knife plays as a
## one-off action ([method act]): its stretch of its animation, sped up to fit
## the cut, then its recovery if nothing else follows.
##
## The files live in the gitignored assets/third_party/. If any are missing
## (a fresh clone, CI), the [member stand_ins] stay and nothing else changes:
## gameplay never depends on the model. The look is rebuilt if it changes.

## Emitted after the model is built or taken down. [param shown] says
## whether the character is showing (true) or the greybox is (false).
signal dressed(shown: bool)

## What the player can be doing, each with its own animation.
enum Pose {
	IDLE,
	WALK,
	## A cut of the knife (each cut names its own animation).
	STRIKE,
	PARRY,
	## Holding the knife ready while a fillet charges.
	CHARGE,
	## Coming back to rest after the last cut of a chain.
	RECOVER,
	## A sidehop, backflip or roll.
	DODGE,
}

## The toe joints, which the feet are planted by.
const TOE_BONES: PackedStringArray = ["ball_l", "ball_r"]
## The bones the head is cut from the base character's body by.
const HEAD_BONES: PackedStringArray = ["Head", "neck_01"]
## Bones whose position the animations may move (the whole body's sway and
## bob). Every other bone only turns, keeping our proportions.
const MOVING_BONES: PackedStringArray = ["root", "pelvis"]
## The animation library's name on the [AnimationPlayer].
const LIBRARY: StringName = &"moves"
## The still pose held while holding something up, made from a moment of
## [member hold_up_animation] (see [method still_of]).
const HOLD_UP_STILL: StringName = &"Hold_Up_Still"
## The whole character's (Meshy's) name for each bone this script and its
## helpers ask for by the packs' names.
const WHOLE_BONES: Dictionary[String, String] = {
	"ball_l": "LeftToeBase", "ball_r": "RightToeBase",
	"hand_l": "LeftHand", "hand_r": "RightHand",
	"lowerarm_l": "LeftForeArm", "lowerarm_r": "RightForeArm",
	"upperarm_l": "LeftArm", "upperarm_r": "RightArm",
	"clavicle_l": "LeftShoulder", "clavicle_r": "RightShoulder",
	"pelvis": "Hips",
	"thigh_l": "LeftUpLeg", "thigh_r": "RightUpLeg",
	"calf_l": "LeftLeg", "calf_r": "RightLeg",
	"foot_l": "LeftFoot", "foot_r": "RightFoot",
}
## Poses a whole character has no clip for, made here ([method _pose_clip])
## and filed under the names the game asks for: hanging limp (the castaway
## underwater) and lying flat on its back (asleep in the bunk).
const LIMP_NAMES: PackedStringArray = ["Zombie_Idle", "Swim_Idle"]
const LYING_NAMES: PackedStringArray = ["LayToIdle"]
## How the packs' hands sit at rest, in the skeleton's space (which way each
## hand bone's own x, y and z point, and which way the forearm runs): held
## things are placed for these, so a whole character's hands are turned to
## match ([method _hand_fix]).
const PACK_HAND_RIGHT: Basis = Basis(Vector3(0, 1, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1))
const PACK_HAND_LEFT: Basis = Basis(Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1))
const PACK_FOREARM_RIGHT: Vector3 = Vector3(-1, 0, 0)
const PACK_FOREARM_LEFT: Vector3 = Vector3(1, 0, 0)
## The look a whole character is drawn with.
const WHOLE_STYLE: CharacterStyle = preload("res://data/art/styles/character.tres")
## A whole character's clips that play once; every other loops.
const ONCE_CLIPS: PackedStringArray = ["Sword_Regular", "Sword_Heavy", "Roll", "Jump"]
## How high the hips are that a backflip turns about, in metres, when the
## skeleton doesn't say.
const FLIP_PIVOT_HEIGHT: float = 0.7

## Whether characters are built from the packs at all. Tests turn it off,
## so they run the same with or without the pack files (as in CI), and
## quickly; the character's own tests turn it back on with small stand-in
## files.
static var packs_enabled: bool = true

## The heads already cut from base characters' bodies, by file and mesh, so
## changing look doesn't cut them again.
static var _heads: Dictionary[String, ArrayMesh] = {}

## The boy's parts.
@export var boy: CharacterParts
## The girl's parts.
@export var girl: CharacterParts
## Files holding the animations, on the same skeleton (the Universal
## Animation Library). Later files win when two have the same animation.
@export_file("*.glb", "*.gltf") var animation_files: PackedStringArray = []
## How far through a chop (see [method chop_at]) the knife meets the board.
const CHOP_CONTACT: float = 0.62

## The animation for each [enum Pose].
@export var idle_animation: StringName = &"Idle"
@export var walk_animation: StringName = &"Walk"
## The animation for walking quickly: at [member run_from] metres per second
## or faster, the walk becomes this.
@export var run_animation: StringName = &"Jog_Fwd"
## The walking speed, in metres per second, from which the walk is a run.
@export var run_from: float = 3.0
## The animation for a cut whose own animation isn't in the library.
@export var strike_animation: StringName = &"Sword_Regular_A"
@export var parry_animation: StringName = &"Idle_Shield"
## The animation held while the fillet charges: knife ready.
@export var charge_animation: StringName = &"Sword_Idle"
## How fast a recovery after a cut plays, against normal speed.
@export var recovery_speed: float = 1.4
## Greybox meshes to hide while the character shows.
@export var stand_ins: Array[VisualInstance3D] = []
## The player whose doings pick the pose. Without one it idles.
@export var player: Player3D
## How big the head is, against the body: above 1 reads younger.
@export var head_scale: float = 1.18
## The whole character's size: below 1 is shorter, younger.
@export var body_scale: float = 0.85
## Seconds to blend from one animation into the next.
@export var blend_seconds: float = 0.12
## An animation to be held still on instead of idling, [member held_at]
## seconds in: someone asleep ([code]LayToIdle[/code] at 0 is lying flat).
## Empty to idle as usual.
@export var held_animation: StringName = &""
@export var held_at: float = 0.0
## Whether the character's eyes are shut: asleep, or out cold. A clip can
## move it.
@export var eyes_shut: bool = false:
	set(value):
		eyes_shut = value
		_show_eyes()
## Something for the left arm to reach for. Optional.
@export var reach_for: Node3D
## How far the left arm has lifted towards [member reach_for], leaving the
## rest of the body as it is: 0 not at all, 1 reaching (see [ArmReach]). A
## clip can move it.
@export_range(0.0, 1.0) var reach: float = 0.0:
	set(value):
		reach = clampf(value, 0.0, 1.0)
		if _arm != null:
			_arm.amount = reach
## How far the left hand has closed, holding something: 0 as the animation
## has it, 1 holding (see [ArmReach]). A clip can move it.
@export_range(0.0, 1.0) var hand_grip: float = 0.0:
	set(value):
		hand_grip = clampf(value, 0.0, 1.0)
		if _arm != null:
			_arm.grip = hand_grip
## How far both arms are raised over the head, holding something up for all
## to see (a treasure from a chest): 0 as the animation has them, 1 held up.
## A character with a [member hold_up_animation] (a Meshy cheer) strikes
## that pose as it rises, and goes back to standing as it falls; one
## without lifts its arms straight up ([ArmReach]), the hands open.
@export_range(0.0, 1.0) var hold_up: float = 0.0:
	set(value):
		var was: float = hold_up
		hold_up = clampf(value, 0.0, 1.0)
		var posed: bool = has_hold_up_pose()
		for arm: ArmReach in _lifts:
			arm.amount = 0.0 if posed else hold_up
		if posed and hold_up > was and not _held_up:
			_strike_hold_up(true)
		elif posed and hold_up < was and _held_up:
			_strike_hold_up(false)
## Where the hands meet when held up, above the head, in metres: how high
## over the head bone, how far in front of it, and how far apart the hands are.
@export var hold_up_height: float = 0.6
@export var hold_up_forward: float = 0.14
@export var hold_up_spread: float = 0.17
## The clip whose pose is held while holding something up (the whole
## character's "Cheer with Both Hands"), how far into it, in seconds,
## and how long the arms take to go up into it and come down from it.
@export var hold_up_animation: StringName = &"Hold_Up"
## The stance at a chopping board (#207): leaning in over it, head down, the
## left hand steadying the food, small cuts going on. Played round and round
## in place of the idle while [member chopping]; a Meshy text-to-motion clip
## on the whole character, so the greybox and packs keep their idle.
@export var chop_animation: StringName = &"Chop"
@export var hold_up_at: float = 0.3
@export var hold_up_blend: float = 0.6
## Something for the head to turn towards. Optional.
@export var watch: Node3D
## How far the head has turned towards [member watch], leaving the rest of
## the body as it is: 0 not at all, 1 looking at it (see [HeadLook]). A clip
## can move it.
@export_range(0.0, 1.0) var head_turn: float = 0.0:
	set(value):
		head_turn = clampf(value, 0.0, 1.0)
		if _head != null:
			_head.amount = head_turn
## How much the legs hang as they do in water instead of standing: 0 the
## animation's own legs, 1 floating (see [FloatingLegs]).
@export_range(0.0, 1.0) var afloat: float = 0.0:
	set(value):
		afloat = clampf(value, 0.0, 1.0)
		if _legs != null:
			_legs.amount = afloat
## Parts to build instead of the player's own look ([member boy] or
## [member girl]), e.g. for a preview.
@export var parts_override: CharacterParts
## Leave a whole character's clothes off, so it shows in what its model
## was made in (the boy's underwear): the castaway, pulled from the sea.
@export var undressed: bool = false

## Whether the character stands at a chopping board, chopping: the idle
## becomes the [member chop_animation]. Set by the board ([Counter3D]).
var chopping: bool = false
## The character, or null while the greybox shows.
var character: Node3D = null
## The character's skeleton, or null.
var skeleton: Skeleton3D = null
## The pose being played.
var pose: Pose = Pose.IDLE
## The character's right hand, which holds the knife, or null.
var right_hand: Node3D = null
## The character's left hand, which holds the pan, or null.
var left_hand: Node3D = null

var _animator: AnimationPlayer = null
## Whether the character showing is a whole one (Meshy), and its parts.
var _whole: bool = false
## Whether the hold-up pose is struck (see [member hold_up]).
var _held_up: bool = false
var _whole_parts: CharacterParts = null
## A whole character's moves, made once per build.
var _whole_moves: AnimationLibrary = null
## How each of a whole character's hand nodes is turned from its hand bone.
var _hand_fixes: Dictionary[Node3D, Basis] = {}
var _hand_bones: Dictionary[Node3D, int] = {}
## A whole character's meshes and its hips bone, for the rounded shading's
## line (which follows the body as it lies down or bends).
var _whole_meshes: Array[MeshInstance3D] = []
## A whole character's body meshes its closed eyes are drawn on, and its
## head bone: they're drawn in the head bone's space.
var _eye_bodies: Array[MeshInstance3D] = []
var _whole_head: int = -1
var _whole_hips: int = -1
## What lifts the left arm when it reaches.
var _arm: ArmReach = null
## What lifts both arms when something is held up: the left, then the right.
var _lifts: Array[ArmReach] = []
## What brings the right arm (the knife hand) down in a chop at the board.
var _chop_arm: ArmReach = null
## What turns the head when it watches something.
var _head: HeadLook = null
## What lets the legs hang when afloat.
var _legs: FloatingLegs = null
var _duellist: Duellist = null
## How high a toe joint is when its boot's sole is on the floor, in metres
## above this node: measured from the rest pose when the character is built.
var _toe_height: float = 0.0
## How fast the walk and run animations move their feet, played at normal
## speed, in metres per second: the speed each was made for. Measured when
## built; 0 if there's no such animation.
var _stride_speed: float = 0.0
var _run_stride_speed: float = 0.0
## Seconds left of the action playing (see [method act]), or 0.
var _act_left: float = 0.0
## How fast the action plays, against normal speed.
var _act_speed: float = 1.0
## The recovery to play when the cut playing ends, if nothing follows it.
var _recovery: StringName = &""


func _ready() -> void:
	if player != null:
		_duellist = player.get_node_or_null("Duellist") as Duellist
	if _duellist != null:
		_duellist.cut_started.connect(_on_cut_started)
	if player != null:
		player.dodged.connect(_on_dodged)
	if not Engine.is_editor_hint():
		Game.look_changed.connect(func(_body: PlayerLook.Body) -> void: dress())
	dress()


func _process(delta: float) -> void:
	if _animator == null:
		return
	plant_feet()
	_turn_for_flip()
	if _arm != null and is_instance_valid(reach_for):
		_arm.target = reach_for.global_position
	if _head != null and is_instance_valid(watch):
		_head.target = watch.global_position
	if hold_up > 0.0:
		_aim_lifts()
	# Holding something up, the pose stays struck whatever else happens.
	if _held_up:
		_animator.speed_scale = 1.0
		return
	var walking: bool = player != null and player.is_walking
	var charging: bool = _duellist != null and _duellist.is_charging()
	var parrying: bool = _duellist != null and _duellist.parry.is_active()
	var wanted: Pose = pose_for(walking, false, parrying, charging)
	if _act_left > 0.0:
		_act_left -= delta
		# A recovery gives way to anything else the player does.
		var interrupted: bool = pose == Pose.RECOVER and wanted != Pose.IDLE
		if _act_left > 0.0 and not interrupted:
			_animator.speed_scale = _act_speed
			return
		_act_left = 0.0
		var recovery: StringName = _recovery
		_recovery = &""
		if pose == Pose.STRIKE and wanted == Pose.IDLE and not recovery.is_empty() \
				and act(recovery, 0.0, 0.0, clip_length(recovery) / recovery_speed,
						Pose.RECOVER):
			return
	play(wanted)
	# Walk in step: the walk plays as fast as the feet must go to keep up.
	var speed: float = player.move_speed if player != null else 0.0
	var stride: float = _run_stride_speed if is_running() else _stride_speed
	_animator.speed_scale = walk_playback(speed, stride) if pose == Pose.WALK else 1.0


## Builds the character for who the player is now. Returns whether it's
## showing; if any file is missing the greybox shows instead.
func dress() -> bool:
	_undress()
	var parts: CharacterParts = girl if Game.look == PlayerLook.Body.GIRL else boy
	if parts_override != null:
		parts = parts_override
	if not packs_enabled or parts == null or not parts.is_complete():
		_show_stand_ins(true)
		dressed.emit(false)
		return false
	_build(parts)
	_show_stand_ins(false)
	dressed.emit(true)
	return true


## Raises the character so the lower foot's sole is never below the floor.
## The animations come from a skeleton with other proportions, so without
## this the boots sink into the ground in some poses. It only ever lifts:
## running has moments with both feet in the air, and pulling the body down
## then would drag the feet along the ground.
func plant_feet() -> void:
	if skeleton == null:
		return
	var lowest: float = INF
	for bone_name: String in TOE_BONES:
		var bone: int = skeleton.find_bone(_bone(bone_name))
		if bone < 0:
			return
		var toe: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(bone).origin
		lowest = minf(lowest, to_local(toe).y)
	character.position.y = clampf(character.position.y + _toe_height - lowest, 0.0, 0.2)


## How high the lower foot's sole is above the floor, in metres: 0 when
## planted, never below. For tests.
func sole_height() -> float:
	if skeleton == null:
		return 0.0
	var lowest: float = INF
	for bone_name: String in TOE_BONES:
		var bone: int = skeleton.find_bone(_bone(bone_name))
		var toe: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(bone).origin
		lowest = minf(lowest, to_local(toe).y)
	return lowest - _toe_height


## Plays the animation for [param next], blending from the last, unless it's
## already playing.
func play(next: Pose) -> void:
	if _animator == null:
		return
	var anim: StringName = animation_for(next)
	var full: StringName = StringName("%s/%s" % [LIBRARY, anim])
	if not _animator.has_animation(full):
		return
	if next == pose and _animator.current_animation == String(full):
		return
	pose = next
	if anim == chop_animation:
		_animator.get_animation(full).loop_mode = Animation.LOOP_LINEAR
	_animator.play(full, blend_seconds)


## Plays a one-off action as [param as_pose]: [param length] seconds of the
## animation [param anim_name] from [param from] seconds in (all of the rest
## of it if [param length] is 0), sped up or slowed down to take
## [param seconds]. Nothing else plays until it's done. Returns whether it
## played (not without a character or that animation).
func act(anim_name: StringName, from: float, length: float, seconds: float,
		as_pose: Pose) -> bool:
	if _animator == null or seconds <= 0.0:
		return false
	var full: StringName = StringName("%s/%s" % [LIBRARY, anim_name])
	if not _animator.has_animation(full):
		return false
	if _whole:
		# The stretch was chosen for the packs' animation of this name; a
		# whole character's own clip is played from start to finish.
		from = 0.0
		length = 0.0
	var span: float = length if length > 0.0 else _animator.get_animation(full).length - from
	_animator.play(full, blend_seconds)
	_animator.seek(from, true)
	_act_speed = maxf(span, 0.01) / seconds
	_animator.speed_scale = _act_speed
	_act_left = seconds
	pose = as_pose
	return true


## Whether holding something up strikes a pose from a clip (see
## [member hold_up]), not lifting the arms straight up.
func has_hold_up_pose() -> bool:
	return _animator != null and _animator.has_animation("%s/%s" % [LIBRARY, HOLD_UP_STILL])


## A clip that holds [param clip] still [param at] seconds in: every track
## keeps the one value it has then, looping, so it can be blended into and
## out of like any other move.
static func still_of(clip: Animation, at: float) -> Animation:
	var still: Animation = Animation.new()
	still.length = 0.1
	still.loop_mode = Animation.LOOP_LINEAR
	var when: float = clampf(at, 0.0, clip.length)
	for track: int in clip.get_track_count():
		var kind: Animation.TrackType = clip.track_get_type(track)
		var copy: int = still.add_track(kind)
		still.track_set_path(copy, clip.track_get_path(track))
		match kind:
			Animation.TYPE_POSITION_3D:
				still.position_track_insert_key(copy, 0.0,
						clip.position_track_interpolate(track, when))
			Animation.TYPE_ROTATION_3D:
				still.rotation_track_insert_key(copy, 0.0,
						clip.rotation_track_interpolate(track, when))
			Animation.TYPE_SCALE_3D:
				still.scale_track_insert_key(copy, 0.0, clip.scale_track_interpolate(track, when))
			Animation.TYPE_BLEND_SHAPE:
				still.blend_shape_track_insert_key(copy, 0.0,
						clip.blend_shape_track_interpolate(track, when))
			Animation.TYPE_VALUE:
				still.track_insert_key(copy, 0.0, clip.value_track_interpolate(track, when))
			_:
				still.remove_track(copy)
	return still


## How long the animation [param anim_name] is, in seconds, or 0 if there's
## no such animation.
func clip_length(anim_name: StringName) -> float:
	var full: StringName = StringName("%s/%s" % [LIBRARY, anim_name])
	if _animator == null or not _animator.has_animation(full):
		return 0.0
	return _animator.get_animation(full).length


## Holds the character still [param at] seconds into the animation
## [param anim_name], until something else plays.
## Returns whether there's such an animation.
func hold(anim_name: StringName, at: float) -> bool:
	var full: StringName = StringName("%s/%s" % [LIBRARY, anim_name])
	if _animator == null or not _animator.has_animation(full):
		return false
	_animator.play(full, 0.0)
	_animator.seek(at, true)
	_animator.pause()
	set_process(false)
	return true


## Whether an action is playing (see [method act]).
func is_acting() -> bool:
	return _act_left > 0.0


## Whether walking is quick enough to be a run (see [member run_from]), and
## there's a run to play.
func is_running() -> bool:
	return player != null and player.move_speed >= run_from and _run_stride_speed > 0.0


## The animation played for [param of].
func animation_for(of: Pose) -> StringName:
	match of:
		Pose.WALK:
			# A quick walk is a run, if there's a run to play.
			if is_running() and _animator != null \
					and _animator.has_animation("%s/%s" % [LIBRARY, run_animation]):
				return run_animation
			return walk_animation
		Pose.STRIKE:
			return strike_animation
		Pose.PARRY:
			return parry_animation
		Pose.CHARGE:
			return charge_animation
	if chopping and _animator != null \
			and _animator.has_animation("%s/%s" % [LIBRARY, chop_animation]):
		return chop_animation
	return idle_animation


## How fast to play the walk so its feet keep pace with walking at
## [param speed] metres per second, for a walk made for [param stride_speed]:
## faster than normal for a quicker walk, slower for a slower one. 1 if the
## walk's speed isn't known.
static func walk_playback(speed: float, stride_speed: float) -> float:
	if stride_speed <= 0.0 or speed <= 0.0:
		return 1.0
	return clampf(speed / stride_speed, 0.3, 4.0)


## The speed the walk (or the run, when running) was made for, in metres
## per second (see [method walk_playback]). 0 without a character or a walk.
func stride_speed() -> float:
	return _run_stride_speed if is_running() else _stride_speed


## Chops at [param point] in the world with the knife hand, over
## [param seconds]: the hand lifts above it, strikes down onto it a little
## past halfway ([constant CHOP_CONTACT] of the way through), and goes back
## to where the animation has it. Does nothing without a character.
func chop_at(point: Vector3, seconds: float) -> void:
	if _chop_arm == null or seconds <= 0.0:
		return
	create_tween().tween_method(_set_chop.bind(point), 0.0, 1.0, seconds)


## Where the treasure sits while it's held up: between the two hands as
## they really are (the arms reach towards [method hold_up_point] but stop
## where their length does), a little above them. Without hands, the
## [method hold_up_point].
func held_point() -> Vector3:
	if right_hand == null or left_hand == null:
		return hold_up_point()
	var between: Vector3 = (right_hand.global_position + left_hand.global_position) / 2.0
	return between + Vector3.UP * 0.08


## Where something held up is held, in the world: above the head, a little
## in front (see [member hold_up]). Without a character, over the greybox.
func hold_up_point() -> Vector3:
	var forward: Vector3 = -global_basis.z.normalized()
	if skeleton == null:
		return global_position + Vector3.UP * 2.0 + forward * hold_up_forward
	var head: int = skeleton.find_bone("Head")
	if head == -1:
		return global_position + Vector3.UP * 2.0 + forward * hold_up_forward
	var at: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(head).origin
	return at + Vector3.UP * hold_up_height + forward * hold_up_forward


## What to play: a strike, a charge or a parry wins over walking, and
## walking over standing still.
static func pose_for(walking: bool, striking: bool, parrying: bool,
		charging: bool = false) -> Pose:
	if striking:
		return Pose.STRIKE
	if charging:
		return Pose.CHARGE
	if parrying:
		return Pose.PARRY
	if walking:
		return Pose.WALK
	return Pose.IDLE


## The parts of [param body] moved mostly by the [param keep] bones: the
## head and neck off a whole body. A triangle is kept if every corner's
## strongest bone is one of them. [param skin] names the bones.
static func cut_out(body: ArrayMesh, skin: Skin, keep: PackedStringArray) -> ArrayMesh:
	var cut: ArrayMesh = ArrayMesh.new()
	for surface: int in body.get_surface_count():
		var arrays: Array = body.surface_get_arrays(surface)
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if bones.is_empty() or vertices.is_empty():
			continue
		@warning_ignore("integer_division")
		var per_vertex: int = bones.size() / vertices.size()
		# Which vertices are mostly moved by a kept bone.
		var kept_vertex: PackedByteArray = []
		kept_vertex.resize(vertices.size())
		for vertex: int in vertices.size():
			var strongest: int = 0
			for k: int in per_vertex:
				if weights[vertex * per_vertex + k] > weights[vertex * per_vertex + strongest]:
					strongest = k
			var bind: int = bones[vertex * per_vertex + strongest]
			kept_vertex[vertex] = 1 if keep.has(String(skin.get_bind_name(bind))) else 0
		var kept: PackedInt32Array = []
		for corner: int in range(0, indices.size(), 3):
			var a: int = indices[corner]
			var b: int = indices[corner + 1]
			var c: int = indices[corner + 2]
			if kept_vertex[a] == 1 and kept_vertex[b] == 1 and kept_vertex[c] == 1:
				kept.append_array([a, b, c])
		if kept.is_empty():
			continue
		arrays[Mesh.ARRAY_INDEX] = kept
		# Extra per-vertex data the packs carry and we don't draw.
		for custom: int in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2,
				Mesh.ARRAY_CUSTOM3]:
			arrays[custom] = null
		var flags: int = body.surface_get_format(surface) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		cut.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
		cut.surface_set_material(cut.get_surface_count() - 1, body.surface_get_material(surface))
	return cut


## A copy of [param animation] that moves the skeleton at [param skeleton_path]
## (from the [AnimationPlayer]'s root), with only rotations, plus positions
## for the [constant MOVING_BONES]. Those positions are multiplied by
## [param height_ratio]: our hips' height over the animated skeleton's, so a
## body with longer legs isn't pushed into the floor (or lifted off it).
static func retarget(animation: Animation, skeleton_path: NodePath,
		height_ratio: float = 1.0) -> Animation:
	var copy: Animation = animation.duplicate(true) as Animation
	for track: int in range(copy.get_track_count() - 1, -1, -1):
		var path: NodePath = copy.track_get_path(track)
		var bone: String = String(path.get_concatenated_subnames())
		var kind: Animation.TrackType = copy.track_get_type(track)
		var keeps: bool = kind == Animation.TYPE_ROTATION_3D \
				or (kind == Animation.TYPE_POSITION_3D and MOVING_BONES.has(bone))
		if bone.is_empty() or not keeps:
			copy.remove_track(track)
			continue
		copy.track_set_path(track, NodePath("%s:%s" % [skeleton_path, bone]))
		if kind == Animation.TYPE_POSITION_3D and height_ratio != 1.0:
			for key: int in copy.track_get_key_count(track):
				var at: Vector3 = copy.track_get_key_value(track, key)
				copy.track_set_key_value(track, key, at * height_ratio)
	return copy


## A whole character's (Meshy's) name for the bone the packs call
## [param pack_name]; the name itself if it has no other.
static func whole_bone(pack_name: String) -> String:
	if WHOLE_BONES.has(pack_name):
		return WHOLE_BONES[pack_name]
	return pack_name


## Gives the body meshes among [param meshes] (not the clothes, whose
## names start "Outfit_") [param eyes] to draw shut. Returns the meshes
## they're on, which need telling where the head is; none without eyes.
static func draw_closed_eyes(meshes: Array[MeshInstance3D], eyes: ClosedEyes) -> Array[MeshInstance3D]:
	var drawn: Array[MeshInstance3D] = []
	if eyes == null:
		return drawn
	for mesh_node: MeshInstance3D in meshes:
		if String(mesh_node.name).begins_with("Outfit_") or mesh_node.mesh == null:
			continue
		for surface: int in mesh_node.mesh.get_surface_count():
			var material: ShaderMaterial = mesh_node.get_active_material(surface) as ShaderMaterial
			if material != null:
				eyes.apply(material)
		drawn.append(mesh_node)
	return drawn


## What a whole character built from [param parts] wears: its outfit, or
## nothing over what its model was made in when [param bare].
static func outfit_for(parts: CharacterParts, bare: bool) -> CharacterOutfit:
	return null if bare else parts.whole_outfit


## Whether a whole character's clip for the animation [param anim_name] plays
## once (a strike or a tumble) and doesn't loop.
static func plays_once(anim_name: StringName) -> bool:
	for start: String in ONCE_CLIPS:
		if String(anim_name).begins_with(start):
			return true
	return false


## How high [param skeleton]'s hips are at rest, or 0 if it has none.
static func hip_height(skeleton: Skeleton3D) -> float:
	var hips: int = skeleton.find_bone("pelvis")
	return skeleton.get_bone_global_rest(hips).origin.y if hips >= 0 else 0.0


func _build(parts: CharacterParts) -> void:
	if parts.is_whole():
		_build_whole(parts)
		return
	character = (load(parts.outfit) as PackedScene).instantiate() as Node3D
	add_child(character)
	# The packs face +Z; our forward is -Z.
	character.rotation.y = PI
	character.scale = Vector3.ONE * body_scale
	skeleton = character.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	# Measured on the outfit alone: its boots are what stand on the floor.
	_toe_height = _rest_toe_height()
	_add_head(parts.head_from)
	if not parts.hair.is_empty():
		_add_meshes(parts.hair, parts.hair_colour)
	if not parts.eyebrows.is_empty():
		_add_meshes(parts.eyebrows, parts.hair_colour)
	skeleton.set_bone_pose_scale(skeleton.find_bone("Head"), Vector3.ONE * head_scale)
	_animator = AnimationPlayer.new()
	character.add_child(_animator)
	_animator.add_animation_library(LIBRARY, _library(_animator.get_node(_animator.root_node)))
	# The charge's stance is held as long as the button is: round and round.
	var stance: StringName = StringName("%s/%s" % [LIBRARY, charge_animation])
	if _animator.has_animation(stance):
		_animator.get_animation(stance).loop_mode = Animation.LOOP_LINEAR
	right_hand = _hand("hand_r")
	left_hand = _hand("hand_l")
	_stride_speed = _measure_stride(walk_animation)
	_run_stride_speed = _measure_stride(run_animation)
	_show_eyes()
	_arm = ArmReach.new()
	_arm.name = "ArmReach"
	_arm.amount = reach
	_arm.grip = hand_grip
	skeleton.add_child(_arm)
	_lifts.clear()
	for side: String in ["_l", "_r"]:
		var lift: ArmReach = ArmReach.new()
		lift.name = "HoldUp" + side.to_upper()
		lift.upper_bone = StringName("upperarm" + side)
		lift.lower_bone = StringName("lowerarm" + side)
		lift.hand_bone = StringName("hand" + side)
		lift.shoulder_bone = StringName("clavicle" + side)
		lift.side = side
		lift.amount = hold_up
		skeleton.add_child(lift)
		_lifts.append(lift)
	_chop_arm = ArmReach.new()
	_chop_arm.name = "ChopArm"
	_chop_arm.upper_bone = &"upperarm_r"
	_chop_arm.lower_bone = &"lowerarm_r"
	_chop_arm.hand_bone = &"hand_r"
	_chop_arm.side = "_r"
	_chop_arm.shoulder_bone = &"clavicle_r"
	_chop_arm.shoulder_share = 0.15
	skeleton.add_child(_chop_arm)
	_head = HeadLook.new()
	_head.name = "HeadLook"
	_head.amount = head_turn
	skeleton.add_child(_head)
	_legs = FloatingLegs.new()
	_legs.name = "FloatingLegs"
	_legs.amount = afloat
	skeleton.add_child(_legs)
	pose = Pose.IDLE
	play(Pose.IDLE)
	if not held_animation.is_empty():
		hold(held_animation, held_at)


# The bone a whole character has for [param pack_name], the packs' name for
# it; the name itself for a character built from the packs.
func _bone(pack_name: String) -> String:
	return whole_bone(pack_name) if _whole else pack_name


# Builds a whole character (a Meshy model): a [ThirdPartyModel] draws it in
# its outfit, and this plays its own clips on it. Its model can be dressed
# again while the game runs (a new outfit, the painted look switching on),
# which makes a new skeleton: [method _hook_whole] wires this to whichever is
# showing. Its hands are nodes of ours that follow the hand bones, so what
# they hold outlives the model being dressed again.
func _build_whole(parts: CharacterParts) -> void:
	_whole = true
	_whole_parts = parts
	var dresser: ThirdPartyModel = ThirdPartyModel.new()
	dresser.name = "Whole"
	dresser.path = parts.whole
	dresser.outfit = outfit_for(parts, undressed)
	# Always stylised: the body under the clothes is only left undrawn by the
	# stylised look's shader, so drawn as made its feet show through its boots.
	dresser.style = WHOLE_STYLE
	# Meshy models face +Z; our forward is -Z.
	dresser.rotation.y = PI
	dresser.scale = Vector3.ONE * parts.whole_scale
	character = dresser
	add_child(dresser)
	right_hand = _whole_hand("HandR")
	left_hand = _whole_hand("HandL")
	dresser.dressed.connect(func(_shown: bool) -> void: _hook_whole())
	_hook_whole()
	pose = Pose.IDLE
	play(Pose.IDLE)
	if not held_animation.is_empty():
		hold(held_animation, held_at)


func _whole_hand(called: String) -> Node3D:
	var hand: Node3D = Node3D.new()
	hand.name = called
	add_child(hand)
	_hand_fixes[hand] = Basis.IDENTITY
	_hand_bones[hand] = -1
	return hand


# Wires this to the whole character's model as it now stands: its skeleton,
# an animator with its moves, its hands and what moves its arms and head.
func _hook_whole() -> void:
	var dresser: ThirdPartyModel = character as ThirdPartyModel
	if dresser == null or dresser.model == null:
		return
	var skeletons: Array[Node] = dresser.model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	# Already wired to this very skeleton (the model says it's dressed more
	# than once as it puts its outfit on).
	if skeletons[0] == skeleton and is_instance_valid(_animator):
		return
	skeleton = skeletons[0] as Skeleton3D
	_toe_height = _rest_toe_height()
	_animator = AnimationPlayer.new()
	dresser.model.add_child(_animator)
	if _whole_moves == null:
		_whole_moves = _whole_library(_whole_parts)
	_animator.add_animation_library(LIBRARY, _whole_moves)
	_hand_bones[right_hand] = skeleton.find_bone(_bone("hand_r"))
	_hand_bones[left_hand] = skeleton.find_bone(_bone("hand_l"))
	_hand_fixes[right_hand] = _hand_fix("_r", PACK_HAND_RIGHT, PACK_FOREARM_RIGHT)
	_hand_fixes[left_hand] = _hand_fix("_l", PACK_HAND_LEFT, PACK_FOREARM_LEFT)
	skeleton.skeleton_updated.connect(_place_hands)
	_place_hands()
	_stride_speed = _measure_stride(walk_animation)
	_run_stride_speed = _measure_stride(run_animation)
	_arm = ArmReach.new()
	_arm.name = "ArmReach"
	_arm.upper_bone = StringName(_bone("upperarm_l"))
	_arm.lower_bone = StringName(_bone("lowerarm_l"))
	_arm.hand_bone = StringName(_bone("hand_l"))
	# The shoulder rises into a reach, as a real one does.
	_arm.shoulder_bone = StringName(_bone("clavicle_l"))
	_arm.amount = reach
	_arm.grip = hand_grip
	skeleton.add_child(_arm)
	_lifts.clear()
	for side: String in ["_l", "_r"]:
		var lift: ArmReach = ArmReach.new()
		lift.name = "HoldUp" + side.to_upper()
		lift.upper_bone = StringName(_bone("upperarm" + side))
		lift.lower_bone = StringName(_bone("lowerarm" + side))
		lift.hand_bone = StringName(_bone("hand" + side))
		lift.shoulder_bone = StringName(_bone("clavicle" + side))
		lift.side = side
		lift.amount = hold_up
		skeleton.add_child(lift)
		_lifts.append(lift)
	_chop_arm = ArmReach.new()
	_chop_arm.name = "ChopArm"
	_chop_arm.upper_bone = StringName(_bone("upperarm_r"))
	_chop_arm.lower_bone = StringName(_bone("lowerarm_r"))
	_chop_arm.hand_bone = StringName(_bone("hand_r"))
	_chop_arm.side = "_r"
	_chop_arm.shoulder_bone = StringName(_bone("clavicle_r"))
	_chop_arm.shoulder_share = 0.15
	skeleton.add_child(_chop_arm)
	_head = HeadLook.new()
	_head.name = "HeadLook"
	_head.amount = head_turn
	skeleton.add_child(_head)
	_legs = FloatingLegs.new()
	_legs.name = "FloatingLegs"
	_legs.bones = WHOLE_BONES
	_legs.amount = afloat
	skeleton.add_child(_legs)
	_show_eyes()
	# Lit as a smooth round form (one clean shadow edge on lumpy clothes),
	# with no one light burning it out.
	_whole_meshes.clear()
	_whole_hips = skeleton.find_bone(_bone("pelvis"))
	for found: Node in dresser.model.find_children("*", "MeshInstance3D", true, false):
		var mesh_node: MeshInstance3D = found as MeshInstance3D
		mesh_node.set_instance_shader_parameter(&"round_form", 0.75)
		mesh_node.set_instance_shader_parameter(&"light_cap", 0.85)
		_whole_meshes.append(mesh_node)
	_whole_head = skeleton.find_bone(_bone("Head"))
	_eye_bodies = draw_closed_eyes(_whole_meshes,
			_whole_parts.whole_closed_eyes if _whole_head >= 0 else null)
	# Pick up whatever was playing on the new animator.
	var was: Pose = pose
	pose = Pose.IDLE
	play(was if _act_left <= 0.0 else Pose.IDLE)


# How a whole character's hand node is turned from its hand bone, so that
# it sits as the packs' hand does: the packs' hand, swung from the way their
# forearm runs to the way this one's does.
func _hand_fix(side: String, pack_hand: Basis, pack_forearm: Vector3) -> Basis:
	var hand: int = skeleton.find_bone(_bone("hand" + side))
	var elbow: int = skeleton.find_bone(_bone("lowerarm" + side))
	if hand < 0 or elbow < 0:
		return Basis.IDENTITY
	var rest: Transform3D = skeleton.get_bone_global_rest(hand)
	var forearm: Vector3 = (rest.origin - skeleton.get_bone_global_rest(elbow).origin).normalized()
	var swung: Basis = Basis(Quaternion(pack_forearm, forearm)) * pack_hand
	return rest.basis.orthonormalized().inverse() * swung


# Puts a whole character's hand nodes on its hand bones, each time the
# skeleton has moved.
func _place_hands() -> void:
	if skeleton == null or not is_instance_valid(skeleton):
		return
	for hand: Node3D in _hand_bones:
		var bone: int = _hand_bones[hand]
		if bone < 0 or not is_instance_valid(hand):
			continue
		var at: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(bone)
		hand.global_transform = Transform3D(
				at.basis.orthonormalized() * _hand_fixes[hand], at.origin)
	# Where the head is, for drawn closed eyes.
	if _whole_head >= 0 and not _eye_bodies.is_empty():
		var head: Transform3D = skeleton.get_bone_global_pose(_whole_head)
		for body: MeshInstance3D in _eye_bodies:
			if not is_instance_valid(body):
				continue
			body.set_instance_shader_parameter(&"head_origin", head.origin)
			body.set_instance_shader_parameter(&"head_x", head.basis.x / head.basis.x.length_squared())
			body.set_instance_shader_parameter(&"head_y", head.basis.y / head.basis.y.length_squared())
			body.set_instance_shader_parameter(&"head_z", head.basis.z / head.basis.z.length_squared())
	# The rounded shading's line runs through the hips, the way the body does.
	if _whole_hips >= 0:
		var hips: Transform3D = skeleton.get_bone_global_pose(_whole_hips)
		var along: Vector3 = hips.basis.y.normalized()
		for mesh_node: MeshInstance3D in _whole_meshes:
			if is_instance_valid(mesh_node):
				mesh_node.set_instance_shader_parameter(&"round_origin", hips.origin)
				mesh_node.set_instance_shader_parameter(&"round_axis", along)


# A whole character's moves: each of its clips under the name the game asks
# for. A clip plays where the character stands (one that starts off-centre is
# moved back), and loops unless it's a strike or a tumble.
func _whole_library(parts: CharacterParts) -> AnimationLibrary:
	var library: AnimationLibrary = AnimationLibrary.new()
	var hips_at: Vector3 = Vector3.ZERO
	var hips: int = skeleton.find_bone(_bone("pelvis"))
	if hips >= 0:
		hips_at = skeleton.get_bone_rest(hips).origin
	for anim_name: StringName in parts.whole_clips:
		var path: String = parts.whole_clips[anim_name]
		if not ResourceLoader.exists(path):
			continue
		var source: Node = (load(path) as PackedScene).instantiate()
		var wanted: String = parts.whole_clip_names.get(anim_name, "")
		var clip: Animation = null
		for found: Node in source.find_children("*", "AnimationPlayer", true, false):
			var animator: AnimationPlayer = found as AnimationPlayer
			for clip_name: StringName in animator.get_animation_list():
				if clip_name == &"RESET":
					continue
				if clip == null and (wanted.is_empty() or String(clip_name) == wanted):
					clip = animator.get_animation(clip_name).duplicate(true) as Animation
		source.free()
		if clip == null:
			continue
		for track: int in clip.get_track_count():
			var bone: String = String(clip.track_get_path(track).get_concatenated_subnames())
			if bone != _bone("pelvis") or clip.track_get_type(track) != Animation.TYPE_POSITION_3D:
				continue
			# Only where the clip starts off-centre is taken out: the hips
			# still shift as the clip has them, or the body's lean to balance
			# them would be left as a slump.
			var first: Vector3 = clip.track_get_key_value(track, 0)
			var off: Vector3 = Vector3(first.x - hips_at.x, 0.0, first.z - hips_at.z)
			for key: int in clip.track_get_key_count(track):
				var at: Vector3 = clip.track_get_key_value(track, key)
				clip.track_set_key_value(track, key, at - off)
		clip.loop_mode = Animation.LOOP_NONE if plays_once(anim_name) else Animation.LOOP_LINEAR
		library.add_animation(anim_name, clip)
	# Holding something up is one moment of its clip, held.
	if library.has_animation(hold_up_animation):
		library.add_animation(HOLD_UP_STILL,
				still_of(library.get_animation(hold_up_animation), hold_up_at))
	# The poses it has no clip for.
	var forward: Vector3 = Vector3.RIGHT
	var across: Vector3 = Vector3.BACK
	var limp: Animation = _pose_clip({
		"Spine02": [[forward, 10.0]], "Spine01": [[forward, 10.0]], "Spine": [[forward, 8.0]],
		"neck": [[forward, 18.0]], "Head": [[forward, 22.0]],
		"LeftArm": [[across, -34.0], [forward, -22.0]],
		"RightArm": [[across, 34.0], [forward, -22.0]],
		"LeftForeArm": [[forward, -28.0]], "RightForeArm": [[forward, -28.0]],
	}, 0.0, Vector3(0.0, 1.0, 0.0))
	for anim_name: String in LIMP_NAMES:
		if not library.has_animation(anim_name):
			library.add_animation(anim_name, limp)
	# On its back, head towards our +Z (as the packs' character lies), hips
	# just above the floor, arms by its sides.
	var lying: Animation = _pose_clip({
		"LeftArm": [[across, -20.0], [forward, -14.0]],
		"RightArm": [[across, 20.0], [forward, -14.0]],
	}, -90.0, Vector3(0.0, 0.12, -0.38))
	for anim_name: String in LYING_NAMES:
		if not library.has_animation(anim_name):
			library.add_animation(anim_name, lying)
	for anim_name: StringName in library.get_animation_list():
		_proportion(library.get_animation(anim_name), parts)
	return library


# A still pose as a clip: the skeleton at rest, with the bones in
# [param turns] turned (each a list of [axis, degrees] in the skeleton's own
# space, where +X is the character's left, +Y up and +Z its front: turning
# about +X tips what's above forwards), then the whole body tipped
# [param lay] degrees about X (-90 lays it on its back), with the hips at
# [param hips_at], as shares of how high the hips stand at rest.
func _pose_clip(turns: Dictionary, lay: float, hips_at: Vector3) -> Animation:
	var clip: Animation = Animation.new()
	clip.length = 1.0
	clip.loop_mode = Animation.LOOP_LINEAR
	var to_skeleton: String = String(_animator.get_node(_animator.root_node).get_path_to(skeleton))
	var hips: int = skeleton.find_bone(_bone("pelvis"))
	# Each bone's facing in the skeleton's space, as posed, parents first.
	var posed: Array[Basis] = []
	for bone: int in skeleton.get_bone_count():
		var parent: int = skeleton.get_bone_parent(bone)
		var above: Basis = posed[parent] if parent >= 0 else Basis.IDENTITY
		var local: Basis = skeleton.get_bone_rest(bone).basis.orthonormalized()
		var bone_name: String = skeleton.get_bone_name(bone)
		if turns.has(bone_name):
			var list: Array = turns[bone_name]
			for entry: Array in list:
				var axis: Vector3 = entry[0]
				var degrees: float = entry[1]
				# Turned in the skeleton's space, on top of what it inherits.
				local = above.inverse() * Basis(axis.normalized(), deg_to_rad(degrees)) * above * local
		posed.append(above * local)
		var shown: Basis = local
		if bone == hips and lay != 0.0:
			shown = Basis(Vector3.RIGHT, deg_to_rad(lay)) * local
		var turn: int = clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(turn, NodePath("%s:%s" % [to_skeleton, bone_name]))
		clip.rotation_track_insert_key(turn, 0.0, shown.get_rotation_quaternion())
		if bone == hips:
			var rest: Vector3 = skeleton.get_bone_rest(bone).origin
			var place: int = clip.add_track(Animation.TYPE_POSITION_3D)
			clip.track_set_path(place, NodePath("%s:%s" % [to_skeleton, bone_name]))
			clip.position_track_insert_key(place, 0.0,
					Vector3(rest.x + hips_at.x * rest.y, hips_at.y * rest.y, rest.z + hips_at.z * rest.y)
					if lay != 0.0 else rest)
	return clip


# Gives a clip the look's proportions: every key of its arms and hands is
# the size the parts ask for, whatever size the clip had them.
func _proportion(clip: Animation, parts: CharacterParts) -> void:
	if is_equal_approx(parts.whole_arm_scale, 1.0) and is_equal_approx(parts.whole_hand_scale, 1.0):
		return
	for track: int in range(clip.get_track_count() - 1, -1, -1):
		if clip.track_get_type(track) == Animation.TYPE_SCALE_3D:
			clip.remove_track(track)
	var to_skeleton: String = String(_animator.get_node(_animator.root_node).get_path_to(skeleton))
	var sizes: Dictionary[String, float] = {
		"upperarm_l": parts.whole_arm_scale, "upperarm_r": parts.whole_arm_scale,
		"hand_l": parts.whole_hand_scale, "hand_r": parts.whole_hand_scale,
	}
	for pack_name: String in sizes:
		if skeleton.find_bone(_bone(pack_name)) < 0:
			continue
		var track: int = clip.add_track(Animation.TYPE_SCALE_3D)
		clip.track_set_path(track, NodePath("%s:%s" % [to_skeleton, _bone(pack_name)]))
		clip.scale_track_insert_key(track, 0.0, Vector3.ONE * sizes[pack_name])


# The head and neck of [param path]'s body, and its eyes.
func _add_head(path: String) -> void:
	var source: Node = (load(path) as PackedScene).instantiate()
	for mesh: MeshInstance3D in source.find_children("*", "MeshInstance3D", true, false):
		# The base character's own eyebrows: the parts bring their own.
		if mesh.name == "Eyebrows":
			continue
		if mesh.name != "Eyes" and mesh.skin != null:
			var key: String = "%s:%s" % [path, mesh.name]
			if not _heads.has(key):
				_heads[key] = cut_out(mesh.mesh as ArrayMesh, mesh.skin, HEAD_BONES)
			mesh.mesh = _heads[key]
		_move_to_skeleton(mesh)
	source.free()


# Every mesh in [param path], onto our skeleton, tinted [param colour].
func _add_meshes(path: String, colour: Color) -> void:
	var source: Node = (load(path) as PackedScene).instantiate()
	for mesh: MeshInstance3D in source.find_children("*", "MeshInstance3D", true, false):
		for surface: int in mesh.mesh.get_surface_count():
			var own: BaseMaterial3D = mesh.mesh.surface_get_material(surface) as BaseMaterial3D
			if own == null:
				continue
			var tinted: BaseMaterial3D = own.duplicate() as BaseMaterial3D
			tinted.albedo_color = colour
			mesh.set_surface_override_material(surface, tinted)
		_move_to_skeleton(mesh)
	source.free()


func _move_to_skeleton(mesh: MeshInstance3D) -> void:
	mesh.get_parent().remove_child(mesh)
	mesh.owner = null
	skeleton.add_child(mesh)
	mesh.transform = Transform3D.IDENTITY
	mesh.skeleton = NodePath("..")


# Every animation in the animation files, moving our skeleton.
func _library(animator_root: Node) -> AnimationLibrary:
	var library: AnimationLibrary = AnimationLibrary.new()
	var to_skeleton: NodePath = animator_root.get_path_to(skeleton)
	for path: String in animation_files:
		if not ResourceLoader.exists(path):
			continue
		var source: Node = (load(path) as PackedScene).instantiate()
		var ratio: float = 1.0
		var skeletons: Array[Node] = source.find_children("*", "Skeleton3D", true, false)
		if not skeletons.is_empty():
			var theirs: float = hip_height(skeletons[0] as Skeleton3D)
			var ours: float = hip_height(skeleton)
			if theirs > 0.0 and ours > 0.0:
				ratio = ours / theirs
		for found: Node in source.find_children("*", "AnimationPlayer", true, false):
			var animator: AnimationPlayer = found as AnimationPlayer
			for anim_name: StringName in animator.get_animation_list():
				if library.has_animation(anim_name):
					library.remove_animation(anim_name)
				library.add_animation(anim_name,
						retarget(animator.get_animation(anim_name), to_skeleton, ratio))
		source.free()
	return library


# How far a toe joint sits above the boot's sole at rest, in metres in this
# node's space: the toe's rest height less the lowest point of the outfit.
func _rest_toe_height() -> float:
	var toe: int = skeleton.find_bone(_bone(TOE_BONES[0]))
	if toe < 0:
		return 0.0
	var toe_at: Vector3 = skeleton.global_transform * skeleton.get_bone_global_rest(toe).origin
	var lowest: float = INF
	for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		lowest = minf(lowest, to_local(box.position).y)
	if lowest == INF:
		lowest = 0.0
	return to_local(toe_at).y - lowest


# The speed the walk was made for: plays it through once, watching a toe.
# While that foot is down it sweeps backwards under the body exactly as fast
# as the body is meant to go forwards, so that's the speed.
func _measure_stride(anim_name: StringName) -> float:
	var walk: StringName = StringName("%s/%s" % [LIBRARY, anim_name])
	var toe: int = skeleton.find_bone(_bone(TOE_BONES[0]))
	if not _animator.has_animation(walk) or toe < 0:
		return 0.0
	var length: float = _animator.get_animation(walk).length
	if length <= 0.0:
		return 0.0
	const SAMPLES: int = 60
	var step: float = length / SAMPLES
	var heights: PackedFloat32Array = []
	var alongs: PackedFloat32Array = []
	_animator.play(walk)
	for sample: int in SAMPLES + 1:
		_animator.seek(step * sample, true)
		var at: Vector3 = to_local(skeleton.global_transform
				* skeleton.get_bone_global_pose(toe).origin)
		heights.append(at.y)
		alongs.append(at.z)
	_animator.stop()
	# Down is within 2 cm of the lowest the toe gets.
	var lowest: float = INF
	for height: float in heights:
		lowest = minf(lowest, height)
	var swept: float = 0.0
	var time_down: float = 0.0
	for sample: int in SAMPLES:
		if heights[sample] < lowest + 0.02 and heights[sample + 1] < lowest + 0.02:
			# Forward is -Z, so a planted foot moves towards +Z.
			swept += alongs[sample + 1] - alongs[sample]
			time_down += step
	return swept / time_down if time_down > 0.0 and swept > 0.0 else 0.0


# Shuts or opens the eyes: shut, the eyeballs aren't drawn, which leaves
# the lids' own shadowed hollow.
func _show_eyes() -> void:
	if skeleton == null:
		return
	if _whole:
		# No eyelids to shut: the stylised shader paints the eyes over. Only
		# on the body, not the clothes (a blue shirt is eye-coloured).
		for child: Node in skeleton.get_children():
			var body: MeshInstance3D = child as MeshInstance3D
			if body != null and not String(body.name).begins_with("Outfit_"):
				body.set_instance_shader_parameter(&"eyes_shut", 1.0 if eyes_shut else 0.0)
		return
	for mesh: MeshInstance3D in skeleton.find_children("Eyes", "MeshInstance3D", true, false):
		mesh.visible = not eyes_shut


# A dodge: plays its stretch of its animation.
func _on_dodged(move: DodgeMove) -> void:
	_recovery = &""
	act(move.animation, move.animation_from, move.animation_length, move.seconds, Pose.DODGE)


# Through a backflip, turns the character head over heels backwards, once
# round, about its hips; otherwise leaves it upright.
func _turn_for_flip() -> void:
	var angle: float = flip_angle()
	if angle == 0.0 and character.rotation.x == 0.0:
		return
	character.rotation.x = angle
	# Turned about the hips, not the feet: move it so the hips stay put. Its
	# forward is -Z, so backwards (head first towards +Z) is a negative turn.
	var pivot: float = hip_height(skeleton) * body_scale
	var hips: Vector3 = Vector3.UP * (pivot if pivot > 0.0 else FLIP_PIVOT_HEIGHT)
	var turned: Vector3 = Vector3(0.0, hips.y * cos(angle), -hips.y * sin(angle))
	var lift: float = character.position.y if angle == 0.0 else 0.0
	character.position = Vector3(0.0, lift, 0.0) + hips - turned


## How far round the backflip has turned the character, in radians: 0
## upright, down to minus a full turn as it lands. 0 when not flipping.
func flip_angle() -> float:
	if player == null or player.dodge_move == null or not player.dodge_move.flips:
		return 0.0
	return -TAU * smoothstep(0.0, 1.0, player.dodge_progress())


# A cut of the knife: plays its stretch of its animation (or the plain
# strike, if the library hasn't got it), then its recovery.
func _on_cut_started(cut: KnifeCut) -> void:
	if not act(cut.animation, cut.animation_from, cut.animation_length, cut.seconds,
			Pose.STRIKE):
		act(strike_animation, 0.0, 0.0, cut.seconds, Pose.STRIKE)
	_recovery = cut.recovery_animation


func _hand(bone: String) -> BoneAttachment3D:
	var hand: BoneAttachment3D = BoneAttachment3D.new()
	hand.name = bone.capitalize().replace(" ", "")
	hand.bone_name = bone
	skeleton.add_child(hand)
	return hand


func _undress() -> void:
	# A whole character's hands are ours, not its skeleton's.
	for hand: Node3D in _hand_fixes:
		if is_instance_valid(hand):
			hand.queue_free()
	_hand_fixes.clear()
	_hand_bones.clear()
	_whole_meshes.clear()
	_eye_bodies.clear()
	_whole_head = -1
	_whole_hips = -1
	_whole = false
	_held_up = false
	_whole_parts = null
	_whole_moves = null
	if character != null:
		character.queue_free()
	character = null
	skeleton = null
	right_hand = null
	left_hand = null
	_animator = null
	_arm = null
	_lifts.clear()
	_chop_arm = null
	_head = null
	_legs = null
	_act_left = 0.0
	_recovery = &""


# How far through a chop at [param point] it is, [param through] from 0 to 1:
# up above it, down onto it, then back.
func _set_chop(through: float, point: Vector3) -> void:
	if _chop_arm == null:
		return
	_chop_arm.amount = smoothstep(0.0, 0.3, through) * (1.0 - smoothstep(0.75, 1.0, through))
	var strike: float = smoothstep(CHOP_CONTACT - 0.14, CHOP_CONTACT, through)
	_chop_arm.target = point + Vector3.UP * lerpf(0.32, -0.04, strike)


# Points each raised hand at its side of the hold-up point, so the hands
# meet round what they hold.
func _aim_lifts() -> void:
	var point: Vector3 = hold_up_point()
	var across: Vector3 = global_basis.x.normalized() * hold_up_spread
	if _lifts.size() == 2:
		# The character faces -Z, so its right hand is towards +X.
		_lifts[0].target = point - across
		_lifts[1].target = point + across


func _show_stand_ins(shown: bool) -> void:
	for stand_in: VisualInstance3D in stand_ins:
		if stand_in != null:
			stand_in.visible = shown


# Strikes the hold-up pose ([param up]) or goes back to standing, blending
# over [member hold_up_blend] seconds.
func _strike_hold_up(up: bool) -> void:
	_held_up = up
	_act_left = 0.0
	_animator.speed_scale = 1.0
	if up:
		_animator.play(StringName("%s/%s" % [LIBRARY, HOLD_UP_STILL]), hold_up_blend)
		return
	pose = Pose.IDLE
	_animator.play(StringName("%s/%s" % [LIBRARY, idle_animation]), hold_up_blend * 0.6)
