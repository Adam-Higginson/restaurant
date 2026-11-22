extends GameTestSuite
## Tests for the galley's recipe book (its pages come up on the card, one per
## dish) and for the days at sea (each morning is a new day).


func test_reading_the_book_shows_a_page_per_recipe() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var hud: Hud3D = new_hud_3d(rig[1] as Player3D)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)
	var book: RecipeBook = rig[0].get_node("Galley/RecipeBook") as RecipeBook

	var pages: int = book.read()

	assert_int(pages).is_equal(Catalog.load_default().recipes.size())
	var card: MemoryCard = hud.get_node("%MemoryCard") as MemoryCard
	assert_str(card.showing.title).is_equal(Catalog.load_default().recipes[0].title)


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
