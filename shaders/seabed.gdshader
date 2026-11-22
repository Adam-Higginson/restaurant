// The seabed in the underwater set: dark sand in low dunes, lost in the
// murk until something lights it.
//
// - Dunes: the flat sheet is raised by a sum of slow waves. LanternField
//   (scripts/intro/lantern_field.gd) has the same sum (dune_height), so the
//   dead lanterns sit on the sand.
// - Lightning: light coming down through waves is gathered into a moving
//   net of bright lines (caustics). While a flash lasts (flash), that net
//   is drawn on the sand.
// - The thing: something long is passing, and it's never drawn. Inside its
//   shape (from gap_from to gap_to, gap_width wide) the net of light is
//   missing and the sand is black. You know it by what it blocks.
//
// LanternField sets flash and the gap.
shader_type spatial;
render_mode cull_back;

// The sand, and how much its colour varies from patch to patch.
uniform vec4 sand : source_color = vec4(0.16, 0.15, 0.12, 1.0);
uniform float patchiness = 0.35;
// The colour of the lightning's net of light, and how bright it is.
uniform vec4 net_colour : source_color = vec4(0.62, 0.8, 1.0, 1.0);
uniform float net_energy = 2.4;
// How big the net's meshes are, in metres, and how fast they shift.
uniform float net_size = 5.5;
uniform float net_speed = 0.9;
// How bright the lightning is right now, 0 to 1.
uniform float flash = 0.0;
// The two ends of the thing's middle line in the world (x, z), how wide
// it is in metres, and how much it's there (0 not at all).
uniform vec2 gap_from = vec2(0.0);
uniform vec2 gap_to = vec2(0.0);
uniform float gap_width = 3.4;
uniform float gap = 0.0;

varying vec3 world_spot;

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

// How high the dunes stand at (x, z). The same sum as
// LanternField.dune_height.
float dune(vec2 at) {
	return 0.35 * sin(at.x * 0.31 + 1.3) * cos(at.y * 0.27) + 0.15 * sin(at.x * 0.9 + at.y * 0.7);
}

// The net of light: a few rounds of bending the pattern back on itself,
// which gathers it into thin bright lines the way waves gather light.
float net(vec2 at, float time) {
	vec2 p = mod(at * 6.2831853, 6.2831853) - 250.0;
	vec2 i = p;
	float gathered = 1.0;
	for (int n = 0; n < 4; n++) {
		float t = time * (1.0 - 3.5 / float(n + 1));
		i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
		gathered += 1.0 / length(vec2(p.x / (sin(i.x + t) / 0.005),
				p.y / (cos(i.y + t) / 0.005)));
	}
	gathered = 1.17 - pow(gathered / 4.0, 1.4);
	return pow(abs(gathered), 8.0);
}

// How deep this spot is inside the thing: 1 well inside, 0 outside.
float in_gap(vec2 at) {
	vec2 along = gap_to - gap_from;
	float h = clamp(dot(at - gap_from, along) / max(dot(along, along), 0.0001), 0.0, 1.0);
	float away = length(at - gap_from - along * h);
	return gap * (1.0 - smoothstep(gap_width * 0.35, gap_width * 0.5, away));
}

void vertex() {
	vec3 spot = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += dune(spot.xz);
	// Tip the surface to match, so light falls across the dunes.
	float step_size = 0.5;
	float rise_x = dune(spot.xz + vec2(step_size, 0.0)) - dune(spot.xz - vec2(step_size, 0.0));
	float rise_z = dune(spot.xz + vec2(0.0, step_size)) - dune(spot.xz - vec2(0.0, step_size));
	NORMAL = normalize(vec3(-rise_x, 2.0 * step_size, -rise_z));
	world_spot = spot;
}

void fragment() {
	float patch_here = noise(world_spot.xz * 0.7) * 0.6 + noise(world_spot.xz * 3.1) * 0.4;
	float hidden = in_gap(world_spot.xz);
	ALBEDO = sand.rgb * (1.0 - patchiness + patchiness * patch_here) * (1.0 - hidden);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	float lines = net(world_spot.xz / net_size, TIME * net_speed);
	EMISSION = net_colour.rgb * lines * flash * net_energy * (1.0 - hidden);
}
