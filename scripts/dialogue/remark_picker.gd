class_name RemarkPicker
extends RefCounted
## Chooses which remark to say next (see [Remark]). Pure logic: it's told
## where everyone is, what the dialogue state is and what time it is, and
## remembers what it's picked, so it's easy to test.
##
## A remark can be said when everyone in it is there and near each other,
## its guard holds, it's off its cooldown, and it isn't the one said last.
## Of those, only the ones with the highest priority are picked from, each
## as likely as its weight.

## How near everyone in an exchange must be to the first speaker, in metres.
var near: float = 5.0

var _rng: RandomNumberGenerator
## When each remark was last said, in seconds, by [member Remark.key].
var _said_at: Dictionary[String, float] = {}
var _last: String = ""


## Picks with [param rng], or a freshly shuffled one if none is given. Tests
## pass one with a fixed seed so the picks are always the same.
func _init(rng: RandomNumberGenerator = null) -> void:
	_rng = rng
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()


## Picks one of [param remarks] whose [member Remark.moment] is
## [param moment], or null if none can be said. [param speakers] is where
## each speaker is, by [member Person.id]; anybody missing isn't there.
## [param now] is the time in seconds, for cooldowns.
##
## A reaction to a moment would rather not repeat the one said last, but will
## if it's the only one that fits; chatter never does.
func pick(remarks: Array[Remark], speakers: Dictionary[StringName, Vector3],
		state: DialogueState, now: float, moment: StringName = &"") -> Remark:
	var fits: Array[Remark] = _fitting(remarks, speakers, state, now, moment, false)
	if fits.is_empty() and moment != &"":
		fits = _fitting(remarks, speakers, state, now, moment, true)
	if fits.is_empty():
		return null
	var top: int = fits[0].priority
	for remark: Remark in fits:
		top = maxi(top, remark.priority)
	var total: int = 0
	var tier: Array[Remark] = []
	for remark: Remark in fits:
		if remark.priority == top:
			tier.append(remark)
			total += remark.weight
	var roll: int = _rng.randi_range(1, total)
	for remark: Remark in tier:
		roll -= remark.weight
		if roll <= 0:
			return remark
	return tier[-1]


## Whether [param remark] can be said now (see the class description).
## [param allow_last] lets the one said last be said again.
func can_say(remark: Remark, speakers: Dictionary[StringName, Vector3],
		state: DialogueState, now: float, allow_last: bool = false) -> bool:
	if remark.speakers.is_empty():
		return false
	if not allow_last and remark.key == _last:
		return false
	if _said_at.has(remark.key) and now - _said_at[remark.key] < remark.cooldown:
		return false
	if not remark.guard.is_empty() and not DialogueCondition.holds(remark.guard, state):
		return false
	for speaker: StringName in remark.speakers:
		if not speakers.has(speaker):
			return false
	var first: Vector3 = speakers[remark.speakers[0]]
	for speaker: StringName in remark.speakers:
		if speakers[speaker].distance_to(first) > near:
			return false
	return true


## Notes that [param remark] was said at [param now], for its cooldown and so
## it isn't picked again next.
func said(remark: Remark, now: float) -> void:
	_said_at[remark.key] = now
	_last = remark.key


func _fitting(remarks: Array[Remark], speakers: Dictionary[StringName, Vector3],
		state: DialogueState, now: float, moment: StringName, allow_last: bool) -> Array[Remark]:
	var fits: Array[Remark] = []
	for remark: Remark in remarks:
		if remark.moment == moment and can_say(remark, speakers, state, now, allow_last):
			fits.append(remark)
	return fits
