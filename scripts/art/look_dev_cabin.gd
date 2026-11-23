class_name LookDevCabin
extends Node3D
## The look-dev cabin (#168): one wooden cabin, lit like the golden-hour
## reference, for trying the stylised look on our characters and props before
## it goes anywhere else. Open scenes/tools/look_dev_cabin.tscn and press F6.
##
## The buttons in the corner switch, while it runs:
## - the characters between stylised and as made ([method set_stylised]);
## - their outlines ([method set_outlined]);
## - the light between the golden cabin and plain studio light, which shows
##   the models as they come ([method set_golden]).
## The characters wear the shared style (data/art/styles/character.tres) in
## the saved scene, so tuning that file shows on them in the editor at once.
## While it runs, the buttons work on a copy of the style, so they never
## change the shared file, and nothing here changes any other scene.
##
## Run with [code]-- --capture=<folder>[/code] and it photographs every shot
## (the Marker3D nodes under Shots) in each treatment, saves the pictures
## there and quits. That's how the look is checked by eye.

## One way of drawing the cabin, photographed by --capture.
class Treatment:
	var name: String
	var stylised: bool
	var outlined: bool
	var golden: bool

	func _init(called: String, styled: bool, lined: bool, gold: bool) -> void:
		name = called
		stylised = styled
		outlined = lined
		golden = gold


## Frames to wait before each photograph, for the light shafts to settle.
const SETTLE_FRAMES: int = 45

## The stylised look put on the characters.
@export var style: CharacterStyle
## The characters' models, which the style is put on.
@export var characters: Array[ThirdPartyModel] = []
@export var world: WorldEnvironment
@export var sun: DirectionalLight3D
## The golden-hour cabin's environment, and plain studio light.
@export var golden: Environment
@export var plain: Environment
## Characters with no animator of their own: their model's first animation
## is played on a loop.
@export var posed: Array[ThirdPartyModel] = []
## The lanterns' lights, out in plain studio light.
@export var lamps: Array[Light3D] = []
@export_group("Sun")
@export var golden_sun_color: Color = Color(1.0, 0.82, 0.6)
@export var golden_sun_energy: float = 3.0
@export var plain_sun_color: Color = Color.WHITE
@export var plain_sun_energy: float = 1.2

## Whether the characters are drawn stylised.
var stylised: bool = true
## Whether the characters have outlines.
var outlined: bool = true
## Whether it's lit as the golden cabin (or plain studio light).
var golden_light: bool = true

var _capture_folder: String = ""

@onready var _camera: Camera3D = $Camera
@onready var _shots: Node3D = $Shots


func _ready() -> void:
	for option: String in OS.get_cmdline_user_args():
		if option.begins_with("--capture="):
			_capture_folder = option.trim_prefix("--capture=")
	if style != null:
		style = style.duplicate() as CharacterStyle
	for character: ThirdPartyModel in posed:
		if character != null:
			character.dressed.connect(_loop_first_animation.bind(character))
			_loop_first_animation(character.model != null, character)
	set_stylised(stylised)
	set_outlined(outlined)
	set_golden(golden_light)
	if _capture_folder.is_empty():
		_add_buttons()
	else:
		await _capture_all()
		get_tree().quit()


## Draws the characters stylised, or as made.
func set_stylised(on: bool) -> void:
	stylised = on
	for character: ThirdPartyModel in characters:
		if character != null:
			character.style = style if on else null


## Gives the stylised characters outlines, or not.
func set_outlined(on: bool) -> void:
	outlined = on
	if style != null:
		style.outline = on


## Lights the cabin at golden hour, or in plain studio light.
func set_golden(on: bool) -> void:
	golden_light = on
	if world != null:
		world.environment = golden if on else plain
	if sun != null:
		sun.light_color = golden_sun_color if on else plain_sun_color
		sun.light_energy = golden_sun_energy if on else plain_sun_energy
	for lamp: Light3D in lamps:
		if lamp != null:
			lamp.visible = on


func _loop_first_animation(shown: bool, character: ThirdPartyModel) -> void:
	if not shown:
		return
	var players: Array[Node] = character.model.find_children("*", "AnimationPlayer")
	if players.is_empty():
		return
	var player: AnimationPlayer = players[0] as AnimationPlayer
	var names: PackedStringArray = player.get_animation_list()
	if names.is_empty():
		return
	player.get_animation(names[0]).loop_mode = Animation.LOOP_LINEAR
	player.play(names[0])


func _add_buttons() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	var column: VBoxContainer = VBoxContainer.new()
	column.position = Vector2(16.0, 16.0)
	layer.add_child(column)
	column.add_child(_button("Stylised characters", stylised, set_stylised))
	column.add_child(_button("Outlines", outlined, set_outlined))
	column.add_child(_button("Golden cabin light", golden_light, set_golden))


func _button(label: String, on: bool, action: Callable) -> CheckButton:
	var button: CheckButton = CheckButton.new()
	button.text = label
	button.button_pressed = on
	button.toggled.connect(action)
	return button


func _capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(_capture_folder)
	var treatments: Array[Treatment] = [
		Treatment.new("plain_as_made", false, false, false),
		Treatment.new("golden_as_made", false, false, true),
		Treatment.new("golden_stylised", true, true, true),
		Treatment.new("golden_no_outline", true, false, true),
	]
	for treatment: Treatment in treatments:
		set_stylised(treatment.stylised)
		set_outlined(treatment.outlined)
		set_golden(treatment.golden)
		for shot: Node in _shots.get_children():
			var mark: Node3D = shot as Node3D
			if mark == null:
				continue
			_camera.global_transform = mark.global_transform
			for frame: int in SETTLE_FRAMES:
				await get_tree().process_frame
			var picture: Image = get_viewport().get_texture().get_image()
			picture.save_png("%s/%s_%s.png" % [_capture_folder, mark.name.to_snake_case(),
					treatment.name])
