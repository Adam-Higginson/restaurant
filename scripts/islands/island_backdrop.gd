@tool
class_name IslandBackdrop
extends MeshInstance3D
## The far-off land behind an island: ridges of hills standing one behind
## another, each taller and paler than the one in front, so the island seems
## to go on rising into the distance. You can't walk there; it's scenery,
## like a painted backcloth with depth.
##
## Each ridge is a long sloping strip with a wandering skyline, made here in
## code. How hazy each is rides along in its vertex colour, and
## shaders/far_hills.gdshader paints it: the further the ridge, the nearer
## the colour of the sky.

## Metres between the points along a skyline.
const STEP: float = 12.0

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
## Which skylines you get.
@export var backdrop_seed: int = 5:
	set(value):
		backdrop_seed = value
		_refresh()


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


## How hazy ridge number [param ridge] is, from 0 (clear) to 1 (lost in the
## sky).
func haze(ridge: int) -> float:
	return clampf(0.18 + 0.27 * ridge, 0.0, 0.92)


## Builds the ridges afresh.
func build() -> void:
	var points: PackedVector3Array = PackedVector3Array()
	var colours: PackedColorArray = PackedColorArray()
	var uvs: PackedVector2Array = PackedVector2Array()
	var columns: int = int(half_width * 2.0 / STEP)
	for ridge: int in ridges:
		var crest_z: float = -(first_distance + ridge_spacing * ridge)
		var hazy: Color = Color(haze(ridge), 0.0, 0.0)
		for column: int in columns:
			var x_a: float = -half_width + column * STEP
			var x_b: float = x_a + STEP
			var top_a: float = skyline(ridge, x_a)
			var top_b: float = skyline(ridge, x_b)
			# The slope comes forward about as far as it's tall, down to
			# below the ground so its foot is never seen.
			var crest_a: Vector3 = Vector3(x_a, top_a, crest_z)
			var crest_b: Vector3 = Vector3(x_b, top_b, crest_z)
			var foot_a: Vector3 = Vector3(x_a, -4.0, crest_z + top_a * 1.1)
			var foot_b: Vector3 = Vector3(x_b, -4.0, crest_z + top_b * 1.1)
			var corners: Array[Vector3] = [crest_a, crest_b, foot_a, crest_b, foot_b, foot_a]
			var heights: Array[float] = [1.0, 1.0, 0.0, 1.0, 0.0, 0.0]
			for corner: int in corners.size():
				points.append(corners[corner])
				colours.append(hazy)
				uvs.append(Vector2(corners[corner].x / 40.0, heights[corner]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var hills: ArrayMesh = ArrayMesh.new()
	if not points.is_empty():
		hills.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = hills


func _noise(ridge: int) -> FastNoiseLite:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = backdrop_seed + ridge * 17
	noise.frequency = 1.0 / 160.0
	return noise


func _refresh() -> void:
	if is_inside_tree():
		build()
