extends GameTestSuite
## Tests for FloatOnSea: whatever it's a child of rides the waves, a set
## height above (or below) the surface, and is left alone with no sea.

const SEA_SCENE: String = "res://scenes/prototype/weather/sea_surface.tscn"


func test_its_parent_sits_on_the_surface_where_it_is() -> void:
	var world: Node3D = _world_with_sea()
	var floated: Node3D = _floated(world, Vector3(12, 40, -7), 0.0)
	var sea: Sea = world.get_node("Sea") as Sea
	var runner: GdUnitSceneRunner = scene_runner(world)

	await physics_ticks(runner, 5)

	assert_float(floated.global_position.y).is_equal_approx(
			FloatOnSea.surface_height(sea, floated.global_position), 0.05)
	# Only its height is touched.
	assert_float(floated.global_position.x).is_equal(12.0)
	assert_float(floated.global_position.z).is_equal(-7.0)


func test_it_keeps_its_height_above_the_surface() -> void:
	var world: Node3D = _world_with_sea()
	var above: Node3D = _floated(world, Vector3(3, 0, 3), 2.0)
	var below: Node3D = _floated(world, Vector3(3, 0, 3), -1.5)
	var runner: GdUnitSceneRunner = scene_runner(world)

	await physics_ticks(runner, 5)

	assert_float(above.global_position.y - below.global_position.y).is_equal_approx(3.5, 0.001)


func test_it_rises_and_falls_as_the_waves_pass() -> void:
	var world: Node3D = _world_with_sea()
	var floated: Node3D = _floated(world, Vector3(0, 0, 0), 0.0)
	var runner: GdUnitSceneRunner = scene_runner(world)
	var lowest: float = INF
	var highest: float = -INF

	for i: int in 240:
		await physics_ticks(runner, 1)
		lowest = minf(lowest, floated.global_position.y)
		highest = maxf(highest, floated.global_position.y)

	assert_float(highest - lowest).is_greater(0.05)


func test_with_no_sea_its_parent_stays_where_it_is() -> void:
	var world: Node3D = Node3D.new()
	auto_free(world)
	var floated: Node3D = _floated(world, Vector3(1, 4, 2), 9.0)
	var runner: GdUnitSceneRunner = scene_runner(world)

	await physics_ticks(runner, 5)

	assert_vector(floated.global_position).is_equal(Vector3(1, 4, 2))


func _world_with_sea() -> Node3D:
	var world: Node3D = Node3D.new()
	auto_free(world)
	var sea: Sea = (load(SEA_SCENE) as PackedScene).instantiate() as Sea
	sea.name = "Sea"
	sea.settings = load("res://data/sea/night_swell.tres") as WaveSettings
	world.add_child(sea)
	return world


# A node at [param at] with a FloatOnSea keeping it [param height] above
# the surface, added to [param world].
func _floated(world: Node3D, at: Vector3, height: float) -> Node3D:
	var floated: Node3D = Node3D.new()
	floated.position = at
	var floater: FloatOnSea = FloatOnSea.new()
	floater.height_above = height
	floated.add_child(floater)
	world.add_child(floated)
	return floated
