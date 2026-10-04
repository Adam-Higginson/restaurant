extends StaticBody2D
## Placeholder behaviour for props until they get real gameplay: sets the
## shape's colour and flashes briefly when used.

const FLASH_COLOR: Color = Color(1.8, 1.8, 1.8, 1)
const FLASH_SECONDS: float = 0.15

@export var color: Color = Color(1, 1, 1, 1)

@onready var _body: Polygon2D = $Body
@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_body.color = color
	_interactable.interacted.connect(_on_interacted)


func _on_interacted(_player: Player) -> void:
	modulate = FLASH_COLOR
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), FLASH_SECONDS)
