extends GameTestSuite
## Tests for AnimationStepper (hand-keyed N64 animation) and the looks'
## other small N64 touches: per-corner light and the three-point filter.

const STAND_IN: String = "res://tests/fixtures/box_model.tscn"


func after_test() -> void:
	FiredModel.forget()


func test_without_steps_the_animation_runs_smoothly() -> void:
	var stepper: AnimationStepper = AnimationStepper.new()
	assert_float(stepper.take(0.016)).is_equal_approx(0.016, 0.00001)


func test_with_steps_it_moves_a_few_poses_a_second() -> void:
	var stepper: AnimationStepper = AnimationStepper.new(15.0)
	var frame: float = 1.0 / 60.0
	# Four frames of 1/60 s make one step of 1/15 s: still for three, then
	# the whole step at once.
	var moved: Array[float] = []
	for tick: int in 8:
		moved.append(stepper.take(frame))
	for still: int in [0, 1, 2, 4, 5, 6]:
		assert_float(moved[still]).is_equal(0.0)
	assert_float(moved[3]).is_equal_approx(4.0 * frame, 0.00001)
	assert_float(moved[7]).is_equal_approx(4.0 * frame, 0.00001)


func test_no_time_is_lost_over_a_second() -> void:
	var stepper: AnimationStepper = AnimationStepper.new(12.0)
	var total: float = 0.0
	for tick: int in 60:
		total += stepper.take(1.0 / 60.0)
	assert_float(total).is_equal_approx(1.0, 0.0001)


func test_creatures_move_in_steps_and_characters_smoothly() -> void:
	var creature: ArtLook = load("res://data/art/looks/creature.tres") as ArtLook
	var body: ArtLook = load("res://data/art/looks/character_body.tres") as ArtLook
	assert_float(creature.animation_steps).is_between(12.0, 20.0)
	assert_float(body.animation_steps).is_equal(0.0)


func test_the_small_touches_are_drawing_settings_not_firing_ones() -> void:
	var firing: Dictionary = ArtLook.new().firing()
	for key: String in ["vertex_lighting", "three_point_filter", "animation_steps"]:
		assert_bool(firing.has(key)).override_failure_message(key).is_false()


func test_per_corner_light_draws_with_the_vertex_lit_shader() -> void:
	var look: ArtLook = ArtLook.new()
	look.vertex_lighting = true
	var material: ShaderMaterial = FiredModel.material(
			"res://tests/fixtures/kiln/box_model.test.png", look)
	assert_object(material.shader).is_same(FiredModel.VERTEX_SHADER)
	var plain: ShaderMaterial = FiredModel.material(
			"res://tests/fixtures/kiln/box_model.test.png", ArtLook.new())
	assert_object(plain.shader).is_same(FiredModel.SHADER)


func test_the_three_point_filter_is_switched_on_by_the_look() -> void:
	var look: ArtLook = ArtLook.new()
	look.three_point_filter = true
	var material: ShaderMaterial = FiredModel.material(
			"res://tests/fixtures/kiln/box_model.test.png", look)
	var three_point: bool = material.get_shader_parameter(&"three_point")
	assert_bool(three_point).is_true()
