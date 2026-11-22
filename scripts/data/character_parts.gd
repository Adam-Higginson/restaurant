class_name CharacterParts
extends Resource
## The pack files one look of the player is built from, all on the same
## Quaternius humanoid skeleton: an outfit, the head off a base character's
## body (the outfits leave the head bare), hair and eyebrows.
##
## The files live in the gitignored assets/third_party/, so these are paths,
## not loaded resources: a fresh clone without them falls back to the greybox.
## [CharacterModel] puts the parts together.

## The outfit: clothes, hands and boots, rigged.
@export_file("*.gltf", "*.glb") var outfit: String = ""
## The base character whose head is used. Only the head and neck are kept.
@export_file("*.gltf", "*.glb") var head_from: String = ""
## The hairstyle, rigged to the head bone.
@export_file("*.gltf", "*.glb") var hair: String = ""
## The eyebrows, rigged to the head bone.
@export_file("*.gltf", "*.glb") var eyebrows: String = ""
## The hair and eyebrows' colour (their texture is grey, for tinting).
@export var hair_colour: Color = Color(0.45, 0.28, 0.16)


## Every file this look needs. It's only built if all of them are there.
func files() -> PackedStringArray:
	var all: PackedStringArray = [outfit, head_from]
	for optional: String in [hair, eyebrows]:
		if not optional.is_empty():
			all.append(optional)
	return all


## Whether every file this look needs is there.
func is_complete() -> bool:
	for path: String in files():
		if path.is_empty() or not ResourceLoader.exists(path):
			return false
	return true
