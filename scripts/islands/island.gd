class_name Island
extends Node3D
## An island scene's root. For now it does one thing: smooths the edges of
## everything drawn while the island is showing.
##
## Antialiasing is a setting of the viewport (the surface the game is drawn
## on), normally set for the whole game in the project settings. The island
## sets it for itself when it comes in and puts it back when it leaves, so
## the rest of the game is drawn as before (#134 decides it game-wide).
## MSAA smooths the outlines of models, which is what an island is made of:
## fronds, blades of grass, rocks against the sky.

## How much to smooth edges while the island is showing.
@export var edge_smoothing: Viewport.MSAA = Viewport.MSAA_4X

var _smoothing_before: Viewport.MSAA = Viewport.MSAA_DISABLED


func _enter_tree() -> void:
	var viewport: Viewport = get_viewport()
	_smoothing_before = viewport.msaa_3d
	viewport.msaa_3d = edge_smoothing


func _exit_tree() -> void:
	get_viewport().msaa_3d = _smoothing_before
