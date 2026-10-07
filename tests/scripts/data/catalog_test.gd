extends GameTestSuite
## Tests for the game data: res://data/catalog.tres and the item, element and
## reaction files it lists. The expected values mirror the Cooking and MVP menu
## sections of docs/GDD.md, so if either changes, update both deliberately.

## Items with no reaction producing them: what the shop and the kitchen provide.
const RAW: Array[String] = [
	"lettuce", "tomato", "onion", "bread", "cheese", "chopping_board", "plate",
]

var _catalog: Catalog


func before_test() -> void:
	_catalog = Catalog.load_default()


# --- Contents -------------------------------------------------------------

func test_catalog_has_the_mvp_items() -> void:
	var ids: Array[StringName] = []
	for item: Item in _catalog.items:
		ids.append(item.id)
	assert_array(ids).contains_exactly_in_any_order([
		&"lettuce", &"tomato", &"onion", &"bread", &"cheese",
		&"chopped_lettuce", &"sliced_tomato", &"diced_tomato",
		&"garden_salad", &"tomato_soup", &"grilled_cheese",
		&"chopping_board", &"plate",
	])


func test_cut_is_an_instant_element() -> void:
	var cut: Element = _catalog.find_element(&"cut")
	assert_object(cut).is_not_null()
	assert_int(cut.kind).is_equal(Element.Kind.INSTANT)


func test_knife_is_a_tool_that_cuts() -> void:
	var knife: HandTool = _catalog.find_tool(&"chefs_knife")
	assert_object(knife).is_not_null()
	assert_object(knife.element).is_same(_catalog.find_element(&"cut"))


func test_find_tool_returns_null_for_unknown_id() -> void:
	assert_object(_catalog.find_tool(&"spatula")).is_null()


func test_chopping_reactions_match_design_doc() -> void:
	_assert_reaction(&"chop_lettuce", [&"lettuce"], [&"chopping_board"], &"cut", 3,
		&"chopped_lettuce", 3)
	_assert_reaction(&"slice_tomato", [&"tomato"], [&"chopping_board"], &"cut", 2,
		&"sliced_tomato", 3)
	_assert_reaction(&"dice_tomato", [&"sliced_tomato"], [&"chopping_board"], &"cut", 3,
		&"diced_tomato", 3)


func test_garden_salad_reactions_match_design_doc() -> void:
	_assert_reaction(&"garden_salad", [&"chopped_lettuce", &"sliced_tomato"], [&"plate"], &"", 0,
		&"garden_salad", 3)
	_assert_reaction(&"garden_salad_shortcut", [&"lettuce", &"tomato"], [&"plate"], &"", 0,
		&"garden_salad", 1)


# --- Tracing dishes back to raw items ------------------------------------------

func test_garden_salad_traces_back_to_raw_ingredients() -> void:
	# Every path to a salad bottoms out in raw items, through the proper chain
	# and the shortcut.
	var paths: Array[Array] = _raw_paths("garden_salad", [])
	var expected: Array[Array] = [
		["chopping_board", "lettuce", "plate", "tomato"],
		["lettuce", "plate", "tomato"],
	]
	assert_array(paths).contains_exactly_in_any_order(expected)


func test_garden_salad_quality_through_each_path() -> void:
	# Proper: lettuce★ and tomato★ chopped to ★★ each, plated to ★★★.
	var plate: VesselContents = _play_proper_salad()
	assert_int(plate.get_contents()[0].quality).is_equal(3)
	# Shortcut: whole ★ lettuce and tomato on a plate give a ★ salad.
	var shortcut: VesselContents = _vessel(&"plate", 3)
	shortcut.add_item(ItemInstance.new(_item(&"lettuce")))
	shortcut.add_item(ItemInstance.new(_item(&"tomato")))
	assert_object(shortcut.get_contents()[0].item).is_same(_item(&"garden_salad"))
	assert_int(shortcut.get_contents()[0].quality).is_equal(1)


# --- Consistency -----------------------------------------------------------

func test_ids_are_unique_within_each_kind() -> void:
	# An item and the reaction that makes it may share a name (garden_salad).
	var item_ids: Array[StringName] = []
	for item: Item in _catalog.items:
		item_ids.append(item.id)
	var element_ids: Array[StringName] = []
	for element: Element in _catalog.elements:
		element_ids.append(element.id)
	var reaction_ids: Array[StringName] = []
	for reaction: Reaction in _catalog.reactions:
		reaction_ids.append(reaction.id)
	for ids: Array[StringName] in [item_ids, element_ids, reaction_ids]:
		assert_array(_duplicates(ids)).override_failure_message(
			"Duplicate ids: %s" % [_duplicates(ids)]
		).is_empty()


func test_everything_is_complete() -> void:
	for item: Item in _catalog.items:
		assert_str(String(item.id)).is_not_empty()
		assert_str(item.display_name).override_failure_message(
			"%s has no name" % item.id
		).is_not_empty()
	for element: Element in _catalog.elements:
		assert_str(String(element.id)).is_not_empty()
		assert_str(element.display_name).is_not_empty()


func test_reactions_only_use_catalog_entries() -> void:
	# Same instances, not copies: reactions must link to the shared files.
	for reaction: Reaction in _catalog.reactions:
		for item: Item in reaction.consumes + reaction.requires + [reaction.result]:
			assert_bool(_catalog.items.has(item)).override_failure_message(
				"%s uses %s, which isn't in the catalog" % [reaction.id, str(item.id) if item else "nothing"]
			).is_true()
		for element: Element in reaction.elements:
			assert_bool(_catalog.elements.has(element)).override_failure_message(
				"%s uses an element that isn't in the catalog" % reaction.id
			).is_true()


func test_reactions_are_well_formed() -> void:
	for reaction: Reaction in _catalog.reactions:
		var message: String = "Reaction %s: " % reaction.id
		assert_array(reaction.consumes).override_failure_message(
			message + "consumes nothing"
		).is_not_empty()
		assert_array(reaction.requires).override_failure_message(
			message + "has no vessel"
		).is_not_empty()
		assert_int(reaction.quality).is_between(1, 3)
		if reaction.is_immediate():
			assert_float(reaction.amount).override_failure_message(
				message + "is immediate but has an amount"
			).is_equal(0.0)
		else:
			assert_float(reaction.amount).override_failure_message(
				message + "needs a positive amount"
			).is_greater(0.0)


func test_no_two_reactions_have_identical_inputs() -> void:
	var seen: Dictionary[String, StringName] = {}
	for reaction: Reaction in _catalog.reactions:
		var key: String = _inputs_key(reaction)
		assert_bool(seen.has(key)).override_failure_message(
			"%s and %s have identical inputs" % [reaction.id, seen.get(key, &"")]
		).is_false()
		seen[key] = reaction.id


# --- Helpers -------------------------------------------------------------------

func _assert_reaction(
	id: StringName, consumes: Array[StringName], requires: Array[StringName],
	element: StringName, amount: float, result: StringName, quality: int
) -> void:
	var reaction: Reaction = _find_reaction(id)
	assert_object(reaction).override_failure_message("No reaction with id %s" % id).is_not_null()
	if reaction == null:
		return
	assert_array(_ids(reaction.consumes)).contains_exactly_in_any_order(consumes)
	assert_array(_ids(reaction.requires)).contains_exactly_in_any_order(requires)
	var driver: Element = reaction.driving_element()
	assert_str(String(driver.id) if driver else "").is_equal(String(element))
	assert_float(reaction.amount).is_equal(amount)
	assert_str(String(reaction.result.id)).is_equal(String(result))
	assert_int(reaction.quality).is_equal(quality)


# Every set of raw items that can make [param id], each sorted. A path is the
# union of the raw items along the way (vessels included).
func _raw_paths(id: String, visiting: Array[String]) -> Array[Array]:
	if RAW.has(id):
		return [[id]]
	var paths: Array[Array] = []
	if visiting.has(id):
		return paths  # A loop: no way to make it from raw items this way.
	for reaction: Reaction in _catalog.reactions:
		if String(reaction.result.id) != id:
			continue
		var combined: Array[Array] = [[]]
		for input: Item in reaction.consumes + reaction.requires:
			var deeper: Array[String] = visiting.duplicate()
			deeper.append(id)
			var options: Array[Array] = _raw_paths(String(input.id), deeper)
			var next: Array[Array] = []
			for partial: Array in combined:
				for option: Array in options:
					next.append(_union(partial, option))
			combined = next
		for path: Array in combined:
			if not paths.has(path):
				paths.append(path)
	return paths


func _union(a: Array, b: Array) -> Array:
	var result: Array = a.duplicate()
	for value: Variant in b:
		if not result.has(value):
			result.append(value)
	result.sort()
	return result


func _play_proper_salad() -> VesselContents:
	var cut: Element = _catalog.find_element(&"cut")
	var board: VesselContents = _vessel(&"chopping_board", 1)
	var plate: VesselContents = _vessel(&"plate", 3)
	for raw: StringName in [&"lettuce", &"tomato"]:
		board.add_item(ItemInstance.new(_item(raw)))
		# Cut until it's the prepared version the salad needs.
		var steps: int = 3 if raw == &"lettuce" else 2
		for i: int in steps:
			board.add_element(cut)
		var prepared: ItemInstance = board.get_contents()[0]
		board.remove_item(prepared)
		plate.add_item(prepared)
	assert_int(plate.get_contents().size()).is_equal(1)
	assert_object(plate.get_contents()[0].item).is_same(_item(&"garden_salad"))
	return plate


func _vessel(id: StringName, capacity: int) -> VesselContents:
	return VesselContents.new(_item(id), _catalog.reactions, capacity)


func _item(id: StringName) -> Item:
	return _catalog.find_item(id)


func _find_reaction(id: StringName) -> Reaction:
	for reaction: Reaction in _catalog.reactions:
		if reaction.id == id:
			return reaction
	return null


func _duplicates(ids: Array[StringName]) -> Array[StringName]:
	var duplicates: Array[StringName] = []
	for id: StringName in ids:
		if ids.count(id) > 1 and not duplicates.has(id):
			duplicates.append(id)
	return duplicates


func _ids(items: Array[Item]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for item: Item in items:
		ids.append(item.id)
	return ids


func _inputs_key(reaction: Reaction) -> String:
	var consumes: Array[StringName] = _ids(reaction.consumes)
	var requires: Array[StringName] = _ids(reaction.requires)
	consumes.sort()
	requires.sort()
	var elements: Array[String] = []
	for element: Element in reaction.elements:
		elements.append(String(element.id))
	elements.sort()
	return "%s|%s|%s" % [consumes, requires, elements]
