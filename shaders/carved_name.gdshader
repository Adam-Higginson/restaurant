// The ship's name, chiselled into a dark, weathered plank at her stern.
// The letters aren't laid on the wood, they're cut into it: this draws one
// plank, and uses a picture of the name (white letters on black, see
// CarvedName in scripts/intro/carved_name.gd) as a mask to lower the wood
// where the letters are. It's a bump map worked out as it's drawn.
//
// What makes it wood and not lettering:
//  - everything is drawn on one grid of texels, the letters included, so
//    the carving looks baked into the ship's blocky wood texture;
//  - the grain (broad bands, long fibres, a few cracks) runs straight
//    through the face, the walls and the floor of the cuts;
//  - the edges of the cuts wobble with the grain, as a chisel's would.
//
// Depth comes from three things, all of which follow the light:
//  - the sloping wall of a cut that faces the light is bright, and the wall
//    that faces away is dark;
//  - the dark wall throws a shadow across the floor of the cut;
//  - the slopes, and the grain, are also handed to Godot as a normal map,
//    so every real light (the lantern, the lightning) shades them too.
// The light is the lantern on the hook when he's near, so the lit side of
// every letter swings round as he passes; with no lamp near it's the dull
// sky, from above.
//
// So the name is never quite lost in the dark, there's a faint ember glow
// down in the grooves, a little stronger near the lamp.
shader_type spatial;

// The name, white on black, the same shape as the plank.
uniform sampler2D mask : filter_linear, repeat_disable;
// How many texels to a metre it's all drawn in: lower is chunkier.
uniform float texels_per_metre = 190.0;
// The plank's size in metres.
uniform vec2 plank_size = vec2(3.3, 0.42);
// How wide the sloping wall of a cut is, as a share of the plank's height.
// Wider reads as a deeper, V-shaped cut.
uniform float bevel : hint_range(0.0, 0.15) = 0.045;
// How far the grain pushes the edges of the cuts about, in metres.
uniform float wobble : hint_range(0.0, 0.02) = 0.003;
// How steep the walls of the cuts are to real lights: higher is harder.
uniform float steepness : hint_range(0.0, 8.0) = 2.2;
// The plank's wood: the pale and the dark of its grain.
uniform vec3 wood : source_color = vec3(0.43, 0.275, 0.16);
uniform vec3 wood_dark : source_color = vec3(0.16, 0.097, 0.058);
// How strongly the grain shows, and how dark its cracks are.
uniform float grain : hint_range(0.0, 1.5) = 0.7;
uniform float cracks : hint_range(0.0, 1.0) = 0.55;
// How much darker the wood is on the floor of a cut.
uniform float groove_shade : hint_range(0.0, 1.0) = 0.38;
// How dark the wall facing away from the light is, and how much brighter
// the one facing it.
uniform float wall_shadow : hint_range(0.0, 1.0) = 0.85;
uniform float wall_light : hint_range(0.0, 3.0) = 2.4;
// How dark the shadow thrown onto the floor of a cut is.
uniform float cast_shadow : hint_range(0.0, 1.0) = 0.6;
// The glow down in the grooves, and how bright it is with no lamp near.
uniform vec3 ember : source_color = vec3(1.0, 0.38, 0.08);
uniform float ember_glow : hint_range(0.0, 2.0) = 0.045;
// How much brighter the grooves glow right by the lamp.
uniform float lamp_warmth : hint_range(0.0, 4.0) = 0.16;
// Where the lamp is, measured from the middle of the plank in the plank's
// own space (x along it, y up it, z out from it), and how bright it is
// (0 with no lamp).
uniform vec3 lamp = vec3(0.0, 1000.0, 0.0);
uniform float lamp_glow = 0.0;
// How far the lamp's light reaches along the letters, in metres.
uniform float reach = 1.3;
// How bright a lightning flash is right now, 0 to 1.
uniform float flash = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// How much of the name there is at a spot: 1 inside a letter, 0 outside.
float cut(vec2 uv) {
	return texture(mask, uv).r;
}

void fragment() {
	// Snap to a grid of texels, in metres from the plank's top-left. From
	// here on everything (grain, letters, shading) uses the snapped spot,
	// so it's all drawn in the same chunky squares.
	vec2 at = (floor(UV * plank_size * texels_per_metre) + 0.5) / texels_per_metre;

	// ---- The wood ---------------------------------------------------
	// Grain runs along the plank: broad pale and dark bands, long fibres
	// that waver a little, and fine fibres on top.
	float waver = noise(at * vec2(1.4, 3.0)) * 0.06;
	float bands = noise(vec2(at.x * 0.7, (at.y + waver) * 16.0));
	float fibres = noise(vec2(at.x * 2.4, (at.y + waver) * 62.0));
	float fine = noise(vec2(at.x * 9.0, at.y * 170.0));
	float pale = clamp(0.5 + ((bands - 0.5) * 0.9 + (fibres - 0.5) * 0.8
			+ (fine - 0.5) * 0.45) * grain, 0.0, 1.0);
	// Cracks: a few thin dark lines along the grain, here and there.
	float line = noise(vec2(at.x * 0.9 + 3.0, (at.y + waver) * 40.0));
	float crack = smoothstep(0.79, 0.83, line) * step(0.45, noise(at * vec2(0.6, 9.0) + 5.0));
	vec3 timber = mix(wood_dark, wood, pale * pale) * (1.0 - cracks * crack);

	// ---- The cuts ---------------------------------------------------
	// The grain pushes the chisel about, so the edges aren't quite true.
	vec2 push = (vec2(noise(at * 34.0), noise(at * 34.0 + 9.0)) - 0.5) * 2.0 * wobble;
	push.y += (fibres - 0.5) * wobble;
	vec2 uv = (at + push) / plank_size;
	// One wall's width, as a step in the mask (which is wider than tall).
	vec2 step_uv = vec2(bevel * plank_size.y / plank_size.x, bevel);
	// Look a little way to each side, at six distances, to find which way
	// the wood slopes here and how deep we are. Looking further out makes
	// the walls of the cuts wide and sloping rather than sheer.
	float across = 0.0;
	float down = 0.0;
	float depth = cut(uv);
	for (int i = 1; i <= 6; i++) {
		vec2 reach_uv = step_uv * float(i) / 6.0;
		float right = cut(uv + vec2(reach_uv.x, 0.0));
		float left = cut(uv - vec2(reach_uv.x, 0.0));
		float below = cut(uv + vec2(0.0, reach_uv.y));
		float above = cut(uv - vec2(0.0, reach_uv.y));
		across += right - left;
		down += below - above;
		depth += right + left + below + above;
	}
	depth /= 25.0;
	// How much of a wall this is: 0 on the flat (the plank's face, or the
	// floor of a cut), up to 1 on the steepest part of a slope.
	float wall = clamp(length(vec2(across, down)) / 4.2, 0.0, 1.0);
	// Which way that wall faces, across the plank (x along, y up). The
	// wood drops as the mask rises, so a wall faces into its letter.
	vec2 slope = vec2(across, -down);
	vec2 faces = length(slope) > 0.001 ? normalize(slope) : vec2(0.0);

	// Real lights shade the slopes, and the ridges of the grain, through
	// a normal map. (UV runs down the plank; a normal map's green runs up.)
	vec2 ridges = vec2(0.0, (fibres - 0.5) * 0.9 + crack * 1.2);
	NORMAL_MAP = normalize(vec3(slope * steepness + ridges, 1.0)) * 0.5 + 0.5;

	// ---- The light --------------------------------------------------
	// This spot, in metres from the plank's middle: x along, y up.
	vec2 spot = vec2(at.x - plank_size.x * 0.5, plank_size.y * 0.5 - at.y);
	// Where the light comes from, across the plank: the lamp when it's
	// near, otherwise the dull sky, from above and a little to one side.
	float near = 1.0 - smoothstep(reach * 0.25, reach, distance(vec3(spot, 0.0), lamp));
	float lamp_light = clamp(near * lamp_glow, 0.0, 1.0);
	vec2 to_lamp = lamp.xy - spot;
	vec2 from_lamp = length(to_lamp) > 0.001 ? normalize(to_lamp) : vec2(0.0, 1.0);
	vec2 light_from = normalize(mix(vec2(-0.35, 0.94), from_lamp, lamp_light));
	float towards = dot(faces, light_from);
	float lit_wall = wall * max(towards, 0.0);
	float dark_wall = wall * max(-towards, 0.0);
	// The wall on the light's side shadows the floor beside it: a spot on
	// the floor is in shadow if, a wall's width towards the light, there's
	// uncut plank standing over it.
	vec2 towards_light_uv = vec2(light_from.x, -light_from.y) * step_uv * 1.3;
	float overhang = 1.0 - 0.5 * (cut(uv + towards_light_uv) + cut(uv + towards_light_uv * 0.5));
	float shadowed = cut(uv) * overhang;

	// ---- Putting it together ----------------------------------------
	// It's the same timber everywhere: darker down in the cuts, darker
	// still on the walls turned from the light and in their shadow, and
	// brighter (not paler: still grained) on the walls that face it.
	vec3 colour = timber * (1.0 - groove_shade * depth);
	colour *= 1.0 - wall_shadow * dark_wall;
	colour *= 1.0 - cast_shadow * shadowed;
	colour *= 1.0 + wall_light * lit_wall;
	ALBEDO = colour;
	ROUGHNESS = mix(0.85, 0.6, lit_wall);
	SPECULAR = 0.3;

	// Light of its own, so the carving reads at night: the lit walls
	// glow warm by the lamp (and cold in lightning), and there's a faint
	// ember on the floor of the cuts, breathing slowly.
	float breath = 0.85 + 0.15 * sin(TIME * 1.3 + at.x * 2.0);
	float in_cut = smoothstep(0.3, 0.85, depth) * (1.0 - 0.7 * shadowed);
	vec3 glow = ember * (ember_glow * breath + lamp_light * lamp_warmth) * in_cut
			* (0.5 + pale);
	glow += timber * vec3(3.2, 2.5, 1.7) * lit_wall * lamp_light;
	// Even away from the lamp the lips catch a little of the night sky.
	glow += timber * vec3(0.9, 0.85, 0.8) * lit_wall * 0.55;
	glow += timber * vec3(1.6, 1.9, 2.3) * lit_wall * flash;
	// The lamp lifts the face of the plank a little too, so the grain shows.
	glow += timber * vec3(1.0, 0.8, 0.55) * lamp_light * 0.35 * (1.0 - depth);
	EMISSION = glow;
}
