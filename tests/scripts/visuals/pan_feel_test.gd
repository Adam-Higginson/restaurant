extends GameTestSuite
## Tests for how cooking over the hob feels (#152): it steams while it
## cooks, glows gold at its golden moment, and its bubble shows the cooking,
## "Now!" at the moment, and the dish with its stars once it's done. (How it
## looks isn't tested.)

const HOB_SCENE: String = "res://scenes/prototype/props/hob.tscn"


func test_it_steams_while_something_cooks() -> void:
	var setup: Array = await _frying(&"herring_fillet")
	var feel: PanFeel = setup[1]

	assert_bool((feel.get_node("Steam") as CPUParticles3D).emitting).is_true()


func test_its_bubble_is_up_while_something_cooks() -> void:
	var setup: Array = await _frying(&"herring_fillet")
	var feel: PanFeel = setup[1]

	assert_bool(feel.is_bubble_up()).is_true()
	assert_float(_face(feel).fraction).is_greater(0.0)


func test_it_glows_and_says_now_at_the_golden_moment() -> void:
	var setup: Array = await _frying(&"herring_fillet")
	var runner: GdUnitSceneRunner = setup[2]
	var feel: PanFeel = setup[1]

	await physics_ticks(runner, 6 * 60 + 5)

	assert_object(feel.moment()).is_not_null()
	assert_float((feel.get_node("Glow") as OmniLight3D).light_energy).is_greater(0.0)
	assert_str(_face(feel).text).is_equal("Now!")


func test_caught_it_names_the_dish_at_its_best() -> void:
	var setup: Array = await _frying(&"herring_fillet")
	var hob: Hob = setup[0]
	var feel: PanFeel = setup[1]
	var runner: GdUnitSceneRunner = setup[2]
	await physics_ticks(runner, 6 * 60 + 5)

	hob.heated.contents.remove_element(hob.heat)
	await physics_ticks(runner, 2)

	assert_str(_face(feel).text).is_equal("Pan-fried Herring ★★★")


func test_missed_it_names_the_dish_as_it_is() -> void:
	var setup: Array = await _frying(&"herring_fillet")
	var hob: Hob = setup[0]
	var feel: PanFeel = setup[1]
	var runner: GdUnitSceneRunner = setup[2]

	await physics_ticks(runner, 6 * 60 + 5 + roundi(hob.heated.item.golden_window * 60) + 5)

	assert_object(feel.moment()).is_null()
	assert_str(_face(feel).text).is_equal("Pan-fried Herring ★★")


# A hob with its pan frying a ★★ [param food_id], in a world freed after the
# test. Returns [hob, its PanFeel, runner].
func _frying(food_id: StringName) -> Array:
	var world: Node3D = Node3D.new()
	auto_free(world)
	var hob: Hob = (load(HOB_SCENE) as PackedScene).instantiate() as Hob
	world.add_child(hob)
	var camera: Camera3D = Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 1.5, 2)
	var runner: GdUnitSceneRunner = scene_runner(world)
	await physics_ticks(runner, 2)
	hob.heated.contents.add_item(ItemInstance.new(Catalog.load_default().find_item(food_id), 2))
	await physics_ticks(runner, 3)
	return [hob, hob.get_node("PanFeel") as PanFeel, runner]


func _face(feel: PanFeel) -> CookBubble:
	return feel.bubble().face() as CookBubble
