class_name LanternField
extends Node3D
## The dead lanterns hanging in the deep below you in the underwater set,
## and what happens to them. Its children are the lanterns (each a Node3D
## with a [code]Glass[/code] mesh drawn by shaders/dead_glass.gdshader).
##
## There's no seabed. The lanterns hang at many depths, further and
## fainter until the murk takes them, which is what says how deep the water
## is. They're empty: they give no light of their own, and show only as
## dark shapes when the living lantern's flare or the lightning finds them.
##
## - [b]Sinking.[/b] Each is still going down, very slowly, at its own
##   pace, turning a little as it goes.
## - [b]The thing.[/b] Something far bigger passes beneath them
##   ([member thing], a dark mass that's never lit: it's seen only by what
##   it hides). Each lantern it comes near rocks in its wake and settles.
## - [b]Lightning.[/b] It joins the group [Lightning] tells about every
##   flash, and passes the flash on to the lanterns' glass as a cold sheen.

## How fast the lanterns sink, in metres a second: the slowest and fastest.
@export var sink_slowest: float = 0.04
@export var sink_fastest: float = 0.12
## How far each turns about its upright as it sinks, in radians a second.
@export var turn_speed: float = 0.05
## The thing that passes beneath them. Optional.
@export var thing: Node3D
## How long the thing is, along its own X, in metres.
@export var thing_length: float = 60.0
## How near it must come to a lantern to rock it, in metres.
@export var wake_reach: float = 9.0
## How far a lantern tips in its wake, in radians, and how long it takes
## to settle, in seconds.
@export var rock_angle: float = 0.5
@export var rock_seconds: float = 3.0
## How much the dead lanterns flicker, 0 to 1: as his light pours into you
## (#183), faint embers sputter in them, each to its own rhythm, as if
## something passed through them all. A clip moves it; at 0 they're as
## they were (dark, or the steady glow a few of them keep).
@export_range(0.0, 1.0) var flicker: float = 0.0:
	set(value):
		flicker = clampf(value, 0.0, 1.0)

var _lanterns: Array[Node3D] = []
## The glow each lantern has of its own (most none), kept while it flickers.
var _base_ember: PackedFloat32Array = []
var _rest: Array[Transform3D] = []
## How far each lantern has sunk since it was last put back, in metres.
var _sunk: PackedFloat32Array = []
## Seconds since each lantern was caught in the wake, or -1.
var _since_rocked: PackedFloat32Array = []
## Whether each lantern was within the wake last time we looked.
var _near: PackedByteArray = []
var _flash: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	add_to_group(Lightning.LIT_GROUP)
	for child: Node in get_children():
		var lantern: Node3D = child as Node3D
		if lantern != null and lantern.has_node("Glass"):
			_lanterns.append(lantern)
			_rest.append(lantern.transform)
			var glass: GeometryInstance3D = lantern.get_node("Glass") as GeometryInstance3D
			var own: float = 0.0
			if glass != null and glass.get_instance_shader_parameter(&"ember") != null:
				own = glass.get_instance_shader_parameter(&"ember")
			_base_ember.append(own)
	_sunk.resize(_lanterns.size())
	_since_rocked.resize(_lanterns.size())
	_near.resize(_lanterns.size())
	reset()


func _process(delta: float) -> void:
	advance(delta)


## How many lanterns there are.
func count() -> int:
	return _lanterns.size()


## Puts every lantern back where it began, still and upright.
func reset() -> void:
	_time = 0.0
	_sunk.fill(0.0)
	_since_rocked.fill(-1.0)
	_near.fill(0)
	_apply()


## Moves everything on by [param delta] seconds: the lanterns sink a
## little further, and any the thing has just come near begin to rock.
func advance(delta: float) -> void:
	_time += delta
	for index: int in _lanterns.size():
		_sunk[index] += sink_speed_of(index) * delta
		var near: bool = is_instance_valid(thing) and distance_to_thing(
				_lanterns[index].global_position) <= wake_reach
		# Caught as it arrives: the wake rocks it once.
		if near and _near[index] == 0:
			_since_rocked[index] = 0.0
		elif _since_rocked[index] >= 0.0:
			_since_rocked[index] += delta
			if _since_rocked[index] > rock_seconds:
				_since_rocked[index] = -1.0
		_near[index] = 1 if near else 0
	_apply()


## How fast lantern [param index] sinks, in metres a second: each has its
## own pace between [member sink_slowest] and [member sink_fastest].
func sink_speed_of(index: int) -> float:
	return lerpf(sink_slowest, sink_fastest, share_of(index))


## How far lantern [param index] has sunk since it was put back, in metres.
func sunk_of(index: int) -> float:
	return _sunk[index]


## How brightly the lightning shows on the lanterns' glass right now, 0 to
## 1: nothing between flashes.
func sheen() -> float:
	return _flash


## How far lantern [param index] is tipped by the wake right now, in radians.
func tilt_of(index: int) -> float:
	if _since_rocked[index] < 0.0:
		return 0.0
	return rock_after(_since_rocked[index], rock_seconds) * rock_angle


## How far [param place] (in the world) is from the thing: from the nearest
## point along its length, in metres.
func distance_to_thing(place: Vector3) -> float:
	if not is_instance_valid(thing):
		return INF
	var along: Vector3 = thing.global_transform.basis.x.normalized()
	var offset: Vector3 = place - thing.global_position
	var half: float = thing_length * 0.5
	var nearest: Vector3 = along * clampf(offset.dot(along), -half, half)
	return offset.distance_to(nearest)


## How much glow lantern [param index] has right now, 0 to 1: its own steady
## ember, or more while they flicker.
func ember_of(index: int) -> float:
	return maxf(_base_ember[index], flicker * sputter(index, _time))


## How much a flickering lantern [param index] is alight [param time]
## seconds in, 0 to 1: short uneven sputters, each to its own rhythm, out
## more often than in.
static func sputter(index: int, time: float) -> float:
	var pace: float = 4.0 + share_of(index + 3) * 7.0
	var wave: float = sin(time * pace + share_of(index + 11) * 40.0) \
			* sin(time * pace * 0.37 + share_of(index + 17) * 20.0)
	return clampf(wave * 2.5 - 0.9, 0.0, 1.0) * (0.35 + 0.65 * share_of(index + 5))


## How bright the lightning is now: 0 dark, 1 the brightest moment.
func set_lightning(brightness: float) -> void:
	_flash = clampf(brightness, 0.0, 1.0)
	_apply()


## A number from 0 to 1 that's always the same for lantern [param index]
## and different for its neighbours: what makes each one its own.
static func share_of(index: int) -> float:
	return fposmod(sin(float(index) * 12.9898 + 4.1) * 43758.5453, 1.0)


## How far a lantern is tipped [param seconds] after the wake caught it, as
## a share of the furthest it tips: it swings one way, back past upright,
## and settles within [param lasting] seconds.
static func rock_after(seconds: float, lasting: float) -> float:
	if seconds < 0.0 or seconds >= lasting or lasting <= 0.0:
		return 0.0
	var t: float = seconds / lasting
	return sin(t * TAU * 2.0) * (1.0 - t) * (1.0 - t)


func _apply() -> void:
	for index: int in _lanterns.size():
		var lantern: Node3D = _lanterns[index]
		var glass: GeometryInstance3D = lantern.get_node("Glass") as GeometryInstance3D
		if glass != null:
			glass.set_instance_shader_parameter(&"cold", _flash)
			if flicker > 0.0 or _base_ember[index] > 0.0:
				glass.set_instance_shader_parameter(&"ember", ember_of(index))
			else:
				glass.set_instance_shader_parameter(&"ember", 0.0)
		var rest: Transform3D = _rest[index]
		var turned: Basis = Basis(Vector3.UP, _time * turn_speed * (share_of(index + 7) - 0.5) * 2.0)
		var rocked: Basis = Basis(Vector3.RIGHT, tilt_of(index))
		lantern.transform = Transform3D(turned * rest.basis * rocked,
				rest.origin + Vector3.DOWN * _sunk[index])
