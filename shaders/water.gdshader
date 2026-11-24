// The sea. Gerstner waves (the same maths as scripts/sea/waves.gd) move the
// surface; detail ripples, rain rings and foam (on crests, along the hull and
// in the wake) are added per pixel. Sea (scripts/sea/sea.gd) sets the
// uniforms every frame. Godot's fog is applied on top, which hides the edge.
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

// --- Waves (set by Sea from a WaveSettings resource) ----------------------
uniform int wave_count = 0;
// Per layer: direction x, direction z, wave number, speed.
uniform vec4 wave_a[4];
// Per layer: amplitude, sideways push, unused, unused.
uniform vec4 wave_b[4];
// Seconds, already multiplied by the settings' time scale.
uniform float wave_time = 0.0;

// --- The ship (for the hull cut-out, the hull foam and the wake) ----------
uniform mat4 hull_inverse = mat4(1.0);
// Half the hull's width (x) and length (y), in metres: the box from the
// stern to where the bow starts.
uniform vec2 hull_half = vec2(6.0, 15.0);
// How far the pointed bow reaches forward of the box, at the waterline.
uniform float bow_reach = 0.0;
// How strong the wake is: 0 moored, 1 at full sail.
uniform float wake = 0.0;

// --- Weather ---------------------------------------------------------------
// Rain intensity, 0 to 1: how many rain rings dimple the surface.
uniform float rain = 0.0;

// --- Look ------------------------------------------------------------------
uniform vec4 deep_color : source_color = vec4(0.025, 0.06, 0.075, 1.0);
uniform vec4 crest_color : source_color = vec4(0.07, 0.22, 0.23, 1.0);
uniform vec4 foam_color : source_color = vec4(0.62, 0.68, 0.7, 1.0);
uniform float roughness_water : hint_range(0.0, 1.0) = 0.04;
// Seamless normal maps scrolled against each other for the fine chop.
uniform sampler2D detail_a : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_b : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float detail_scale = 0.06;
uniform float detail_strength : hint_range(0.0, 1.0) = 0.5;
// A seamless noise for breaking up foam.
uniform sampler2D foam_noise : filter_linear_mipmap, repeat_enable;
// How pointed a crest must be before it foams.
uniform float crest_foam_from : hint_range(0.0, 1.0) = 0.55;
uniform float hull_foam_width = 1.4;
// How much wider the foam at the bow grows while the ship is under way.
uniform float bow_wave = 1.6;
// Pale glowing plankton stirred up in the foam along the hull and the wake.
uniform vec4 glimmer_color : source_color = vec4(0.25, 0.85, 0.8, 1.0);
uniform float glimmer : hint_range(0.0, 4.0) = 1.2;
// How much crests and foam glow by themselves at night.
uniform float night_glow : hint_range(0.0, 2.0) = 0.6;
// The misty sky the surface mirrors at glancing angles.
uniform vec4 sky_reflection : source_color = vec4(0.2, 0.24, 0.28, 1.0);

// The Grave of the Lanterns far below (#182): a few faint warm lights deep
// under the surface. grave is how much shows, 0 (the open sea) to 1; set by
// the Sea from a cutscene's @grave cue.
uniform float grave = 0.0;
uniform vec4 grave_color : source_color = vec4(1.0, 0.55, 0.2, 1.0);
uniform float grave_energy = 0.45;
// What share of the places one could be actually has a light.
uniform float grave_share : hint_range(0.0, 1.0) = 0.06;

varying vec3 v_world;
varying vec3 v_normal;
varying float v_height;
varying float v_crest;

// Signed distance from the hull's waterline outline (negative inside), in
// metres: a box from the stern forward, then a pointed bow. The outline is a
// polygon, and this is the usual signed distance to a polygon: the nearest
// edge gives the distance, and counting edge crossings gives the sign.
float hull_distance(vec3 world) {
	vec2 p = (hull_inverse * vec4(world, 1.0)).xz;
	float hx = hull_half.x;
	float hz = hull_half.y;
	vec2 v[9] = {
		vec2(hx, hz), vec2(-hx, hz), vec2(-hx, -hz),
		vec2(-hx * 0.87, -hz - bow_reach * 0.48), vec2(-hx * 0.53, -hz - bow_reach * 0.83),
		vec2(0.0, -hz - bow_reach),
		vec2(hx * 0.53, -hz - bow_reach * 0.83), vec2(hx * 0.87, -hz - bow_reach * 0.48),
		vec2(hx, -hz)
	};
	float d = dot(p - v[0], p - v[0]);
	float s = 1.0;
	for (int i = 0; i < 9; i++) {
		int j = (i + 8) % 9;
		vec2 e = v[j] - v[i];
		vec2 w = p - v[i];
		vec2 b = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
		d = min(d, dot(b, b));
		bvec3 c = bvec3(p.y >= v[i].y, p.y < v[j].y, e.x * w.y > e.y * w.x);
		if (all(c) || all(not(c))) {
			s *= -1.0;
		}
	}
	return s * sqrt(d);
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 still = world.xz;
	vec3 moved = vec3(0.0);
	// Slopes of the surface along x (binormal) and z (tangent).
	vec3 binormal = vec3(1.0, 0.0, 0.0);
	vec3 tangent = vec3(0.0, 0.0, 1.0);
	float crest = 0.0;
	for (int i = 0; i < wave_count; i++) {
		vec2 dir = wave_a[i].xy;
		float k = wave_a[i].z;
		float phase = k * (dot(dir, still) - wave_a[i].w * wave_time);
		float amp = wave_b[i].x;
		float side = wave_b[i].y;
		float s = sin(phase);
		float c = cos(phase);
		moved += vec3(dir.x * side * amp * c, amp * s, dir.y * side * amp * c);
		float ka = k * amp;
		binormal += vec3(-side * dir.x * dir.x * ka * s, dir.x * ka * c, -side * dir.x * dir.y * ka * s);
		tangent += vec3(-side * dir.x * dir.y * ka * s, dir.y * ka * c, -side * dir.y * dir.y * ka * s);
		crest += side * ka * s;
	}
	// The mesh is only ever moved, never turned, so a world offset is a local one.
	VERTEX += moved;
	v_world = world + moved;
	v_normal = normalize(cross(tangent, binormal));
	v_height = moved.y;
	v_crest = crest;
}

// A small random number for a grid cell.
float hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

// The slope (x, z) of rain rings around [world]: each 1.2 m cell has a drop
// landing at a random time and place, spreading a ring outwards.
vec2 rain_slope(vec2 world, float time) {
	vec2 slope = vec2(0.0);
	float cell_size = 1.2;
	vec2 base = floor(world / cell_size);
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 cell = base + vec2(float(x), float(y));
			float seed = hash(cell);
			// Fewer drops land when the rain is lighter.
			if (seed > rain) {
				continue;
			}
			vec2 centre = (cell + vec2(hash(cell + 3.1), hash(cell + 7.7))) * cell_size;
			float age = fract(time * 0.9 + seed * 13.0);
			vec2 to_here = world - centre;
			float dist = length(to_here);
			float ring = age * 0.9;
			float wave = sin((dist - ring) * 28.0) * smoothstep(0.12, 0.0, abs(dist - ring));
			slope += normalize(to_here + 0.0001) * wave * (1.0 - age) * 0.35;
		}
	}
	return slope;
}

// How much light from the Grave of the Lanterns reaches the surface at
// [world], seen from [eye]. The view ray carries on down through the surface
// to three depths, and at each a few seeded spots hold a dying light. Because
// each is found where the ray reaches its depth, the lights sit under the
// water and slide past each other as the camera moves, as deep things do.
float grave_lights(vec3 world, vec3 eye, float time) {
	vec3 ray = normalize(world - eye);
	// Looking flat across the water, nothing below can be seen.
	if (ray.y > -0.08) {
		return 0.0;
	}
	float lit = 0.0;
	for (int layer = 0; layer < 3; layer++) {
		float depth = 5.0 + float(layer) * 7.0;
		vec2 at = world.xz + ray.xz / -ray.y * depth;
		float cell_size = 4.0 + float(layer) * 2.5;
		vec2 base = floor(at / cell_size);
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				vec2 cell = base + vec2(float(x), float(y)) + float(layer) * 31.0;
				float seed = hash(cell);
				if (seed > grave_share) {
					continue;
				}
				vec2 centre = (cell - float(layer) * 31.0
						+ vec2(hash(cell + 1.3), hash(cell + 5.1)) * 0.6 + 0.2) * cell_size;
				float d = length(at - centre);
				float radius = 0.25 + 0.2 * hash(cell + 9.9);
				// A small core, and a wider faint halo from the water around it.
				float glow = exp(-d * d / (radius * radius))
						+ 0.2 * exp(-d * d / (radius * radius * 9.0));
				float gutter = 0.7 + 0.3 * sin(time * (0.8 + seed * 3.0) + seed * 40.0);
				lit += glow * gutter * (1.0 - float(layer) * 0.3);
			}
		}
	}
	return lit;
}

void fragment() {
	float hull_d = hull_distance(v_world);
	// The hull hides the water inside it; cut it out so it can't show
	// through the galley floor as the swell passes.
	if (hull_d < 0.0) {
		discard;
	}

	// The fine chop, from two normal maps drifting different ways.
	vec2 uv = v_world.xz * detail_scale;
	vec3 na = texture(detail_a, uv + vec2(0.02, 0.013) * TIME).xyz * 2.0 - 1.0;
	vec3 nb = texture(detail_b, uv * 1.7 - vec2(0.017, 0.022) * TIME).xyz * 2.0 - 1.0;
	vec2 detail = (na.xy + nb.xy) * detail_strength;
	vec2 rings = rain_slope(v_world.xz, TIME) * rain;
	vec3 n = normalize(v_normal + vec3(detail.x + rings.x, 0.0, detail.y + rings.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);

	// Light glows through the wave where the surface is high and thin.
	float glow = clamp(v_height * 0.35 + 0.2, 0.0, 1.0) * clamp(v_crest * 2.0 + 0.4, 0.0, 1.0);
	vec3 water = mix(deep_color.rgb, crest_color.rgb, glow);

	// Foam: on sharp crests, hugging the hull, and trailing behind the ship.
	float noise = texture(foam_noise, v_world.xz * 0.08 + vec2(0.0, TIME * 0.03)).r;
	float foam = smoothstep(crest_foam_from, 1.0, v_crest + noise * 0.25);
	vec2 local = (hull_inverse * vec4(v_world, 1.0)).xz;
	// Under way, the bow shoulders the water aside in a wider wave of foam.
	float at_bow = smoothstep(-hull_half.y + 3.0, -hull_half.y - bow_reach, local.y);
	float band_width = hull_foam_width * (1.0 + bow_wave * wake * at_bow);
	float hull_band = 1.0 - smoothstep(0.0, band_width, hull_d);
	foam = max(foam, hull_band * smoothstep(0.25, 0.75, noise + 0.25));
	float stirred = hull_band;
	float behind = local.y - hull_half.y;
	if (behind > 0.0 && wake > 0.0) {
		float spread = hull_half.x * (0.7 + behind * 0.12);
		float across = 1.0 - smoothstep(spread * 0.6, spread, abs(local.x));
		float fade = 1.0 - smoothstep(0.0, 45.0, behind);
		float streaks = smoothstep(0.35, 0.8, texture(foam_noise, local * vec2(0.18, 0.05)).r);
		foam = max(foam, across * fade * streaks * wake);
		stirred = max(stirred, across * fade * wake);
	}
	// Where the water's been stirred, tiny specks glint and fade.
	float specks = texture(foam_noise, v_world.xz * 1.3 + vec2(TIME * 0.11, -TIME * 0.07)).r;
	float twinkle = smoothstep(0.7, 0.78, specks) * (0.6 + 0.4 * sin(TIME * 3.0 + specks * 40.0));
	float glints = twinkle * stirred * foam;

	ALBEDO = mix(water, foam_color.rgb, foam);
	// A night sea has almost no light on it, so crests and foam glow a
	// little on their own, the way painted night seas do; otherwise the swell
	// would vanish into black.
	// Water mirrors the sky at a glancing angle and looks dark head-on. The
	// night sky is nearly black, so the misty sky colour is added by hand,
	// which is what lets the swell's shape read against the fog.
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	vec3 sky = sky_reflection.rgb * fresnel * (1.0 - foam);
	EMISSION = sky + crest_color.rgb * glow * night_glow
			+ foam_color.rgb * foam * night_glow * 0.35
			+ glimmer_color.rgb * glints * glimmer;
	if (grave > 0.0) {
		// Seen through the water, so foam and the mirrored sky hide them.
		EMISSION += grave_color.rgb * grave_lights(v_world, CAMERA_POSITION_WORLD, TIME)
				* grave * grave_energy * (1.0 - foam) * (1.0 - fresnel);
	}
	ROUGHNESS = mix(roughness_water, 0.85, foam);
	METALLIC = 0.0;
	SPECULAR = 0.5;
}
