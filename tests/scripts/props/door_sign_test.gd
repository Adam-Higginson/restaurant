extends GameTestSuite
## Tests for DoorSign: Interact flips the restaurant between Open and Closed.

const DOOR_SIGN_SCENE: String = "res://scenes/props/door_sign.tscn"
const MAIN_SCENE: String = "res://scenes/main.tscn"
## Just above the door sign (centred at 352, 232).
const ABOVE_DOOR_SIGN: Vector2 = Vector2(352, 200)

var _state: GameState


func before_test() -> void:
	_state = GameState.new()
	auto_free(_state)


func after_test() -> void:
	# The scene tests use the real Game autoload, so put it back afterwards.
	Game.new_game()


# --- Flipping -----------------------------------------------------------------

func test_flip_opens_a_closed_restaurant() -> void:
	var door_sign: DoorSign = _new_sign()
	door_sign.flip()
	assert_bool(_state.is_open).is_true()


func test_flip_again_closes_it() -> void:
	var door_sign: DoorSign = _new_sign()
	door_sign.flip()
	door_sign.flip()
	assert_bool(_state.is_open).is_false()


func test_cannot_open_once_the_day_is_over() -> void:
	var door_sign: DoorSign = _new_sign()
	_state.end_day()
	door_sign.flip()
	assert_bool(_state.is_open).is_false()


func test_interacting_flips_it() -> void:
	var door_sign: DoorSign = _new_sign()
	(door_sign.get_node("Interactable") as Interactable).interact(null)
	assert_bool(_state.is_open).is_true()


func test_uses_the_game_autoload_by_default() -> void:
	var door_sign: DoorSign = (load(DOOR_SIGN_SCENE) as PackedScene).instantiate() as DoorSign
	add_child(door_sign)
	auto_free(door_sign)
	assert_object(door_sign.game_state).is_same(Game)


# --- In the restaurant --------------------------------------------------------

func test_restaurant_has_a_door_sign() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	assert_object(runner.find_child("DoorSign")).is_instanceof(DoorSign)


func test_pressing_interact_at_the_door_sign_opens_and_closes() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	place_player(runner, ABOVE_DOOR_SIGN)

	await walk(runner, "move_down", 20)
	await press(runner, "interact")
	assert_bool(Game.is_open).is_true()

	await press(runner, "interact")
	assert_bool(Game.is_open).is_false()


func _new_sign() -> DoorSign:
	var door_sign: DoorSign = (load(DOOR_SIGN_SCENE) as PackedScene).instantiate() as DoorSign
	# Before add_child, so _ready sees it instead of using the Game autoload.
	door_sign.game_state = _state
	add_child(door_sign)
	auto_free(door_sign)
	return door_sign
