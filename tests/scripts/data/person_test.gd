extends GameTestSuite
## Tests for Person: a townsperson's tastes and how they choose what to order.

var _catalog: Catalog
var _salad: Item
var _soup: Item
var _grilled: Item


func before_test() -> void:
	_catalog = Catalog.load_default()
	_salad = _catalog.find_item(&"garden_salad")
	_soup = _catalog.find_item(&"tomato_soup")
	_grilled = _catalog.find_item(&"grilled_cheese")


# --- Taste ----------------------------------------------------------------------

func test_a_loved_dish_weighs_most() -> void:
	var person: Person = _person([_salad], [], [])
	assert_int(person.taste_weight(_salad)).is_equal(Person.LOVED_WEIGHT)


func test_a_liked_dish_weighs_less_than_a_loved_one() -> void:
	var person: Person = _person([], [_salad], [])
	assert_int(person.taste_weight(_salad)).is_equal(Person.LIKED_WEIGHT)
	assert_int(Person.LIKED_WEIGHT).is_less(Person.LOVED_WEIGHT)


func test_any_other_dish_weighs_least() -> void:
	var person: Person = _person([_soup], [_grilled], [])
	assert_int(person.taste_weight(_salad)).is_equal(Person.OTHER_WEIGHT)
	assert_int(Person.OTHER_WEIGHT).is_less(Person.LIKED_WEIGHT)


func test_a_disliked_dish_weighs_nothing() -> void:
	var person: Person = _person([], [], [_salad])
	assert_int(person.taste_weight(_salad)).is_equal(0)


func test_a_dislike_wins_over_a_love() -> void:
	# A data mistake shouldn't make someone order a dish they dislike.
	var person: Person = _person([_salad], [], [_salad])
	assert_int(person.taste_weight(_salad)).is_equal(0)


# --- Can they order? --------------------------------------------------------------

func test_can_order_from_a_menu_with_a_dish_they_dont_dislike() -> void:
	var person: Person = _person([], [], [_salad])
	assert_bool(person.can_order_from(_menu([_salad, _soup]))).is_true()


func test_cannot_order_when_they_dislike_everything_on_the_menu() -> void:
	var person: Person = _person([], [], [_salad, _soup])
	assert_bool(person.can_order_from(_menu([_salad, _soup]))).is_false()


func test_cannot_order_from_an_empty_menu() -> void:
	var person: Person = _person([_salad], [], [])
	assert_bool(person.can_order_from(_menu([]))).is_false()


# --- Choosing an order --------------------------------------------------------------

func test_orders_the_only_dish_on_the_menu() -> void:
	var person: Person = _person([], [], [])
	assert_object(person.choose_order(_menu([_salad]), _rng())).is_same(_salad)


func test_never_orders_a_disliked_dish() -> void:
	var person: Person = _person([], [], [_soup])
	var menu: Menu = _menu([_salad, _soup, _grilled])
	var rng: RandomNumberGenerator = _rng()
	for i: int in 200:
		assert_object(person.choose_order(menu, rng)).is_not_same(_soup)


func test_orders_nothing_when_they_dislike_everything() -> void:
	var person: Person = _person([], [], [_salad])
	assert_object(person.choose_order(_menu([_salad]), _rng())).is_null()


func test_orders_loved_dishes_more_often() -> void:
	# Loved (3) against an ordinary dish (1): about three orders in four.
	var person: Person = _person([_salad], [], [])
	var menu: Menu = _menu([_salad, _soup])
	var rng: RandomNumberGenerator = _rng()
	var salads: int = 0
	for i: int in 2000:
		if person.choose_order(menu, rng) == _salad:
			salads += 1
	assert_float(salads / 2000.0).is_between(0.7, 0.8)


func test_orders_every_dish_they_dont_dislike_sometimes() -> void:
	var person: Person = _person([_salad], [_soup], [])
	var menu: Menu = _menu([_salad, _soup, _grilled])
	var rng: RandomNumberGenerator = _rng()
	var seen: Array[Item] = []
	for i: int in 200:
		var dish: Item = person.choose_order(menu, rng)
		if not seen.has(dish):
			seen.append(dish)
	assert_array(seen).contains_exactly_in_any_order([_salad, _soup, _grilled])


# --- Helpers ----------------------------------------------------------------------

func _person(loved: Array[Item], liked: Array[Item], disliked: Array[Item]) -> Person:
	var person: Person = Person.new()
	person.id = &"test_person"
	person.display_name = "Test"
	person.loved = loved
	person.liked = liked
	person.disliked = disliked
	return person


func _menu(dishes: Array[Item]) -> Menu:
	var menu: Menu = Menu.new()
	for dish: Item in dishes:
		menu.prices[dish] = 10
	return menu


func _rng() -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345
	return rng
