extends GameTestSuite
## Tests for Hearts: the player's health in half-hearts.


func test_three_hearts_are_six_halves() -> void:
	var hearts: Hearts = Hearts.new(3)

	assert_int(hearts.max_halves).is_equal(6)
	assert_int(hearts.halves).is_equal(6)
	assert_bool(hearts.is_empty()).is_false()


func test_a_hit_removes_half_a_heart() -> void:
	var hearts: Hearts = Hearts.new(3)
	var seen: Array[int] = []
	hearts.changed.connect(func(halves: int) -> void: seen.append(halves))

	hearts.hurt()

	assert_int(hearts.halves).is_equal(5)
	assert_array(seen).contains_exactly([5])


func test_a_bigger_hit_removes_more() -> void:
	var hearts: Hearts = Hearts.new(3)

	hearts.hurt(2)

	assert_int(hearts.halves).is_equal(4)


func test_the_last_half_heart_empties_them_once() -> void:
	var hearts: Hearts = Hearts.new(1)
	var emptied: Array[int] = [0]
	hearts.emptied.connect(func() -> void: emptied[0] += 1)

	hearts.hurt()
	assert_int(emptied[0]).is_equal(0)
	hearts.hurt()
	hearts.hurt()

	assert_bool(hearts.is_empty()).is_true()
	assert_int(emptied[0]).is_equal(1)


func test_hearts_never_go_below_none() -> void:
	var hearts: Hearts = Hearts.new(1)

	hearts.hurt(10)

	assert_int(hearts.halves).is_equal(0)


func test_a_hit_of_nothing_changes_nothing() -> void:
	var hearts: Hearts = Hearts.new(3)
	var changes: Array[int] = [0]
	hearts.changed.connect(func(_halves: int) -> void: changes[0] += 1)

	hearts.hurt(0)
	hearts.hurt(-2)

	assert_int(hearts.halves).is_equal(6)
	assert_int(changes[0]).is_equal(0)


func test_refill_fills_every_heart() -> void:
	var hearts: Hearts = Hearts.new(3)
	hearts.hurt(6)

	hearts.refill()

	assert_int(hearts.halves).is_equal(6)
	assert_bool(hearts.is_empty()).is_false()


func test_the_last_heart_is_one_heart_or_less_but_not_none() -> void:
	var hearts: Hearts = Hearts.new(3)
	assert_bool(hearts.is_last_heart()).is_false()

	hearts.hurt(3)
	assert_bool(hearts.is_last_heart()).is_false()
	hearts.hurt(1)
	assert_bool(hearts.is_last_heart()).is_true()
	hearts.hurt(1)
	assert_bool(hearts.is_last_heart()).is_true()
	hearts.hurt(1)
	assert_bool(hearts.is_last_heart()).is_false()
