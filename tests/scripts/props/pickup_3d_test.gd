extends GameTestSuite
## Tests for Pickup3D: something lying on the ground (a crab's meat) that
## Interact picks up onto the toolbar, unless the toolbar is full.

const CRAB_MEAT: Item = preload("res://data/items/crab_meat.tres")
const TOMATO: Item = preload("res://data/items/tomato.tres")
## Just in front of the player, where their detector looks.
const IN_FRONT: Vector3 = Vector3(0, 0, -0.8)


func test_it_says_what_it_is_and_how_good() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var pickup: Pickup3D = Pickup3D.spawn(player.get_parent(), IN_FRONT,
			ItemInstance.new(CRAB_MEAT, 2))
	scene_runner(player.get_parent())

	assert_str(pickup.prompt(player)).is_equal("Pick up Crab Meat ★★")


func test_interact_picks_it_up_onto_the_toolbar() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var pickup: Pickup3D = Pickup3D.spawn(player.get_parent(), IN_FRONT,
			ItemInstance.new(CRAB_MEAT))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 4)

	await press(runner, "interact")

	assert_bool(player.toolbar.has_item(&"crab_meat")).is_true()
	assert_bool(is_instance_valid(pickup)).is_false()
	assert_bool(player.is_dodging()).is_false()


func test_the_prompt_offers_to_pick_it_up() -> void:
	var player: Player3D = new_player_3d_on_floor()
	Pickup3D.spawn(player.get_parent(), IN_FRONT, ItemInstance.new(CRAB_MEAT))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 4)

	var detector: InteractionDetector3D = player.get_node("InteractionDetector") \
			as InteractionDetector3D
	assert_str(detector.interact_prompt()).is_equal("Pick up Crab Meat ★")


func test_with_the_toolbar_full_it_stays_where_it_lies() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var pickup: Pickup3D = Pickup3D.spawn(player.get_parent(), IN_FRONT,
			ItemInstance.new(CRAB_MEAT))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	while not player.toolbar.is_full():
		player.toolbar.add(ItemInstance.new(TOMATO))

	assert_bool(pickup.pick_up(player)).is_false()

	assert_bool(is_instance_valid(pickup)).is_true()
	assert_bool(player.toolbar.has_item(&"crab_meat")).is_false()


func test_it_shows_the_item() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var pickup: Pickup3D = Pickup3D.spawn(player.get_parent(), IN_FRONT,
			ItemInstance.new(CRAB_MEAT))
	scene_runner(player.get_parent())

	assert_object(pickup.get_node_or_null("Item")).is_not_null()
