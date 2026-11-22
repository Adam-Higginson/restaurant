extends GameTestSuite
## Checks project settings that are easy to lose: an editor left open from
## before a change can save its old settings back over project.godot.

const SHIP: String = "res://scenes/prototype/sea.tscn"


func test_running_the_project_starts_the_ship() -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")

	# F5 (Run Project) runs this: the 3D ship, not the old 2D restaurant.
	assert_str(main_scene).is_equal(SHIP)
	assert_bool(ResourceLoader.exists(main_scene)).is_true()
