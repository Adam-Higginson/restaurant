class_name Waypoint
extends Marker3D
## A point on the ship's [Walkways]. Crew walking somewhere go from waypoint
## to waypoint along the links, so they keep to open floor: through doorways,
## up the hatch ramp, round the mast.
##
## A link goes both ways, so it only needs listing on one of the two. Two
## linked waypoints must have open floor between them, with no wall or solid
## prop in the way (the tests check every link).

## The names of the waypoints this one leads straight to.
@export var links: Array[StringName] = []
