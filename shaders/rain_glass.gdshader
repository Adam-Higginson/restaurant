// A porthole's glass on a rainy night (#206: smooth, no longer pixel art).
// You see the real storm outside through it, softened where the glass is
// misted, and sharp but bent through the drops: each drop is a little lens,
// so what's behind it shows shifted and clear. Beads sit on the glass,
// swelling and drying, and now and then a drop runs down, leaving a trail of
// tiny beads. The drops' rims catch the warm light of the room. How rainy it
// is comes from the `wetness` shader global the Weather sets.
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never;

global uniform float wetness;

// The glass's faint cold tint and how much of it shows.
uniform vec4 tint : source_color = vec4(0.5, 0.62, 0.85, 0.12);
// The colour the drops catch from the room's lamps.
uniform vec4 drop_light : source_color = vec4(1.0, 0.78, 0.5, 1.0);
// How many beads fit across the pane (more is smaller).
uniform float columns = 9.0;
// How far a drop bends what's behind it, as a share of the screen.
uniform float refraction = 0.025;
// How blurred the misted glass shows the outside (a mipmap level), and how
// misted the glass gets at the height of a storm.
uniform float mist_blur = 2.5;
uniform float mist = 0.55;
// The colour the pane turns when lightning flashes outside.
uniform vec4 flash_color : source_color = vec4(0.75, 0.85, 1.0, 1.0);
// How bright the lightning is right now, 0 to 1. Each porthole has its own
// (set by Porthole), so it's an instance uniform.
instance uniform float flash = 0.0;

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;


vec3 hash3(vec2 cell) {
	vec3 q = vec3(dot(cell, vec2(127.1, 311.7)), dot(cell, vec2(269.5, 183.3)),
			dot(cell, vec2(419.2, 371.9)));
	return fract(sin(q) * 43758.5453);
}


// A drop at [param centre] of [param radius] (y squashed by [param stretch]):
// xy, the way its surface leans (for the bend and the glint); z, how much of
// it there is, soft at the edge.
vec3 lens(vec2 p, vec2 centre, float radius, float stretch) {
	vec2 d = (p - centre) / radius;
	d.y /= stretch;
	float r2 = dot(d, d);
	if (r2 >= 1.0) {
		return vec3(0.0);
	}
	return vec3(d * sqrt(1.0 - r2 * 0.5), smoothstep(1.0, 0.75, r2));
}


// Beads sitting on the glass, one or none to a cell, each slowly swelling
// and drying away at its own pace.
vec3 beads(vec2 uv, float scale, float wet, float seed, float density) {
	vec2 p = uv * scale;
	vec2 cell = floor(p);
	vec3 h = hash3(cell + seed);
	if (h.x > density * wet) {
		return vec3(0.0);
	}
	float life = fract(TIME * (0.03 + 0.04 * h.y) + h.z);
	float size = (0.12 + 0.16 * h.y) * smoothstep(0.0, 0.25, life) * smoothstep(1.0, 0.7, life);
	if (size <= 0.01) {
		return vec3(0.0);
	}
	vec2 centre = cell + 0.5 + (h.yz - 0.5) * 0.5;
	return lens(p, centre, size, 1.0);
}


// One drop running down a column of the pane now and then, wobbling a
// little, with a trail of tiny beads left behind it.
vec3 runner(vec2 uv, float scale, float wet) {
	float lanes = scale * 0.5;
	vec2 p = uv * lanes;
	float lane = floor(p.x);
	vec3 h = hash3(vec2(lane, 17.0));
	if (h.x > wet) {
		return vec3(0.0);
	}
	// Each run takes a while, then a pause before the next.
	float t = TIME * (0.12 + 0.12 * h.y) + h.z * 7.0;
	float run = fract(t);
	float y = run * 1.4 * lanes - 0.2 * lanes;
	float x = lane + 0.5 + 0.18 * sin(y * 3.1 + h.z * 6.0) + (h.y - 0.5) * 0.3;
	vec3 drop = lens(p, vec2(x, y), 0.2, 1.3);
	// The trail: little beads in the drop's wake, fading the further back.
	float behind = y - p.y;
	if (behind > 0.0 && behind < 0.8 * lanes && abs(p.x - x) < 0.25) {
		vec2 q = vec2(p.x, p.y * 6.0);
		vec2 cell = floor(q);
		vec3 k = hash3(cell + lane * 13.0);
		float fade = 1.0 - behind / (0.8 * lanes);
		if (k.x < 0.6 * fade) {
			vec3 tiny = lens(vec2(p.x, q.y / 6.0), vec2(x + (k.y - 0.5) * 0.1,
					(cell.y + 0.5) / 6.0), 0.04 + 0.04 * k.z * fade, 1.0);
			drop = tiny.z > drop.z ? tiny : drop;
		}
	}
	return drop;
}


void fragment() {
	vec2 from_centre = UV * 2.0 - 1.0;
	if (length(from_centre) > 1.0) {
		discard;
	}
	float wet = clamp(wetness, 0.0, 1.0);

	// The biggest drop over this point wins: running ones over beads, big
	// beads over small.
	vec3 water = beads(UV, columns, wet, 0.0, 0.4);
	vec3 small = beads(UV, columns * 2.3, wet, 41.0, 0.3);
	water = small.z > water.z ? small : water;
	vec3 running = runner(UV, columns, wet);
	water = running.z > 0.0 ? running : water;

	// Through a drop: the outside, sharp and bent. Elsewhere: the glass,
	// misted (blurred) as much as it's wet.
	vec2 bent = SCREEN_UV - water.xy * refraction * water.z;
	vec3 through_drop = textureLod(screen, bent, 0.0).rgb;
	vec3 through_mist = textureLod(screen, SCREEN_UV, mist_blur * wet).rgb;
	float misted = mist * wet;
	vec3 glass = mix(through_mist, tint.rgb, tint.a);
	// A drop is a little lens: the outside shows through it bent and a touch
	// brighter, darker round its edge, with a bright spot where the room's
	// lamps catch its curve.
	vec3 normal = normalize(vec3(water.xy, sqrt(max(1.0 - dot(water.xy, water.xy), 0.05))));
	float edge = smoothstep(0.55, 1.0, length(water.xy));
	vec3 lensed = mix(through_drop * 1.25 + tint.rgb * 0.12, glass, 0.25) * (1.0 - 0.45 * edge);
	float spot = pow(max(dot(normal, normalize(vec3(-0.45, -0.6, 0.65))), 0.0), 18.0);
	lensed += drop_light.rgb * (spot * 0.9 + edge * 0.12);
	vec3 color = mix(glass, lensed, water.z);
	ALBEDO = color;
	ALPHA = mix(max(tint.a, misted), 0.92, water.z);
	// Lightning lights the whole pane cold white-blue, and the drops stand out
	// dark against it.
	ALBEDO = mix(ALBEDO, flash_color.rgb * (1.0 - 0.5 * water.z), flash);
	ALPHA = mix(ALPHA, 0.85, flash);
}
