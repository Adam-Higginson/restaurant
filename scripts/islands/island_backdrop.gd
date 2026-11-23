@tool
class_name IslandBackdrop
extends MeshInstance3D
## The far-off land behind an island: ridges of hills standing one behind
## another, each taller and paler than the one in front, so the island seems
## to go on rising into the distance. You can't walk there; it's scenery,
## like a painted backcloth with depth.
##
## Each ridge is a long sloping strip with a wandering skyline, made here in
## code, and shaders/far_hills.gdshader paints it: the further a ridge is
## from the camera, the nearer the colour of the sky.
##
## The ridges are then covered in treetops: thousands of lumpy crowns drawn
## as one [MultiMesh] (shaders/far_canopy.gdshader), thickest along each
## skyline, so a hill's edge against the sky is trees and not a smooth line.

## Metres between the points along a skyline.
const STEP: float = 12.0
## How far forward of its skyline a ridge's foot is, as a part of its height.
const RUN: float = 1.1
## How far below the ground a ridge's foot is, so it's never seen.
const FOOT_DEPTH: float = 4.0

## How many ridges stand behind one another.
@export var ridges: int = 3:
	set(value):
		ridges = value
		_refresh()
## How far inland (towards -Z) the nearest ridge's skyline is, in metres.
@export var first_distance: float = 85.0:
	set(value):
		first_distance = value
		_refresh()
## How much further back each ridge is than the one in front.
@export var ridge_spacing: float = 75.0:
	set(value):
		ridge_spacing = value
		_refresh()
## How tall the nearest ridge is, in metres.
@export var first_height: float = 30.0:
	set(value):
		first_height = value
		_refresh()
## How much taller each ridge is than the one in front.
@export var height_step: float = 34.0:
	set(value):
		height_step = value
		_refresh()
## How far the ridges reach to either side, in metres.
@export var half_width: float = 420.0:
	set(value):
		half_width = value
		_refresh()
## Which skylines (and which treetops) you get.
@export var backdrop_seed: int = 5:
	set(value):
		backdrop_seed = value
		_refresh()

@export_group("Treetops")
## How many crowns cover each ridge. None leaves the hills bare.
@export var crowns_per_ridge: int = 5000:
	set(value):
		crowns_per_ridge = value
		_refresh()
## How wide a crown is on the nearest ridge, in metres: from so wide to so
## wide. Crowns on further ridges are bigger, to cover them with as few.
@export var crown_size: Vector2 = Vector2(5.0, 10.0):
	set(value):
		crown_size = value
		_refresh()
## What the crowns are painted with (shaders/far_canopy.gdshader).
@export var crown_material: ShaderMaterial:
	set(value):
		crown_material = value
		_refresh()
## The sun the crowns are lit by.
@export var sun: DirectionalLight3D:
	set(value):
		sun = value
		_refresh()

var _crowns: MultiMeshInstance3D = null
# The noise each skyline is cut from, by seed and ridge, made once.
var _noises: Dictionary[int, FastNoiseLite] = {}


func _ready() -> void:
	build()


## How high ridge number [param ridge] (0 is the nearest) stands at
## [param x]: its skyline.
func skyline(ridge: int, x: float) -> float:
	var noise: FastNoiseLite = _noise(ridge)
	var tall: float = first_height + height_step * ridge
	# Rolling hills, with a broad swell so each ridge has a high end.
	var roll: float = noise.get_noise_1d(x) * 0.5 + 0.5
	var swell: float = noise.get_noise_1d(x * 0.3 + 500.0) * 0.5 + 0.5
	return tall * (0.45 + 0.35 * roll + 0.2 * swell)


## The spot on ridge number [param ridge]'s slope at [param x], [param up]
## of the way from its foot (0) to its skyline (1).
func on_slope(ridge: int, x: float, up: float) -> Vector3:
	var top: float = skyline(ridge, x)
	var crest_z: float = -(first_distance + ridge_spacing * ridge)
	var crest: Vector3 = Vector3(x, top, crest_z)
	var foot: Vector3 = Vector3(x, -FOOT_DEPTH, crest_z + top * RUN)
	return foot.lerp(crest, up)


## Where the treetops stand: each crown's place, with its size in the
## fourth number. Worked out from the ridges and the seed alone.
func crowns() -> Array[Vector4]:
	var found: Array[Vector4] = []
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = backdrop_seed + 300
	for ridge: int in ridges:
		# Further ridges get bigger crowns: they're as big on screen.
		var bigger: float = 1.0 + 0.55 * ridge
		for crown: int in crowns_per_ridge:
			var x: float = random.randf_range(-half_width, half_width)
			# More of them towards the skyline, where they show against the sky.
			var up: float = 1.0 - random.randf() * random.randf()
			var size: float = random.randf_range(crown_size.x, crown_size.y) * bigger
			var spot: Vector3 = on_slope(ridge, x, up)
			found.append(Vector4(spot.x, spot.y + size * 0.15, spot.z, size))
	return found


## Builds the ridges and their treetops afresh.
func build() -> void:
	var points: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var columns: int = int(half_width * 2.0 / STEP)
	for ridge: int in ridges:
		for column: int in columns:
			var x_a: float = -half_width + column * STEP
			var x_b: float = x_a + STEP
			var crest_a: Vector3 = on_slope(ridge, x_a, 1.0)
			var crest_b: Vector3 = on_slope(ridge, x_b, 1.0)
			var foot_a: Vector3 = on_slope(ridge, x_a, 0.0)
			var foot_b: Vector3 = on_slope(ridge, x_b, 0.0)
			var corners: Array[Vector3] = [crest_a, crest_b, foot_a, crest_b, foot_b, foot_a]
			var heights: Array[float] = [1.0, 1.0, 0.0, 1.0, 0.0, 0.0]
			for corner: int in corners.size():
				points.append(corners[corner])
				uvs.append(Vector2(corners[corner].x / 40.0, heights[corner]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var hills: ArrayMesh = ArrayMesh.new()
	if not points.is_empty():
		hills.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = hills
	_build_crowns()


func _build_crowns() -> void:
	if _crowns != null:
		remove_child(_crowns)
		_crowns.queue_free()
		_crowns = null
	var places: Array[Vector4] = crowns()
	if places.is_empty():
		return
	# One crown: a squat ball of few faces. The shader makes each lumpy.
	var ball: SphereMesh = SphereMesh.new()
	ball.radius = 0.5
	ball.height = 0.8
	ball.radial_segments = 7
	ball.rings = 4
	var many: MultiMesh = MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.use_colors = true
	many.mesh = ball
	many.instance_count = places.size()
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = backdrop_seed + 600
	var per_ridge: int = maxi(crowns_per_ridge, 1)
	for index: int in places.size():
		var place: Vector4 = places[index]
		var turned: Basis = Basis(Vector3.UP, random.randf_range(0.0, TAU))
		turned = turned.scaled(Vector3(place.w, place.w * random.randf_range(0.8, 1.25), place.w))
		many.set_instance_transform(index, Transform3D(turned, Vector3(place.x, place.y, place.z)))
		# Red: extra mist for a crown low on its hill. Green: a number of
		# its own, for the shader to vary it by.
		@warning_ignore("integer_division")
		var ridge: int = index / per_ridge
		var low: float = clampf(1.0 - place.y / (first_height + height_step * ridge), 0.0, 1.0)
		many.set_instance_color(index, Color(low * 0.12, random.randf(), 0.0))
	_crowns = MultiMeshInstance3D.new()
	_crowns.name = "Treetops"
	_crowns.multimesh = many
	_crowns.material_override = crown_material
	_crowns.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if crown_material != null and sun != null:
		# A light shines along its own -Z, so the sun is back along its +Z.
		var to_sun: Vector3 = sun.global_basis.z if sun.is_inside_tree() else sun.basis.z
		crown_material.set_shader_parameter(&"to_sun", to_sun.normalized())
	add_child(_crowns)


func _noise(ridge: int) -> FastNoiseLite:
	var key: int = backdrop_seed * 1000 + ridge
	var noise: FastNoiseLite = _noises.get(key, null)
	if noise == null:
		noise = FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.seed = backdrop_seed + ridge * 17
		noise.frequency = 1.0 / 160.0
		_noises[key] = noise
	return noise


func _refresh() -> void:
	if is_inside_tree():
		build()
