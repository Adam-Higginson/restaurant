@tool
class_name KilnPalette
extends Resource
## A shared paintbox: the colours every fired texture is snapped to, so models
## from every pack share one set of colours, like the N64's small indexed
## textures.
##
## The Salt and Ember palette (data/art/palettes/salt_and_ember.tres) is made
## by tools/kiln/make_palette.sh from the game's own textures and the fired
## ones. Colours are compared in OKLab, a colour space where equal distances
## look equally different to the eye.

## The colours, opaque.
@export var colours: PackedColorArray = []


## The palette's colour nearest to [param colour], as the eye sees it, or
## [param colour] itself if the palette is empty.
func nearest(colour: Color) -> Color:
	var best: Color = colour
	var best_distance: float = INF
	var target: Vector3 = oklab(colour)
	for candidate: Color in colours:
		var distance: float = target.distance_squared_to(oklab(candidate))
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


## The colours as [r, g, b] lists, sRGB 0-1, for the Kiln's job file.
func to_list() -> Array[Array]:
	var list: Array[Array] = []
	for colour: Color in colours:
		list.append([snappedf(colour.r, 0.0001), snappedf(colour.g, 0.0001),
				snappedf(colour.b, 0.0001)])
	return list


## [param colour] (sRGB) in OKLab: lightness and two colour axes.
static func oklab(colour: Color) -> Vector3:
	var linear: Color = colour.srgb_to_linear()
	var l: float = 0.4122214708 * linear.r + 0.5363325363 * linear.g + 0.0514459929 * linear.b
	var m: float = 0.2119034982 * linear.r + 0.6806995451 * linear.g + 0.1073969566 * linear.b
	var s: float = 0.0883024619 * linear.r + 0.2817188376 * linear.g + 0.6299787005 * linear.b
	l = pow(l, 1.0 / 3.0)
	m = pow(m, 1.0 / 3.0)
	s = pow(s, 1.0 / 3.0)
	return Vector3(
			0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
			1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
			0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)
