extends GameTestSuite
## Tests for the galley in the 3D ship: its row of stations along the
## bulkhead, and a Garden Salad made from start to finish while the ship sails.

const LETTUCE: Item = preload("res://data/items/lettuce.tres")
const TOMATO: Item = preload("res://data/items/tomato.tres")
const BOARD: Item = preload("res://data/items/chopping_board.tres")
const PLATE: Item = preload("res://data/items/plate.tres")
const CHOPPED_LETTUCE: Item = preload("res://data/items/chopped_lettuce.tres")
const GARDEN_SALAD: Item = preload("res://data/items/garden_salad.tres")
## The stations along the bulkhead, port to starboard.
const STATIONS: Array[String] = ["Pantry", "Counter", "BoardCounter", "PlateRack"]
## Where the player stands, in the ship's own space, facing each station
## (the player faces -Z, towards the bulkhead).
const STAND_Z: float = 2.35
const STAND_Y: float = 1.05


func after_test() -> void:
	# A failing test could leave the game paused, which would stall later suites.
	get_tree().paused = false


func test_the_stations_stand_in_a_row_along_the_bulkhead() -> void:
	var ship: Ship = new_moored_ship_with_player(_spot_at(0.0))[0] as Ship
	scene_runner(ship.get_parent())

	var last_x: float = -INF
	for station_name: String in STATIONS:
		var station: Node3D = _station(ship, station_name)
		assert_float(station.position.z).is_equal_approx(1.45, 0.001)
		assert_float(station.position.x).is_greater(last_x)
		last_x = station.position.x
	assert_bool((_station(ship, "Counter") as Counter3D).slot.is_empty()).is_true()
	var board: Counter3D = _station(ship, "BoardCounter") as Counter3D
	assert_object(board.slot.get_item().item).is_same(BOARD)
	assert_object((_station(ship, "PlateRack") as Dispenser3D).item).is_same(PLATE)
	var pantry: StorageProp3D = _station(ship, "Pantry") as StorageProp3D
	assert_int(pantry.contents.count(LETTUCE, ItemInstance.MIN_QUALITY)).is_equal(3)
	assert_int(pantry.contents.count(TOMATO, ItemInstance.MIN_QUALITY)).is_equal(3)


func test_each_station_is_focused_from_in_front_of_it() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(_spot_at(0.0))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var detector: InteractionDetector3D = player.get_node("InteractionDetector") \
			as InteractionDetector3D
	await physics_ticks(runner, 5)

	for station_name: String in STATIONS:
		await _go_to(runner, ship, station_name)
		var focused: Interactable3D = detector.focused
		assert_object(focused).is_not_null()
		assert_object(focused.get_parent()).is_same(_station(ship, station_name))


func test_a_garden_salad_from_start_to_finish_while_sailing() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(_spot_at(0.0))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var counter: Counter3D = _station(ship, "Counter") as Counter3D
	var board: Counter3D = _station(ship, "BoardCounter") as Counter3D
	await physics_ticks(runner, 10)
	ship.set_sail()
	await physics_ticks(runner, 30)
	var start: Vector3 = ship.global_position
	var detector: InteractionDetector3D = player.get_node("InteractionDetector") 			as InteractionDetector3D

	# A plate from the rack goes down on the counter.
	await _go_to(runner, ship, "PlateRack")
	assert_str(detector.interact_prompt()).is_equal("Take Plate")
	await press(runner, "interact")
	await _go_to(runner, ship, "Counter")
	assert_str(detector.interact_prompt()).is_equal("Put down Plate")
	await press(runner, "interact")

	# Lettuce from the pantry, chopped on the board, carried to the plate.
	await _take_from_pantry(runner, ship, "Lettuce")
	await _go_to(runner, ship, "BoardCounter")
	assert_str(detector.interact_prompt()).is_equal("Put Lettuce on Chopping Board")
	await press(runner, "interact")
	assert_str(detector.tool_prompt()).is_equal("Chop")
	for i: int in 3:
		await press(runner, "use_tool")
	assert_str(detector.tool_prompt()).is_empty()
	await press(runner, "interact")
	assert_object(player.arms.top().item).is_same(CHOPPED_LETTUCE)
	await _go_to(runner, ship, "Counter")
	assert_str(detector.interact_prompt()).is_equal("Put Chopped Lettuce on Plate")
	await press(runner, "interact")
	assert_bool(player.arms.is_empty()).is_true()

	# A tomato sliced on the board (two cuts, stopping before diced), then the
	# plate carried over to it: the tomato slides onto the plate.
	await _take_from_pantry(runner, ship, "Tomato")
	await _go_to(runner, ship, "BoardCounter")
	await press(runner, "interact")
	for i: int in 2:
		await press(runner, "use_tool")
	await _go_to(runner, ship, "Counter")
	assert_str(detector.interact_prompt()).is_equal("Pick up Plate")
	await press(runner, "interact")
	await _go_to(runner, ship, "BoardCounter")
	assert_str(detector.interact_prompt()).is_equal("Put Sliced Tomato on Plate")
	await press(runner, "interact")
	await _go_to(runner, ship, "Counter")
	await press(runner, "interact")

	var plate: ItemInstance = counter.slot.get_item()
	assert_object(plate.item).is_same(PLATE)
	var food: Array[ItemInstance] = plate.contents.get_contents()
	assert_int(food.size()).is_equal(1)
	assert_object(food[0].item).is_same(GARDEN_SALAD)
	# Chopped and sliced properly: ★★ each, so a ★★★ salad. See Quality in the GDD.
	assert_int(food[0].quality).is_equal(ItemInstance.MAX_QUALITY)
	assert_array(board.slot.get_item().contents.get_contents()).is_empty()
	assert_bool(player.arms.is_empty()).is_true()
	assert_bool(ship.is_sailing).is_true()
	assert_float(ship.global_position.distance_to(start)).is_greater(1.0)


func test_one_pantry_visit_takes_lettuce_and_a_tomato() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(_spot_at(0.0))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await _go_to(runner, ship, "Pantry")
	await press(runner, "interact")
	var panel: ContainerPanel = _station(ship, "Pantry").get_node("ContainerPanel") 			as ContainerPanel
	for food_name: String in ["Lettuce", "Tomato"]:
		for button: Button in panel.get_rows():
			if button.text.begins_with(food_name):
				button.pressed.emit()
				break
	await press(runner, "ui_cancel")

	assert_int(player.toolbar.size()).is_equal(2)
	assert_object(player.toolbar.top().item).is_same(TOMATO)
	assert_object(player.toolbar.get_item(1).item).is_same(LETTUCE)


# Opens the pantry, takes one of the food named [param food_name], and closes it.
func _take_from_pantry(runner: GdUnitSceneRunner, ship: Ship, food_name: String) -> void:
	await _go_to(runner, ship, "Pantry")
	await press(runner, "interact")
	var panel: ContainerPanel = _station(ship, "Pantry").get_node("ContainerPanel") \
			as ContainerPanel
	assert_bool(panel.is_open()).is_true()
	for button: Button in panel.get_rows():
		if button.text.begins_with(food_name):
			button.pressed.emit()
			break
	await press(runner, "ui_cancel")
	assert_bool(panel.is_open()).is_false()


# Puts the player in front of the station named [param station_name], on the
# moving ship, and lets the detector catch up.
func _go_to(runner: GdUnitSceneRunner, ship: Ship, station_name: String) -> void:
	var x: float = _station(ship, station_name).position.x
	place_player_3d(runner, ship.to_global(_spot_at(x)))
	await physics_ticks(runner, 3)


func _spot_at(x: float) -> Vector3:
	return Vector3(x, STAND_Y, STAND_Z)


func _station(ship: Ship, station_name: String) -> Node3D:
	return ship.get_node("Galley/" + station_name) as Node3D
