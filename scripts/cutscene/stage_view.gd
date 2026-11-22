class_name StageView
extends Control
## Shows a 3D set of its own, filling the screen: the [code]World[/code]
## child is a [SubViewport] (an off-screen screen with a 3D world to
## itself), and the [code]Picture[/code] child shows what it draws. Put it
## as the first child of a [Stage].
##
## The set is drawn at the window's full size, like the rest of the game's
## 3D, and only while the stage is up.

@onready var _world: SubViewport = $World
@onready var _picture: TextureRect = $Picture


func _ready() -> void:
	_picture.texture = _world.get_texture()
	get_window().size_changed.connect(_fit)
	_fit()
	var stage: Stage = get_parent() as Stage
	if stage != null:
		stage.opened.connect(_set_drawing.bind(true))
		stage.closed.connect(_set_drawing.bind(false))
		_set_drawing(stage.is_open)


func _fit() -> void:
	_world.size = get_window().size


func _set_drawing(drawing: bool) -> void:
	_world.render_target_update_mode = SubViewport.UPDATE_ALWAYS if drawing \
			else SubViewport.UPDATE_DISABLED
