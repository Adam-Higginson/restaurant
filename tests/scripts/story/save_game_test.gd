extends GameTestSuite
## Tests for keeping the voyage: what's saved, reading it back, nothing (not a
## crash) when there's no save or it's garbled, sleeping saves, and starting
## again picks up where you left off.


func before_test() -> void:
	SaveGame.erase()
	Game.memories.clear()


func after_test() -> void:
	SaveGame.erase()
	Game.memories.clear()


func test_a_voyage_saves_and_reads_back() -> void:
	var book: MemoryBook = MemoryBook.new(Catalog.load_default().memories)
	book.notice(Catalog.load_default().find_item(&"herring"))
	var time: TimeOfDay = TimeOfDay.new()
	auto_free(time)
	time.day = 4

	assert_bool(SaveGame.write(SaveGame.capture(book, time, 0.6))).is_true()
	var data: Dictionary = SaveGame.read()

	assert_array(data["memories"]).contains_exactly(["first_catch"])
	var day: int = data["day"]
	var morning: bool = data["morning"]
	var warmth: float = data["warmth"]
	assert_int(day).is_equal(4)
	assert_bool(morning).is_false()
	assert_float(warmth).is_equal_approx(0.6, 0.001)


func test_no_save_or_a_garbled_one_reads_as_nothing() -> void:
	assert_bool(SaveGame.exists()).is_false()

	var file: FileAccess = FileAccess.open(SaveGame.path, FileAccess.WRITE)
	file.store_string("not a voyage {")
	file.close()

	assert_dict(SaveGame.read()).is_empty()


func test_restoring_puts_memories_back_quietly() -> void:
	var book: MemoryBook = MemoryBook.new(Catalog.load_default().memories)
	var heard: Array[int] = [0]
	book.remembered.connect(func(_memory: Memory) -> void: heard[0] += 1)
	var time: TimeOfDay = TimeOfDay.new()
	auto_free(time)

	SaveGame.restore({"memories": ["first_catch", "nonsense"], "day": 3, "morning": true},
			book, time, null)

	assert_bool(book.has(&"first_catch")).is_true()
	assert_int(book.remembered_ids().size()).is_equal(1)
	assert_int(heard[0]).is_equal(0)
	assert_int(time.day).is_equal(3)
	assert_bool(time.is_morning()).is_true()


func test_sleeping_saves_the_voyage() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(4.0, 1.05, 13.95))
	var ship: Ship = rig[0] as Ship
	var time: TimeOfDay = TimeOfDay.new()
	ship.get_parent().add_child(time)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var bedside: Bedside = ship.get_node("BunkRoom/Bedside") as Bedside
	(bedside.get_node("ScreenFade") as ScreenFade).fade_seconds = 0.05
	bedside.sleep_seconds = 0.05
	await physics_ticks(runner, 2)
	Game.memories.notice(Catalog.load_default().find_item(&"garden_salad"))

	await bedside.sleep(rig[1] as Player3D)

	var data: Dictionary = SaveGame.read()
	var morning: bool = data["morning"]
	var day: int = data["day"]
	assert_bool(morning).is_true()
	assert_int(day).is_equal(2)
	assert_array(data["memories"]).contains(["squeaky_gate"])


func test_starting_again_carries_on_the_voyage() -> void:
	SaveGame.write({"version": SaveGame.VERSION, "memories": ["first_catch"], "day": 5,
			"morning": true, "warmth": 0.5})
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 5.35, 7.5))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var time: TimeOfDay = TimeOfDay.new()
	ship.get_parent().add_child(time)
	var opening: Opening = Opening.new()
	opening.player = player
	opening.ship = ship
	opening.title_seconds = 0.1
	var fade: ScreenFade = (load("res://ui/screen_fade.tscn") as PackedScene).instantiate() \
			as ScreenFade
	fade.name = "ScreenFade"
	fade.fade_seconds = 0.1
	opening.add_child(fade)
	ship.get_parent().add_child(opening)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())

	await physics_ticks(runner, 40)

	assert_bool(Game.memories.has(&"first_catch")).is_true()
	assert_int(time.day).is_equal(5)
	assert_bool(time.is_morning()).is_true()
	var spirit: LanternSpirit = player.get_node("LanternSpirit") as LanternSpirit
	assert_float(spirit.warmth).is_less(0.6)
	assert_bool(spirit.saying() in LanternLines.WELCOME_BACK).is_true()
