class_name VesselContents
extends RefCounted
## The cooking logic of one vessel (a chopping board, a plate, a pan): what's in
## it, which elements are present, and the reactions in progress.
##
## A board or pan node owns one and feeds it items, elements and time. The
## reaction engine runs inside every change ([method add_item],
## [method add_element], [method tick] and so on), so callers never trigger it
## themselves. Nodes redraw from the signals and the [code]get_[/code] methods.
##
## Matching rules (see the GDD's Cooking section):
## - A reaction runs when everything it consumes and requires is present. The
##   vessel itself counts as present.
## - Items a reaction consumes are claimed by it; items it requires can be shared.
## - Reactions using more items win. A bigger reaction takes over items from a
##   smaller one already running, which is cancelled.
## - Immediate reactions finish straight away. Others progress while their
##   elements are present, and pause when a timed element goes away.
## - A finished reaction swaps its consumed items for its result, then matching
##   runs again so reactions can chain.

## Emitted after any change to what's in the vessel.
signal contents_changed()
signal reaction_started(active: ActiveReaction)
signal reaction_progressed(active: ActiveReaction)
## Emitted when a reaction stops early, because an item it needed was removed or
## a bigger reaction took its items.
signal reaction_cancelled(active: ActiveReaction)
signal reaction_finished(active: ActiveReaction, result: ItemInstance)

# Stops bad data (reactions that turn items back and forth) from looping forever.
const _MAX_CHAIN: int = 100

var _vessel: Item
var _capacity: int
# Reactions that can happen in this vessel, highest priority first.
var _reactions: Array[Reaction] = []
var _contents: Array[ItemInstance] = []
# Timed elements present right now.
var _elements: Array[Element] = []
var _active: Array[ActiveReaction] = []
var _contents_dirty: bool = false


## [param vessel] is the item this is the inside of (e.g. the chopping board).
## Only [param reactions] that require it can happen here. [param capacity] is
## how many items fit.
func _init(vessel: Item, reactions: Array[Reaction], capacity: int) -> void:
	_vessel = vessel
	_capacity = capacity
	var possible: Array[Reaction] = []
	for reaction: Reaction in reactions:
		if reaction.requires.has(vessel):
			possible.append(reaction)
	_reactions = _by_priority(possible)


## Puts [param instance] in the vessel. Returns false, changing nothing, if the
## vessel is full or already holds it.
func add_item(instance: ItemInstance) -> bool:
	if _contents.size() >= _capacity or _contents.has(instance):
		return false
	_contents.append(instance)
	_contents_dirty = true
	_react()
	return true


## Takes [param instance] out, cancelling any reaction that needed it. Returns
## false if it wasn't here.
func remove_item(instance: ItemInstance) -> bool:
	if not _contents.has(instance):
		return false
	_take_out(instance)
	_react()
	return true


## Applies [param element]. An instant element (a cut) moves every reaction it
## drives forward one step and doesn't stay. A timed element (fire) stays until
## [method remove_element]. Returns whether it did anything: false for a cut
## with nothing to cut, or fire that was already here.
func add_element(element: Element) -> bool:
	if element.kind == Element.Kind.TIMED:
		if _elements.has(element):
			return false
		_elements.append(element)
		return true
	var advanced: bool = false
	for active: ActiveReaction in _active:
		if active.reaction.driving_element() == element and _has_other_elements(active):
			active.progress = minf(active.progress + 1.0, active.reaction.amount)
			reaction_progressed.emit(active)
			advanced = true
	_react()
	return advanced


## Removes a timed [param element]. Reactions it drives pause, keeping their
## progress. Returns false if it wasn't here.
func remove_element(element: Element) -> bool:
	if not _elements.has(element):
		return false
	_elements.erase(element)
	return true


## Whether a timed [param element] is present.
func has_element(element: Element) -> bool:
	return _elements.has(element)


## Moves reactions driven by a present timed element forward by [param seconds].
func tick(seconds: float) -> void:
	for active: ActiveReaction in _active:
		var driver: Element = active.reaction.driving_element()
		if driver == null or driver.kind != Element.Kind.TIMED or not _elements.has(driver):
			continue
		if not _has_other_elements(active) or active.is_complete():
			continue
		active.progress = minf(active.progress + seconds, active.reaction.amount)
		reaction_progressed.emit(active)
	_react()


## What's in the vessel, in order. A copy: changing it doesn't change the vessel.
func get_contents() -> Array[ItemInstance]:
	return _contents.duplicate()


## The reactions in progress. A copy, like [method get_contents].
func get_active_reactions() -> Array[ActiveReaction]:
	return _active.duplicate()


# --- The engine ---------------------------------------------------------------

# Finishes what's complete and starts what's newly possible, until nothing
# changes. Every public change ends here.
func _react() -> void:
	var settled: bool = false
	for _step: int in _MAX_CHAIN:
		_start_reactions()
		if not _finish_completed():
			settled = true
			break
	if not settled:
		push_error(
			"VesselContents: reactions in %s kept chaining; check the data for a loop" % _vessel.id
		)
	if _contents_dirty:
		_contents_dirty = false
		contents_changed.emit()


func _start_reactions() -> void:
	for priority: int in _reactions.size():
		var reaction: Reaction = _reactions[priority]
		if reaction.consumes.is_empty():
			continue  # Would match forever; the catalog tests forbid it.
		var candidate: ActiveReaction = _match(reaction, priority)
		while candidate != null:
			for instance: ItemInstance in candidate.consumed:
				var owner: ActiveReaction = _claimant(instance)
				if owner != null:
					_cancel(owner)
			_active.append(candidate)
			reaction_started.emit(candidate)
			candidate = _match(reaction, priority)


# An ActiveReaction for [param reaction] using items present now, or null.
# Consumed items must be unclaimed, or claimed by a lower-priority reaction.
func _match(reaction: Reaction, priority: int) -> ActiveReaction:
	var consumed: Array[ItemInstance] = []
	for wanted: Item in reaction.consumes:
		var found: ItemInstance = _find_consumable(wanted, priority, consumed)
		if found == null:
			return null
		consumed.append(found)
	var required: Array[ItemInstance] = []
	var vessel_counted: bool = false
	for wanted: Item in reaction.requires:
		if wanted == _vessel and not vessel_counted:
			vessel_counted = true
			continue
		var found: ItemInstance = _find(wanted, consumed + required)
		if found == null:
			return null
		required.append(found)
	return ActiveReaction.new(reaction, consumed, required)


# Prefers an unclaimed instance, so a bigger reaction only takes over a running
# one when it has to.
func _find_consumable(wanted: Item, priority: int, exclude: Array[ItemInstance]) -> ItemInstance:
	var fallback: ItemInstance = null
	for instance: ItemInstance in _contents:
		if instance.item != wanted or exclude.has(instance):
			continue
		var owner: ActiveReaction = _claimant(instance)
		if owner == null:
			return instance
		if fallback == null and _reactions.find(owner.reaction) > priority:
			fallback = instance
	return fallback


func _find(wanted: Item, exclude: Array[ItemInstance]) -> ItemInstance:
	for instance: ItemInstance in _contents:
		if instance.item == wanted and not exclude.has(instance):
			return instance
	return null


func _claimant(instance: ItemInstance) -> ActiveReaction:
	for active: ActiveReaction in _active:
		if active.consumed.has(instance):
			return active
	return null


# Returns whether anything finished.
func _finish_completed() -> bool:
	var finished: bool = false
	for active: ActiveReaction in _active.duplicate():
		if _active.has(active) and active.is_complete():
			_finish(active)
			finished = true
	return finished


func _finish(active: ActiveReaction) -> void:
	_active.erase(active)
	var qualities: Array[int] = []
	for instance: ItemInstance in active.consumed + active.required:
		qualities.append(instance.quality)
	var result: ItemInstance = ItemInstance.new(
		active.reaction.result, active.reaction.result_quality(qualities)
	)
	# The result takes the place of the first item it consumed.
	var slot: int = _contents.find(active.consumed[0])
	for instance: ItemInstance in active.consumed:
		_take_out(instance)
	_contents.insert(mini(slot, _contents.size()), result)
	reaction_finished.emit(active, result)


# Removes an item and cancels every other reaction that used it.
func _take_out(instance: ItemInstance) -> void:
	_contents.erase(instance)
	_contents_dirty = true
	for active: ActiveReaction in _active.duplicate():
		if active.uses(instance):
			_cancel(active)


func _cancel(active: ActiveReaction) -> void:
	_active.erase(active)
	reaction_cancelled.emit(active)


# Whether every element the reaction needs, other than the one driving it, is present.
func _has_other_elements(active: ActiveReaction) -> bool:
	var driver: Element = active.reaction.driving_element()
	for element: Element in active.reaction.elements:
		if element != driver and not _elements.has(element):
			return false
	return true


# Most items (consumed + required) first; ties keep their original order.
static func _by_priority(reactions: Array[Reaction]) -> Array[Reaction]:
	# sort_custom isn't stable, so ties are broken by original position.
	var order: Array[int] = []
	for i: int in reactions.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool:
		var size_a: int = _size(reactions[a])
		var size_b: int = _size(reactions[b])
		return size_a > size_b if size_a != size_b else a < b
	)
	var sorted: Array[Reaction] = []
	for i: int in order:
		sorted.append(reactions[i])
	return sorted


static func _size(reaction: Reaction) -> int:
	return reaction.consumes.size() + reaction.requires.size()
