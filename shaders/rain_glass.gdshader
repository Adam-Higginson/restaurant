// A porthole's glass on a rainy night: through it, the storm outside (a deep
// blue sky, rain slanting down, the dark sea with a few glints), and on it,
// beads of water and drops running down. It glows faintly blue, the cold
// counterpoint to the warm room.
//
// The view is painted rather than real: outside the porthole is only black
// fog, which would show nothing. How rainy it is comes from the `wetness`
// shader global the Weather sets.
shader_type spatial;
render_mode unshaded, cull_disabled;

global uniform float wetness;

uniform vec4 sky_top : source_color = vec4(0.04, 0.07, 0.17, 1.0);
uniform vec4 sky_low : source_color = vec4(0.16, 0.24, 0.42, 1.0);
uniform vec4 sea : source_color = vec4(0.02, 0.05, 0.1, 1.0);
uniform vec4 rain_colour : source_color = vec4(0.55, 0.65, 0.85, 1.0);
// Where the sea meets the sky, from the top (0) to the bottom (1).
uniform float horizon = 0.62;
// How brightly the view glows.
uniform float glow = 1.3;
// How many texels across it's drawn with, for the chunky look.
uniform float texels = 40.0;
// How many drop columns cross the pane.
uniform float columns = 9.0;


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
	vec2 uv = (floor(UV * texels) + 0.5) / texels;

	// The storm outside.
	vec3 view = mix(sky_top.rgb, sky_low.rgb, smoothstep(0.0, horizon, uv.y));
	if (uv.y > horizon) {
		float deep = smoothstep(horizon, 1.0, uv.y);
		view = mix(sea.rgb * 1.6, sea.rgb, deep);
		// A few glints on the swell.
		vec3 g = hash3(floor(vec2(uv.x * 14.0 + TIME * 0.3, uv.y * 30.0)));
		view += rain_colour.rgb * step(0.94, g.x) * 0.25 * (1.0 - deep);
	}
	// Rain slanting down outside, in thin streaks.
	vec2 slant = vec2(uv.x + uv.y * 0.25, uv.y);
	float lane = floor(slant.x * 26.0);
	vec3 r = hash3(vec2(lane, 3.0));
	// Each lane has a short streak falling at its own speed, if it's raining.
	float fall_at = fract(slant.y * 2.0 - TIME * (1.6 + r.x) + r.y);
	float streak = step(0.8, fall_at) * step(r.z, 0.6 * wet);
	view = mix(view, rain_colour.rgb, streak * 0.35);

	// Water on the glass: still beads, and one drop running down each column.
	vec2 p = UV * columns;
	vec2 cell = floor(p);
	vec3 h = hash3(cell);
	float water = h.x < 0.45 * wet ? drop(p, cell + 0.3 + 0.4 * h.yz, 0.12 + 0.1 * h.z) : 0.0;
	vec3 column = hash3(vec2(cell.x, 7.0));
	float fall = fract(TIME * (0.06 + 0.1 * column.x) + column.y);
	vec2 runner = vec2(cell.x + 0.3 + 0.4 * column.z, fall * columns);
	water = max(water, drop(p, runner, 0.22) * step(column.x, wet));
	// Drops catch the warm light of the room on one side.
	view = mix(view, vec3(0.9, 0.75, 0.55), water * 0.35);

	// A darker rim where the glass meets the brass.
	float rim = smoothstep(0.75, 1.0, length(from_centre));
	ALBEDO = view * glow * (1.0 - 0.5 * rim);
}
