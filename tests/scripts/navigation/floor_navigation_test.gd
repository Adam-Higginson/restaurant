extends GameTestSuite
## Tests for FloorNavigation: the walkable floor customers find their way on.

const MAIN_SCENE: String = "res://scenes/main.tscn"
## The table's collision box (scenes/props/table.tscn), centred on the table.
const TABLE_SIZE: Vector2 = Vector2(28, 12)


func test_the_floor_is_baked_when_the_scene_starts() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var region: FloorNavigation = runner.find_child("FloorNavigation") as FloorNavigation
	assert_object(region).is_not_null()
	assert_int(region.navigation_polygon.get_polygon_count()).is_greater(0)


func test_every_seat_can_be_reached_from_the_door() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	assert_bool(await wait_for_navigation(runner)).is_true()
	var door: Vector2 = (runner.find_child("Door") as Node2D).global_position
	for table: Node2D in _tables(runner):
		var seat: Vector2 = (table.get_node("Seat") as Node2D).global_position
		var path: PackedVector2Array = _path(runner, door, seat)
		assert_bool(path.is_empty()).override_failure_message(
			"No path to %s" % table.name).is_false()
		if not path.is_empty():
			assert_float(path[path.size() - 1].distance_to(seat)).override_failure_message(
				"The path to %s stops short of its seat" % table.name).is_less(1.0)


func test_paths_go_around_the_tables() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	assert_bool(await wait_for_navigation(runner)).is_true()
	var door: Vector2 = (runner.find_child("Door") as Node2D).global_position
	var tables: Array[Node2D] = _tables(runner)
	for target: Node2D in tables:
		var seat: Vector2 = (target.get_node("Seat") as Node2D).global_position
		var path: PackedVector2Array = _path(runner, door, seat)
		assert_bool(path.is_empty()).override_failure_message(
			"No path to %s" % target.name).is_false()
		for i: int in range(1, path.size()):
			for table: Node2D in tables:
				var box: Rect2 = Rect2(table.global_position - TABLE_SIZE / 2.0, TABLE_SIZE)
				assert_bool(_segment_hits(path[i - 1], path[i], box)).override_failure_message(
					"The path to %s goes through %s" % [target.name, table.name]).is_false()


func _tables(runner: GdUnitSceneRunner) -> Array[Node2D]:
	var tables: Array[Node2D] = []
	for node: Node in runner.scene().get_tree().get_nodes_in_group(&"tables"):
		tables.append(node as Node2D)
	return tables


func _path(runner: GdUnitSceneRunner, from: Vector2, to: Vector2) -> PackedVector2Array:
	var map: RID = (runner.scene() as Node2D).get_world_2d().navigation_map
	return NavigationServer2D.map_get_path(map, from, to, true)


## Whether the segment from [param a] to [param b] passes through [param box],
## checked every pixel along it.
func _segment_hits(a: Vector2, b: Vector2, box: Rect2) -> bool:
	var steps: int = maxi(ceili(a.distance_to(b)), 1)
	for i: int in steps + 1:
		if box.has_point(a.lerp(b, float(i) / steps)):
			return true
	return false
