class_name Bill
extends RefCounted
## What a customer pays for a dish: the menu price, a tip for its quality and a
## tip if it's a dish they love. See Serving in docs/GDD.md.

## The quality tip as a percentage of the price, indexed by stars (index 0 is
## unused).
const QUALITY_TIP_PERCENT: Array[int] = [0, 0, 25, 50]
const LOVED_TIP_PERCENT: int = 25

var price: int = 0
var quality_tip: int = 0
var loved_tip: int = 0
## Whether it was a dish they love, so they show a heart.
var loved: bool = false


func _init(dish_price: int, quality: int, is_loved: bool) -> void:
	price = dish_price
	quality_tip = _percent_of(price, QUALITY_TIP_PERCENT[quality])
	loved_tip = _percent_of(price, LOVED_TIP_PERCENT) if is_loved else 0
	loved = is_loved


## The bill for serving [param dish] to [param person] from [param menu].
static func for_dish(menu: Menu, person: Person, dish: ItemInstance) -> Bill:
	var dish_price: int = menu.price_of(dish.item)
	var dish_quality: int = dish.quality
	var dish_is_loved: bool = person.loved.has(dish.item)
	return Bill.new(dish_price, dish_quality, dish_is_loved)


func tips() -> int:
	return quality_tip + loved_tip


func total() -> int:
	return price + tips()


# Rounded up to a whole coin, so 25% of 18 (4.5) gives 5. Dividing by 100.0
# keeps the fraction; int / int would drop it before ceili() could round it up.
static func _percent_of(amount: int, percent: int) -> int:
	return ceili(amount * percent / 100.0)
