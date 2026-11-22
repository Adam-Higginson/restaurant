extends GameTestSuite
## Tests for the memories of home: each comes back once, the first time you
## make or catch its trigger, from the board, the hob or the rod; and the HUD
## shows it a line at a time.


func before_test() -> void:
	Game.memories.clear()


func after_test() -> void:
	Game.memories.clear()


func test_a_memory_comes_back_the_first_time_only() -> void:
	var book: MemoryBook = MemoryBook.new(Catalog.load_default().memories)
	var tomato: Item = Catalog.load_default().find_item(&"sliced_tomato")
	var heard: Array[Memory] = []
	book.remembered.connect(func(memory: Memory) -> void: heard.append(memory))

	var first: Memory = book.notice(tomato)
	var again: Memory = book.notice(tomato)

	assert_str(String(first.id)).is_equal("warm_tomatoes")
	assert_object(again).is_null()
	assert_int(heard.size()).is_equal(1)
	assert_bool(book.has(&"warm_tomatoes")).is_true()


func test_things_without_a_memory_bring_nothing_back() -> void:
	var book: MemoryBook = MemoryBook.new(Catalog.load_default().memories)

	assert_object(book.notice(Catalog.load_default().find_item(&"onion"))).is_null()
	assert_array(book.remembered_memories()).is_empty()


func test_every_memory_has_a_title_lines_and_a_trigger_in_the_catalog() -> void:
	var catalog: Catalog = Catalog.load_default()
	assert_array(catalog.memories).is_not_empty()
	for memory: Memory in catalog.memories:
		assert_str(memory.title).is_not_empty()
		assert_bool(memory.lines.size() >= 2).is_true()
		assert_object(catalog.find_item(memory.trigger.id)).is_not_null()


func test_slicing_a_tomato_on_the_board_brings_one_back() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	var board: Counter3D = ship.get_node("Galley/BoardCounter") as Counter3D
	var knife: HandTool = Catalog.load_default().find_tool(&"chefs_knife")

	board.slot.get_item().contents.add_item(
			ItemInstance.new(Catalog.load_default().find_item(&"tomato")))
	board.slot.use_tool(knife)
	board.slot.use_tool(knife)

	assert_bool(Game.memories.has(&"warm_tomatoes")).is_true()


func test_frying_on_the_hob_brings_one_back() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	var hob: Hob = ship.get_node("Galley/Hob") as Hob

	hob.heated.contents.add_item(
			ItemInstance.new(Catalog.load_default().find_item(&"herring_fillet")))
	await physics_ticks(runner, 6 * 60 + 5)

	assert_bool(Game.memories.has(&"fogged_window")).is_true()


func test_the_hud_shows_a_memory_a_line_at_a_time() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var hud: Hud3D = new_hud_3d(rig[1] as Player3D)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var card: MemoryCard = hud.get_node("%MemoryCard") as MemoryCard
	card.line_seconds = 0.3
	card.fade_seconds = 0.2
	card.hold_seconds = 0.3
	await physics_ticks(runner, 2)

	Game.memories.notice(Catalog.load_default().find_item(&"herring"))
	await physics_ticks(runner, 15)
	var early: PackedStringArray = card.shown_text()
	await physics_ticks(runner, 60)
	var later: PackedStringArray = card.shown_text()

	assert_str(card.showing.title).is_equal("A cold jetty")
	assert_int(early.size()).is_less(later.size())
	assert_str(later[0]).is_equal("A cold jetty")


func test_the_lantern_lights_up_when_a_memory_comes_back() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	new_hud_3d(rig[1] as Player3D)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = rig[1].get_node("LanternSpirit") as LanternSpirit
	await physics_ticks(runner, 2)

	Game.memories.notice(Catalog.load_default().find_item(&"garden_salad"))
	await physics_ticks(runner, 2)

	assert_bool(spirit.is_excited()).is_true()
