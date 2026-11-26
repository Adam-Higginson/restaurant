extends GameTestSuite
## Tests for the recipe book (#184): it lies on the lantern's table by your
## bunk (#206); picking it up makes it yours, on your toolbar to read later,
## without opening it; on your toolbar, Use reads it wherever you are; it
## opens in the book view, a page per dish, and every page fits its paper.
## And for the days at sea (each morning is a new day).

## Where to stand to pick the book up from the table by your bunk.
const STAND_AT: Vector3 = Vector3(3.6, 1.05, 13.6)


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_it_lies_by_the_lantern_and_picking_it_up_opens_your_journal() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var conversation: Conversation = new_conversation(player)
	var hud: Hud3D = new_hud_3d(player)
	var view: BookView = hud.get_node("%BookView") as BookView
	var opened: Array[int] = [0]
	view.opened.connect(func(_book: Book) -> void: opened[0] += 1)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	var book: RecipeBook = ship.get_node("BunkRoom/RecipeBook") as RecipeBook
	# On the little table by your bunk, beside the lantern's perch.
	var perch: Node3D = ship.get_node("BunkRoom/LanternPerch/Perch") as Node3D
	assert_float(book.global_position.distance_to(perch.global_position)).is_less(0.8)
	var detector: InteractionDetector3D = player.get_node("InteractionDetector") \
			as InteractionDetector3D
	place_player_3d(runner, ship.to_global(STAND_AT))
	player.face_towards(book.global_position)
	await physics_ticks(runner, 3)
	assert_bool(book.visible).is_true()
	assert_str(detector.interact_prompt()).is_equal("Pick up the book")
	assert_bool(player.toolbar.has_tool(&"recipe_book")).is_false()

	await press(runner, "interact")
	assert_bool(conversation.is_active()).is_true()
	# Read through: held up and yours, then the lantern's question and your
	# nod. It doesn't fall open: you read it later (#206).
	for i: int in 400:
		if not conversation.is_active():
			break
		var box: DialogueBox = conversation.box
		if box != null and box.is_typing():
			box.finish_typing()
		conversation.press()
		await physics_ticks(runner, 2)
	assert_bool(conversation.is_active()).is_false()

	assert_bool(Game.dialogue.is_set(RecipeBook.OWNED_FLAG)).is_true()
	assert_bool(Game.dialogue.is_set(&"said_a_cook")).is_true()
	assert_bool(player.toolbar.has_tool(&"recipe_book")).is_false()
	await physics_ticks(runner, 2)
	assert_int(opened[0]).is_equal(1)
	assert_bool(player.controls_enabled).is_false()
	assert_bool(book.visible).is_false()
	assert_bool(book.is_taken()).is_true()
	# Picking it up again does nothing.
	assert_bool(book.pick_up(player)).is_false()


func test_an_existing_book_flag_unlocks_the_journal_shortcut() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var player: Player3D = rig[1] as Player3D
	var hud: Hud3D = new_hud_3d(player)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)
	var view: BookView = hud.get_node("%BookView") as BookView
	Game.dialogue.set_flag(RecipeBook.OWNED_FLAG)
	assert_bool(player.toolbar.has_tool(&"recipe_book")).is_false()

	await press(runner, "journal")
	assert_bool(view.is_open()).is_true()
	assert_str(view.reading.left_page().heading).contains("A Little Warmth")
	assert_bool(player.controls_enabled).is_false()
	view.close()
	assert_bool(player.controls_enabled).is_true()


func test_opening_it_opens_the_book_view_with_a_page_per_recipe() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var player: Player3D = rig[1] as Player3D
	var hud: Hud3D = new_hud_3d(player)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)

	var pages: int = RecipeBook.open_book(player, player)

	assert_int(pages).is_equal(Catalog.load_default().recipes.size())
	var view: BookView = hud.get_node("%BookView") as BookView
	assert_bool(view.is_open()).is_true()
	assert_bool(hud.shows_play_parts()).is_false()
	view.close()
	assert_bool(hud.shows_play_parts()).is_true()


func test_journal_recipes_unlock_with_the_cookbook_and_fit_the_page() -> void:
	var early: Book = RecipeBook.make_journal()
	for page: BookPage in early.pages:
		assert_str(page.heading).is_not_equal("Spicy Tomato Soup")
	for flag: StringName in [&"has_saucepan", &"read_fire_spirits", &"fetched_water",
			&"cooked_remedy", &"warmed_lantern"]:
		Game.dialogue.set_flag(flag)
	var finished: Book = RecipeBook.make_journal()
	var has_remedy: bool = false
	for page: BookPage in finished.pages:
		has_remedy = has_remedy or page.heading == "Spicy Tomato Soup"
		assert_bool(BookView.fits(page)).override_failure_message(page.heading).is_true()
	assert_bool(has_remedy).is_true()


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
