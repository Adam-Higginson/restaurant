extends GameTestSuite
## Tests for KeepsFacing, which keeps the lantern turned to you through the
## underwater rescue (#203): his front (-Z) turns to the target, his clips'
## tip and roll stay, it wins over a clip that turns him, and off it leaves
## him be.

var _world: Node3D
var _turned: Node3D
var _target: Node3D
var _facing: KeepsFacing


func test_his_front_turns_to_the_target() -> void:
	_build()
	_target.position = Vector3(3, 1, 0)

	_facing.face_now()

	var front: Vector3 = -_turned.global_basis.z
	assert_vector(front).is_equal_approx(Vector3(1, 0, 0), Vector3(0.001, 0.001, 0.001))


func test_his_tip_and_roll_stay_as_they_were() -> void:
	_build()
	_turned.rotation = Vector3(0.3, 2.0, -0.1)
	_target.position = Vector3(0, 0, -4)

	_facing.face_now()

	assert_float(_turned.rotation.x).is_equal_approx(0.3, 0.001)
	assert_float(_turned.rotation.z).is_equal_approx(-0.1, 0.001)
	assert_float(_turned.rotation.y).is_equal_approx(0.0, 0.001)


func test_switched_off_it_leaves_him_be() -> void:
	_build()
	_turned.rotation.y = 2.0
	_facing.enabled = false

	_facing.face_now()

	assert_float(_turned.rotation.y).is_equal_approx(2.0, 0.001)


func test_a_clip_that_turns_him_away_cant() -> void:
	_build()
	_target.position = Vector3(-3, 0, 0)
	var clips: AnimationPlayer = _turning_clip()
	_facing.clips = clips

	clips.play(&"clips/turns_away")
	for i: int in 6:
		await get_tree().process_frame

	# The clip tips him (x) and would turn him to 2.0; he faces -X instead.
	assert_float(_turned.rotation.x).is_equal_approx(0.4, 0.001)
	assert_float(_turned.rotation.y).is_equal_approx(PI / 2.0, 0.001)


# A lantern (Turned) and a target in a world of their own, and the
# KeepsFacing joining them.
func _build() -> void:
	_world = Node3D.new()
	auto_free(_world)
	add_child(_world)
	_turned = Node3D.new()
	_turned.name = "Turned"
	_world.add_child(_turned)
	_target = Node3D.new()
	_world.add_child(_target)
	_target.position = Vector3(0, 0, -2)
	_facing = KeepsFacing.new()
	_facing.turned = _turned
	_facing.target = _target
	_world.add_child(_facing)


# An AnimationPlayer with a clip that holds Turned tipped and turned away.
func _turning_clip() -> AnimationPlayer:
	var clip: Animation = Animation.new()
	clip.length = 1.0
	var track: int = clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, NodePath("Turned:rotation"))
	clip.track_insert_key(track, 0.0, Vector3(0.4, 2.0, 0.0))
	clip.track_insert_key(track, 1.0, Vector3(0.4, 2.0, 0.0))
	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation(&"turns_away", clip)
	var player: AnimationPlayer = AnimationPlayer.new()
	_world.add_child(player)
	player.root_node = NodePath("..")
	player.add_animation_library(&"clips", library)
	return player
