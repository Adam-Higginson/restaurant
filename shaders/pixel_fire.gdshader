// Flames: a fire drawn on a small grid of texels, blended softly between
// them to soften the edges (#137), rising and flickering, glowing so
// the bloom catches it. Used for the stove's firebox and the lantern panes,
// so every light aboard visibly comes from a flame.
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
// Blend the texels softly, to soften the edges; off draws them as
// chunky squares.
uniform bool soft = true;


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


// How hot the flame is at the middle of the texel at [uv].
float heat_at(vec2 uv, float t) {
	float up = 1.0 - uv.y;
	float lick = noise(vec2(uv.x * 4.0, up * 3.0 - t)) * 0.6
			+ noise(vec2(uv.x * 9.0 + 3.0, up * 6.0 - t * 1.7)) * 0.4;
	// Hottest low and in the middle, thinning to tongues at the top.
	float centre = 1.0 - abs(uv.x - 0.5) * 1.6;
	return clamp(centre * (1.2 - up) + lick * 0.7 - up * 0.5, 0.0, 1.0);
}


void fragment() {
	float t = TIME * speed + seed * 17.0;
	float heat;
	if (soft) {
		// Blend neighbouring samples to give the flame soft edges.
		vec2 cell = UV * texels - 0.5;
		vec2 base = floor(cell);
		vec2 f = fract(cell);
		float a = heat_at((base + 0.5) / texels, t);
		float b = heat_at((base + vec2(1.5, 0.5)) / texels, t);
		float c = heat_at((base + vec2(0.5, 1.5)) / texels, t);
		float d = heat_at((base + 1.5) / texels, t);
		heat = mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
		// A few bands still, like a small palette, but their edges blend.
		float banded = heat * 5.0;
		heat = (floor(banded) + smoothstep(0.25, 0.75, fract(banded))) / 5.0;
	} else {
		// Chunky squares and hard bands.
		heat = heat_at((floor(UV * texels) + 0.5) / texels, t);
		heat = floor(heat * 5.0) / 5.0;
	}
	vec3 colour = mix(ember.rgb, warm.rgb, smoothstep(0.1, 0.5, heat));
	colour = mix(colour, hot.rgb, smoothstep(0.5, 0.9, heat));
	float flicker = 0.85 + 0.15 * noise(vec2(t * 3.0, seed));
	ALBEDO = colour * (0.4 + heat) * glow * flicker;
}
