class_name Calendar
extends RefCounted
## Turns a day number (1, 2, 3, ...) into a date: season, day of the season,
## weekday and year.
##
## Four seasons of 28 days, and 7-day weeks. Day 1 is
## Spring 1, a Monday, in year 1. After Winter 28 comes Spring 1 of the next
## year. Every function is static, so call them on the class itself, e.g.
## [code]Calendar.season_of(12)[/code]. Day numbers start at 1.

enum Season { SPRING, SUMMER, AUTUMN, WINTER }

const DAYS_PER_SEASON: int = 28
const DAYS_PER_WEEK: int = 7
const SEASONS_PER_YEAR: int = 4
## Indexed by [enum Season].
const SEASON_NAMES: Array[String] = ["Spring", "Summer", "Autumn", "Winter"]
## Indexed by [method weekday_of]: 0 is Monday.
const WEEKDAY_NAMES: Array[String] = [
	"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
]


## The season [param day] falls in. Day 1 to 28 is spring, 29 to 56 is
## summer, and so on, starting again with spring in the next year.
static func season_of(day: int) -> Season:
	var days_since_start: int = day - 1
	@warning_ignore("integer_division")
	var seasons_that_have_passed: int = days_since_start / DAYS_PER_SEASON
	var this_year_season: int = seasons_that_have_passed % SEASONS_PER_YEAR
	return this_year_season as Season


## Which day of its season [param day] is, from 1 to 28.
static func day_of_season(day: int) -> int:
	var days_since_start: int = day - 1
	return (days_since_start % DAYS_PER_SEASON) + 1


## The weekday of [param day], from 0 (Monday) to 6 (Sunday).
static func weekday_of(day: int) -> int:
	var days_since_start: int = day - 1
	return days_since_start % DAYS_PER_WEEK


## The year [param day] falls in, starting at 1.
static func year_of(day: int) -> int:
	var days_since_start: int = day - 1
	@warning_ignore("integer_division")
	return (days_since_start / (DAYS_PER_SEASON * SEASONS_PER_YEAR)) + 1


## The date as players read it, e.g. "Spring 3, Wednesday".
static func format_date(day: int) -> String:
	return "{season} {day}, {weekday}".format({
		"season": SEASON_NAMES[season_of(day)],
		"day": day_of_season(day),
		"weekday": WEEKDAY_NAMES[weekday_of(day)],
	})
