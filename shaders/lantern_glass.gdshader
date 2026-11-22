// The glass of the lantern spirit. His flame is drawn on the panes as
// chunky pixel fire, the same way as every other lantern aboard
// (shaders/pixel_fire.gdshader), but his can act: it grows and shrinks with
// his strength, cools from amber to blue as he weakens, and leans the way he
// leans. Over it, the glass shows what he's been through: it clouds (fog),
// rain runs down it (streaks), and a hairline crack grows down the front
// when he's badly hurt (crack). LanternFace
// (scripts/companion/lantern_face.gd) sets the uniforms.
shader_type spatial;
render_mode unshaded, cull_back;

// How many texels across (and up) the flame is drawn with.
uniform float texels = 7.0;
// The fire's colours when he's strong...
uniform vec4 hot : source_color = vec4(1.0, 0.92, 0.55, 1.0);
uniform vec4 warm : source_color = vec4(1.0, 0.55, 0.15, 1.0);
uniform vec4 ember : source_color = vec4(0.5, 0.16, 0.04, 1.0);
// ...and when he's nearly out.
uniform vec4 cold_hot : source_color = vec4(0.82, 0.93, 1.0, 1.0);
uniform vec4 cold_warm : source_color = vec4(0.3, 0.55, 1.0, 1.0);
uniform vec4 cold_ember : source_color = vec4(0.05, 0.12, 0.32, 1.0);
// How bright it glows: above 1 it blooms.
uniform float glow = 3.2;
// How fast the flames lick upwards.
uniform float speed = 1.6;
// Each lantern flickers its own way.
uniform float seed = 0.0;
// How strong his flame is, 0 to 1: its height, steadiness and colour.
uniform float strength = 1.0;
// The way his flame tips, in his own space (x and z matter), up to 1.
uniform vec3 lean = vec3(0.0);
// How much the pane glows behind the flame, so his eyes always show.
uniform float backing = 0.55;
// How clouded the glass is, 0 to 1.
uniform float fog = 0.0;
// How much rain is running down it, 0 to 1.
uniform float streaks = 0.0;
// How far the crack has grown down the front, 0 to 1.
uniform float crack = 0.0;
// Half the glass's width and height, in metres, to measure across it.
uniform vec2 half_size = vec2(0.085, 0.1);

varying vec3 local_spot;
varying vec3 local_normal;

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

void vertex() {
	local_spot = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	// Across and up the pane being drawn, each from 0 to 1.
	bool side_pane = abs(local_normal.x) > 0.5;
	float across = side_pane ? local_spot.z : local_spot.x;
	float u = clamp(across / half_size.x * 0.5 + 0.5, 0.0, 1.0);
	float v = clamp(local_spot.y / half_size.y * 0.5 + 0.5, 0.0, 1.0);
	float tip = side_pane ? lean.z : lean.x;

	// Snap to the texel grid, so the flame is drawn in chunky squares.
	vec2 uv = (floor(vec2(u, v) * texels) + 0.5) / texels;
	// Weak, the flame is low and quick; strong, tall and steady.
	float height = mix(0.3, 1.0, strength);
	float up = uv.y / height;
	float t = TIME * speed * mix(2.4, 1.0, strength) + seed * 17.0;
	// The higher up, the further the flame is pushed the way he leans.
	float x = uv.x - tip * 0.45 * uv.y;
	float lick = noise(vec2(x * 4.0, up * 3.0 - t)) * 0.6
			+ noise(vec2(x * 9.0 + 3.0, up * 6.0 - t * 1.7)) * 0.4;
	// Hottest low and in the middle, thinning to tongues at the top.
	float centre = 1.0 - abs(x - 0.5) * 1.6;
	float heat = clamp(centre * (1.2 - up) + lick * 0.7 - up * 0.5, 0.0, 1.0);
	// Snap the heat into a few bands, like a small palette.
	heat = floor(heat * 5.0) / 5.0;

	float cool = 1.0 - smoothstep(0.08, 0.55, strength);
	vec3 hot_now = mix(hot.rgb, cold_hot.rgb, cool);
	vec3 warm_now = mix(warm.rgb, cold_warm.rgb, cool);
	vec3 ember_now = mix(ember.rgb, cold_ember.rgb, cool);
	vec3 colour = mix(ember_now, warm_now, smoothstep(0.1, 0.5, heat));
	colour = mix(colour, hot_now, smoothstep(0.5, 0.9, heat));
	float flicker = 0.85 + 0.15 * noise(vec2(t * 3.0, seed));
	float bright = glow * mix(0.45, 1.0, strength) * flicker;
	colour = colour * (0.4 + heat) * bright;
	// A glow behind the flame, so his eyes are never lost against dark glass.
	colour = max(colour, warm_now * backing * mix(0.5, 1.0, strength));

	// Fog: a milky bloom over everything.
	vec3 misted = mix(warm_now, vec3(1.0), 0.75) * 1.1;
	colour = mix(colour, misted, fog * 0.85);

	// Streaks: a few lanes, each with a bright drop sliding down.
	float lane = floor(u * 6.0);
	float lane_middle = (lane + 0.5) / 6.0;
	float wander = (hash(vec2(lane, 1.0)) - 0.5) * 0.06;
	float in_lane = 1.0 - smoothstep(0.0, 0.035, abs(u - lane_middle + wander));
	float fall = TIME * (0.35 + hash(vec2(lane, 7.0)) * 0.4) + hash(vec2(lane, 3.0));
	float tail = smoothstep(0.55, 1.0, fract(v + fall)) * in_lane * streaks;
	colour = mix(colour, vec3(0.9, 0.96, 1.0) * 1.6, tail * 0.8);

	// The crack: a jagged dark line down the front pane only, from the top.
	if (local_normal.z < -0.5) {
		float line = 0.5 + 0.13 * sin(v * 9.0) + 0.05 * sin(v * 23.0 + 1.3);
		float on_line = 1.0 - smoothstep(0.012, 0.03, abs(u - line));
		float grown = step(1.0 - crack, v) * step(0.001, crack);
		colour = mix(colour, vec3(0.03, 0.02, 0.02), on_line * grown);
	}

	ALBEDO = colour;
}
