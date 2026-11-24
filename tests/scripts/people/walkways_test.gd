extends GameTestSuite
## Tests for Walkways, the network of waypoints the crew walk along (#157):
## the shortest way over its links, nothing when there's no way, and, on the
## ship itself, that every link is open floor and the way from the captain's
## fire to the water butt goes up the hatch ramp.


func test_the_way_goes_along_the_links_and_ends_at_the_target() -> void:
	# An L: A to B is 4 m along -Z, B to C 4 m along +X. A and C aren't linked.
	var walkways: Walkways = _walkways()
	_point(walkways, &"A", Vector3.ZERO, [&"B"])
	_point(walkways, &"B", Vector3(0, 0, -4), [&"C"])
	_point(walkways, &"C", Vector3(4, 0, -4), [])
	walkways.rebuild()

	var path: PackedVector3Array = walkways.route(Vector3(0.2, 0, 0.1), Vector3(4.5, 0, -4))

	assert_array(Array(path)).is_equal([Vector3.ZERO, Vector3(0, 0, -4), Vector3(4, 0, -4),
			Vector3(4.5, 0, -4)])


func test_near_the_same_waypoint_at_both_ends_the_way_goes_straight_there() -> void:
	# Both ends are nearest A, so there's no doubling back to it (#203).
	var walkways: Walkways = _walkways()
	_point(walkways, &"A", Vector3.ZERO, [&"B"])
	_point(walkways, &"B", Vector3(0, 0, -10), [])
	walkways.rebuild()

	var path: PackedVector3Array = walkways.route(Vector3(1, 0, 2), Vector3(3, 0, -1))

	assert_array(Array(path)).is_equal([Vector3(3, 0, -1)])


func test_with_no_way_along_the_links_there_is_no_route() -> void:
	var walkways: Walkways = _walkways()
	_point(walkways, &"A", Vector3.ZERO, [])
	_point(walkways, &"B", Vector3(0, 0, -4), [])
	walkways.rebuild()

	assert_array(Array(walkways.route(Vector3.ZERO, Vector3(0, 0, -4)))).is_empty()


func test_empty_walkways_have_no_route() -> void:
	var walkways: Walkways = _walkways()

	assert_array(Array(walkways.route(Vector3.ZERO, Vector3.ONE))).is_empty()


func test_every_link_aboard_is_open_floor() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var ship: Ship = rig[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 3)
	var walkways: Walkways = ship.get_node("Walkways") as Walkways
	var space: PhysicsDirectSpaceState3D = ship.get_world_3d().direct_space_state
	var ignored: Array[RID] = [(rig[1] as Player3D).get_rid()]
	for node: Node in ship.get_tree().get_nodes_in_group(Crewmate.GROUP):
		ignored.append((node as CollisionObject3D).get_rid())
	var ends: PackedVector3Array = walkways.link_ends()
	assert_int(ends.size()).is_greater(0)

	var blocked: PackedStringArray = PackedStringArray()
	for i: int in range(0, ends.size(), 2):
		# At knee and chest height, so a low prop or a wall both show.
		for height: float in [0.5, 1.4]:
			var from: Vector3 = walkways.to_global(ends[i] + Vector3.UP * height)
			var to: Vector3 = walkways.to_global(ends[i + 1] + Vector3.UP * height)
			var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
			query.exclude = ignored
			var hit: Dictionary = space.intersect_ray(query)
			if not hit.is_empty():
				var collider: Object = hit["collider"]
				blocked.append("%s -> %s at %.1f m hits %s" % [ends[i], ends[i + 1], height,
						(collider as Node).name])
	assert_array(Array(blocked)).is_empty()


func test_the_way_from_the_captains_fire_to_the_water_butt_climbs_the_ramp() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var ship: Ship = rig[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	var walkways: Walkways = ship.get_node("Walkways") as Walkways
	var fire: Node3D = ship.get_node("Crew/HeronNight") as Node3D
	var butt: Node3D = ship.get_node("Marks/WaterButt") as Node3D

	var path: PackedVector3Array = walkways.route(walkways.to_local(fire.global_position),
			walkways.to_local(butt.global_position))

	assert_int(path.size()).is_greater(3)
	assert_float(path[0].y).is_equal_approx(1.0, 0.05)
	assert_float(path[path.size() - 1].y).is_equal_approx(5.3, 0.05)


# Empty walkways in a world freed after the test.
func _walkways() -> Walkways:
	var walkways: Walkways = Walkways.new()
	add_child(walkways)
	auto_free(walkways)
	return walkways


# Adds a waypoint called [param point_name] at [param at] to [param walkways],
# linked to [param links].
func _point(walkways: Walkways, point_name: StringName, at: Vector3,
		links: Array[StringName]) -> void:
	var point: Waypoint = Waypoint.new()
	point.name = point_name
	point.position = at
	point.links = links
	walkways.add_child(point)
