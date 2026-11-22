class_name PlayerLook
extends RefCounted
## Who the player is: a boy or a girl, chosen when a new voyage begins
## ([LookChoice]) and kept in the save. [CharacterModel] dresses the player to
## match. The game holds the choice in [member GameState.look].

enum Body {
	BOY,
	GIRL,
}


## [param body] as a word for the save file.
static func to_text(body: Body) -> String:
	return "girl" if body == Body.GIRL else "boy"


## The body saved as [param text]. Anything unknown is a boy, the first choice.
static func from_text(text: String) -> Body:
	return Body.GIRL if text == "girl" else Body.BOY
