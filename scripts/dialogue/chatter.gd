class_name Chatter
extends Node
## The ship's chatter: now and then, somebody near you says something in
## passing, or two of the crew have a little exchange, in speech bubbles you
## overhear. What they say is in the files of remarks named in [member files]
## (see [Remark]); a [RemarkPicker] chooses which.
##
## One remark at a time, with a quiet gap of [member gap_min] to
## [member gap_max] seconds between. Only people within [member earshot] of
## you, with no wall between, chat; nobody does while you're in a proper
## [Conversation] (one starting cuts the chatter off) or can't move (asleep,
## or the opening's title). It never touches your controls or the camera.

## Emitted when a remark begins.
signal remark_started(remark: Remark)
## Emitted when it's over, whether it finished or was cut off.
signal remark_finished(remark: Remark)

## The group the chatter is in, so the lantern can hush it (see [method hush_all]).
const GROUP: StringName = &"chatter"

## Who's listening: the player. Found by group if unset.
@export var player: Node3D
## The files of remarks to chat from, in [code]data/dialogue[/code].
@export var files: Array[StringName] = [&"ambient"]
## How near you must be to somebody to overhear them, in metres.
@export var earshot: float = 9.0
## How near everyone in an exchange must be to each other, in metres.
@export var near: float = 5.0
## The first remark comes between these many seconds after the scene starts.
@export var first_wait_min: float = 10.0
@export var first_wait_max: float = 20.0
## After a remark, the next comes between these many seconds later.
@export var gap_min: float = 25.0
@export var gap_max: float = 60.0
## When there's nothing to say, how long to wait before looking again.
@export var retry_seconds: float = 4.0

## Shuffles the waits and the picks. Made when the chatter's ready, unless a
## test has given it one with a fixed seed first.
var rng: RandomNumberGenerator = null
## The remarks to chat from: read from [member files] when the chatter's
## ready, unless a test has given it some first.
var remarks: Array[Remark] = []

## The remark playing, or null.
var playing: Remark:
	get:
		return _playback.remark

## Seconds until the chatter next looks for something to say.
var wait_left: float:
	get:
		return _wait

var _picker: RemarkPicker = null
var _playback: RemarkPlayback = RemarkPlayback.new()
var _started: Remark = null
## Seconds since the chatter began, for cooldowns.
var _clock: float = 0.0
var _wait: float = 0.0
var _conversation: Conversation = null


func _ready() -> void:
	add_to_group(GROUP)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	_picker = RemarkPicker.new(rng)
	_picker.near = near
	if remarks.is_empty():
		for file: StringName in files:
			remarks.append_array(DialogueLibrary.remarks(file))
	_wait = rng.randf_range(first_wait_min, first_wait_max)
	_playback.finished.connect(_on_finished)
	# The conversation may be ready after us.
	_find_conversation.call_deferred()


func _process(delta: float) -> void:
	_clock += delta
	if _is_talking():
		hush()
		return
	if _playback.is_playing():
		return
	_wait -= delta
	if _wait > 0.0:
		return
	if not chat():
		_wait = retry_seconds


## Starts a remark now, if there's one to say. Returns whether one began.
func chat() -> bool:
	if _is_talking() or _playback.is_playing() or not _can_listen():
		return false
	var speakers: Dictionary[StringName, Speaker] = audible()
	if speakers.is_empty():
		return false
	var places: Dictionary[StringName, Vector3] = {}
	for who: StringName in speakers:
		# Somebody nearby is already talking (the lantern): let them finish.
		if speakers[who].is_busy():
			return false
		places[who] = speakers[who].global_position
	var remark: Remark = _picker.pick(remarks, places, Game.dialogue, _clock)
	if remark == null:
		return false
	_picker.said(remark, _clock)
	_started = remark
	if not _playback.start(remark, speakers, Game.dialogue):
		return false
	remark_started.emit(remark)
	return true


## Cuts off the remark playing, if any.
func hush() -> void:
	_playback.stop()


## Everybody you could overhear: within [member earshot], with no wall
## between, by [member Speaker.who].
func audible() -> Dictionary[StringName, Speaker]:
	var found: Dictionary[StringName, Speaker] = {}
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group(Player3D.GROUP) as Node3D
	if not is_instance_valid(player):
		return found
	var eye: Vector3 = Speaker.eye_of(player)
	for node: Node in get_tree().get_nodes_in_group(Speaker.GROUP):
		var speaker: Speaker = node as Speaker
		if speaker == null or speaker.who == &"":
			continue
		if speaker.global_position.distance_to(eye) > earshot:
			continue
		speaker.listener = player
		if speaker.in_sight_of(eye):
			found[speaker.who] = speaker
	return found


## Cuts off any chatter in [param tree]: somebody has something to say that
## matters more.
static func hush_all(tree: SceneTree) -> void:
	tree.call_group(GROUP, &"hush")


func _on_finished() -> void:
	_wait = rng.randf_range(gap_min, gap_max)
	remark_finished.emit(_started)


# Whether the player's about and awake: not asleep or watching a title.
func _can_listen() -> bool:
	var listener: Player3D = player as Player3D
	return listener == null or listener.controls_enabled


func _is_talking() -> bool:
	return is_instance_valid(_conversation) and _conversation.talking != &""


func _find_conversation() -> void:
	_conversation = Conversation.find(self)
	if _conversation != null:
		_conversation.started.connect(func(_tree_id: StringName) -> void: hush())
