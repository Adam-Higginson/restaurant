extends GameTestSuite
## Tests for how the game begins. A new voyage opens with the intro cutscene
## (data/dialogue/intro.dlg): black and a title, you wake by your bunk
## unable to move, the lantern speaks, the captain appears in the doorway,
## and then the ship is yours. It can be skipped, and started part-way in.
## Skipped altogether (Opening.skip), you start where you stand.

const INTRO: StringName = &"intro"

var _ship: Ship
var _player: Player3D
var _conversation: Conversation


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()
	Game.set_look(PlayerLook.Body.BOY)


func test_the_intro_plays_from_black_to_the_ship_being_yours() -> void:
	var opening: Opening = _stage(false)
	var runner: GdUnitSceneRunner = scene_runner(_ship.get_parent())
	var heron: Crewmate = _ship.get_node("Crew/Heron") as Crewmate
	var rig: CameraRig = _player.camera_rig
	await physics_ticks(runner, 3)

	# Black, and the title. You're by your bunk and can't move; the captain
	# isn't in the room.
	assert_bool(opening.is_playing).is_true()
	assert_bool(_conversation.is_cutscene()).is_true()
	assert_bool(_fade(opening).is_covering()).is_true()
	assert_bool(_player.controls_enabled).is_false()
	var at: Vector3 = _ship.to_local(_player.global_position)
	assert_float(at.distance_to(opening.wake_spot)).is_less(0.3)
	assert_bool(heron.is_present()).is_false()

	# The lantern's three lines.
	assert_bool(await _reaches(runner, &"waking")).is_true()
	assert_bool(_fade(opening).visible).is_false()
	for i: int in 3:
		assert_str(String(_conversation.section())).is_equal("waking")
		_conversation.press()

	# The captain in the doorway, on a fixed shot.
	assert_bool(await _reaches(runner, &"doorway")).is_true()
	await physics_ticks(runner, 60)
	var doorway: Node3D = _ship.get_node("Marks/Doorway") as Node3D
	assert_bool(heron.is_present()).is_true()
	assert_vector(heron.global_position).is_equal_approx(doorway.global_position,
			Vector3(0.05, 0.05, 0.05))
	assert_bool(rig.is_fixed).is_true()
	_conversation.press()
	_conversation.press()

	# The pot on the stove; the captain goes back to the fire; and it ends.
	assert_bool(await _reaches(runner, &"stove")).is_true()
	var night: Node3D = _ship.get_node("Crew/HeronNight") as Node3D
	assert_vector(heron.global_position).is_equal_approx(night.global_position,
			Vector3(0.05, 0.05, 0.05))
	assert_bool(await wait_for_signal(opening.finished, 20.0)).is_true()

	assert_bool(opening.is_playing).is_false()
	assert_bool(_conversation.is_active()).is_false()
	assert_bool(_player.controls_enabled).is_true()
	assert_bool(rig.is_fixed).is_false()
	assert_bool(heron.is_present()).is_true()


func test_skipping_the_intro_ends_it_with_everyone_in_place() -> void:
	var opening: Opening = _stage(false)
	var runner: GdUnitSceneRunner = scene_runner(_ship.get_parent())
	var heron: Crewmate = _ship.get_node("Crew/Heron") as Crewmate
	await physics_ticks(runner, 10)

	_conversation.skip()
	await physics_ticks(runner, 30)

	assert_bool(opening.is_playing).is_false()
	assert_bool(_player.controls_enabled).is_true()
	assert_bool(_fade(opening).visible).is_false()
	assert_bool(_player.camera_rig.is_fixed).is_false()
	var night: Node3D = _ship.get_node("Crew/HeronNight") as Node3D
	assert_bool(heron.is_present()).is_true()
	assert_vector(heron.global_position).is_equal_approx(night.global_position,
			Vector3(0.05, 0.05, 0.05))
	var at: Vector3 = _ship.to_local(_player.global_position)
	assert_float(at.distance_to(opening.wake_spot)).is_less(0.6)


func test_it_can_open_on_a_later_beat_with_no_black_screen() -> void:
	var opening: Opening = _stage(false)
	opening.start_section = &"doorway"
	var runner: GdUnitSceneRunner = scene_runner(_ship.get_parent())
	await physics_ticks(runner, 5)

	assert_str(String(_conversation.section())).is_equal("doorway")
	assert_bool(_fade(opening).visible).is_false()
	assert_bool(opening.is_playing).is_true()


func test_every_shot_mark_and_person_the_intro_asks_for_is_aboard() -> void:
	var opening: Opening = _stage(true)
	var runner: GdUnitSceneRunner = scene_runner(_ship.get_parent())
	await physics_ticks(runner, 3)
	assert_bool(opening.is_playing).is_false()
	var shots: ShotCues = _ship.get_parent().get_node("ShotCues") as ShotCues
	var actors: ActorCues = _ship.get_parent().get_node("ActorCues") as ActorCues
	var tree: DialogueTree = DialogueLibrary.find(INTRO)
	assert_array(tree.errors).is_empty()

	for step: DialogueStep in tree.steps:
		if step.kind != DialogueStep.Kind.CUE:
			continue
		var where: String = "intro.dlg, line %d" % step.line_number
		match step.cue:
			&"shot":
				if step.args[0] != ShotCues.FREE:
					assert_object(shots.find_shot(step.args[0])) \
							.override_failure_message("%s: no shot '%s'" % [where, step.args[0]]) \
							.is_not_null()
			&"place":
				assert_object(actors.find_mark(step.args[1])) \
						.override_failure_message("%s: no mark '%s'" % [where, step.args[1]]) \
						.is_not_null()
		if actors.cues().has(step.cue):
			assert_object(actors.find_actor(step.args[0])) \
					.override_failure_message("%s: nobody called '%s'" % [where, step.args[0]]) \
					.is_not_null()


func test_you_stay_aboard_while_the_ship_sails_on() -> void:
	var opening: Opening = _stage(false)
	var runner: GdUnitSceneRunner = scene_runner(_ship.get_parent())
	_ship.set_sail()

	await physics_ticks(runner, 90)

	# Still by the bunk, give or take settling onto the floor; left behind, the
	# ship would have sailed metres away.
	var at: Vector3 = _ship.to_local(_player.global_position)
	assert_float(at.distance_to(opening.wake_spot)).is_less(0.6)


func test_with_nothing_to_play_the_intro_you_just_open_your_eyes() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 5.35, 7.5))
	_ship = rig[0] as Ship
	_player = rig[1] as Player3D
	var opening: Opening = _opening(false)
	var runner: GdUnitSceneRunner = scene_runner(_ship.get_parent())
	await physics_ticks(runner, 3)
	assert_bool(opening.is_playing).is_true()
	assert_bool(_player.controls_enabled).is_false()

	await physics_ticks(runner, 30)

	assert_bool(opening.is_playing).is_false()
	assert_bool(_player.controls_enabled).is_true()
	assert_bool(_fade(opening).visible).is_false()


func test_skipped_you_start_where_you_stand() -> void:
	var opening: Opening = _stage(true)
	var runner: GdUnitSceneRunner = scene_runner(_ship.get_parent())
	await physics_ticks(runner, 5)

	assert_bool(opening.is_playing).is_false()
	assert_bool(_conversation.is_active()).is_false()
	assert_float(_ship.to_local(_player.global_position).y).is_greater(5.0)


func test_a_new_voyage_asks_who_you_are_before_the_intro() -> void:
	var opening: Opening = _stage(false)
	var choice: LookChoice = _add_choice(opening)
	var runner: GdUnitSceneRunner = scene_runner(_ship.get_parent())
	await physics_ticks(runner, 10)

	assert_bool(choice.is_open()).is_true()
	assert_bool(_conversation.is_active()).is_false()
	assert_bool(_player.controls_enabled).is_false()

	choice.choose(PlayerLook.Body.GIRL)
	await physics_ticks(runner, 5)

	assert_bool(choice.is_open()).is_false()
	assert_int(Game.look).is_equal(PlayerLook.Body.GIRL)
	assert_bool(_conversation.is_active()).is_true()


func test_without_choosing_the_intro_starts_at_once() -> void:
	var opening: Opening = _stage(false)
	var choice: LookChoice = _add_choice(opening)
	opening.choose_look = false
	var runner: GdUnitSceneRunner = scene_runner(_ship.get_parent())
	await physics_ticks(runner, 10)

	assert_bool(choice.is_open()).is_false()
	assert_bool(_conversation.is_active()).is_true()


# Gives [param opening] its "Who are you?" screen, as sea.tscn has it.
func _add_choice(opening: Opening) -> LookChoice:
	var choice: LookChoice = (load("res://ui/look_choice.tscn") as PackedScene).instantiate() 			as LookChoice
	opening.add_child(choice)
	return choice


# Waits until the cutscene is reading [param section], and returns whether
# it got there within 20 seconds of game time.
func _reaches(runner: GdUnitSceneRunner, section: StringName) -> bool:
	for i: int in 1200:
		if _conversation.section() == section:
			return true
		await physics_ticks(runner, 1)
	return false


func _fade(opening: Opening) -> ScreenFade:
	return opening.get_node("ScreenFade") as ScreenFade


# A moored ship with the player on deck, a conversation, every cue handler
# and an opening, as scenes/prototype/sea.tscn has them. Called at the start
# of each test, so everything is made (and freed) inside it.
func _stage(skip: bool) -> Opening:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 5.35, 7.5))
	_ship = rig[0] as Ship
	_player = rig[1] as Player3D
	var world: Node = _ship.get_parent()
	_conversation = new_conversation(_player)
	var opening: Opening = _opening(skip)
	var shots: ShotCues = ShotCues.new()
	shots.name = "ShotCues"
	shots.player = _player
	world.add_child(shots)
	var fades: FadeCues = FadeCues.new()
	fades.fade = _fade(opening)
	world.add_child(fades)
	world.add_child(WaitCues.new())
	var actors: ActorCues = ActorCues.new()
	actors.name = "ActorCues"
	actors.player = _player
	world.add_child(actors)
	return opening


# An opening with quick fades, added to the ship's world.
func _opening(skip: bool) -> Opening:
	var opening: Opening = Opening.new()
	opening.skip = skip
	opening.player = _player
	opening.ship = _ship
	opening.title_seconds = 0.1
	opening.load_save = false
	var fade: ScreenFade = (load("res://ui/screen_fade.tscn") as PackedScene).instantiate() \
			as ScreenFade
	fade.name = "ScreenFade"
	fade.fade_seconds = 0.1
	opening.add_child(fade)
	_ship.get_parent().add_child(opening)
	return opening
