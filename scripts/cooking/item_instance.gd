class_name ItemInstance
extends RefCounted
## One physical thing in the world: this particular tomato. Points at its shared
## [Item] definition and holds what's different about this one, its quality.

const MIN_QUALITY: int = 1
const MAX_QUALITY: int = 3

var item: Item
## From 1 (normal) to 3. See the GDD's Quality section.
var quality: int = MIN_QUALITY


func _init(source: Item, start_quality: int = MIN_QUALITY) -> void:
	item = source
	quality = clampi(start_quality, MIN_QUALITY, MAX_QUALITY)
