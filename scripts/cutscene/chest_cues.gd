class_name ChestCues
extends CueHandler
## The treasure chest's big moment, as in Ocarina of Time (#152). A
## [TreasureChest] plays [code]data/dialogue/chest.dlg[/code] when it's
## opened, and these cues stage it:
##
## [codeblock]
## @open     you step up to the chest, the camera looks over your shoulder,
##           you open it: the lid creaks up and the light pours out
## @hold_up  you turn round and hold the treasure up over your head, turning
##           slowly in the light, with a fanfare
## [/codeblock]
##
## The treasure stays held up while the lines are read. When the cutscene
## ends you lower it (it's on your toolbar by then: the script gives it), the
## camera is yours again, and the chest's light settles.

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
	return [&"open", &"hold_up"]


## The treasure held up, or null.
func treasure() -> Node3D:
	return _treasure if is_instance_valid(_treasure) else null


func _perform(cue: StringName, _args: PackedStringArray) -> void:
	if not is_instance_valid(player):
		warn("@%s needs the player (ChestCues' Player)" % cue)
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
	var held: int = hold()
	var shot: Marker3D = chest.hold_shot()
	player.face_towards(shot.global_position)
	player.camera_rig.hold_shot(shot, true)
	_treasure = make_treasure(chest.contents)
	chest.get_parent().add_child(_treasure)
	_treasure.global_position = chest.item_spot().global_position
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
	var root: Node3D = Node3D.new()
	root.name = "Treasure"
	var bar: MeshInstance3D = MeshInstance3D.new()
	bar.name = "Greybox"
	var box: BoxMesh = BoxMesh.new()
	box.size = tool.model_size if tool != null else Vector3(0.15, 0.6, 0.06)
	bar.mesh = box
	var colour: StandardMaterial3D = StandardMaterial3D.new()
	colour.albedo_color = tool.color if tool != null else Color.WHITE
	colour.metallic = 0.4
	bar.material_override = colour
	root.add_child(bar)
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
	if tool != null and not tool.model_path.is_empty():
		var model: ThirdPartyModel = ThirdPartyModel.new()
		model.name = "Model"
		model.look = tool.model_look
		model.fit_size = tool.model_size
		model.stand_ins = [bar]
		# Centred on the hands rather than sitting on them.
		model.position = Vector3.DOWN * tool.model_size.y / 2.0
		root.add_child(model)
		model.path = tool.model_path
	return root


func _on_ended(_tree_id: StringName) -> void:
	if _chest == null:
		return
	if is_instance_valid(_treasure):
		_treasure.queue_free()
	_treasure = null
	_held = false
	var model: CharacterModel = _character()
	if model != null:
		create_tween().tween_property(model, "hold_up", 0.0, 0.35)
	if is_instance_valid(player):
		player.camera_rig.release_shot(true)
	if is_instance_valid(_chest):
		_chest.settle()
	_chest = null


func _character() -> CharacterModel:
	if not is_instance_valid(player):
		return null
	return player.get_node_or_null("Model/Character") as CharacterModel


func _play(stream: AudioStream) -> void:
	if stream == null:
		return
	_sound.stream = stream
	_sound.play()
