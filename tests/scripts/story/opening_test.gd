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
## The title's menu, for a saved voyage: its choices in order.
const CONTINUE: int = 0
const NEW: int = 1

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
	Game.set_look(PlayerLook.Body.BOY)


func test_it_opens_on_her_name_and_waits_for_any_button() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	var hook_lantern: Node3D = _hook_lantern()
	var carved: CarvedName = _ship.get_node("SternWatch/Name") as CarvedName
	var swing: SternSwing = _ship.get_node("SternWatch/Swing") as SternSwing
	var face: LanternFace = hook_lantern.get_node("Body") as LanternFace
	var underwater: Stage = _sea.get_node("Stages/Underwater") as Stage
	var prompt: CutscenePrompt = _sea.get_node("Story/CutscenePrompt") as CutscenePrompt
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

	# Any key at all. The night goes on a moment longer, then he's seen
	# something, and stops. The captain is up at the wheel, and faint lights
	# come up, far down in the water.
	var said: Array[int] = [0]
	_conversation.line_said.connect(func(_speaker: Person) -> void: said[0] += 1)
	runner.simulate_key_pressed(KEY_ENTER)
	assert_bool(await _reaches(runner, &"the_stern")).is_true()
	await physics_ticks(runner, 130)
	assert_bool(swing.swinging).is_false()
	assert_int(face.expression).is_equal(LanternFace.Look.SURPRISED)
	assert_bool(_heron().is_present()).is_true()
	assert_float(_heron().global_position.distance_to(_mark("wheel").global_position)) \
			.is_less(0.1)

	# His first words, to the captain, waiting to be read.
	assert_bool(await _line_shows(runner, said, 1)).is_true()
	assert_str(_conversation.box.line_text()).is_equal("There you are...")
	assert_str(_conversation.box.speaker_name()).is_equal("Lantern")
	assert_bool(_conversation.is_aside_up()).is_false()
	assert_float(_sea_surface().grave).is_greater(0.3)
	assert_bool(underwater.is_open).is_false()


func test_the_rail_looks_down_into_the_grave_finds_a_hand_and_ends_in_his_dive() -> void:
	_build(&"the_stern")
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	var said: Array[int] = [0]
	_conversation.line_said.connect(func(_speaker: Person) -> void: said[0] += 1)
	var grave: Stage = _sea.get_node("Stages/Grave") as Stage
	var underwater: Stage = _sea.get_node("Stages/Underwater") as Stage
	var overboard: Node3D = _grave_set().get_node("Overboard") as Node3D
	var thing: Node3D = _grave_set().get_node("Thing") as Node3D
	var hook_lantern: Node3D = _hook_lantern()
	await physics_ticks(runner, 3)

	# The invitation plays at the wheel before either of them goes to the rail.
	assert_bool(await _read_on_until(runner, said, &"to_the_rail")).is_true()
	assert_bool(await _line_shows(runner, said, 5)).is_true()
	assert_str(_conversation.box.line_text()).is_equal("Captain. Come take a look.")
	assert_float(hook_lantern.global_position.distance_to(_mark("at_wheel").global_position)) \
			.is_less(0.35)
	assert_float(_heron().global_position.distance_to(_mark("wheel").global_position)) \
			.is_less(0.3)

	# At the rail they look out together. The camera goes past
	# him, out over the water and down into the Grave of the Lanterns, a set
	# of its own. You're not to be seen yet.
	assert_bool(await _read_on_until(runner, said, &"the_grave", said[0] - 1)).is_true()
	var beside: Vector3 = _mark("beside_him").global_position
	var perch: Vector3 = _mark("rail_perch").global_position
	assert_float(_heron().global_position.distance_to(beside)).is_less(0.3)
	assert_float(hook_lantern.global_position.distance_to(perch)).is_less(0.6)
	await physics_ticks(runner, 3)
	assert_bool(grave.is_open).is_false()
	await physics_ticks(runner, 100)
	assert_bool(grave.is_open).is_true()
	assert_bool(overboard.visible).is_false()

	# The rail comes back in a direct cut, before the bell rings.
	assert_bool(await _read_on_until(runner, said, &"something_down_there")).is_true()
	await physics_ticks(runner, 3)
	assert_bool(grave.is_open).is_false()
	assert_bool(_fade().visible).is_false()

	# Back over the water, the thing goes by under the lanterns.
	assert_bool(await _read_on_until(runner, said, &"the_shape", said[0] - 1)).is_true()
	await physics_ticks(runner, 100)
	assert_bool(grave.is_open).is_true()
	var thing_was: Vector3 = thing.position
	await physics_ticks(runner, 120)
	assert_float(thing.position.distance_to(thing_was)).is_greater(10.0)

	# Among the dead lights, a hand: you.
	assert_bool(await _reaches(runner, &"the_hand")).is_true()
	await physics_ticks(runner, 3)
	assert_bool(overboard.visible).is_true()

	# "Somebody overboard!" The captain turns on him, and he's gone: from out
	# on the water a lantern is in the air astern of her.
	var flying: Node3D = _ship.get_node("RescueSet/Props/FlyingLantern") as Node3D
	var hung_at: Vector3 = flying.position
	assert_bool(await _read_on_until(runner, said, &"plunge")).is_true()
	assert_bool(grave.is_open).is_false()
	await physics_ticks(runner, 45)
	var to_him: Vector3 = (_mark("rail_perch").global_position - _heron().global_position)
	to_him.y = 0.0
	var facing: Vector3 = -(_heron().get_node("Model") as Node3D).global_basis.z
	facing.y = 0.0
	assert_float(facing.normalized().dot(to_him.normalized())).is_greater(0.7)
	assert_bool(flying.visible).is_true()
	assert_float(flying.position.distance_to(hung_at)).is_greater(2.0)
	assert_bool(hook_lantern.is_visible_in_tree()).is_false()

	# He hits the water, and we're under with him, straight away.
	assert_bool(await _reaches(runner, &"light")).is_true()
	assert_bool(underwater.is_open).is_true()
	assert_bool(_ambience().submerged).is_true()


func test_he_comes_down_warm_finds_you_and_holds_out_his_hand() -> void:
	_build(&"light")
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	var said: Array[int] = [0]
	_conversation.line_said.connect(func(_speaker: Person) -> void: said[0] += 1)
	var underwater: Stage = _sea.get_node("Stages/Underwater") as Stage
	var prompt: CutscenePrompt = _sea.get_node("Story/CutscenePrompt") as CutscenePrompt
	var face: LanternFace = _sinking_lantern()
	var hand: FlameHand = _underwater_set().get_node("Lantern/Hand") as FlameHand
	var trail: CPUParticles3D = _underwater_set().get_node("Lantern/Trail") as CPUParticles3D
	var you: CharacterModel = _underwater_set().get_node("Castaway/Character") as CharacterModel

	# Through the surface at full strength, bubbles streaming off him.
	await physics_ticks(runner, 60)
	assert_str(String(_conversation.section())).is_equal("light")
	assert_float(face.strength).is_greater(0.9)
	assert_bool(trail.emitting).is_true()

	# The dive costs him nothing yet: he reaches you still warm, his door
	# shut and no hand offered, and speaks to you. You don't answer.
	assert_bool(await _reaches(runner, &"finds_you")).is_true()
	assert_float(face.strength).is_greater(0.85)
	assert_float(face.door).is_less(0.1)
	assert_float(hand.reach).is_equal(0.0)
	assert_bool(await _line_shows(runner, said, 1)).is_true()
	assert_str(_conversation.box.line_text()).is_equal("Hello?")
	assert_bool(you.eyes_shut).is_true()

	# He checks your face, tries to lift you, looks up at the surface, and then
	# opens his door: his flame makes a hand, and holds it out, steady.
	assert_bool(await _read_on_until(runner, said, &"reach", 0)).is_true()
	await physics_ticks(runner, 300)
	assert_bool(underwater.is_open).is_true()
	assert_str(prompt.shown_text()).contains("Take his hand")
	assert_float(face.strength).is_greater(0.8)
	assert_float(face.door).is_equal_approx(1.0, 0.01)
	assert_bool(face.cracked).is_false()
	assert_float(hand.reach).is_greater(0.8)
	# It never fails while he waits: the hand keeps its shape.
	var weakest: float = 1.0
	for i: int in 400:
		weakest = minf(weakest, hand.form)
		await physics_ticks(runner, 1)
	assert_float(weakest).is_greater(0.9)
	# You're out cold and floating; only your hand will move.
	assert_bool(you.eyes_shut).is_true()
	assert_float(you.reach).is_equal(0.0)
	assert_float(you.afloat).is_equal(1.0)
	# What he says can be seen: the dialogue box is drawn over the water.
	var box_layer: CanvasLayer = _conversation.box.get_parent() as CanvasLayer
	assert_object(box_layer).is_not_null()
	assert_int(box_layer.layer).is_greater(underwater.layer)


func test_his_light_pours_into_you_the_deep_stirs_and_he_lets_go_to_white() -> void:
	_build(&"reach")
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	var said: Array[int] = [0]
	_conversation.line_said.connect(func(_speaker: Person) -> void: said[0] += 1)
	var underwater: Stage = _sea.get_node("Stages/Underwater") as Stage
	var heron: Crewmate = _ship.get_node("Crew/Heron") as Crewmate
	var face: LanternFace = _sinking_lantern()
	var hand: FlameHand = _underwater_set().get_node("Lantern/Hand") as FlameHand
	var you: CharacterModel = _underwater_set().get_node("Castaway/Character") as CharacterModel
	var flow: LightFlow = _underwater_set().get_node("Flow") as LightFlow
	var drain: LightFlow = _underwater_set().get_node("Drain") as LightFlow
	var field: LanternField = _underwater_set().get_node("Lanterns") as LanternField
	var thing: Node3D = _underwater_set().get_node("Thing") as Node3D
	var lightning: Lightning = _sea.get_node("Weather/Lightning") as Lightning
	var strikes: Array[int] = []
	lightning.struck.connect(func() -> void: strikes.append(1))
	await physics_ticks(runner, 300)

	# Taking his hand brings a brief conscious response before his light flows.
	_conversation.press()
	assert_bool(await _reaches(runner, &"it_catches")).is_true()
	await physics_ticks(runner, 70)
	assert_float(hand.grip).is_equal_approx(1.0, 0.01)
	assert_float(you.reach).is_equal_approx(1.0, 0.01)
	assert_bool(you.eyes_shut).is_false()
	assert_float(face.strength).is_greater(0.95)
	assert_float(flow.flow).is_equal(0.0)
	assert_float(drain.flow).is_equal(0.0)

	# Then his light pours out of his hand into you: the flow runs, you fill,
	# and he fades. A thinner thread of it sinks away to the lanterns far
	# below (#203).
	assert_bool(await _read_on_until(runner, said, &"it_flows")).is_true()
	await physics_ticks(runner, 200)
	assert_float(flow.flow).is_greater(0.5)
	assert_float(flow.filled).is_greater(0.2)
	assert_float(face.strength).is_less(0.95)
	assert_float(drain.flow).is_greater(0.2)
	assert_float(drain.to.global_position.y).is_less(drain.from.global_position.y - 3.0)

	# He pulls back and it holds; the lanterns all round flicker; the thing
	# passes far below, shown twice in the lightning.
	var thing_was: Vector3 = thing.global_position
	assert_bool(await _read_on_until(runner, said, &"the_deep_stirs")).is_true()
	var most_flicker: float = 0.0
	for i: int in 420:
		most_flicker = maxf(most_flicker, field.flicker)
		await physics_ticks(runner, 1)
	assert_float(most_flicker).is_greater(0.9)
	assert_int(strikes.size()).is_greater_equal(2)
	assert_float(thing.global_position.distance_to(thing_was)).is_greater(40.0)
	assert_float(thing.global_position.y).is_less(-30.0)
	assert_float(face.strength).is_less(0.5)

	# He looks back at you, nearly out, and lets the last of it go: gold,
	# then white, and silence.
	assert_bool(await _read_on_until(runner, said, &"lets_go")).is_true()
	assert_float(face.strength).is_less(0.35)
	assert_float(drain.flow).is_equal(0.0)
	assert_bool(await _read_on_until(runner, said, &"asleep")).is_true()
	assert_bool(_fade().is_white()).is_true()
	assert_bool(_ambience().hushed).is_true()
	assert_float(flow.filled).is_equal_approx(1.0, 0.01)

	# No surface and no rail: from the white to black, and the bunk room,
	# where the captain stands at the foot of your bunk.
	assert_bool(underwater.is_open).is_false()
	assert_vector(heron.global_position).is_equal_approx(_mark("bedside").global_position, NEAR)
	for i: int in 240:
		if _fade().is_covering() and not _fade().is_white():
			break
		await physics_ticks(runner, 1)
	assert_bool(_fade().is_covering()).is_true()
	assert_bool(_fade().is_white()).is_false()
	assert_bool(await _reaches(runner, &"waking")).is_true()
	assert_bool(_ambience().hushed).is_false()


func test_you_wake_the_captain_and_the_weak_lantern_talk_and_then_the_ship_is_yours() -> void:
	_build(&"asleep")
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	var heron: Crewmate = _ship.get_node("Crew/Heron") as Crewmate
	var rig: CameraRig = _player.camera_rig
	var sleeping: Node3D = _ship.get_node("WakingSet/Props/SleepingYou") as Node3D
	var you_asleep: CharacterModel = sleeping.get_node("Character") as CharacterModel
	var spirit: LanternSpirit = _player.get_node("LanternSpirit") as LanternSpirit
	var your_body: Node3D = _player.get_node("Model") as Node3D
	var quest: FirstQuest = _sea.get_node("FirstQuest") as FirstQuest
	var walker: CrewWalker = heron.get_node("Walker") as CrewWalker
	var tries: Marker3D = _mark("lantern_tries")
	var said: Array[int] = [0]
	var lines: PackedStringArray = PackedStringArray()
	var speakers: PackedStringArray = PackedStringArray()
	_conversation.line_said.connect(func(speaker: Person) -> void:
		said[0] += 1
		lines.append(_conversation.box.line_text())
		speakers.append(String(speaker.id) if speaker != null else ""))
	var replies: PackedStringArray = PackedStringArray()
	_conversation.choice_made.connect(func() -> void:
		replies.append(_conversation.box.shown_choices()[_conversation.selected_choice()]))

	# Out of the black: you, asleep in your bunk, and the captain by its
	# head, watching over you. The lantern is beside you, home on the little
	# table by your bunk (#206), low (#158), his glass whole (#183).
	var bedside: Node3D = _mark("bedside")
	var perch: Node3D = _ship.get_node("BunkRoom/LanternPerch/Perch") as Node3D
	assert_bool(await _reaches(runner, &"waking")).is_true()
	assert_bool(_fade().visible).is_false()
	assert_bool(heron.is_present()).is_true()
	assert_vector(heron.global_position).is_equal_approx(bedside.global_position, NEAR)
	assert_bool(sleeping.visible).is_true()
	assert_bool(your_body.visible).is_false()
	assert_object(spirit.held).is_null()
	assert_object(spirit.home).is_same(perch)
	assert_float(perch.global_position.distance_to(sleeping.global_position)).is_less(1.6)
	assert_bool(spirit.is_low()).is_true()
	assert_bool(spirit.face().cracked).is_false()
	assert_bool(rig.is_fixed).is_true()

	# You wake on your own: your eyes open before anyone says a word.
	await physics_ticks(runner, 70)
	assert_bool(you_asleep.eyes_shut).is_false()
	assert_int(said[0]).is_equal(0)

	# Still lying down, on a shot of you in your bunk, the captain speaks
	# first (#206).
	assert_bool(await _reaches(runner, &"you_look_up")).is_true()
	assert_bool(await _line_shows(runner, said, 1)).is_true()
	assert_str(lines[0]).is_equal("Ah. You're awake.")
	assert_object(rig.held_shot()).is_same(_shot("you_lying_down"))
	assert_bool(sleeping.visible).is_true()
	assert_bool(your_body.visible).is_false()

	# You're up, and he's still there by your bunk, facing you, on a fixed
	# shot: no calling across the room.
	assert_bool(await _read_on_until(runner, said, &"by_your_bunk", 0)).is_true()
	assert_bool(heron.is_present()).is_true()
	assert_vector(heron.global_position).is_equal_approx(bedside.global_position, NEAR)
	assert_float(heron.global_position.distance_to(_player.global_position)).is_less(3.0)
	assert_bool(sleeping.visible).is_false()
	var seated: Node3D = _ship.get_node("WakingSet/Props/SeatedYou") as Node3D
	assert_bool(seated.visible).is_true()
	await physics_ticks(runner, 110)
	assert_bool(your_body.visible).is_true()
	assert_bool(seated.visible).is_false()

	# Read on, answering when asked. Low as he is, the lantern talks; he
	# tries to float over to you and sinks back home.
	var floated: bool = false
	var pressed: int = said[0] - 1
	var answered_after: int = -1
	var facing_him: Marker3D = _shot("facing_him")
	var asked_facing: Array[bool] = [false]
	_conversation.choices_offered.connect(func() -> void:
		# When he asks what you remember, you face him, and the shot sees
		# your face, not the back of your head (#206).
		var to_camera: Vector3 = facing_him.global_position - _player.global_position
		to_camera.y = 0.0
		var to_heron: Vector3 = heron.global_position - _player.global_position
		to_heron.y = 0.0
		asked_facing[0] = _player.facing.dot(to_camera.normalized()) > 0.0 \
				and _player.facing.dot(to_heron.normalized()) > 0.8)
	for i: int in 3600:
		if not _opening.is_playing:
			break
		if spirit.held == tries:
			floated = true
		# The box goes on showing a reply until the next line: answer once.
		if _conversation.box.shown_choices().size() > 0 and answered_after != said[0]:
			answered_after = said[0]
			await physics_ticks(runner, 2)
			_press()
			await physics_ticks(runner, 2)
		elif said[0] > pressed:
			await physics_ticks(runner, 2)
			pressed = said[0]
			_press()
		await physics_ticks(runner, 1)
	assert_bool(floated).is_true()
	assert_bool(asked_facing[0]).is_true()
	assert_object(spirit.held).is_null()
	assert_bool(speakers.has("lantern")).is_true()
	assert_bool(lines.has("Oh. That's not ideal.")).is_true()
	# You've nothing to tell him: the replies are things you do.
	assert_array(Array(replies)).is_equal(["(Shake your head)", "(Say nothing)", "(Say nothing)",
			"(Look down)"])
	# Last, the lantern points you to your book, on his table (#206).
	assert_str(lines[lines.size() - 1]).contains("your book")

	# Then the ship is yours, and the captain sets off up to the helm (#186).
	assert_bool(_opening.is_playing).is_false()
	assert_bool(_conversation.is_active()).is_false()
	assert_bool(_player.controls_enabled).is_true()
	assert_bool(rig.is_fixed).is_false()
	assert_bool(heron.is_present()).is_true()
	await physics_ticks(runner, 2)
	assert_bool(quest.is_heading_to_helm).is_true()
	assert_bool(walker.is_walking).is_true()
	# He's still low once it's over, his glass whole.
	assert_bool(spirit.is_low()).is_true()
	assert_bool(spirit.face().cracked).is_false()


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
	# Up and about: not asleep in the bunk, and him not kept anywhere.
	assert_bool((_ship.get_node("WakingSet/Props/SleepingYou") as Node3D).visible).is_false()
	assert_bool((_player.get_node("Model") as Node3D).visible).is_true()
	assert_object((_player.get_node("LanternSpirit") as LanternSpirit).held).is_null()
	# The captain is about, setting off up to the helm (#186), and the lantern
	# is low (#158).
	assert_bool(heron.is_present()).is_true()
	assert_bool((_sea.get_node("FirstQuest") as FirstQuest).is_heading_to_helm).is_true()
	assert_bool(Game.dialogue.is_set(LanternSpirit.LOW_FLAG)).is_true()
	var at: Vector3 = _ship.to_local(_player.global_position)
	assert_float(at.distance_to(_ship.to_local(_mark("bunk_stand").global_position))) \
			.is_less(0.6)
	assert_bool((_ship.get_node("WakingSet/Props/SeatedYou") as Node3D).visible).is_false()


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
	await _choose_voyage(runner, CONTINUE)
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


func test_a_voyage_saved_at_the_island_carries_on_there() -> void:
	Game.dialogue.set_flag(Bedside.ARRIVED_FLAG)
	SaveGame.write(SaveGame.capture(null, 1.0, Game.dialogue))
	Game.dialogue.reset()
	_build(DialogueTree.START, true)
	_opening.title_seconds = 0.2
	# Heard, rather than really going (that would replace the test's scene).
	_opening.island_scene = ""
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	await physics_ticks(runner, 240)

	runner.simulate_key_pressed(KEY_ENTER)
	await _choose_voyage(runner, CONTINUE)

	assert_bool(await wait_for_signal(_opening.went_ashore, 20.0)).is_true()
	assert_bool(Game.dialogue.is_set(Bedside.ARRIVED_FLAG)).is_true()


func test_everything_the_intro_asks_for_is_in_the_scene() -> void:
	_build()
	_opening.skip = true
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	await physics_ticks(runner, 3)
	assert_bool(_opening.is_playing).is_false()
	var shots: ShotCues = _sea.get_node("Story/ShotCues") as ShotCues
	var actors: ActorCues = _sea.get_node("Story/ActorCues") as ActorCues
	var stages: StageCues = _sea.get_node("StageCues") as StageCues
	var clips: ClipCues = _sea.get_node("Story/ClipCues") as ClipCues
	var sounds: SoundCues = _sea.get_node("Story/SoundCues") as SoundCues
	var looks: LookCues = _sea.get_node("Story/LookCues") as LookCues
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
			&"play", &"start", &"queue":
				found = clips.find_player(StringName(word))
			&"look":
				found = looks.find_face(word)
			&"sound":
				found = sounds.find_sound(word)
				# One that's still waiting for its recording is allowed to be silent.
				if found != null and not found is OptionalSound:
					assert_object((found as AudioStreamPlayer).stream).override_failure_message(
							"intro.dlg, line %d: the sound '%s' has no recording"
							% [step.line_number, word]).is_not_null()
		assert_object(found).override_failure_message("intro.dlg, line %d: there's no '%s' for @%s"
				% [step.line_number, word, step.cue]).is_not_null()
		checked += 1
	assert_int(checked).is_greater(30)


func test_it_can_open_on_a_later_beat_with_no_black_screen() -> void:
	_build(&"by_your_bunk")
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	await physics_ticks(runner, 5)

	assert_str(String(_conversation.section())).is_equal("by_your_bunk")
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


func test_after_the_title_a_new_voyage_asks_who_you_are() -> void:
	_build()
	_choice_cues().ask = true
	var choice: LookChoice = _sea.get_node("LookChoice") as LookChoice
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	# Her name, waiting for a button; nothing asked yet.
	await physics_ticks(runner, 240)
	assert_bool(choice.is_open()).is_false()

	runner.simulate_key_pressed(KEY_ENTER)

	# Asked over her name, and the intro waits for the answer.
	assert_bool(await _reaches(runner, &"who_are_you")).is_true()
	await physics_ticks(runner, 60)
	assert_bool(choice.is_open()).is_true()
	assert_str(String(_conversation.section())).is_equal("who_are_you")

	choice.choose(PlayerLook.Body.GIRL)

	assert_int(Game.look).is_equal(PlayerLook.Body.GIRL)
	assert_bool(await _reaches(runner, &"the_stern")).is_true()
	assert_bool(choice.is_open()).is_false()


func test_a_continued_voyage_isnt_asked_who_you_are() -> void:
	SaveGame.write({"version": SaveGame.VERSION, "memories": [], "day": 2,
			"morning": true, "warmth": 1.0, "look": "girl"})
	_build(DialogueTree.START, true)
	_choice_cues().ask = true
	var choice: LookChoice = _sea.get_node("LookChoice") as LookChoice
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	await physics_ticks(runner, 240)

	runner.simulate_key_pressed(KEY_ENTER)
	await _choose_voyage(runner, CONTINUE)

	assert_bool(await _reaches(runner, &"carry_on")).is_true()
	assert_bool(await wait_for_signal(_opening.finished, 20.0)).is_true()
	assert_bool(choice.is_open()).is_false()
	assert_int(Game.look).is_equal(PlayerLook.Body.GIRL)


func test_a_saved_voyage_asks_to_continue_or_start_again_before_loading() -> void:
	SaveGame.write({"version": SaveGame.VERSION, "memories": [], "day": 5,
			"morning": true, "warmth": 0.5})
	_build(DialogueTree.START, true)
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	await physics_ticks(runner, 240)

	runner.simulate_key_pressed(KEY_ENTER)

	assert_bool(await _reaches(runner, &"voyage_menu")).is_true()
	await physics_ticks(runner, 10)
	assert_array(Array(_conversation.box.shown_choices())) \
			.contains_exactly(["Continue your voyage", "Start a new voyage"])
	# Nothing's loaded until it's chosen.
	var time: TimeOfDay = _sea.get_node("TimeOfDay") as TimeOfDay
	assert_int(time.day).is_not_equal(5)


func test_a_new_voyage_asks_who_you_are_and_keeps_the_old_save() -> void:
	SaveGame.write({"version": SaveGame.VERSION, "memories": [], "day": 5,
			"morning": true, "warmth": 0.5, "look": "girl"})
	_build(DialogueTree.START, true)
	_choice_cues().ask = true
	var choice: LookChoice = _sea.get_node("LookChoice") as LookChoice
	var runner: GdUnitSceneRunner = scene_runner(_sea)
	await physics_ticks(runner, 240)

	runner.simulate_key_pressed(KEY_ENTER)
	await _choose_voyage(runner, NEW)

	assert_bool(await _reaches(runner, &"who_are_you")).is_true()
	await physics_ticks(runner, 60)
	assert_bool(choice.is_open()).is_true()
	choice.choose(PlayerLook.Body.BOY)
	assert_bool(await _reaches(runner, &"the_stern")).is_true()
	# The saved voyage wasn't loaded, and is still there until you next sleep.
	var time: TimeOfDay = _sea.get_node("TimeOfDay") as TimeOfDay
	assert_int(time.day).is_not_equal(5)
	assert_int(Game.look).is_equal(PlayerLook.Body.BOY)
	assert_bool(SaveGame.exists()).is_true()


func _choice_cues() -> ChoiceCues:
	return _sea.get_node("ChoiceCues") as ChoiceCues


# Presses Interact past any typing: on to the next line.
# Waits until [param said] (a count of lines said) reaches [param line], up
# to ten seconds of ticks. Returns whether it did.
func _line_shows(runner: GdUnitSceneRunner, said: Array[int], line: int) -> bool:
	for i: int in 600:
		if said[0] >= line:
			await physics_ticks(runner, 2)
			return true
		await physics_ticks(runner, 1)
	return false


# Reads the cutscene on, pressing Interact once for each line as it shows,
# until it's reading [param section]. Returns whether it got there within a
# minute of game time. [param pressed_so_far] is how many lines have had
# their press already (all of those said so far, unless given).
func _read_on_until(runner: GdUnitSceneRunner, said: Array[int], section: StringName,
		pressed_so_far: int = -1) -> bool:
	var pressed: int = said[0] if pressed_so_far < 0 else pressed_so_far
	for i: int in 3600:
		if _conversation.section() == section:
			return true
		if said[0] > pressed:
			await physics_ticks(runner, 2)
			pressed = said[0]
			_press()
		await physics_ticks(runner, 1)
	return false


func _heron() -> Crewmate:
	return _ship.get_node("Crew/Heron") as Crewmate


func _mark(mark_name: String) -> Marker3D:
	return (_sea.get_node("Story/ActorCues") as ActorCues).find_mark(mark_name)


func _shot(shot_name: String) -> Marker3D:
	return (_sea.get_node("Story/ShotCues") as ShotCues).find_shot(shot_name)


func _sea_surface() -> Sea:
	return _sea.get_node("SeaSurface") as Sea


# The Grave of the Lanterns' set, inside its stage.
func _grave_set() -> Node:
	return _sea.get_node("Stages/Grave/View/World/Set")


func _press() -> void:
	var box: DialogueBox = _conversation.box
	if box != null and box.is_typing():
		box.finish_typing()
	_conversation.press()


# Waits for the title's menu, then picks [param which] (CONTINUE or NEW).
func _choose_voyage(runner: GdUnitSceneRunner, which: int) -> void:
	assert_bool(await _reaches(runner, &"voyage_menu")).is_true()
	await physics_ticks(runner, 10)
	_conversation.move_choice(which)
	_press()


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


# The set you sink through, inside its stage.
func _underwater_set() -> Node:
	return _sea.get_node("Stages/Underwater/View/World/Set")


# The lantern who comes down for you.
func _sinking_lantern() -> LanternFace:
	return _underwater_set().get_node("Lantern/Body") as LanternFace


func _fade() -> ScreenFade:
	return _opening.get_node("ScreenFade") as ScreenFade


func _ambience() -> Ambience:
	return _sea.get_node("Weather/Ambience") as Ambience


# The real sea scene, not yet running, with its opening set to begin at
# [param section] and to ignore any saved voyage unless [param load_save].
# It doesn't ask who you are (that has tests of its own).
# Called at the start of each test, so it's made (and freed) inside it.
func _build(section: StringName = DialogueTree.START, load_save: bool = false) -> void:
	_sea = (load(SEA) as PackedScene).instantiate()
	auto_free(_sea)
	_opening = _sea.get_node("Opening") as Opening
	_opening.start_section = section
	_opening.load_save = load_save
	_choice_cues().ask = false
	_ship = _sea.get_node("Ship") as Ship
	_player = _sea.get_node("Player") as Player3D
	_conversation = _sea.get_node("Story/Conversation") as Conversation
