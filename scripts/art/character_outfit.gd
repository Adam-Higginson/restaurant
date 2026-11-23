@tool
class_name CharacterOutfit
extends Resource
## What a character wears, slot by slot (#168): the start of the outfit and
## armour system. Each slot holds one piece, a model bound to the character's
## own armature (made by tools/meshy/fit_layer.py), and can be changed on its
## own. An empty slot wears nothing there.
##
## Put one in a [member ThirdPartyModel.outfit]: the pieces are put on the
## character's skeleton when its model loads, so they follow every animation.

## The shirt, tunic or chest armour.
@export_file("*.glb", "*.gltf") var top: String = "":
	set(value):
		top = value
		emit_changed()
## Trousers (and the belt).
@export_file("*.glb", "*.gltf") var legs: String = "":
	set(value):
		legs = value
		emit_changed()
## Boots or shoes.
@export_file("*.glb", "*.gltf") var feet: String = "":
	set(value):
		feet = value
		emit_changed()


## The names of the body bones under clothing, by what's worn, so the body
## there isn't drawn and can't poke through.
func hidden_bones() -> PackedStringArray:
	var hidden: PackedStringArray = []
	var worn: Dictionary[StringName, String] = pieces()
	for slot: StringName in worn:
		hidden.append_array(covers(slot))
	if worn.has(&"legs") and worn.has(&"feet"):
		# The shins: half under the trousers, half in the boots.
		hidden.append_array(PackedStringArray(["LeftLeg", "RightLeg"]))
	return hidden


## The body bones a slot's piece covers. The chest stays: an open collar
## shows skin.
static func covers(slot: StringName) -> PackedStringArray:
	match slot:
		&"top":
			return PackedStringArray()
		&"legs":
			return PackedStringArray(["Hips", "LeftUpLeg", "RightUpLeg"])
		&"feet":
			return PackedStringArray(["LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"])
	return PackedStringArray()


## Every slot with a piece in it, slot name to file, in the order they go on.
func pieces() -> Dictionary[StringName, String]:
	var worn: Dictionary[StringName, String] = {}
	for slot: StringName in [&"legs", &"feet", &"top"]:
		var path: String = get(slot)
		if not path.is_empty():
			worn[slot] = path
	return worn
