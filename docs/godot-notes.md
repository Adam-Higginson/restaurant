# Godot notes

A growing glossary of the Godot concepts this project uses: what each one is, in a couple of lines, and where to find it in our code. Each PR adds the new concepts it introduces.

## Basics

**Node and scene.** Everything in Godot is a tree of nodes. A scene (`.tscn`) is a saved tree that can be placed inside other scenes as a single node, like a prefab. *Ours:* `scenes/props/fridge.tscn` is one scene, placed many times.

**Script.** A GDScript file (`.gd`) attached to a node adds behaviour to it. `class_name` gives it a global type name, so other scripts can write `var arms: Arms`. *Ours:* everything under `scripts/`.

**Resource.** A data object saved as a file (`.tres`), edited in the Inspector, shared and never copied by accident. Good for definitions. *Ours:* every item, reaction and tool under `data/`.

**Resource UID.** A permanent id in a resource's header (`uid="uid://..."`), so references survive a file being moved or renamed. If a hand-written `.tres` has none, the editor may re-save it to add one, and a shader material re-saved before its shader compiles loses all its parameters. *Ours:* every shader material in `assets/placeholder/materials/` has one, checked by `tests/resource_standards_test.gd`.

**Signal.** A node or object announces "this happened" and anyone connected reacts, so the sender doesn't need to know who's listening. *Ours:* `VesselContents.reaction_finished`, `Arms.changed`. Signals are named in the past tense.

**Autoload.** A script Godot creates once at startup and makes available everywhere by name. *Ours:* `Game` (`scripts/state/game_state.gd`).

**`@onready` and `$Child`.** `$Name` finds a child node by its name. `@onready` waits until the node is in the tree before looking it up. *Ours:* `@onready var _x: Type = $X` in every scene script.

**`_process` and `_physics_process`.** Called every rendered frame, and every physics tick (60 per second), respectively. Movement and collisions go in `_physics_process`. *Ours:* player movement.

**Input Map.** Named actions ("interact", "move_left") bound to keys and controller buttons in Project Settings → Input Map, so code never checks a specific key. *Ours:* `project.godot`, `tests/input_map_test.gd`.

**Tween.** Animates a property from one value to another over time, created from code. *Ours:* `ui/screen_fade.gd`.

## Rendering

**Renderer: Compatibility vs Forward+.** Godot has three renderers. *Compatibility* (OpenGL) runs on almost anything, but has simple 3D lighting. *Forward+* (Vulkan/D3D12) supports many lights with shadows, glow, volumetric fog, screen-space effects and good water. The 3D look we want needs it. *Ours:* switched in #61.

**Screen-space reflections (SSR).** An `Environment` setting that makes glossy surfaces mirror whatever else is on screen, worked out from the image itself, so it costs little but can't reflect things off-screen. It only shows on smooth surfaces (low roughness). *Ours:* on in `sea.tscn`, so lanterns mirror in the deck's puddles and wet seams (#90).

**Tonemapping and colour grading.** The renderer works in brightnesses beyond white; *tonemapping* squeezes them into what a screen shows. *AgX* keeps bright lights from going flat white and keeps their colour. A *colour correction* texture then regrades every pixel: our `Grade_Night` gradient lifts the darks towards teal and the brights towards amber. *Ours:* the `Environment` in `sea.tscn` (#90).

## 3D

**Units and axes.** One unit is one metre. Y is up, and a node's "forward" is its **-Z** axis (so a ship facing north looks down -Z). *Ours:* the ship is 24 m long and 8 m wide, and sails at 3 m/s.

**Node3D.** The basic 3D node: a position, rotation and scale (together, its *transform*) and nothing else. Children move with their parent. Good for grouping. *Ours:* the ship's `Visuals` node holds every mesh, so rocking it rocks them all.

**MeshInstance3D.** Draws a 3D shape (a *mesh*). Built-in meshes like `BoxMesh` and `CylinderMesh` are perfect for greyboxing. It has no collision: that's a separate node. *Ours:* every box of the ship, the island and the water plane.

**CollisionShape3D.** Gives a physics body its solid shape (a box, a cylinder, ...). It must be a **direct child** of the body. *Ours:* `HullShape`, `RampShape` and friends sit directly under `Ship`, matching the meshes in `Visuals`.

**AnimatableBody3D.** A solid body that code moves, which pushes and carries whatever touches it, like a lift or a moving platform. With `sync_to_physics` on (the default), setting its transform takes effect on the **next physics tick**, so it can work out how fast riders should be carried. *Ours:* `Ship` (`scripts/ship/ship.gd`), so the player can stand on deck while it sails (#62).

**StaticBody3D.** A solid body that never moves: floors, walls, scenery. *Ours:* the island's beach, mound and jetty.

**Path3D and Curve3D.** A `Path3D` node holds a `Curve3D`: a line through points, with handles that bend it into smooth curves. `curve.sample_baked(distance)` gives the point that many metres along it. *Ours:* the ship's `Route` in `sea.tscn`. `Ship` samples it every tick.

**Marker3D.** An empty point with a little gizmo in the editor, used to mark a spot. *Ours:* the `Landing` in `islands/duel_arena.tscn`, where the lantern sets you down after a defeat.

**WorldEnvironment.** Sets up the whole scene's look: the sky, the ambient light, tone mapping, and fog. One per scene. *Ours:* `sea.tscn`, with a procedural sky and exponential distance fog (`fog_density`).

**DirectionalLight3D.** Sunlight: parallel rays from one direction, lighting everything. Only its rotation matters, not its position. With shadows on, it casts them up to `directional_shadow_max_distance`. *Ours:* the `Sun` in `sea.tscn`.

**OmniLight3D.** A light bulb: shines in every direction from a point, fading out by its `omni_range`. *Ours:* the warm `GalleyLight` below deck.

**Camera3D.** What the player sees. The one marked `current` is used. *Ours:* the player's `CameraRig/Camera3D` (`scenes/prototype/player.tscn`), which the rig places each frame, at the spring arm's `FreeSpot` or a camera zone's shot.

**StandardMaterial3D and texture filtering.** A material sets a surface's colour, texture and shininess. *Texture filter* decides how texture pixels are blended when stretched: *Linear* blurs them, *Nearest* keeps them as crisp blocks. "With mipmaps" also uses smaller copies far away, to stop shimmering. Godot has no project-wide setting for this in 3D, so we set it on each material. **Triplanar** mapping projects the texture from the sides, so boxes of any size get evenly sized squares without UV unwrapping. *Ours:* `assets/placeholder/materials/greybox_*.tres`, all sharing the 16-pixel `greybox_grid.png` (one square per metre).

**CharacterBody3D and `move_and_slide()`.** A body moved by its own script rather than by physics forces: you set its `velocity`, then call `move_and_slide()`, which moves it, slides it along walls and slopes, and works out whether it's on the floor (`is_on_floor()`). If the floor is a moving body, it adds that floor's velocity too (the *platform velocity*), including turning. *Ours:* `Player3D` (`scripts/player/player_3d.gd`). That's how the ship's deck carries the player as it sails and turns.

**`get_gravity()`.** A physics body's gravity where it stands (the project's default, 9.8 m/s² downwards, unless an area changes it). Characters add it to their velocity each tick while in the air. *Ours:* `Player3D._physics_process`.

**`Input.get_vector()`.** Reads four actions (left, right, up, down) as one `Vector2`, already combining keys and a stick, with the deadzone applied and the length capped at 1. *Ours:* the player's movement and the camera's right stick.

**Basis, yaw and pitch.** A `Basis` is a node's rotation (and scale), stored as its three axes. *Yaw* turns left and right about the up axis; *pitch* tilts up and down. Rotating a direction with `.rotated(Vector3.UP, yaw)` turns it the way the camera faces. *Ours:* `Player3D.camera_relative()` makes "up" on the stick mean "away from the camera".

**Camera rig (nested nodes for each rotation).** Put yaw on one node and pitch on a child, so turning never tilts the horizon and tilting never twists the turn. *Ours:* `CameraRig` (yaw) → `Pitch` → `SpringArm3D` → `FreeSpot`.

**SpringArm3D.** Casts a shape from itself out along its +Z axis for `spring_length` metres, and moves its children (for us, the `FreeSpot` marker the camera follows) to where the shape first hits something, so walls and masts never come between the camera and the player. `get_hit_length()` says how far out it got. A cast ignores anything it starts inside, so the player's own capsule doesn't stop it. *Ours:* `Player/CameraRig/Pitch/SpringArm3D`, 5 m long with a small sphere.

**`top_level`.** Makes a node ignore its parent's transform: it stays a child in the tree but moves in world space by itself. *Ours:* `CameraRig`, which follows the player in its own `_process` instead of moving with it.

**Physics interpolation.** Physics runs 60 times a second, but screens can draw 144 frames or more. With *Project Settings → Physics → Common → Physics Interpolation* on, Godot draws physics objects part-way between their last two positions, so movement looks smooth at any frame rate. Anything moved by a jump (spawning, teleporting) calls `reset_physics_interpolation()` so it doesn't glide there. Nodes that move every frame themselves (like a camera) turn it off with `physics_interpolation_mode`. *Ours:* turned on in #62. `Ship._ready()` and `place_player_3d()` reset it after a jump.

**`get_global_transform_interpolated()`.** Where a physics-interpolated node is *drawn* this frame, rather than where physics last put it. Use it from `_process` to follow a physics body smoothly. *Ours:* `CameraRig._follow_target()`.

**Mouse capture and `InputEventMouseMotion`.** `Input.mouse_mode = Input.MOUSE_MODE_CAPTURED` hides the cursor and locks it to the window, so the mouse can turn the camera forever without hitting the screen edge. Each movement arrives as an `InputEventMouseMotion` whose `relative` is how far it moved. Mouse movement can't be an Input Map action, so the camera reads it in `_unhandled_input`. *Ours:* `CameraRig` and `FollowCamera` (the rowing greybox's chase camera, where `RowingGreybox` captures on a click and frees on Esc). Esc releases the mouse, and a click captures it again.

**Area3D and `body_entered` / `body_exited`.** An invisible volume (shaped by a `CollisionShape3D` child) that notices physics bodies overlapping it, but doesn't block them. It emits `body_entered(body)` when one starts overlapping and `body_exited(body)` when it stops, checked on physics ticks. It notices every body its collision mask covers, so check what came in. *Ours:* `CameraZone` (`scripts/camera/camera_zone.gd`), which reacts only to a `Player3D`.

**Marker3D.** An empty node that only marks a position and rotation, drawn as a small cross in the editor. Like a camera, it "looks" along its -Z axis. *Ours:* a `CameraZone`'s `Shot` (where its fixed camera sits) and the rig's `FreeSpot` (where the free camera would be).

**`Transform3D.interpolate_with()`.** Returns a transform part-way between two others: `a.interpolate_with(b, 0.25)` is a quarter of the way from `a` to `b`. Positions move in a straight line, and rotations turn smoothly the short way round. *Ours:* `CameraRig._place_camera()` glides the camera between the free spot and a fixed shot.

**`lerp_angle()` and `move_toward()`.** `lerp_angle(a, b, t)` goes part-way between two angles the short way round, so going from 170° to -170° passes through 180°, not 0°. `move_toward(from, to, step)` moves a number towards a target by at most `step`, and never overshoots. *Ours:* `CameraRig.view_yaw` (lerp_angle) and `_update_blend()` (move_toward, so leaving half way just reverses the glide).

**Easing (`smoothstep`, `ease`).** Turns a value that grows steadily from 0 to 1 into one that starts or ends gently, so motion doesn't jolt. `smoothstep(0, 1, t)` is slow at both ends; `ease(t, curve)` gives a family of shapes picked by `curve`. *Ours:* `CameraRig.blend_curve()` (your turn in #63).

**Collision layers and masks.** Every physics object is *on* some layers (`collision_layer`) and *looks at* some layers (`collision_mask`), as bit flags: layer 2 is `1 << 1`. An area only notices things on layers its mask covers. *Ours:* `Interactable3D` sits on layer 2 and the player's `InteractionDetector3D` looks only at layer 2, so the detector never notices walls or camera zones, and camera zones never notice interactables.

**`monitoring` and `monitorable`.** An `Area3D` with `monitoring` on notices others (and gets `get_overlapping_areas()`); one with `monitorable` on can be noticed. Turning off the side you don't need saves work. *Ours:* interactables are monitorable only; the detector is monitoring only.

**Building nodes in code.** `MeshInstance3D.new()`, a `BoxMesh` or `CylinderMesh` with a size, and `add_child()` make scenery from a script, which suits things that change shape often. Free the old ones with `remove_child()` then `queue_free()`, so the old and new never show at once. *Ours:* `ItemModel.build()`, used by `Counter3D` and `CarriedStack3D`.

**One scene, many instances, dressed by exports.** A scene placed many times is the same everywhere, but each instance can set its root's `@export` properties differently, and its script applies them in `_ready()`. That's how one scene can look different in each place without copying it. *Ours:* every bunk bay is `bunk_bay.tscn`; `BunkBay`'s exports pick each bay's quilts, whether its curtains are drawn and whether its lantern is lit.

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

**GPUParticles3D.** Thousands of small meshes moved on the graphics card, set up with a `ParticleProcessMaterial` (where they start, which way and how fast they go, how they grow and fade). `local_coords = false` leaves them where they were born when the emitter moves. *Ours:* `RainEffect` builds the rain streaks and splashes in code and keeps them around the camera; `Drips` drip off the hatch rim and the sail; `GalleyStove` builds its steam, embers and chimney smoke.

**Fog: depth and volumetric.** The `Environment`'s *depth* fog fades things between two distances from the camera (we start at 10 m, so rooms stay clear). *Volumetric* fog fills the air itself, so lights glow as haloes and cones in it (Forward+ only). *Ours:* `sea.tscn`'s `WorldEnvironment`, with each lantern's `light_volumetric_fog_energy`.

**CSG shapes.** *Constructive solid geometry*: simple shapes (`CSGBox3D`, `CSGCylinder3D`) that combine, with a child set to *Subtraction* cutting itself out of its parent. Quick for blocking out levels; slower than plain meshes, so best for a few pieces. *Ours:* the galley's starboard wall is a `CSGBox3D` with two cylinders cut out for the portholes.

**Override materials.** A mesh's own materials can be replaced per instance without touching the mesh: `material_override` covers the whole mesh, `set_surface_override_material()` one surface. *Ours:* `ThirdPartyModel` applies stylised materials or a tint to individual imported models this way.

**Overridden properties on an instance.** A scene placed inside another (an *instance*) keeps its own values unless the outer scene changes one. A changed value is saved in the outer scene, shows in the Inspector with a circular ↺ revert arrow beside it, and clicking the arrow goes back to the instanced scene's value. *Ours:* `sea.tscn` used to set its `Player`'s `speed` to 2 m/s for a slower pace aboard; that's gone, so every scene uses `player.tscn`'s 3.5 m/s.

**`@tool` scripts.** A script marked `@tool` also runs inside the editor, so it can show things while you edit (here, models loaded at runtime). Anything it adds without an *owner* isn't saved into the scene. *Ours:* `ThirdPartyModel` shows pack models in the editor without saving them.

**Particle collision and heightfields.** Particles don't use the physics engine. They collide with special collider nodes instead. A `GPUParticlesCollisionHeightField3D` photographs everything inside its box from above into a height map, and particles that go below it have hit something. It's cheap and ideal for rain, but it can't see under overhangs. *Ours:* the ship's `RainCatcher` covers the whole ship, so drops land on the deck, rails and sail, and the deck keeps the galley dry.

**Particle shaders and sub-emitters.** A `shader_type particles` shader replaces the `ParticleProcessMaterial`: `start()` places each particle and `process()` moves it every step. `COLLIDED` says it hit a collider, and `emit_subparticle()` starts a particle in another system, the *sub-emitter* (set by `GPUParticles3D.sub_emitter`). *Ours:* `shaders/rain_drops.gdshader` turns each drop that lands into one splash ring, then removes the drop.

**Global shader uniforms.** A `global uniform` is a setting shared by every shader that declares it, listed under Project Settings → Shader Globals and set once from code with `RenderingServer.global_shader_parameter_set()`. *Ours:* `wetness`, which `Weather` sets from the rain and `shaders/wet_surface.gdshader` reads on every wet material.

**Sky shaders.** A `shader_type sky` shader colours the sky in every direction (`EYEDIR`), and it also feeds the scene's ambient light and reflections. `LIGHT0_DIRECTION` points at the first directional light. Using `TIME` means the sky changes every frame, so the `Sky` resource is set to the real-time process mode. *Ours:* `shaders/night_sky.gdshader` draws the moon where the `Moon` light is, with drifting cloud.

**Audio buses and effects.** Sounds play on a *bus*, like a channel on a mixing desk; a bus can have effects (a low-pass filter muffles high sounds) and sends into `Master`. The layout lives in `default_bus_layout.tres`. *Ours:* the `Ambience` bus, whose low-pass filter `Ambience` closes as you go below deck.

**`call_deferred()`.** Runs a function at the end of the current frame instead of now, once everything else has caught up (for instance, once every node in a new scene is ready). *Ours:* `Weather` listens to the shelter zones that way, so zones later in the tree have joined their group.

**Groups and `call_group()`.** A group is a named tag a node joins (`add_to_group(&"name")`). `get_tree().call_group(&"name", &"method", args)` calls that method on every node in it, so the caller doesn't need to know who's listening, or how many. *Ours:* `Weather` tells the "drips" group how wet it is; `Lightning` tells the "lightning_lit" group how bright each flash is, and every `Porthole` joins it.

**ReflectionProbe (and a room's own ambient light).** Captures its box of the scene so shiny things inside reflect the room rather than the sky. With *interior* on, it also replaces the sky's ambient light inside its box with an `ambient_color` you choose. *Ours:* `GalleyProbe` gives the galley a dim, warm ambient light, so corners stay dark below deck while the deck keeps the night sky's.

**SSAO (screen-space ambient occlusion).** An `Environment` setting that darkens creases, corners and the ground under things, where light would struggle to reach. It only darkens ambient light (and a little direct light, with `ssao_light_affect`). *Ours:* turned on, subtly, in the sea scene's environment.

**SpotLight3D.** A torch: a cone of light from a point, fading to its range, with `spot_angle` for how wide. *Ours:* each `Porthole`'s cold blue `Moonlight`, aimed down onto the galley floor.

**Instance uniforms.** `instance uniform float flash;` in a shader is a value each mesh using that material has its own of, set with `set_instance_shader_parameter()`, so many meshes can share one material but differ. *Ours:* each porthole's glass lights up on its own when `Lightning` flashes.

**Backlight (on a material).** `backlight_enabled` lets light that falls on the far side of a surface show through on the near side, tinted by the `backlight` colour, like a lamp behind thin cloth. *Ours:* the bunk curtains (`curtain*.tres`) and hammock canvas, so a drawn curtain glows when the lamp in its bunk is lit.

**A ceiling the camera can't pass.** A collision shape well above the player's head is never touched by them, but the camera's `SpringArm3D` hits it, so the camera is pulled in under the ceiling rather than rising through it. *Ours:* `GalleyCeilingShape`, `BunkCeilingShape` and `BunkCeilingForeShape`, and a `…Shape` for each ceiling beam, in both rooms.

**Exported enums.** An `enum` names a small set of choices (`enum Bedding { MADE, SLEPT_IN }`); exporting a variable of that type (`@export var lower_bedding: Bedding`) shows it in the Inspector as a drop-down of those names. *Ours:* `BunkBay.lower_bedding` and `upper_bedding`, made or slept in.

**Alpha scissor.** A material's transparency mode where each pixel is either fully drawn or not drawn at all, cut where the texture's alpha is below a threshold. It's cheap (no sorting, it still casts and takes shadows) and keeps pixel art's hard edges. *Ours:* the braided rug (`braided_rug.tres`): an oval cut from a square plane.

*Still to come with the prototype tickets: ...*

**SurfaceTool.** Builds a mesh from triangles in code: give it vertices (and normals) three at a time, then `commit()` an `ArrayMesh`. Godot treats triangles listed *clockwise* (seen from the outside) as front faces. *Ours:* the pointed bow and its deck, from the hull's outline at three heights (in `scenes/prototype/deck/upper_deck.tscn`) (#90).

**ConvexPolygonShape3D.** A collision shape made from any set of points: Godot wraps the tightest convex shape round them. *Ours:* `BowDeckShape`, the floor over the pointed bow (#90).

**AudioStreamPlayer3D.** Plays a sound from a place in the world: it gets quieter with distance and pans to where it is relative to the camera. *Ours:* `SoundSpot` (`scripts/weather/sound_spot.gd`), the creaks and groans placed round the deck (#90).

**Billboards and render modes.** A shader's `render_mode` line switches whole features on or off: `unshaded` skips lighting, `blend_add` adds its colour to what's behind (good for glows), `fog_disabled` ignores fog. Setting `MODELVIEW_MATRIX` from the camera's rotation makes a quad always face the camera (a *billboard*). *Ours:* `shaders/sparkle.gdshader`, the treasure chest's glowing motes (#152); `fog_disabled` in `shaders/far_hills.gdshader`.

**Signed distance to a shape.** A function giving how far a point is from a shape's edge: positive outside, negative inside. It makes cut-outs and bands of effect easy (inside: hide; within 1.4 m: foam). *Ours:* `hull_distance()` in `shaders/water.gdshader`, the distance to the hull's pointed outline (a polygon), which cuts the sea out of the hull and wraps foam round the bow (#90).

## Conversations (#93)

**RichTextLabel and BBCode.** A label whose text can carry markup in square brackets: `[color=#ffbd57]wet planks[/color]` colours those words. Its `visible_characters` says how many letters to show, which is all a typewriter effect needs: raise it a little each frame. *Ours:* the `Text` node in `ui/dialogue_box.tscn`; `DialogueBox.to_bbcode()` turns `*words*` into a colour tag.

**Drawing a control yourself (`_draw`).** A `Control` can paint itself with `draw_rect()` and friends inside `_draw()`, called again whenever you ask with `queue_redraw()`. Good for frames and cursors that need no picture file. *Ours:* the dialogue box's brass frame, name plank, "more" arrow and flame cursor.

**FontVariation.** A resource that wraps a font and changes how it's drawn (weight, slant, spacing) without a second font file. Pointing every label at one variation means the font is swapped in one place. *Ours:* `assets/fonts/dialogue_font.tres` (Varela Round).

**Groups, for finding one node.** A node can join a named group (`add_to_group`), and anything can ask the tree for it (`get_first_node_in_group`). It's a way to find "the" something without an autoload or a hard-wired path. *Ours:* the `Conversation` (group `conversation`), shot markers (`shots`), the lantern's home (`lantern_home`), like `TimeOfDay` before them.

**RefCounted, for logic with no nodes.** A script that `extends RefCounted` is a plain object: no scene tree, freed by itself when nothing holds it. Logic written this way can be tested without running a scene. *Ours:* `DialogueRunner`, `DialogueState`, `DialogueScript`.

**FileAccess and plain text files.** `FileAccess.get_file_as_string("res://...")` reads any file as text. Files Godot doesn't recognise aren't resources, so they need adding to an export's "non-resource files" filter when the game is exported. *Ours:* the `.dlg` conversations, read by `DialogueLibrary`.

**RegEx.** A pattern for picking text apart: `RegEx.create_from_string(...)`, then `search()` gives the pieces in brackets. *Ours:* `DialogueScript`, to split `speaker: words [tag]` and `- reply -> section`.

**InputEventAction and `set_input_as_handled`.** `_unhandled_input` is offered each press in turn, last node in the tree first; a node that uses a press calls `get_viewport().set_input_as_handled()` so nobody else also acts on it. *Ours:* `Conversation` takes Interact while you talk, so the press that ends a talk doesn't start another.

**AudioStreamWAV made in code.** A sound is just numbers: fill a `PackedByteArray` with a wave's samples, give it to an `AudioStreamWAV`, and an `AudioStreamPlayer` plays it. `pitch_scale` then plays it higher or lower. *Ours:* the typing blip in `ui/dialogue_sounds.gd`, pitched per speaker.

**Pre-render generated sounds rather than streaming them.** An `AudioStreamGenerator` lets code push samples while a sound plays, but in Godot 4.7 its playback keeps only a raw pointer to the generator. If the player (and with it the generator) is freed while the sound is still playing or fading out, the audio thread mixes with freed memory, and a garbage sample rate can trap it in a loop that hangs the whole game. When a sound can be worked out in advance, render it once into an `AudioStreamWAV` (whose playback holds a proper reference) and play that. *Ours:* `Hum.recording()` in `scripts/companion/hum.gd`, the lantern's three-note hum; this was the CI hang tracked down in Nov 2026.

## Duels (#66)

**State machine.** A thing that is always in exactly one of a few named states, with rules for when it moves to the next. In GDScript it's an `enum` for the states, a variable holding the current one, and a `match` that says what each state does. It keeps "what is it doing now?" in one place instead of a tangle of flags. *Ours:* `CrabCycle` (`scripts/combat/crab_cycle.gd`): idle, windup, attack, opening, staggered, cleared.

**Stepping logic with `delta`.** `_physics_process(delta)` is told how many seconds have passed since the last tick (1/60). Logic that only ever adds up `delta` doesn't care who is calling it, so a test can hand it any amount of time and check exactly what happened. *Ours:* `CrabCycle.tick(delta)` and `ParryWindow.tick(delta)`; `Crab` and `Duellist` call them every physics tick, and the tests call them with whole seconds.

**Groups, for finding many nodes.** As well as finding "the" one of something, `get_tree().get_nodes_in_group(name)` gives every node in a group, and `remove_from_group` takes a node out again. *Ours:* everything in `lock_on_target` can be locked on to and struck; a fog-crab leaves it when its fog clears. The player's `Duellist` is in `duellist`, and the place a defeat puts you is in `landing`.

**Groups set in a scene.** A node can be put in a group in the editor: select it, open the **Node** dock (beside the Inspector), then **Groups**. In the `.tscn` it's saved as `groups=["landing"]`. *Ours:* `Landing` in `duel_arena.tscn`.

**`lerp_angle`.** Like `lerp` (a value part-way between two others), but for angles: it goes the short way round, so easing from 350° to 10° turns 20°, not 340° backwards. *Ours:* `CameraRig._swing_to_target()` eases the camera's yaw towards the locked-on target.

**Easing that ignores frame rate.** `value = lerp(value, goal, 1.0 - exp(-speed * delta))` moves a fixed fraction of the remaining distance per second, however many frames that second has. Plain `lerp(value, goal, 0.1)` would move faster on a faster machine. *Ours:* the camera's zoom and its lock-on swing.

**`atan2` for "which way is it?"** `atan2(-x, -z)` turns a flat direction into the yaw (turn about the up axis) that points a node's forward (-Z) along it. *Ours:* `CameraRig.yaw_along()`, `Player3D.face_towards()`, and the fog-crab turning to face you.

**Angles between directions (`angle_to`).** `a.angle_to(b)` on two `Vector2`s gives the angle from one to the other. Comparing it with half an arc says whether something is "in front". *Ours:* `Duellist.in_reach()`: the knife hits what's within 2 m and inside a 120° arc ahead.

**Signals between plain objects.** Signals aren't only for nodes: a `RefCounted` can declare and emit them too. *Ours:* `Hearts.changed` redraws the `HeartsBar`; `CrabCycle.attacked` tells the `Crab` to land its hit; `CrabCycle.state_changed` sets the lantern's light.

**Input Map actions for triggers.** A controller's triggers are *axes* (how far they're pulled), not buttons: bind them as "Joypad Axis 4" (left) and "5" (right). The action's *deadzone* is how far they must be pulled to count as pressed. *Ours:* `lock_on` and `parry` in Project Settings > Input Map, with a deadzone of 0.5.

**`is_action_pressed` and `is_action_released` on an event.** In `_unhandled_input(event)`, these say whether this event is a button going down or coming up, which is what a held button needs. *Ours:* `LockOn` locks on at the press and lets go at the release.

**Sound files and AudioStreamPlayer.** Drop an `.ogg` or `.wav` into the project and Godot imports it as an `AudioStream` (the `.import` file beside it records how). An `AudioStreamPlayer` node plays whatever is in its `stream`, at its `volume_db`, heard the same wherever you are. *Ours:* the six players under `DuelSounds` in `player.tscn` (swing, slice, tink, pan up, clang, hurt).

**AudioStreamPlayer3D.** The same, but the sound comes from the node's place in the world: quieter with distance, and from the left or right of the camera. *Ours:* the three players under `Sounds` in `crab.tscn`, so the far crab's ticking stays far away.

**AudioStreamRandomizer.** A resource that holds several recordings and plays one at random each time, never the same twice running, at a slightly different pitch (`random_pitch`). A sound heard over and over stops feeling stamped out. Give it to a player as its `stream`. *Ours:* one `.tres` per sound in `assets/audio/combat/` (`clang.tres`, `swing.tres`, `crab_click.tres`...). Open one in the Inspector to see its recordings and press play on each.

**A node that only listens.** Sound doesn't belong in the rules, so the rules just emit signals and a separate node connects to them and plays things. Remove the node and the game still works, silently. `signal.connect(play.bind(NAME))` connects one function to many signals, each with its own argument. *Ours:* `DuelSounds` listens to `Duellist`; `CrabSounds` listens to the crab's `CrabCycle`.

## Overheard chatter (#94)

**SubViewport and ViewportTexture.** A `SubViewport` is a little off-screen screen: whatever is inside it (here a 2D `Control`) is drawn into a picture, and `get_texture()` hands that picture to anything that shows textures. Drawing a 2D thing once and showing it on a flat panel in the 3D world is how 2D UI gets a place in the world. *Ours:* `SpeechBubble3D` (`ui/speech_bubble_3d.gd`) draws a `SpeechBubble` into one and shows it on a `QuadMesh`.

**Facing the camera by copying its rotation.** Setting a panel's rotation to the camera's own (`camera.global_basis`) turns it to face the camera square-on every frame, wherever you look from. It's a billboard done in a script rather than a shader. *Ours:* `SpeechBubble3D._follow()`, which also scales the panel with distance.

**`no_depth_test` and `render_priority`.** A material with `no_depth_test` draws over whatever is in front of it instead of being hidden, and a higher `render_priority` draws it after other see-through things. *Ours:* the speech bubble's material, so a low beam never cuts a bubble in half.

**Raycasts (`intersect_ray`).** `get_world_3d().direct_space_state.intersect_ray(query)` asks the physics engine what solid thing a straight line from one point to another hits first; an empty answer means nothing's in the way. The query can `exclude` bodies to ignore. *Ours:* `Speaker.in_sight_of()`, line of sight from your eyes to a speaker's face (ignoring you and them), to hide bubbles behind walls and keep the chatter to people you can see.

**RandomNumberGenerator with a seed.** Its own random numbers rather than the global `randi()`. Give it a fixed `seed` and it makes the same "random" numbers every time, so a test can check random picks exactly. *Ours:* `RemarkPicker` takes one; the chatter tests seed it.

**`call_group`.** `get_tree().call_group("name", "method")` calls a method on every node in a group, and does nothing if there are none, so two parts can talk without either holding a reference to the other. *Ours:* `Chatter.hush_all()`, which the lantern uses to cut the chatter off when he has something to say.

**Turning off physics interpolation, and `process_priority`.** A node placed afresh every frame (in `_process`) must set `physics_interpolation_mode` to Off, or Godot also smooths it between physics ticks and it lags and shakes (see Physics interpolation above). `process_priority` sets the order nodes' `_process` runs in each frame, lowest first, so a node that depends on another (a bubble facing the camera) can run after it. *Ours:* `SpeechBubble3D` does both, so bubbles keep still and line up with the camera this frame, not last frame.

**Inner classes.** A `class Name:` block inside a script defines a small type only that script needs, like a struct. *Ours:* `Speaker.Queued`, a line and its bubble style waiting their turn.

## Cutscenes (#100)

**`await` and coroutines.** `await something` pauses a function at that line until `something` happens (a signal fires, or another function that itself awaits finishes), then carries on from there. Meanwhile the rest of the game keeps running. A function with an `await` in it is a coroutine. *Ours:* `WaitCues` waits out a pause one physics tick at a time; `FadeCues` awaits the fade's tween; `Opening` awaits the cutscene's `ended` signal.

**Calling a coroutine without `await`.** If you call a function that awaits and don't `await` it yourself, it runs up to its first pause and your code carries straight on; the rest happens later by itself. *Ours:* `CueHandler.handle` starts a cue's work this way, which is why a handler has to tell the script to wait explicitly, with `hold()` and `release()`.

**`_enter_tree` comes before `_ready`.** When a scene is added, every node in it gets `_enter_tree` first (parents before children), and only then do the `_ready` calls happen. So something done in `_enter_tree` is in place before any node's `_ready` runs. *Ours:* `Conversation` joins its group in `_enter_tree`, so the cue handlers can find it in their `_ready` wherever they sit in the scene.

**Disabling a node (`PROCESS_MODE_DISABLED`).** Setting `process_mode` to disabled stops a node and its children running their `_process` and `_physics_process`, and a physics body that's disabled is also taken out of the physics world, so nothing collides with it. With `visible = false` as well, it's as if it weren't there. *Ours:* `Crewmate.set_present`, used by `@hide` and `@show`.

**Instance ids.** Every object has a number, `get_instance_id()`. Keeping the number instead of the object lets you ask later whether it still exists (`is_instance_id_valid`) and get it back (`instance_from_id`), without ever holding a freed object in a typed variable, which is an error. *Ours:* `Conversation` remembers who holds the script this way, so a handler that's been freed can't leave a cutscene waiting for ever.

**Holding a button (`Input.is_action_pressed`).** `_unhandled_input` tells you the moment a button goes down. To know it's still down, ask `Input.is_action_pressed("action")` every frame in `_process` and add up the time. *Ours:* `Conversation` counts a second of `skip_cutscene` before skipping.

**Default arguments.** A parameter with `= value` can be left out by callers: `func hold_shot(shot: Marker3D, cut: bool = false)`. It lets a function grow a new option without changing the code that already calls it. *Ours:* `CameraRig.hold_shot` and `release_shot` gained `cut`; `ScreenFade.fade_in` and `fade_out` gained `seconds`.

## Combat feel and models (#107)

**`Engine.time_scale`.** Godot's dial for how fast game time passes: every `delta` is multiplied by it. Turned almost to 0 everything that moves by `delta` stops, but `_process` and `_physics_process` still run (with a tiny delta) and sound carries on. *Ours:* `HitStop` turns it down for a few physics ticks when a blow lands, and back up after, even if it's freed mid-freeze (`_exit_tree`).

**`CPUParticles3D` one-shot bursts.** A particle emitter whose particles are meshes. With `one_shot` and `explosiveness` 1 it throws all its particles at once; `restart()` throws another burst. CPU particles need no shader compiled the first time they fire, so there's no stutter on the first hit. *Ours:* the crab's `Chips` and `Wisps`, the pan's `Sparks`.

**`material_overlay`.** A second material drawn over a mesh on top of its own, without replacing it. *Ours:* `Crab` lays a white unshaded one over every mesh of its model for the flash when struck.

**`ImmediateMesh`.** A mesh you rebuild in code every frame: `clear_surfaces()`, then `surface_begin`, a colour and a point per vertex, `surface_end`. *Ours:* `KnifeTrail`, a ribbon through where the blade has been.

**Screen-reading shaders (`hint_screen_texture`).** A `canvas_item` shader can read what's already been drawn behind it, and change it: tint it, blur it, drain its colour. Whatever draws after it isn't affected. *Ours:* `HurtOverlay` (`shaders/hurt_overlay.gdshader`), the first thing in the HUD so the hearts and toolbar stay untouched.

**Audio bus effects.** Every sound goes through a bus (`Master`, `Ambience`), and a bus can have effects such as a low-pass filter. Its settings can change while the game runs: `AudioServer.get_bus_effect` gives you the effect, and `set_bus_effect_enabled` turns it on and off. *Ours:* the `Muffle` low-pass on Master (`default_bus_layout.tres`), swept down by `HitFeel` when you're hurt.

**Skeletons and bones (`Skeleton3D`).** An animated model is a mesh "skinned" to a skeleton: each vertex follows a few bones by weight, so turning a bone bends the mesh. Bones are named and posed in code with `set_bone_pose_rotation` and `set_bone_pose_scale`. *Ours:* `CharacterModel` puts every part on one skeleton and scales the head bone; `Crab` lifts the claws through the arm bones.

**`BoneAttachment3D`.** A node that follows one bone of a skeleton, so anything under it moves with that bone. *Ours:* `CharacterModel.right_hand` and `left_hand`, which hold the knife and pan.

**`AnimationPlayer` and `AnimationLibrary`.** Animations live in libraries on a player, named `library/animation`. Each track moves one thing, for a bone written `path/to/Skeleton3D:bone`, so changing the path points an animation at another skeleton with the same bone names. Godot drops a `_Loop` ending from imported names and makes those animations loop. *Ours:* `CharacterModel.retarget` copies the Universal Animation Library's animations onto our skeleton, keeping only rotations.

**Advancing an animation by hand.** With `callback_mode_process` set to Manual, an `AnimationPlayer` only moves on when you call `advance(delta)`. You can then adjust its bones after it, in the same frame. *Ours:* `Crab._animate` plays the crab's walk, then lifts its claws on top.

**Mesh arrays (`ArrayMesh`).** `surface_get_arrays` gives a mesh's raw data (positions, bone indices and weights, and the index list of triangles), and `add_surface_from_arrays` builds a mesh from data. *Ours:* `CharacterModel.cut_out` keeps only the triangles the head and neck bones move, to take a head off a whole body.

**Static variables.** `static var` belongs to the class rather than to each node, so every instance (and tests) sees the same one. *Ours:* `CharacterModel.packs_enabled`, which tests switch off, and its cache of cut heads.

**Blender's command line.** `blender -b file.blend --python script.py -- args` runs Blender without a window, opens the file and runs a Python script on it. *Ours:* `tools/blend_to_glb.py` turns the crab's `.blend` into a `.glb` Godot can import.

## The knife combo and dodging (#108)

**Your own Resource type for tuning.** A script that `extends Resource` with a `class_name` and `@export` fields becomes a kind of file: make one in the FileSystem dock (right click → New Resource) and its fields show in the Inspector. A node can then `@export` a slot for it, or `preload` one as a default. *Ours:* `KnifeCut` (`scripts/data/knife_cut.gd`) and `DodgeMove`; the files are in `data/combat/`. Open `cleave.tres` to change how hard the cleave hits without touching code.

**Playing part of an animation, fitted to a time.** `AnimationPlayer.play(name, blend)` starts an animation (blending from the last over `blend` seconds), `seek(seconds, true)` jumps into it, and `speed_scale` plays it faster or slower. Together they play any stretch of a clip in exactly the time you want. *Ours:* `CharacterModel.act`, which plays, say, 0.6 s of `Sword_Heavy_Combo` from 2.2 s in, squeezed into the cleave's 0.38 s.

**Input buffering.** Remembering a press that came too early, and acting on it as soon as it can be. Without it, a tap during a swing is lost and combos feel unresponsive. *Ours:* `KnifeCombo.press()` mid-cut sets `_buffered`, and the next cut starts the moment this one ends.

**Telling a held button from a tap.** Count how long it's been down since `is_action_pressed`, and act on `is_action_released`. Doing the tap's action at the press keeps taps instant; holding on just adds more. *Ours:* the knife cuts at the press, charges if Use tool is still down 0.3 s later, and `Duellist._unhandled_input` lets the fillet go on the release.

**`@export_group`.** Gathers the exports after it under a folding heading in the Inspector, so a node with many settings stays readable. *Ours:* `Duellist` has Knife, Pan, Blows taken and In hand groups.

**A jump with `CharacterBody3D`.** Set `velocity.y` upwards for one tick; gravity (`get_gravity()`) pulls it back down, and `is_on_floor()` says when it's landed. Floor snapping doesn't stick a body that's moving up. *Ours:* `Player3D.dodge()` lifts the player by the move's `hop`; the backflip's 2.4 m/s carries them about 0.3 m up.

**Turning about a point that isn't the origin.** A node turns about its own origin, which for a character is its feet. To turn it about its hips instead, turn it and then move it by the difference: `position = hips - rotated(hips)`. *Ours:* `CharacterModel._turn_for_flip`, so the backflip goes head over heels round the waist instead of swinging the head through the ground.

**Single-precision angles.** Vectors store their numbers as 32-bit floats, so an angle worked out from them can come out a hair off: straight behind is pi, but in 32 bits it rounds just above the 64-bit `PI`. Compare angles with a little room, or special-case the edges. *Ours:* `Duellist.in_reach` treats an arc of 360 degrees as reaching everything, or the fillet missed a crab directly behind.

## Hunting crabs (#109)

**`Label3D`.** Text placed in the 3D world, like a sign, rather than on the screen. It has its own font, size (`font_size` × `pixel_size` metres per pixel), colour (`modulate`) and outline. *Ours:* the "Lv 1" over each crab (`LevelLabel` in `crab.tscn`) and every `DamageNumber`.

**Billboarding and `no_depth_test`.** A billboard turns to face the camera every frame, so text and sprites never show edge-on. Turning off the depth test draws it over whatever is in front of it, so a wall or the crab itself can't hide it; `render_priority` then says what's drawn on top of what. *Ours:* `DamageNumber` and the level label have both.

**Nodes that free themselves.** Something short-lived (a number, a puff) can count its own time in `_process` and call `queue_free()` when it's done, so whoever made it never has to tidy up. Add it to the world, not to the thing it's about, so it stays put if that moves or is freed first. *Ours:* `DamageNumber.spawn` adds the number to the crab's parent; a dead `Crab` frees itself once it has sunk.

**Static functions for formulas.** A `static func` belongs to the class, not to one node, so it can be called and tested without making a scene. Good for rules like "health from level". *Ours:* `Crab.health_for(level)` and `Crab.meat_quality_for(level)`.

**Turning a body's collision off.** A `CollisionShape3D` with `disabled` on stops blocking anything, so the player walks over a dead crab. Change it with `set_deferred("disabled", true)` when it happens during physics (as a strike landing does), or Godot complains about changing shapes mid-step. A body with no shape mustn't keep moving under gravity, or it falls through the floor. *Ours:* `Crab._on_died`.

**`set_deferred` and `call_deferred`.** Set a property, or call a function, at the end of the current frame instead of now: the safe way to change physics or the scene tree from inside a physics callback. *Ours:* turning off a dead crab's shape.

**A scene a script loads, not preloads.** `preload` reads a file when the script is compiled; if that file is a scene using the same script, it's a loop. `load()` at the moment it's needed avoids it. *Ours:* `Pickup3D.spawn` loads `scenes/props/pickup.tscn`, whose root uses `pickup_3d.gd`.

## The intro's water half (#102)

**AnimationPlayer and clips.** An `AnimationPlayer` records properties changing over time (a position, a light's brightness) as animations with keyframes, and plays them back. Select one in the editor and the Animation panel at the bottom shows its timeline: pick a clip, drag the playhead to scrub, move keys to retime. A clip can loop. *Ours:* `Clips` in `scenes/prototype/intro/underwater.tscn` (`sinking`, `lantern_descends`, `offered`, `taken`) and in `rescue_set.tscn` (`title_drift`, `dive`), played by `ClipCues` for `@play` and `@start`.

**A SubViewport with its own world.** A `SubViewport` is an off-screen screen. With `own_world_3d` on, the 3D things inside it live in a separate world from the rest of the game, with their own camera, lights and `WorldEnvironment`, so nothing leaks either way. Its picture is a texture you can show anywhere. *Ours:* the underwater set in `underwater_stage.tscn`: the storm, the ship and the rain don't exist in there, and its darkness doesn't touch the game. `StageView` shows its picture full-screen.

**`disable_3d` on a viewport.** Stops a viewport drawing its 3D world while leaving its 2D and UI alone. *Ours:* `Stage` sets it on the game's main viewport while the underwater set covers the screen, so the sea and ship aren't drawn behind a picture that hides them.

**A camera's `current`.** Each viewport shows the view of one `Camera3D`: the one marked current. A SubViewport has its own current camera, separate from the game's. *Ours:* the `Camera` in `underwater.tscn`.

**NoiseTexture2D.** A texture Godot fills with smooth random noise (from a `FastNoiseLite`), tiling if asked. Handy for anything cloudy or rippling without drawing a picture. *Ours:* the light of the surface seen from below (`shaders/sea_underside.gdshader`) slides two copies of one over each other.

**CPUParticles3D.** Many small copies of a mesh, each born, moved and removed by simple rules (where they start, which way they go, how long they last). The CPU version is easier to set up than `GPUParticles3D` and fine for a few hundred. *Ours:* the bubbles and drifting motes underwater. They rise past a figure that's holding still, which is what makes it look like sinking.

## The lantern's face and the nameboard (#114)

**Bump and normal maps, made in a shader.** A normal map tells the lighting which way each point of a flat surface is "really" facing, so a flat plank can be lit as if it had dents and ridges. Usually it's a texture; a shader can also work it out and write it to `NORMAL_MAP`. Because the lighting is real, a moving light makes highlights and shadows slide across the bumps. *Ours:* the ship's carved name (`shaders/carved_name.gdshader`): the slope of each cut is worked out from a mask of the text. The same slopes are also shaded directly by where the lantern is, so the lit and shadowed walls of the letters swing round as he does.

**A SubViewport as a texture you draw yourself.** Put ordinary 2D nodes (here a `Label`) in a `SubViewport` and its picture becomes a texture a shader can read. Set it to draw once and it costs nothing afterwards. *Ours:* `Name/Mask` in `scenes/prototype/intro/stern_watch.tscn` writes "SALT AND EMBER" in white on black, and the carving is cut wherever that's white. Change the text on `Name` and the carving changes.

**`to_local()`.** Turns a place in the world into a place measured from a node: its own origin, its own left and right. Something that depends on "where is the lamp relative to this plank" keeps working whichever way the ship is pointing. *Ours:* `CarvedName` gives its shader the lamp's place this way.

**A material of your own (`duplicate()`).** Every instance of a scene shares the same material resource, so changing it on one changes them all. `material.duplicate()` makes a private copy for one instance. *Ours:* `LanternFace` copies its glass material in `_ready`, so fogging one lantern doesn't fog the others.

**Driving a shader from a script.** A shader's `uniform` values are its dials. `material.set_shader_parameter("name", value)` turns one from code, every frame if you like, so game state can change how something is drawn. *Ours:* `LanternFace` sends his strength, lean, fog, streaks and crack to `lantern_flame.gdshader`; `CarvedName` sends the lamp's position to `carved_name.gdshader`, which lights the cuts of each letter from that side.

**Easing towards a target.** Rather than jumping to a new value, move a fraction of the way there each frame: `value = lerp(value, target, 1.0 - exp(-speed * delta))`. It starts quickly and settles gently, and takes the same time whatever the frame rate. *Ours:* how his eyes change shape between looks.

**Enums as a list of named choices.** `enum Look { CALM, SURPRISED, ... }` gives each choice a name and a number. An exported enum shows as a dropdown in the Inspector, and an animation clip can key it. *Ours:* `LanternFace.Look`. (Don't name one after a built-in class: `Expression` is taken.)

## The mutual rescue and the light underwater (#119)

**Volumetric fog.** Ordinary fog just tints far things. Volumetric fog (Forward+ only, a tick-box on the `Environment`) fills the air with a haze that lights shine *through*: a lamp makes a visible glow round itself, and things in the way cast shadows through the haze. It's worked out on a coarse 3D grid, so it's soft and can't show fine detail. Each light has a `Volumetric Fog Energy` saying how strongly it lights the haze. *Ours:* the water in `underwater.tscn` (`WorldEnvironment`), which is what gives the lantern's glow a body. A clip turns his light's fog energy down when he's strong, or the haze round him would drown him out.

**Reading the screen in a shader.** A shader can ask for the picture drawn so far (`hint_screen_texture`) and how far away each pixel is (`hint_depth_texture`), and draw a changed version of it. Draw that on a sheet that covers the screen and it works like a lens over the camera. *Ours:* `shaders/underwater_lens.gdshader` on `Camera/Lens`, which takes the red out of far things and wobbles the picture near the lantern.

**Covering the screen from a vertex shader.** Setting `POSITION` in a shader's `vertex()` says exactly where on screen each corner goes, ignoring where the mesh is in the world. Four corners at the screen's corners make a sheet that always fills the view. *Ours:* the lens.

**Opaque and see-through are drawn in two rounds.** Solid things are drawn first; anything see-through (or that reads the screen) is drawn afterwards, back to front. A screen-reading shader only sees the first round. `render_priority` on a material moves it earlier or later within the second round. *Ours:* the lens has a low priority so the bubbles and the burst of light are drawn over it; and the surface overhead is drawn solid, so the lens tints it like everything else.

**Drawing a shape with distances.** Instead of a picture of a hand, the shader works out, for each pixel, how far it is from the nearest part of the hand (a line for the arm, a circle for the palm, a line for each finger). Inside if the distance is below zero. Move those lines and the shape moves; add noise to the distance and its edge flickers like fire. (The usual name is a signed distance field.) *Ours:* `shaders/flame_hand.gdshader`.

**Lit and unlit materials.** An `unshaded` material shows its own colour whatever the lighting (a flame, a glow). A lit one shows only what light falls on it. *Ours:* his flame and hand are unshaded; the bubbles (`shaders/bubble.gdshader`) and the dust in the water are lit, so they glow amber near him and vanish in the dark.

**Adding instead of covering (`blend_add`).** A see-through material normally covers what's behind it. With `blend_add` its colour is added on top, so it can only brighten: right for light. *Ours:* the burst of light and the shafts between the hands.

**A camera moved by a clip.** A `Camera3D`'s position, rotation and field of view are properties like any other, so an animation can key them. A cut is two keys a thousandth of a second apart. *Ours:* every clip in `underwater.tscn` moves `Camera`, so each clip is also a shot.

**Total internal reflection (the window overhead).** Light leaving water bends, and past about 49 degrees from straight up it can't leave at all and bounces back. So from below the sky shows only through a round window, with a mirror round it. *Ours:* `shaders/sea_underside.gdshader` works this out per pixel from the angle between the camera and the surface.

**Audio buses.** Sounds play through named buses (Project > Audio, bottom panel), each with its own volume and effects, so a whole group can be changed at once. *Ours:* the weather plays on the `Ambience` bus; `@muffle` turns down its filter, and `@hush` turns the whole bus down to silence for a held breath.

**A node told it's been switched off.** When a node can no longer run (its `process_mode` or a parent's became Disabled) it gets `NOTIFICATION_DISABLED`, and `NOTIFICATION_ENABLED` when it can again. Catch them in `_notification(what)`. *Ours:* `OptionalSound` pauses a looping sound while its stage is put away.

## The deep, the thing in the lightning, and the storyboard (#120)

**Instance uniforms.** Normally every object sharing a material shares its shader values too. Mark a uniform `instance uniform` and each object can have its own value, set with `set_instance_shader_parameter("name", value)`, while they all still share one material. *Ours:* the 90 dead lanterns share one glass material, and `LanternField` gives each its `cold` (how much of the lightning shows on its glass).

**Saying "deep" without a floor.** Depth is shown by things getting smaller, dimmer and bluer with distance and never ending. Three things already in the set do the dimming: the haze (volumetric fog), the lens that takes colour out of far things, and a light's own falloff with distance. *Ours:* the lanterns hang from a few metres below you to about fifty, and the furthest are barely there.

**Faking shafts of light.** Real light shafts need something in the way to break the light up. A cheap stand-in is a tall see-through tube, added on top of the picture (`blend_add`), bright at the top and fading to nothing, with its sides faded out by how squarely each bit faces the camera so it never looks solid. *Ours:* `shaders/light_shaft.gdshader` on the tubes under `Shafts`, shown only while lightning flashes.

**Showing something by what it hides.** The thing's body is an ordinary mesh drawn in one flat colour, the colour of the deep. It never catches light, so in the dark it can't be seen at all. In a flash, the lit haze behind it and the shafts and lanterns it covers are what give away its shape. *Ours:* `Thing/Body` in `underwater.tscn`.

**Shaping a mesh in its vertex shader.** `vertex()` can move each corner of a mesh before it's drawn. A plain tube with plenty of rings along it can be squeezed here and swollen there into a body, and bent a little differently every frame so it moves, without modelling or rigging anything. *Ours:* `shaders/the_thing.gdshader` turns a cylinder into a head, a body and a swaying tail.

**Groups as a broadcast.** `get_tree().call_group("name", "method", value)` calls that method on every node in the group, wherever it is in the tree. *Ours:* `Lightning` tells the group `lightning_lit` how bright each flash is, which now includes `Lanterns` and `Shafts` inside the underwater set.

**Preparing an effect before it's needed.** The first time Godot draws something with a new shader it may stop for a moment to prepare it, which shows as a hitch. Hiding a thing until it's needed just moves that hitch to the worst moment. Drawing it from the start, at no brightness, gets it over with while nothing is happening. *Ours:* the burst of light, the shafts between the hands and the lightning shafts are always drawn; their brightness is what's switched.

**Ragdolls (tried, and removed).** `PhysicalBoneSimulator3D` and `PhysicalBone3D` can hand a skeleton's bones to the physics engine so a body goes limp. We tried it for the unconscious castaway. Without carefully set limits on every joint the limbs flail, and it can't be checked by tests or stills, only by watching. A chosen pose and a slow drift do the job predictably.

**Changing bones after the animation (`SkeletonModifier3D`).** A node under a `Skeleton3D` that gets a turn, every frame, after the animation has posed the bones and before the model is drawn. Whatever it sets replaces the animation's value for that bone only. It's how you add one thing (a look, a reach) on top of an animation without making a new animation. *Ours:* three of them sit under the character's skeleton. `scripts/art/arm_reach.gd` turns the upper arm, forearm and hand to point at his hand (`CharacterModel.reach` says how far), and curls each finger and thumb joint to hold it (`CharacterModel.hand_grip`); the fingers bend about their own Z, the thumb about its X, because it lies across the palm. `scripts/art/head_look.gd` turns the head towards him (`head_turn`), never further than a neck goes. `scripts/art/floating_legs.gd` bends the hips, knees and ankles so the legs trail and drift instead of standing (`afloat`).

**Turning one direction into another (`Quaternion(from, to)`).** A quaternion is a way of storing a rotation. Built from two directions, it's the shortest turn that takes the first to the second, and `slerp` gives a share of that turn. *Ours:* how `ArmReach` works out how to swing a bone towards its target, and how the arm can be raised gradually.

**Holding an animation still (`AnimationPlayer.pause`).** Play an animation, `seek()` to a moment in it with the second argument `true` (so the pose updates at once), then `pause()`: the character holds that pose. A paused player's `current_animation` is empty; `assigned_animation` still names it. *Ours:* `CharacterModel.held_animation` holds the sleeping you in your bunk on the first frame of `LayToIdle` (lying flat, before getting up).

**`top_level` doesn't escape a hidden parent.** A `top_level` node ignores its parent's position, but not its visibility: hide the parent and it's hidden too. *Ours:* the lantern spirit is a child of the player (so `@hide player` hides only the player's `Model`, or he'd vanish with you).

**Hiding part of a model.** A character built from several meshes can show or hide each with `visible`. *Ours:* `CharacterModel.eyes_shut` hides the eyeballs, which leaves the lids' own hollow: closed eyes, with no extra art.

**Queueing an animation (`AnimationPlayer.queue`).** `play()` switches to a clip at once; `queue()` lines one up to start when the current one ends. *Ours:* the `@queue` cue: `pleads` plays once, then the `offered` loop takes over for as long as the player waits.

**Lines that don't wait.** A line in the dialogue box normally waits for a button. `Conversation.say_aside()` shows one that doesn't: the box has no arrow, the script carries on, and whoever asked puts it away. *Ours:* the `@say` and `@say_in` cues (`scripts/cutscene/speech_cues.gd`), for a shout or a plea that should pass with the moment.

**Giving each of many things its own pace.** A small sum that turns an index into a number between 0 and 1, always the same for that index, is enough to make a crowd look unplanned without storing anything. *Ours:* `LanternField.share_of`, which sets how fast each lantern sinks and turns.

## The Meshy heron captain (#139)

**Blending between animations.** `AnimationPlayer.play(name, custom_blend)` fades from whatever was playing into the new animation over that many seconds, so a character eases from listening into talking instead of snapping. *Ours:* `CrewAnimator` blends over 0.3 s.

**Loop modes.** Each `Animation` has a `loop_mode`: none (plays once and stops on its last frame), linear (starts again from the top) or ping-pong (back and forth). Imported animations usually come without a loop, so we set it in code. *Ours:* `CrewAnimator` sets its idle, talking and listening animations to loop when the model loads.

**An armature's scale and its animations' units.** A model's skeleton can sit under a scaled node: Meshy's `Armature` is scaled by 0.01, its bones and animations are in centimetres, and the mesh is in metres. It all lines up inside the file, but measuring the mesh's box through that scale reads it 100 times too small. Scale the node that holds the whole model instead. *Ours:* the heron's `Model/Meshy` node is scaled by 1.21, with `fit_size` left at zero.

## Publishing builds (#143)

**Exporting.** Turning the project into a game people can run without Godot: a program for each system plus a `.pck` of the game's data. *Ours:* `tools/build/export.sh` runs `godot --headless --export-release "Windows" <path>`.

**Export templates.** The ready-made Godot player programs an export starts from, one per system, downloaded once per Godot version (about 1.2 GB for all of them; *Editor > Manage Export Templates*). They live in your user folder, not the project. *Ours:* the workflow keeps only the Windows and Mac ones.

**Export presets (`export_presets.cfg`).** One per platform: its settings (the app's name, icon, texture formats, signing) and which files go in. *Project > Export* shows them. *Ours:* "Windows" and "macOS". Their file lists are written just before each build, by `tools/build/prepare_export.gd`.

**The `.pck` file.** Every scene, script and imported asset packed into one file, which the game program reads at startup. Godot can run one directly: `godot --main-pack Game.pck`. *Ours:* the smoke test in `export.sh` runs the Windows build's `.pck` that way, headless, and fails on any error.

**Which files are exported.** By default everything the project has imported. "Export selected resources" takes a list and adds whatever each one depends on (a model's textures, a scene's scripts). Files loaded by a path written in a string can't be seen that way, and plain text files like our `.dlg` scripts need the preset's non-resource filter. *Ours:* `ExportList` (`scripts/build/`).

**Release and debug builds.** A release export leaves out debugging help: no console window, and `OS.is_debug_build()` is false, so our debug keys switch themselves off. *Ours:* every published build is a release build.

**Texture formats (S3TC/BPTC and ETC2/ASTC).** Graphics cards read compressed textures in a few formats: PCs use S3TC/BPTC, and Apple Silicon and phones use ETC2/ASTC. *Project Settings > Rendering > Textures > VRAM Compression > Import ETC2 ASTC* makes Godot import both, so the Mac build has them. *Ours:* turned on in #143.

**Ad-hoc signing (Mac).** Apple Silicon Macs only run signed apps. Ad hoc means signed without an Apple Developer account: the Mac runs it, but macOS warns the first time and asks to *Open Anyway*. *Ours:* the macOS preset's *Codesign: Built-in (ad-hoc only)*.

**Stamping settings with `ProjectSettings.save()`.** A script can set any project setting, even one of our own like `application/config/build_commit`, and save it to `project.godot`. *Ours:* `BuildInfo.stamp`, run only while building; `export.sh` puts `project.godot` back afterwards.

**A script run with `-s`.** `godot --headless -s res://some_script.gd` runs a script that `extends SceneTree` instead of the game: a command-line tool written in GDScript. It can't see autoloads like `Game`. *Ours:* `tools/build/prepare_export.gd`.

**Deploy keys (GitHub).** A key that opens one repo only, read-only unless allowed to write. The private half is kept as an encrypted secret that workflows can use. *Ours:* `ASSETS_DEPLOY_KEY` lets the publish workflow read the private art repo.

## Books (#145)

**TextureRect.** A `Control` that shows a picture. `expand_mode` *Ignore Size* lets it be any size, not the picture's own, and `stretch_mode` says how the picture fills it (*Scale* stretches it to fit; *Keep Centered* shows it at its own size in the middle). Like any `CanvasItem` it has its own `texture_filter`: *Linear* blends pixels smoothly when the picture is drawn bigger or smaller than it is. *Ours:* `ui/book_view.tscn`'s `Spread`, the painted open book.

**Measuring text before it's drawn.** `font.get_multiline_string_size(text, alignment, width, size)` says how tall a piece of text would stand if wrapped to `width` at font size `size`, without making a label. *Ours:* `BookView.page_height` measures a page at each size and `body_size_for` picks the largest that fits the paper.

**Theme overrides in code.** A control's look comes from its theme, and any part can be replaced on one control: `add_theme_font_override("font", f)`, `add_theme_font_size_override("font_size", 11)`, `add_theme_color_override("font_color", c)`. They're the same as the *Theme Overrides* section in the Inspector. *Ours:* `BookView` sets the ink, the face and the sizes on each label it makes.

**One page per push of a stick.** A key sends one "pressed" event (repeats are marked as echoes and ignored by default), but a stick held over sends a stream of motion events, and each counts as "pressed". To act once per push, remember the action as held when it's pressed and forget it when `event.is_action_released(...)` comes. *Ours:* `BookView._newly_pushed`.

**A resource made of resources (sub-resources).** A `.tres` file can hold small resources of its own as well as the main one: each `[sub_resource]` block is one, used inside the file with `SubResource("id")`. They live and die with the file, so they're right for parts nobody else shares. *Ours:* `data/books/fire_spirits.tres`, a `Book` whose six `BookPage`s are sub-resources; open it in the Inspector and click into Pages to edit each page.

**CanvasLayer order.** Each `CanvasLayer` has a `layer` number; higher layers draw on top of lower ones, whatever their place in the tree. *Ours:* the HUD's `BookLayer` (16) covers the HUD, and the dialogue's `SpeechLayer` (17) sits above that.

## The first island (#163)

**Building a mesh in code (`ArrayMesh`).** A mesh is lists of numbers: the corners (vertices), which way each faces (normals), where each sits on a texture (UVs), and which corners make each triangle (indices). Fill those lists and hand them to an `ArrayMesh` and you have a mesh no modelling program ever saw. *Ours:* `IslandGround` (`scripts/islands/island_ground.gd`) builds the island's ground, a point every metre, from the heights `IslandShape` gives it; `GrassPatch`, `SunShafts`, `FishShoal` and `IslandBackdrop` build a tuft, a shaft, a fish and the far hills the same way.

**Height-map collision (`HeightMapShape3D`).** A collision shape made of a grid of heights: Godot's shape for terrain. Far cheaper than giving the ground's mesh to the physics engine triangle by triangle. *Ours:* `IslandGround` fills one from the same heights as the mesh, but stops it at knee depth under the sea (`wade_depth`), so you can wade in and no deeper.

**`@tool` scripts.** A script marked `@tool` also runs inside the editor, so what it builds shows in the 3D view while you work. *Ours:* the island's ground, groves, grass, shafts and far hills are all built by `@tool` scripts: change a number in the Inspector and the island changes in front of you. What they build is never saved into the scene file (a child node added in code has no owner, and only owned nodes are saved).

**`MultiMesh`.** One mesh drawn many times in a single go, each copy with its own place, turn and size. Thousands of copies cost about what one does, which is how grass is done. *Ours:* `GrassPatch` draws 70,000 tufts of grass (and the leafy undergrowth, and the beach grass) this way; `SunShafts` and `FishShoal` use it too, and `IslandBackdrop` covers the far hills in 15,000 tree crowns with it (each given its own haze and tint through the MultiMesh's per-copy colour).

**Scattering by rule and seed.** Instead of placing forty palms by hand, give a rule (so many, this far inland, not on steep ground, no closer than so far) and a seed: a number that makes the "random" choices come out the same every time. *Ours:* `IslandScatter` (`scripts/islands/island_scatter.gd`), one node for each kind of plant or rock in `cove.tscn`.

**Volumetric fog and `FogVolume`.** Ordinary fog just fades distant things to a colour. Volumetric fog is lit in 3D: sunlight brightens it, shadows darken it, so light pours visibly between trees. A `FogVolume` node is a box (or other shape) of extra-thick fog in one place. *Ours:* the cove's `WorldEnvironment` has a thin haze everywhere, and the `JungleMist` box hangs thicker mist among the trees behind the front row, so the nearest palms stand dark against a glowing jungle. Volumetric fog only reaches so far from the camera (`volumetric_fog_length`), which is why the fog wall out at sea is painted instead (`shaders/fog_bank.gdshader`).

**SDFGI, SSAO, glow, tonemapping.** Settings on the `Environment`. *SDFGI* bounces light: sunlit sand lights the undersides of the palms. *SSAO* darkens creases where things meet. *Glow* makes very bright things bleed light. *Tonemapping* squeezes the huge range of real brightness into what a screen can show; the mode chosen sets the picture's contrast and colour. *Ours:* all four are on in `cove.tscn`'s `WorldEnvironment`; open it in the Inspector to see each group.

**Sky shader.** A shader of type `sky` paints the background, and Godot takes the scene's ambient light and reflections from it. *Ours:* `shaders/island_sky.gdshader`: blue overhead, warm haze at the horizon, drifting clouds lit on the sun's side.

**Screen and depth textures in a shader.** A material can read what's already been drawn behind it (`hint_screen_texture`) and how far away that is (`hint_depth_texture`). *Ours:* the shore water (`shaders/shore_water.gdshader`) draws the seabed seen through it, bent by its ripples, from the screen texture, and uses the depth texture to find rocks standing in it and ring them with foam. `shaders/sun_shaft.gdshader` uses depth to fade a shaft of light where it meets the ground, so there's no hard line.

**Handing a shader a picture of the world.** A shader only knows about the one point it's drawing. To let the water know how deep it is everywhere, the ground is baked into a small picture (red: its height; green: how far inland of the waterline), and the water shader looks itself up in it. *Ours:* `IslandGround.height_texture()`, handed to the water by `Shore` (`scripts/islands/shore.gd`).

**Moving a mesh in the vertex function.** A shader's `vertex()` function can move each corner of the mesh before it's drawn, with no cost to the CPU. *Ours:* the water's waves (the surface is lifted into crests that roll in and break), the palms' and grass's sway in the wind (`shaders/plant_sway.gdshader`, `shaders/grass_blade.gdshader`: each point is pushed more the higher up the plant it is, and gusts cross the island as travelling waves), and the fish wagging their tails.

**Two shaders that must agree.** The sand goes dark and wet where the water has just been, but the sand and the water are different materials. Each works the wave out for itself from the same numbers (sea level, how far the water rises, how often). *Ours:* `Shore` is the one place those numbers live, and hands them to both; a test checks they match.

**Backlight.** A material's `BACKLIGHT` lets light through from behind, so a thin thing glows when the sun is the other side of it. *Ours:* palm fronds, leaves and grass, in the plant shaders.

**Adding to an instanced scene.** A scene placed inside another is one node there, but you can still hang extra children on it from the outer scene, and they move with it. *Ours:* in `cove.tscn` the ship is the whole `ship.tscn`, with two things added under it: `DeckStart` (a `Marker3D`, an invisible point with a direction, marking where you begin and which way you face) and the deck's `JollyBoat`.

**Awaiting a fade.** A function that uses `await` pauses there until the thing it waits for is done, and the game carries on meanwhile. *Ours:* `JollyBoat.cross` (`scripts/islands/jolly_boat.gd`) awaits the screen fading out, moves you, then awaits it fading back in, with your controls off in between.

**`RigidBody3D`, impulses and physics layers.** A rigid body is moved by the physics engine itself: it falls, rolls and comes to rest. An *impulse* is a sudden push given to one. Every body is on some physics *layers* and collides with the layers in its *mask*, which is how two things can be made to ignore each other. *Ours:* a `Coconut` (`scripts/islands/coconut.gd`) is a rigid body on a layer of its own, so it rests on the ground but never blocks you; when you walk into it, it gives itself an impulse the way you were going.

**MSAA (antialiasing).** Smooths the stair-stepped edges of models by sampling each pixel several times along edges. It's a setting of the viewport. *Ours:* `Island` (`scripts/islands/island.gd`) turns 4x MSAA on while an island is showing and puts it back after.

**Mipmaps.** Smaller copies of a texture that Godot draws when the texture is far away; without them fine detail shimmers in the distance. *Ours:* `ThirdPartyTexture` can make them as it loads (its `mipmaps` setting), used for the photographed sand and forest floor.

## Crew walking (#157)

**AStar3D (shortest paths over a graph).** You give it points (an id and a position) and say which pairs are connected; `get_id_path(from, to)` returns the shortest chain of points between two, and `get_closest_point(position)` the nearest point to anywhere. It's the A* search games have long used for pathfinding. *Ours:* `Walkways` builds one from its `Waypoint` children.

**Waypoints vs navigation meshes.** Godot can also bake a *navigation mesh* (`NavigationRegion3D`) from the floor and let a `NavigationAgent3D` find its own way across it. A hand-placed set of waypoints is simpler and stays put on a moving ship, and you can see exactly where people will walk. *Ours:* the ship's `Walkways`, a child of the ship, so its ways sail with her.

**Moving in a parent's space.** `node.to_local(world_point)` turns a world position into a node's own coordinates, and `to_global` back. Doing the walking in the ship's coordinates means a walker keeps their place on deck while the ship heaves and turns under them. *Ours:* `CrewWalker._physics_process`.

**Borrowing an animation from another file.** An `AnimationPlayer` keeps its animations in `AnimationLibrary`s. Another imported model on the same skeleton has the same bone names, so one of its animations can be copied (`duplicate()`) and added to this player's library with `add_animation(name, animation)`. *Ours:* `CrewAnimator._borrow_walk` takes the heron's walk from his rig's `walk.glb`.

**Raycasts in tests.** `get_world_3d().direct_space_state.intersect_ray(query)` asks the physics engine what a line hits; `query.exclude` lists bodies to ignore. A test can use it to check level layout. *Ours:* `walkways_test.gd` makes sure no walkway runs through a wall.

## Cooking feel and the knife in the chest (#152)

**A hinge is a pivot node.** A node turns about its own origin, so to make a lid swing on its back edge, put a `Node3D` exactly on that edge and the lid's mesh under it, offset forward; turning the pivot's `rotation.x` swings the lid open. *Ours:* `TreasureChest`'s greybox `LidHinge`, and the Meshy chest's `Lid`, whose origin `tools/meshy/split_lid.py` moved to its back edge in Blender.

**A light in the volumetric fog.** With volumetric fog on in the `Environment`, every light also lights the air, and its `light_volumetric_fog_energy` says how much: that's what makes a glowing haze (god rays) around it. Too high and the whole room goes orange. *Ours:* the chest's `Glow` (1.5), on top of the `chest_beam` shader's painted shaft.

**Particles that ride with their node.** By default a particle, once born, stays where it is in the world while its emitter moves on. `local_coords = true` keeps the particles in the emitter's own space, so they travel with it. On a sailing ship, steam that doesn't streams away behind the pan. *Ours:* `PanFeel`'s steam and glints.

**A child is ready before its parent.** `_ready` runs from the leaves up, so in a child's `_ready` the parent's own `_ready` hasn't run and anything it makes there doesn't exist yet. `await get_parent().ready` waits for it. *Ours:* `PanFeel` waits for its `Hob`'s slot.

**Reading a scene's settings without running it.** `PackedScene.get_state()` gives a `SceneState`: every node's name and the properties saved on it, read from the file without building the scene. *Ours:* tests check that the real game's `Player` starts with no tools and that the `GalleyChest` holds the knife.

**Tweening a function.** `tween_method(callable, from, to, seconds)` calls a function with a value easing from one number to another, for anything a property tween can't reach in one go. `callable.bind(x)` adds more arguments after the value. *Ours:* `TreasureChest.swing_open` (the lid and its light together) and `CharacterModel.chop_at` (`_set_chop.bind(point)`).

**See-through by accident: alpha textures.** A model whose texture has an alpha channel is often imported with its material set to *Alpha* transparency, even where every pixel is solid. See-through materials don't hide what's behind them reliably (they're drawn in a later pass, sorted by distance), so a light inside a box shows through its walls. Setting the material's `transparency` back to *Disabled* makes it solid. *Ours:* `TreasureChest._make_solid` and `ItemModel._as_made`, for Meshy's models.

**A fixed time step for pictures.** Saving a screenshot stalls the game, and the next frame's `delta` swallows the stall, so a moment you meant to photograph is skipped. Running Godot with `--fixed-fps 60` makes every frame advance exactly 1/60 s however long it took, so a capture shows what really happens at that frame. (The tests run this way too.)

## The stylised look and the look-dev cabin (#168)

**A shader's `light()` function.** A spatial shader's `fragment()` says what colour a surface is; Godot then works out how each light lights it. Writing your own `light()` replaces that: it runs once per pixel *per light*, is told the surface's direction (`NORMAL`), the light's (`LIGHT`), its colour and how much reaches it (`ATTENUATION`, which includes shadows), and adds to `DIFFUSE_LIGHT` and `SPECULAR_LIGHT`. Snapping "how much it faces the light" to a few steps gives cel shading. *Ours:* `shaders/stylised_character.gdshader`.

**`next_pass`: drawing a mesh twice.** Every material can name a `next_pass` material, and the mesh is drawn again with it straight after. It's the same mesh, bent by the same skeleton, so whatever the second pass draws follows every animation. *Ours:* the outline, which `CharacterStyle` puts after every stylised surface.

**The inverted hull (outlines).** To outline a model, draw it a second time pushed out a little along its normals and show only its *back* faces (`cull_front`), in one dark colour. The body hides the middle, so only a rim round the silhouette shows. *Ours:* `shaders/outline.gdshader`, kept the same width on screen up to a cap in metres.

**`AO` scales only the ambient light.** In a spatial shader, writing `AO` (ambient occlusion) darkens only the light from the environment, not the lamps or the sun (`AO_LIGHT_AFFECT = 0`). It's an easy "how much ambient light" knob. *Ours:* the character style's `ambient_strength`.

**Screen-space indirect light (SSIL).** An `Environment` setting that lets brightly lit surfaces on screen bounce a little of their colour onto what's near them, so a sunlit floor warms the ceiling and the shadows around it. It's cheap and approximate, and only knows what's on screen. *Ours:* `data/art/environments/golden_cabin.tres`.

**An `Environment` saved as its own file.** A `WorldEnvironment`'s settings (sky, ambient light, tone mapping, glow, fog) are an `Environment` resource. Saved as a `.tres`, several scenes can share it and it can be swapped at runtime by setting `world.environment`. *Ours:* `golden_cabin.tres`, which `LookDevCabin.set_golden` swaps with plain studio light.

**A shared resource that tells its users it changed.** A `Resource` can call `emit_changed()` in its property setters; anything connected to its `changed` signal then updates. With `@tool` it works in the editor too, so tuning the file in the Inspector updates the viewport straight away. *Ours:* `CharacterStyle`, which `ThirdPartyModel` listens to.

**Editable children of an instanced scene.** A scene placed inside another (an instance) is sealed: you can move it, but not touch the nodes inside it. Right-click it → *Editable Children* opens it up, so one inner node's property can be changed for this placement only, without touching the original scene. *Ours:* the look-dev cabin's `Heron`, whose `Model/Meshy` gets the stylised `style` there and nowhere else.

## The painted look on the ship and the island (#168)

**A full-screen filter as a mesh.** A quad whose shader ignores its own shape and writes `POSITION = vec4(VERTEX.xy, 1.0, 1.0)` covers the whole screen wherever the camera is. Its shader can read the picture already drawn (`hint_screen_texture`), each pixel's depth and which way its surface faces, and write a new picture. *Ours:* `shaders/painted_filter.gdshader`, hung on the camera by `PaintedLook`.

**The stencil buffer.** A hidden number per pixel that one shader can write (`stencil_mode write, ...`) and a later one can test (`stencil_mode read, compare_equal, ...`), drawing only where it matches. *Ours:* stylised characters mark it; one copy of the painted filter draws only over them (fine brush), another only everywhere else.

**Instance uniforms.** A shader setting declared `instance uniform` belongs to one mesh, not to the material, and is set with `set_instance_shader_parameter`. Many meshes can share one material and still differ. *Ours:* each curtain's width, folds and swing; each character's light cap.

**Shaping a mesh in the vertex shader.** `vertex()` can put every point wherever it likes, from its UV or position, each frame. Nothing is simulated, so it's cheap and can't break. *Ours:* `shaders/curtain_cloth.gdshader` (pleats, swing and ripples), and the plants' sway.

**A viewport's texture sharpness.** `Viewport.texture_mipmap_bias` below zero makes Godot draw every texture from a finer copy than the distance alone would pick, and `anisotropic_filtering_level` keeps them sharp at glancing angles. *Ours:* `PaintedLook` sets both while it's on.

## The boy as the player, and what he wears (#172, #173)

**One skin per mesh, one skeleton for all.** A skinned mesh carries its own `Skin` (which bones move it, and their rest poses), so several meshes made separately can hang on one `Skeleton3D` and follow the same animation. *Ours:* the boy's shirt, trousers, boots and coat, each fitted to his body by `tools/meshy/fit_layer.py` and put on his skeleton by `ThirdPartyModel`.

**An `AnimationLibrary` built in code.** An `AnimationPlayer` plays animations from named libraries. A library can be made at runtime and filled with animations copied from other files, under any names you like. *Ours:* `CharacterModel._whole_library` files the boy's own clips under the names the game asks for ("Walk", "Sword_Regular_A").

**Following a bone without being its child.** A `BoneAttachment3D` follows a bone but lives under the skeleton, so it dies when the model is reloaded. A plain node can follow a bone instead by copying the bone's pose each time the skeleton emits `skeleton_updated`. *Ours:* the boy's hand nodes (`CharacterModel._place_hands`), so the knife he holds outlives his model being dressed again.

**Moving loose parts in code.** A model with no skeleton can still move if it's cut into parts whose origins are their joints: turning a part's `transform` swings it from that joint. *Ours:* the crab's legs and claws (`Crab._move_parts`), cut by `tools/meshy/split_crab.py`.

**Noise in a shader.** A shader can make its own pattern from numbers: a hash turns each whole-numbered spot into a random number, and blending between neighbouring spots gives smooth noise; stretch it one way and it looks like brush strokes. *Ours:* `brush_strokes()` in `shaders/stylised_character.gdshader` breaks the edge between light and shadow into painted strokes (the style's `brush_strength`), and `stroke_offset()` in `shaders/painted_filter.gdshader` brushes every edge of the scenery, laid on the surfaces' positions (worked out from depth) in the ship's own space, so they stay put on the ship as the camera moves and as she sails and rocks (`PaintedLook.scenery_strokes`, pinned by `stroke_anchor`). Pinned to the world instead, the ship sails through the pattern and the strokes crawl over her.

**Where a moving thing is drawn (physics interpolation).** With physics interpolation on, something moved in the physics step is drawn smoothly between ticks, a little apart from where physics has it. `global_transform` is the physics one; `get_global_transform_interpolated()` is where it's drawn this frame. Anything drawn to match it (an effect pinned to it) must use the second, or it lags by up to a tick. *Ours:* `PaintedLook` pins the strokes to the ship with it.

**A brush that follows edges.** A filter can tell which way an edge runs at a pixel by how the brightness changes across it: the edge runs at right angles to the way it rises. Turning each brush dab to lie along that line, stretched into an oval, makes strokes follow the forms (planks, rails, a table's rim), the idea behind the "anisotropic Kuwahara" filter. *Ours:* `brush_flow` in `shaders/painted_filter.gdshader` (`PaintedLook.brush_flow`).

**A rim from the depth buffer.** A full-screen shader can read how far away the surface under each pixel is (`hint_depth_texture`). Where a character's pixel has something much further away just beside it, it's on the character's outer edge, and lightening it there draws a thin rim that separates the character from what's behind, with no outline. *Ours:* `silhouette_rim` in `shaders/painted_filter.gdshader`, on the painted look's characters-only copy (`PaintedLook.character_rim`). The same distance makes faraway things softer and hazier (`far_brush`, `haze_strength`).

**Drawing in a bone's own space.** Every bone has its own coordinate system that moves with it. A shader told where a bone is each frame (as instance uniforms) can turn each point of the mesh into that bone's space, and there a spot on the face stays put however the head turns, so shapes can be drawn on it. *Ours:* the boy's closed eyes (`ClosedEyes`, `data/characters/boy_eyes.tres`), drawn over his painted eyes in his head bone's space; `CharacterModel._place_hands` tells the shader where his head is.

**A pose held from a clip.** To hold a character still in one moment of an animation and still blend in and out of it (a paused AnimationPlayer stops blending too), we copy that moment into a clip of its own: each track gets one key, the value the clip has then (`position_track_interpolate`, `rotation_track_interpolate` and so on), and the copy loops. Playing it with a blend time eases the body into the pose and out again like any other move. *Ours:* `CharacterModel.still_of()` makes `Hold_Up_Still` from the boy's "Cheer with Both Hands" at 0.3 s, struck as `hold_up` rises (`chest_cues.gd`, the item-get).

**Looking at the camera.** `get_viewport().get_camera_3d()` is whichever camera is drawing now, and it's a Node3D like any other, so a head-turn can follow it as it moves. *Ours:* while you hold a treasure up, `ChestCues` sets the character's `watch` to the camera and turns `head_turn` up, and puts both back when you put it away.

## The talk at the rail and the Grave of the Lanterns (#182)

**Lights deep under a surface you can't see through.** The open sea is drawn solid, so nothing placed under it would show. To show faint lights far below anyway, its shader follows each pixel's line of sight (from `CAMERA_POSITION_WORLD` to the surface point) on down through the water to a chosen depth, and asks whether a light hangs there. Because the line carries on at its own angle, the lights stay put under the water and slide past each other as the camera moves, the way deep things do. *Ours:* `grave_lights()` in `shaders/water.gdshader`, three depths of seeded lights, faded in by the Sea's `grave` (the `@grave on` cue).

**Volumetric fog needs something behind it.** Volumetric fog is added to whatever a pixel's ray hits, by how much fog it passes through on the way. A plain clear colour isn't hit by anything, so it gets none, and things in the fog come out *brighter* than the empty water around them: the wrong way round. A big dark sphere round the set (faces turned inwards) gives every ray something to end on, so the fog builds up behind things and they stand dark against it. *Ours:* `Deep` in `scenes/prototype/intro/grave.tscn`, with the fog itself a `FogVolume` box that stops at the surface (`UnderTheSurface`).

**A camera moved by a clip, and physics interpolation.** With physics interpolation on, Godot smooths things moved in the physics step between ticks. A camera moved by an `AnimationPlayer` on rendered frames instead makes it warn ("triggered from outside physics process"). Setting the camera's `physics_interpolation_mode` to Off says "draw me exactly where the clip puts me". *Ours:* the grave set's `Camera`.

**A MultiMesh's copies live in the renderer.** `set_instance_transform` hands each copy's place to the rendering server, and a headless run's stand-in server doesn't keep them, so reading one back in a test gives nothing. Test the numbers the copies are placed from instead. *Ours:* `HangingChain.point_at()`, tested in `tests/scripts/intro/grave_test.gd`.

## The rescue as his sacrifice, to white (#183)

**Clips that each set the whole scene.** Every clip in the underwater set keys every moving thing (the camera, him, you, his hand, the lights, the shape), even what it leaves still. So whichever clip plays, or wherever a skip jumps to, everything is where that moment wants it, and one clip can follow any other. The cost: a new moving thing needs a track in every clip. *Ours:* `scenes/prototype/intro/underwater.tscn`'s `Clips`; #183 added four tracks to all of them (`Flow:flow`, `Flow:filled`, `Lanterns:flicker`, `Lantern/Body:rotation`).

**Turning a child, not the parent.** A child moves with its parent, so turning the parent swings everything hung off it. To turn only part of something, turn that part. *Ours:* his flame hand hangs off `Lantern`, so when he looks down or back at you it's `Lantern/Body` (his glass and face) that turns, and the hand stays on yours.

**Fading CPU particles.** `GPUParticles3D` has `amount_ratio` to thin a stream without restarting it; `CPUParticles3D` doesn't. Its `color` tints every particle instead, if the particle's material has *Vertex Color > Use as Albedo* ticked, so the alpha in that colour fades them all. (Changing a particle node's `amount` or `lifetime` restarts the stream, so set those once.) *Ours:* `LightFlow`'s `Motes`, the gold running along your arm.

**Tweening two things at once.** A `Tween` runs its steps one after another unless you call `set_parallel()`, after which they run together. *Ours:* `ScreenFade.fade_to_white()` brings the cover up and turns its colour white in the same moment, and `fade_out()` from white turns it to black while staying covered.

## Waking with a weak, talking lantern, and the recipe book (#184)

**A prop that plays a cutscene.** Any node can start a scene of its own: find the `Conversation` (`Conversation.find(self)`) and `play()` a `.dlg` by name. *Ours:* the `RecipeBook` by your pillow plays `recipe_book.dlg` when you pick it up, as the chest plays `chest.dlg`; it watches `Game.dialogue.flag_changed` for `has_recipe_book` and hides itself once you have it.

**A tool that isn't used on anything.** Tools on the toolbar are normally used on whatever's in reach (the knife on a board). The recipe book is read instead, wherever you are, so `InteractionDetector3D` checks for it first (`HandTool.is_recipe_book`) and opens the book before looking for a target, and its HUD prompt is the tool's own `verb`.

**A shader can draw outside a mesh's box.** Every mesh has a box round it (`get_aabb()`) that Godot uses to decide what's on screen. It only knows the mesh as made: a material that pushes the surface about in its vertex shader can draw beyond it. *Ours:* the quilt on your bunk draws higher than its box says, so the book was first placed "on" it and came out buried in it.

**A capture camera on a moving ship.** With physics interpolation on, things moved in the physics step (the ship, and everything aboard) are drawn a little behind where they are, smoothed between ticks. A throwaway camera placed by hand isn't, so stills from it show the ship shifted. Taking stills through the game's own camera rig, which is smoothed the same way, shows things where they really are.

## The navigation room (#185)

**A room as a scene of its own.** The room's walls, floor, ceiling and things are one scene (`scenes/prototype/navigation_room.tscn`, a `StaticBody3D` whose `CollisionShape3D` children are its walls), placed in the ship like any prop. It moves with the ship because it's a child of it, and it can be opened and arranged on its own. Other scenes go inside it too: the deck's chart table, the galley's bookshelf, the old book.

**Cutting a doorway in a box wall.** A wall drawn and blocked by one box can't have a hole in it, so it becomes three boxes round the gap: one either side and one over the top (the lintel). The same three for the collision. *Ours:* `BulkheadPort`, `BulkheadStarboard` and `BulkheadLintel` (and their `...Shape`s) in `ship.tscn`.

**Asking the physics world along a line.** `get_world_3d().direct_space_state.intersect_ray(...)` returns the first solid thing between two points, or nothing: a quick way for a test to ask "is this doorway open? is that wall closed?" without walking anyone through. *Ours:* `tests/scenes/navigation_room_test.gd`.

**Something you only look at.** `Inspectable` (`scripts/props/`) is a prop with a `Reach`: Interact says "Look at the chart" and plays a section of `data/dialogue/look.dlg`. Writing what a thing looks like is writing a few lines there.

## The pot, the herbs and the first meal (#186)

**Growing the walkway network.** The crew find their way with Godot's A* search (`AStar3D`) over `Waypoint` markers joined by their `links`; a route runs from the waypoint nearest where they are to the one nearest where they're going. Adding a way somewhere new is adding waypoints and naming the links: Godot joins them both ways. *Ours:* `HatchStarboard`, `PortWaist`, `AftOfHatch`, `PortStairFoot`, `PortStairTop` and `Helm` under `Walkways` in `ship.tscn` take the captain up to the wheel, and `walkways_test.gd` casts a ray along every link to prove nothing solid is in the way (it caught the first try clipping the hatch).

**An overheard line.** A crewmate's `head` is a `Speaker`: `head.say("Could do with a drink.")` shows a bubble over them, heard by anyone near, without starting a conversation. *Ours:* `FirstQuest` when the captain sets off for a drink.

**A method, not a lambda, on an autoload's signal.** `Game.dialogue` lives for the whole game, but the props listening to it come and go. Connect a method (`Game.dialogue.flag_changed.connect(_on_flag_changed)`) and Godot drops the connection when the prop is freed; a lambda that captures things can outlive them and complain ("Lambda capture ... was freed"). *Ours:* `SupperSpot._on_flag_changed` clears the first meal's bowl when the lantern's well.

**`@export_range`.** `@export_range(1, 3) var quality: int` shows a slider in the Inspector that only allows 1 to 3. *Ours:* `Dispenser3D.quality`: the herb planter's is 2.

**How names become cue words.** A cue finds a mark by its node name in snake case, and Godot's `to_snake_case()` splits numbers off: `LanternCircle1` is `lantern_circle_1`, not `lantern_circle1`. *Ours:* `remedy.dlg`; `supper_spot_test.gd` checks every mark and shot it names is really in the ship.

## The voyage to the cove (#187)

**One scene shared by two.** The conversation and its cue handlers are a scene of their own (`scenes/prototype/story.tscn`), instanced in both the sea and the cove. Each place fills in what it differs by: the instance's children can have their settings changed from the outer scene (its `player`, its `fade`), and extra nodes can hang under them (the sea's intro sounds and the cove's anchor clunk under `Story/SoundCues`).

**Changing scene.** `get_tree().change_scene_to_file(path)` throws the whole current scene away and loads another. Anything that should survive the trip has to live outside it: ours is in the `Game` autoload, which is why the story's flags (`arriving`, `at_cove`) carry the voyage across. *Ours:* `TravelCues` (`@travel cove`) and `Opening` (carrying a voyage on at the island). Tests can't let it happen (it would replace the test's own scene), so both have a setting to only say they would.

**`Area3D` as a trigger.** An `Area3D` with a collision shape notices bodies coming in (`body_entered`) without stopping them. *Ours:* `StoryTrigger` at the top of the hatch ramp plays the deck talk when you walk into it, once.

**A body that follows physics (`sync_to_physics`).** The ship is an `AnimatableBody3D` set to move in step with the physics engine, which is what lets her carry you. The catch: set her position directly and the node only shows it after the next physics step, so reading it straight back gives the old one. *Ours:* `CoveArrival` waits two physics steps before standing you on her deck, and tweens her with `tween_method` from and to positions it gives outright rather than reading her position.

**A tween in physics steps.** `create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)` moves things in the physics steps instead of the drawn frames, so a moving deck and the player standing on it agree. *Ours:* the ship sailing into the cove; `set_ease(Tween.EASE_OUT)` slows her to a stop at her anchorage.

## The montage at sea (#197)

**Blending through three looks.** `lerp(a, b, t)` goes from `a` to `b` as `t` goes 0 to 1. Blending the result again towards a third value gives three looks from two numbers: night to dawn by `dawn`, then on to a clear day by `clear`. *Ours:* `TimeOfDay.colour_of` and `number_of`, used for every sky, fog, sun and sea setting.

**Colour correction with a curve (`adjustment_color_correction`).** An `Environment` can push the finished picture through a `GradientTexture1D`: each colour channel's brightness is looked up along the gradient, so it works as a curve per channel. A curve that's grey at each point (the same as its position) changes nothing. *Ours:* the sea's night grade, which cools and greys everything, eases off to that neutral curve as the day clears, or a blue sky could never look blue.

**Fog over the sky (`fog_sky_affect`).** How much the depth fog covers the sky, 0 to 1. At 0.5 a blue sky comes out half fog-grey. *Ours:* turned down to 0.05 on a clear day.

**A class inside a script.** `class Leap:` inside a script makes a small type of its own, used only there: a handy bundle of a few values with names. *Ours:* `LeapingFish` keeps each fish's body, spray and arc in a `Leap`.

**One-shot particles.** A `CPUParticles3D` with `one_shot` set fires all its particles once when told (`restart()`) and then stops. *Ours:* the spray as each fish leaves the water and drops back in.

**Recording the game (Movie Maker).** `godot_console.exe --path . --write-movie out.avi --fixed-fps 30 <scene>` runs the scene and saves every frame and its sound to a video, at a steady 30 frames a second however slow the machine is. *Ours:* how the montage was recorded to send round.

## The ship made (#196)

**Moving a mesh's points.** `mesh.surface_get_arrays(0)` gives a surface's points, normals, texture coordinates and triangles as arrays you can change and build a new mesh from (`SurfaceTool.create_from_arrays`, then `commit()`). Stretch a model unevenly and its normals must be divided by the stretch, not multiplied. *Ours:* `HullShell.fit_mesh` fits the Meshy hull to the ship as it loads.

**Leaving pixels undrawn (`discard`).** In a shader, `discard;` drops the pixel: nothing is drawn there, as if the surface had a hole. It drops it from the shadows too, so light comes through. *Ours:* `hull_shell.gdshader` leaves a hole wherever a `HullOpening` is.

**Which side of a face you're seeing.** In a shader, `FRONT_FACING` is true when you see a triangle from its front. Godot draws a triangle's front where its corners run clockwise. *Ours:* the hull's planks go on its inside skin seen from the front, and on its outer skin seen from behind (through a hole in the inside).

**Data in a vertex's colour.** A mesh's vertex colour (`COLOR` in a shader) can carry any number a shader needs, not only a colour. *Ours:* `HullShell.outer_skin` marks each of the hull's triangles white (outside) or black (inside).

**A per-copy shader setting (`instance uniform`).** One material shared by many meshes, each with its own value: `mesh.set_instance_shader_parameter(&"cover", colour)`. *Ours:* every `ShelfBook` shares one material and sets its own cover colour.

**Collision given to a body.** A physics body only feels `CollisionShape3D`s that are its direct children, or shapes handed to it in code: `create_shape_owner(self)` then `shape_owner_add_shape(id, shape)`. *Ours:* `DeckEdge` gives the ship its decks' edges and walls.

**When a loaded resource is freed.** `load()` keeps a resource only while something holds it. Free the last scene using a model and the model goes; the next `load()` reads it from disk again. A `static var` (one shared by every copy of a script, for the whole run) can hold on to it. *Ours:* `ThirdPartyModel._loaded`, `HullShell._fitted`.

**Children that aren't saved.** `add_child(node, false, Node.INTERNAL_MODE_BACK)` adds an internal child: it's drawn, but it isn't in the Scene dock and isn't saved with the scene. *Ours:* the hull, the decks' edges, the books in a row, a porthole's sleeve.

**A tool script's resources must be tools too.** In the editor, a `@tool` script calling a `Resource`'s functions fails ("placeholder instance") unless that resource's script is `@tool` too. *Ours:* `HullOutline`, used by `DeckEdge`.

**A setting just for builds (feature overrides).** A project setting with `.release` (or `.debug`, `.windows`, ...) on the end of its name wins only where that feature tag is on: `display/window/size/mode.release=3` makes exported release builds start fullscreen while the game run from the editor (a debug run) keeps its window. In the Project Settings window, a setting's Add button offers these overrides. *Ours:* the window mode in `project.godot`.

**Fullscreen, and switching it.** `DisplayServer.window_set_mode(...)` changes the game's window: `WINDOW_MODE_FULLSCREEN` is a borderless window covering the screen (quick to alt-tab), `WINDOW_MODE_EXCLUSIVE_FULLSCREEN` takes over the display. *Ours:* `WindowToggle` (`scripts/app/`, the autoload `FullscreenToggle`) switches on Alt+Enter or F11. An autoload's name and a `class_name` mustn't be the same, so this one's registered as `FullscreenToggle`.

## Glass lanterns with a flame inside (#199)

**Raymarching.** Instead of painting a picture onto a surface, a shader can follow your line of sight *into* the object from each pixel and step along it, asking "what's here?" at each step. Whatever it finds is drawn at its real depth, so it shifts behind the surface as you move. *Ours:* `lantern_flame.gdshader` steps through the thin cylinder round the wick (20 steps) to find the flame, then works out where the ray leaves the box to draw the floor plate, the roof or the far pane's grille.

**Object space in a shader.** In `vertex()`, `VERTEX` is the point in the mesh's own space; `inverse(MODEL_MATRIX) * CAMERA_POSITION_WORLD` brings the camera into that space too. Working there, the flame stays inside the lantern however it swings or is scaled. *Ours:* the lantern glass's `local_spot` and `camera_local`.

**See-through materials (alpha blending).** Setting `ALPHA` below 1 blends the surface over what's behind it. Godot multiplies everything the surface gives off by `ALPHA`, so to add light (a flame behind clear glass) without it fading, give `EMISSION` divided by the alpha. See-through things are drawn after solid ones, sorted back to front; `render_priority` on the material breaks ties. *Ours:* the lantern glass is clear (about 5%) but its flame shines at full strength.

**Throwing pixels away (`discard`).** A fragment shader can `discard` a pixel: it's not drawn at all, and the surface stays solid everywhere else (unlike blending, so it sorts and casts shadows like any solid thing). *Ours:* `glass_cutout.gdshader` throws away every part of a Meshy lantern inside its glass box, so the painted glass vanishes and our glass shows through the frame.

**A custom `light()` function.** A spatial shader can say how each light lights it: Godot calls `light()` once per light per pixel, with `LIGHT`, `ATTENUATION` and `LIGHT_COLOR`, and you add to `DIFFUSE_LIGHT`. *Ours:* the cut-away lantern frame caps each light's share, so the lantern's own light, centimetres away, warms the frame instead of burning it white.

**Shadow bias.** A light's `shadow_bias` pushes shadows slightly away to stop surfaces shadowing themselves (speckled "acne"). Too much, and an occluder very close to the light lets light leak past it. *Ours:* the lantern lights use 0.02 rather than 0.1, so no light pours out under a lantern's solid base.

## The cooking rework (#207)

**A mode that owns the buttons (`_input`).** `_input` hears every press before any `_unhandled_input` does, so a node that's taken over (a mini-game) can grab its presses first and call `set_input_as_handled()` so nothing else acts on them. *Ours:* chop mode in `Counter3D._input`: left click cuts, right click or Esc stops, and the camera rig never sees that Esc (it would free the mouse).

**Theme overrides and StyleBoxes.** Every Control draws itself from its theme; `add_theme_stylebox_override`, `add_theme_color_override` and `add_theme_constant_override` change one look on one node from code. A `StyleBoxFlat` is a coloured box with borders and rounded corners; a `StyleBoxTexture` fills the box with a picture (tiled with `AXIS_STRETCH_MODE_TILE`) tinted by `modulate_color`. A Button has a StyleBox per state (`normal`, `hover`, `pressed`, `focus`, `disabled`); a Label's background is its `normal` StyleBox. *Ours:* the pantry's panel (`ContainerPanel._dress`): a weathered wood back, plank shelves with a dark lip, a paper label.

**Ripples without a texture.** A shader can make a flat disc look like liquid by tilting its normal with a few sine waves of `UV` and `TIME` and writing that to `NORMAL_MAP` (see "Bump and normal maps" above); low `ROUGHNESS` makes the lamps glint off it, and `ALPHA` below 1 lets the pot's floor show through water. *Ours:* `shaders/liquid_surface.gdshader`, the water and soup in a pot or bowl.

**A one-shot particle burst.** A `CPUParticles3D` with `one_shot` on and `explosiveness` near 1 throws all its particles at once when `emitting` is set; its `finished` signal says when the last has died, so it can free itself. *Ours:* the splash at the water butt (`WaterButt._splash`).

## Prologue polish (#203)

**Acting after the clips (`mixer_applied`).** An `AnimationPlayer` (an `AnimationMixer`) sets the properties its clip keys during its own processing each frame, so anything a script sets on those properties earlier in the frame is overwritten. Its `mixer_applied` signal is emitted just after it has set them: connect to it to adjust what the clip did, every frame, and win. *Ours:* `KeepsFacing` (`scripts/intro/keeps_facing.gd`) turns the underwater lantern to face you after his clips have moved him, so they can tip and rock him but never turn him away.

**Depth fog, and the sea going into it.** An `Environment`'s fog with `fog_mode` set to Depth fades things to the fog colour between two distances (`fog_depth_begin`, `fog_depth_end`, shaped by `fog_depth_curve`), and `fog_sky_affect` covers the background too. A shader that reads the screen (our see-through sea) may not be fogged with the rest, so it fades itself by its depth (`-VERTEX.z`, the distance in front of the camera) to the same colour. *Ours:* `grave.tscn`'s environment and `grave_water.gdshader`'s `mist_*` uniforms, matched, so the Grave's sea has no edge.

**World-space versus object-space patterns.** Sampling a texture with a pixel's world position (`v_world.xz`) pins the pattern to the world; with its position in a moving object's space, the pattern rides along with the object. *Ours:* the wake's foam in `water.gdshader` is shaped in the ship's space (straight astern, widening behind her) but patterned in the world's, so the foam stays where she left it and she draws away from it.

**Changing over under black.** A dissolve from one picture to another looks odd when the two don't match; dipping through black (fade out, change everything at once, fade in) reads as a cut in time instead. *Ours:* `@stage off cut` closes the Grave stage at once while the screen is black (`StageCues`); going down into the Grave, the camera instead moves out over the sea, looking down, so the dissolve joins two pictures of dark water.

## The wake-up, the toolbar's pictures and the rain (#206)

**Taking a picture with a SubViewport (icons).** A `SubViewport` with its own world, a camera and a lamp is a little photo studio: put a model in, let it draw, and `get_texture().get_image()` gives you the picture as an `Image`, which `ImageTexture.create_from_image()` turns back into a texture to draw anywhere. `render_target_update_mode` says when it draws: `UPDATE_DISABLED` (never, so it costs nothing), `UPDATE_ONCE`, or `UPDATE_ALWAYS`. A material drawn for the first time can take a frame or two to be ready, so draw a few frames before keeping the picture. *Ours:* `ItemIcons` (`scripts/visuals/item_icons.gd`) photographs each item and tool once, keeps the picture, and `ToolbarBar` draws it in the slot.

**An orthographic camera.** `Camera3D.projection = PROJECTION_ORTHOGONAL` has no perspective: things don't shrink with distance, and `size` says how many metres the picture is across. That makes it easy to fit a model to a picture: measure it, set `size` to match. *Ours:* `ItemIcons._frame()`.

**Mipmaps and texture filtering on a Control.** Drawing a big picture small with the default (nearest) filter makes it crunchy. `CanvasItem.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS` smooths it, using the smaller copies `Image.generate_mipmaps()` made. *Ours:* `ToolbarBar` (the rest of the HUD stays crisp).

**Blurring what's behind with mipmaps.** A screen texture read with `filter_linear_mipmap` can be sampled at a higher mipmap level (`textureLod(screen, uv, 2.5)`) to get a cheap blur: frosted glass. *Ours:* the misted glass in `shaders/rain_glass.gdshader`; each raindrop instead reads the screen sharp and shifted, so it works as a little lens.

**Following a bone.** A character's hand is a node that moves with its bone (`CharacterModel.left_hand`); anything that copies its `global_position` each frame (in `_process`, with physics interpolation off, since it's placed by hand) goes where the hand goes. *Ours:* `CarriedStack3D` puts the held item in the hero's left palm.

**Groups as a lookup.** `get_first_node_in_group(&"lantern_home")` finds whatever node is in that group, wherever it is in the tree, so moving where the lantern lives is a matter of which marker is in the group. *Ours:* the `Perch` in `scenes/prototype/props/lantern_perch.tscn` (it used to be the round table's).

## Below-deck snags (#204)

**Z-fighting.** When two surfaces sit in (almost) the same place, the depth buffer can't tell which is in front, so they flicker in stripes as the camera moves. Fix it by moving one a few centimetres, never by hoping. *Ours:* a bunk's two curtains, bunched together at the head of the bed, hang 2.5 cm apart (`BunkBay.OPEN_STAGGER`).

**Drawn one way, walked another.** What you see and what you collide with are separate: a `MeshInstance3D` is only a look, a `CollisionShape3D` is only a shape. Stairs walked on as stairs catch the player's capsule on every step edge, so games lay a smooth slope under them. *Ours:* `Stairs` (`scripts/ship/stairs.gd`) builds the hatch steps from boxes; you walk on the old ramp's `RampShape` beneath them, each tread's middle on its slope.

**Clearing a box in a shader.** A shader can `discard` every pixel whose position falls inside a box (passed in as its two corners), carving a model without editing it. *Ours:* `HullShell.clear_boxes` keeps the Meshy hull out of the galley and the bunk room, where its bottom rose through the ceiling.

**Particles that change colour as they age.** A `ParticleProcessMaterial`'s `color_ramp` is a gradient each particle runs along from birth to death, and `scale_curve` does the same for its size. *Ours:* the hearth's flames (`GalleyStove._make_flames`) are born yellow and broad at the logs and die small, red and see-through as they rise.

## Letting Claude see the game (#237)

**EditorPlugin.** A script that extends the Godot editor itself: new docks, buttons, import steps, or (for godot-ai) a connection to an outside program. It lives in `addons/<name>/` with a `plugin.cfg`, and only runs once ticked in *Project → Project Settings → Plugins*, which records it under `[editor_plugins]` in `project.godot`. *Ours:* gdUnit4 and godot-ai.

**An autoload added by a plugin.** A plugin can register an autoload so that a script of its own runs inside the game while it's played from the editor. godot-ai's `_mcp_game_helper` relays screenshots, input and the live scene tree back to the editor. It does nothing outside the editor, and godot-ai's export plugin strips it from builds. *Ours:* `project.godot`'s `[autoload]` section.

**Editor Settings vs Project Settings.** Project Settings belong to the game and are saved in `project.godot`, shared through git. Editor Settings belong to your copy of Godot on this computer (*Editor → Editor Settings*, saved in `%APPDATA%\Godot\editor_settings-4.7.tres`) and apply to every project you open. *Ours:* godot-ai's usage-data switch and excluded tool groups are Editor Settings, so each PC sets them once.

**MCP (Model Context Protocol).** The standard way to give an AI assistant extra tools. A small server offers tools (here: "take a screenshot", "press move_up for 30 frames") and Claude Code calls them. `.mcp.json` tells Claude Code which servers to start for this project. *Ours:* the `godot-ai` server, which talks to the editor plugin over a local, authenticated connection.

## Rowing and the current (#226)

**Moving a node by script instead of physics.** A `RigidBody3D` is pushed around by the physics engine: forces, mass, collisions. It's realistic, but hard to steer and free to tip over. A plain `Node3D` that a script moves each physics tick does exactly what the script says, so it can feel good to control and can never capsize. *Ours:* `Rowboat.row()` works out the boat's velocity and heading from the stick and the water, then moves it; `Rowboat.ride()` sets its height and tilt.

**Framerate-independent smoothing with `exp()`.** `lerpf(now, wanted, 1.0 - exp(-rate * delta))` moves a value towards a target the same amount per second however many frames there are, where a fixed `lerpf(now, wanted, 0.1)` would be faster at higher frame rates. Multiplying by `exp(-drag * delta)` is the same idea for slowing down. *Ours:* the boat's drag and turning (`Rowboat.row()`), and how `FollowCamera` swings round.

**`Basis.from_euler()`.** Builds a rotation from three angles in radians: pitch about X, yaw about Y and roll about Z. *Ours:* `Rowboat.ride()` turns the boat to its heading and tilts it with the swell in one go.

**`rotate_toward()` and `lerp_angle()`.** Angles wrap round (a little past 180 degrees is a little past -180), so they can't be moved with plain `lerpf`. `rotate_toward(from, to, step)` turns by at most `step` the short way round; `lerp_angle(from, to, weight)` blends the short way round. *Ours:* the current swinging the boat's bow round (`Rowboat.row()`), and `FollowCamera` swinging round behind it.

**Exports in groups.** `@export_group("Rowing")` puts the exports after it under a foldable heading in the Inspector, so a node with lots of settings stays readable. *Ours:* `Rowboat`'s Rowing, Turning, Riding the sea and Oars.

**Raw keys in a test scene.** `_unhandled_input` receives every input event nothing else used. Checking `InputEventKey.keycode` against a key like `KEY_C` reads a key directly, without an Input Map action, which is fine for a tuning tool that players never see. *Ours:* `RowingGreybox`: C lets the current take the boat, X gives it back.

## Home waters at dusk (#227)

**A procedural sky.** A `WorldEnvironment` with `background_mode` set to Sky draws a `Sky` whose material paints it. A `ProceduralSkyMaterial` needs no picture: you give it a top colour, a horizon colour and how sharply they blend (`sky_curve`), and it draws the sun where the scene's `DirectionalLight3D` points, with a glow round it (`sun_angle_max`). The sky also lights the scene (`ambient_light_source` = Sky). *Ours:* the violet dusk in `home_waters.tscn`, with the low orange sun beyond the buoy.

**Height fog.** Besides the usual fog that thickens with distance (`fog_density`), an `Environment` can make fog thicker low down: below `fog_height` it gets denser by `fog_height_density`. `fog_sky_affect` says how much the fog covers the sky. *Ours:* the violet mist lying on the water round the island; `HomeWaters` thickens `fog_density` as you row out past home waters.

**Resources local to the scene.** Resources (materials, environments) are shared: every copy of a scene uses the same one, so changing it in one changes them all. Ticking `resource_local_to_scene` gives each copy of the scene its own. *Ours:* the home waters `Environment`, so the fog `HomeWaters` thickens is only that copy's (each test loads a fresh one).

**Physics process priority.** Every node's `_physics_process` runs once a tick, lower `process_physics_priority` first (0 is the default, then tree order). *Ours:* `HomeWaters` sets its own to 10, so it runs after the `Rowboat` has moved and its `KeepClear` walls see where the boat went.

**A wall for something that isn't a physics body.** A collision shape only stops physics bodies, and the rowboat is moved by script. So the wall is a sum instead: if the boat's inside the circle, put it back on the edge and take away the part of its speed heading in, which leaves it free to slide along. `Geometry2D.get_closest_point_to_segment()` is the same kind of flat sum for "how near a line". *Ours:* `KeepClear` (`scripts/sea/keep_clear.gd`) round the island, the buoy and the chain's foot; `HomeWaters.chain_distance()`.

**Soft particles from a gradient.** A particle drawn as a plain `QuadMesh` is a hard square. A `GradientTexture2D` with `fill` set to Radial makes a soft dot from a gradient (white in the middle, clear at the edge), and as the quad's texture it makes each particle a puff. With *Billboard* set to Particle the quads always face the camera. *Ours:* the chimney smoke over each cottage in `home_waters.tscn`.

## Testing

**gdUnit4.** The test framework (`addons/gdUnit4`). Suites extend our `GameTestSuite` and have `test_...` functions. `scene_runner` loads a scene and lets a test press inputs and wait physics ticks. *Ours:* `tests/`.

**Vertex displacement.** A spatial shader can move a mesh’s vertices before Godot draws it. The mesh needs enough subdivisions to bend smoothly. The Grave’s water moves the vertices up and down and uses the wave slopes for its lighting and refraction.

**Input Map.** The project names actions independently of their buttons so scripts and prompts can use the same binding. The Journal action comes from the Input Map and the HUD reads its key or controller button.

**Sampling an animation.** An animation can set a property to a point on another clip's timeline. The waking scene samples the imported lying and sitting clips on its cutscene stand-ins so it can cut from the bunk to Lantern and back.
