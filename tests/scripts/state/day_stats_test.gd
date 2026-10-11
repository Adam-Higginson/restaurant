extends GameTestSuite
## Tests for DayStats: the day's tally of customers served and lost, and what
## they paid, for the end-of-day summary.

var _stats: DayStats


func before_test() -> void:
	_stats = DayStats.new()


func test_starts_at_zero() -> void:
	assert_int(_stats.served).is_equal(0)
	assert_int(_stats.lost).is_equal(0)
	assert_int(_stats.earnings).is_equal(0)
	assert_int(_stats.tips).is_equal(0)


func test_record_served_counts_the_customer_and_what_they_paid() -> void:
	# 12 + 6 (★★★) + 3 (loved).
	_stats.record_served(Bill.new(12, 3, true))
	assert_int(_stats.served).is_equal(1)
	assert_int(_stats.earnings).is_equal(21)
	assert_int(_stats.tips).is_equal(9)


func test_served_customers_add_up() -> void:
	_stats.record_served(Bill.new(12, 1, false))
	_stats.record_served(Bill.new(12, 2, false))
	_stats.record_served(Bill.new(18, 1, true))
	assert_int(_stats.served).is_equal(3)
	# 12 + 15 + 23.
	assert_int(_stats.earnings).is_equal(50)
	# 0 + 3 + 5.
	assert_int(_stats.tips).is_equal(8)


func test_record_lost_counts_the_customer_and_nothing_else() -> void:
	_stats.record_lost()
	_stats.record_lost()
	assert_int(_stats.lost).is_equal(2)
	assert_int(_stats.served).is_equal(0)
	assert_int(_stats.earnings).is_equal(0)


func test_reset_starts_the_tally_again() -> void:
	_stats.record_served(Bill.new(12, 3, true))
	_stats.record_lost()
	_stats.reset()
	assert_int(_stats.served).is_equal(0)
	assert_int(_stats.lost).is_equal(0)
	assert_int(_stats.earnings).is_equal(0)
	assert_int(_stats.tips).is_equal(0)


func test_assigning_a_count_directly_is_an_error_and_changes_nothing() -> void:
	await assert_error(func() -> void: _stats.served = 5).is_push_error(
		"DayStats: served is read-only, use record_served()"
	)
	await assert_error(func() -> void: _stats.lost = 5).is_push_error(
		"DayStats: lost is read-only, use record_lost()"
	)
	assert_int(_stats.served).is_equal(0)
	assert_int(_stats.lost).is_equal(0)
