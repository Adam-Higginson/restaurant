class_name Item
extends Resource
## Anything physical in the world: an ingredient, prepared food, a dish or a
## utensil. One .tres file per item under res://data/items/.
##
## Every state food can be in is its own item (tomato, sliced tomato, diced
## tomato), so only designed states exist. [Reaction]s turn items into others.

## Where food is kept. NONE for things that can't be stored: utensils, plates
## and liquids. PANTRY is only a container's kind, never an item's: a pantry
## takes any food that can be stored. New kinds go at the end, because the
## .tres files save them as numbers.
enum StorageKind { NONE, FRIDGE, CUPBOARD, PANTRY }
## How a vessel is drawn: flat (a board or plate), a bowl, a pan with a long
## handle, or a deep pot. New shapes go at the end (saved as numbers).
enum VesselShape { FLAT, BOWL, PAN, POT }

## Stable internal name (e.g. &"sliced_tomato"). Saves will refer to this, so don't change it.
@export var id: StringName = &""
@export var display_name: String = ""
## Placeholder colour until there's real art, and the greybox's colour
## while the real model isn't there.
@export var color: Color = Color.WHITE
## The item's model (#152): a file under res://assets/third_party/, fitted
## into [member model_size] (sitting on its base, centred). Without one, or
## on a fresh clone, it's drawn as a greybox in [member color].
@export_file("*.gltf", "*.glb") var model_path: String = ""
## How the Kiln fires [member model_path] (see [member ThirdPartyModel.look]).
## None draws it as made (a Meshy model).
@export var model_look: ArtLook = null
@export var model_size: Vector3 = Vector3(0.2, 0.2, 0.2)
## Multiplies the model's colours: a fillet's model browned for the fried
## dish, the herring's made greener for a mackerel.
@export var model_tint: Color = Color.WHITE
## Moves the fitted model, in metres: a pot or pan's model is centred with its
## handle, so it's slid along to put the bowl in the middle, where food goes.
@export var model_offset: Vector3 = Vector3.ZERO
## Turns the fitted model about the up axis, in degrees.
@export var model_yaw_degrees: float = 0.0
## Whether it's a liquid (water, soup): in a pot or bowl it's drawn as a
## surface filling it, not as a piece of food sitting in it (#207).
@export var liquid: bool = false
## How many food items fit in it, for vessels (a chopping board, a plate).
## 0 for everything else, including food.
@export var capacity: int = 0
## Whether pick up takes it whole with its food (a plate or bowl). Otherwise
## pick up takes its top food item, and the vessel itself only once it's empty
## (a chopping board or pan).
@export var carried_whole: bool = false
## Which container it can be put away in. See Storage in docs/GDD.md.
@export var storage: StorageKind = StorageKind.NONE
## For vessels, how it's drawn (see [ItemModel]).
@export var vessel_shape: VesselShape = VesselShape.FLAT
## For cookware: how long food's golden moment lasts in it, in seconds
## (see [GoldenMoment]). A better pan gives you longer to catch it.
@export var golden_window: float = 1.5
## For a pan you can parry with: how long it stays up after a press (the
## parry window), and how soon after it goes up a blow must land to be
## parried perfectly, in seconds. A better pan has longer ones (#152).
@export var parry_seconds: float = 0.3
@export var perfect_parry_seconds: float = 0.12


## The Kiln job for [member model_path], or null if it's never fired.
func kiln_job() -> KilnJob:
	if model_path.is_empty() or model_look == null:
		return null
	var job: KilnJob = KilnJob.new(model_path, model_look)
	job.fit_size = model_size
	return job


## Whether food can go in it. Vessels never go inside other vessels.
func is_vessel() -> bool:
	return capacity > 0
