extends GameTestSuite
## Tests for Menu, and the game's menu (res://data/menu.tres). The expected
## prices mirror the MVP menu section of docs/GDD.md.

var _catalog: Catalog
var _salad: Item
var _soup: Item


func before_test() -> void:
	_catalog = Catalog.load_default()
	_salad = _catalog.find_item(&"garden_salad")
	_soup = _catalog.find_item(&"tomato_soup")


# --- Looking things up ----------------------------------------------------------

func test_dishes_lists_everything_on_the_menu() -> void:
	var menu: Menu = Menu.new()
	menu.prices[_salad] = 12
	menu.prices[_soup] = 18
	assert_array(menu.dishes()).contains_exactly([_salad, _soup])


func test_an_empty_menu_has_no_dishes() -> void:
	assert_array(Menu.new().dishes()).is_empty()


func test_has_dish() -> void:
	var menu: Menu = Menu.new()
	menu.prices[_salad] = 12
	assert_bool(menu.has_dish(_salad)).is_true()
	assert_bool(menu.has_dish(_soup)).is_false()


func test_price_of_a_dish_on_the_menu() -> void:
	var menu: Menu = Menu.new()
	menu.prices[_salad] = 12
	assert_int(menu.price_of(_salad)).is_equal(12)


func test_price_of_a_dish_not_on_the_menu_is_zero() -> void:
	assert_int(Menu.new().price_of(_soup)).is_equal(0)


# --- The game's menu --------------------------------------------------------------

func test_the_game_menu_sells_garden_salad_for_12() -> void:
	# Only the salad can be cooked so far; soup (#37) and grilled cheese (#38)
	# join the menu when they can be.
	var menu: Menu = Menu.load_default()
	assert_array(menu.dishes()).contains_exactly([_salad])
	assert_int(menu.price_of(_salad)).is_equal(12)


func test_the_game_menu_uses_the_catalog_items() -> void:
	# The same instances, so customers' tastes match menu dishes.
	for dish: Item in Menu.load_default().dishes():
		assert_bool(_catalog.items.has(dish)).is_true()
