@tool
class_name ArtLook
extends Resource
## How the Kiln fires a model into our N64 look, and how the fired model is
## drawn: a preset such as "prop", "creature" or "character".
##
## The Kiln (tools/kiln/fire.py, run in Blender) crunches a pack model down to
## [member triangles], gives it a new small texture at about
## [member pixels_per_metre] at the size it's drawn in the game, and paints
## the original's colours (and soft shading in its creases) onto it. Presets
## live in data/art/looks/; a node can use its own copy to override one.

## The most triangles the fired model may have. Models already under it are
## only tidied (welded and flattened), never made finer.
@export_range(4, 20000) var triangles: int = 300
## Texture pixels per metre of surface, at the size the model is drawn.
## The N64 recipe is about 64.
@export_range(8.0, 512.0) var pixels_per_metre: float = 64.0
## The biggest the texture may get, in pixels across (and down), however big
## the model: it keeps very large models from needing a huge texture.
@export_range(8, 1024) var max_texture: int = 128
## Neighbouring faces this close to flat (in degrees) merge into one big flat
## face before the crunch: boxy and confident, not bevelled. 0 keeps them.
@export_range(0.0, 45.0) var flatten_degrees: float = 3.0
## How much the creases and the spaces between parts are darkened in the
## texture, as N64 artists painted shading in: 0 none, 1 fully.
@export_range(0.0, 1.0) var creases: float = 0.4
## How strongly each texture pixel is made a little lighter or darker at
## random: the busy grain N64 surfaces had, for packs painted in flat colour.
## 0 for painted textures, which have their own.
@export_range(0.0, 0.5) var grain: float = 0.0
## Crunch both sides alike (left and right of the model), so a character's
## or creature's face and body stay even.
@export var symmetric: bool = false
## How strongly open edges (a neckline, where a head meets a collar) are kept
## in place by the crunch, so parts that meet still meet.
@export_range(0.0, 8.0) var protect_edges: float = 1.0

@export_group("Drawing")
## Light each face as one flat colour (faceted), like N64 props. Off shades
## smoothly across faces, like N64 characters.
@export var faceted: bool = true
## How rough the surface is: 1 is fully matte.
@export_range(0.0, 1.0) var roughness: float = 0.85
## How much shine highlights get: low for the N64's matte look.
@export_range(0.0, 1.0) var specular: float = 0.2


## The name fired files carry, so a model fired with two looks has two files:
## the preset's file name ("prop" for data/art/looks/prop.tres), or "custom"
## for a look made in a scene.
func tag() -> String:
	if not resource_name.is_empty():
		return resource_name.to_snake_case()
	if resource_path.is_empty() or resource_path.contains("::"):
		return "custom"
	return resource_path.get_file().get_basename()


## The settings the Kiln fires with, by the names fire.py reads.
func firing() -> Dictionary:
	return {
		"triangles": triangles,
		"pixels_per_metre": pixels_per_metre,
		"max_texture": max_texture,
		"flatten_degrees": flatten_degrees,
		"creases": creases,
		"grain": grain,
		"symmetric": symmetric,
		"protect_edges": protect_edges,
	}
