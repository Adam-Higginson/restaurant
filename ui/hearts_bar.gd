class_name HeartsBar
extends Control
## The player's hearts, in the HUD's top-left corner: a row of little pixel
## hearts, each full, half or empty. It only shows the [Duellist]'s
## [Hearts]; the rules live there. When a blow costs a heart some of itself,
## that heart shakes with a crack across it for a moment.

## How far apart hearts are drawn, in pixels.
const SPACING: int = 9
## One heart as rows of pixels: "#" is drawn, "." is not.
const SHAPE: PackedStringArray = [
	".##.##.",
	"#######",
	"#######",
	".#####.",
	"..###..",
	"...#...",
]
## The crack drawn across a heart that has just lost some of itself: the
## pixels, by column and row, in a jagged line down the middle.
const CRACK: Array[Vector2i] = [Vector2i(3, 0), Vector2i(3, 1), Vector2i(4, 2), Vector2i(3, 3),
		Vector2i(3, 4)]
const FULL: Color = Color(0.86, 0.2, 0.22)
const EMPTY: Color = Color(0.16, 0.13, 0.15, 0.8)
const CRACK_COLOUR: Color = Color(1.0, 0.95, 0.9)
## How long a heart shows its crack, in seconds.
const CRACK_SECONDS: float = 0.6

## How many half-hearts are drawn filled.
var shown_halves: int:
	get:
		return _hearts.halves if _hearts != null else 0

## Which heart (0 is the first) is showing its crack, or -1 for none.
var cracked_heart: int:
	get:
		return _cracked if _crack_left > 0.0 else -1

var _hearts: Hearts = null
## The half-hearts shown before the last change.
var _was: int = 0
var _cracked: int = -1
var _crack_left: float = 0.0
var _time: float = 0.0


## Shows [param player]'s hearts, or hides if they have none to show.
func setup(player: Player3D) -> void:
	var duellist: Duellist = player.get_node_or_null("Duellist") as Duellist
	if duellist == null or duellist.hearts == null:
		hide()
		return
	_hearts = duellist.hearts
	_was = _hearts.halves
	_hearts.changed.connect(_on_hearts_changed)
	queue_redraw()


func _process(delta: float) -> void:
	if _crack_left <= 0.0:
		return
	_time += delta
	_crack_left = maxf(_crack_left - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	if _hearts == null:
		return
	@warning_ignore("integer_division")
	var count: int = _hearts.max_halves / Hearts.HALVES_PER_HEART
	for heart: int in count:
		# How much of this heart is left: 0, 1 (half) or 2 (full) halves.
		var left: int = clampi(_hearts.halves - heart * Hearts.HALVES_PER_HEART, 0,
				Hearts.HALVES_PER_HEART)
		var at: Vector2 = Vector2(heart * SPACING, 0)
		var cracking: bool = heart == cracked_heart
		if cracking:
			# A shiver, a pixel either way.
			at.x += 1.0 if int(_time * 30.0) % 2 == 0 else -1.0
		_draw_heart(at, left)
		if cracking:
			for pixel: Vector2i in CRACK:
				draw_rect(Rect2(at + Vector2(pixel), Vector2.ONE), CRACK_COLOUR)


func _draw_heart(at: Vector2, halves_left: int) -> void:
	for row: int in SHAPE.size():
		var line: String = SHAPE[row]
		for column: int in line.length():
			if line[column] != "#":
				continue
			# A half heart fills its left side: the first four columns.
			var filled: bool = halves_left == 2 or (halves_left == 1 and column < 4)
			draw_rect(Rect2(at + Vector2(column, row), Vector2.ONE), FULL if filled else EMPTY)


## The heart (0 is the first) that a drop from [param was] to [param now]
## half-hearts took something from: the one holding the last half lost.
static func heart_hit(was: int, now: int) -> int:
	if now >= was:
		return -1
	@warning_ignore("integer_division")
	return now / Hearts.HALVES_PER_HEART


func _on_hearts_changed(halves: int) -> void:
	var hit: int = heart_hit(_was, halves)
	_was = halves
	if hit >= 0:
		_cracked = hit
		_crack_left = CRACK_SECONDS
		_time = 0.0
	else:
		# Refilled: no crack to show.
		_crack_left = 0.0
	queue_redraw()
