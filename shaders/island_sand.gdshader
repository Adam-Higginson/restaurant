// An island's ground: pale sand on the beach, going dark and glossy where
// the waves have just been, with ripples and glints; turning to earth and
// grass over the dune. One shader for the whole ground: it picks what to
// paint from how high each spot is and how steep.
shader_type spatial;

// --- The shore (set by the Shore node, the same numbers as the water) -----
uniform float sea_level = 0.0;
uniform float swash_height = 0.09;
uniform float swash_period = 6.0;

// --- Sand -----------------------------------------------------------------
uniform vec4 sand_color : source_color = vec4(0.93, 0.82, 0.62, 1.0);
uniform vec4 sand_shade : source_color = vec4(0.82, 0.68, 0.47, 1.0);
uniform vec4 wet_color : source_color = vec4(0.52, 0.42, 0.3, 1.0);
// A small soft noise, tiled: the sand's grain, and patchiness when stretched.
uniform sampler2D grain : filter_linear_mipmap, repeat_enable;
uniform float grain_metres = 1.6;
// Wind ripples: a noise used as bumps.
uniform sampler2D ripples : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float ripple_metres = 3.5;
uniform float ripple_strength : hint_range(0.0, 1.0) = 0.35;
// How strongly single grains flash in the sun.
uniform float glints : hint_range(0.0, 4.0) = 1.2;
// How far above the top of the swash the sand stays damp, in metres of height.
uniform float damp_band = 0.16;

// --- Inland ---------------------------------------------------------------
uniform vec4 earth_color : source_color = vec4(0.36, 0.29, 0.17, 1.0);
uniform vec4 grass_color : source_color = vec4(0.23, 0.36, 0.11, 1.0);
// The height where sand starts giving way to earth and grass, and how many
// metres of height the change takes.
uniform float grass_from = 1.5;
uniform float grass_over = 1.6;

// --- Under the water ------------------------------------------------------
// Bright wavering lines of sunlight on the seabed.
uniform float caustics : hint_range(0.0, 2.0) = 0.5;

varying vec3 v_world;
varying vec3 v_world_normal;

float swash(float time) {
	return 0.5 + 0.5 * cos(TAU * (time / swash_period - 0.1));
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 at = v_world.xz;
	float height = v_world.y;
	float fine = texture(grain, at / grain_metres).r;
	float patchy = texture(grain, at / (grain_metres * 9.0) + vec2(0.37, 0.11)).r;

	// Dry sand: two tones, patchy, with a fine grain.
	vec3 sand = mix(sand_shade.rgb, sand_color.rgb, smoothstep(0.25, 0.75, patchy));
	sand *= 0.9 + 0.2 * fine;

	// Wet sand. The water's edge now, and the furthest it gets.
	float water_now = sea_level + swash_height * swash(TIME);
	float water_top = sea_level + swash_height;
	// Damp for good a little above the top of the swash, fraying at its edge.
	float damp = 1.0 - smoothstep(water_top, water_top + damp_band, height + (patchy - 0.5) * 0.06);
	// A glossy film just behind the water as it draws back.
	float film = damp * (1.0 - smoothstep(0.0, 0.07, height - water_now));
	float under = 1.0 - smoothstep(-0.02, 0.02, height - water_now);

	// Inland: earth showing through, then grass, in patches.
	float inland = smoothstep(grass_from, grass_from + grass_over, height + (patchy - 0.5) * 1.2);
	vec3 ground = mix(earth_color.rgb, grass_color.rgb, smoothstep(0.35, 0.65, fine * 0.5 + patchy * 0.5));
	// Steep ground sheds its grass.
	float steep = smoothstep(0.75, 0.55, v_world_normal.y);
	ground = mix(ground, earth_color.rgb, steep);

	vec3 colour = mix(sand, wet_color.rgb, damp * 0.85);
	colour = mix(colour, ground, inland);

	// Sunlight wavering on the seabed, fading with depth.
	float depth = max(0.0, water_now - height);
	vec2 drift = vec2(TIME * 0.05, TIME * 0.035);
	float lines_a = texture(grain, at * 0.21 + drift).r;
	float lines_b = texture(grain, at * 0.17 - drift.yx + vec2(0.5)).r;
	float lines = 1.0 - abs(lines_a - lines_b) * 3.0;
	lines = pow(clamp(lines, 0.0, 1.0), 6.0);
	colour += colour * lines * caustics * under * exp(-depth * 0.5) * 1.5;

	ALBEDO = colour;

	// Ripples on the dry sand; the wet sand is smoothed flat by the water.
	vec3 bump = texture(ripples, at / ripple_metres).rgb;
	NORMAL_MAP = bump;
	NORMAL_MAP_DEPTH = ripple_strength * (1.0 - damp) * (1.0 - inland);

	// Single grains flash: a few bright specks that change as you move.
	float speck = texture(grain, at * 5.3 + VIEW.xy * 0.6).r;
	float flash = smoothstep(0.78, 0.9, speck) * glints * (1.0 - inland) * (1.0 - under);
	ROUGHNESS = mix(mix(0.95, 0.55, damp), 0.12, film);
	SPECULAR = mix(0.25, 0.6, max(film, flash * 0.5));
	EMISSION = sand_color.rgb * flash * 0.06;
}
