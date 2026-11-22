class_name CharacterModel
extends Node3D
## The player's body: a Quaternius character put together from pack files
## and animated, standing in for the greybox capsule when the files are there.
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
## walk, strike or parry ([method pose_for]).
##
## The files live in the gitignored assets/third_party/. If any are missing
## (a fresh clone, CI), the [member stand_ins] stay and nothing else changes:
## gameplay never depends on the model. The look is rebuilt if it changes.

## Emitted after the model is built or taken down. [param shown] says
## whether the character is showing (true) or the greybox is (false).
signal dressed(shown: bool)

## What the player can be doing, each with its own animation.
enum Pose { IDLE, WALK, STRIKE, PARRY }

## The toe joints, which the feet are planted by.
const TOE_BONES: PackedStringArray = ["ball_l", "ball_r"]
## The bones the head is cut from the base character's body by.
const HEAD_BONES: PackedStringArray = ["Head", "neck_01"]
## Bones whose position the animations may move (the whole body's sway and
## bob). Every other bone only turns, keeping our proportions.
const MOVING_BONES: PackedStringArray = ["root", "pelvis"]
## The animation library's name on the [AnimationPlayer].
const LIBRARY: StringName = &"moves"

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
## The animation for each [enum Pose].
@export var idle_animation: StringName = &"Idle"
@export var walk_animation: StringName = &"Walk"
## The animation for walking quickly: at [member run_from] metres per second
## or faster, the walk becomes this.
@export var run_animation: StringName = &"Jog_Fwd"
## The walking speed, in metres per second, from which the walk is a run.
@export var run_from: float = 3.0
@export var strike_animation: StringName = &"Sword_Regular_A"
@export var parry_animation: StringName = &"Idle_Shield"
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
## Draw it the N64 way: chunky texture pixels (nearest-neighbour, not
## smoothed) and no shine. Its own materials are kept: the props' N64 shader
## turns these textures the wrong colours.
@export var n64: bool = true
## How fine a version of the model to draw (see [member ThirdPartyModel.detail]).
@export var detail: float = 0.3
## Whether the character's eyes are shut: asleep, or out cold. A clip can
## move it.
@export var eyes_shut: bool = false:
	set(value):
		eyes_shut = value
		_show_eyes()
## Whether the body is limp: its arms, legs and neck hang and trail under
## physics instead of being posed (see [Ragdoll]). The hips and chest still
## go wherever the character is taken. A clip can move it.
@export var limp: bool = false:
	set(value):
		limp = value
		_go_limp()
## While limp, whether the left arm stays posed: it's holding on to
## something.
@export var holding_on: bool = false:
	set(value):
		holding_on = value
		_go_limp()

## The character, or null while the greybox shows.
var character: Node3D = null
## The character's skeleton, or null.
var skeleton: Skeleton3D = null
## The pose being played.
var pose: Pose = Pose.IDLE
## The character's right hand, which holds the knife, or null.
var right_hand: BoneAttachment3D = null
## The character's left hand, which holds the pan, or null.
var left_hand: BoneAttachment3D = null

var _animator: AnimationPlayer = null
## The physics for going limp, made the first time it's needed.
var _ragdoll: PhysicalBoneSimulator3D = null
var _duellist: Duellist = null
## How high a toe joint is when its boot's sole is on the floor, in metres
## above this node: measured from the rest pose when the character is built.
var _toe_height: float = 0.0
## How fast the walk and run animations move their feet, played at normal
## speed, in metres per second: the speed each was made for. Measured when
## built; 0 if there's no such animation.
var _stride_speed: float = 0.0
var _run_stride_speed: float = 0.0


func _ready() -> void:
	if player != null:
		_duellist = player.get_node_or_null("Duellist") as Duellist
	if not Engine.is_editor_hint():
		Game.look_changed.connect(func(_body: PlayerLook.Body) -> void: dress())
	dress()


func _process(_delta: float) -> void:
	if _animator == null:
		return
	# A limp body isn't standing on anything.
	if not limp:
		plant_feet()
	var walking: bool = player != null and player.is_walking
	var striking: bool = _duellist != null and _duellist.is_striking()
	var parrying: bool = _duellist != null and _duellist.parry.is_active()
	play(pose_for(walking, striking, parrying))
	# Walk in step: the walk plays as fast as the feet must go to keep up.
	var speed: float = player.move_speed if player != null else 0.0
	var stride: float = _run_stride_speed if is_running() else _stride_speed
	_animator.speed_scale = walk_playback(speed, stride) if pose == Pose.WALK else 1.0


## Builds the character for who the player is now. Returns whether it's
## showing; if any file is missing the greybox shows instead.
func dress() -> bool:
	_undress()
	var parts: CharacterParts = girl if Game.look == PlayerLook.Body.GIRL else boy
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
		var bone: int = skeleton.find_bone(bone_name)
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
		var bone: int = skeleton.find_bone(bone_name)
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
	_animator.play(full, blend_seconds)


## Whether walking is quick enough to be a run (see [member run_from]), and
## there's a run to play.
func is_running() -> bool:
	return player != null and player.move_speed >= run_from and _run_stride_speed > 0.0


## The animation played for [param of].
func animation_for(of: Pose) -> StringName:
	match of:
		Pose.WALK:
			# A quick walk is a run, if there's a run to play.
			if is_running() and _animator != null 					and _animator.has_animation("%s/%s" % [LIBRARY, run_animation]):
				return run_animation
			return walk_animation
		Pose.STRIKE:
			return strike_animation
		Pose.PARRY:
			return parry_animation
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


## What to play: a strike or a parry wins over walking, and walking over
## standing still.
static func pose_for(walking: bool, striking: bool, parrying: bool) -> Pose:
	if striking:
		return Pose.STRIKE
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


## How high [param skeleton]'s hips are at rest, or 0 if it has none.
static func hip_height(skeleton: Skeleton3D) -> float:
	var hips: int = skeleton.find_bone("pelvis")
	return skeleton.get_bone_global_rest(hips).origin.y if hips >= 0 else 0.0


func _build(parts: CharacterParts) -> void:
	character = (load(parts.outfit) as PackedScene).instantiate() as Node3D
	add_child(character)
	# The packs face +Z; our forward is -Z.
	character.rotation.y = PI
	character.scale = Vector3.ONE * body_scale
	skeleton = character.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	# Measured on the outfit alone: its boots are what stand on the floor.
	_toe_height = _rest_toe_height()
	_add_head(parts.head_from)
	for extra: String in [parts.hair, parts.eyebrows]:
		if not extra.is_empty():
			_add_meshes(extra, parts.hair_colour)
	skeleton.set_bone_pose_scale(skeleton.find_bone("Head"), Vector3.ONE * head_scale)
	for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
		mesh.lod_bias = detail
		if n64:
			_use_n64(mesh)
	_animator = AnimationPlayer.new()
	character.add_child(_animator)
	_animator.add_animation_library(LIBRARY, _library(_animator.get_node(_animator.root_node)))
	right_hand = _hand("hand_r")
	left_hand = _hand("hand_l")
	_stride_speed = _measure_stride(walk_animation)
	_run_stride_speed = _measure_stride(run_animation)
	_show_eyes()
	pose = Pose.IDLE
	play(Pose.IDLE)
	_go_limp()


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


# Draws each of [param mesh]'s surfaces with chunky texture pixels and no
# shine, keeping its colour, texture and any tint already given.
func _use_n64(mesh: MeshInstance3D) -> void:
	for surface: int in mesh.mesh.get_surface_count():
		var source: BaseMaterial3D = mesh.get_surface_override_material(surface) as BaseMaterial3D
		if source == null:
			source = mesh.mesh.surface_get_material(surface) as BaseMaterial3D
		if source == null:
			continue
		var material: BaseMaterial3D = source.duplicate() as BaseMaterial3D
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		material.metallic_specular = 0.2
		mesh.set_surface_override_material(surface, material)


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
	var toe: int = skeleton.find_bone(TOE_BONES[0])
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
	var toe: int = skeleton.find_bone(TOE_BONES[0])
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


## Whether the body's physics are running right now.
func is_limp() -> bool:
	return _ragdoll != null and _ragdoll.is_simulating_physics()


# Hands the limbs to physics, or back to the animation.
func _go_limp() -> void:
	if skeleton == null:
		return
	if not limp:
		if _ragdoll != null:
			_ragdoll.physical_bones_stop_simulation()
		return
	if _ragdoll == null:
		_ragdoll = Ragdoll.build(skeleton)
	# Started afresh, so a change in which arm is posed takes hold.
	_ragdoll.physical_bones_stop_simulation()
	_ragdoll.physical_bones_start_simulation(Ragdoll.limp_bones(holding_on))


# Shuts or opens the eyes: shut, the eyeballs aren't drawn, which leaves
# the lids' own shadowed hollow.
func _show_eyes() -> void:
	if skeleton == null:
		return
	for mesh: MeshInstance3D in skeleton.find_children("Eyes", "MeshInstance3D", true, false):
		mesh.visible = not eyes_shut


func _hand(bone: String) -> BoneAttachment3D:
	var hand: BoneAttachment3D = BoneAttachment3D.new()
	hand.name = bone.capitalize().replace(" ", "")
	hand.bone_name = bone
	skeleton.add_child(hand)
	return hand


func _undress() -> void:
	if character != null:
		character.queue_free()
	character = null
	skeleton = null
	right_hand = null
	left_hand = null
	_animator = null
	_ragdoll = null


func _show_stand_ins(shown: bool) -> void:
	for stand_in: VisualInstance3D in stand_ins:
		if stand_in != null:
			stand_in.visible = shown
