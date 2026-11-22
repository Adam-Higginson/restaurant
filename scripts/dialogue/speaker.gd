class_name Speaker
extends Marker3D
## Where somebody's words come from: a marker at their head. What they say
## floats up beside it in a speech bubble (a [SpeechBubble3D]), stays long
## enough to read and fades; lines said together wait their turn.
##
## A wall between you and them hides the bubble: every few physics ticks it
## looks along a straight line from your eyes to their face (a little below
## this marker), and fades the bubble out if something solid is in the way.
##
## Every speaker joins [constant GROUP], so the [Chatter] can find who's about.

## Emitted when a line has been shown and has faded.
signal said(line: String)
## Emitted when [method hush] cuts them off mid-line.
signal hushed

## The group every speaker is in.
const GROUP: StringName = &"speakers"
## How high the player's eyes are above their feet, in metres.
const EYE_HEIGHT: float = 1.5
## Line of sight is checked once every this many physics ticks.
const SIGHT_EVERY: int = 6

## Who this is: a [member Person.id], as written in dialogue scripts.
@export var who: StringName = &""
## Seconds to read a line: this, plus [member seconds_per_letter] per letter.
@export var base_seconds: float = 1.6
@export var seconds_per_letter: float = 0.055
## Seconds of quiet after a line fades, before the next.
@export var pause_seconds: float = 0.35
## Seconds for the bubble to fade when a wall comes between you.
@export var sight_fade_seconds: float = 0.2
## How far below this marker their face is, in metres: line of sight is
## checked to there. The marker floats above their head, where the bubble's
## tail points, and under a low ceiling it can poke through.
@export var sight_drop: float = 0.35

## Who's listening, for line of sight: the player, found when first needed.
var listener: Node3D = null

## The line showing now, or "" when they're quiet.
var saying: String:
	get:
		return _saying

## The bubble their words show in.
var bubble: SpeechBubble3D:
	get:
		return _bubble

var _saying: String = ""
var _queue: Array[Queued] = []
var _tween: Tween = null
var _bubble: SpeechBubble3D = SpeechBubble3D.new()
## Whether the listener could see this marker when last checked.
var _seen: bool = true
var _ticks_to_look: int = 0


## A line waiting its turn.
class Queued:
	var words: String
	var style: SpeechBubble.Style

	func _init(line: String, how: SpeechBubble.Style) -> void:
		words = line
		style = how


func _init() -> void:
	# A child from the start, so it's freed with the speaker even if they
	# never join the tree.
	add_child(_bubble)


func _ready() -> void:
	add_to_group(GROUP)


func _process(delta: float) -> void:
	var target: float = 1.0 if _seen else 0.0
	_bubble.sight = move_toward(_bubble.sight, target, delta / maxf(sight_fade_seconds, 0.01))


func _physics_process(_delta: float) -> void:
	if _saying.is_empty():
		return
	_ticks_to_look -= 1
	if _ticks_to_look > 0:
		return
	_ticks_to_look = SIGHT_EVERY
	_seen = is_seen()


## Says [param words] in a bubble of [param style], after anything they're
## already saying.
func say(words: String, style: SpeechBubble.Style = SpeechBubble.Style.SPEECH) -> void:
	if words.is_empty():
		return
	_queue.append(Queued.new(words, style))
	if _saying.is_empty():
		_next()


## Stops whatever they're saying, and says [param words] straight away.
func say_now(words: String, style: SpeechBubble.Style = SpeechBubble.Style.SPEECH) -> void:
	hush()
	say(words, style)


## Stops talking: the bubble fades and anything waiting is forgotten.
func hush() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	_queue.clear()
	var was_saying: bool = not _saying.is_empty()
	_saying = ""
	_bubble.hush()
	if was_saying:
		hushed.emit()


## Whether they're saying something, or have something waiting to be said.
func is_busy() -> bool:
	return not _saying.is_empty()


## How long [param line] stays up, in seconds, not counting its fades.
func read_seconds(line: String) -> float:
	return base_seconds + seconds_per_letter * line.length()


## Whether the listener can see this marker, with nothing solid between
## their eyes and it. True if there's nobody listening.
func is_seen() -> bool:
	if not is_instance_valid(listener):
		listener = get_tree().get_first_node_in_group(Player3D.GROUP) as Node3D
	if not is_instance_valid(listener):
		return true
	return in_sight_of(eye_of(listener))


## Whether nothing solid is between [param eye] and their face (see
## [member sight_drop]). Neither the listener nor the body this marker belongs
## to counts.
func in_sight_of(eye: Vector3) -> bool:
	if not is_inside_tree():
		return false
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(eye,
			global_position + Vector3.DOWN * sight_drop)
	var exclude: Array[RID] = []
	var own_body: CollisionObject3D = _own_body()
	if own_body != null:
		exclude.append(own_body.get_rid())
	var listening: CollisionObject3D = listener as CollisionObject3D
	if listening != null:
		exclude.append(listening.get_rid())
	query.exclude = exclude
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Where [param someone]'s eyes are: [constant EYE_HEIGHT] above their feet.
static func eye_of(someone: Node3D) -> Vector3:
	return someone.global_position + Vector3.UP * EYE_HEIGHT


## The bubble style for a line tagged [param tag] (see [constant Remark.LINE_TAGS]).
static func style_for(tag: StringName) -> SpeechBubble.Style:
	match tag:
		&"thought":
			return SpeechBubble.Style.THOUGHT
		&"shout":
			return SpeechBubble.Style.EXCLAIM
		&"sound":
			return SpeechBubble.Style.SOUND
	return SpeechBubble.Style.SPEECH


# Shows the next line waiting, or goes quiet.
func _next() -> void:
	if _queue.is_empty():
		_saying = ""
		return
	var line: Queued = _queue.pop_front()
	_saying = line.words
	# Look now, so a bubble behind a wall never flashes up before the first check.
	_seen = is_seen()
	_bubble.sight = 1.0 if _seen else 0.0
	_ticks_to_look = SIGHT_EVERY
	_bubble.say(line.words, self, line.style)
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(_bubble.fade_seconds + read_seconds(line.words))
	_tween.tween_callback(_bubble.hush)
	_tween.tween_interval(_bubble.fade_seconds + pause_seconds)
	_tween.tween_callback(_finish.bind(line.words))


func _finish(line: String) -> void:
	_tween = null
	said.emit(line)
	# A listener may have hushed them, or begun something new.
	if _tween == null and not _saying.is_empty():
		_next()


# The nearest body this marker belongs to (a crewmate's), if any.
func _own_body() -> CollisionObject3D:
	var node: Node = get_parent()
	while node != null:
		if node is CollisionObject3D:
			return node as CollisionObject3D
		node = node.get_parent()
	return null
