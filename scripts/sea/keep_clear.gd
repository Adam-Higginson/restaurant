class_name KeepClear
extends Marker3D
## An invisible round wall on the water (#227): a rowboat can't come nearer
## than [member radius] to this marker, measured flat across the sea. Round
## the home island it keeps you from landing; round the buoy it stops you
## rowing through it.
##
## The rowboat isn't a physics body (a script moves it), so a collision shape
## wouldn't stop it. Instead, after the boat has moved each physics tick,
## [method hold_off] puts it back on the circle's edge and takes away the part
## of its speed heading inwards, so it stops dead against the wall and can
## slide along it.

## How near the boat may come, in metres.
@export var radius: float = 10.0


## Pushes [param boat] back out to the edge if it has come inside. Returns
## whether it had to.
func hold_off(boat: Rowboat) -> bool:
	var centre: Vector2 = Vector2(global_position.x, global_position.z)
	var here: Vector2 = Vector2(boat.global_position.x, boat.global_position.z)
	var out: Vector2 = push_out(here, centre, radius)
	if out == here:
		return false
	boat.global_position = Vector3(out.x, boat.global_position.y, out.y)
	var outward: Vector2 = (out - centre).normalized()
	var inward_speed: float = boat.velocity.dot(-outward)
	if inward_speed > 0.0:
		boat.velocity += outward * inward_speed
	return true


## Where [param spot] must be moved to keep it at least [param keep] from
## [param centre]: unchanged if it's already that far out.
static func push_out(spot: Vector2, centre: Vector2, keep: float) -> Vector2:
	var away: Vector2 = spot - centre
	if away.length() >= keep:
		return spot
	if away.length() < 0.001:
		away = Vector2.DOWN
	return centre + away.normalized() * keep
