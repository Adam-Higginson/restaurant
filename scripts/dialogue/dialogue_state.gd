class_name DialogueState
extends RefCounted
## What conversations remember and can ask about. [b]Flags[/b] are whole
## numbers that scripts set and that are saved with the voyage (0 means "not
## set"). [b]Facts[/b] are things the game knows right now (is it night?),
## which scripts can read but not change.
##
## The game's is [code]Game.dialogue[/code]. Tests make their own.

## Emitted when a flag changes.
signal flag_changed(flag: StringName, value: int)

var _flags: Dictionary[StringName, int] = {}
## Each fact's name, and a function taking nothing and returning an int.
var _facts: Dictionary[StringName, Callable] = {}


## The value of [param name]: a fact if there is one, otherwise the flag, or
## 0 if it's never been set.
func value(name: StringName) -> int:
	if _facts.has(name):
		var fact: Callable = _facts[name]
		if fact.is_valid():
			var answer: int = fact.call()
			return answer
		return 0
	return _flag(name)


## Whether [param name] is anything other than 0.
func is_set(name: StringName) -> bool:
	return value(name) != 0


## Sets flag [param name] to [param amount]. Facts can't be set.
func set_flag(name: StringName, amount: int = 1) -> void:
	if _facts.has(name):
		push_error("DialogueState: '%s' is a fact, and can't be set" % name)
		return
	if _flag(name) == amount:
		return
	if amount == 0:
		_flags.erase(name)
	else:
		_flags[name] = amount
	flag_changed.emit(name, amount)


## Adds [param amount] to flag [param name].
func add(name: StringName, amount: int = 1) -> void:
	set_flag(name, _flag(name) + amount)


## Puts flag [param name] back to 0.
func clear(name: StringName) -> void:
	set_flag(name, 0)


## Gives scripts something to read called [param name]: [param answer] takes
## nothing and returns an int (a bool counts as 1 or 0), asked each time.
func set_fact(name: StringName, answer: Callable) -> void:
	_facts[name] = answer


## Takes fact [param name] away again.
func remove_fact(name: StringName) -> void:
	_facts.erase(name)


## Whether [param name] is a fact.
func is_fact(name: StringName) -> bool:
	return _facts.has(name)


## Forgets every flag. Facts stay.
func reset() -> void:
	_flags.clear()


## The flags as plain data, for saving.
func to_dict() -> Dictionary:
	var data: Dictionary = {}
	for name: StringName in _flags:
		data[String(name)] = _flags[name]
	return data


## Puts saved flags back, replacing the ones there now.
func restore(data: Dictionary) -> void:
	_flags.clear()
	for key: Variant in data:
		var amount: int = int(str(data[key]).to_float())
		if amount != 0:
			_flags[StringName(str(key))] = amount


# A flag's value, 0 if it's never been set.
func _flag(name: StringName) -> int:
	var amount: int = _flags.get(name, 0)
	return amount
