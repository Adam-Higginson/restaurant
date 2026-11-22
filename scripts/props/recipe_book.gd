class_name RecipeBook
extends Node3D
## The galley's recipe book, open on the crew table. Read it (Interact) and
## its pages come up one after another on the card: each dish the galley
## knows, and how to make it.

@onready var _reach: Interactable3D = $Reach


func _ready() -> void:
	_reach.interacted.connect(func(_player: Player3D) -> void: read())
	_reach.describe_interact = func(_player: Player3D) -> String: return "Read the recipe book"


## Shows every recipe, a page each. Returns how many pages it showed.
func read() -> int:
	var card: MemoryCard = get_tree().get_first_node_in_group(&"memory_card") as MemoryCard
	if card == null:
		return 0
	var recipes: Array[Recipe] = Catalog.load_default().recipes
	for recipe: Recipe in recipes:
		card.show_card(recipe.title, recipe.steps)
	return recipes.size()
