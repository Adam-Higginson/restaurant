// Still water in something small (#204): the top of the water butt. Dark and
// deep, a sheen of sky across it that's strongest where you look along it,
// a slow breathing ripple, and, while it rains (the wetness global, 0 to 1),
// rings spreading where the drops land. The sea's own shader is made for
// waves and a hull, and on a still surface it read as a flat colour.
shader_type spatial;
render_mode cull_back, specular_schlick_ggx;

global uniform float wetness;

uniform vec4 deep_colour : source_color = vec4(0.02, 0.045, 0.055, 1.0);
uniform vec4 shallow_colour : source_color = vec4(0.06, 0.13, 0.14, 1.0);
// The sky the surface mirrors, added where you look along it.
uniform vec4 sky_colour : source_color = vec4(0.22, 0.27, 0.32, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.03;
// How many ripple waves span a metre, and how much they tilt the surface.
uniform float ripple_scale = 9.0;
uniform float ripple_strength : hint_range(0.0, 1.0) = 0.25;
// Rain rings: how many cells a metre (one drop in each at a time), and how
// long a ring takes to spread and fade, in seconds.
uniform float drop_cells = 7.0;
uniform float drop_life = 0.9;
uniform float ring_strength : hint_range(0.0, 2.0) = 1.0;

varying vec2 surface;


float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}


// The slope a rain ring gives the surface at [param p] (in metres): each cell
// has one drop at a time, landing somewhere random in it and spreading out.
vec2 ring_slope(vec2 p) {
	vec2 slope = vec2(0.0);
	vec2 cell = floor(p * drop_cells);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 here = cell + vec2(float(x), float(y));
			float offset = hash(here);
			float age = fract(TIME / drop_life + offset);
			// A new place for each drop.
			float turn = floor(TIME / drop_life + offset);
			vec2 at = (here + vec2(hash(here + turn), hash(here - turn))) / drop_cells;
			vec2 away = p - at;
			float far = length(away);
			float radius = age * 1.6 / drop_cells;
			float band = far - radius;
			float wave = sin(band * 90.0) * exp(-band * band * 4000.0);
			slope += away / max(far, 0.0001) * wave * (1.0 - age) * (1.0 - age);
		}
	}
	return slope;
}


void vertex() {
	// In the butt's own space, so the ripples sail with the ship.
	surface = VERTEX.xz;
}


void fragment() {
	vec2 slope = vec2(
			sin(surface.x * ripple_scale + TIME * 0.7) + sin(surface.y * ripple_scale * 0.8 - TIME * 0.5),
			cos(surface.y * ripple_scale * 1.1 + TIME * 0.6) + cos(surface.x * ripple_scale * 0.7 - TIME * 0.4))
			* 0.5 * ripple_strength;
	slope += ring_slope(surface) * ring_strength * clamp(wetness, 0.0, 1.0);
	vec3 bent = normalize(vec3(slope.x, 1.0, slope.y) * vec3(0.12, 1.0, 0.12));
	NORMAL = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(bent, 0.0)).xyz);
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - facing, 4.0);
	ALBEDO = mix(deep_colour.rgb, shallow_colour.rgb, facing * 0.5);
	EMISSION = sky_colour.rgb * fresnel * 0.6;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.6;
}
