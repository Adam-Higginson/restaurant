// The night sky over the rainy sea: a dark gradient, low cloud drifting
// slowly overhead, and the moon showing through where the cloud thins. The
// cloud near the moon is lit silver at its edges, so the moonlight has a
// visible source.
//
// The moon sits wherever the scene's first DirectionalLight3D (the Moon
// node) shines from, so moving that light moves the moon.
shader_type sky;

group_uniforms sky;
uniform vec3 top_color : source_color = vec3(0.02, 0.028, 0.042);
uniform vec3 horizon_color : source_color = vec3(0.09, 0.105, 0.125);
uniform vec3 below_color : source_color = vec3(0.01, 0.014, 0.02);

group_uniforms moon;
uniform vec3 moon_color : source_color = vec3(0.86, 0.9, 1.0);
uniform float moon_energy = 4.0;
// The moon's width across the sky, in degrees (the real one is about 0.5;
// games draw it bigger).
uniform float moon_degrees = 3.0;
// The soft glow around the moon, close and wide.
uniform float halo_strength = 0.35;

group_uniforms clouds;
uniform sampler2D cloud_noise : repeat_enable, filter_linear, hint_default_black;
// How much of the sky is cloud: 0 clear, 1 overcast.
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.62;
uniform vec3 cloud_color : source_color = vec3(0.06, 0.07, 0.085);
// The colour of cloud edges near the moon.
uniform vec3 lining_color : source_color = vec3(0.55, 0.62, 0.75);
uniform float cloud_speed = 0.006;


void sky() {
	vec3 dir = EYEDIR;
	float up = dir.y;

	vec3 colour = up >= 0.0
			? mix(horizon_color, top_color, smoothstep(0.0, 0.6, up))
			: mix(horizon_color, below_color, smoothstep(0.0, -0.3, up));

	// How close this part of the sky is to the moon, as an angle.
	float near_moon = 0.0;
	float disc = 0.0;
	if (LIGHT0_ENABLED) {
		float angle = acos(clamp(dot(dir, LIGHT0_DIRECTION), -1.0, 1.0));
		float radius = radians(moon_degrees) * 0.5;
		disc = 1.0 - smoothstep(radius * 0.85, radius, angle);
		near_moon = exp(-angle * 3.5);
		colour += moon_color * halo_strength * (exp(-angle * 9.0) * 0.6 + exp(-angle * 40.0));
	}

	// Cloud: two layers of noise, projected onto a ceiling above the sea, so
	// cloud near the horizon looks far away and squashed.
	vec2 sky_spot = dir.xz / (max(up, 0.0) + 0.12);
	vec2 drift = vec2(1.0, 0.35) * TIME * cloud_speed;
	float big = texture(cloud_noise, sky_spot * 0.18 + drift).r;
	float small = texture(cloud_noise, sky_spot * 0.55 - drift * 1.7).r;
	float raw = big * 0.7 + small * 0.3;
	float density = smoothstep(1.0 - cloud_cover, 1.0 - cloud_cover + 0.3, raw);
	density *= smoothstep(-0.05, 0.08, up);
	// Thin cloud (the edges) catches the moonlight; thick cloud stays dark.
	float edge = clamp(density * (1.0 - density) * 4.0, 0.0, 1.0);
	vec3 cloud = cloud_color + lining_color * near_moon * (0.25 + edge);

	colour = mix(colour, cloud, density);
	// The moon behind the cloud: dimmed by how thick it is there.
	colour += moon_color * moon_energy * disc * (1.0 - 0.9 * density);

	COLOR = colour;
}
