class_name MemoryBook
extends RefCounted
## The memories of home you've got back so far. Each [Memory] comes back
## once, the first time you make or catch its trigger item; after that it's
## in the book for good. Plain logic, no nodes: the [GameState] keeps one, and
## the HUD shows each memory as it comes back.

## Emitted when a memory comes back for the first time.
signal remembered(memory: Memory)

## Every memory there is to get back.
var all: Array[Memory] = []

var _remembered: Array[StringName] = []


func _init(memories: Array[Memory] = []) -> void:
	all = memories


## Notices that you've made or caught [param item]. If that brings back a
## memory you haven't had yet, returns it (and emits [signal remembered]);
## otherwise null.
func notice(item: Item) -> Memory:
	if item == null:
		return null
	for memory: Memory in all:
		if memory.trigger != null and memory.trigger.id == item.id \
				and not _remembered.has(memory.id):
			_remembered.append(memory.id)
			remembered.emit(memory)
			return memory
	return null


## Whether the memory with [param id] has come back.
func has(id: StringName) -> bool:
	return _remembered.has(id)


## The memories you've got back, in the order they came.
func remembered_memories() -> Array[Memory]:
	var found: Array[Memory] = []
	for id: StringName in _remembered:
		for memory: Memory in all:
			if memory.id == id:
				found.append(memory)
	return found


## Forgets everything, for a new game.
func clear() -> void:
	_remembered.clear()
