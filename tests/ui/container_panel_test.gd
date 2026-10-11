extends GameTestSuite
## Tests for ContainerPanel, which lists a container's food and moves the
## picked piece onto the player's arms.

const CONTAINER_PANEL_SCENE: String = "res://ui/container_panel.tscn"

var _tomato: Item
var _onion: Item
var _contents: StorageContents
var _arms: Arms


func before_test() -> void:
	var catalog: Catalog = Catalog.load_default()
	_tomato = catalog.find_item(&"tomato")
	_onion = catalog.find_item(&"onion")
	_contents = StorageContents.new(Item.StorageKind.FRIDGE, 12)
	_arms = Arms.new()


func after_test() -> void:
	# A failing test could leave the game paused, which would stall later suites.
	get_tree().paused = false


# --- Opening ------------------------------------------------------------------

func test_starts_hidden() -> void:
	var panel: ContainerPanel = _new_panel()
	assert_bool(panel.is_open()).is_false()


func test_open_shows_the_title_and_pauses_the_game() -> void:
	var panel: ContainerPanel = _new_panel()
	panel.open("Fridge", _contents, _arms)
	assert_bool(panel.is_open()).is_true()
	assert_str((panel.find_child("Title") as Label).text).is_equal("Fridge")
	assert_bool(get_tree().paused).is_true()


func test_keeps_working_while_the_game_is_paused() -> void:
	assert_int(_new_panel().process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)


func test_one_row_per_item_and_quality_in_arrival_order() -> void:
	_contents.add(ItemInstance.new(_tomato, 1))
	_contents.add(ItemInstance.new(_onion, 1))
	_contents.add(ItemInstance.new(_tomato, 2))
	_contents.add(ItemInstance.new(_tomato, 1))
	var panel: ContainerPanel = _new_panel()
	panel.open("Fridge", _contents, _arms)
	assert_array(_texts(panel)).contains_exactly(["Tomato ★ ×2", "Onion ★ ×1", "Tomato ★★ ×1"])


func test_empty_container_says_so() -> void:
	var panel: ContainerPanel = _new_panel()
	panel.open("Fridge", _contents, _arms)
	assert_array(panel.get_rows()).is_empty()
	assert_str(_status(panel).text).is_equal("Empty")
	assert_bool(_status(panel).visible).is_true()
	assert_bool(_button(panel, "CloseButton").has_focus()).is_true()


func test_first_row_has_focus_so_a_controller_can_pick() -> void:
	_contents.add(ItemInstance.new(_tomato))
	_contents.add(ItemInstance.new(_onion))
	var panel: ContainerPanel = _new_panel()
	panel.open("Fridge", _contents, _arms)
	assert_bool(panel.get_rows()[0].has_focus()).is_true()
	assert_bool(_status(panel).visible).is_false()


# --- Taking -------------------------------------------------------------------

func test_picking_a_row_moves_one_piece_onto_the_arms() -> void:
	var tomato: ItemInstance = ItemInstance.new(_tomato, 2)
	_contents.add(tomato)
	_contents.add(ItemInstance.new(_tomato, 2))
	var panel: ContainerPanel = _new_panel()
	panel.open("Fridge", _contents, _arms)

	panel.get_rows()[0].pressed.emit()

	assert_object(_arms.top()).is_same(tomato)
	assert_int(_contents.size()).is_equal(1)
	assert_array(_texts(panel)).contains_exactly(["Tomato ★★ ×1"])
	assert_bool(panel.is_open()).is_true()


func test_taking_the_last_of_a_row_moves_focus_to_the_next() -> void:
	_contents.add(ItemInstance.new(_tomato))
	_contents.add(ItemInstance.new(_onion))
	var panel: ContainerPanel = _new_panel()
	panel.open("Fridge", _contents, _arms)

	panel.get_rows()[0].pressed.emit()

	assert_array(_texts(panel)).contains_exactly(["Onion ★ ×1"])
	assert_bool(panel.get_rows()[0].has_focus()).is_true()


func test_full_arms_disable_the_rows() -> void:
	_contents.add(ItemInstance.new(_tomato))
	for i: int in Arms.CAPACITY:
		_arms.add(ItemInstance.new(_onion))
	var panel: ContainerPanel = _new_panel()
	panel.open("Fridge", _contents, _arms)

	assert_bool(panel.get_rows()[0].disabled).is_true()
	assert_str(_status(panel).text).is_equal("Arms full")
	assert_bool(_button(panel, "CloseButton").has_focus()).is_true()


func test_filling_the_arms_while_open_disables_the_rows() -> void:
	for i: int in Arms.CAPACITY + 1:
		_contents.add(ItemInstance.new(_tomato))
	var panel: ContainerPanel = _new_panel()
	panel.open("Fridge", _contents, _arms)

	for i: int in Arms.CAPACITY:
		panel.get_rows()[0].pressed.emit()

	assert_int(_arms.size()).is_equal(Arms.CAPACITY)
	assert_int(_contents.size()).is_equal(1)
	assert_bool(panel.get_rows()[0].disabled).is_true()


# --- Closing ------------------------------------------------------------------

func test_close_button_closes_and_unpauses() -> void:
	var panel: ContainerPanel = _new_panel()
	var closed: Array[bool] = []
	panel.closed.connect(func() -> void: closed.append(true))
	panel.open("Fridge", _contents, _arms)

	_button(panel, "CloseButton").pressed.emit()

	assert_bool(panel.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()
	assert_array(closed).has_size(1)


func test_cancel_closes() -> void:
	var panel: ContainerPanel = _new_panel()
	panel.open("Fridge", _contents, _arms)
	var cancel: InputEventAction = InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	panel._unhandled_input(cancel)
	assert_bool(panel.is_open()).is_false()


func test_stops_listening_once_closed() -> void:
	var panel: ContainerPanel = _new_panel()
	panel.open("Fridge", _contents, _arms)
	panel.close()
	assert_bool(_contents.changed.is_connected(panel._refresh)).is_false()
	assert_bool(_arms.changed.is_connected(panel._refresh)).is_false()
	# Changes after closing don't touch the hidden panel.
	_contents.add(ItemInstance.new(_tomato))
	assert_array(panel.get_rows()).is_empty()


func test_describe() -> void:
	assert_str(ContainerPanel.describe(_tomato, 3, 4)).is_equal("Tomato ★★★ ×4")


func _new_panel() -> ContainerPanel:
	var scene: PackedScene = load(CONTAINER_PANEL_SCENE) as PackedScene
	var panel: ContainerPanel = scene.instantiate() as ContainerPanel
	add_child(panel)
	auto_free(panel)
	return panel


func _texts(panel: ContainerPanel) -> Array[String]:
	var texts: Array[String] = []
	for button: Button in panel.get_rows():
		texts.append(button.text)
	return texts


func _status(panel: ContainerPanel) -> Label:
	return panel.find_child("Status") as Label


func _button(panel: ContainerPanel, button_name: String) -> Button:
	return panel.find_child(button_name) as Button
