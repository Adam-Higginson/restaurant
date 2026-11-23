class_name CrewAnimator
extends Node
## Plays a crewmate's animations from what's being said: an idle while nobody
## is talking with them, talking while they say a line, listening while
## someone else in the same conversation speaks (or you choose a reply), and
## the idle again when it's over. A cutscene is a conversation too, so the
## lines in one get the same.
##
## The animations come in the [member model]'s file, which lives in the
## gitignored assets/third_party/. Without it (CI, a fresh clone) the greybox
## shows and nothing plays, but [member mood] still follows the conversation.
##
## Which animations to play are names in that file, set on this node, so
## nothing here belongs to any one crewmate.

## What the crewmate is doing, each with its own animation.
enum Mood {
	## Nobody is talking with them.
	IDLE,
	## They're saying a line.
	TALK,
	## Someone else in their conversation is, or you're choosing a reply.
	LISTEN,
	## They're walking somewhere (#157).
	WALK,
}

## Who this animates: their lines are the ones they talk through.
@export var crewmate: Crewmate
## The model whose animations play. Its file brings them.
@export var model: ThirdPartyModel
## The animation for [enum Mood] IDLE.
@export var idle_animation: StringName = &""
## The animations for talking, taken in turn line by line, so a long talk
## doesn't loop the same gesture.
@export var talk_animations: Array[StringName] = []
## The animation for listening.
@export var listen_animation: StringName = &""
## Seconds to blend from one animation into the next.
@export var blend_seconds: float = 0.3
## Their walker, whose walking plays [member walk_animation].
@export var walker: CrewWalker
## The animation for walking.
@export var walk_animation: StringName = &""
## A file to borrow [member walk_animation] from, if the model's own file
## hasn't got it: another file made on the same skeleton (the heron's rig came
## with a walk in a file of its own). Its first animation is taken.
@export_file("*.glb") var walk_animation_from: String = ""

## What they're doing now.
var mood: Mood = Mood.IDLE:
	get:
		return _mood
## The animation for what they're doing now, or &"" if none is set for it.
var animation: StringName:
	get:
		return animation_for(_mood, _lines)

var _mood: Mood = Mood.IDLE
## How many lines they've said in the conversation under way.
var _lines: int = 0
## Whether their walker is moving them just now.
var _walking: bool = false
## What the conversation has them doing, whether or not they're walking.
var _talk_mood: Mood = Mood.IDLE
## Whether they're part of the conversation under way: it was begun with
## them, or they've said a line in it.
var _involved: bool = false
## The model's animation player, or null while the greybox shows.
var _animator: AnimationPlayer = null


func _ready() -> void:
	if model != null:
		model.dressed.connect(_on_dressed)
		_on_dressed(model.model != null)
	var conversation: Conversation = Conversation.find(self)
	if conversation != null:
		conversation.started.connect(func(_tree_id: StringName) -> void:
			hear_start(conversation.partner))
		conversation.line_said.connect(hear_line)
		conversation.choices_offered.connect(hear_choices)
		conversation.ended.connect(func(_tree_id: StringName) -> void: hear_end())
	if walker != null:
		walker.walking_changed.connect(hear_walking)


## The animation for [param for_mood], when they've said [param lines] lines
## so far: talking takes the [member talk_animations] in turn.
func animation_for(for_mood: Mood, lines: int) -> StringName:
	match for_mood:
		Mood.TALK:
			if talk_animations.is_empty():
				return &""
			return talk_animations[maxi(lines - 1, 0) % talk_animations.size()]
		Mood.LISTEN:
			return listen_animation
		Mood.WALK:
			return walk_animation
	return idle_animation


## Their walker has set off or stopped ([param moving]). While they're
## moving they walk, even through a line in a cutscene; stopped, they're back
## to what the conversation has them doing. (Talking with them stops their
## walker, so a conversation of their own is never walked through.)
func hear_walking(moving: bool) -> void:
	_walking = moving
	_show()


## A conversation has begun with [param partner] (null for a cutscene). If
## it's with them, they listen until they speak.
func hear_start(partner: Crewmate) -> void:
	_lines = 0
	_involved = partner != null and partner == crewmate
	if _involved:
		_set_mood(Mood.LISTEN)


## Somebody has started a line: [param speaker], or null for nobody in
## particular.
func hear_line(speaker: Person) -> void:
	if _is_them(speaker):
		_involved = true
		_lines += 1
		_set_mood(Mood.TALK)
	elif _involved:
		_set_mood(Mood.LISTEN)


## Replies are offered: if it's their conversation, they wait on your answer.
func hear_choices() -> void:
	if _involved:
		_set_mood(Mood.LISTEN)


## The conversation is over: back to what they were doing.
func hear_end() -> void:
	_involved = false
	_lines = 0
	_set_mood(Mood.IDLE)


func _is_them(speaker: Person) -> bool:
	return speaker != null and crewmate != null and crewmate.person != null \
			and speaker.id == crewmate.person.id


# What the conversation has them doing now: shown unless they're walking.
func _set_mood(to: Mood) -> void:
	_talk_mood = to
	_show()


func _show() -> void:
	_mood = Mood.WALK if _walking else _talk_mood
	_play(blend_seconds)


func _play(blend: float) -> void:
	var wanted: StringName = animation
	if _animator == null or wanted == &"" or not _animator.has_animation(wanted):
		return
	_animator.play(wanted, blend)


func _on_dressed(shown: bool) -> void:
	_animator = null
	if not shown or model == null or model.model == null:
		return
	var found: Array[Node] = model.model.find_children("*", "AnimationPlayer", true, false)
	if found.is_empty():
		return
	_animator = found[0] as AnimationPlayer
	_borrow_walk()
	# The file's animations play once; ours go round until something changes.
	var ours: Array[StringName] = talk_animations.duplicate()
	ours.append_array([idle_animation, listen_animation, walk_animation])
	for clip: StringName in ours:
		if _animator.has_animation(clip):
			_animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	_play(0.0)


# Adds the walk from [member walk_animation_from] to the model's animations,
# if it hasn't one of its own. The other file is on the same skeleton, so its
# tracks name the same bones.
func _borrow_walk() -> void:
	if walk_animation == &"" or walk_animation_from.is_empty() \
			or _animator.has_animation(walk_animation) \
			or not ResourceLoader.exists(walk_animation_from):
		return
	var source: PackedScene = load(walk_animation_from) as PackedScene
	if source == null:
		return
	var other: Node = source.instantiate()
	var players: Array[Node] = other.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		var their: AnimationPlayer = players[0] as AnimationPlayer
		var names: PackedStringArray = their.get_animation_list()
		if not names.is_empty():
			var walk: Animation = their.get_animation(names[0]).duplicate() as Animation
			var library: AnimationLibrary = _animator.get_animation_library(&"")
			if library != null:
				library.add_animation(walk_animation, walk)
	other.free()
