// Shafts of light fanning out from between two joined hands. Real light
// through real fingers is too fine for the water's haze to show (it works
// on a coarse grid), so these are painted: a flat sheet facing the camera,
// with bright spokes that slowly shift, strongest near the middle and
// fading outwards, added on top of the picture. FlameHand
// (scripts/intro/flame_hand.gd) puts it at the palm and says how bright.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;

uniform vec4 colour : source_color = vec4(1.0, 0.72, 0.36, 1.0);
// How bright the shafts are right now: 0 none.
uniform float brightness = 0.0;
// Each fan shifts its own way.
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
	vec2 from_middle = UV * 2.0 - 1.0;
	float out_here = length(from_middle);
	// Which way this pixel lies from the middle, as a point on a circle, so
	// the spokes join up all the way round.
	vec2 way = from_middle / max(out_here, 0.0001);
	float t = TIME * 0.3;
	float spokes = noise(way * 2.6 + vec2(seed + t, -t * 0.6))
			* noise(way * 6.5 - vec2(t * 1.4, seed));
	spokes = smoothstep(0.26, 0.7, spokes);
	float reach = (1.0 - smoothstep(0.08, 1.0, out_here)) * smoothstep(0.02, 0.12, out_here);
	ALBEDO = colour.rgb * brightness * spokes * reach;
}
