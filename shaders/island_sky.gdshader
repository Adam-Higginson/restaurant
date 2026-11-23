// An island's sky: blue overhead paling to a warm haze at the horizon, a
// glow round the low sun, and soft clouds drifting, lit warm on the sun's
// side. A sky shader paints the background, and Godot also takes the
// scene's ambient light and reflections from it, so the whole island is
// tinted by this.
shader_type sky;

uniform vec4 top_color : source_color = vec4(0.24, 0.52, 0.86, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.97, 0.91, 0.8, 1.0);
uniform vec4 cloud_color : source_color = vec4(1.0, 0.95, 0.86, 1.0);
uniform vec4 cloud_shade : source_color = vec4(0.78, 0.76, 0.74, 1.0);
// A soft tiled noise the clouds are cut from.
uniform sampler2D cloud_noise : filter_linear_mipmap, repeat_enable;
// How much of the sky the clouds fill.
uniform float cover : hint_range(0.0, 1.0) = 0.42;
// How big the clouds are (smaller numbers, bigger clouds).
uniform float cloud_scale = 0.09;
// How fast they drift.
uniform float drift = 0.0015;
// How strong the glow round the sun is.
uniform float sun_glow : hint_range(0.0, 2.0) = 0.5;

void sky() {
	vec3 dir = normalize(EYEDIR);
	float up = clamp(dir.y, 0.0, 1.0);
	vec3 colour = mix(horizon_color.rgb, top_color.rgb, pow(up, 0.38));

	// The glow round the sun, and the sun itself.
	float toward = max(dot(dir, LIGHT0_DIRECTION), 0.0);
	vec3 sun = LIGHT0_COLOR;
	colour += sun * (pow(toward, 6.0) * 0.3 + pow(toward, 40.0) * 0.5) * sun_glow;
	colour += sun * smoothstep(0.9993, 0.9997, toward) * 6.0;

	// Clouds: the noise laid on a flat ceiling far overhead, so they shrink
	// and crowd towards the horizon.
	vec2 ceiling = dir.xz / (dir.y + 0.15) * cloud_scale + vec2(TIME * drift, TIME * drift * 0.4);
	float big = texture(cloud_noise, ceiling).r;
	float small = texture(cloud_noise, ceiling * 2.7 + vec2(0.31, 0.62)).r;
	float cloud = smoothstep(1.0 - cover, 1.15 - cover, big * 0.7 + small * 0.3);
	cloud *= smoothstep(0.0, 0.1, dir.y);
	// Thicker middles are shaded; the sun's side is lit warm.
	float thick = smoothstep(1.05 - cover, 1.4 - cover, big * 0.7 + small * 0.3);
	vec3 lit = mix(cloud_color.rgb, cloud_shade.rgb, thick * 0.7);
	lit += sun * pow(toward, 3.0) * 0.35;
	colour = mix(colour, lit, cloud * 0.9);

	// Below the horizon: haze.
	colour = mix(colour, horizon_color.rgb, smoothstep(0.0, -0.08, dir.y));
	COLOR = colour;
}
