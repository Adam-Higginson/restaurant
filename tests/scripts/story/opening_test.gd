extends GameTestSuite
## Tests for how the game begins, in the real scene (scenes/prototype/sea.tscn),
## so its wiring is tested too. The intro cutscene (data/dialogue/intro.dlg)
## opens on the ship's name at her stern, lit by the lantern on his hook, and
## waits for a button; on a new voyage he dives and it goes under, through
## the rescue, to waking by your bunk; a saved voyage carries on.
## It can be skipped, and started part-way in. Skipped altogether
## (Opening.skip), you start where you stand.
##
## The intro is long, so each test plays one stretch of it.

const SEA: String = "res://scenes/prototype/sea.tscn"
const INTRO: StringName = &"intro"
const NEAR: Vector3 = Vector3(0.05, 0.05, 0.05)

var _sea: Node
var _opening: Opening
var _ship: Ship
var _player: Player3D
var _conversation: Conversation


func before_test() -> void:
	Game.dialogue.reset()
	SaveGame.erase()


func after_test() -> void:
	Game.dialogue.reset()
	SaveGame.erase()


func test_it_opens_on_her_name_and_waits_for_any_button() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	var hook_lantern: Node3D = _hook_lantern()
	var carved: CarvedName = _ship.get_node("SternWatch/Name") as CarvedName
	var swing: SternSwing = _ship.get_node("SternWatch/Swing") as SternSwing
	var face: LanternFace = hook_lantern.get_node("Body") as LanternFace
	var underwater: Stage = _sea.get_node("Stages/Underwater") as Stage
	var prompt: CutscenePrompt = _sea.get_node("CutscenePrompt") as CutscenePrompt
	await physics_ticks(runner, 3)

	# Black at first; you're by your bunk and can't move.
	assert_bool(_opening.is_playing).is_true()
	assert_bool(_conversation.is_cutscene()).is_true()
	assert_bool(_fade().visible).is_true()
	assert_bool(_player.controls_enabled).is_false()
	var at: Vector3 = _ship.to_local(_player.global_position)
	assert_float(at.distance_to(_opening.wake_spot)).is_less(0.3)

	# Her name at the stern, on a fixed shot: he's on his hook, swinging,
	# half asleep, and his light is what shows the letters.
	await physics_ticks(runner, 240)
	assert_bool(hook_lantern.is_visible_in_tree()).is_true()
	assert_bool(swing.swinging).is_true()
	assert_int(face.expression).is_equal(LanternFace.Look.TIRED)
	assert_float(carved.lamp_glow()).is_greater(0.9)
	# The gallery windows behind her name are off, so his light shows.
	var dimmer: WindowDimmer = _ship.get_node("SternWatch/WindowDimmer") as WindowDimmer
	assert_bool(dimmer.dimmed).is_true()
	assert_float(dimmer.level).is_equal(0.0)
	assert_bool(_fade().visible).is_false()
	assert_bool(_player.camera_rig.is_fixed).is_true()
	assert_str(prompt.shown_text()).is_equal("Press any button")
	assert_str(String(_conversation.section())).is_equal("start")

	# However long you leave it, it waits.
	await physics_ticks(runner, 240)
	assert_str(String(_conversation.section())).is_equal("start")

	# Any key at all: he hears something, and stops.
	runner.simulate_key_pressed(KEY_ENTER)
	assert_bool(await _reaches(runner, &"he_hears")).is_true()
	await physics_ticks(runner, 20)
	assert_bool(swing.swinging).is_false()
	assert_int(face.expression).is_equal(LanternFace.Look.SURPRISED)

	# Off the hook and over the side: her name is dark, and you're under.
	assert_bool(await _reaches(runner, &"dark")).is_true()
	assert_bool(hook_lantern.is_visible_in_tree()).is_false()
	assert_float(carved.lamp_glow()).is_equal(0.0)
	assert_bool(dimmer.dimmed).is_false()
	assert_bool(underwater.is_open).is_true()
	assert_bool(_ambience().submerged).is_true()
	assert_str(prompt.shown_text()).is_empty()


func test_the_rescue_waits_for_you_to_take_his_hand_then_goes_to_the_surface() -> void:
	_build(&"reach")
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	var underwater: Stage = _sea.get_node("Stages/Underwater") as Stage
	var prompt: CutscenePrompt = _sea.get_node("CutscenePrompt") as CutscenePrompt
	var castaway: Node3D = _ship.get_node("RescueSet/Props/Castaway") as Node3D
	var boathook: Node3D = _ship.get_node("RescueSet/Props/ReachingBoathook") as Node3D
	var heron: Crewmate = _ship.get_node("Crew/Heron") as Crewmate

	# It waits underwater, and says what to press.
	await physics_ticks(runner, 200)
	assert_str(String(_conversation.section())).is_equal("reach")
	assert_bool(underwater.is_open).is_true()
	assert_str(prompt.shown_text()).contains("Take his hand")
	assert_bool(castaway.visible).is_false()

	# Take it: up to the surface, beside the ship, with the storm clear again.
	_conversation.press()
	assert_bool(await _reaches(runner, &"surface")).is_true()
	await physics_ticks(runner, 5)
	assert_bool(underwater.is_open).is_false()
	assert_bool(_ambience().submerged).is_false()
	assert_bool(castaway.visible).is_true()
	assert_bool(_player.camera_rig.is_fixed).is_true()

	# The captain at the rail with the boathook.
	assert_bool(await _reaches(runner, &"boathook")).is_true()
	await physics_ticks(runner, 5)
	var rail: Node3D = _ship.get_node("RescueSet/Marks/Rail") as Node3D
	assert_bool(heron.is_present()).is_true()
	assert_vector(heron.global_position).is_equal_approx(rail.global_position, NEAR)
	assert_bool(boathook.visible).is_true()

	# To black and the chapter card, with the rescue's pieces put away.
	assert_bool(await _reaches(runner, &"title")).is_true()
	await physics_ticks(runner, 5)
	assert_bool(castaway.visible).is_false()
	assert_bool(boathook.visible).is_false()
	assert_bool(heron.is_present()).is_false()
	assert_bool(_fade().is_covering()).is_true()


func test_you_wake_and_the_captain_appears_and_then_the_ship_is_yours() -> void:
	_build(&"title")
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	var heron: Crewmate = _ship.get_node("Crew/Heron") as Crewmate
	var rig: CameraRig = _player.camera_rig

	# The lantern's three lines.
	assert_bool(await _reaches(runner, &"waking")).is_true()
	assert_bool(_fade().visible).is_false()
	assert_bool(heron.is_present()).is_false()
	for i: int in 3:
		assert_str(String(_conversation.section())).is_equal("waking")
		_press()

	# The captain in the doorway, on a fixed shot.
	assert_bool(await _reaches(runner, &"doorway")).is_true()
	await physics_ticks(runner, 60)
	var doorway: Node3D = _ship.get_node("Marks/Doorway") as Node3D
	assert_bool(heron.is_present()).is_true()
	assert_vector(heron.global_position).is_equal_approx(doorway.global_position, NEAR)
	assert_bool(rig.is_fixed).is_true()
	_press()
	_press()

	# The pot on the stove; the captain goes back to the fire; and it ends.
	assert_bool(await _reaches(runner, &"stove")).is_true()
	var night: Node3D = _ship.get_node("Crew/HeronNight") as Node3D
	assert_vector(heron.global_position).is_equal_approx(night.global_position, NEAR)
	assert_bool(await wait_for_signal(_opening.finished, 20.0)).is_true()

	assert_bool(_opening.is_playing).is_false()
	assert_bool(_conversation.is_active()).is_false()
	assert_bool(_player.controls_enabled).is_true()
	assert_bool(rig.is_fixed).is_false()
	assert_bool(heron.is_present()).is_true()


func test_skipping_the_intro_ends_it_with_everything_put_away() -> void:
	_build(&"dark")
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	var heron: Crewmate = _ship.get_node("Crew/Heron") as Crewmate
	await physics_ticks(runner, 30)
	assert_bool((_sea.get_node("Stages/Underwater") as Stage).is_open).is_true()

	_conversation.skip()
	await physics_ticks(runner, 60)

	assert_bool(_opening.is_playing).is_false()
	assert_bool(_player.controls_enabled).is_true()
	assert_bool(_fade().visible).is_false()
	assert_bool(_player.camera_rig.is_fixed).is_false()
	assert_bool((_sea.get_node("Stages/Underwater") as Stage).is_open).is_false()
	assert_bool(_hook_lantern().is_visible_in_tree()).is_false()
	assert_bool((_ship.get_node("SternWatch/WindowDimmer") as WindowDimmer).dimmed).is_false()
	assert_bool(_ambience().submerged).is_false()
	assert_bool((_ship.get_node("RescueSet/Props/Castaway") as Node3D).visible).is_false()
	assert_bool((_ship.get_node("RescueSet/Props/ReachingBoathook") as Node3D).visible).is_false()
	var night: Node3D = _ship.get_node("Crew/HeronNight") as Node3D
	assert_bool(heron.is_present()).is_true()
	assert_vector(heron.global_position).is_equal_approx(night.global_position, NEAR)
	var at: Vector3 = _ship.to_local(_player.global_position)
	assert_float(at.distance_to(_opening.wake_spot)).is_less(0.6)


func test_a_saved_voyage_carries_on_after_the_title_instead_of_the_rescue() -> void:
	SaveGame.write({"version": SaveGame.VERSION, "memories": [], "day": 5, "morning": true,
			"warmth": 0.5})
	_build(DialogueTree.START, true)
	_opening.title_seconds = 0.2
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	var heron: Crewmate = _ship.get_node("Crew/Heron") as Crewmate
	await physics_ticks(runner, 240)
	assert_bool(_hook_lantern().is_visible_in_tree()).is_true()

	runner.simulate_key_pressed(KEY_ENTER)
	assert_bool(await _reaches(runner, &"carry_on")).is_true()
	await physics_ticks(runner, 10)
	# He doesn't dive: he's pleased to see you.
	var face: LanternFace = _hook_lantern().get_node("Body") as LanternFace
	assert_bool(_hook_lantern().is_visible_in_tree()).is_true()
	assert_int(face.expression).is_equal(LanternFace.Look.PLEASED)
	assert_bool(await wait_for_signal(_opening.finished, 20.0)).is_true()

	# No rescue: straight to the ship, the day it was, everyone aboard, and
	# the hook at the stern empty.
	assert_bool(_hook_lantern().is_visible_in_tree()).is_false()
	assert_bool((_sea.get_node("Stages/Underwater") as Stage).is_open).is_false()
	assert_bool(_ambience().submerged).is_false()
	assert_bool(_player.controls_enabled).is_true()
	assert_bool(_player.camera_rig.is_fixed).is_false()
	assert_bool(heron.is_present()).is_true()
	var time: TimeOfDay = _sea.get_node("TimeOfDay") as TimeOfDay
	assert_int(time.day).is_equal(5)
	await physics_ticks(runner, 90)
	assert_bool(_fade().visible).is_false()


func test_everything_the_intro_asks_for_is_in_the_scene() -> void:
	_build()
	_opening.skip = true
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	await physics_ticks(runner, 3)
	assert_bool(_opening.is_playing).is_false()
	var shots: ShotCues = _sea.get_node("ShotCues") as ShotCues
	var actors: ActorCues = _sea.get_node("ActorCues") as ActorCues
	var stages: StageCues = _sea.get_node("StageCues") as StageCues
	var clips: ClipCues = _sea.get_node("ClipCues") as ClipCues
	var sounds: SoundCues = _sea.get_node("SoundCues") as SoundCues
	var looks: LookCues = _sea.get_node("LookCues") as LookCues
	var tree: DialogueTree = DialogueLibrary.find(INTRO)
	assert_array(tree.errors).is_empty()

	var checked: int = 0
	for step: DialogueStep in tree.steps:
		if step.kind != DialogueStep.Kind.CUE:
			continue
		var word: String = step.args[0] if not step.args.is_empty() else ""
		var found: Object = self
		match step.cue:
			&"shot":
				if word != ShotCues.FREE:
					found = shots.find_shot(word)
			&"place":
				found = actors.find_mark(step.args[1])
				assert_object(actors.find_actor(word)).override_failure_message(
						"intro.dlg, line %d: nobody called '%s'" % [step.line_number, word]) \
						.is_not_null()
			&"face", &"hide", &"show", &"home":
				found = actors.find_actor(word)
			&"stage":
				if word != "off":
					found = stages.find_stage(word)
			&"play", &"start":
				found = clips.find_player(StringName(word))
			&"look":
				found = looks.find_face(word)
			&"sound":
				found = sounds.find_sound(word)
				if found != null:
					assert_object((found as AudioStreamPlayer).stream).override_failure_message(
							"intro.dlg, line %d: the sound '%s' has no recording"
							% [step.line_number, word]).is_not_null()
		assert_object(found).override_failure_message("intro.dlg, line %d: there's no '%s' for @%s"
				% [step.line_number, word, step.cue]).is_not_null()
		checked += 1
	assert_int(checked).is_greater(30)


func test_it_can_open_on_a_later_beat_with_no_black_screen() -> void:
	_build(&"doorway")
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	await physics_ticks(runner, 5)

	assert_str(String(_conversation.section())).is_equal("doorway")
	assert_bool(_fade().visible).is_false()
	assert_bool(_opening.is_playing).is_true()


func test_you_stay_aboard_while_the_ship_sails_on() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	_ship.set_sail()

	await physics_ticks(runner, 90)

	# Still by the bunk, give or take settling onto the floor; left behind, the
	# ship would have sailed metres away.
	var at: Vector3 = _ship.to_local(_player.global_position)
	assert_float(at.distance_to(_opening.wake_spot)).is_less(0.6)


func test_with_nothing_to_play_the_intro_you_just_open_your_eyes() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 5.35, 7.5))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var opening: Opening = Opening.new()
	opening.player = player
	opening.ship = ship
	opening.load_save = false
	var fade: ScreenFade = (load("res://ui/screen_fade.tscn") as PackedScene).instantiate() \
			as ScreenFade
	fade.name = "ScreenFade"
	fade.fade_seconds = 0.1
	opening.add_child(fade)
	ship.get_parent().add_child(opening)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 3)
	assert_bool(opening.is_playing).is_true()
	assert_bool(player.controls_enabled).is_false()

	await physics_ticks(runner, 30)

	assert_bool(opening.is_playing).is_false()
	assert_bool(player.controls_enabled).is_true()
	assert_bool(fade.visible).is_false()


func test_skipped_you_start_where_you_stand() -> void:
	_build()
	_opening.skip = true
	var before: Vector3 = _player.position
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	await physics_ticks(runner, 5)

	assert_bool(_opening.is_playing).is_false()
	assert_bool(_conversation.is_active()).is_false()
	assert_bool(_player.controls_enabled).is_true()
	assert_float(_player.global_position.distance_to(before)).is_less(1.0)


# Presses Interact past any typing: on to the next line.
func _press() -> void:
	var box: DialogueBox = _conversation.box
	if box != null and box.is_typing():
		box.finish_typing()
	_conversation.press()


# Waits until the cutscene is reading [param section], and returns whether
# it got there within 30 seconds of game time.
func _reaches(runner: GdUnitSceneRunner, section: StringName) -> bool:
	for i: int in 1800:
		if _conversation.section() == section:
			return true
		await physics_ticks(runner, 1)
	return false


# The lantern hanging from the hook at the stern.
func _hook_lantern() -> Node3D:
	return _ship.get_node("SternWatch/Swing/HookLantern") as Node3D


func _fade() -> ScreenFade:
	return _opening.get_node("ScreenFade") as ScreenFade


func _ambience() -> Ambience:
	return _sea.get_node("Weather/Ambience") as Ambience


# The real sea scene, not yet running, with its opening set to begin at
# [param section] and to ignore any saved voyage unless [param load_save].
# Called at the start of each test, so it's made (and freed) inside it.
func _build(section: StringName = DialogueTree.START, load_save: bool = false) -> void:
	_sea = (load(SEA) as PackedScene).instantiate()
	auto_free(_sea)
	_opening = _sea.get_node("Opening") as Opening
	_opening.start_section = section
	_opening.load_save = load_save
	_ship = _sea.get_node("Ship") as Ship
	_player = _sea.get_node("Player") as Player3D
	_conversation = _sea.get_node("Conversation") as Conversation
