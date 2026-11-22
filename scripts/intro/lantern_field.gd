class_name LanternField
extends Node3D
## The dead lanterns on the seabed in the underwater set, and what happens
## to them. Its children are the lanterns (each a Node3D with a
## [code]Glass[/code] mesh drawn by shaders/dead_glass.gdshader).
##
## - [b]The flare.[/b] When the living lantern catches alight, a ring of
##   light spreads from him ([member burst]). As it reaches each dead
##   lantern, that one glints and then keeps a faint glow that fades
##   ([member glow_seconds]). One of them, the [member keeper], keeps it far
##   longer.
## - [b]The thing.[/b] Something long is passing along the seabed. It's
##   never drawn: it's a gap ([member gap], [member gap_centre]) inside
##   which the lanterns go dark and the seabed ([member floor_mesh], drawn
##   by shaders/seabed.gdshader) loses the lightning's net of light. Each
##   lantern it reaches rocks in its wake and settles.
## - [b]Lightning.[/b] It joins the group [Lightning] tells about every
##   flash, and passes the flash on to the lanterns' glass and the seabed.
##
## A clip moves [member gap] and [member gap_centre]; the rest follows.

## How long a lantern's glint lasts as the light reaches it, in seconds.
const GLINT_SECONDS: float = 0.35
## How bright the glint is against the glow that follows it.
const GLINT_BRIGHTNESS: float = 3.0
## How bright the glow is just after the glint, before it fades.
const AFTERGLOW: float = 0.4

## The burst of light that lights them. Optional: without one, set
## [member front] yourself.
@export var burst: LightBurst
## How long a lantern's glow takes to fade after it's lit, in seconds.
@export var glow_seconds: float = 5.0
## The one lantern that keeps its glow. Optional.
@export var keeper: Node3D
## How long the keeper's glow takes to fade, in seconds.
@export var keeper_seconds: float = 90.0
## The seabed, told where the gap is and how bright the lightning is.
@export var floor_mesh: MeshInstance3D
## How much the thing is there: 0 not at all, 1 fully.
@export_range(0.0, 1.0) var gap: float = 0.0
## The middle of the thing, in this node's space. A clip slides it along.
@export var gap_centre: Vector3 = Vector3.ZERO
## Which way it lies and travels: an angle about the upright, in radians.
## 0 is along X.
@export var gap_heading: float = 0.0
## How long and how wide it is, in metres.
@export var gap_length: float = 26.0
@export var gap_width: float = 3.4
## How far a lantern tips in its wake, in radians, and how long it takes
## to settle, in seconds.
@export var rock_angle: float = 0.4
@export var rock_seconds: float = 2.6

## How far the light has spread from where it started, in metres. Follows
## [member burst] if there is one.
var front: float = 0.0
## Where the light started, in the world. Follows [member burst] too.
var light_origin: Vector3 = Vector3.ZERO

var _lanterns: Array[Node3D] = []
var _rest: Array[Transform3D] = []
## Seconds since each lantern was lit, or -1 if it hasn't been.
var _since_lit: PackedFloat32Array = []
## Seconds since each lantern was caught in the wake, or -1.
var _since_rocked: PackedFloat32Array = []
## How deep in the gap each lantern is right now, 0 to 1.
var _dark: PackedFloat32Array = []
var _flash: float = 0.0


func _ready() -> void:
	add_to_group(Lightning.LIT_GROUP)
	for child: Node in get_children():
		var lantern: Node3D = child as Node3D
		if lantern != null and lantern.has_node("Glass"):
			_lanterns.append(lantern)
			_rest.append(lantern.transform)
	_since_lit.resize(_lanterns.size())
	_since_rocked.resize(_lanterns.size())
	_dark.resize(_lanterns.size())
	reset()


func _process(delta: float) -> void:
	if is_instance_valid(burst):
		light_origin = burst.global_position
		front = burst.size_now() * 0.5 if burst.spread > 0.0 else 0.0
	advance(delta)


## How many lanterns there are.
func count() -> int:
	return _lanterns.size()


## Puts every lantern back as it was before any light reached it.
func reset() -> void:
	_since_lit.fill(-1.0)
	_since_rocked.fill(-1.0)
	_dark.fill(0.0)
	_apply()


## Moves everything on by [param delta] seconds: lights the lanterns the
## light has reached, fades the ones already lit, darkens those in the gap
## and rocks the ones it has just reached.
func advance(delta: float) -> void:
	# The light going back to nothing means the scene is starting again.
	if front <= 0.0 and is_instance_valid(burst):
		_since_lit.fill(-1.0)
	for index: int in _lanterns.size():
		var place: Vector3 = _lanterns[index].global_position
		if _since_lit[index] >= 0.0:
			_since_lit[index] += delta
		elif front > 0.0 and place.distance_to(light_origin) <= front:
			_since_lit[index] = 0.0
		var inside: float = gap * in_gap(to_local(place), gap_centre, gap_heading,
				gap_length, gap_width)
		# Caught as it arrives: the wake rocks it once.
		if inside > 0.5 and _dark[index] <= 0.5:
			_since_rocked[index] = 0.0
		elif _since_rocked[index] >= 0.0:
			_since_rocked[index] += delta
			if _since_rocked[index] > rock_seconds:
				_since_rocked[index] = -1.0
		_dark[index] = inside
	_apply()


## Whether the light has reached lantern [param index].
func is_lit(index: int) -> bool:
	return _since_lit[index] >= 0.0


## How brightly lantern [param index] glows right now: its glint, then its
## fading glow, and nothing while it's in the gap.
func glow_of(index: int) -> float:
	if _since_lit[index] < 0.0:
		return 0.0
	var lasting: float = keeper_seconds if _lanterns[index] == keeper else glow_seconds
	return glow_after(_since_lit[index], lasting) * (1.0 - _dark[index])


## How deep in the gap lantern [param index] is right now, 0 to 1.
func darkness_of(index: int) -> float:
	return _dark[index]


## How far lantern [param index] is tipped by the wake right now, in radians.
func tilt_of(index: int) -> float:
	if _since_rocked[index] < 0.0:
		return 0.0
	return rock_after(_since_rocked[index], rock_seconds) * rock_angle


## How bright the lightning is now: 0 dark, 1 the brightest moment.
func set_lightning(brightness: float) -> void:
	_flash = clampf(brightness, 0.0, 1.0)
	_apply()


## How brightly a lantern glows [param seconds] after the light reached it,
## if its glow takes [param lasting] seconds to fade: a bright glint that's
## over in a moment, then a faint glow dying away.
static func glow_after(seconds: float, lasting: float) -> float:
	if seconds < 0.0:
		return 0.0
	var glint: float = GLINT_BRIGHTNESS * maxf(1.0 - seconds / GLINT_SECONDS, 0.0)
	var left: float = clampf(1.0 - seconds / maxf(lasting, 0.001), 0.0, 1.0)
	return glint + AFTERGLOW * left * left


## How far a lantern is tipped [param seconds] after the wake caught it, as
## a share of the furthest it tips: it swings one way, back past upright,
## and settles within [param lasting] seconds.
static func rock_after(seconds: float, lasting: float) -> float:
	if seconds < 0.0 or seconds >= lasting or lasting <= 0.0:
		return 0.0
	var t: float = seconds / lasting
	return sin(t * TAU * 2.0) * (1.0 - t) * (1.0 - t)


## How deep [param point] is inside a long shape lying flat: 1 well inside,
## 0 outside, in between at its soft edge. The shape is [param length] long
## and [param width] wide, centred on [param centre] and turned
## [param heading] radians about the upright. Height is ignored.
static func in_gap(point: Vector3, centre: Vector3, heading: float, length: float,
		width: float) -> float:
	var along: Vector2 = Vector2(cos(heading), sin(heading))
	var offset: Vector2 = Vector2(point.x - centre.x, point.z - centre.z)
	var reach: float = maxf(length * 0.5 - width * 0.5, 0.0)
	var nearest: Vector2 = along * clampf(offset.dot(along), -reach, reach)
	var away: float = offset.distance_to(nearest)
	return 1.0 - smoothstep(width * 0.35, width * 0.5, away)


## How high the seabed's dunes stand at ([param x], [param z]), in metres
## above its level. The seabed's shader raises its surface by the same sum,
## so a lantern set down at this height sits on the sand.
static func dune_height(x: float, z: float) -> float:
	return 0.35 * sin(x * 0.31 + 1.3) * cos(z * 0.27) + 0.15 * sin(x * 0.9 + z * 0.7)


## The two ends of the gap's middle line, in the world, as (x, z).
func gap_ends() -> Array[Vector2]:
	var along: Vector3 = Vector3(cos(gap_heading), 0.0, sin(gap_heading))
	var reach: float = maxf(gap_length * 0.5 - gap_width * 0.5, 0.0)
	var from: Vector3 = to_global(gap_centre - along * reach)
	var to: Vector3 = to_global(gap_centre + along * reach)
	return [Vector2(from.x, from.z), Vector2(to.x, to.z)]


func _apply() -> void:
	for index: int in _lanterns.size():
		var lantern: Node3D = _lanterns[index]
		var glass: GeometryInstance3D = lantern.get_node("Glass") as GeometryInstance3D
		if glass != null:
			glass.set_instance_shader_parameter(&"glow", glow_of(index))
			glass.set_instance_shader_parameter(&"cold", _flash * (1.0 - _dark[index]))
		lantern.transform = _rest[index] * Transform3D(
				Basis(Vector3.RIGHT, tilt_of(index)), Vector3.ZERO)
	if not is_instance_valid(floor_mesh) or not is_inside_tree():
		return
	var sand: ShaderMaterial = floor_mesh.material_override as ShaderMaterial
	if sand == null:
		return
	var ends: Array[Vector2] = gap_ends()
	sand.set_shader_parameter("gap_from", ends[0])
	sand.set_shader_parameter("gap_to", ends[1])
	sand.set_shader_parameter("gap_width", gap_width)
	sand.set_shader_parameter("gap", gap)
	sand.set_shader_parameter("flash", _flash)
