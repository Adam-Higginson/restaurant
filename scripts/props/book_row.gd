@tool
class_name BookRow
extends Node3D
## A row of books standing on a shelf (#196), every one the same Meshy [ShelfBook]
## in its own colour, height and thickness, spines out (+Z), filling
## [member length] metres along +X from this node. The last one may lean on
## its neighbour. The same [member shuffle] always makes the same row, so a
## shelf looks the same every time; change it for a different row.

## How long the row is, in metres.
@export var length: float = 0.8:
	set(value):
		length = value
		build()
## Which row: each number makes a different one.
@export var shuffle: int = 1:
	set(value):
		shuffle = value
		build()
## The colours the covers are picked from.
@export var palette: PackedColorArray = PackedColorArray([
		Color(0.55, 0.14, 0.12), Color(0.16, 0.22, 0.42), Color(0.22, 0.36, 0.2),
		Color(0.42, 0.26, 0.14), Color(0.62, 0.46, 0.18), Color(0.38, 0.18, 0.32)]):
	set(value):
		palette = value
		build()
## The shortest and tallest books, in metres.
@export var heights: Vector2 = Vector2(0.2, 0.28):
	set(value):
		heights = value
		build()
## Lean the last book over on its neighbour.
@export var lean_last: bool = true:
	set(value):
		lean_last = value
		build()

## The books, from the start of the row.
var books: Array[ShelfBook] = []


func _ready() -> void:
	build()


## Makes the row (again).
func build() -> void:
	if not is_inside_tree():
		return
	for book: ShelfBook in books:
		book.queue_free()
	books.clear()
	var dice: RandomNumberGenerator = RandomNumberGenerator.new()
	dice.seed = shuffle
	var along: float = 0.0
	while true:
		var book: ShelfBook = ShelfBook.new()
		book.height = dice.randf_range(heights.x, heights.y)
		book.thickness = dice.randf_range(0.7, 1.5)
		book.cover = palette[dice.randi_range(0, palette.size() - 1)] if not palette.is_empty() \
				else Color.SADDLE_BROWN
		if along + book.depth() > length:
			book.free()
			break
		book.position = Vector3(along + book.depth() / 2.0, 0.0, 0.0)
		along += book.depth() + 0.004
		add_child(book, false, Node.INTERNAL_MODE_BACK)
		books.append(book)
	if lean_last and books.size() > 1 and along < length - 0.05:
		# It tips back onto its neighbour, its foot slid out into the gap.
		var last: ShelfBook = books[books.size() - 1]
		last.rotation.z = deg_to_rad(18.0)
		last.position.x += sin(deg_to_rad(18.0)) * last.height / 2.0
