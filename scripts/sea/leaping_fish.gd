class_name LeapingFish
extends Node3D
## Fish leaping alongside the ship (#197): a few at a time jump out of the
## water beside her, arc forward and drop back in, with a burst of spray
## each way. Put it on the ship, so they keep pace with her; its space is
## hers.
##
## Each fish is the herring ([member fish], its ingredient's model, a greybox
## block when the art isn't there). They only leap while [member leaping] is
## on ([code]@leaping_fish on[/code]); turned off, the ones in the air land
## and no more jump.

## The group leaping fish are in, for the cue.
const GROUP: StringName = &"leaping_fish"

## The fish they're made from: its model and its colour.
@export var fish: Item = preload("res://data/items/herring.tres")
## How long each fish is, in metres.
@export var fish_size: float = 0.6
## How many fish there are, each jumping again after a rest.
@export_range(1, 32) var count: int = 12
## Whether they're leaping.
@export var leaping: bool = false:
	set(value):
		leaping = value
		if value:
			for leap: Leap in _leaps:
				if not leap.flying:
					leap.rest = randf_range(0.0, 1.2)
## How far out from her side they jump, in metres: nearest and furthest.
@export var out_from: Vector2 = Vector2(6.0, 14.0)
## Along her length, from bow to stern (her -Z is forward), where they rise.
@export var along: Vector2 = Vector2(-14.0, 18.0)
## How far each jump carries, in metres, and how high, shortest to longest.
@export var reach: Vector2 = Vector2(2.5, 5.0)
@export var height: Vector2 = Vector2(0.8, 1.8)
## How long each jump lasts, in seconds, shortest to longest.
@export var airtime: Vector2 = Vector2(0.7, 1.1)
## Where the sea is, in her space: they jump from and fall back to it.
@export var sea_level: float = 0.0
## The rest between one fish's jumps, in seconds, shortest to longest.
@export var rests: Vector2 = Vector2(0.6, 3.0)

var _leaps: Array[Leap] = []


## One fish and its jump.
class Leap:
	var body: Node3D
	var spray: CPUParticles3D
	var flying: bool = false
	var rest: float = 0.0
	var from: Vector3
	var to: Vector3
	var peak: float = 1.0
	var t: float = 0.0
	var seconds: float = 1.0


func _ready() -> void:
	add_to_group(GROUP)
	for i: int in count:
		_leaps.append(_make_leap(i))


func _process(delta: float) -> void:
	for leap: Leap in _leaps:
		if leap.flying:
			_fly(leap, delta)
		elif leaping:
			leap.rest -= delta
			if leap.rest <= 0.0:
				_launch(leap)


## Turns the leaping on or off. Called by the cue on the group.
func set_leaping(on: bool) -> void:
	leaping = on


## How many fish are in the air now.
func in_the_air() -> int:
	var flying: int = 0
	for leap: Leap in _leaps:
		if leap.flying:
			flying += 1
	return flying


## Where each fish in the air is, in her space.
func fish_positions() -> Array[Vector3]:
	var at: Array[Vector3] = []
	for leap: Leap in _leaps:
		if leap.flying:
			at.append(leap.body.position)
	return at


func _make_leap(index: int) -> Leap:
	var leap: Leap = Leap.new()
	leap.body = Node3D.new()
	leap.body.name = "Fish%d" % index
	leap.body.visible = false
	add_child(leap.body)
	var model: Node3D = ItemModel.food(fish, fish_size)
	# The Meshy model faces +Z; turned round, its nose leads.
	model.rotation_degrees.y = 180.0
	leap.body.add_child(model)
	leap.spray = _make_spray()
	add_child(leap.spray)
	leap.rest = randf_range(rests.x, rests.y)
	return leap


func _make_spray() -> CPUParticles3D:
	var spray: CPUParticles3D = CPUParticles3D.new()
	spray.emitting = false
	spray.one_shot = true
	spray.amount = 14
	spray.lifetime = 0.7
	spray.explosiveness = 0.9
	spray.direction = Vector3.UP
	spray.spread = 35.0
	spray.initial_velocity_min = 1.5
	spray.initial_velocity_max = 3.0
	spray.gravity = Vector3(0, -9.0, 0)
	spray.scale_amount_min = 0.05
	spray.scale_amount_max = 0.1
	var drop: SphereMesh = SphereMesh.new()
	drop.radius = 0.5
	drop.height = 1.0
	drop.radial_segments = 6
	drop.rings = 3
	var white: StandardMaterial3D = StandardMaterial3D.new()
	white.albedo_color = Color(0.92, 0.96, 1.0)
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = white
	spray.mesh = drop
	return spray


func _launch(leap: Leap) -> void:
	var side: float = -1.0 if randf() < 0.5 else 1.0
	var out: float = side * randf_range(out_from.x, out_from.y)
	var start: float = randf_range(along.x, along.y)
	var length: float = randf_range(reach.x, reach.y)
	leap.from = Vector3(out, sea_level, start)
	# Forward (her -Z), drifting a little in or out.
	leap.to = Vector3(out + randf_range(-0.5, 0.5), sea_level, start - length)
	leap.peak = randf_range(height.x, height.y)
	leap.seconds = randf_range(airtime.x, airtime.y)
	leap.t = 0.0
	leap.flying = true
	leap.body.visible = true
	_splash(leap, leap.from)
	_fly(leap, 0.0)


func _fly(leap: Leap, delta: float) -> void:
	leap.t += delta / leap.seconds
	if leap.t >= 1.0:
		leap.flying = false
		leap.body.visible = false
		leap.rest = randf_range(rests.x, rests.y)
		_splash(leap, leap.to)
		return
	leap.body.position = _arc(leap, leap.t)
	# Nose along the arc: up as it jumps, down as it falls back in.
	var ahead: Vector3 = _arc(leap, minf(leap.t + 0.02, 1.0)) - leap.body.position
	if ahead.length() > 0.0001:
		leap.body.basis = Basis.looking_at(ahead.normalized(), Vector3.UP)


# An arc: out of the sea at [member Leap.from], highest halfway, back in at
# [member Leap.to].
func _arc(leap: Leap, t: float) -> Vector3:
	var flat: Vector3 = leap.from.lerp(leap.to, t)
	flat.y = sea_level + leap.peak * 4.0 * t * (1.0 - t)
	return flat


func _splash(leap: Leap, where: Vector3) -> void:
	leap.spray.position = where
	leap.spray.restart()
