extends GameTestSuite
## Tests for ReadableBook, a book in the world you can read, and the old book
## on the creatures and spirits of the sea, on the navigation room's shelf
## (#159, moved there in #185): it opens at the page the
## heron's feather marks, says what the lantern needs, never gives the water
## away, and remembers you've read it.

const FIRE_SPIRITS: String = "res://data/books/fire_spirits.tres"
## Where the old book lies: on the navigation room bookshelf's third shelf,
## in ship space.
const BOOK_AT: Vector3 = Vector3(4.55, 1.95, 1.45)


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_the_old_book_falls_open_at_the_remedy() -> void:
	var book: Book = load(FIRE_SPIRITS) as Book
	var reading: BookReading = BookReading.new(book)

	assert_str(reading.left_page().heading).is_equal("A Remedy")
	assert_bool(reading.can_turn_back()).is_true()


func test_it_points_to_a_spiced_red_soup_and_never_to_the_water() -> void:
	var book: Book = load(FIRE_SPIRITS) as Book
	var text: String = ""
	for page: BookPage in book.pages:
		text += page.heading + " " + " ".join(page.lines) + " "
	text = text.to_lower()

	for clue: String in ["red soup", "tomato", "chilli", "spice"]:
		assert_str(text).contains(clue)
	for giveaway: String in ["water", "rain", "butt"]:
		assert_str(text).not_contains(giveaway)


func test_every_page_fits_its_paper() -> void:
	var book: Book = load(FIRE_SPIRITS) as Book
	for page: BookPage in book.pages:
		assert_bool(BookView.fits(page)).override_failure_message(
				"%s is too long for a page" % page.heading).is_true()


func test_pressing_interact_at_the_shelf_opens_it_and_remembers() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var hud: Hud3D = new_hud_3d(player)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	var view: BookView = hud.get_node("%BookView") as BookView
	var detector: InteractionDetector3D = player.get_node("InteractionDetector") \
			as InteractionDetector3D
	place_player_3d(runner, ship.to_global(Vector3(BOOK_AT.x, 1.05, BOOK_AT.z + 0.9)))
	player.face_towards(ship.to_global(BOOK_AT))
	await physics_ticks(runner, 3)
	assert_str(detector.interact_prompt()).is_equal("Read the old book")
	assert_bool(Game.dialogue.is_set(&"read_fire_spirits")).is_false()

	await press(runner, "interact")

	assert_bool(view.is_open()).is_true()
	assert_str(view.reading.left_page().heading).is_equal("A Remedy")
	assert_bool(Game.dialogue.is_set(&"read_fire_spirits")).is_true()


func test_with_no_book_view_it_does_not_open_or_remember() -> void:
	var scene: PackedScene = load("res://scenes/prototype/props/old_book.tscn") as PackedScene
	var old_book: ReadableBook = scene.instantiate() as ReadableBook
	add_child(old_book)
	auto_free(old_book)

	assert_bool(old_book.read()).is_false()
	assert_bool(Game.dialogue.is_set(&"read_fire_spirits")).is_false()
