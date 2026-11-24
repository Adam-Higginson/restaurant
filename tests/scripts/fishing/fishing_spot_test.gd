extends GameTestSuite
## Tests for the rod at the rail: cast, a bite while hove to, strike, and the
## herring in your toolbar; fish won't bite while sailing; the lantern gets
## excited; and the herring fillets on the chopping board.

## Standing at the rod, facing it (starboard).
const AT_THE_ROD: Vector3 = Vector3(4.6, 5.35, 4.3)


func test_casting_puts_the_line_out() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_ROD)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spot: FishingSpot = _spot(rig[0] as Ship)
	await physics_ticks(runner, 5)
	assert_str(spot.prompt()).is_equal("Cast a line")

	await walk(runner, "move_right", 2)
	await press(runner, "interact")

	assert_int(spot.line.state).is_equal(FishingLine.State.WAITING)
	assert_bool((spot.get_node("Bobber") as Node3D).visible).is_true()


func test_a_strike_while_it_bites_lands_a_herring() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_ROD)
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spot: FishingSpot = _quick(_spot(rig[0] as Ship))
	await physics_ticks(runner, 5)
	await walk(runner, "move_right", 2)

	await press(runner, "interact")
	await physics_ticks(runner, 10)
	assert_str(spot.prompt()).is_equal("Strike!")
	await press(runner, "interact")

	var top: ItemInstance = player.toolbar.top()
	assert_object(top).is_not_null()
	assert_str(String(top.item.id)).is_equal("herring")


func test_fish_do_not_bite_while_sailing() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_ROD)
	var ship: Ship = rig[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var spot: FishingSpot = _quick(_spot(ship))
	ship.set_sail()
	await physics_ticks(runner, 5)

	spot.line.cast()
	await physics_ticks(runner, 30)

	assert_int(spot.line.state).is_equal(FishingLine.State.WAITING)
	assert_str(spot.prompt()).contains("hove to")


func test_the_lantern_gets_excited_when_a_fish_bites() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_ROD)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spot: FishingSpot = _quick(_spot(rig[0] as Ship))
	var spirit: LanternSpirit = rig[1].get_node("LanternSpirit") as LanternSpirit
	await physics_ticks(runner, 5)
	await walk(runner, "move_right", 2)

	await press(runner, "interact")
	await physics_ticks(runner, 8)

	assert_int(spot.line.state).is_equal(FishingLine.State.BITING)
	assert_bool(spirit.is_excited()).is_true()


func test_a_herring_fillets_on_the_chopping_board() -> void:
	var catalog: Catalog = Catalog.load_default()
	var fillet: Reaction = null
	for reaction: Reaction in catalog.reactions:
		if reaction.id == &"fillet_herring":
			fillet = reaction

	assert_object(fillet).is_not_null()
	assert_str(String(fillet.consumes[0].id)).is_equal("herring")
	assert_str(String(fillet.requires[0].id)).is_equal("chopping_board")
	assert_str(String(fillet.result.id)).is_equal("herring_fillet")
	assert_object(catalog.find_item(&"herring")).is_not_null()


func test_at_dawn_the_mackerel_bite_instead() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_ROD)
	var player: Player3D = rig[1] as Player3D
	var time: TimeOfDay = TimeOfDay.new()
	rig[0].get_parent().add_child(time)
	time.dawn = 1.0
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	_quick(_spot(rig[0] as Ship))
	await physics_ticks(runner, 5)
	await walk(runner, "move_right", 2)

	await press(runner, "interact")
	await physics_ticks(runner, 10)
	await press(runner, "interact")

	assert_str(String(player.toolbar.top().item.id)).is_equal("mackerel")


# The rod came off the deck in #207 (it confused players); fishing is kept for
# later, so the tests put one back where it stood, at the starboard rail.
func _spot(ship: Ship) -> FishingSpot:
	return add_rod(ship)


# Bites come a tenth of a second after a cast, and wait a second for a strike.
func _quick(spot: FishingSpot) -> FishingSpot:
	spot.line.min_wait = 0.1
	spot.line.max_wait = 0.1
	spot.line.bite_window = 1.0
	return spot
