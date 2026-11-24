class_name VesselLook
extends RefCounted
## How the inside of a pot, pan or bowl looks right now, read from its
## reactions (#207): what the liquid is becoming, and how far.
##
## A reaction whose result is a liquid (water boiling, tomato soup) is
## matched as soon as everything it needs is in, and progresses while its
## element is there (the fire). So:
## - Matched, even off the heat, the liquid is already tinted a little
##   towards the result: tomato water ([constant FIRST_TINT]).
## - As it progresses, the liquid blends the rest of the way to the result's
##   colour, and the food it's using up shrinks into it ([constant SHRINK]).
## - With nothing reacting, the liquid is its own colour and food is whole.
##
## Plain logic with no nodes: [ItemModel] draws from it, and its rules are
## tested without a scene. It reads only item colours and the recipe data, so
## any new liquid dish works the same way.

## How far towards its result's colour a liquid is tinted the moment its
## reaction is matched, before any cooking (0 to 1).
const FIRST_TINT: float = 0.3
## How much of a piece of food has melted away by the time its reaction is
## done (0 to 1): it never quite vanishes before the result replaces it.
const SHRINK: float = 0.85


## The liquid in [param contents] (water, soup), or null.
static func liquid_in(contents: VesselContents) -> ItemInstance:
	for piece: ItemInstance in contents.get_contents():
		if piece.item.liquid:
			return piece
	return null


## Whether [param contents] hold a liquid: then nothing can be taken out by
## hand, only ladled out whole (once it's in the soup, it's in, #207).
static func has_liquid(contents: VesselContents) -> bool:
	return liquid_in(contents) != null


## The colour to draw the liquid in [param contents]: its own, tinted
## towards what it's becoming. Clear when there's no liquid.
static func liquid_colour(contents: VesselContents) -> Color:
	var liquid: ItemInstance = liquid_in(contents)
	if liquid == null:
		return Color(0, 0, 0, 0)
	var becoming: ActiveReaction = _becoming(contents, liquid)
	if becoming == null:
		return liquid.item.color
	var share: float = lerpf(FIRST_TINT, 1.0, becoming.get_fraction())
	return liquid.item.color.lerp(becoming.reaction.result.color, share)


## How big to draw [param piece] of food in [param contents], 0 to 1: it
## shrinks as a reaction making a liquid uses it up; otherwise whole.
static func piece_scale(contents: VesselContents, piece: ItemInstance) -> float:
	for active: ActiveReaction in contents.get_active_reactions():
		if piece in active.consumed and _makes_liquid(active):
			return 1.0 - SHRINK * active.get_fraction()
	return 1.0


# The reaction turning [param liquid] into another liquid, or null. Prefers
# one that uses the liquid itself; any liquid-making reaction will do.
static func _becoming(contents: VesselContents, liquid: ItemInstance) -> ActiveReaction:
	var any: ActiveReaction = null
	for active: ActiveReaction in contents.get_active_reactions():
		if not _makes_liquid(active):
			continue
		if liquid in active.consumed:
			return active
		if any == null:
			any = active
	return any


static func _makes_liquid(active: ActiveReaction) -> bool:
	return active.reaction.result != null and active.reaction.result.liquid
