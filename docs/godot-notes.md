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

**Override materials.** A mesh's own materials can be replaced per instance without touching the mesh: `material_override` covers the whole mesh, `set_surface_override_material()` one surface. *Ours:* `ThirdPartyModel` gives pack models the N64 grain shader this way, keeping each model's own colours.

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

**Billboards and render modes.** A shader's `render_mode` line switches whole features on or off: `unshaded` skips lighting, `blend_add` adds its colour to what's behind (good for glows), `fog_disabled` ignores fog. Setting `MODELVIEW_MATRIX` from the camera's rotation makes a quad always face the camera (a *billboard*). *Ours:* `shaders/far_light.gdshader`, the faint light out in the fog (#90).

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

**Stepping logic with `delta`.** `_physics_process(delta)` is told how many seconds have passed since the last tick (1/60). Logic that only ever adds up `delta` doesn't care who is calling it, so a test can hand it any amount of time and check exactly what happened. *Ours:* `CrabCycle.tick(delta)` and `ParryWindow.tick(delta)`; `FogCrab` and `Duellist` call them every physics tick, and the tests call them with whole seconds.

**Groups, for finding many nodes.** As well as finding "the" one of something, `get_tree().get_nodes_in_group(name)` gives every node in a group, and `remove_from_group` takes a node out again. *Ours:* everything in `lock_on_target` can be locked on to and struck; a fog-crab leaves it when its fog clears. The player's `Duellist` is in `duellist`, and the place a defeat puts you is in `landing`.

**Groups set in a scene.** A node can be put in a group in the editor: select it, open the **Node** dock (beside the Inspector), then **Groups**. In the `.tscn` it's saved as `groups=["landing"]`. *Ours:* `Landing` in `duel_arena.tscn`.

**`lerp_angle`.** Like `lerp` (a value part-way between two others), but for angles: it goes the short way round, so easing from 350° to 10° turns 20°, not 340° backwards. *Ours:* `CameraRig._swing_to_target()` eases the camera's yaw towards the locked-on target.

**Easing that ignores frame rate.** `value = lerp(value, goal, 1.0 - exp(-speed * delta))` moves a fixed fraction of the remaining distance per second, however many frames that second has. Plain `lerp(value, goal, 0.1)` would move faster on a faster machine. *Ours:* the camera's zoom and its lock-on swing.

**`atan2` for "which way is it?"** `atan2(-x, -z)` turns a flat direction into the yaw (turn about the up axis) that points a node's forward (-Z) along it. *Ours:* `CameraRig.yaw_along()`, `Player3D.face_towards()`, and the fog-crab turning to face you.

**Angles between directions (`angle_to`).** `a.angle_to(b)` on two `Vector2`s gives the angle from one to the other. Comparing it with half an arc says whether something is "in front". *Ours:* `Duellist.in_reach()`: the knife hits what's within 2 m and inside a 120° arc ahead.

**Signals between plain objects.** Signals aren't only for nodes: a `RefCounted` can declare and emit them too. *Ours:* `Hearts.changed` redraws the `HeartsBar`; `CrabCycle.attacked` tells the `FogCrab` to land its hit; `CrabCycle.state_changed` sets the lantern's light.

**Input Map actions for triggers.** A controller's triggers are *axes* (how far they're pulled), not buttons: bind them as "Joypad Axis 4" (left) and "5" (right). The action's *deadzone* is how far they must be pulled to count as pressed. *Ours:* `lock_on` and `parry` in Project Settings > Input Map, with a deadzone of 0.5.

**`is_action_pressed` and `is_action_released` on an event.** In `_unhandled_input(event)`, these say whether this event is a button going down or coming up, which is what a held button needs. *Ours:* `LockOn` locks on at the press and lets go at the release.

**Sound files and AudioStreamPlayer.** Drop an `.ogg` or `.wav` into the project and Godot imports it as an `AudioStream` (the `.import` file beside it records how). An `AudioStreamPlayer` node plays whatever is in its `stream`, at its `volume_db`, heard the same wherever you are. *Ours:* the six players under `DuelSounds` in `player.tscn` (swing, slice, tink, pan up, clang, hurt).

**AudioStreamPlayer3D.** The same, but the sound comes from the node's place in the world: quieter with distance, and from the left or right of the camera. *Ours:* the three players under `Sounds` in `fog_crab.tscn`, so the far crab's ticking stays far away.

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

**`material_overlay`.** A second material drawn over a mesh on top of its own, without replacing it. *Ours:* `FogCrab` lays a white unshaded one over every mesh of its model for the flash when struck.

**`ImmediateMesh`.** A mesh you rebuild in code every frame: `clear_surfaces()`, then `surface_begin`, a colour and a point per vertex, `surface_end`. *Ours:* `KnifeTrail`, a ribbon through where the blade has been.

**Screen-reading shaders (`hint_screen_texture`).** A `canvas_item` shader can read what's already been drawn behind it, and change it: tint it, blur it, drain its colour. Whatever draws after it isn't affected. *Ours:* `HurtOverlay` (`shaders/hurt_overlay.gdshader`), the first thing in the HUD so the hearts and toolbar stay untouched.

**Audio bus effects.** Every sound goes through a bus (`Master`, `Ambience`), and a bus can have effects such as a low-pass filter. Its settings can change while the game runs: `AudioServer.get_bus_effect` gives you the effect, and `set_bus_effect_enabled` turns it on and off. *Ours:* the `Muffle` low-pass on Master (`default_bus_layout.tres`), swept down by `HitFeel` when you're hurt.

**Skeletons and bones (`Skeleton3D`).** An animated model is a mesh "skinned" to a skeleton: each vertex follows a few bones by weight, so turning a bone bends the mesh. Bones are named and posed in code with `set_bone_pose_rotation` and `set_bone_pose_scale`. *Ours:* `CharacterModel` puts every part on one skeleton and scales the head bone; `FogCrab` lifts the claws through the arm bones.

**`BoneAttachment3D`.** A node that follows one bone of a skeleton, so anything under it moves with that bone. *Ours:* `CharacterModel.right_hand` and `left_hand`, which hold the knife and pan.

**`AnimationPlayer` and `AnimationLibrary`.** Animations live in libraries on a player, named `library/animation`. Each track moves one thing, for a bone written `path/to/Skeleton3D:bone`, so changing the path points an animation at another skeleton with the same bone names. Godot drops a `_Loop` ending from imported names and makes those animations loop. *Ours:* `CharacterModel.retarget` copies the Universal Animation Library's animations onto our skeleton, keeping only rotations.

**Advancing an animation by hand.** With `callback_mode_process` set to Manual, an `AnimationPlayer` only moves on when you call `advance(delta)`. You can then adjust its bones after it, in the same frame. *Ours:* `FogCrab._animate` plays the crab's walk, then lifts its claws on top.

**Mesh arrays (`ArrayMesh`).** `surface_get_arrays` gives a mesh's raw data (positions, bone indices and weights, and the index list of triangles), and `add_surface_from_arrays` builds a mesh from data. *Ours:* `CharacterModel.cut_out` keeps only the triangles the head and neck bones move, to take a head off a whole body.

**Static variables.** `static var` belongs to the class rather than to each node, so every instance (and tests) sees the same one. *Ours:* `CharacterModel.packs_enabled`, which tests switch off, and its cache of cut heads.

**Blender's command line.** `blender -b file.blend --python script.py -- args` runs Blender without a window, opens the file and runs a Python script on it. *Ours:* `tools/blend_to_glb.py` turns the crab's `.blend` into a `.glb` Godot can import.

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

**Driving a shader from a script.** A shader's `uniform` values are its dials. `material.set_shader_parameter("name", value)` turns one from code, every frame if you like, so game state can change how something is drawn. *Ours:* `LanternFace` sends his strength, lean, fog, streaks and crack to `lantern_glass.gdshader`; `CarvedName` sends the lamp's position to `carved_name.gdshader`, which lights the cuts of each letter from that side.

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

**A ragdoll (`PhysicalBoneSimulator3D`, `PhysicalBone3D`).** A skeleton's bones are normally posed by an animation. A `PhysicalBoneSimulator3D` under the skeleton can take some of them over: each gets a `PhysicalBone3D`, a small physics body with a shape, jointed to the one above. Call `physical_bones_start_simulation(names)` and physics decides where those bones hang; the rest still follow the animation. *Ours:* `scripts/art/ragdoll.gd` builds one for the character, and `CharacterModel.limp` switches it on. Only the arms, legs and neck are simulated, so the body still goes where the clip takes it and the limbs trail behind. They're nearly weightless and heavily damped, for water.

**A joint's limits (`joint_constraints/...`).** Each physical bone's joint says how far it may swing and twist from its rest direction. Too loose and limbs fold impossibly; too tight and they look stiff. These are set by name with `set("joint_constraints/swing_span", degrees)`, because Godot adds those properties as it runs. *Ours:* `Ragdoll.SWING_DEGREES` and `TWIST_DEGREES`.

**Hiding part of a model.** A character built from several meshes can show or hide each with `visible`. *Ours:* `CharacterModel.eyes_shut` hides the eyeballs, which leaves the lids' own hollow: closed eyes, with no extra art.

**Queueing an animation (`AnimationPlayer.queue`).** `play()` switches to a clip at once; `queue()` lines one up to start when the current one ends. *Ours:* the `@queue` cue: `pleads` plays once, then the `offered` loop takes over for as long as the player waits.

**Lines that don't wait.** A line in the dialogue box normally waits for a button. `Conversation.say_aside()` shows one that doesn't: the box has no arrow, the script carries on, and whoever asked puts it away. *Ours:* the `@say` and `@say_in` cues (`scripts/cutscene/speech_cues.gd`), for a shout or a plea that should pass with the moment.

**Giving each of many things its own pace.** A small sum that turns an index into a number between 0 and 1, always the same for that index, is enough to make a crowd look unplanned without storing anything. *Ours:* `LanternField.share_of`, which sets how fast each lantern sinks and turns.

## Testing

**gdUnit4.** The test framework (`addons/gdUnit4`). Suites extend our `GameTestSuite` and have `test_...` functions. `scene_runner` loads a scene and lets a test press inputs and wait physics ticks. *Ours:* `tests/`.
