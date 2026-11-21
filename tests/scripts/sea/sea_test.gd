extends GameTestSuite
## Tests for Sea: following the ship and moving around it on the swell,
## while the ship itself stays level.

const SEA_SCENE: String = "res://scenes/prototype/weather/sea_surface.tscn"


func test_centres_under_the_ship_and_drops_by_the_wave_height() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var sea: Sea = _add_sea(ship)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 3)
	# The sea follows the ship on rendered frames.
	await get_tree().process_frame
	await get_tree().process_frame

	var under: Vector2 = Vector2(ship.global_position.x, ship.global_position.z)
	assert_float(sea.global_position.x).is_equal_approx(snappedf(under.x, sea.grid_step), 0.001)
	assert_float(sea.global_position.z).is_equal_approx(snappedf(under.y, sea.grid_step), 0.001)
	assert_float(sea.global_position.y).is_equal_approx(-sea.height_at(under), 0.01)


func test_the_ship_stays_level_on_the_swell() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	_add_sea(ship)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 30)

	# The floor you see is the floor you stand on: nothing tilts the visuals
	# away from the body.
	var visuals: Node3D = ship.get_node("Visuals") as Node3D
	assert_vector(visuals.rotation).is_equal(Vector3.ZERO)
	assert_vector(ship.global_basis.y).is_equal_approx(Vector3.UP, Vector3.ONE * 0.0001)


func test_rain_is_kept_between_zero_and_one() -> void:
	var sea: Sea = _new_sea(WaveSettings.new())
	sea.rain = 3.0
	assert_float(sea.rain).is_equal(1.0)
	sea.rain = -1.0
	assert_float(sea.rain).is_equal(0.0)


func _add_sea(ship: Ship) -> Sea:
	var sea: Sea = (load(SEA_SCENE) as PackedScene).instantiate() as Sea
	sea.ship = ship
	ship.get_parent().add_child(sea)
	return sea


func _new_sea(settings: WaveSettings) -> Sea:
	var sea: Sea = (load(SEA_SCENE) as PackedScene).instantiate() as Sea
	sea.settings = settings
	add_child(sea)
	auto_free(sea)
	return sea

