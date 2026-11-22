class_name HeartsBar
extends Control
## The player's hearts, in the HUD's top-left corner: a row of little pixel
## hearts, each full, half or empty. It only shows the [Duellist]'s
## [Hearts]; the rules live there.

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
const FULL: Color = Color(0.86, 0.2, 0.22)
const EMPTY: Color = Color(0.16, 0.13, 0.15, 0.8)

## How many half-hearts are drawn filled.
var shown_halves: int:
	get:
		return _hearts.halves if _hearts != null else 0

var _hearts: Hearts = null


## Shows [param player]'s hearts, or hides if they have none to show.
func setup(player: Player3D) -> void:
	var duellist: Duellist = player.get_node_or_null("Duellist") as Duellist
	if duellist == null or duellist.hearts == null:
		hide()
		return
	_hearts = duellist.hearts
	_hearts.changed.connect(_on_hearts_changed)
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
		_draw_heart(Vector2(heart * SPACING, 0), left)


func _draw_heart(at: Vector2, halves_left: int) -> void:
	for row: int in SHAPE.size():
		var line: String = SHAPE[row]
		for column: int in line.length():
			if line[column] != "#":
				continue
			# A half heart fills its left side: the first four columns.
			var filled: bool = halves_left == 2 or (halves_left == 1 and column < 4)
			draw_rect(Rect2(at + Vector2(column, row), Vector2.ONE), FULL if filled else EMPTY)


func _on_hearts_changed(_halves: int) -> void:
	queue_redraw()
