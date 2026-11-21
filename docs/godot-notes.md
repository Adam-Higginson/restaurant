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

**Camera3D.** What the player sees. The one marked `current` is used. *Ours:* a temporary `DeckCamera` on the ship in `sea.tscn`, replaced by the follow camera in #62.

**StandardMaterial3D and texture filtering.** A material sets a surface's colour, texture and shininess. *Texture filter* decides how texture pixels are blended when stretched: *Linear* blurs them, *Nearest* keeps them as crisp blocks (the N64/OoT look). "With mipmaps" also uses smaller copies far away, to stop shimmering. Godot has no project-wide setting for this in 3D, so we set it on each material. **Triplanar** mapping projects the texture from the sides, so boxes of any size get evenly sized squares without UV unwrapping. *Ours:* `assets/placeholder/materials/greybox_*.tres`, all sharing the 16-pixel `greybox_grid.png` (one square per metre).

*Still to come with the prototype tickets: `CharacterBody3D`, `Area3D`, `SpringArm3D`, ...*

## Testing

**gdUnit4.** The test framework (`addons/gdUnit4`). Suites extend our `GameTestSuite` and have `test_...` functions. `scene_runner` loads a scene and lets a test press inputs and wait physics ticks. *Ours:* `tests/`.
