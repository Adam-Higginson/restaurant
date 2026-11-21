// A porthole's glass on a rainy night: clear, so you see the real storm
// outside (the sea, the rain, the fog), with beads of water sitting on it and
// drops running down. The drops catch the warm light of the room. How rainy
// it is comes from the `wetness` shader global the Weather sets.
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never;

global uniform float wetness;

// The glass's faint cold tint and how much of it shows.
uniform vec4 tint : source_color = vec4(0.5, 0.62, 0.85, 0.12);
// The colour the drops catch from the room's lamps.
uniform vec4 drop_light : source_color = vec4(1.0, 0.78, 0.5, 1.0);
// How many drop columns cross the pane.
uniform float columns = 9.0;
// How many texels across the drops are drawn with, for the chunky look.
uniform float texels = 40.0;


vec3 hash3(vec2 cell) {
	vec3 q = vec3(dot(cell, vec2(127.1, 311.7)), dot(cell, vec2(269.5, 183.3)),
			dot(cell, vec2(419.2, 371.9)));
	return fract(sin(q) * 43758.5453);
}


// A round drop at [param centre] of [param radius]: 1 in the middle, 0 outside.
float drop(vec2 p, vec2 centre, float radius) {
	vec2 d = (p - centre) / radius;
	return sqrt(max(1.0 - dot(d, d), 0.0));
}


void fragment() {
	vec2 from_centre = UV * 2.0 - 1.0;
	if (length(from_centre) > 1.0) {
		discard;
	}
	float wet = clamp(wetness, 0.0, 1.0);

	// Still beads in some cells, and one drop running down each column, drawn
	// on a coarse grid of square texels.
	vec2 p = (floor(UV * texels) + 0.5) / texels * columns;
	vec2 cell = floor(p);
	vec3 h = hash3(cell);
	float water = h.x < 0.45 * wet ? drop(p, cell + 0.3 + 0.4 * h.yz, 0.12 + 0.1 * h.z) : 0.0;
	vec3 column = hash3(vec2(cell.x, 7.0));
	float fall = fract(TIME * (0.06 + 0.1 * column.x) + column.y);
	vec2 runner = vec2(cell.x + 0.3 + 0.4 * column.z, fall * columns);
	water = max(water, drop(p, runner, 0.22) * step(column.x, wet));
	// The thin wet trail a running drop leaves above it.
	float trail = smoothstep(0.08, 0.0, abs(p.x - runner.x)) * step(p.y, runner.y)
			* smoothstep(runner.y - 2.5, runner.y, p.y) * step(column.x, wet);

	// A few hard bands of shading, like a small palette, not smooth domes.
	water = floor(water * 3.0 + 0.5) / 3.0;
	trail = step(0.5, trail);

	// Mostly clear glass; drops glint with the room's warm light on their rims.
	float glint = smoothstep(0.2, 0.6, water) * (1.0 - smoothstep(0.6, 1.0, water));
	ALBEDO = mix(tint.rgb, drop_light.rgb, glint);
	ALPHA = tint.a + 0.3 * water + 0.06 * trail;
}
