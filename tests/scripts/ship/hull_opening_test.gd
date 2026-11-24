extends GameTestSuite
## Tests for the holes portholes cut through the hull (#196): finding how far
## out the hull's outside is, which way, and what's inside the hole.


func test_it_finds_how_far_the_outside_is() -> void:
	var opening: HullOpening = HullOpening.new()
	auto_free(opening)
	opening.outline = _box_outline(3.0)
	var out: float = opening.reach(Vector3(0.0, 1.0, 1.0), Vector3.RIGHT)
	assert_float(out).is_between(3.0, 3.1)


func test_off_the_end_of_the_hull_is_outside_too() -> void:
	var opening: HullOpening = HullOpening.new()
	auto_free(opening)
	opening.outline = _box_outline(3.0)
	assert_float(opening.reach(Vector3(0.0, 1.0, 1.5), Vector3.BACK)).is_between(0.5, 0.6)


func test_the_hole_runs_one_way_from_the_porthole() -> void:
	var opening: HullOpening = HullOpening.new()
	opening.sleeve = false
	add_child(opening)
	auto_free(opening)
	opening.radius = 0.3
	opening.depth = 1.0
	opening.direction = -1.0
	assert_bool(opening.contains(opening.to_global(Vector3(0.0, 0.0, -0.5)))).is_true()
	assert_bool(opening.contains(opening.to_global(Vector3(0.0, 0.0, 0.5)))).is_false()
	assert_bool(opening.contains(opening.to_global(Vector3(0.4, 0.0, -0.5)))).is_false()


func test_the_galleys_porthole_opens_out_through_the_starboard_side() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	var opening: HullOpening = ship.get_node("Galley/PortholeGalley/HullOpening") as HullOpening
	assert_float(opening.depth).is_greater(0.5)
	var far_end: Vector3 = ship.to_local(opening.to_global(Vector3(0.0, 0.0,
			opening.direction * opening.depth)))
	var outline: HullOutline = load("res://data/ship/hull_outline.tres") as HullOutline
	assert_float(far_end.x).is_greater(outline.half_width_at(far_end.z, far_end.y) - 0.1)


func test_the_hull_knows_every_porthole_aboard() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	var openings: int = 0
	for node: Node in ship.get_tree().get_nodes_in_group(HullOpening.GROUP):
		if ship.is_ancestor_of(node):
			openings += 1
	# The galley's, the bunk room's and the two stern windows.
	assert_int(openings).is_equal(4)


## A hull 3 m either side of the centreline, 2 m long, 3 m tall.
func _box_outline(half: float) -> HullOutline:
	var outline: HullOutline = HullOutline.new()
	outline.start_z = 0.0
	outline.step = 1.0
	outline.rims = PackedFloat32Array([3.0, 3.0, 3.0])
	outline.low_y = 0.0
	outline.height_step = 1.0
	outline.heights = 4
	var widths: PackedFloat32Array = PackedFloat32Array()
	for at: int in 12:
		widths.append(half)
	outline.widths = widths
	return outline
