extends GameTestSuite
## Tests for the hull's saved shape (#196): reading its top edge and how wide
## it is between the measured samples and heights.


## Three samples a metre apart from z = 0, measured at y = 4, 5 and 6.
func _outline() -> HullOutline:
	var outline: HullOutline = HullOutline.new()
	outline.start_z = 0.0
	outline.step = 1.0
	outline.rims = PackedFloat32Array([5.5, 6.0, 7.0])
	outline.low_y = 4.0
	outline.height_step = 1.0
	outline.heights = 3
	# Sample by sample, bottom to top; nothing above each rim.
	outline.widths = PackedFloat32Array([2.0, 3.0, 0.0, 4.0, 5.0, 6.0, 4.0, 5.0, 6.0])
	return outline


func test_it_covers_from_the_first_sample_to_the_last() -> void:
	var outline: HullOutline = _outline()
	assert_float(outline.end_z()).is_equal(2.0)
	assert_bool(outline.covers(1.5)).is_true()
	assert_bool(outline.covers(-0.1)).is_false()
	assert_bool(outline.covers(2.1)).is_false()


func test_the_top_edge_is_read_between_samples_and_held_past_the_ends() -> void:
	var outline: HullOutline = _outline()
	assert_float(outline.rim_at(1.5)).is_equal_approx(6.5, 0.001)
	assert_float(outline.rim_at(-3.0)).is_equal_approx(5.5, 0.001)
	assert_float(outline.rim_at(9.0)).is_equal_approx(7.0, 0.001)


func test_the_width_is_read_between_samples_and_heights() -> void:
	var outline: HullOutline = _outline()
	assert_float(outline.half_width_at(1.0, 4.5)).is_equal_approx(4.5, 0.001)
	assert_float(outline.half_width_at(1.5, 5.0)).is_equal_approx(5.0, 0.001)


func test_no_width_above_the_top_edge_below_the_heights_or_past_the_ends() -> void:
	var outline: HullOutline = _outline()
	assert_float(outline.half_width_at(0.0, 5.8)).is_zero()
	assert_float(outline.half_width_at(1.0, 3.0)).is_zero()
	assert_float(outline.half_width_at(-1.0, 5.0)).is_zero()


func test_a_height_with_no_hull_doesnt_halve_its_neighbour() -> void:
	# At the first sample there's no hull at y = 6: just under the top edge it
	# reads the width at y = 5, not half of it.
	var outline: HullOutline = _outline()
	assert_float(outline.half_width_at(0.0, 5.4)).is_equal_approx(3.0, 0.001)


func test_the_saved_outline_is_ship_shaped() -> void:
	# Narrow at the bow, widest amidships, the top edge rising to the stern.
	var outline: HullOutline = load("res://data/ship/hull_outline.tres") as HullOutline
	var bow: float = outline.half_width_at(-18.0, 6.0)
	var middle: float = outline.half_width_at(0.0, 5.5)
	assert_float(bow).is_less(middle / 2.0)
	assert_float(middle).is_between(6.3, 7.5)
	assert_float(outline.rim_at(14.0)).is_greater(outline.rim_at(0.0) + 1.0)
