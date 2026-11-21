// Chunky pixel flames, N64 style: a fire drawn on a small grid of square
// texels, rising and flickering, glowing so the bloom catches it. Used for the
// stove's firebox and the lantern panes, so every light aboard visibly comes
// from a flame.
shader_type spatial;
render_mode unshaded, cull_disabled;

// How many texels across (and up) the flame is drawn with.
uniform float texels = 10.0;
uniform vec4 hot : source_color = vec4(1.0, 0.92, 0.55, 1.0);
uniform vec4 warm : source_color = vec4(1.0, 0.55, 0.15, 1.0);
uniform vec4 ember : source_color = vec4(0.45, 0.1, 0.02, 1.0);
// How bright it glows: above 1 it blooms.
uniform float glow = 4.0;
// How fast the flames lick upwards.
uniform float speed = 1.6;
// Each fire flickers its own way.
uniform float seed = 0.0;


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


void fragment() {
	// Snap to the texel grid, so the flame is drawn in chunky squares.
	vec2 uv = (floor(UV * texels) + 0.5) / texels;
	float up = 1.0 - uv.y;
	float t = TIME * speed + seed * 17.0;
	float lick = noise(vec2(uv.x * 4.0, up * 3.0 - t)) * 0.6
			+ noise(vec2(uv.x * 9.0 + 3.0, up * 6.0 - t * 1.7)) * 0.4;
	// Hottest low and in the middle, thinning to tongues at the top.
	float centre = 1.0 - abs(uv.x - 0.5) * 1.6;
	float heat = clamp(centre * (1.2 - up) + lick * 0.7 - up * 0.5, 0.0, 1.0);
	// Snap the heat into a few bands, like a small palette.
	heat = floor(heat * 5.0) / 5.0;
	vec3 colour = mix(ember.rgb, warm.rgb, smoothstep(0.1, 0.5, heat));
	colour = mix(colour, hot.rgb, smoothstep(0.5, 0.9, heat));
	float flicker = 0.85 + 0.15 * noise(vec2(t * 3.0, seed));
	ALBEDO = colour * (0.4 + heat) * glow * flicker;
}
