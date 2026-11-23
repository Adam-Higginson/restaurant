// Water at a shore: clear at the edge, turquoise in the shallows, deep blue
// further out, with waves that rise, break into foam and run up the sand.
// Unlike the open sea (water.gdshader), which is opaque and bottomless,
// this water knows how deep it is at every spot: it's handed the ground's
// heights as a picture (ground_heights, from IslandGround), and you see the
// seabed through it, bent by the ripples.
//
// The waves are made in two places that must agree. The vertex function
// lifts the surface into crests; the fragment function paints foam on those
// same crests. Both work out where the crests are from the same sum:
// rollers(), below.
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

// --- The shore (set by the Shore node, the same numbers as the sand) ------
uniform float sea_level = 0.0;
uniform float swash_height = 0.09;
uniform float swash_period = 6.0;
// The ground as a picture, one pixel a metre (red: its height; green: how
// far inland of the waterline, negative out at sea), and the patch of the
// world the picture covers (its corner and size, in x and z).
uniform sampler2D ground_heights : filter_linear, repeat_disable;
uniform vec2 ground_corner = vec2(-90.0, -65.0);
uniform vec2 ground_size = vec2(180.0, 130.0);

// --- Colour ---------------------------------------------------------------
uniform vec4 shallow_color : source_color = vec4(0.16, 0.8, 0.68, 1.0);
uniform vec4 deep_color : source_color = vec4(0.0, 0.3, 0.4, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 0.99, 0.96, 1.0);
// How quickly the water hides the seabed with depth, and takes its deep colour.
uniform float murk = 0.36;
uniform float deepening = 0.3;

// --- Surface --------------------------------------------------------------
uniform sampler2D detail_a : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_b : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float detail_metres = 4.5;
uniform float detail_strength : hint_range(0.0, 1.0) = 0.7;
// How far the ripples bend what's seen through the water.
uniform float bending = 0.035;
// The swell further out: its height in metres and the distance between crests.
uniform float swell_height = 0.2;
uniform float swell_length = 15.0;

// --- Breaking waves -------------------------------------------------------
// How far out a wave first rises, and how far apart the waves are, in metres.
uniform float waves_from = 17.0;
uniform float wave_spacing = 6.0;
// How tall a wave stands just before it breaks, in metres.
uniform float wave_height = 0.21;

// --- Foam -----------------------------------------------------------------
uniform sampler2D foam_noise : filter_linear_mipmap, repeat_enable;
// How deep the water is where the foam at the edge ends.
uniform float edge_foam_depth = 0.04;
// How much of the swell's crests break into white further out.
uniform float whitecaps : hint_range(0.0, 1.0) = 0.6;
// How close the water comes to something solid (a rock) before it foams
// round it, in metres.
uniform float ring_metres = 0.22;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear, repeat_disable;

varying vec3 v_world;
varying float v_level;
// How near the top of a swell this spot is, from 0 to 1.
varying float v_crest;

float swash(float time) {
	return 0.5 + 0.5 * cos(TAU * (time / swash_period - 0.1));
}

// The ground under a spot: x is its height, y how far out from the
// waterline it is, in metres. Off the edge of the picture it's deep sea,
// far out.
vec2 ground_at(vec2 at) {
	vec2 uv = (at - ground_corner) / ground_size;
	float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	vec2 here = textureLod(ground_heights, uv, 0.0).rg;
	return mix(vec2(-9.0, 200.0), vec2(here.x, -here.y), inside);
}

// Where a spot is in the waves rolling in, given how far out from the
// waterline it is. x: how far behind a wave's front it is, from 0 (at the
// front) to 1 (where the next wave's front is). y: how strong the waves
// are this far out, from 0 to 1 (they grow as they come in).
vec2 rollers(float out_by, vec2 at) {
	// The fronts aren't dead straight: they wander a little along the beach.
	float wander = sin(at.x * 0.19 + at.y * 0.07) * 0.5 + sin(at.x * 0.071 - 1.3) * 0.5;
	float travel = out_by / wave_spacing + TIME / swash_period - 0.1 + wander * 0.12;
	float strength = smoothstep(waves_from, waves_from * 0.45, out_by);
	return vec2(fract(travel), strength);
}

// A wave's shape across itself: steep at the front, a long back.
float wave_shape(float behind_front) {
	return smoothstep(0.0, 0.1, behind_front) * (1.0 - smoothstep(0.1, 0.6, behind_front));
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// The whole surface rises and falls with the swash...
	float level = sea_level + swash_height * swash(TIME);
	vec2 under = ground_at(world.xz);
	float still_depth = level - under.x;
	// ...a slow swell rolls in from the open sea, dying away in the shallows...
	float open = smoothstep(0.6, 4.0, still_depth);
	float roll = sin(world.z * TAU / swell_length + world.x * 0.07 + TIME * 0.8);
	float cross_roll = sin(world.x * TAU / (swell_length * 1.7) - world.z * 0.05 + TIME * 0.55);
	float swell = roll * 0.65 + cross_roll * 0.35;
	level += swell * swell_height * open;
	v_crest = clamp(swell, 0.0, 1.0) * open;
	// ...and near the sand the waves stand up and break.
	vec2 wave = rollers(under.y, world.xz);
	float standing = smoothstep(0.02, 0.35, still_depth);
	level += wave_shape(wave.x) * wave.y * standing * wave_height;
	VERTEX.y += level - world.y;
	v_world = vec3(world.x, level, world.z);
	v_level = level;
}

void fragment() {
	vec2 at = v_world.xz;
	vec2 under = ground_at(at);
	float depth = v_level - under.x;
	float still_depth = sea_level + swash_height * swash(TIME) - under.x;

	// Ripples: two noises sliding past each other, and a finer chop.
	vec2 slide = vec2(TIME * 0.04, TIME * 0.025);
	vec3 bump_a = texture(detail_a, at / detail_metres + slide).rgb;
	vec3 bump_b = texture(detail_b, at / (detail_metres * 0.57) - slide.yx).rgb;
	vec3 bump_c = texture(detail_a, at / (detail_metres * 0.21) + slide.yx * 2.3).rgb;
	vec3 bump = bump_a * 0.4 + bump_b * 0.35 + bump_c * 0.25;
	NORMAL_MAP = bump;
	NORMAL_MAP_DEPTH = detail_strength * smoothstep(0.0, 0.4, depth);

	// What's behind the water, bent by the ripples (less in the shallows).
	vec2 bend = (bump.xy - 0.5) * bending * smoothstep(0.0, 1.0, depth);
	vec3 behind = textureLod(screen_texture, SCREEN_UV + bend, 0.0).rgb;

	// The water's own colour takes over with depth.
	float hidden = 1.0 - exp(-max(depth, 0.0) * murk);
	vec3 water = mix(shallow_color.rgb, deep_color.rgb, 1.0 - exp(-max(depth, 0.0) * deepening));
	// A hint of the shallow colour even where it's clear, so the edge reads.
	vec3 seen = behind * mix(vec3(1.0), shallow_color.rgb * 1.3, clamp(depth * 1.1, 0.0, 0.55));

	// --- Foam ---
	// Lace: a web of thin lines, like the bubbles left behind a wave. It's
	// drawn where two soft noises, sliding past each other, are equal.
	// It drifts shoreward with the waves.
	float lace_a = texture(foam_noise, at * 0.27 + vec2(TIME * 0.012, -TIME * 0.04)).r;
	float lace_b = texture(foam_noise, at * 0.21 + vec2(-TIME * 0.015, -TIME * 0.028) + vec2(0.4)).r;
	float lace = pow(clamp(1.0 - abs(lace_a - lace_b) * 3.2, 0.0, 1.0), 2.0);
	float soft = texture(foam_noise, at * 0.05 + vec2(TIME * 0.01, 0.0)).r;

	// At the very edge, where the water is a finger deep.
	float edge = 1.0 - smoothstep(0.0, edge_foam_depth, depth - (soft - 0.5) * 0.05);

	// On the breaking waves: solid white at the front, then lace trailing
	// off behind until the next wave. Thicker the nearer the sand.
	vec2 wave = rollers(under.y, at);
	float front = wave_shape(wave.x);
	float front_foam = smoothstep(0.55, 0.85, front * (0.7 + 0.6 * soft) + lace * 0.2);
	float trail = (1.0 - wave.x) * (1.0 - wave.x);
	float trail_foam = smoothstep(0.4, 0.8, lace * (0.3 + trail));
	float breaking = wave.y * smoothstep(0.0, 0.12, still_depth);
	float wave_foam = max(front_foam, trail_foam * 0.85) * breaking;

	// Crests breaking white out in the cove: streaks lying along the swell.
	float streak = texture(foam_noise, at * vec2(0.05, 0.3) + vec2(TIME * 0.01, TIME * 0.02)).r;
	float cap = smoothstep(0.7, 0.92, v_crest * 0.6 + streak * 0.55 + lace * 0.1) * whitecaps;

	// Round rocks: wherever something solid stands in the water (found by
	// how close behind the surface the next solid thing is), away from the
	// beach's own edge, which has its foam already.
	float scene = texture(depth_texture, SCREEN_UV).r;
	vec4 solid = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, scene, 1.0);
	float gap = -solid.z / solid.w + VERTEX.z;
	float ring = 1.0 - smoothstep(0.0, ring_metres * (0.5 + soft), gap);
	ring *= smoothstep(0.2, 0.5, depth);

	float foam = clamp(max(max(edge, wave_foam), max(cap, ring)), 0.0, 1.0);

	// The seabed shows through as light; the water's own colour is lit.
	float cover = max(hidden, foam);
	ALBEDO = mix(water, foam_color.rgb, foam) * cover;
	EMISSION = seen * (1.0 - cover);
	ROUGHNESS = mix(0.04, 0.75, foam);
	SPECULAR = 0.3;
	METALLIC = 0.0;
}
