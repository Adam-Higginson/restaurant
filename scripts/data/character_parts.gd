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
## Each part can be fired in the Kiln (the Fire in Kiln button, or kiln.sh):
## the outfit, the head (cut from the body, with the eyebrows painted on as
## the N64 did) and the hair, each with its own [ArtLook]. Fired parts are
## drawn instead of the pack's, part by part, as soon as they're there.

## The bones the head is cut from the base character's body by.
const HEAD_BONES: PackedStringArray = ["Head", "neck_01"]
## The base characters' own eyebrows, left out: the parts bring their own.
const BASE_EYEBROWS: String = "Eyebrows"

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

@export_group("Kiln")
## How the outfit is fired.
@export var body_look: ArtLook
## How the head is fired.
@export var head_look: ArtLook
## How the hair is fired.
@export var hair_look: ArtLook
## How big the character is drawn, against its files, so its pixels come out
## the right size ([member CharacterModel.body_scale]).
@export var game_scale: float = 0.85
## Fires every part in the Kiln, in the background. The player shows them the
## next time the game runs.
@export_tool_button("Fire in Kiln", "Bake") var fire_button: Callable = fire_in_kiln


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


## The Kiln job for the outfit, or null without a look.
func outfit_job() -> KilnJob:
	if body_look == null:
		return null
	var job: KilnJob = KilnJob.new(outfit, body_look)
	job.scale = game_scale
	return job


## The Kiln job for the head: the head and neck cut from [member head_from],
## its eyes kept, with [member eyebrows] painted on in [member hair_colour].
## Null without a look.
func head_job() -> KilnJob:
	if head_look == null:
		return null
	var job: KilnJob = KilnJob.new(head_from, head_look)
	job.keep_bones = HEAD_BONES
	job.drop_meshes = [BASE_EYEBROWS]
	job.tints = [Color.WHITE]
	if not eyebrows.is_empty():
		job.sources.append(eyebrows)
		job.tints.append(hair_colour)
	job.scale = game_scale
	return job


## The Kiln job for the hair, in [member hair_colour]. Null without hair or a
## look.
func hair_job() -> KilnJob:
	if hair_look == null or hair.is_empty():
		return null
	var job: KilnJob = KilnJob.new(hair, hair_look)
	job.tints = [hair_colour]
	job.scale = game_scale
	return job


## Every part's Kiln job.
func jobs() -> Array[KilnJob]:
	var all: Array[KilnJob] = []
	for job: KilnJob in [outfit_job(), head_job(), hair_job()]:
		if job != null:
			all.append(job)
	return all


## Fires every part in the Kiln, in the background. Call it with
## [code]await[/code]. Returns how many came out fresh.
func fire_in_kiln() -> int:
	if not Kiln.has_blender():
		push_warning("No Blender at %s (set BLENDER to its path)." % Kiln.blender())
		return 0
	var fresh: int = await Kiln.fire_in_background(jobs())
	emit_changed()
	return fresh
