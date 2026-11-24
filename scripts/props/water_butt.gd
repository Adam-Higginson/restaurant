class_name WaterButt
extends Node3D
## The open water butt on deck, brimming with rain. Holding a saucepan (or
## any vessel with room), Interact to fill it with rainwater, for boiling
## below. The storm keeps it full.
##
## Nothing says the soup's water comes from here (the first quest's quiet
## puzzle, #158): filling something sets the flag [constant FETCHED_FLAG], so
## the captain stops hinting.

## The story flag set the first time water is fetched from here.
const FETCHED_FLAG: StringName = &"fetched_water"

## What it gives.
@export var water: Item
## A loop of rain drumming into it, heard only close by: the one tell, for
## anyone listening, of where the ship's water comes from. Third-party and
## gitignored; without it the butt is silent.
@export_file("*.ogg", "*.wav") var drumming_path: String = \
		"res://assets/third_party/audio/rain_window.ogg"
## How loud the drumming is in a full storm, in decibels. The recording is
## loud, and it should only be noticed standing by the butt.
@export var drumming_db: float = -12.0

var _drumming: AudioStreamPlayer3D = null
var _weather: Weather = null

@onready var _reach: Interactable3D = $Reach


func _ready() -> void:
	_reach.interacted.connect(func(player: Player3D) -> void: fill(player.arms))
	_reach.describe_interact = func(player: Player3D) -> String: return prompt(player.arms)
	_start_drumming()


func _process(_delta: float) -> void:
	if _drumming == null:
		return
	if not is_instance_valid(_weather):
		_weather = get_tree().get_first_node_in_group(Weather.GROUP) as Weather
	var intensity: float = _weather.intensity if is_instance_valid(_weather) else 1.0
	_drumming.volume_db = drumming_db + linear_to_db(maxf(intensity, 0.001))


## Whether [param arms] hold something it could pour water into.
func can_fill(arms: Arms) -> bool:
	var held: ItemInstance = arms.top()
	return water != null and held != null and held.is_vessel() \
			and not held.item.carried_whole and held.contents.room() > 0


## Pours rainwater into the held vessel. Returns whether it did.
func fill(arms: Arms) -> bool:
	if not can_fill(arms):
		return false
	if not arms.top().contents.add_item(ItemInstance.new(water)):
		return false
	Game.dialogue.set_flag(FETCHED_FLAG)
	return true


## What Interact would do, for the HUD: "Fill Saucepan with rainwater", or "".
func prompt(arms: Arms) -> String:
	if not can_fill(arms):
		return ""
	return "Fill %s with rainwater" % arms.top().item.display_name


## Whether the rain can be heard drumming into it.
func is_drumming() -> bool:
	return _drumming != null and _drumming.playing


func _start_drumming() -> void:
	if not Ambience.has_sound(drumming_path):
		return
	var stream: AudioStream = load(drumming_path) as AudioStream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_drumming = AudioStreamPlayer3D.new()
	_drumming.name = "Drumming"
	_drumming.stream = stream
	_drumming.bus = Ambience.BUS
	_drumming.unit_size = 1.0
	_drumming.max_distance = 6.0
	_drumming.volume_db = drumming_db
	add_child(_drumming)
	_drumming.play()
