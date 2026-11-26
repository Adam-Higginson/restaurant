// The sea over the Grave of the Lanterns, seen from just above it at night
// (scenes/prototype/intro/grave.tscn). Unlike the open sea it's see-through:
// it reads the picture already drawn behind it (the screen texture) and
// bends it with the ripples, so the lanterns hanging below show through. The
// depth texture says how far each pixel behind it is, so the further you
// look down through the water, the more it hides: there's no bottom, only
// murk. The night sky shows on it at a glancing angle, and rain rings it.
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear, repeat_disable;

// The fine chop, from two normal maps drifting different ways.
uniform sampler2D detail_a : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_b : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float detail_scale = 0.18;
uniform float detail_strength : hint_range(0.0, 1.0) = 0.35;

// How far the ripples bend what's below, as a share of the screen.
uniform float bending = 0.025;
// What the water does to light passing down through it: the colour things
// below are tinted, and the colour it all sinks into with distance.
uniform vec4 tint : source_color = vec4(0.5, 0.72, 0.7, 1.0);
uniform vec4 murk_color : source_color = vec4(0.004, 0.014, 0.02, 1.0);
// How quickly the murk takes things, per metre looked down through.
uniform float murk = 0.11;
// The night sky mirrored at a glancing angle.
uniform vec4 sky_reflection : source_color = vec4(0.1, 0.13, 0.16, 1.0);
// The mist the sea goes into far off: its colour, and between what
// distances from the eye it closes in, in metres (curve > 1 keeps the near
// water clear for longer). Match the set's Environment fog.
uniform vec4 mist_color : source_color = vec4(0.08, 0.115, 0.15, 1.0);
uniform float mist_begin = 7.0;
uniform float mist_end = 29.0;
uniform float mist_curve = 1.6;
// How many raindrops land, 0 to 1.
uniform float rain : hint_range(0.0, 1.0) = 0.8;

float hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

// The slope (x, z) of rain rings around [world]: each cell has a drop
// landing at a random time and place, spreading a ring outwards.
vec2 rain_slope(vec2 world, float time) {
	vec2 slope = vec2(0.0);
	float cell_size = 0.6;
	vec2 base = floor(world / cell_size);
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 cell = base + vec2(float(x), float(y));
			float seed = hash(cell);
			if (seed > rain) {
				continue;
			}
			vec2 centre = (cell + vec2(hash(cell + 3.1), hash(cell + 7.7))) * cell_size;
			float age = fract(time * 1.1 + seed * 13.0);
			vec2 to_here = world - centre;
			float dist = length(to_here);
			float ring = age * 0.45;
			float wave = sin((dist - ring) * 55.0) * smoothstep(0.06, 0.0, abs(dist - ring));
			slope += normalize(to_here + 0.0001) * wave * (1.0 - age) * 0.5;
		}
	}
	return slope;
}

varying vec3 v_world;
varying vec2 swell_normal;

void vertex() {
	float roll = dot(VERTEX.xz, vec2(0.65, 0.43)) - TIME * 1.55;
	float cross_wave = dot(VERTEX.xz, vec2(-0.31, 0.87)) - TIME * 1.16;
	VERTEX.y += 0.23 * sin(roll) + 0.11 * sin(cross_wave);
	swell_normal = -0.23 * cos(roll) * vec2(0.65, 0.43)
			- 0.11 * cos(cross_wave) * vec2(-0.31, 0.87);
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = v_world.xz * detail_scale;
	vec3 na = texture(detail_a, uv + vec2(0.03, 0.02) * TIME).xyz * 2.0 - 1.0;
	vec3 nb = texture(detail_b, uv * 1.6 - vec2(0.025, 0.03) * TIME).xyz * 2.0 - 1.0;
	vec2 slope = swell_normal + (na.xy + nb.xy) * detail_strength + rain_slope(v_world.xz, TIME) * rain;
	vec3 n = normalize(vec3(slope.x, 1.0, slope.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);

	// How far behind the surface the thing at this pixel is: the water the
	// eye looks down through to reach it.
	vec2 bent_uv = SCREEN_UV + slope * bending;
	float scene = texture(depth_texture, bent_uv).r;
	vec4 solid = INV_PROJECTION_MATRIX * vec4(bent_uv * 2.0 - 1.0, scene, 1.0);
	float beyond = -solid.z / solid.w;
	// Something above the water (a raindrop) mustn't be bent in: look straight.
	if (beyond < -VERTEX.z) {
		bent_uv = SCREEN_UV;
		scene = texture(depth_texture, bent_uv).r;
		solid = INV_PROJECTION_MATRIX * vec4(bent_uv * 2.0 - 1.0, scene, 1.0);
		beyond = -solid.z / solid.w;
	}
	float through = max(beyond - (-VERTEX.z), 0.0);
	float hidden = 1.0 - exp(-through * murk);

	vec3 below = textureLod(screen_texture, bent_uv, 0.0).rgb * tint.rgb;
	vec3 water = mix(below, murk_color.rgb, hidden);

	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	// Far off, the sea goes into the mist (#203), so there's no edge to it:
	// the same colour and distances as the set's fog, which the sky gets.
	float misted = pow(smoothstep(mist_begin, mist_end, -VERTEX.z), mist_curve);
	ALBEDO = vec3(0.0);
	EMISSION = mix(water * (1.0 - fresnel) + sky_reflection.rgb * fresnel, mist_color.rgb, misted);
	ROUGHNESS = 0.06;
	SPECULAR = 0.5 * (1.0 - misted);
	METALLIC = 0.0;
}
