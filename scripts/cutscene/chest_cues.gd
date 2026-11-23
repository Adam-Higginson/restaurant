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

## The player who opens chests.
@export var player: Player3D
## How long after you start opening it the lid lifts, in seconds: when the
## hands reach it in the animation.
@export var lid_delay: float = 0.55
## The animation of opening a chest, and how long it plays.
@export var open_animation: StringName = &"Chest_Open"
@export var open_animation_seconds: float = 1.4
## How long the treasure takes to rise from the chest to over your head.
@export var rise_seconds: float = 0.9
## How fast the treasure turns while it's held up, in turns a second.
@export var spin_turns: float = 0.35
## Where the camera stands for a gift held up without a chest: how far in
## front of you, how high, and how far round to one side, in degrees.
@export var gift_shot_distance: float = 2.3
@export var gift_shot_height: float = 1.35
@export var gift_shot_angle: float = 40.0
## The lid creaking up, and the fanfare as the treasure is held up.
@export var creak: AudioStream
@export var fanfare: AudioStream

## The chest being opened now, or null.
var _chest: TreasureChest = null
## The treasure being held up, or null.
var _treasure: Node3D = null
## Whether the treasure has reached the hands and follows them.
var _held: bool = false
var _sound: AudioStreamPlayer = null
## The camera's mark for a gift held up without a chest, or null.
var _gift_shot: Marker3D = null


func _ready() -> void:
	super._ready()
	_sound = AudioStreamPlayer.new()
	_sound.name = "ChestSound"
	add_child(_sound)


func _process(delta: float) -> void:
	if not is_instance_valid(_treasure):
		return
	_treasure.rotate_y(TAU * spin_turns * delta)
	var model: CharacterModel = _character()
	if _held and model != null:
		_treasure.global_position = _treasure.global_position.lerp(model.held_point(),
				minf(1.0, 12.0 * delta))


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
	_raise(make_treasure(chest.contents), chest.hold_shot(), chest.get_parent(),
			chest.item_spot().global_position)


# Holds up [param id] (an item's or a tool's), handed over rather than found
# in a chest: it rises from your hands, and the camera looks at you from in
# front, a little to one side.
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
	var at: Vector3 = player.global_position + round_by * gift_shot_distance \
			+ Vector3.UP * gift_shot_height
	_gift_shot.global_transform = Transform3D(Basis.looking_at(head - at, Vector3.UP), at)
	_raise(treasure_node, _gift_shot, player.get_parent(),
			player.global_position + Vector3.UP * 1.1 + player.facing * 0.3)


# Raises [param treasure_node] from [param from] to over your head as your
# arms go up, with the fanfare and the camera at [param shot]. It joins
# [param world] so it stays put in the world as it rises.
func _raise(treasure_node: Node3D, shot: Marker3D, world: Node, from: Vector3) -> void:
	var held: int = hold()
	player.face_towards(shot.global_position)
	player.camera_rig.hold_shot(shot, true)
	if is_instance_valid(_treasure):
		_treasure.queue_free()
	_treasure = treasure_node
	world.add_child(_treasure)
	_treasure.global_position = from
	_held = false
	var model: CharacterModel = _character()
	if is_skipping():
		_held = true
		if model != null:
			model.hold_up = 1.0
		release(held)
		return
	_play(fanfare)
	var rise: Tween = create_tween().set_parallel()
	var to: Vector3 = model.hold_up_point() if model != null \
			else player.global_position + Vector3.UP * 2.0
	rise.tween_property(_treasure, "global_position", to, rise_seconds) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if model != null:
		rise.tween_property(model, "hold_up", 1.0, rise_seconds * 0.7) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await pause(rise_seconds, held)
	_held = true
	release(held)


## The model of [param tool] to hold up: its own model when it has one,
## otherwise a greybox bar in its colour. Freed by whoever adds it.
static func make_treasure(tool: HandTool) -> Node3D:
	if tool == null:
		return _treasure_of("", null, Vector3(0.15, 0.6, 0.06), Color.WHITE, false)
	return _treasure_of(tool.model_path, tool.model_look, tool.model_size, tool.color, false)


## The model of [param item] to hold up (the heron's pan): its own model
## stood on end, handle up, so it shows its face; otherwise a greybox block.
static func make_item_treasure(item: Item) -> Node3D:
	return _treasure_of(item.model_path, item.model_look, item.model_size, item.color, true)


# A treasure to hold up: the model at [param path] fitted into [param size]
# (a greybox block in [param tint] without it), lit and haloed, centred on
# the hands. [param stood_up] turns a flat thing (a pan) on end.
static func _treasure_of(path: String, look: ArtLook, size: Vector3, tint: Color,
		stood_up: bool) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Treasure"
	# What turns it on end, if it's stood up: its length (Z) becomes its height.
	var turn: Node3D = Node3D.new()
	turn.name = "Turn"
	if stood_up:
		turn.rotation_degrees.x = -90.0
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
	# Lit as a treasure is: a warm light of its own, and a soft halo behind
	# it bright enough to bloom.
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "Light"
	light.light_color = Color(1.0, 0.82, 0.5)
	light.light_energy = 1.4
	light.omni_range = 1.4
	root.add_child(light)
	var halo_mesh: QuadMesh = QuadMesh.new()
	halo_mesh.size = Vector2(0.9, 0.9)
	var halo_material: ShaderMaterial = ShaderMaterial.new()
	halo_material.shader = HALO_SHADER
	halo_material.set_shader_parameter(&"energy", 0.9)
	halo_mesh.material = halo_material
	var halo: MeshInstance3D = MeshInstance3D.new()
	halo.name = "Halo"
	halo.mesh = halo_mesh
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(halo)
	if not path.is_empty():
		var model: ThirdPartyModel = ThirdPartyModel.new()
		model.name = "Model"
		model.look = look
		model.fit_size = size
		model.stand_ins = [bar]
		# Centred on the hands rather than sitting on them.
		model.position = Vector3.DOWN * size.y / 2.0
		turn.add_child(model)
		model.path = path
	return root


# Lowers whatever's held up: it's gone (it's on your toolbar by now), your
# arms come down, the camera's back as it was, and a chest's light settles.
func _put_away() -> void:
	if is_instance_valid(_treasure):
		_treasure.queue_free()
	_treasure = null
	_held = false
	var model: CharacterModel = _character()
	if model != null and model.hold_up > 0.0:
		create_tween().tween_property(model, "hold_up", 0.0, 0.35)
	if is_instance_valid(player):
		player.camera_rig.release_shot(true)
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
