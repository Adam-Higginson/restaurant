// Small details drawn on a flat quad in chunky texels, with see-through
// gaps: cobwebs in the corners, scuffs on the floor, soot on the ceiling.
// One shader, three looks (pick with `kind`), so they all share the same
// coarse N64 grid as the textures around them.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never;

// 0 a cobweb (from the UV's corner at 0,0), 1 a scuff or soot patch.
uniform int kind = 0;
uniform vec4 colour : source_color = vec4(0.85, 0.85, 0.82, 0.55);
// How many texels across it's drawn with.
uniform float texels = 18.0;
uniform float seed = 0.0;


float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 13.1) * 43758.5453);
}


float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}


void fragment() {
	vec2 uv = (floor(UV * texels) + 0.5) / texels;
	float amount = 0.0;
	if (kind == 0) {
		// Threads fan out from the corner, crossed by sagging rings.
		float r = length(uv);
		float angle = atan(uv.y, uv.x) / (PI * 0.5);
		float spoke = 1.0 - smoothstep(0.0, 0.06, abs(fract(angle * 5.0 + 0.5) - 0.5));
		float ring = 1.0 - smoothstep(0.0, 0.05, abs(fract(r * 4.5 - angle * 0.15) - 0.5) - 0.42);
		amount = max(spoke, ring * step(0.08, r)) * (1.0 - smoothstep(0.75, 1.0, r));
		amount *= step(0.35, hash(floor(UV * texels)));
	} else {
		// A blotchy patch, thickest in the middle.
		float r = length(uv - 0.5) * 2.0;
		amount = smoothstep(1.0, 0.2, r + (noise(uv * 6.0) - 0.5) * 0.8);
		amount = floor(amount * 3.0) / 3.0;
	}
	ALBEDO = colour.rgb;
	ALPHA = colour.a * amount;
	ROUGHNESS = 0.95;
}
