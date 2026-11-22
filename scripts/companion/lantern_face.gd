class_name LanternFace
extends Node3D
## The lantern spirit's body, and everything about it that shows what he
## feels. He has three voices:
##
## - His [b]eyes[/b] change shape with [member expression]: round for
##   surprise, slanted in for determined, slanted out for worried, flat for
##   tired, thin lines for asleep.
## - His [b]flame[/b], drawn on his panes as pixel fire like every other
##   lantern aboard, follows [member strength] (lower, flickering harder
##   and cooling from amber to blue as he weakens), tips towards
##   [member lean], and stands taller or shrinks back with [member swell].
## - His [b]glass[/b] shows what he's been through: [member fogged],
##   [member streaked] with rain, [member cracked]. Its front is a
##   [member door] he can open.
##
## Everything eases to its new look over a moment rather than snapping. The
## same body is used wherever he appears (at your shoulder, on his hook at
## the stern, in the water), so he looks and acts the same everywhere. A
## cutscene directs one with [code]@look hook_lantern determined[/code]
## (see [LookCues] and [method direct]); a clip can move [member strength],
## [member lean], [member swell] and [member door] on the timeline.

## A look for his eyes.
enum Look {
	## His usual look.
	CALM,
	## Round and wide: he's heard or seen something.
	SURPRISED,
	## Narrowed and slanted in: he's set on something.
	DETERMINED,
	## Slanted out: sad, or afraid.
	WORRIED,
	## Huge and a little slanted out: asking.
	PLEADING,
	## Squeezed shut.
	EFFORT,
	## Flat, heavy lines.
	TIRED,
	## Thin, drooping lines.
	ASLEEP,
	## Thin and lifted, like a smile.
	PLEASED,
}

## The group every face joins, so a cutscene can find one by name.
const GROUP: StringName = &"lantern_faces"
## Each look's eye shape: how wide (x) and tall (y) an eye is, as a share of
## its usual size, and how far it tilts in radians (z): positive slants the
## inner ends down (determined), negative the outer ends down (worried).
const SHAPES: Dictionary[Look, Vector3] = {
	Look.CALM: Vector3(1.0, 1.0, 0.0),
	Look.SURPRISED: Vector3(1.3, 1.35, 0.0),
	Look.DETERMINED: Vector3(1.25, 0.6, 0.5),
	Look.WORRIED: Vector3(1.05, 0.85, -0.45),
	Look.PLEADING: Vector3(1.35, 1.5, -0.2),
	Look.EFFORT: Vector3(1.5, 0.2, 0.35),
	Look.TIRED: Vector3(1.55, 0.28, 0.0),
	Look.ASLEEP: Vector3(1.5, 0.16, -0.3),
	Look.PLEASED: Vector3(1.3, 0.34, -0.4),
}
## How far each look lifts the eyes, in metres: up for pleased, down for tired.
const LIFTS: Dictionary[Look, float] = {
	Look.PLEADING: 0.008,
	Look.PLEASED: 0.012,
	Look.TIRED: -0.008,
	Look.ASLEEP: -0.01,
}
## The words a script can use after [code]@look someone[/code], and the look
## each gives his eyes.
const LOOK_WORDS: Dictionary[String, Look] = {
	"calm": Look.CALM,
	"surprised": Look.SURPRISED,
	"determined": Look.DETERMINED,
	"worried": Look.WORRIED,
	"pleading": Look.PLEADING,
	"effort": Look.EFFORT,
	"tired": Look.TIRED,
	"asleep": Look.ASLEEP,
	"pleased": Look.PLEASED,
}
## The words that change his glass instead: each turns one thing on or off.
const GLASS_WORDS: PackedStringArray = ["fogged", "clear", "streaked", "dry", "cracked",
		"mended"]
## His light at full strength, and at his weakest.
const WARM: Color = Color(1.0, 0.72, 0.36)
const COLD: Color = Color(0.42, 0.68, 1.0)
## How far his door swings when it's wide open, in radians.
const DOOR_SWING: float = 1.9

## What a script calls this one: [code]hook_lantern[/code]. Empty if no
## script directs it.
@export var look_name: String = ""
## The look of his eyes.
@export var expression: Look = Look.CALM
## How strong his flame is, 0 to 1: its size, its steadiness and its colour.
@export_range(0.0, 1.0) var strength: float = 1.0
## The way his flame tips, in his own space: (1, 0, 0) leans it to his
## left as far as it goes. Longer than 1 counts as 1.
@export var lean: Vector3 = Vector3.ZERO
## How tall his flame stands against its usual height for his strength: 1
## as usual, more when it bristles before an effort, less as he breathes
## out. A clip moves it to make him pant.
@export_range(0.0, 2.5) var swell: float = 1.0
## How far the door in the front of his glass is open: 0 shut, 1 wide.
@export_range(0.0, 1.0) var door: float = 0.0
## Whether his glass is clouded over: he's flustered.
@export var fogged: bool = false
## Whether rain is running down his glass.
@export var streaked: bool = false
## Whether his glass is cracked: he's been badly hurt.
@export var cracked: bool = false
## A light to colour and dim with his flame. Optional: the companion looks
## after his own.
@export var light: OmniLight3D
## How bright [member light] is at full strength.
@export var light_energy: float = 2.0
## How quickly a new look arrives: higher is snappier.
@export var blend_speed: float = 12.0
## The shortest and longest wait between blinks, in seconds.
@export var blink_min: float = 2.5
@export var blink_max: float = 6.0
## How long a blink takes, in seconds.
@export var blink_seconds: float = 0.14

## Whether a cutscene has taken over his look (see [method direct]), so
## whoever usually decides it should leave it alone.
var directed: bool:
	get:
		return _directed

var _directed: bool = false
## The eyes' shape now, easing towards the look's (see [constant SHAPES]).
var _shape: Vector3 = Vector3(1.0, 1.0, 0.0)
var _lift: float = 0.0
## The flame and glass now, each easing towards what's asked for.
var _strength_now: float = 1.0
var _lean_now: Vector3 = Vector3.ZERO
var _swell_now: float = 1.0
var _door_now: float = 0.0
var _fog: float = 0.0
var _streaks: float = 0.0
var _crack: float = 0.0
var _blink_wait: float = 0.0
var _blink_left: float = 0.0
var _time: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _glass_material: ShaderMaterial = null

@onready var _eyes: Node3D = $Eyes
@onready var _eye_left: Node3D = $Eyes/EyeLeft
@onready var _eye_right: Node3D = $Eyes/EyeRight
@onready var _glass: MeshInstance3D = $Glass
@onready var _door: Node3D = $Door
@onready var _eye_spacing: float = absf(_eye_left.position.x)


func _ready() -> void:
	add_to_group(GROUP)
	# His own copies, so one lantern's look never changes another's.
	_glass_material = (_glass.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	_glass.material_override = _glass_material
	# Each lantern flickers its own way.
	_glass_material.set_shader_parameter("seed", _rng.randf())
	_blink_wait = _rng.randf_range(blink_min, blink_max)
	snap()


func _process(delta: float) -> void:
	_time += delta
	var blend: float = 1.0 - exp(-blend_speed * delta)
	_shape = _shape.lerp(target_shape(), blend)
	_lift = lerpf(_lift, target_lift(), blend)
	_strength_now = lerpf(_strength_now, strength, blend)
	_lean_now = _lean_now.lerp(lean.limit_length(1.0), blend)
	_swell_now = lerpf(_swell_now, swell, blend)
	_door_now = lerpf(_door_now, door, blend)
	# The glass changes more slowly: fog gathers, a crack creeps.
	var slow: float = 1.0 - exp(-2.5 * delta)
	_fog = lerpf(_fog, 1.0 if fogged else 0.0, slow)
	_streaks = lerpf(_streaks, 1.0 if streaked else 0.0, slow)
	_crack = move_toward(_crack, 1.0 if cracked else 0.0, delta * 1.2)
	_blink(delta)
	_apply()


## Jumps straight to the look that's asked for, with no easing.
func snap() -> void:
	_shape = target_shape()
	_lift = target_lift()
	_strength_now = strength
	_lean_now = lean.limit_length(1.0)
	_swell_now = swell
	_door_now = door
	_fog = 1.0 if fogged else 0.0
	_streaks = 1.0 if streaked else 0.0
	_crack = 1.0 if cracked else 0.0
	if is_node_ready():
		_apply()


## Takes over his look for a cutscene: [param word] is one of
## [constant LOOK_WORDS] (his eyes) or [constant GLASS_WORDS] (his glass).
## Returns false, changing nothing, for a word that's neither.
func direct(word: String) -> bool:
	if LOOK_WORDS.has(word):
		expression = LOOK_WORDS[word]
	else:
		match word:
			"fogged":
				fogged = true
			"clear":
				fogged = false
			"streaked":
				streaked = true
			"dry":
				streaked = false
			"cracked":
				cracked = true
			"mended":
				cracked = false
			_:
				return false
	_directed = true
	return true


## Gives his look back to whoever usually decides it (the cutscene's over).
func release() -> void:
	_directed = false


## Whether [param word] is something a script can say after
## [code]@look someone[/code].
static func knows(word: String) -> bool:
	return LOOK_WORDS.has(word) or GLASS_WORDS.has(word)


## Blinks once, now. Nothing happens if his eyes are already shut.
func blink() -> void:
	if can_blink():
		_blink_left = blink_seconds


## Whether his eyes are open enough to blink: not while asleep or squeezed shut.
func can_blink() -> bool:
	return expression != Look.ASLEEP and expression != Look.EFFORT


## The eye shape the current look asks for (see [constant SHAPES]).
func target_shape() -> Vector3:
	return SHAPES[expression]


## How far the current look lifts his eyes, in metres (see [constant LIFTS]).
func target_lift() -> float:
	return LIFTS[expression] if LIFTS.has(expression) else 0.0


## His eyes' shape right now, part-way to [method target_shape] if a look
## has just changed.
func eye_shape() -> Vector3:
	return _shape


## The colour of his flame and light for [param how_strong] he is, 0 to 1:
## blue at his weakest, amber from about half strength up.
static func colour_for(how_strong: float) -> Color:
	return COLD.lerp(WARM, smoothstep(0.08, 0.55, how_strong))


## The colour of his flame right now.
func flame_colour() -> Color:
	return colour_for(_strength_now)


## How tall his flame is right now, as a share of its full height: more
## than 1 while it bristles (see [member swell]).
func flame_size() -> float:
	return lerpf(0.3, 1.0, _strength_now) * _swell_now


## How far his door is open right now, 0 to 1.
func door_open() -> float:
	return _door_now


## The way his flame is tipping right now, in his own space, up to 1 long.
func flame_lean() -> Vector3:
	return _lean_now


## How far his glass is clouded, streaked and cracked right now, each 0 to 1.
func glass_state() -> Vector3:
	return Vector3(_fog, _streaks, _crack)


func _blink(delta: float) -> void:
	if _blink_left > 0.0:
		_blink_left -= delta
		var t: float = clampf(_blink_left / blink_seconds, 0.0, 1.0)
		# Shut in the middle of the blink, open at either end.
		_eyes.scale.y = maxf(absf(t * 2.0 - 1.0), 0.1)
		return
	_eyes.scale.y = 1.0
	if not can_blink():
		return
	_blink_wait -= delta
	if _blink_wait <= 0.0:
		blink()
		_blink_wait = _rng.randf_range(blink_min, blink_max)


# Puts the eased values onto the eyes, the flame, the glass and the light.
func _apply() -> void:
	for eye: Node3D in [_eye_left, _eye_right]:
		# The left eye is the mirror image of the right.
		var side: float = -1.0 if eye == _eye_left else 1.0
		eye.scale = Vector3(_shape.x, _shape.y, 1.0)
		eye.rotation.z = _shape.z * side
		eye.position = Vector3(_eye_spacing * side, _lift, 0.0)
	# The shader draws his flame on the panes from these.
	_glass_material.set_shader_parameter("strength", _strength_now)
	_glass_material.set_shader_parameter("lean", _lean_now)
	_glass_material.set_shader_parameter("swell", _swell_now)
	_door.rotation.y = _door_now * DOOR_SWING
	_glass_material.set_shader_parameter("fog", _fog)
	_glass_material.set_shader_parameter("streaks", _streaks)
	_glass_material.set_shader_parameter("crack", _crack)
	if is_instance_valid(light):
		light.light_color = flame_colour()
		light.light_energy = light_energy * lerpf(0.15, 1.0, _strength_now)
