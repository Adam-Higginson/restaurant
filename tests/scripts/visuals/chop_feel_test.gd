extends GameTestSuite
## Tests for how a cut at the chopping board feels (#152): the knife shows
## in the hand, you step up to the board, and how well the cut was timed is
## said over the board as the knife lands. (How it looks isn't tested.)

const COUNTER_SCENE: String = "res://scenes/prototype/props/counter.tscn"
const BOARD: Item = preload("res://data/items/chopping_board.tres")
const TOMATO: Item = preload("res://data/items/tomato.tres")
const KNIFE: HandTool = preload("res://data/tools/chefs_knife.tres")


func test_a_perfect_cut_says_so_as_the_knife_lands() -> void:
	var setup: Array = await _board_with_tomato()
	var counter: Counter3D = setup[0]
	var player: Player3D = setup[1]
	var runner: GdUnitSceneRunner = setup[2]

	counter.meter.position = counter.meter.centre
	counter.cut_with(player, KNIFE)
	await physics_ticks(runner, 30)

	assert_array(_words_said(counter)).contains(["Perfect!"])


func test_a_ragged_cut_says_so() -> void:
	var setup: Array = await _board_with_tomato()
	var counter: Counter3D = setup[0]
	var player: Player3D = setup[1]
	var runner: GdUnitSceneRunner = setup[2]

	counter.meter.position = 0.0
	counter.cut_with(player, KNIFE)
	await physics_ticks(runner, 30)

	assert_array(_words_said(counter)).contains(["Ragged"])


func test_the_knife_shows_in_the_hand_for_a_cut() -> void:
	var setup: Array = await _board_with_tomato()
	var counter: Counter3D = setup[0]
	var player: Player3D = setup[1]
	var runner: GdUnitSceneRunner = setup[2]
	var duellist: Duellist = duellist_of(player)
	assert_bool(duellist.knife.visible).is_false()

	counter.cut_with(player, KNIFE)
	await physics_ticks(runner, 2)

	assert_bool(duellist.knife.visible).is_true()


func test_the_knife_leaves_no_trail_at_the_board() -> void:
	var setup: Array = await _board_with_tomato()
	var counter: Counter3D = setup[0]
	var player: Player3D = setup[1]
	var runner: GdUnitSceneRunner = setup[2]

	counter.cut_with(player, KNIFE)
	await physics_ticks(runner, 6)

	assert_int((player.get_node("KnifeTrail") as KnifeTrail).length()).is_equal(0)


func test_the_first_cut_steps_you_up_to_the_board() -> void:
	var setup: Array = await _board_with_tomato()
	var counter: Counter3D = setup[0]
	var player: Player3D = setup[1]
	var runner: GdUnitSceneRunner = setup[2]
	var before: float = _distance(player, counter)

	counter.cut_with(player, KNIFE)
	await physics_ticks(runner, 20)

	assert_float(_distance(player, counter)).is_less(before - 0.3)


func test_walking_away_stops_the_step() -> void:
	var setup: Array = await _board_with_tomato()
	var counter: Counter3D = setup[0]
	var player: Player3D = setup[1]
	var runner: GdUnitSceneRunner = setup[2]

	counter.cut_with(player, KNIFE)
	await walk(runner, "move_down", 24)

	assert_float(_distance(player, counter)).is_greater(1.5)


# A board with a tomato on it 1.2 m in front of a player facing it, after
# the meter's gone up. Returns [counter, player, runner].
func _board_with_tomato() -> Array:
	var player: Player3D = new_player_3d_on_floor()
	var counter: Counter3D = (load(COUNTER_SCENE) as PackedScene).instantiate() as Counter3D
	counter.start_item = BOARD
	counter.position = Vector3(0, 0, -1.2)
	player.get_parent().add_child(counter)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	counter.slot.get_item().contents.add_item(ItemInstance.new(TOMATO))
	await physics_ticks(runner, 5)
	return [counter, player, runner]


# The words popped up beside [param counter] so far.
func _words_said(counter: Counter3D) -> PackedStringArray:
	var said: PackedStringArray = PackedStringArray()
	for node: Node in counter.get_parent().get_children():
		var label: DamageNumber = node as DamageNumber
		if label != null:
			said.append(label.words)
	return said


func _distance(player: Player3D, counter: Counter3D) -> float:
	var gap: Vector3 = counter.global_position - player.global_position
	gap.y = 0.0
	return gap.length()
