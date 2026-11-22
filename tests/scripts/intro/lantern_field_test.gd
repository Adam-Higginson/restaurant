extends GameTestSuite
## Tests for the dead lanterns on the seabed: they give no light of their
## own, the thing passing is a gap in which they're lost and come back, they
## rock in its wake and settle, and lightning shows on the glass of the ones
## outside the gap.

const LANTERN: PackedScene = preload("res://scenes/prototype/intro/dead_lantern.tscn")
const SEABED: Shader = preload("res://shaders/seabed.gdshader")


func test_inside_the_thing_is_dark_and_outside_is_not() -> void:
	var centre: Vector3 = Vector3(0, 0, 0)

	# Twenty long, four wide, lying along X.
	assert_float(LanternField.in_gap(Vector3(0, 0, 0), centre, 0.0, 20.0, 4.0)).is_equal(1.0)
	assert_float(LanternField.in_gap(Vector3(7, 5, 0.5), centre, 0.0, 20.0, 4.0)).is_equal(1.0)
	assert_float(LanternField.in_gap(Vector3(0, 0, 3), centre, 0.0, 20.0, 4.0)).is_equal(0.0)
	assert_float(LanternField.in_gap(Vector3(13, 0, 0), centre, 0.0, 20.0, 4.0)).is_equal(0.0)
	# Turned a quarter, it lies along Z instead.
	assert_float(LanternField.in_gap(Vector3(0, 0, 7), centre, PI * 0.5, 20.0, 4.0)).is_equal(1.0)
	assert_float(LanternField.in_gap(Vector3(7, 0, 0), centre, PI * 0.5, 20.0, 4.0)).is_equal(0.0)


func test_lanterns_are_lost_in_the_dark_as_it_passes_and_come_back() -> void:
	var field: LanternField = _new_field([Vector3(0, 0, 0), Vector3(0, 0, 8)])
	field.set_lightning(1.0)
	assert_float(field.sheen_of(0)).is_equal(1.0)

	# It arrives over the first lantern.
	field.gap = 1.0
	field.gap_length = 20.0
	field.gap_width = 4.0
	field.gap_centre = Vector3(0, 0, 0)
	field.advance(0.1)
	assert_float(field.darkness_of(0)).is_equal(1.0)
	assert_float(field.sheen_of(0)).is_equal(0.0)
	assert_float(field.darkness_of(1)).is_equal(0.0)
	assert_float(field.sheen_of(1)).is_equal(1.0)

	# And moves on.
	field.gap_centre = Vector3(40, 0, 0)
	field.advance(0.1)
	assert_float(field.darkness_of(0)).is_equal(0.0)
	assert_float(field.sheen_of(0)).is_equal(1.0)


func test_between_flashes_they_show_nothing_of_their_own() -> void:
	var field: LanternField = _new_field([Vector3(0, 0, 0)])

	field.advance(1.0)

	assert_float(field.sheen_of(0)).is_equal(0.0)
	assert_float(_sent(field, 0, &"cold")).is_equal(0.0)


func test_while_its_not_there_nothing_goes_dark() -> void:
	var field: LanternField = _new_field([Vector3(0, 0, 0)])
	field.gap = 0.0
	field.gap_centre = Vector3(0, 0, 0)

	field.advance(0.1)

	assert_float(field.darkness_of(0)).is_equal(0.0)


func test_a_lantern_rocks_in_its_wake_and_settles_where_it_was() -> void:
	var field: LanternField = _new_field([Vector3(0, 0, 0)])
	var lantern: Node3D = field.get_child(0) as Node3D
	var at_rest: Basis = lantern.transform.basis
	field.rock_seconds = 2.0
	field.rock_angle = 0.5
	field.gap = 1.0
	field.gap_centre = Vector3(0, 0, 0)

	field.advance(0.01)
	field.advance(0.25)
	assert_float(absf(field.tilt_of(0))).is_greater(0.05)
	assert_bool(lantern.transform.basis.is_equal_approx(at_rest)).is_false()

	field.advance(3.0)
	assert_float(field.tilt_of(0)).is_equal(0.0)
	assert_bool(lantern.transform.basis.is_equal_approx(at_rest)).is_true()


func test_the_rocking_swings_both_ways_and_dies_down() -> void:
	var early: float = LanternField.rock_after(0.125, 1.0)
	var back: float = LanternField.rock_after(0.375, 1.0)
	var late: float = LanternField.rock_after(0.875, 1.0)

	assert_float(early).is_greater(0.3)
	assert_float(back).is_less(-0.1)
	assert_float(absf(late)).is_less(absf(back))
	assert_float(LanternField.rock_after(1.0, 1.0)).is_equal(0.0)


func test_lightning_reaches_the_lanterns_outside_it_and_the_seabed() -> void:
	var field: LanternField = _new_field([Vector3(0, 0, 0), Vector3(0, 0, 9)])
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var sand: ShaderMaterial = ShaderMaterial.new()
	sand.shader = SEABED
	floor_mesh.material_override = sand
	field.get_parent().add_child(floor_mesh)
	field.floor_mesh = floor_mesh
	field.gap = 1.0
	field.gap_width = 4.0
	field.gap_length = 20.0
	field.gap_centre = Vector3(0, 0, 0)
	field.advance(0.1)

	field.set_lightning(0.8)

	assert_bool(field.is_in_group(Lightning.LIT_GROUP)).is_true()
	assert_float(_sent(field, 0, &"cold")).is_equal(0.0)
	assert_float(_sent(field, 1, &"cold")).is_equal_approx(0.8, 0.001)
	var flash: float = sand.get_shader_parameter("flash")
	var there: float = sand.get_shader_parameter("gap")
	assert_float(flash).is_equal_approx(0.8, 0.001)
	assert_float(there).is_equal(1.0)


func test_the_seabed_is_told_where_its_two_ends_are() -> void:
	var field: LanternField = _new_field([])
	field.position = Vector3(10, -7, 0)
	field.gap_length = 20.0
	field.gap_width = 4.0
	field.gap_centre = Vector3(1, 0, 2)

	var ends: Array[Vector2] = field.gap_ends()

	# Eight either side of the middle (its rounded ends take up the rest).
	assert_vector(ends[0]).is_equal_approx(Vector2(3, 2), Vector2(0.001, 0.001))
	assert_vector(ends[1]).is_equal_approx(Vector2(19, 2), Vector2(0.001, 0.001))


func test_starting_again_stands_every_lantern_back_up() -> void:
	var field: LanternField = _new_field([Vector3(0, 0, 0)])
	field.gap = 1.0
	field.gap_centre = Vector3(0, 0, 0)
	field.advance(0.01)
	field.advance(0.25)
	assert_float(absf(field.tilt_of(0))).is_greater(0.05)

	field.reset()

	assert_float(field.tilt_of(0)).is_equal(0.0)
	assert_float(field.darkness_of(0)).is_equal(0.0)


func test_the_dunes_are_low_and_rolling() -> void:
	var highest: float = 0.0
	for step: int in 200:
		highest = maxf(highest, absf(LanternField.dune_height(step * 0.37, step * 0.53)))

	assert_float(highest).is_between(0.2, 0.5)


# A number lantern [param index]'s glass has been given.
func _sent(field: LanternField, index: int, parameter: StringName) -> float:
	var glass: GeometryInstance3D = field.get_child(index).get_node("Glass") as GeometryInstance3D
	var value: float = glass.get_instance_shader_parameter(parameter)
	return value


# A field with a dead lantern at each of [param places], in its own space.
func _new_field(places: Array[Vector3]) -> LanternField:
	var world: Node3D = Node3D.new()
	auto_free(world)
	add_child(world)
	var field: LanternField = LanternField.new()
	for place: Vector3 in places:
		var lantern: Node3D = LANTERN.instantiate() as Node3D
		lantern.position = place
		field.add_child(lantern)
	world.add_child(field)
	return field
