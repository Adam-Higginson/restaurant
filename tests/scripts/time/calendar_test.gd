extends GameTestSuite
## Tests for Calendar: 28-day seasons, 7-day weeks, day 1 = Spring 1, Monday.


# --- Seasons ------------------------------------------------------------------

func test_first_day_is_spring() -> void:
	assert_int(Calendar.season_of(1)).is_equal(Calendar.Season.SPRING)


func test_last_day_of_spring_is_still_spring() -> void:
	assert_int(Calendar.season_of(28)).is_equal(Calendar.Season.SPRING)


func test_day_after_spring_is_summer() -> void:
	assert_int(Calendar.season_of(29)).is_equal(Calendar.Season.SUMMER)


func test_seasons_run_in_order() -> void:
	assert_int(Calendar.season_of(57)).is_equal(Calendar.Season.AUTUMN)
	assert_int(Calendar.season_of(85)).is_equal(Calendar.Season.WINTER)
	assert_int(Calendar.season_of(112)).is_equal(Calendar.Season.WINTER)


func test_year_two_starts_in_spring() -> void:
	assert_int(Calendar.season_of(113)).is_equal(Calendar.Season.SPRING)


# --- Day of the season --------------------------------------------------------

func test_day_of_season_counts_from_one() -> void:
	assert_int(Calendar.day_of_season(1)).is_equal(1)
	assert_int(Calendar.day_of_season(3)).is_equal(3)


func test_day_of_season_ends_at_28() -> void:
	assert_int(Calendar.day_of_season(28)).is_equal(28)


func test_day_of_season_restarts_each_season() -> void:
	assert_int(Calendar.day_of_season(29)).is_equal(1)
	assert_int(Calendar.day_of_season(56)).is_equal(28)
	assert_int(Calendar.day_of_season(113)).is_equal(1)


# --- Weekdays -----------------------------------------------------------------

func test_first_day_is_monday() -> void:
	assert_int(Calendar.weekday_of(1)).is_equal(0)


func test_seventh_day_is_sunday() -> void:
	assert_int(Calendar.weekday_of(7)).is_equal(6)


func test_weeks_repeat() -> void:
	assert_int(Calendar.weekday_of(8)).is_equal(0)
	assert_int(Calendar.weekday_of(10)).is_equal(2)


func test_every_season_starts_on_monday() -> void:
	# 28 is a whole number of weeks, so seasons line up with weeks.
	assert_int(Calendar.weekday_of(29)).is_equal(0)
	assert_int(Calendar.weekday_of(113)).is_equal(0)


# --- Years --------------------------------------------------------------------

func test_first_year_is_one() -> void:
	assert_int(Calendar.year_of(1)).is_equal(1)
	assert_int(Calendar.year_of(112)).is_equal(1)


func test_year_two_starts_after_winter() -> void:
	assert_int(Calendar.year_of(113)).is_equal(2)
	assert_int(Calendar.year_of(225)).is_equal(3)


# --- Text ---------------------------------------------------------------------

func test_format_date_first_day() -> void:
	assert_str(Calendar.format_date(1)).is_equal("Spring 1, Monday")


func test_format_date_mid_spring() -> void:
	assert_str(Calendar.format_date(3)).is_equal("Spring 3, Wednesday")


func test_format_date_later_season() -> void:
	assert_str(Calendar.format_date(35)).is_equal("Summer 7, Sunday")
