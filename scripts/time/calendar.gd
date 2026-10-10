class_name Calendar
extends RefCounted
## Turns a day number (1, 2, 3, ...) into a date: season, day of the season,
## weekday and year.
##
## Like Stardew Valley: four seasons of 28 days, and 7-day weeks. Day 1 is
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
	# TODO(you): replace this.
	return Season.SPRING


## Which day of its season [param day] is, from 1 to 28.
static func day_of_season(day: int) -> int:
	# TODO(you): replace this.
	return 0


## The weekday of [param day], from 0 (Monday) to 6 (Sunday).
static func weekday_of(day: int) -> int:
	# TODO(you): replace this.
	return 0


## The year [param day] falls in, starting at 1.
static func year_of(day: int) -> int:
	# TODO(you): replace this.
	return 0


## The date as players read it, e.g. "Spring 3, Wednesday".
static func format_date(day: int) -> String:
	# TODO(you): replace this. Use the functions above and the name constants.
	return ""
