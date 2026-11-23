extends GameTestSuite
## Tests that the models of food and tools are fired in the Kiln like the
## props (#152): an item or tool with a model and a look has a Kiln job,
## fitted to its own size, and the Kiln's catalog finds it among the data. A
## model kept as made (Meshy's, with no look) is never fired.

const LOOK: ArtLook = preload("res://data/art/looks/prop.tres")
const KNIFE: HandTool = preload("res://data/tools/chefs_knife.tres")


func test_an_item_with_a_model_and_a_look_is_fired_at_its_own_size() -> void:
	var item: Item = Item.new()
	item.model_path = "res://assets/third_party/kaykit_restaurant/Assets/gltf/food_ingredient_tomato.gltf"
	item.model_look = LOOK
	item.model_size = Vector3(0.3, 0.3, 0.3)

	var job: KilnJob = item.kiln_job()

	assert_object(job).is_not_null()
	assert_object(job.fit_size).is_equal(Vector3(0.3, 0.3, 0.3))


func test_an_item_kept_as_made_is_never_fired() -> void:
	var item: Item = Item.new()
	item.model_path = "res://assets/third_party/meshy/herring/model/model.glb"

	assert_object(item.kiln_job()).is_null()


func test_the_knife_is_fired_for_holding_up() -> void:
	assert_object(KNIFE.kiln_job()).is_not_null()


func test_the_kiln_finds_the_models_of_the_food() -> void:
	var jobs: Array[KilnJob] = KilnCatalog.jobs_in_resource("res://data/items/tomato.tres")

	assert_array(jobs).has_size(1)


func test_the_kiln_leaves_meshy_food_alone() -> void:
	var jobs: Array[KilnJob] = KilnCatalog.jobs_in_resource("res://data/items/herring.tres")

	assert_array(jobs).is_empty()
