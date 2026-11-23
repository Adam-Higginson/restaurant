class_name IslandShape
extends Resource
## The lie of an island's land, as numbers: how high the ground is at any
## spot. Everything that needs the ground asks this: [IslandGround] builds
## the mesh and the collision from it, the scatterers stand plants on it, and
## the shore water reads it to know how deep it is.
##
## The land is a cove. The sea is towards +Z and the land towards -Z; the
## waterline bites inland in the middle and comes out to a headland at each
## end. Going inland from the water: a gently sloping beach, a dune, then
## bumpy higher ground for the palms. Sea level is height 0.

## How far the ground reaches along X and Z, in metres, centred on the origin.
@export var size: Vector2 = Vector2(180.0, 130.0)
## Where the waterline is (its Z) at the middle of the cove.
@export var shore_z: float = 6.0
## How much further out to sea the waterline is at the headlands.
@export var cove_depth: float = 16.0
## How wide the cove is: the distance from its middle to where the headlands
## are halfway out.
@export var cove_width: float = 42.0
## How far the waterline wanders in and out along the beach, in metres.
@export var shore_wander: float = 1.6

@export_group("Beach")
## Rise for each metre inland on the beach (and fall, just into the water).
@export var beach_slope: float = 0.065
## How wide the beach is from the waterline to the foot of the dune.
@export var beach_width: float = 13.0
## How much steeper the seabed gets with each metre out.
@export var seabed_steepening: float = 0.006
## The deepest the seabed goes.
@export var seabed_floor: float = -9.0

@export_group("Inland")
## How high the dune stands above the top of the beach.
@export var dune_height: float = 2.4
## How far the dune takes to rise.
@export var dune_width: float = 11.0
## Rise for each metre further inland behind the dune.
@export var inland_slope: float = 0.03
## How tall the bumps of the inland ground are.
@export var bumps: float = 0.9
## How far apart the bumps are, in metres.
@export var bump_spacing: float = 14.0
## Which bumps you get.
@export var bump_seed: int = 7

var _noise: FastNoiseLite = null


## The Z of the waterline at [param x].
func shore_line(x: float) -> float:
	var out: float = 1.0 - exp(-(x / cove_width) * (x / cove_width))
	var wander: float = sin(x * 0.11) * 0.6 + sin(x * 0.047 + 1.3) * 0.4
	return shore_z + cove_depth * out + shore_wander * wander


## How far inland of the waterline a spot is, in metres (negative out at sea).
func inland(x: float, z: float) -> float:
	return shore_line(x) - z


## The height of the ground at a spot. Sea level is 0.
func height_at(x: float, z: float) -> float:
	var s: float = inland(x, z)
	if s <= 0.0:
		var out: float = -s
		return maxf(seabed_floor, -(beach_slope * out + seabed_steepening * out * out))
	var height: float = beach_slope * minf(s, beach_width)
	var past_beach: float = maxf(0.0, s - beach_width)
	height += dune_height * smoothstep(0.0, dune_width, past_beach)
	height += inland_slope * past_beach
	# The beach is smooth; the bumps grow in over the dune.
	var bumpy: float = smoothstep(beach_width * 0.5, beach_width + dune_width, s)
	height += _bump(x, z) * bumps * bumpy
	return height


## How steep the ground is at a spot: rise over run (0 is flat, 1 is 45°).
func slope_at(x: float, z: float) -> float:
	var dx: float = height_at(x + 0.5, z) - height_at(x - 0.5, z)
	var dz: float = height_at(x, z + 0.5) - height_at(x, z - 0.5)
	return Vector2(dx, dz).length()


## The direction straight up out of the ground at a spot.
func normal_at(x: float, z: float) -> Vector3:
	var dx: float = height_at(x + 0.5, z) - height_at(x - 0.5, z)
	var dz: float = height_at(x, z + 0.5) - height_at(x, z - 0.5)
	return Vector3(-dx, 1.0, -dz).normalized()


## Whether a spot is on this island's patch of ground at all.
func covers(x: float, z: float) -> bool:
	return absf(x) <= size.x / 2.0 and absf(z) <= size.y / 2.0


func _bump(x: float, z: float) -> float:
	if _noise == null:
		_noise = FastNoiseLite.new()
		_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_noise.seed = bump_seed
		_noise.frequency = 1.0 / bump_spacing
	return _noise.get_noise_2d(x, z)
