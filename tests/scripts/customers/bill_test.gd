extends GameTestSuite
## Tests for Bill: what a customer pays for a dish. The rules mirror the
## Serving section of docs/GDD.md: the menu price, plus a quality tip (★★ 25%,
## ★★★ 50%) and a loved-dish tip (25%), each rounded up.

var _catalog: Catalog
var _salad: Item
var _soup: Item


func before_test() -> void:
	_catalog = Catalog.load_default()
	_salad = _catalog.find_item(&"garden_salad")
	_soup = _catalog.find_item(&"tomato_soup")


# --- Price and quality tip -----------------------------------------------------

func test_a_one_star_dish_pays_the_price_with_no_tip() -> void:
	var bill: Bill = Bill.new(12, 1, false)
	assert_int(bill.price).is_equal(12)
	assert_int(bill.quality_tip).is_equal(0)
	assert_int(bill.loved_tip).is_equal(0)
	assert_int(bill.tips()).is_equal(0)
	assert_int(bill.total()).is_equal(12)


func test_a_two_star_dish_tips_a_quarter() -> void:
	var bill: Bill = Bill.new(12, 2, false)
	assert_int(bill.quality_tip).is_equal(3)
	assert_int(bill.total()).is_equal(15)


func test_a_three_star_dish_tips_a_half() -> void:
	var bill: Bill = Bill.new(12, 3, false)
	assert_int(bill.quality_tip).is_equal(6)
	assert_int(bill.total()).is_equal(18)


func test_the_quality_tip_rounds_up() -> void:
	# 25% of 18 is 4.5.
	assert_int(Bill.new(18, 2, false).quality_tip).is_equal(5)
	# 50% of 15 is 7.5.
	assert_int(Bill.new(15, 3, false).quality_tip).is_equal(8)


# --- Loved tip -------------------------------------------------------------------

func test_a_loved_dish_tips_a_quarter_more() -> void:
	var bill: Bill = Bill.new(12, 1, true)
	assert_bool(bill.loved).is_true()
	assert_int(bill.loved_tip).is_equal(3)
	assert_int(bill.total()).is_equal(15)


func test_a_dish_that_isnt_loved_has_no_loved_tip() -> void:
	assert_bool(Bill.new(12, 3, false).loved).is_false()


func test_the_loved_tip_rounds_up() -> void:
	# 25% of 18 is 4.5.
	assert_int(Bill.new(18, 1, true).loved_tip).is_equal(5)


func test_quality_and_loved_tips_add_up() -> void:
	# 12 + 6 (★★★) + 3 (loved).
	var bill: Bill = Bill.new(12, 3, true)
	assert_int(bill.tips()).is_equal(9)
	assert_int(bill.total()).is_equal(21)


func test_each_tip_rounds_up_on_its_own() -> void:
	# 18 + 4.5 → 5 (★★) + 4.5 → 5 (loved). Rounding the sum would give 27.
	assert_int(Bill.new(18, 2, true).total()).is_equal(28)


# --- From a menu, a person and a served dish ---------------------------------

func test_for_dish_uses_the_menu_price_and_the_dish_quality() -> void:
	var menu: Menu = Menu.new()
	menu.prices[_salad] = 12
	var hazel: Person = _catalog.find_person(&"hazel")
	var bill: Bill = Bill.for_dish(menu, hazel, ItemInstance.new(_salad, 3))
	assert_int(bill.price).is_equal(12)
	assert_int(bill.quality_tip).is_equal(6)
	assert_bool(bill.loved).is_false()


func test_for_dish_tips_for_a_dish_the_person_loves() -> void:
	var menu: Menu = Menu.new()
	menu.prices[_salad] = 12
	# Pip loves Garden Salad.
	var pip: Person = _catalog.find_person(&"pip")
	var bill: Bill = Bill.for_dish(menu, pip, ItemInstance.new(_salad))
	assert_bool(bill.loved).is_true()
	assert_int(bill.loved_tip).is_equal(3)


func test_for_dish_off_the_menu_costs_nothing() -> void:
	var menu: Menu = Menu.new()
	menu.prices[_salad] = 12
	# Wren loves Tomato Soup, but it isn't on this menu.
	var wren: Person = _catalog.find_person(&"wren")
	var bill: Bill = Bill.for_dish(menu, wren, ItemInstance.new(_soup, 3))
	assert_int(bill.total()).is_equal(0)
