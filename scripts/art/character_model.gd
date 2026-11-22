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
@export var idle_animation: StringName = &"Idle_Lantern"
@export var walk_animation: StringName = &"Walk_Carry"
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
var _duellist: Duellist = null
## How high a toe joint is when its boot's sole is on the floor, in metres
## above this node: measured from the rest pose when the character is built.
var _toe_height: float = 0.0


func _ready() -> void:
	if player != null:
		_duellist = player.get_node_or_null("Duellist") as Duellist
	if not Engine.is_editor_hint():
		Game.look_changed.connect(func(_body: PlayerLook.Body) -> void: dress())
	dress()


func _process(_delta: float) -> void:
	if _animator == null:
		return
	plant_feet()
	var walking: bool = player != null and player.is_walking
	var striking: bool = _duellist != null and _duellist.is_striking()
	var parrying: bool = _duellist != null and _duellist.parry.is_active()
	play(pose_for(walking, striking, parrying))


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


## Raises or lowers the character so the lower foot's sole is on the floor.
## The animations come from a skeleton with other proportions, so without
## this the boots sink into the ground in some poses and float in others.
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
	character.position.y = clampf(character.position.y + _toe_height - lowest, -0.2, 0.2)


## How high the lower foot's sole is above the floor, in metres: 0 when
## planted. For tests.
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


## The animation played for [param of].
func animation_for(of: Pose) -> StringName:
	match of:
		Pose.WALK:
			return walk_animation
		Pose.STRIKE:
			return strike_animation
		Pose.PARRY:
			return parry_animation
	return idle_animation


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
	pose = Pose.IDLE
	play(Pose.IDLE)


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


func _show_stand_ins(shown: bool) -> void:
	for stand_in: VisualInstance3D in stand_ins:
		if stand_in != null:
			stand_in.visible = shown
