class_name HeldItemLabel3D
extends Label
## Names what the 3D player holds and its quality, e.g. "Sliced Tomato ★★",
## or "Plate: Garden Salad ★★★" for a plate. Empty with free hands.
##
## Display only: it reads the player's [Arms] and updates when they change.
## [Hud3D] hands it the player. The wording comes from the legacy 2D
## [method HeldItemLabel.describe], so both games read the same.

var _player: Player3D = null


## Starts showing what [param player] holds.
func setup(player: Player3D) -> void:
	_player = player
	_player.arms.changed.connect(_update)
	_update()


func _update() -> void:
	var held: ItemInstance = _player.arms.top()
	text = "" if held == null else HeldItemLabel.describe(held)
