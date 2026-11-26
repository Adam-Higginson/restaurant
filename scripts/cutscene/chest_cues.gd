class_name ChestCues
extends CueHandler
## The treasure chest's big moment, as in Ocarina of Time (#152). A
## [TreasureChest] plays [code]data/dialogue/chest.dlg[/code] when it's
## opened, and these cues stage it:
##
## [codeblock]
## @open                you step up to the chest, the camera looks over your
##                      shoulder, you open it: the lid creaks up and the
##                      light pours out
## @hold_up             you turn round and hold the treasure up over your
##                      head, turning slowly in the light, with a fanfare
## @hold_up frying_pan  you hold that up, no chest needed: a gift (the
##                      heron's pan), by its item or tool id
## @put_away            you lower it, and the camera's back as it was
## [/codeblock]
##
## The treasure stays held up while the lines are read, until
## [code]@put_away[/code] or the end of the script. The script gives it
## ([code]set has_frying_pan[/code]: see [member HandTool.owned_flag]).

## The soft glow behind a treasure held up: a round spot facing the camera.
const HALO_SHADER: Shader = preload("res://shaders/sparkle.gdshader")
## The colour of a treasure's light: the green of an opened chest.
const TREASURE_GREEN: Color = Color(0.62, 1.0, 0.68)
## How far a model is turned about its forward axis to stand it up, in
## degrees: our Meshy tools and pans lie along X, the knife's point and the
## pans' handles at +X or -X. The knife stands point up, a pan handle up.
const TOOL_TURN_DEGREES: float = -90.0
const ITEM_TURN_DEGREES: float = 90.0

## The player who opens chests.
@export var player: Player3D
## How long after you start opening it the lid lifts, in seconds: when the
## hands reach it in the animation.
@export var lid_delay: float = 0.55
## The animation of opening a chest, and how long it plays.
@export var open_animation: StringName = &"Chest_Open"
@export var open_animation_seconds: float = 1.4
## How long your arms take to go up with the treasure, in seconds, and how
## long the treasure takes to pop in, in your hands.
@export var rise_seconds: float = 0.9
@export var pop_seconds: float = 0.3
## How far above where the hands meet the treasure floats, in metres, and
## how far it bobs up and down as it floats, and how fast (bobs a second).
@export var above_hands: float = 0.12
@export var bob_height: float = 0.03
@export var bob_rate: float = 0.6
## How fast the treasure turns while it's held up, in turns a second.
@export var spin_turns: float = 0.35
## How far your head turns to look at the camera while you hold the
## treasure up: 0 not at all, 1 straight at it.
@export_range(0.0, 1.0) var look_at_camera: float = 0.85
## Where the camera stands for a gift held up without a chest: how far in
## front of you, how high (above your head, looking down at you and what
## you hold up), and how far round to one side, in degrees.
@export var gift_shot_distance: float = 2.3
@export var gift_shot_height: float = 2.5
@export var gift_shot_angle: float = 40.0
## The lid creaking up, and the fanfare as the treasure is held up.
@export var creak: AudioStream
@export var fanfare: AudioStream

## The chest being opened now, or null.
var _chest: TreasureChest = null
## The treasure being held up, or null.
var _treasure: Node3D = null
var _sound: AudioStreamPlayer = null
## The camera's mark for a gift held up without a chest, or null.
var _gift_shot: Marker3D = null
## The shot the camera was holding before the scene began (the captain's
## conversation by the stove), to go back to after; null for the free camera.
var _shot_before: Marker3D = null
## Whether a scene is under way (a chest opening or a gift held up), so the
## shot from before it is remembered once, not replaced by its own shots.
var _staging: bool = false
## What your head was watching before you looked at the camera, and how
## far it was turned, to put back.
var _watch_before: Node3D = null
var _turn_before: float = 0.0
var _looking: bool = false


func _ready() -> void:
	super._ready()
	_sound = AudioStreamPlayer.new()
	_sound.name = "ChestSound"
	add_child(_sound)


func _process(delta: float) -> void:
	if not is_instance_valid(_treasure):
		return
	# Every treasure turns slowly on the spot, standing up, as in Zelda (#207).
	_treasure.rotate_y(TAU * spin_turns * delta)
	# Always over your hands, from the moment it appears: it rises with
	# them, floating, bobbing gently.
	_treasure.global_position = hands_point() \
			+ Vector3.UP * bob_height * sin(Time.get_ticks_msec() / 1000.0 * TAU * bob_rate)


## Where the treasure floats: [member above_hands] over where your hands
## are as they really are, or over your head without a character.
func hands_point() -> Vector3:
	var model: CharacterModel = _character()
	if model != null:
		return model.held_point() + Vector3.UP * above_hands
	return player.global_position + Vector3.UP * 2.0 if is_instance_valid(player) \
			else Vector3.ZERO


func cues() -> Array[StringName]:
	return [&"open", &"hold_up", &"put_away"]


## The treasure held up, or null.
func treasure() -> Node3D:
	return _treasure if is_instance_valid(_treasure) else null


func _perform(cue: StringName, args: PackedStringArray) -> void:
	if not is_instance_valid(player):
		warn("@%s needs the player (ChestCues' Player)" % cue)
		return
	if cue == &"put_away":
		_put_away()
		return
	if cue == &"hold_up" and not args.is_empty():
		_hold_up_gift(StringName(args[0]))
		return
	var chest: TreasureChest = TreasureChest.opening_in(get_tree())
	if chest == null:
		warn("@%s: no chest is being opened" % cue)
		return
	_chest = chest
	match cue:
		&"open":
			_open(chest)
		&"hold_up":
			_hold_up(chest)


func _open(chest: TreasureChest) -> void:
	var held: int = hold()
	var stand: Marker3D = chest.stand_mark()
	player.global_position = stand.global_position
	player.velocity = Vector3.ZERO
	player.face_towards(chest.global_position)
	player.reset_physics_interpolation()
	_begin_staging()
	player.camera_rig.hold_shot(chest.open_shot(), true)
	if is_skipping():
		chest.swing_open(true)
		release(held)
		return
	var model: CharacterModel = _character()
	if model != null:
		model.act(open_animation, 0.0, 0.0, open_animation_seconds, CharacterModel.Pose.IDLE)
	await pause(lid_delay, held)
	_play(creak)
	chest.swing_open()
	await pause(chest.open_seconds + 0.3, held)
	release(held)


func _hold_up(chest: TreasureChest) -> void:
	var holds_item: bool = chest.contents == null and chest.item != null
	var treasure: Node3D = make_item_treasure(chest.item) if holds_item \
			else make_treasure(chest.contents)
	_raise(treasure, chest.hold_shot(), chest.get_parent())


# Holds up [param id] (an item's or a tool's), handed over rather than found
# in a chest, with the camera looking at you from in front, a little to one
# side.
func _hold_up_gift(id: StringName) -> void:
	var catalog: Catalog = Catalog.load_default()
	var treasure_node: Node3D = null
	var tool: HandTool = catalog.find_tool(id)
	var item: Item = catalog.find_item(id)
	if tool != null:
		treasure_node = make_treasure(tool)
	elif item != null:
		treasure_node = make_item_treasure(item)
	else:
		warn("@hold_up: there's no item or tool called '%s'" % id)
		return
	_gift_shot = Marker3D.new()
	_gift_shot.name = "GiftShot"
	player.add_child(_gift_shot)
	var round_by: Vector3 = player.facing.rotated(Vector3.UP, deg_to_rad(gift_shot_angle))
	var head: Vector3 = player.global_position + Vector3.UP * 1.75
	var at: Vector3 = clear_of_walls(head, player.global_position + round_by * gift_shot_distance
			+ Vector3.UP * gift_shot_height)
	_gift_shot.global_transform = Transform3D(Basis.looking_at(head - at, Vector3.UP), at)
	_raise(treasure_node, _gift_shot, player.get_parent())


## Where a camera wanting to stand at [param want] can, looking at
## [param from]: there, or pulled in short of the first wall between them,
## like a spring arm, so it never ends up outside the room.
func clear_of_walls(from: Vector3, want: Vector3) -> Vector3:
	if not is_inside_tree() or not is_instance_valid(player):
		return want
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, want)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return want
	var wall: Vector3 = hit["position"]
	return wall + (from - wall).normalized() * 0.25


# Holds [param treasure_node] up as your arms go up, with the fanfare and the
# camera at [param shot]: it appears in your hands, floating, popping in, and
# rises with them (see [method hands_point]). It joins [param world].
func _raise(treasure_node: Node3D, shot: Marker3D, world: Node) -> void:
	var held: int = hold()
	player.face_towards(shot.global_position)
	_begin_staging()
	player.camera_rig.hold_shot(shot, true)
	if is_instance_valid(_treasure):
		_treasure.queue_free()
	_treasure = treasure_node
	world.add_child(_treasure)
	_treasure.global_position = hands_point()
	var model: CharacterModel = _character()
	var camera: Camera3D = get_viewport().get_camera_3d()
	if model != null and camera != null and not _looking:
		_looking = true
		_watch_before = model.watch
		_turn_before = model.head_turn
		model.watch = camera
	if is_skipping():
		if model != null:
			model.hold_up = 1.0
			if _looking:
				model.head_turn = look_at_camera
		release(held)
		return
	_play(fanfare)
	var rise: Tween = create_tween().set_parallel()
	_treasure.scale = Vector3.ONE * 0.01
	rise.tween_property(_treasure, "scale", Vector3.ONE, pop_seconds) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if model != null:
		rise.tween_property(model, "hold_up", 1.0, rise_seconds) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if _looking:
			rise.tween_property(model, "head_turn", look_at_camera, rise_seconds) \
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await pause(rise_seconds, held)
	release(held)


# Notes the shot the camera holds before a scene, once, so the scene's own
# shots (the chest's, the gift's) aren't mistaken for it.
func _begin_staging() -> void:
	if _staging:
		return
	_staging = true
	_shot_before = player.camera_rig.held_shot()


## The model of [param tool] to hold up, standing on end and turning (the
## knife point up, #207): its own model when it has one, otherwise a greybox
## bar in its colour. Freed by whoever adds it.
static func make_treasure(tool: HandTool) -> Node3D:
	if tool == null:
		return _treasure_of("", Vector3(0.15, 0.6, 0.06), Color.WHITE, 0.0)
	return _treasure_of(tool.model_path, tool.model_size, tool.color,
			tool.hold_up_turn_degrees)


## The model of [param item] to hold up (the captain's pot): its own model
## stood on end, handle up, turning on the spot; otherwise a greybox block.
static func make_item_treasure(item: Item) -> Node3D:
	return _treasure_of(item.model_path, item.model_size, item.color,
			ITEM_TURN_DEGREES)


# A treasure to hold up: the model at [param path] fitted into [param size]
# (a greybox block in [param tint] without it), lit and haloed, its middle on
# the hands. [param turn_degrees] turns it about its forward axis to stand it
# up (a knife point up, a pot handle up).
static func _treasure_of(path: String, size: Vector3, tint: Color,
		turn_degrees: float) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Treasure"
	# What stands it on end: its length (X, for our Meshy models) turned up.
	var turn: Node3D = Node3D.new()
	turn.name = "Turn"
	turn.rotation_degrees.z = turn_degrees
	root.add_child(turn)
	var bar: MeshInstance3D = MeshInstance3D.new()
	bar.name = "Greybox"
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	bar.mesh = box
	var colour: StandardMaterial3D = StandardMaterial3D.new()
	colour.albedo_color = tint
	colour.metallic = 0.4
	bar.material_override = colour
	turn.add_child(bar)
	# Lit as a treasure is, in the chest's green: a light of its own, and a
	# small soft halo behind it.
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "Light"
	light.light_color = TREASURE_GREEN
	light.light_energy = 0.6
	light.omni_range = 1.2
	root.add_child(light)
	var halo_mesh: QuadMesh = QuadMesh.new()
	halo_mesh.size = Vector2(0.55, 0.55)
	var halo_material: ShaderMaterial = ShaderMaterial.new()
	halo_material.shader = HALO_SHADER
	halo_material.set_shader_parameter(&"colour", TREASURE_GREEN)
	halo_material.set_shader_parameter(&"energy", 0.6)
	halo_mesh.material = halo_material
	var halo: MeshInstance3D = MeshInstance3D.new()
	halo.name = "Halo"
	halo.mesh = halo_mesh
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(halo)
	if not path.is_empty():
		var model: ThirdPartyModel = ThirdPartyModel.new()
		model.name = "Model"
		model.fit_size = size
		model.stand_ins = [bar]
		# Its middle on the hands, so it turns on the spot rather than round a
		# point off to one side (the pot orbited round its bowl, #207).
		model.dressed.connect(func(shown: bool) -> void:
			if shown:
				model.position = -_middle_of(model))
		turn.add_child(model)
		model.path = path
	return root


# Lowers whatever's held up: it's gone (it's on your toolbar by now), your
# arms come down, the camera's back as it was, and a chest's light settles.
func _put_away() -> void:
	if is_instance_valid(_treasure):
		_treasure.queue_free()
	_treasure = null
	var model: CharacterModel = _character()
	if model != null and model.hold_up > 0.0:
		create_tween().tween_property(model, "hold_up", 0.0, 0.35)
	if model != null and _looking:
		# Your head goes back to what it was watching before.
		var watch_before: Node3D = _watch_before
		var back: Tween = create_tween()
		back.tween_property(model, "head_turn", _turn_before, 0.35)
		back.tween_callback(func() -> void:
			if is_instance_valid(model):
				model.watch = watch_before if is_instance_valid(watch_before) else null)
	_looking = false
	_watch_before = null
	if is_instance_valid(player):
		# Back to the shot from before (the conversation's), or the free camera.
		if is_instance_valid(_shot_before):
			player.camera_rig.hold_shot(_shot_before, true)
		else:
			player.camera_rig.release_shot(true)
	_shot_before = null
	_staging = false
	if is_instance_valid(_gift_shot):
		_gift_shot.queue_free()
	_gift_shot = null
	if is_instance_valid(_chest):
		_chest.settle()
	_chest = null


func _on_ended(_tree_id: StringName) -> void:
	if _chest != null or is_instance_valid(_treasure) or is_instance_valid(_gift_shot):
		_put_away()


func _character() -> CharacterModel:
	if not is_instance_valid(player):
		return null
	return player.get_node_or_null("Model/Character") as CharacterModel


func _play(stream: AudioStream) -> void:
	if stream == null:
		return
	_sound.stream = stream
	_sound.play()


# The middle of everything drawn under [param model], in its parent's space.
static func _middle_of(model: Node3D) -> Vector3:
	var box: AABB = AABB()
	var first: bool = true
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if not mesh.visible or mesh.mesh == null:
			continue
		var to_model: Transform3D = Transform3D.IDENTITY
		var at: Node = mesh
		while at != model and at != null:
			to_model = (at as Node3D).transform * to_model
			at = at.get_parent()
		var part: AABB = to_model * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return Vector3.ZERO if first else model.transform * box.get_center() - model.position
