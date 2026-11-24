class_name FlyingFish
extends Node3D
## Flying fish leaping alongside the ship (#197): a few at a time burst out
## of the water beside her, glide forward in a long low arc with their wing
## fins spread, and drop back in, with a burst of spray each way. Put it on
## the ship, so they keep pace with her; its space is hers.
##
## Each fish is the herring ([member fish], its ingredient's model, a greybox
## block when the art isn't there), with two see-through wing fins made here.
## They only leap while [member leaping] is on ([code]@flying_fish on[/code]);
## turned off, the ones in the air finish their leap and no more start.

## The group flying fish are in, for the cue.
const GROUP: StringName = &"flying_fish"

## The fish they're made from: its model and its size.
@export var fish: Item = preload("res://data/items/herring.tres")
## How long each fish is, in metres.
@export var fish_size: float = 0.5
## How many fish there are, each leaping again after a rest.
@export_range(1, 32) var count: int = 12
## Whether they're leaping.
@export var leaping: bool = false:
	set(value):
		leaping = value
		if value:
			for leap: Leap in _leaps:
				if not leap.flying:
					leap.rest = randf_range(0.0, 1.2)
## How far out from her side they leap, in metres: nearest and furthest.
@export var out_from: Vector2 = Vector2(8.0, 18.0)
## Along her length, from stern to bow (her -Z is forward), where they rise.
@export var along: Vector2 = Vector2(-14.0, 18.0)
## How far each glides, in metres, and how high its arc, shortest to longest.
@export var glide: Vector2 = Vector2(9.0, 18.0)
@export var height: Vector2 = Vector2(0.6, 1.6)
## How fast they glide, in metres a second, past her.
@export var speed: float = 9.0
## Where the sea is, in her space: they rise from and fall back to it.
@export var sea_level: float = 0.0
## The rest between one fish's leaps, in seconds, shortest to longest.
@export var rests: Vector2 = Vector2(0.6, 3.0)

var _leaps: Array[Leap] = []
var _fin_material: StandardMaterial3D = null


## One fish and its leap.
class Leap:
	var body: Node3D
	var fins: Array[Node3D] = []
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
	_fin_material = StandardMaterial3D.new()
	_fin_material.albedo_color = Color(0.9, 0.95, 1.0, 0.82)
	_fin_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fin_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_fin_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
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
	for side: float in [-1.0, 1.0]:
		var hinge: Node3D = Node3D.new()
		hinge.position = Vector3(side * fish_size * 0.12, fish_size * 0.25, -fish_size * 0.05)
		leap.body.add_child(hinge)
		var fin: MeshInstance3D = MeshInstance3D.new()
		fin.mesh = _fin_mesh(side)
		fin.material_override = _fin_material
		fin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hinge.add_child(fin)
		leap.fins.append(hinge)
	leap.spray = _make_spray()
	add_child(leap.spray)
	leap.rest = randf_range(rests.x, rests.y)
	return leap


# A wing fin lying flat, reaching out to [param side] (-1 left, 1 right):
# broad where it meets the body, swept back to a narrow tip. Her -Z is
# forward.
func _fin_mesh(side: float) -> ArrayMesh:
	var span: float = fish_size * 0.95
	var root: float = fish_size * 0.28
	var sweep: float = fish_size * 0.3
	var tip: float = fish_size * 0.1
	var corners: PackedVector3Array = PackedVector3Array([
		Vector3(0.0, 0.0, -root * 0.5),
		Vector3(0.0, 0.0, root * 0.5),
		Vector3(side * span, 0.0, sweep + tip * 0.5),
		Vector3(side * span, 0.0, sweep - tip * 0.5),
	])
	var normals: PackedVector3Array = PackedVector3Array([
		Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = corners
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


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
	var length: float = randf_range(glide.x, glide.y)
	leap.from = Vector3(out, sea_level, start)
	# Forward (her -Z), drifting a little in or out.
	leap.to = Vector3(out + randf_range(-1.5, 1.5), sea_level, start - length)
	leap.peak = randf_range(height.x, height.y)
	leap.seconds = length / speed
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
	# Nose along the arc: up as it rises, down as it falls.
	var ahead: Vector3 = _arc(leap, minf(leap.t + 0.02, 1.0)) - leap.body.position
	if ahead.length() > 0.0001:
		leap.body.basis = Basis.looking_at(ahead.normalized(), Vector3.UP)
	# Fins spread wide once clear of the water, folded as it leaves and enters.
	var spread: float = sin(leap.t * PI)
	for i: int in leap.fins.size():
		var side: float = -1.0 if i == 0 else 1.0
		leap.fins[i].rotation_degrees.z = side * lerpf(70.0, 0.0, spread)
		leap.fins[i].scale = Vector3.ONE * lerpf(0.3, 1.0, spread)


# A long, low arc: out of the sea at [member Leap.from], highest halfway,
# back in at [member Leap.to].
func _arc(leap: Leap, t: float) -> Vector3:
	var flat: Vector3 = leap.from.lerp(leap.to, t)
	flat.y = sea_level + leap.peak * 4.0 * t * (1.0 - t)
	return flat


func _splash(leap: Leap, where: Vector3) -> void:
	leap.spray.position = where
	leap.spray.restart()
