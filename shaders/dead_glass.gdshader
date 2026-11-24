// The glass of a dead lantern hanging in the deep: dark, dull and empty. It
// gives no light of its own. All it does is catch a faint cold sheen when
// lightning comes down through the water (cold), which is an "instance
// uniform": every dead lantern shares this one material, but each has its
// own value, set by LanternField (scripts/intro/lantern_field.gd).
shader_type spatial;
render_mode cull_back;

// The glass with nothing shining on it.
uniform vec4 dull : source_color = vec4(0.03, 0.045, 0.05, 1.0);
// The colour of the lightning's sheen, and how bright it is at 1.
uniform vec4 chill : source_color = vec4(0.6, 0.78, 1.0, 1.0);
uniform float cold_energy = 0.5;

// The last of a flame, for the few in the Grave of the Lanterns that still
// glow: its colour, and how bright it is at 1.
uniform vec4 ember_color : source_color = vec4(1.0, 0.55, 0.18, 1.0);
uniform float ember_energy = 1.6;

// How bright the lightning is on this lantern right now, 0 to 1.
instance uniform float cold = 0.0;
// How much flame is left in this one, 0 to 1. Almost all of them are 0.
instance uniform float ember = 0.0;

void fragment() {
	// Glass shines most where you see it edge-on.
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = dull.rgb;
	ROUGHNESS = 0.3;
	// An ember gutters, each at its own pace (where it hangs sets the beat).
	float seed = dot(NODE_POSITION_WORLD, vec3(1.7, 3.1, 2.3));
	float gutter = 0.75 + 0.15 * sin(TIME * 1.3 + seed) + 0.1 * sin(TIME * 3.7 + seed * 2.0);
	// Lit from inside, the glass glows most face-on.
	EMISSION = chill.rgb * cold * cold_energy * (0.2 + edge)
			+ ember_color.rgb * ember * ember_energy * gutter * (1.0 - edge * 0.6);
}
