class_name Pantry
extends RefCounted
## How many of each ingredient the restaurant has in stock.
##
## Doesn't track where ingredients came from: the shop fills it today, and farms
## will later. Keyed by the shared [Item] resources from the catalog.

## Emitted whenever an ingredient's stock changes, with its new count.
signal count_changed(ingredient: Item, count: int)

# Only stocked ingredients have an entry: one that reaches 0 is erased.
var _counts: Dictionary[Item, int] = {}


## How many of [param ingredient] are in stock (0 if none).
func count(ingredient: Item) -> int:
	return _counts.get(ingredient, 0)


## Adds [param amount] of [param ingredient]. [param amount] must be positive.
func add(ingredient: Item, amount: int) -> void:
	if not _is_valid(ingredient, amount):
		return
	_set_count(ingredient, count(ingredient) + amount)


## Takes [param amount] of [param ingredient]. If there aren't enough, changes
## nothing and returns false.
func remove(ingredient: Item, amount: int) -> bool:
	if not _is_valid(ingredient, amount) or count(ingredient) < amount:
		return false
	_set_count(ingredient, count(ingredient) - amount)
	return true


## Whether there's enough stock for everything in [param recipe], which maps
## ingredients to amounts.
func has_all(recipe: Dictionary[Item, int]) -> bool:
	for ingredient: Item in recipe:
		if not _is_valid(ingredient, recipe[ingredient]):
			return false
		if count(ingredient) < recipe[ingredient]:
			return false
	return true


## Takes everything in [param recipe], or nothing if anything is short, so
## cooking never uses half a recipe. Returns whether it took them.
func remove_all(recipe: Dictionary[Item, int]) -> bool:
	if not has_all(recipe):
		return false
	# Update every count before emitting, so listeners never see half a recipe
	# taken and can't change the pantry in the middle of the loop.
	var new_counts: Dictionary[Item, int] = {}
	for ingredient: Item in recipe:
		new_counts[ingredient] = count(ingredient) - recipe[ingredient]
		_store(ingredient, new_counts[ingredient])
	for ingredient: Item in new_counts:
		count_changed.emit(ingredient, new_counts[ingredient])
	return true


## The stocked ingredients and their counts. Changing the copy doesn't change
## the pantry.
func get_counts() -> Dictionary[Item, int]:
	return _counts.duplicate()


## Empties the pantry.
func clear() -> void:
	for ingredient: Item in _counts.keys():
		_set_count(ingredient, 0)


func _set_count(ingredient: Item, value: int) -> void:
	_store(ingredient, value)
	count_changed.emit(ingredient, value)


func _store(ingredient: Item, value: int) -> void:
	if value == 0:
		_counts.erase(ingredient)
	else:
		_counts[ingredient] = value


# Bad arguments are a programming mistake, unlike running out of stock.
func _is_valid(ingredient: Item, amount: int) -> bool:
	if ingredient == null:
		push_error("Pantry: ingredient is null")
		return false
	if amount <= 0:
		push_error("Pantry: amount must be positive, got %d" % amount)
		return false
	return true
