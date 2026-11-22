extends GameTestSuite
## Tests for LookChoice, the "Who are you?" screen: it shows when asked,
## either button answers and closes it, and once closed it can't answer again.


func after_test() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_it_is_hidden_until_asked() -> void:
	var choice: LookChoice = _new_choice()

	assert_bool(choice.is_open()).is_false()
	choice.ask()
	assert_bool(choice.is_open()).is_true()


func test_each_button_answers_and_closes_it() -> void:
	for button: String in ["BoyButton", "GirlButton"]:
		var choice: LookChoice = _new_choice()
		var answers: Array[PlayerLook.Body] = []
		choice.chosen.connect(func(body: PlayerLook.Body) -> void: answers.append(body))
		choice.ask()

		(choice.find_child(button) as Button).pressed.emit()

		var expected: PlayerLook.Body = PlayerLook.Body.BOY if button == "BoyButton" \
				else PlayerLook.Body.GIRL
		assert_array(answers).is_equal([expected])
		assert_bool(choice.is_open()).is_false()


func test_once_closed_it_cant_answer_again() -> void:
	var choice: LookChoice = _new_choice()
	var answers: Array[int] = [0]
	choice.chosen.connect(func(_body: PlayerLook.Body) -> void: answers[0] += 1)
	choice.ask()

	choice.choose(PlayerLook.Body.GIRL)
	choice.choose(PlayerLook.Body.BOY)

	assert_int(answers[0]).is_equal(1)


func _new_choice() -> LookChoice:
	var choice: LookChoice = (load("res://ui/look_choice.tscn") as PackedScene).instantiate() \
			as LookChoice
	add_child(choice)
	auto_free(choice)
	return choice
