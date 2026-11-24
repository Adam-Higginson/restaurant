class_name Stage
extends CanvasLayer
## Something shown over the game for part of a cutscene: a set of its own
## (the dark water you sink through, drawn in a [SubViewport] with a 3D
## world to itself) or simply words (the title). A script brings one up
## with [code]@stage underwater[/code] and puts it away with
## [code]@stage off[/code]; see [StageCues].
##
## Its first child must be a [Control] holding everything it shows, which is
## what fades. While closed, nothing in it runs or is drawn.

## Emitted when the stage has been brought up.
signal opened
## Emitted when it's been put away.
signal closed

## The group every stage joins, so [StageCues] can find one by name.
const GROUP: StringName = &"stages"

## How long it takes to fade up and away, in seconds. 0 is at once.
@export var fade_seconds: float = 0.0
## Whether it hides the whole game behind it. If so the game's own 3D world
## isn't drawn while it's up, so the picture isn't paid for twice. A stage
## that fades up over the game (the Grave of the Lanterns) lets the game go
## on being drawn until it's all the way up, so one dissolves into the other.
@export var covers_world: bool = false

## Whether the stage is up.
var is_open: bool:
	get:
		return _open

var _open: bool = false
var _tween: Tween = null

@onready var _content: Control = get_child(0) as Control


func _ready() -> void:
	add_to_group(GROUP)
	_put_away()


func _exit_tree() -> void:
	if _open and covers_world:
		get_viewport().disable_3d = false


## Brings the stage up. With [param at_once] it skips the fade.
func open(at_once: bool = false) -> void:
	if _open:
		return
	_open = true
	show()
	process_mode = Node.PROCESS_MODE_INHERIT
	_kill_tween()
	if at_once or fade_seconds <= 0.0:
		_content.modulate.a = 1.0
		_cover_world()
	else:
		_content.modulate.a = 0.0
		_tween = create_tween()
		_tween.tween_property(_content, "modulate:a", 1.0, fade_seconds)
		_tween.tween_callback(_cover_world)
	opened.emit()


## Puts the stage away. With [param at_once] it skips the fade.
func close(at_once: bool = false) -> void:
	if not _open:
		return
	_open = false
	if covers_world:
		get_viewport().disable_3d = false
	_kill_tween()
	if at_once or fade_seconds <= 0.0:
		_put_away()
	else:
		_tween = create_tween()
		_tween.tween_property(_content, "modulate:a", 0.0, fade_seconds)
		_tween.tween_callback(_put_away)
	closed.emit()


# Once it's all the way up, the game behind it needn't be drawn.
func _cover_world() -> void:
	if _open and covers_world:
		get_viewport().disable_3d = true


func _put_away() -> void:
	hide()
	# Nothing inside runs while it's away: no particles, no clips.
	process_mode = Node.PROCESS_MODE_DISABLED


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
