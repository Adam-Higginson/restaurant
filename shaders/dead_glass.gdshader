// The glass of a dead lantern on the seabed: dark and dull, until a light
// passes. It can glow warm for a while (glow: the living lantern's flare
// reaching it) and catch a cold sheen (cold: lightning coming down through
// the water). Both are "instance uniforms": every dead lantern shares this
// one material, but each has its own value for them, set by LanternField
// (scripts/intro/lantern_field.gd).
shader_type spatial;
render_mode cull_back;

// The glass with nothing shining on or in it.
uniform vec4 dull : source_color = vec4(0.035, 0.06, 0.065, 1.0);
// The colour it glows when the flare has reached it.
uniform vec4 warm : source_color = vec4(1.0, 0.62, 0.22, 1.0);
// The colour of the lightning's sheen.
uniform vec4 chill : source_color = vec4(0.6, 0.78, 1.0, 1.0);
// How bright the glow is at 1: above 1 it blooms.
uniform float glow_energy = 2.2;
// How bright the sheen is at 1.
uniform float cold_energy = 0.9;

// How strongly this lantern glows right now: 0 dead, about 3 at its glint.
instance uniform float glow = 0.0;
// How bright the lightning is on this lantern right now, 0 to 1.
instance uniform float cold = 0.0;

void fragment() {
	// Brightest in the middle of each pane, as if there were a wick again.
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = dull.rgb;
	ROUGHNESS = 0.35;
	EMISSION = warm.rgb * glow * glow_energy * (1.0 - edge * 0.5)
			+ chill.rgb * cold * cold_energy * (0.35 + edge);
}
