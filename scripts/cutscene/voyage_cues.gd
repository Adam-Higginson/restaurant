class_name VoyageCues
extends CueHandler
## Which voyage the title chose. [code]@continue_voyage[/code] says the player
## chose to carry on their saved voyage; the [Opening] loads it once the
## cutscene's over. Without it, the voyage is a new one.

## Whether this cutscene chose to carry on the saved voyage.
var continued: bool = false


func cues() -> Array[StringName]:
	return [&"continue_voyage"]


func _perform(_cue: StringName, _args: PackedStringArray) -> void:
	continued = true
