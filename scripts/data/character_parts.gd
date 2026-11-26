@tool
class_name CharacterParts
extends Resource
## The pack files one look of the player is built from, all on the same
## Quaternius humanoid skeleton: an outfit, the head off a base character's
## body (the outfits leave the head bare), hair and eyebrows.
##
## The files live in the gitignored assets/third_party/, so these are paths,
## not loaded resources: a fresh clone without them falls back to the greybox.
## [CharacterModel] puts the parts together.
##
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

@export_group("Whole character")
## A whole rigged character in one file (a Meshy model), used in place of
## the parts above when the file is there (#172). Its clothes are
## [member whole_outfit]; its moves are [member whole_clips].
@export_file("*.glb", "*.gltf") var whole: String = ""
## What the whole character wears.
@export var whole_outfit: CharacterOutfit
## The file each of the game's animations is played from, by the name the
## game asks for ("Idle", "Walk", "Sword_Regular_A"...). The files must be
## animations of this same character. A name that isn't here doesn't play.
@export var whole_clips: Dictionary[StringName, String] = {}
## Which clip in that file, for a file that holds several. Left out, the
## file's first clip.
@export var whole_clip_names: Dictionary[StringName, String] = {}
## How big the whole character is drawn, against its file.
@export var whole_scale: float = 1.0
## How long and thick its arms are, against its file (hands and all), and
## how big its hands are against those arms: a model's arms can come out too
## long and its hands too big.
@export_range(0.5, 1.5) var whole_arm_scale: float = 1.0
@export_range(0.5, 1.5) var whole_hand_scale: float = 1.0
## Where its eyes are, so shut they're drawn closed. None paints over
## whatever is eye-coloured, which only reads as shut on some faces.
@export var whole_closed_eyes: ClosedEyes = null

## Every file this look needs. It's only built if all of them are there.
func files() -> PackedStringArray:
	var all: PackedStringArray = [outfit, head_from]
	for optional: String in [hair, eyebrows]:
		if not optional.is_empty():
			all.append(optional)
	return all


## Whether this look is a whole character in one file, and the file is there.
func is_whole() -> bool:
	return not whole.is_empty() and ResourceLoader.exists(whole)


## Whether every file this look needs is there.
func is_complete() -> bool:
	if is_whole():
		return true
	for path: String in files():
		if path.is_empty() or not ResourceLoader.exists(path):
			return false
	return true
