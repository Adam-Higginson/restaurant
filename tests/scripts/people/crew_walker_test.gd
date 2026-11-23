extends GameTestSuite
## Tests for CrewWalker, which walks a crewmate about the ship (#157): along
## the walkways to a mark, facing its way at the end; waiting while the player
## is in the way or someone is talking with them; and, on the ship, from the
## captain's fire up the hatch ramp to the water butt and home again.

const HERON: PackedScene = preload("res://scenes/prototype/people/heron.tscn")
## The heron's start: 3 m ahead of the player (at -Z), as in the cue tests.
const START: Vector3 = Vector3(0, 0, -3)
## The mark: 4 m to the right, facing -X. The walkways go START -> CORNER ->
## the mark, 5 m in all.
const CORNER: Vector3 = Vector3(0, 0, -6)
const MARK: Transform3D = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(4, 0, -6))
const NEAR: Vector3 = Vector3(0.02, 0.02, 0.02)
## Physics ticks for the 7 m walk at the walker's 1.1 m/s, with some to spare.
const WALK_TICKS: int = 7 * 60

var _player: Player3D
var _heron: Crewmate
var _walker: CrewWalker
var _mark: Marker3D


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_they_walk_the_ways_to_the_mark_and_face_its_way() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 2)
	var moves: Array[bool] = []
	_walker.walking_changed.connect(func(moving: bool) -> void: moves.append(moving))
	var arrived: Array[int] = [0]
	_walker.arrived.connect(func() -> void: arrived[0] += 1)

	assert_bool(_walker.walk_to(_mark)).is_true()
	await physics_ticks(runner, 60)
	# By the corner first, not cutting across.
	assert_float(_heron.global_position.x).is_equal_approx(0.0, 0.01)
	assert_bool(_walker.is_walking).is_true()
	await physics_ticks(runner, WALK_TICKS)

	assert_int(arrived[0]).is_equal(1)
	assert_bool(_walker.is_walking).is_false()
	assert_vector(_heron.global_position).is_equal_approx(MARK.origin, NEAR)
	assert_float(_heron.global_rotation.y).is_equal_approx(PI / 2.0, 0.02)
	assert_array(moves).is_equal([true, false])


func test_they_wait_while_the_player_is_in_the_way() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 2)
	place_player_3d(runner, Vector3(0, 0, -4.2))
	_walker.walk_to(_mark)

	await physics_ticks(runner, 120)
	assert_bool(_walker.is_waiting).is_true()
	assert_float(_heron.global_position.z).is_greater(-4.2 + 0.5)

	place_player_3d(runner, Vector3(-3, 0, 2))
	await physics_ticks(runner, WALK_TICKS)
	assert_vector(_heron.global_position).is_equal_approx(MARK.origin, NEAR)


func test_they_wait_while_someone_is_talking_with_them() -> void:
	_build()
	var conversation: Conversation = new_conversation(_player)
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 2)
	_walker.walk_to(_mark)
	await physics_ticks(runner, 30)
	var tree: DialogueTree = DialogueScript.parse("heron: Hm.\nheron: Busy.", &"test")
	assert_bool(conversation.begin_tree(tree, _player, _heron)).is_true()
	var there: Vector3 = _heron.global_position

	await physics_ticks(runner, 60)
	assert_vector(_heron.global_position).is_equal_approx(there, NEAR)
	assert_bool(_walker.is_waiting).is_true()

	conversation.stop()
	await physics_ticks(runner, WALK_TICKS)
	assert_vector(_heron.global_position).is_equal_approx(MARK.origin, NEAR)


func test_with_no_walkways_they_go_nowhere() -> void:
	_player = new_player_3d_on_floor()
	_heron = HERON.instantiate() as Crewmate
	_heron.position = START
	_player.get_parent().add_child(_heron)
	_walker = _heron.get_node("Walker") as CrewWalker
	var mark: Marker3D = new_marker(_player.get_parent(), &"marks", "Spot", MARK)
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 2)

	assert_bool(_walker.walk_to(mark)).is_false()
	assert_bool(_walker.is_walking).is_false()


func test_the_captain_walks_up_the_ramp_to_the_water_butt_and_home() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(2, 1.05, 4))
	var ship: Ship = rig[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 3)
	var heron: Crewmate = ship.get_node("Crew/Heron") as Crewmate
	var walker: CrewWalker = heron.get_node("Walker") as CrewWalker
	var butt: Node3D = ship.get_node("Marks/WaterButt") as Node3D
	var fire: Node3D = ship.get_node("Crew/HeronNight") as Node3D
	var highest: Array[float] = [-INF]
	var climb: Callable = func() -> void:
		highest[0] = maxf(highest[0], ship.to_local(heron.global_position).y)

	assert_bool(walker.walk_to(butt)).is_true()
	for i: int in 20:
		await physics_ticks(runner, 60)
		climb.call()
	assert_vector(heron.global_position).is_equal_approx(butt.global_position, NEAR)
	assert_float(highest[0]).is_equal_approx(5.3, 0.05)

	assert_bool(walker.walk_home()).is_true()
	await physics_ticks(runner, 20 * 60)
	assert_vector(heron.global_position).is_equal_approx(fire.global_position, NEAR)


func _build() -> void:
	_player = new_player_3d_on_floor()
	var world: Node = _player.get_parent()
	_heron = HERON.instantiate() as Crewmate
	_heron.position = START
	world.add_child(_heron)
	_walker = _heron.get_node("Walker") as CrewWalker
	var walkways: Walkways = Walkways.new()
	_point(walkways, &"Start", START, [&"Corner"])
	_point(walkways, &"Corner", CORNER, [&"End"])
	_point(walkways, &"End", MARK.origin, [])
	world.add_child(walkways)
	_mark = new_marker(world, &"marks", "Spot", MARK)


func _point(walkways: Walkways, point_name: StringName, at: Vector3,
		links: Array[StringName]) -> void:
	var point: Waypoint = Waypoint.new()
	point.name = point_name
	point.position = at
	point.links = links
	walkways.add_child(point)
