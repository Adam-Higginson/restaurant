class_name HomeWaters
extends Node3D
## The opening's first beat (#227): home waters at dusk. You start tied up at
## the jetty with the island behind you; your older sibling calls once from
## the lit window by the jetty, and you row out to the marker buoy while the
## lantern on the bow pole chatters. Coming alongside the buoy ends the beat
## ([signal reached_buoy]), which hands over to tending the buoy (#228).
##
## What the lantern says is in data/dialogue/home_waters.dlg, one section per
## moment. Some moments come with how far you've rowed (a fifth of the way,
## halfway, nearly there: [constant DISTANCE_CUES]); others as you pass
## landmarks (leaving the jetty, passing the chain, seeing the buoy). Each is
## said once, in the order it happened, and never over another line: a moment
## waits its turn until nobody is speaking.
##
## Soft edges: [KeepClear] markers stop you landing on the island or rowing
## through the buoy. Row far out and the fog closes in, and after a while the
## lantern nudges you back towards the buoy.
##
## Open scenes/prototype/intro/home_waters.tscn and press F6.

## Emitted once, when the boat first comes alongside the buoy.
signal reached_buoy
## Emitted when a moment's lines begin: [param moment] is its name in the
## dialogue file, or [constant SIBLING] for your sibling's call.
signal cue_played(moment: StringName)

## The file the lantern's lines are in.
const LINES: StringName = &"home_waters"
## The name [signal cue_played] gives your sibling's call.
const SIBLING: StringName = &"sibling"
## The moments that come with distance, and the share of the way to the buoy
## (0 at the jetty, 1 at the buoy) each comes at, in order.
const DISTANCE_CUES: Dictionary[StringName, float] = {
	&"out_quarter": 0.2,
	&"out_half": 0.5,
	&"out_most": 0.85,
}
## The moment said again and again (in turn) while you stay far out.
const TOO_FAR: StringName = &"too_far"

## The boat you row.
@export var boat: Rowboat
## The sea, kept centred under the boat.
@export var sea: Sea
## The marker buoy you row out to.
@export var buoy: Node3D
## The great chain, from the island's summit down into the sea by the buoy.
@export var chain: HangingChain
## The lantern's voice, on the bow pole.
@export var lantern: Speaker
## Your sibling's voice, at the lit window by the jetty.
@export var sibling: Speaker
## What your sibling calls.
@export var sibling_line: String = "Back by supper. I'm doing the fish stew."
## The middle of home waters: row further than [member far_radius] from here
## and you're out in the fog.
@export var home_centre: Node3D
## The invisible walls round the island and the buoy.
@export var walls: Array[KeepClear] = []
## The scene's environment, whose fog thickens far out.
@export var world: WorldEnvironment
## Shown when you reach the buoy, until #228 carries on from there.
@export var ending: Control

@export_group("Landmarks")
## How far from where you started you must row to have left the jetty, in metres.
@export var leave_distance: float = 8.0
## How near the chain you must pass, flat across the water, in metres.
@export var chain_near: float = 20.0
## How near the buoy must be to see it clearly, in metres.
@export var sight_distance: float = 55.0
## How near the buoy counts as alongside, in metres (from its middle).
@export var alongside_distance: float = 7.0

@export_group("Far out")
## How far from [member home_centre] home waters reach, in metres.
@export var far_radius: float = 170.0
## How far past that the fog takes to close in fully, in metres.
@export var fog_closing: float = 50.0
## How thick the fog gets fully out, as the environment's fog density.
@export var far_fog_density: float = 0.06
## Seconds out in the fog before the lantern says something.
@export var nudge_seconds: float = 8.0
## Seconds between his nudges if you stay out there.
@export var nudge_repeat: float = 20.0

## The moments said so far (and your sibling's call), in the order they began.
var played: Array[StringName] = []
## The moments waiting their turn, in order.
var waiting: Array[StringName] = []
## Whether you've come alongside the buoy.
var at_buoy: bool = false

var _start: Vector3 = Vector3.ZERO
var _start_distance: float = 1.0
var _home_fog: float = 0.0
## Seconds spent out in the fog since the last nudge.
var _far_seconds: float = 0.0
var _nudges: int = 0


func _ready() -> void:
	# Run after the boat has moved each tick, so the walls see where it went.
	process_physics_priority = 10
	RowingGreybox.clear_hull_cutout(sea)
	if world != null and world.environment != null:
		_home_fog = world.environment.fog_density
	if ending != null:
		ending.visible = false
	if boat != null:
		_start = boat.global_position
		if buoy != null:
			_start_distance = maxf(_flat_distance(_start, buoy.global_position), 1.0)
	if sibling != null:
		sibling.say(sibling_line)
		played.append(SIBLING)
		cue_played.emit(SIBLING)


func _process(_delta: float) -> void:
	RowingGreybox.centre_sea_under(sea, boat)


func _unhandled_input(event: InputEvent) -> void:
	# The mouse turns the camera only while it's captured: Esc frees it, and a
	# click captures it again (as in the rowing greybox).
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if boat == null:
		return
	for wall: KeepClear in walls:
		wall.hold_off(boat)
	notice(delta)
	play_next()


## Looks at where the boat is and queues whatever that calls for: the
## distance and landmark moments, the buoy, and the fog far out.
func notice(delta: float) -> void:
	if at_buoy:
		return
	var here: Vector3 = boat.global_position
	if _flat_distance(here, _start) > leave_distance:
		cue(&"left_jetty")
	var progress: float = progress_at(here)
	for moment: StringName in DISTANCE_CUES:
		if progress >= DISTANCE_CUES[moment]:
			cue(moment)
	if chain != null and chain_distance(here) < chain_near:
		cue(&"by_chain")
	if buoy != null:
		var to_buoy: float = _flat_distance(here, buoy.global_position)
		if to_buoy < sight_distance:
			cue(&"buoy_sighted")
		if to_buoy < alongside_distance:
			_arrive()
			return
	_watch_the_fog(here, delta)


## Queues [param moment] to be said when nobody's speaking. Each is said only
## once, except [constant TOO_FAR]. Returns whether it was queued.
func cue(moment: StringName) -> bool:
	if waiting.has(moment):
		return false
	if moment != TOO_FAR and played.has(moment):
		return false
	waiting.append(moment)
	return true


## Starts the next moment waiting, if nobody's speaking. Returns whether one
## began.
func play_next() -> bool:
	if waiting.is_empty() or is_anyone_speaking():
		return false
	var moment: StringName = waiting.pop_front()
	var lines: Array[DialogueStep] = lines_for(moment, _nudges)
	if moment == TOO_FAR:
		_nudges += 1
	played.append(moment)
	if lantern != null:
		for line: DialogueStep in lines:
			lantern.say(line.text, Speaker.style_for(line.tag))
	cue_played.emit(moment)
	return true


## Whether the lantern or your sibling is saying something.
func is_anyone_speaking() -> bool:
	return (lantern != null and lantern.is_busy()) or (sibling != null and sibling.is_busy())


## How far you are towards the buoy at [param spot]: 0 where you started, 1
## at the buoy, by how much nearer you are.
func progress_at(spot: Vector3) -> float:
	if buoy == null:
		return 0.0
	return clampf(1.0 - _flat_distance(spot, buoy.global_position) / _start_distance, 0.0, 1.0)


## How far [param spot] is from the chain, flat across the water, in metres.
func chain_distance(spot: Vector3) -> float:
	var top: Vector3 = chain.to_global(chain.top)
	var bottom: Vector3 = chain.to_global(chain.bottom)
	var flat: Vector2 = Vector2(spot.x, spot.z)
	var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(flat,
			Vector2(top.x, top.z), Vector2(bottom.x, bottom.z))
	return flat.distance_to(nearest)


## How far out in the fog [param spot] is, 0 (in home waters) to 1 (fully out).
func fog_at(spot: Vector3) -> float:
	if home_centre == null:
		return 0.0
	var past: float = _flat_distance(spot, home_centre.global_position) - far_radius
	return clampf(past / maxf(fog_closing, 0.01), 0.0, 1.0)


## The lines for [param moment]: its [code][on][/code] section in
## [constant LINES]. Where there are several sections for it, [param turn]
## picks which, in turn.
static func lines_for(moment: StringName, turn: int = 0) -> Array[DialogueStep]:
	var found: Array[Remark] = []
	for remark: Remark in DialogueLibrary.remarks(LINES):
		if remark.moment == moment:
			found.append(remark)
	if found.is_empty():
		push_warning("HomeWaters: nothing to say for '%s'" % moment)
		return []
	return RemarkPlayback.lines_of(found[turn % found.size()], Game.dialogue)


func _arrive() -> void:
	at_buoy = true
	# Let the boat glide to a stop alongside: #228 carries on from here.
	boat.controls_enabled = false
	cue(&"at_buoy")
	if ending != null:
		ending.visible = true
	reached_buoy.emit()


# Thickens the fog the further out you are, and has the lantern nudge you
# back after a while out there.
func _watch_the_fog(here: Vector3, delta: float) -> void:
	var out: float = fog_at(here)
	if world != null and world.environment != null:
		world.environment.fog_density = lerpf(_home_fog, far_fog_density, out)
	if out <= 0.0:
		_far_seconds = 0.0
		# Back in home waters: a nudge still waiting its turn is out of date.
		waiting.erase(TOO_FAR)
		return
	_far_seconds += delta
	var due: float = nudge_seconds if _nudges == 0 else nudge_repeat
	if _far_seconds >= due and cue(TOO_FAR):
		_far_seconds = 0.0


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
