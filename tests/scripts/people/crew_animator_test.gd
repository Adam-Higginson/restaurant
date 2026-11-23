extends GameTestSuite
## Tests for a crewmate's animations following what's said: idle when nobody
## talks with them, talking through their own lines (taking the talking
## animations in turn), listening to others in their conversation and while
## you choose, and idle again at the end. The model's file is gitignored, so
## these never need it: a stand-in animation player takes its place.

const HERON: PackedScene = preload("res://scenes/prototype/people/heron.tscn")
const HERON_PERSON: Person = preload("res://data/people/heron.tres")
const LANTERN_PERSON: Person = preload("res://data/people/lantern.tres")

const IDLE: StringName = &"idle"
const TALK_A: StringName = &"talk_a"
const TALK_B: StringName = &"talk_b"
const LISTEN: StringName = &"listen"


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_idles_when_nobody_talks_with_them() -> void:
	var animator: CrewAnimator = _animator()
	assert_int(animator.mood).is_equal(CrewAnimator.Mood.IDLE)
	assert_str(animator.animation).is_equal(IDLE)


func test_talks_through_their_own_line() -> void:
	var animator: CrewAnimator = _animator()
	animator.hear_line(HERON_PERSON)
	assert_int(animator.mood).is_equal(CrewAnimator.Mood.TALK)
	assert_str(animator.animation).is_equal(TALK_A)


func test_takes_the_talking_animations_in_turn_line_by_line() -> void:
	var animator: CrewAnimator = _animator()
	var seen: Array[StringName] = []
	for _line: int in 3:
		animator.hear_line(HERON_PERSON)
		seen.append(animator.animation)
	assert_array(seen).is_equal([TALK_A, TALK_B, TALK_A])


func test_listens_when_someone_else_speaks_in_their_conversation() -> void:
	var animator: CrewAnimator = _animator()
	animator.hear_line(HERON_PERSON)
	animator.hear_line(LANTERN_PERSON)
	assert_int(animator.mood).is_equal(CrewAnimator.Mood.LISTEN)
	assert_str(animator.animation).is_equal(LISTEN)
	# A line from nobody in particular is listened to as well.
	animator.hear_line(HERON_PERSON)
	animator.hear_line(null)
	assert_int(animator.mood).is_equal(CrewAnimator.Mood.LISTEN)


func test_ignores_conversations_they_arent_in() -> void:
	var animator: CrewAnimator = _animator()
	animator.hear_start(null)
	animator.hear_line(LANTERN_PERSON)
	animator.hear_choices()
	assert_int(animator.mood).is_equal(CrewAnimator.Mood.IDLE)


func test_listens_from_the_start_of_a_conversation_begun_with_them() -> void:
	var animator: CrewAnimator = _animator()
	animator.hear_start(animator.crewmate)
	assert_int(animator.mood).is_equal(CrewAnimator.Mood.LISTEN)


func test_waits_on_your_reply_then_idles_when_it_ends() -> void:
	var animator: CrewAnimator = _animator()
	animator.hear_line(HERON_PERSON)
	animator.hear_choices()
	assert_int(animator.mood).is_equal(CrewAnimator.Mood.LISTEN)
	animator.hear_end()
	assert_int(animator.mood).is_equal(CrewAnimator.Mood.IDLE)
	# A fresh conversation starts the talking animations from the first again.
	animator.hear_line(HERON_PERSON)
	assert_str(animator.animation).is_equal(TALK_A)


func test_plays_the_models_animations_and_loops_them() -> void:
	var animator: CrewAnimator = _animator()
	var player: AnimationPlayer = _dress_with_stand_in(animator)
	assert_str(player.current_animation).is_equal(IDLE)
	for clip: StringName in [IDLE, TALK_A, TALK_B, LISTEN]:
		assert_int(player.get_animation(clip).loop_mode).is_equal(Animation.LOOP_LINEAR)

	animator.hear_line(HERON_PERSON)
	assert_str(player.current_animation).is_equal(TALK_A)
	animator.hear_end()
	assert_str(player.current_animation).is_equal(IDLE)


func test_a_missing_animation_leaves_the_last_one_playing() -> void:
	var animator: CrewAnimator = _animator()
	var player: AnimationPlayer = _dress_with_stand_in(animator)
	animator.listen_animation = &"not_in_the_file"
	animator.hear_line(HERON_PERSON)
	animator.hear_choices()
	assert_int(animator.mood).is_equal(CrewAnimator.Mood.LISTEN)
	assert_str(player.current_animation).is_equal(TALK_A)


func test_the_heron_talks_in_a_running_conversation_and_idles_after() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var heron: Crewmate = HERON.instantiate() as Crewmate
	heron.position = Vector3(0, 0, -1.2)
	player.get_parent().add_child(heron)
	var conversation: Conversation = new_conversation(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 3)
	var animator: CrewAnimator = heron.get_node("Animator") as CrewAnimator
	assert_int(animator.mood).is_equal(CrewAnimator.Mood.IDLE)

	var tree: DialogueTree = DialogueScript.parse("heron: Aye.\nlantern: Hello!", &"test")
	assert_bool(conversation.begin_tree(tree, player, heron)).is_true()
	assert_int(animator.mood).is_equal(CrewAnimator.Mood.TALK)
	conversation.press()
	assert_int(animator.mood).is_equal(CrewAnimator.Mood.LISTEN)

	conversation.stop()
	assert_int(animator.mood).is_equal(CrewAnimator.Mood.IDLE)


# An animator for the heron with stand-in animation names and no model yet.
func _animator() -> CrewAnimator:
	var crewmate: Crewmate = Crewmate.new()
	auto_free(crewmate)
	crewmate.person = HERON_PERSON
	var animator: CrewAnimator = CrewAnimator.new()
	auto_free(animator)
	animator.crewmate = crewmate
	animator.idle_animation = IDLE
	animator.talk_animations = [TALK_A, TALK_B]
	animator.listen_animation = LISTEN
	animator.blend_seconds = 0.0
	return animator


# Gives [param animator] a model holding an animation player with the
# stand-in animations, as the model's file would, and returns the player.
func _dress_with_stand_in(animator: CrewAnimator) -> AnimationPlayer:
	var model: ThirdPartyModel = ThirdPartyModel.new()
	auto_free(model)
	add_child(model)
	var body: Node3D = Node3D.new()
	var player: AnimationPlayer = AnimationPlayer.new()
	body.add_child(player)
	var library: AnimationLibrary = AnimationLibrary.new()
	for clip: StringName in [IDLE, TALK_A, TALK_B, LISTEN]:
		var animation: Animation = Animation.new()
		animation.length = 1.0
		library.add_animation(clip, animation)
	player.add_animation_library(&"", library)
	model.add_child(body)
	model.model = body
	animator.model = model
	add_child(animator)
	return player
