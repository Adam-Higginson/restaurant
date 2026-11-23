class_name IslandShape
extends Resource
## The lie of an island's land, as numbers: how high the ground is at any
## spot. Everything that needs the ground asks this: [IslandGround] builds
## the mesh and the collision from it, the scatterers stand plants on it, and
## the shore water reads it to know how deep it is.
##
## The land is a cove. The sea is towards +Z and the land towards -Z; the
## waterline bites inland in the middle and comes out to a headland at each
## end. Going inland from the water: a narrow sloping beach, a bank, then
## bumpy higher ground for the jungle. Going out: a shallow shelf, then the
## bottom drops away. Sea level is height 0.

## How far the ground reaches along X and Z, in metres, centred on the origin.
@export var size: Vector2 = Vector2(180.0, 130.0)
## Where the waterline is (its Z) at the middle of the cove.
@export var shore_z: float = 6.0
## How much further out to sea the waterline is at the headlands.
@export var cove_depth: float = 22.0
## How wide the cove is: the distance from its middle to where the headlands
## are halfway out.
@export var cove_width: float = 34.0
## How far the waterline wanders in and out along the beach, in metres.
@export var shore_wander: float = 2.6

@export_group("Beach")
## Rise for each metre inland on the beach (and fall, out over the shelf).
@export var beach_slope: float = 0.07
## How wide the beach is from the waterline to the foot of the bank.
@export var beach_width: float = 10.0
## How tall the beach's own soft humps and hollows are, in metres.
@export var beach_humps: float = 0.09

@export_group("Seabed")
## How far out the shallow shelf reaches before the bottom drops away.
@export var shelf_width: float = 5.0
## Fall for each metre out, past the shelf: the drop-off.
@export var drop_slope: float = 0.42
## The deepest the seabed goes.
@export var seabed_floor: float = -7.5

@export_group("Inland")
## How high the bank stands above the top of the beach.
@export var dune_height: float = 1.5
## How far the bank takes to rise.
@export var dune_width: float = 7.0
## Rise for each metre further inland behind the bank.
@export var inland_slope: float = 0.03
## How far inland the hillside begins: behind this the land climbs away
## towards the far hills.
@export var hill_from: float = 34.0
## Rise for each metre further inland on the hillside.
@export var hill_slope: float = 0.5
## How tall the bumps of the inland ground are.
@export var bumps: float = 1.3
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
		return _seabed(-s)
	var height: float = beach_slope * minf(s, beach_width)
	var past_beach: float = maxf(0.0, s - beach_width)
	height += dune_height * smoothstep(0.0, dune_width, past_beach)
	height += inland_slope * past_beach
	# The hillside: its foot is rounded over a few metres, not a crease.
	var up_hill: float = maxf(0.0, s - hill_from)
	height += hill_slope * (up_hill * up_hill / (up_hill + 6.0))
	# The beach has soft humps (none at the waterline, so the edge stays
	# clean); the big bumps grow in over the bank.
	var humpy: float = smoothstep(0.5, 3.0, s)
	height += _bump(x * 4.0, z * 4.0) * beach_humps * humpy
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


# The seabed's height [param out] metres from the waterline: the beach's
# slope carries on over the shelf, then turns down into the drop-off (the
# turn is rounded over a couple of metres, not a crease).
func _seabed(out: float) -> float:
	var past_shelf: float = out - shelf_width
	var dropped: float = 0.0
	if past_shelf >= 1.0:
		dropped = past_shelf
	elif past_shelf > -1.0:
		dropped = (past_shelf + 1.0) * (past_shelf + 1.0) / 4.0
	return maxf(seabed_floor, -(beach_slope * out + (drop_slope - beach_slope) * dropped))


func _bump(x: float, z: float) -> float:
	if _noise == null:
		_noise = FastNoiseLite.new()
		_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_noise.seed = bump_seed
		_noise.frequency = 1.0 / bump_spacing
	return _noise.get_noise_2d(x, z)
