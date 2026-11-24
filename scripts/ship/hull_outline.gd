@tool
class_name HullOutline
extends Resource
## The shape of the ship's hull, in ship space (#196): at even steps from bow
## to stern, how high its top edge is and how far its outside stands out from
## the centreline at a range of heights. The deck's edge, the rails and their
## collision are built from it.
##
## It's measured from the Meshy hull once and saved (tools/ship/measure_hull.gd),
## so the deck and rails are the same whether or not the art is on this
## computer: walking and collision never depend on a third-party file.

## Where the first sample is, along the ship (ship z, metres; the bow is -z).
@export var start_z: float = -21.5
## Metres between samples along the ship.
@export var step: float = 0.5
## Height of the hull's top edge, per sample (ship y, metres).
@export var rims: PackedFloat32Array = PackedFloat32Array()
## The lowest height measured across (ship y, metres).
@export var low_y: float = 3.0
## Metres between measured heights.
@export var height_step: float = 0.25
## How many heights are measured at each sample.
@export var heights: int = 0
## Half the hull's width (metres from the centreline to its outside), per
## sample and height: sample [code]s[/code], height [code]h[/code] is at
## [code]s * heights + h[/code]. Zero where the hull doesn't reach.
@export var widths: PackedFloat32Array = PackedFloat32Array()


## How many samples there are along the ship.
func samples() -> int:
	return rims.size()


## Where the last sample is, along the ship.
func end_z() -> float:
	return start_z + step * maxf(samples() - 1, 0)


## True if [param z] is between the bow and the stern.
func covers(z: float) -> bool:
	return samples() > 0 and z >= start_z and z <= end_z()


## The height of the hull's top edge at [param z]. Past the ends, the nearest
## end's.
func rim_at(z: float) -> float:
	if rims.is_empty():
		return 0.0
	var at: float = (clampf(z, start_z, end_z()) - start_z) / step
	var below: int = mini(floori(at), samples() - 1)
	var above: int = mini(below + 1, samples() - 1)
	return lerpf(rims[below], rims[above], at - below)


## How far the outside of the hull stands from the centreline at [param z],
## [param y] high, read between samples. Zero past the ends, above the top
## edge or below the heights measured.
func half_width_at(z: float, y: float) -> float:
	if not covers(z) or heights == 0 or y > rim_at(z):
		return 0.0
	var along: float = (z - start_z) / step
	var up: float = (y - low_y) / height_step
	if up < 0.0:
		return 0.0
	var s0: int = mini(floori(along), samples() - 1)
	var s1: int = mini(s0 + 1, samples() - 1)
	var h0: int = mini(floori(up), heights - 1)
	var h1: int = mini(h0 + 1, heights - 1)
	var near: float = _blend(_width(s0, h0), _width(s0, h1), clampf(up - h0, 0.0, 1.0))
	var far: float = _blend(_width(s1, h0), _width(s1, h1), clampf(up - h0, 0.0, 1.0))
	return _blend(near, far, along - s0)


## Reads between two measurements; where one found no hull (zero), the other.
static func _blend(a: float, b: float, weight: float) -> float:
	if a <= 0.0:
		return b
	if b <= 0.0:
		return a
	return lerpf(a, b, weight)


func _width(sample: int, height: int) -> float:
	return widths[sample * heights + height]
