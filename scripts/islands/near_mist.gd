class_name NearMist
extends FogVolume
## Mist you only see from close by. Sunlit mist among trees is lovely from
## inside it, but from far off the same mist is a pale slab hiding the trees.
## So this thins as the camera moves away from it and is gone at a distance,
## as if the air had cleared: nobody sees it change, because from far enough
## to notice there's nothing left of it.
##
## It needs a [FogMaterial] of its own (not shared), whose density it sets
## every frame.

## How thick the mist is when you're in or beside it.
@export var full_density: float = 0.03
## The mist starts to thin when the camera is this many metres from it...
@export var thins_from: float = 12.0
## ...and is gone by this many.
@export var gone_by: float = 55.0


func _process(_delta: float) -> void:
	var fog: FogMaterial = material as FogMaterial
	var camera: Camera3D = get_viewport().get_camera_3d()
	if fog == null or camera == null:
		return
	fog.density = density_at(distance_to(camera.global_position))


## How far [param point] is from the mist: nothing inside its box, otherwise
## the distance to the nearest part of it.
func distance_to(point: Vector3) -> float:
	var local: Vector3 = to_local(point)
	var half: Vector3 = size / 2.0
	var outside: Vector3 = (local.abs() - half).max(Vector3.ZERO)
	return outside.length()


## How thick the mist is seen from [param distance] metres away.
func density_at(distance: float) -> float:
	return full_density * (1.0 - smoothstep(thins_from, gone_by, distance))
