// The thing's eye. It gives no light of its own: it only shows when
// lightning finds it, pale and cold, between two lids, with a dark slit
// down the middle. It's drawn on a flat sheet lying on the thing's head
// and added on top of the picture, so where it's dark it's simply not
// there. ThingEye (scripts/intro/thing_eye.gd) sets open and shine.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;

uniform vec4 colour : source_color = vec4(0.62, 0.86, 0.95, 1.0);
// How bright it is at its brightest.
uniform float energy = 0.75;
// How far the lids are open: 0 shut, 1 wide.
uniform float open = 0.0;
// How much light is on it right now, 0 to 1.
uniform float shine = 0.0;

void fragment() {
	// Across the eye from corner to corner (-1 to 1), and from lid to lid.
	vec2 at = UV * 2.0 - 1.0;
	// The lids: an almond that narrows to nothing as they close.
	float lid = open * 0.6 * sqrt(max(1.0 - at.x * at.x, 0.0));
	float between = 1.0 - smoothstep(lid * 0.82, lid, abs(at.y));
	between *= step(0.001, open);
	// The slit: tall and thin, wider at its middle.
	float slit_width = 0.09 * (1.0 - at.y * at.y * 0.6);
	float slit = 1.0 - smoothstep(slit_width * 0.6, slit_width, abs(at.x));
	// Brighter towards the slit, the way an eye catches light.
	float iris = 0.3 + 0.7 * (1.0 - smoothstep(0.0, 0.8, abs(at.x)));
	// Darker at its rim, so it sits in the head instead of lying on it.
	iris *= 1.0 - 0.6 * smoothstep(lid * 0.45, lid * 0.95, abs(at.y));
	ALBEDO = colour.rgb * energy * shine * between * iris * (1.0 - slit);
}
