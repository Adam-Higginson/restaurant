class_name LightningLight
extends DirectionalLight3D
## The lightning's light on the world: a cold, hard light from the storm that
## shows the whole ship for an instant, every rope of the rigging thrown in
## sharp shadow across the deck. [Lightning] tells it how bright the flash is,
## and it's switched off between flashes, so it costs nothing in the dark.

## How bright it is at the brightest moment of a flash.
@export var peak_energy: float = 3.0


func _ready() -> void:
	add_to_group(Lightning.LIT_GROUP)
	set_lightning(0.0)


## How bright the flash is now: 0 dark, 1 the brightest moment.
func set_lightning(brightness: float) -> void:
	light_energy = clampf(brightness, 0.0, 1.0) * peak_energy
	visible = brightness > 0.001
