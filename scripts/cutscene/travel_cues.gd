class_name TravelCues
extends CueHandler
## Going somewhere else in the world (#187). [code]@travel cove[/code] says
## where the game goes when the cutscene ends: once it's over, the scene
## changes to that place's. Put it last, after a fade out, so the change
## happens in the dark.

## Emitted when the cutscene that named a place ends, as the game goes there.
signal travelling(place: StringName)

## The places a script can name, and the scene each one is.
@export var places: Dictionary[StringName, String] = {
	&"cove": "res://scenes/prototype/islands/cove.tscn",
}

## Whether to really change scene. Tests turn it off and hear
## [signal travelling].
@export var change_scene: bool = true

## Where the cutscene playing now said to go, or empty.
var destination: StringName = &""


func cues() -> Array[StringName]:
	return [&"travel"]


## The scene file for [param place], or "" if there's no such place.
func scene_of(place: StringName) -> String:
	return places.get(place, "")


func _perform(_cue: StringName, args: PackedStringArray) -> void:
	var place: StringName = StringName(args[0])
	if scene_of(place) == "":
		warn("nowhere called '%s' to travel to (the places are %s)"
				% [place, ", ".join(PackedStringArray(places.keys()))])
		return
	destination = place


func _on_ended(_tree_id: StringName) -> void:
	if destination == &"":
		return
	var place: StringName = destination
	destination = &""
	travelling.emit(place)
	if change_scene:
		# After everything else has heard the cutscene end.
		get_tree().change_scene_to_file.call_deferred(scene_of(place))
