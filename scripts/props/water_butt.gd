class_name WaterButt
extends Node3D
## The open water butt on deck, brimming with rain. Holding a pot (or any
## vessel with room), Use (left click) dips it in: the hero stoops, water
## splashes, and the pot comes up holding one lot of rainwater, for boiling
## below. A pot only ever holds one lot (#207). Use with a pot of nothing but
## water (cold or boiling) pours it back. The storm keeps it full.
##
## Nothing says the soup's water comes from here (the first quest's quiet
## puzzle, #158): filling something sets the flag [constant FETCHED_FLAG], so
## the captain stops hinting.

## The story flag set the first time water is fetched from here.
const FETCHED_FLAG: StringName = &"fetched_water"

## What it gives.
@export var water: Item
## The water already boiled: like the cold, a pot can't take a second lot,
## and it can be poured back.
@export var boiled: Item = preload("res://data/items/boiling_water.tres")
## How long the hero stoops to dip or pour, in seconds. They stand still.
@export var dip_seconds: float = 0.9
## The splash of dipping a pot in, and the optional sound of pouring it back.
@export_file("*.ogg", "*.wav") var dip_sound_path: String = \
		"res://assets/audio/water/pot_dip.wav"
@export_file("*.ogg", "*.wav") var pour_sound_path: String = \
		"res://assets/third_party/audio/water_pour.ogg"
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
	_reach.used.connect(_on_used)
	_reach.describe_use = func(player: Player3D) -> String: return prompt(player.arms)
	_start_drumming()


func _process(_delta: float) -> void:
	if _drumming == null:
		return
	if not is_instance_valid(_weather):
		_weather = get_tree().get_first_node_in_group(Weather.GROUP) as Weather
	var intensity: float = _weather.intensity if is_instance_valid(_weather) else 1.0
	_drumming.volume_db = drumming_db + linear_to_db(maxf(intensity, 0.001))


## Whether [param arms] hold something it could pour water into: a vessel
## with room that holds no water yet.
func can_fill(arms: Arms) -> bool:
	var held: ItemInstance = arms.top()
	return water != null and held != null and held.is_vessel() \
			and not held.item.carried_whole and held.contents.room() > 0 \
			and _water_in(held).is_empty()


## Whether [param arms] hold a vessel of water and nothing else, to pour back.
func can_pour(arms: Arms) -> bool:
	var held: ItemInstance = arms.top()
	if held == null or not held.is_vessel():
		return false
	var water_here: Array[ItemInstance] = _water_in(held)
	return not water_here.is_empty() \
			and water_here.size() == held.contents.get_contents().size()


## Pours rainwater into the held vessel. Returns whether it did.
func fill(arms: Arms) -> bool:
	if not can_fill(arms):
		return false
	if not arms.top().contents.add_item(ItemInstance.new(water)):
		return false
	Game.dialogue.set_flag(FETCHED_FLAG)
	return true


## Pours the held vessel's water back into the butt. Returns whether it did.
func pour(arms: Arms) -> bool:
	if not can_pour(arms):
		return false
	var contents: VesselContents = arms.top().contents
	for item: ItemInstance in _water_in(arms.top()):
		contents.remove_item(item)
	return true


## What Use would do, for the HUD: "Fill Saucepan with rainwater", "Pour out
## the water", or "".
func prompt(arms: Arms) -> String:
	if can_fill(arms):
		return "Fill %s with rainwater" % arms.top().item.display_name
	if can_pour(arms):
		return "Pour out the water"
	return ""


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


# The water in [param vessel]: rainwater or boiling water.
func _water_in(vessel: ItemInstance) -> Array[ItemInstance]:
	var found: Array[ItemInstance] = []
	for item: ItemInstance in vessel.contents.get_contents():
		if item.item == water or item.item == boiled:
			found.append(item)
	return found


# Use: dip the pot in, or pour it back, and show it: the hero faces the butt
# and stoops, standing still while they do, and the water splashes.
func _on_used(player: Player3D) -> void:
	var dipping: bool = can_fill(player.arms)
	if not player.controls_enabled or (not dipping and not can_pour(player.arms)):
		return
	var vessel: ItemInstance = player.arms.top()
	player.face_towards(global_position)
	var model: CharacterModel = player.get_node_or_null("Model/Character") as CharacterModel
	if model != null:
		model.act(&"Farm_Harvest" if dipping else &"Farm_Watering", 0.0, 0.0, dip_seconds,
				CharacterModel.Pose.IDLE)
	_splash()
	_play_once(dip_sound_path if dipping else pour_sound_path)
	player.controls_enabled = false
	var elapsed: float = 0.0
	while is_instance_valid(player) and elapsed < dip_seconds \
			and player.arms.top() == vessel:
		if dipping:
			player.fill_progress = elapsed / dip_seconds
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	if not is_instance_valid(player):
		return
	player.fill_progress = -1.0
	if elapsed >= dip_seconds and player.arms.top() == vessel:
		if dipping:
			fill(player.arms)
		else:
			pour(player.arms)
	player.controls_enabled = true


# A burst of droplets off the water's surface.
func _splash() -> void:
	var drops: CPUParticles3D = CPUParticles3D.new()
	drops.name = "Splash"
	drops.one_shot = true
	drops.explosiveness = 0.9
	drops.amount = 24
	drops.lifetime = 0.7
	drops.direction = Vector3.UP
	drops.spread = 35.0
	drops.initial_velocity_min = 1.2
	drops.initial_velocity_max = 2.2
	drops.gravity = Vector3(0.0, -9.0, 0.0)
	drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	drops.emission_sphere_radius = 0.2
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.02
	mesh.height = 0.04
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.75, 0.88, 1.0, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.1
	mesh.material = material
	drops.mesh = mesh
	var surface: Node3D = get_node_or_null("Surface") as Node3D
	drops.position = surface.position if surface != null else Vector3.UP
	add_child(drops)
	drops.emitting = true
	drops.finished.connect(drops.queue_free)


func _play_once(path: String) -> void:
	if not Ambience.has_sound(path):
		return
	var sound: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	sound.stream = load(path) as AudioStream
	sound.unit_size = 2.0
	add_child(sound)
	sound.play()
	sound.finished.connect(sound.queue_free)
