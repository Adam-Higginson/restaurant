// A porthole's glass with rain on it: a round, faintly tinted pane with
// beads of water sitting on it and drops running down, catching the light.
// How rainy it is comes from the `wetness` shader global the Weather sets.
//
// Drops are drawn on a grid over the pane: each column has one drop sliding
// down at its own speed, and each cell may hold a still bead.
shader_type spatial;
render_mode blend_mix, cull_disabled, specular_schlick_ggx;

global uniform float wetness;

uniform vec4 tint : source_color = vec4(0.55, 0.65, 0.75, 0.1);
// How many drop columns cross the pane.
uniform float columns = 9.0;
// How many still beads, from 0 (none) to 1 (every cell).
uniform float bead_amount : hint_range(0.0, 1.0) = 0.45;


vec3 hash3(vec2 cell) {
	vec3 q = vec3(dot(cell, vec2(127.1, 311.7)), dot(cell, vec2(269.5, 183.3)),
			dot(cell, vec2(419.2, 371.9)));
	return fract(sin(q) * 43758.5453);
}


// A round drop at [param centre] of [param radius]: its height (x) and slope
// (yz), for bending the light.
vec3 drop(vec2 p, vec2 centre, float radius) {
	vec2 d = (p - centre) / radius;
	float r2 = dot(d, d);
	if (r2 >= 1.0) {
		return vec3(0.0);
	}
	float height = sqrt(1.0 - r2);
	return vec3(height, d * 0.8);
}


void fragment() {
	vec2 from_centre = UV * 2.0 - 1.0;
	if (length(from_centre) > 1.0) {
		discard;
	}
	float wet = clamp(wetness, 0.0, 1.0);
	vec2 p = UV * columns;
	vec2 cell = floor(p);
	vec3 h = hash3(cell);

	// A still bead in some cells.
	vec3 water = vec3(0.0);
	if (h.x < bead_amount * wet) {
		water = drop(p, cell + 0.3 + 0.4 * h.yz, 0.12 + 0.1 * h.z);
	}
	// One drop running down each column, then starting again at the top.
	vec3 column = hash3(vec2(cell.x, 7.0));
	float fall = fract(TIME * (0.06 + 0.1 * column.x) + column.y);
	vec2 runner = vec2(cell.x + 0.3 + 0.4 * column.z, fall * columns);
	vec3 running = drop(p, runner, 0.22) * step(column.x, wet);
	// The thin wet trail it leaves above it.
	float trail = smoothstep(0.08, 0.0, abs(p.x - runner.x)) * step(p.y, runner.y)
			* smoothstep(runner.y - 2.5, runner.y, p.y) * step(column.x, wet);
	if (running.x > water.x) {
		water = running;
	}

	ALBEDO = tint.rgb;
	ALPHA = tint.a + 0.35 * water.x + 0.08 * trail;
	ROUGHNESS = 0.05;
	SPECULAR = 0.6;
	NORMAL = normalize(NORMAL + (water.y * TANGENT + water.z * BINORMAL));
}
