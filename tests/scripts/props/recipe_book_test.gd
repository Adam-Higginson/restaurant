extends GameTestSuite
## Tests for the galley's recipe book (it opens in the book view, a page per
## dish, and every page fits its paper) and for the days at sea (each morning
## is a new day).

const BOOK_AT: Vector3 = Vector3(3.15, 1.29, 4.95)


func test_reading_the_book_opens_it_with_a_page_per_recipe() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var player: Player3D = rig[1] as Player3D
	var hud: Hud3D = new_hud_3d(player)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)
	var book: RecipeBook = rig[0].get_node("Galley/RecipeBook") as RecipeBook
	var recipes: Array[Recipe] = Catalog.load_default().recipes

	var pages: int = book.read(player)

	assert_int(pages).is_equal(recipes.size())
	var view: BookView = hud.get_node("%BookView") as BookView
	assert_bool(view.is_open()).is_true()
	assert_str(view.reading.left_page().heading).is_equal(recipes[0].title)
	assert_bool(player.controls_enabled).is_false()
	assert_bool(hud.shows_play_parts()).is_false()

	view.close()
	assert_bool(hud.shows_play_parts()).is_true()


func test_pressing_interact_at_the_book_opens_it_and_again_closes_it() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var hud: Hud3D = new_hud_3d(player)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	var view: BookView = hud.get_node("%BookView") as BookView
	var detector: InteractionDetector3D = player.get_node("InteractionDetector") \
			as InteractionDetector3D
	place_player_3d(runner, ship.to_global(Vector3(BOOK_AT.x + 0.85, 1.05, BOOK_AT.z)))
	player.face_towards(ship.to_global(BOOK_AT))
	await physics_ticks(runner, 3)
	assert_str(detector.interact_prompt()).is_equal("Read the recipe book")

	await press(runner, "interact")
	# The press that opened it mustn't close it again.
	assert_bool(view.is_open()).is_true()

	await press(runner, "interact")
	assert_bool(view.is_open()).is_false()
	assert_bool(player.controls_enabled).is_true()


func test_every_recipe_page_fits_its_paper() -> void:
	var book: Book = RecipeBook.make_book(Catalog.load_default().recipes)
	for page: BookPage in book.pages:
		assert_bool(BookView.fits(page)).override_failure_message(
				"%s is too long for a page of the recipe book" % page.heading).is_true()


func test_every_recipe_has_steps_and_a_dish_the_galley_can_make() -> void:
	var catalog: Catalog = Catalog.load_default()
	assert_int(catalog.recipes.size()).is_greater_equal(3)
	for recipe: Recipe in catalog.recipes:
		assert_bool(recipe.steps.size() >= 2).is_true()
		var made_by_a_reaction: bool = false
		for reaction: Reaction in catalog.reactions:
			made_by_a_reaction = made_by_a_reaction or reaction.result.id == recipe.dish.id
		assert_bool(made_by_a_reaction).override_failure_message(
				"%s: nothing makes %s" % [recipe.id, recipe.dish.id]).is_true()


func test_each_morning_is_a_new_day() -> void:
	var time: TimeOfDay = TimeOfDay.new()
	add_child(time)
	auto_free(time)
	assert_int(time.day).is_equal(1)

	time.dawn = 1.0
	time.dawn = 1.0
	assert_int(time.day).is_equal(2)
	time.dawn = 0.0
	time.dawn = 1.0

	assert_int(time.day).is_equal(3)
