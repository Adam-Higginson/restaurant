class_name Waves
extends RefCounted
## The sea's wave maths, the same as the water shader's, so scripts can ask
## how high the sea is anywhere (under the ship, for instance).
##
## Each [WaveLayer] moves every point of the flat sea in a circle: up and down
## by its amplitude, and sideways along its direction. Because points move
## sideways, the point that ends up above a spot started somewhere else, so
## [method height_at] searches back for it.

## How many search steps [method height_at] takes. Three or four is plenty for
## gentle seas.
const HEIGHT_STEPS: int = 4


## Where the still-water point [param still] (x and z) is moved to at
## [param time] seconds, as an offset: x and z sideways, y up.
static func offset(settings: WaveSettings, still: Vector2, time: float) -> Vector3:
	var moved: Vector3 = Vector3.ZERO
	var t: float = time * settings.time_scale
	for layer: WaveLayer in settings.used_layers():
		var dir: Vector2 = layer.direction()
		var k: float = layer.wave_number()
		var phase: float = k * (dir.dot(still) - layer.speed() * t)
		var side: float = layer.sideways() * layer.amplitude * cos(phase)
		moved += Vector3(dir.x * side, layer.amplitude * sin(phase), dir.y * side)
	return moved


## How high the sea's surface is above the still-water level at the world
## spot [param spot] (x and z), at [param time] seconds.
static func height_at(settings: WaveSettings, spot: Vector2, time: float) -> float:
	# Find the still point that the waves carry to this spot.
	var still: Vector2 = spot
	for i: int in HEIGHT_STEPS:
		var moved: Vector3 = offset(settings, still, time)
		still = spot - Vector2(moved.x, moved.z)
	return offset(settings, still, time).y
