class_name CoveArrival
extends Node
## Coming into the cove at the end of the voyage, the Prologue's Scene 8
## (#187). When the voyage cutscene at sea ends it sets [constant
## ARRIVING_FLAG] and the game comes here; this sees the flag, starts the ship
## [member sail_from] away from her anchorage, and plays [member cutscene] while
## she sails in, slowing to a stop where she lies at anchor. You're on deck
## all the while, carried with her.
##
## Once it's over (or skipped) she's at anchor and you're at [member start],
## the island is reached ([constant ARRIVED_FLAG]), and the voyage is saved
## so carrying it on comes back here. Visiting the cove any other way (the
## editor, a saved voyage) she's simply at anchor.

## Emitted once you've arrived and the voyage is saved.
signal arrived

## Set by the voyage cutscene as you leave the sea: arrive with a cutscene.
const ARRIVING_FLAG: StringName = &"arriving"
## Set once you're here. The bunk stops sailing you on, and a saved voyage
## carries on here.
const ARRIVED_FLAG: StringName = Bedside.ARRIVED_FLAG

## The ship coming in. Where she is in the scene is where she anchors.
@export var ship: Ship
## You.
@export var player: Player3D
## Where you stand on deck as she comes in, and once she's anchored.
@export var start: Node3D
## The screen fade, black until the cutscene fades in.
@export var fade: ScreenFade
## The cutscene: a file in [code]data/dialogue[/code].
@export var cutscene: StringName = &"arrival"
## Where she starts from, measured from her anchorage, in metres.
@export var sail_from: Vector3 = Vector3(90, 0, 0)
## How long she takes to come in to her anchorage, in seconds.
@export var sail_seconds: float = 24.0

## Whether she's on her way in right now.
var is_sailing_in: bool:
	get:
		return _tween != null and _tween.is_running()

var _anchorage: Transform3D
var _begun: bool = false
var _tween: Tween = null


func _ready() -> void:
	if not is_arriving() or ship == null or player == null:
		return
	if fade != null:
		# Black from the first frame: the cutscene fades in.
		fade.cover_now()
	_arrive.call_deferred()


## Whether the game came here from the voyage, to arrive.
func is_arriving() -> bool:
	return Game.dialogue.is_set(ARRIVING_FLAG)


## Where she lies at anchor.
func anchorage() -> Transform3D:
	return _anchorage if _begun else ship.global_transform


func _arrive() -> void:
	_anchorage = ship.global_transform
	_begun = true
	Game.dialogue.clear(ARRIVING_FLAG)
	Game.dialogue.set_flag(ARRIVED_FLAG)
	var from: Vector3 = _anchorage.origin + sail_from
	ship.global_position = from
	ship.reset_physics_interpolation()
	# She's synced to physics, so set like this she only gets there on the
	# next physics step: stand on her deck once she has.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_stand_on_deck()
	# In physics steps, so the deck carries you as she moves. From and to
	# given outright: her position isn't read back until a step has passed.
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_method(_sail_to, from, _anchorage.origin, sail_seconds) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var conversation: Conversation = Conversation.find(self)
	if conversation != null and conversation.play(cutscene, player):
		if conversation.is_active():
			await conversation.ended
	elif fade != null:
		await fade.fade_in()
	await _settle()
	_save()
	arrived.emit()


func _sail_to(where: Vector3) -> void:
	if is_instance_valid(ship):
		ship.global_position = where


# At anchor, whatever happened on the way: skipped, she's put there.
func _settle() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if is_instance_valid(ship):
		ship.global_transform = _anchorage
		ship.reset_physics_interpolation()
		await get_tree().physics_frame
		await get_tree().physics_frame
	_stand_on_deck()


func _stand_on_deck() -> void:
	if is_instance_valid(player) and is_instance_valid(start):
		Island.stand_at(player, start)


# Arriving is a place to keep the voyage, as sleeping is.
func _save() -> void:
	var spirit: LanternSpirit = player.get_node_or_null("LanternSpirit") as LanternSpirit
	var warmth: float = spirit.warmth if spirit != null else 1.0
	SaveGame.write(SaveGame.capture(Game.memories, null, warmth, Game.dialogue, Game.look))
