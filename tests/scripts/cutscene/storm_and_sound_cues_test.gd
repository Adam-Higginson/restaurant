extends GameTestSuite
## Tests for the storm on cue (@muffle, @lightning) and one-off sounds
## (@sound): the weather sounds as it does underwater and is always put
## back, lightning strikes when asked, and a sound plays unless the
## cutscene is being skipped.

const WEATHER: PackedScene = preload("res://scenes/prototype/weather/weather.tscn")

var _player: Player3D
var _conversation: Conversation
var _weather: Weather
var _sounds: SoundCues
var _splash: AudioStreamPlayer
## How many times the splash has been played.
var _played: int


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_muffle_puts_the_weather_underwater_and_off_brings_it_back() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var ambience: Ambience = _weather.get_node("Ambience") as Ambience

	play_cutscene(_conversation, _player, "@muffle on\nheron: Under.\n@muffle off\nheron: Up.")
	assert_bool(ambience.submerged).is_true()
	await physics_ticks(runner, 40)
	assert_float(ambience.mix.depth).is_equal(1.0)

	_conversation.press()
	assert_bool(ambience.submerged).is_false()
	await physics_ticks(runner, 40)
	assert_float(ambience.mix.depth).is_equal(0.0)


func test_the_sound_is_never_left_muffled_when_a_cutscene_ends() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var ambience: Ambience = _weather.get_node("Ambience") as Ambience
	play_cutscene(_conversation, _player, "@muffle on\nheron: Under.")
	assert_bool(ambience.submerged).is_true()

	_conversation.stop()

	assert_bool(ambience.submerged).is_false()


func test_hush_silences_the_weather_and_off_lets_it_back_in() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var ambience: Ambience = _weather.get_node("Ambience") as Ambience
	var bus: int = AudioServer.get_bus_index(Ambience.BUS)

	play_cutscene(_conversation, _player, "@hush on\nheron: Nothing.\n@hush off\nheron: Storm.")
	assert_bool(ambience.hushed).is_true()
	await physics_ticks(runner, 30)
	assert_float(ambience.mix.hush).is_equal(1.0)
	assert_float(AudioServer.get_bus_volume_db(bus)).is_less(-70.0)

	_conversation.press()
	assert_bool(ambience.hushed).is_false()
	await physics_ticks(runner, 30)
	assert_float(AudioServer.get_bus_volume_db(bus)).is_equal_approx(0.0, 0.001)


func test_the_weather_is_never_left_hushed_when_a_cutscene_ends_or_is_skipped() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var ambience: Ambience = _weather.get_node("Ambience") as Ambience
	play_cutscene(_conversation, _player, "@hush on\nheron: Nothing.")
	assert_bool(ambience.hushed).is_true()

	_conversation.stop()
	assert_bool(ambience.hushed).is_false()

	play_cutscene(_conversation, _player, "heron: One.\n@hush on\n@wait 5\nset done")
	_conversation.skip()
	assert_bool(Game.dialogue.is_set(&"done")).is_true()
	assert_bool(ambience.hushed).is_false()


func test_a_sound_with_no_recording_yet_is_silent_without_complaint() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var heartbeat: OptionalSound = OptionalSound.new()
	heartbeat.name = "Heartbeat"
	heartbeat.recording = "res://assets/third_party/audio/not_recorded_yet.ogg"
	_sounds.add_child(heartbeat)

	play_cutscene(_conversation, _player, "@sound heartbeat\nheron: Thump.")

	assert_object(_sounds.find_sound("heartbeat")).is_same(heartbeat)
	assert_bool(heartbeat.playing).is_false()


func test_rain_eases_on_cue_and_stays_eased_after() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	_weather.intensity = 0.8

	play_cutscene(_conversation, _player, "@rain 0.2 1.0
heron: It's easing.")
	await physics_ticks(runner, 20)
	assert_float(_weather.intensity).is_between(0.21, 0.79)
	await physics_ticks(runner, 60)
	assert_float(_weather.intensity).is_equal_approx(0.2, 0.01)
	_conversation.press()
	await physics_ticks(runner, 5)

	assert_bool(_conversation.is_active()).is_false()
	assert_float(_weather.intensity).is_equal_approx(0.2, 0.01)


func test_lightning_strikes_on_cue() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var lightning: Lightning = _weather.get_node("Lightning") as Lightning
	var strikes: Array[int] = []
	lightning.struck.connect(func() -> void: strikes.append(1))

	play_cutscene(_conversation, _player, "@lightning\nheron: Flash.")

	assert_int(strikes.size()).is_equal(1)


func test_a_sound_plays_on_cue_and_the_script_carries_straight_on() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var lines: Array[int] = []
	_conversation.line_said.connect(func(_speaker: Person) -> void: lines.append(1))

	play_cutscene(_conversation, _player, "@sound splash\nheron: Wet.")

	assert_bool(_splash.playing).is_true()
	assert_int(lines.size()).is_equal(1)


func test_nothing_is_played_while_a_cutscene_is_skipped() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "heron: One.\n@sound splash\nset done")

	_conversation.skip()

	assert_bool(Game.dialogue.is_set(&"done")).is_true()
	assert_bool(_splash.playing).is_false()


func test_a_sound_that_isnt_there_is_warned_about() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	await assert_error(func() -> void:
		_sounds.handle(&"sound", PackedStringArray(["thunderclap"]))) \
			.is_push_warning(any_string())

	assert_object(_sounds.find_sound("splash")).is_same(_splash)
	assert_object(_sounds.find_sound("thunderclap")).is_null()


# The player, a conversation, the weather with its storm cues, and the
# sound cues with one sound (a short silent recording). Called at the start
# of each test, so everything is made (and freed) inside it.
func _build() -> void:
	_played = 0
	_player = new_player_3d_on_floor()
	var world: Node = _player.get_parent()
	_conversation = new_conversation(_player)
	_weather = WEATHER.instantiate() as Weather
	world.add_child(_weather)
	var storm: StormCues = StormCues.new()
	storm.weather = _weather
	world.add_child(storm)
	_sounds = SoundCues.new()
	_sounds.name = "SoundCues"
	_splash = AudioStreamPlayer.new()
	_splash.name = "Splash"
	var silence: AudioStreamWAV = AudioStreamWAV.new()
	silence.data = PackedByteArray()
	silence.data.resize(44100)
	_splash.stream = silence
	_splash.volume_db = -80.0
	_sounds.add_child(_splash)
	world.add_child(_sounds)
