// Water at a shore: clear at the edge, turquoise in the shallows, deep blue
// further out, with foam where it meets the sand and lines of foam rolling
// in. Unlike the open sea (water.gdshader), which is opaque and bottomless,
// this water knows how deep it is at every spot: it's handed the ground's
// heights as a picture (ground_heights, from IslandGround), and you see the
// seabed through it, bent by the ripples.
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

// --- The shore (set by the Shore node, the same numbers as the sand) ------
uniform float sea_level = 0.0;
uniform float swash_height = 0.09;
uniform float swash_period = 6.0;
// The ground's heights, one pixel a metre, and the patch of the world the
// picture covers (its corner and size, in x and z).
uniform sampler2D ground_heights : filter_linear, repeat_disable;
uniform vec2 ground_corner = vec2(-90.0, -65.0);
uniform vec2 ground_size = vec2(180.0, 130.0);

// --- Colour ---------------------------------------------------------------
uniform vec4 shallow_color : source_color = vec4(0.36, 0.86, 0.74, 1.0);
uniform vec4 deep_color : source_color = vec4(0.02, 0.27, 0.36, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 0.98, 0.94, 1.0);
// How quickly the water hides the seabed with depth, and takes its deep colour.
uniform float murk = 0.55;
uniform float deepening = 0.3;

// --- Surface --------------------------------------------------------------
uniform sampler2D detail_a : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_b : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float detail_metres = 7.0;
uniform float detail_strength : hint_range(0.0, 1.0) = 0.45;
// How far the ripples bend what's seen through the water.
uniform float bending = 0.03;
// The swell further out: its height in metres and the distance between crests.
uniform float swell_height = 0.16;
uniform float swell_length = 16.0;

// --- Foam -----------------------------------------------------------------
uniform sampler2D foam_noise : filter_linear_mipmap, repeat_enable;
// How deep the water is where the foam at the edge ends.
uniform float edge_foam_depth = 0.07;
// Lines of foam rolling in: how deep the water is where they first show.
uniform float lines_from_depth = 1.1;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;

varying vec3 v_world;
varying float v_level;

float swash(float time) {
	return 0.5 + 0.5 * cos(TAU * (time / swash_period - 0.1));
}

// The ground's height under a spot. Off the edge of the picture it's deep sea.
float ground_at(vec2 at) {
	vec2 uv = (at - ground_corner) / ground_size;
	float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	return mix(-9.0, textureLod(ground_heights, uv, 0.0).r, inside);
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// The whole surface rises and falls with the swash...
	float level = sea_level + swash_height * swash(TIME);
	// ...and a slow swell rolls in from the open sea, dying away in the shallows.
	float depth = max(0.0, level - ground_at(world.xz));
	float open = smoothstep(0.6, 4.0, depth);
	float roll = sin(world.z * TAU / swell_length + world.x * 0.07 + TIME * 0.8);
	float cross = sin(world.x * TAU / (swell_length * 1.7) - world.z * 0.05 + TIME * 0.55);
	level += (roll * 0.65 + cross * 0.35) * swell_height * open;
	VERTEX.y += level - world.y;
	v_world = vec3(world.x, level, world.z);
	v_level = level;
}

void fragment() {
	vec2 at = v_world.xz;
	float depth = v_level - ground_at(at);

	// Ripples: two noises sliding past each other.
	vec2 slide = vec2(TIME * 0.035, TIME * 0.02);
	vec3 bump_a = texture(detail_a, at / detail_metres + slide).rgb;
	vec3 bump_b = texture(detail_b, at / (detail_metres * 0.61) - slide.yx).rgb;
	vec3 bump = mix(bump_a, bump_b, 0.5);
	NORMAL_MAP = bump;
	NORMAL_MAP_DEPTH = detail_strength * smoothstep(0.0, 0.5, depth);

	// What's behind the water, bent by the ripples (less in the shallows).
	vec2 bend = (bump.xy - 0.5) * bending * smoothstep(0.0, 1.0, depth);
	vec3 behind = textureLod(screen_texture, SCREEN_UV + bend, 0.0).rgb;

	// The water's own colour takes over with depth.
	float hidden = 1.0 - exp(-max(depth, 0.0) * murk);
	vec3 water = mix(shallow_color.rgb, deep_color.rgb, 1.0 - exp(-max(depth, 0.0) * deepening));
	// A hint of the shallow colour even where it's clear, so the edge reads.
	vec3 seen = behind * mix(vec3(1.0), shallow_color.rgb * 1.25, clamp(depth * 1.2, 0.0, 0.5));

	// Foam. Broken up by a noise that drifts.
	float noise = texture(foam_noise, at * 0.22 + vec2(TIME * 0.02, -TIME * 0.015)).r;
	float fine = texture(foam_noise, at * 0.9 - vec2(TIME * 0.03, 0.0)).r;
	// At the edge, where the water is a finger deep.
	float edge = 1.0 - smoothstep(0.0, edge_foam_depth, depth - (noise - 0.5) * 0.03);
	// Lines rolling in: each is born out where it's lines_from_depth deep and
	// reaches the sand as the swash comes up the beach.
	float travel = depth / lines_from_depth + TIME / swash_period - 0.1;
	float along = fract(travel);
	float roller = smoothstep(0.0, 0.06, along) * (1.0 - smoothstep(0.06, 0.3, along));
	roller *= 1.0 - smoothstep(0.5, 1.0, depth / lines_from_depth);
	roller *= smoothstep(0.3, 0.6, noise * 0.6 + fine * 0.6);
	// A lacy scum left on the shallows between waves.
	float lace = smoothstep(0.62, 0.8, fine * 0.55 + noise * 0.5) * (1.0 - smoothstep(0.1, 0.9, depth)) * 0.6;
	float foam = clamp(max(max(edge, roller), lace), 0.0, 1.0);

	// The seabed shows through as light; the water's own colour is lit.
	float cover = max(hidden, foam);
	ALBEDO = mix(water, foam_color.rgb, foam) * cover;
	EMISSION = seen * (1.0 - cover);
	ROUGHNESS = mix(0.05, 0.7, foam);
	SPECULAR = 0.5;
	METALLIC = 0.0;
}
