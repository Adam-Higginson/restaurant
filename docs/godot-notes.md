# Godot notes

A growing glossary of the Godot concepts this project uses: what each one is, in a couple of lines, and where to find it in our code. Each PR adds the new concepts it introduces.

## Basics

**Node and scene.** Everything in Godot is a tree of nodes. A scene (`.tscn`) is a saved tree that can be placed inside other scenes as a single node, like a prefab. *Ours:* `scenes/props/fridge.tscn` is one scene, placed many times.

**Script.** A GDScript file (`.gd`) attached to a node adds behaviour to it. `class_name` gives it a global type name, so other scripts can write `var arms: Arms`. *Ours:* everything under `scripts/`.

**Resource.** A data object saved as a file (`.tres`), edited in the Inspector, shared and never copied by accident. Good for definitions. *Ours:* every item, reaction and tool under `data/`.

**Signal.** A node or object announces "this happened" and anyone connected reacts, so the sender doesn't need to know who's listening. *Ours:* `VesselContents.reaction_finished`, `Arms.changed`. Signals are named in the past tense.

**Autoload.** A script Godot creates once at startup and makes available everywhere by name. *Ours:* `Game` (`scripts/state/game_state.gd`).

**`@onready` and `$Child`.** `$Name` finds a child node by its name. `@onready` waits until the node is in the tree before looking it up. *Ours:* `@onready var _x: Type = $X` in every scene script.

**`_process` and `_physics_process`.** Called every rendered frame, and every physics tick (60 per second), respectively. Movement and collisions go in `_physics_process`. *Ours:* player movement.

**Input Map.** Named actions ("interact", "move_left") bound to keys and controller buttons in Project Settings → Input Map, so code never checks a specific key. *Ours:* `project.godot`, `tests/input_map_test.gd`.

**Tween.** Animates a property from one value to another over time, created from code. *Ours:* `ui/screen_fade.gd`.

## Rendering

**Renderer: Compatibility vs Forward+.** Godot has three renderers. *Compatibility* (OpenGL) runs on almost anything, but has simple 3D lighting. *Forward+* (Vulkan/D3D12) supports many lights with shadows, glow, volumetric fog, screen-space effects and good water. The 3D look we want needs it. *Ours:* switched in #61.

## 3D

**Units and axes.** One unit is one metre. Y is up, and a node's "forward" is its **-Z** axis (so a ship facing north looks down -Z). *Ours:* the ship is 24 m long and 8 m wide, and sails at 3 m/s.

**Node3D.** The basic 3D node: a position, rotation and scale (together, its *transform*) and nothing else. Children move with their parent. Good for grouping. *Ours:* the ship's `Visuals` node holds every mesh, so rocking it rocks them all.

**MeshInstance3D.** Draws a 3D shape (a *mesh*). Built-in meshes like `BoxMesh` and `CylinderMesh` are perfect for greyboxing. It has no collision: that's a separate node. *Ours:* every box of the ship, the island and the water plane.

**CollisionShape3D.** Gives a physics body its solid shape (a box, a cylinder, ...). It must be a **direct child** of the body. *Ours:* `HullShape`, `RampShape` and friends sit directly under `Ship`, matching the meshes in `Visuals`.

**AnimatableBody3D.** A solid body that code moves, which pushes and carries whatever touches it, like a lift or a moving platform. With `sync_to_physics` on (the default), setting its transform takes effect on the **next physics tick**, so it can work out how fast riders should be carried. *Ours:* `Ship` (`scripts/ship/ship.gd`), so the player can stand on deck while it sails (#62).

**StaticBody3D.** A solid body that never moves: floors, walls, scenery. *Ours:* the island's beach, mound and jetty.

**Path3D and Curve3D.** A `Path3D` node holds a `Curve3D`: a line through points, with handles that bend it into smooth curves. `curve.sample_baked(distance)` gives the point that many metres along it. *Ours:* the ship's `Route` in `sea.tscn`. `Ship` samples it every tick.

**Marker3D.** An empty point with a little gizmo in the editor, used to mark a spot. *Ours:* `MooringPoint`, where the route ends.

**WorldEnvironment.** Sets up the whole scene's look: the sky, the ambient light, tone mapping, and fog. One per scene. *Ours:* `sea.tscn`, with a procedural sky and exponential distance fog (`fog_density`).

**DirectionalLight3D.** Sunlight: parallel rays from one direction, lighting everything. Only its rotation matters, not its position. With shadows on, it casts them up to `directional_shadow_max_distance`. *Ours:* the `Sun` in `sea.tscn`.

**OmniLight3D.** A light bulb: shines in every direction from a point, fading out by its `omni_range`. *Ours:* the warm `GalleyLight` below deck.

**Camera3D.** What the player sees. The one marked `current` is used. *Ours:* the player's `CameraRig/Camera3D` (`scenes/prototype/player.tscn`), which the rig places each frame, at the spring arm's `FreeSpot` or a camera zone's shot.

**StandardMaterial3D and texture filtering.** A material sets a surface's colour, texture and shininess. *Texture filter* decides how texture pixels are blended when stretched: *Linear* blurs them, *Nearest* keeps them as crisp blocks (the N64/OoT look). "With mipmaps" also uses smaller copies far away, to stop shimmering. Godot has no project-wide setting for this in 3D, so we set it on each material. **Triplanar** mapping projects the texture from the sides, so boxes of any size get evenly sized squares without UV unwrapping. *Ours:* `assets/placeholder/materials/greybox_*.tres`, all sharing the 16-pixel `greybox_grid.png` (one square per metre).

**CharacterBody3D and `move_and_slide()`.** A body moved by its own script rather than by physics forces: you set its `velocity`, then call `move_and_slide()`, which moves it, slides it along walls and slopes, and works out whether it's on the floor (`is_on_floor()`). If the floor is a moving body, it adds that floor's velocity too (the *platform velocity*), including turning. *Ours:* `Player3D` (`scripts/player/player_3d.gd`). That's how the ship's deck carries the player as it sails and turns.

**`get_gravity()`.** A physics body's gravity where it stands (the project's default, 9.8 m/s² downwards, unless an area changes it). Characters add it to their velocity each tick while in the air. *Ours:* `Player3D._physics_process`.

**`Input.get_vector()`.** Reads four actions (left, right, up, down) as one `Vector2`, already combining keys and a stick, with the deadzone applied and the length capped at 1. *Ours:* the player's movement and the camera's right stick.

**Basis, yaw and pitch.** A `Basis` is a node's rotation (and scale), stored as its three axes. *Yaw* turns left and right about the up axis; *pitch* tilts up and down. Rotating a direction with `.rotated(Vector3.UP, yaw)` turns it the way the camera faces. *Ours:* `Player3D.camera_relative()` makes "up" on the stick mean "away from the camera".

**Camera rig (nested nodes for each rotation).** Put yaw on one node and pitch on a child, so turning never tilts the horizon and tilting never twists the turn. *Ours:* `CameraRig` (yaw) → `Pitch` → `SpringArm3D` → `FreeSpot`.

**SpringArm3D.** Casts a shape from itself out along its +Z axis for `spring_length` metres, and moves its children (for us, the `FreeSpot` marker the camera follows) to where the shape first hits something, so walls and masts never come between the camera and the player. `get_hit_length()` says how far out it got. A cast ignores anything it starts inside, so the player's own capsule doesn't stop it. *Ours:* `Player/CameraRig/Pitch/SpringArm3D`, 5 m long with a small sphere.

**`top_level`.** Makes a node ignore its parent's transform: it stays a child in the tree but moves in world space by itself. *Ours:* `CameraRig`, which follows the player in its own `_process` instead of moving with it.

**Physics interpolation.** Physics runs 60 times a second, but screens can draw 144 frames or more. With *Project Settings → Physics → Common → Physics Interpolation* on, Godot draws physics objects part-way between their last two positions, so movement looks smooth at any frame rate. Anything moved by a jump (spawning, teleporting) calls `reset_physics_interpolation()` so it doesn't glide there. Nodes that move every frame themselves (like a camera) turn it off with `physics_interpolation_mode`. *Ours:* turned on in #62. `Ship._ready()` and `place_player_3d()` reset it after a jump.

**`get_global_transform_interpolated()`.** Where a physics-interpolated node is *drawn* this frame, rather than where physics last put it. Use it from `_process` to follow a physics body smoothly. *Ours:* `CameraRig._follow_target()`.

**Mouse capture and `InputEventMouseMotion`.** `Input.mouse_mode = Input.MOUSE_MODE_CAPTURED` hides the cursor and locks it to the window, so the mouse can turn the camera forever without hitting the screen edge. Each movement arrives as an `InputEventMouseMotion` whose `relative` is how far it moved. Mouse movement can't be an Input Map action, so the camera reads it in `_unhandled_input`. *Ours:* `CameraRig`. Esc releases the mouse, and a click captures it again.

**Area3D and `body_entered` / `body_exited`.** An invisible volume (shaped by a `CollisionShape3D` child) that notices physics bodies overlapping it, but doesn't block them. It emits `body_entered(body)` when one starts overlapping and `body_exited(body)` when it stops, checked on physics ticks. It notices every body its collision mask covers, so check what came in. *Ours:* `CameraZone` (`scripts/camera/camera_zone.gd`), which reacts only to a `Player3D`.

**Marker3D.** An empty node that only marks a position and rotation, drawn as a small cross in the editor. Like a camera, it "looks" along its -Z axis. *Ours:* a `CameraZone`'s `Shot` (where its fixed camera sits) and the rig's `FreeSpot` (where the free camera would be).

**`Transform3D.interpolate_with()`.** Returns a transform part-way between two others: `a.interpolate_with(b, 0.25)` is a quarter of the way from `a` to `b`. Positions move in a straight line, and rotations turn smoothly the short way round. *Ours:* `CameraRig._place_camera()` glides the camera between the free spot and a fixed shot.

**`lerp_angle()` and `move_toward()`.** `lerp_angle(a, b, t)` goes part-way between two angles the short way round, so going from 170° to -170° passes through 180°, not 0°. `move_toward(from, to, step)` moves a number towards a target by at most `step`, and never overshoots. *Ours:* `CameraRig.view_yaw` (lerp_angle) and `_update_blend()` (move_toward, so leaving half way just reverses the glide).

**Easing (`smoothstep`, `ease`).** Turns a value that grows steadily from 0 to 1 into one that starts or ends gently, so motion doesn't jolt. `smoothstep(0, 1, t)` is slow at both ends; `ease(t, curve)` gives a family of shapes picked by `curve`. *Ours:* `CameraRig.blend_curve()` (your turn in #63).

**Collision layers and masks.** Every physics object is *on* some layers (`collision_layer`) and *looks at* some layers (`collision_mask`), as bit flags: layer 2 is `1 << 1`. An area only notices things on layers its mask covers. *Ours:* `Interactable3D` sits on layer 2 and the player's `InteractionDetector3D` looks only at layer 2, so the detector never notices walls or camera zones, and camera zones never notice interactables.

**`monitoring` and `monitorable`.** An `Area3D` with `monitoring` on notices others (and gets `get_overlapping_areas()`); one with `monitorable` on can be noticed. Turning off the side you don't need saves work. *Ours:* interactables are monitorable only; the detector is monitoring only.

**Building nodes in code.** `MeshInstance3D.new()`, a `BoxMesh` or `CylinderMesh` with a size, and `add_child()` make scenery from a script, which suits things that change shape often. Free the old ones with `remove_child()` then `queue_free()`, so the old and new never show at once. *Ours:* `ItemModel.build()`, used by `Counter3D` and `CarriedStack3D`.

**Static variables.** `static var` belongs to the class, not to each instance, so every user shares one copy. *Ours:* `ItemModel._materials`, one material per colour for every item model.

**`RefCounted` logic classes.** A script that `extends RefCounted` isn't a node: it lives as long as something refers to it, and can be tested without a scene. Keeping rules in one and having a node wrap it splits "what happens" from "how it looks". *Ours:* `CounterSlot` (wrapped by `Counter3D`), `Arms`, `ToolBelt`.

**Pausing the game and `process_mode`.** Setting `get_tree().paused = true` stops every node whose `process_mode` is *Inherit* (the default) or *Pausable*: no `_process`, `_physics_process` or input. Nodes set to *Always* keep running, which is how a pause menu can still be used. Physics bodies freeze too, so a moving `AnimatableBody3D` stops where it is. *Ours:* `ContainerPanel` (`ui/container_panel.tscn`, `process_mode` Always) pauses while open, which stops the ship and the camera rig until you close it.

**CanvasLayer in a 3D scene.** A `CanvasLayer` draws its 2D controls flat on top of the screen, whatever its parent is, so a 3D prop can carry its own UI as a child. Its `layer` number decides which layers draw over which. *Ours:* the `ContainerPanel` child of `scenes/prototype/props/pantry.tscn`.

**Typed dictionary exports.** `@export var start_items: Dictionary[Item, int]` shows in the Inspector as a list of key/value pairs, with the key limited to an `Item` resource and the value to a whole number. *Ours:* the pantry's starting stock, `StorageProp3D.start_items`.

**`Callable` stored in a variable.** A `Callable` is a function you can keep in a variable and call later with `.call(...)`. A lambda (`func(x: int) -> String: ...`) makes one on the spot. `is_valid()` says whether one has been set. *Ours:* each prop puts a lambda in its `Interactable3D.describe_interact`, so the detector can ask any prop what Interact would do without knowing what kind of prop it is.

**`_input` vs `_unhandled_input`.** Both receive input events. `_input` runs first, for every event, before the UI gets it; `_unhandled_input` only gets events nothing else used. Gameplay listens in `_unhandled_input`, so open panels win. *Ours:* `ActionPrompt._input` notices every key or controller press (to name the right buttons) without using them up; the player and detector use `_unhandled_input`.

**`InputMap.action_get_events()`.** Lists the keys and buttons bound to an Input Map action, so the game can show them instead of hard-coding "E". `OS.get_keycode_string()` turns a key into its name. *Ours:* `ActionPrompt.button_name()`.

**`%UniqueName`.** Tick *Access as Unique Name* on a node in a scene, and scripts in that scene can find it with `%Name` wherever it sits in the tree, so moving it into a container doesn't break the script. *Ours:* `Hud3D` finds `%BeltBar`, `%HeldItem` and `%ActionPrompt`.

**Inheritance and overriding.** `extends SomeClass` makes a script a kind of that class: it gets all its functions, and can replace (*override*) any of them by defining one with the same name and signature. Code that expects the parent type works with the child unchanged. *Ours:* `Toolbar extends Arms`, overriding `top()`, `add()` and `take_top()`, so the counter, pantry and plate-rack rules (written for `Arms`) work with the toolbar.

**Mouse buttons in the Input Map.** An action can be bound to mouse buttons as well as keys and controller buttons (`InputEventMouseButton`, `MOUSE_BUTTON_LEFT`/`RIGHT`; the wheel is buttons 4 and 5). *Ours:* right click is `interact`, left click is `use_tool`, and the wheel cycles the toolbar. A click only counts while the mouse is captured (`InteractionDetector3D.accepts_event`), so the click that recaptures it does nothing else.

**Spatial shaders.** A `.gdshader` file is a small program the graphics card runs for every vertex (`vertex()`, to move the surface) and every pixel (`fragment()`, to colour it). `uniform`s are its settings, set from GDScript with `material.set_shader_parameter()`; `varying`s pass values from the vertex step to the pixel step. *Ours:* `shaders/water.gdshader`, driven by `Sea`.

**Gerstner waves.** Instead of moving the sea only up and down (a sine wave), each point moves in a circle, so crests come out sharp and troughs wide, like real water. Several layers with different directions and lengths add up to a sea. *Ours:* `WaveLayer`/`WaveSettings` in `data/sea/`, used by both the shader and `Waves`, so scripts know exactly how high the drawn sea is.

**Fresnel.** Water (and glass) reflects more the flatter you look across it: almost a mirror at a glancing angle, see-through looking straight down. *Ours:* the water shader adds a misty sky reflection by Fresnel, which is what lets the swell's shape show at night.

**GPUParticles3D.** Thousands of small meshes moved on the graphics card, set up with a `ParticleProcessMaterial` (where they start, which way and how fast they go, how they grow and fade). `local_coords = false` leaves them where they were born when the emitter moves. *Ours:* `RainEffect` builds the rain streaks and splashes in code and keeps them around the camera.

**Fog: depth and volumetric.** The `Environment`'s *depth* fog fades things between two distances from the camera (we start at 10 m, so rooms stay clear). *Volumetric* fog fills the air itself, so lights glow as haloes and cones in it (Forward+ only). *Ours:* `sea.tscn`'s `WorldEnvironment`, with each lantern's `light_volumetric_fog_energy`.

**Audio buses and effects.** Sounds play on a *bus*, like a channel on a mixing desk; a bus can have effects (a low-pass filter muffles high sounds) and sends into `Master`. The layout lives in `default_bus_layout.tres`. *Ours:* the `Ambience` bus, whose low-pass filter `Ambience` closes as you go below deck.

**`call_deferred()`.** Runs a function at the end of the current frame instead of now, once everything else has caught up (for instance, once every node in a new scene is ready). *Ours:* `Weather` listens to the shelter zones that way, so zones later in the tree have joined their group.

*Still to come with the prototype tickets: ...*

## Testing

**gdUnit4.** The test framework (`addons/gdUnit4`). Suites extend our `GameTestSuite` and have `test_...` functions. `scene_runner` loads a scene and lets a test press inputs and wait physics ticks. *Ours:* `tests/`.
