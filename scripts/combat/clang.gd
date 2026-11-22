class_name Clang
extends AudioStreamPlayer
## The clang of a frying pan turning a blow away. It plays one of a few
## recorded metal knocks, never the same one twice running, at a slightly
## different pitch each time, so parry after parry doesn't sound stamped out.
##
## A child of the [Player3D]; the [Duellist] rings it when a parry lands.
## The recordings are from Kenney's Impact Sounds (CC0), in
## [code]assets/audio/combat/[/code] with their licence beside them.

## The recordings to pick from.
const SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/combat/impactMetal_heavy_000.ogg"),
	preload("res://assets/audio/combat/impactMetal_heavy_001.ogg"),
	preload("res://assets/audio/combat/impactMetal_heavy_002.ogg"),
	preload("res://assets/audio/combat/impactMetal_heavy_003.ogg"),
	preload("res://assets/audio/combat/impactMetal_heavy_004.ogg"),
]

## How far the pitch varies from one clang to the next, as a fraction.
@export_range(0.0, 0.3) var pitch_wander: float = 0.06

## How many times it has rung.
var times_rung: int = 0

## Which of [constant SOUNDS] played last, or -1 before the first.
var _last: int = -1


## Rings the pan: a different recording from last time, from the start.
func ring() -> void:
	times_rung += 1
	_last = next_index(_last, randi_range(0, SOUNDS.size() - 1), SOUNDS.size())
	stream = SOUNDS[_last]
	pitch_scale = randf_range(1.0 - pitch_wander, 1.0 + pitch_wander)
	play()


## Which of [param count] sounds to play, having rolled [param rolled] and
## played [param last] last time: the rolled one, or the one after it if
## that would be the same sound twice running.
static func next_index(last: int, rolled: int, count: int) -> int:
	if rolled == last and count > 1:
		return (rolled + 1) % count
	return rolled
