class_name WaveSettings
extends Resource
## The sea's waves: up to [constant MAX_LAYERS] [WaveLayer]s added together.
## The water shader draws them and [Waves] works out heights from the same
## numbers, so what the game asks about is what you see.
##
## One file per sea state under res://data/sea/ (a calm night, a heavy swell).

## The water shader has room for this many layers.
const MAX_LAYERS: int = 4

## The wave layers, longest swell first.
@export var layers: Array[WaveLayer] = []
## Plays the waves slower (below 1) or faster than real deep-water waves, for
## mood: a heavy swell reads better a little slow.
@export_range(0.0, 2.0) var time_scale: float = 1.0


## The layers the shader can draw: the first [constant MAX_LAYERS].
func used_layers() -> Array[WaveLayer]:
	return layers.slice(0, MAX_LAYERS)
