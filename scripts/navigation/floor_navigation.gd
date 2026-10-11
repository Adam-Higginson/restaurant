class_name FloorNavigation
extends NavigationRegion2D
## The floor customers can walk on. Bakes its navigation polygon when the
## scene starts, cutting out the walls and furniture in the
## [constant SOURCE_GROUP] group, so the walkable area always matches the
## current layout.
##
## Debug > Visible Navigation shows the baked floor while the game runs.

## Nodes whose collision shapes (and their children's) block walking.
const SOURCE_GROUP: StringName = &"navigation_source"


func _ready() -> void:
	# On this thread, so customers have a floor from the first physics tick.
	bake_navigation_polygon(false)
