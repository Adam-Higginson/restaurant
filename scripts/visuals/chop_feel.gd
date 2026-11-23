class_name ChopFeel
extends Node3D
## How a cut at the chopping board feels (#152), the way the duel's blows do
## (#107): you swing the knife down, and how well the cut was timed on the
## chop meter shows in everything that follows.
##
## - [b]Perfect[/b]: a short freeze (hitstop), a bright slice and knock with a
##   glassy chime, a spray of juice and a burst of gold glints, and
##   "Perfect!" pops up in gold.
## - [b]Good[/b]: a shorter freeze, the slice and knock, the juice, "Good".
## - [b]Ragged[/b]: no freeze, a dull low knock and no slice, a little juice,
##   "Ragged" in grey.
##
## A child of a [Counter3D], placed on its top; it listens for the counter's
## [signal Counter3D.chopped]. The knife and the freeze belong to whoever cut
## (their [Duellist] and [HitStop]).

const PERFECT_COLOUR: Color = Color(1.0, 0.8, 0.3)
const GOOD_COLOUR: Color = Color(0.98, 0.95, 0.88)
const RAGGED_COLOUR: Color = Color(0.62, 0.6, 0.58)

## The knife going through, the knock of it on the board, and the chime of a
## perfect cut.
@export var slice_sound: AudioStream
@export var knock_sound: AudioStream
@export var chime_sound: AudioStream
## How many physics ticks a perfect cut and a good cut freeze the game for.
@export var perfect_ticks: int = 4
@export var good_ticks: int = 2
## How long the swing takes, in seconds: the knife hand lifts, comes down
## onto the food (see [method CharacterModel.chop_at]) and goes back.
@export var chop_seconds: float = 0.3

var _slice: AudioStreamPlayer3D
var _knock: AudioStreamPlayer3D
var _chime: AudioStreamPlayer3D
var _juice: CPUParticles3D
var _glints: CPUParticles3D

@onready var _counter: Counter3D = get_parent() as Counter3D


func _ready() -> void:
	_slice = _sound_player("Slice", slice_sound)
	_knock = _sound_player("Knock", knock_sound)
	_chime = _sound_player("Chime", chime_sound)
	_juice = _burst("Juice", 16, 1.8, Vector2(0.025, 0.025))
	_juice.gravity = Vector3(0, -9.0, 0)
	_glints = _burst("Glints", 14, 1.2, Vector2(0.04, 0.04))
	_glints.gravity = Vector3.ZERO
	var glint_material: ShaderMaterial = ShaderMaterial.new()
	glint_material.shader = preload("res://shaders/sparkle.gdshader")
	(_glints.mesh as QuadMesh).material = glint_material
	if _counter != null:
		_counter.chopped.connect(_on_chopped)


## Plays the feel of a cut graded [param grade] (a [enum ChopMeter.Grade]):
## the swing now, and the rest as the knife meets the board.
func play(grade: int) -> void:
	var player: Player3D = _counter.last_chopper() if _counter != null else null
	if player != null:
		_swing(player)
	var delay: float = chop_seconds * CharacterModel.CHOP_CONTACT if player != null else 0.0
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if not is_inside_tree():
		return
	_land(player, grade)


func _on_chopped(grade: int) -> void:
	play(grade)


# The knife comes down: it's shown in the hand and the arm swings.
func _swing(player: Player3D) -> void:
	var duellist: Duellist = player.get_node_or_null("Duellist") as Duellist
	if duellist != null:
		duellist.show_knife(chop_seconds + 0.15)
	var model: CharacterModel = player.get_node_or_null("Model/Character") as CharacterModel
	if model != null:
		model.chop_at(global_position, chop_seconds)


# The knife meets the board: a good or perfect cut freezes the game a
# moment, and how it went is heard, seen and said.
func _land(player: Player3D, grade: int) -> void:
	var perfect: bool = grade == ChopMeter.Grade.PERFECT
	var ragged: bool = grade == ChopMeter.Grade.RAGGED
	var ticks: int = perfect_ticks if perfect else (0 if ragged else good_ticks)
	var stop: HitStop = player.get_node_or_null("HitStop") as HitStop \
			if is_instance_valid(player) else null
	if stop != null and ticks > 0:
		stop.freeze(ticks)
	if not ragged:
		_play(_slice, 1.12 if perfect else 1.0)
	_play(_knock, 0.72 if ragged else (1.15 if perfect else 1.0))
	if perfect:
		_play(_chime, 1.3)
		_glints.restart()
	_spray(ragged)
	var words: String = "Perfect!" if perfect else ("Ragged" if ragged else "Good")
	var colour: Color = PERFECT_COLOUR if perfect else (RAGGED_COLOUR if ragged else GOOD_COLOUR)
	# In the world the counter's in, so it rises from where the cut was.
	var world: Node = _counter.get_parent() if _counter != null else self
	DamageNumber.spawn_words(world, global_position + Vector3.UP * 0.12, words, colour, perfect)


# Juice in the colour of what's on the board.
func _spray(ragged: bool) -> void:
	var colour: Color = Color(0.85, 0.2, 0.15)
	var item: ItemInstance = _counter.slot.get_item() if _counter != null else null
	if item != null and item.is_vessel():
		var food: Array[ItemInstance] = item.contents.get_contents()
		if not food.is_empty():
			colour = food[food.size() - 1].item.color
	_juice.color = colour
	_juice.amount = 6 if ragged else 16
	_juice.restart()


func _play(player: AudioStreamPlayer3D, pitch: float) -> void:
	if player.stream == null:
		return
	player.pitch_scale = pitch
	player.play()


func _sound_player(sound_name: String, stream: AudioStream) -> AudioStreamPlayer3D:
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.name = sound_name
	player.stream = stream
	player.unit_size = 4.0
	add_child(player)
	return player


# A one-shot burst of little quads flying up and out.
func _burst(burst_name: String, count: int, speed: float, size: Vector2) -> CPUParticles3D:
	var burst: CPUParticles3D = CPUParticles3D.new()
	burst.name = burst_name
	burst.emitting = false
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = count
	burst.lifetime = 0.5
	burst.direction = Vector3.UP
	burst.spread = 55.0
	burst.initial_velocity_min = speed * 0.5
	burst.initial_velocity_max = speed
	var quad: QuadMesh = QuadMesh.new()
	quad.size = size
	var flat: StandardMaterial3D = StandardMaterial3D.new()
	flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	flat.vertex_color_use_as_albedo = true
	quad.material = flat
	burst.mesh = quad
	add_child(burst)
	return burst
