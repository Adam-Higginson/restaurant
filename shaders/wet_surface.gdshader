// A surface out in the rain: wood (or anything) that gets soaked, pools
// water in its low spots, ripples where drops land and runs with water on
// its sides. How wet everything is comes from one global uniform, `wetness`,
// set by the Weather (Project Settings > Shader Globals).
//
// The look follows how real wet things behave (Lagarde, "Observe rainy
// world"): porous things like wood soak water in and go darker and richer,
// only a little glossier; standing water is a near-mirror; rain lands only on
// faces that look up at the sky.
//
// The surface shader controls the texture filtering. The wet effects are
// smooth lighting on top of them.
//
// Everything is placed in the surface's own space (the ship's, handed in as
// `to_surface_space` by SurfaceSpace), so planks and puddles sail with the
// ship instead of sliding across it.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// 0 dry, 1 soaked. Shared by every wet material; the Weather sets it.
global uniform float wetness;

group_uniforms look;
uniform vec4 albedo : source_color = vec4(0.66, 0.48, 0.32, 1.0);
// The grain. Mapped in the surface space from whichever side a face looks out of,
// so boxes never stretch it.
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
// One copy of the texture covers this many metres.
uniform float texture_metres = 1.0;
uniform float dry_roughness : hint_range(0.0, 1.0) = 0.85;
// How much the grain stands out: the texture's light and dark read as raised
// and sunken, so light catches along the grain.
uniform float grain_bump : hint_range(0.0, 10.0) = 3.0;

group_uniforms planks;
// Plank width in metres on floors and ceilings; 0 for no planks. They run
// along the ship (z).
uniform float plank_width = 0.0;
// Plank width in metres on walls, which run level; 0 for no planks.
uniform float wall_plank_width = 0.0;
// Each plank is this long before a butt joint.
uniform float plank_length = 3.0;
uniform float seam_darkness : hint_range(0.0, 1.0) = 0.55;
// How much planks differ in shade from one another.
uniform float plank_tint : hint_range(0.0, 0.5) = 0.14;
// How much each plank is tipped or cupped, so each catches the light its own
// way.
uniform float plank_warp : hint_range(0.0, 0.2) = 0.05;
// How far in from a plank's edge it starts rounding down to the seam, in metres.
uniform float bevel : hint_range(0.0, 0.1) = 0.03;
// How much lighter the worn edges of boards are, rubbed by boots and hands.
uniform float wear : hint_range(0.0, 1.0) = 0.25;
// How much board widths vary: 0 all the same; higher splits more of them into
// two narrower boards, as on a deck laid from whatever timber was to hand.
uniform float width_variety : hint_range(0.0, 1.0) = 0.0;
// Nail heads: 0 none, 1 a pair across every board over each deck beam.
uniform float nails : hint_range(0.0, 1.0) = 0.0;
// How far apart the beams under the boards are, so where the rows of nails go.
uniform float beam_spacing = 0.9;

group_uniforms wet;
// How much the weather reaches it: 1 out in the rain, 0 indoors (the galley
// floor and walls), where it stays dry whatever the weather.
uniform float exposure : hint_range(0.0, 1.0) = 1.0;
// How much soaking darkens it: high for porous wood, low for paint or metal.
uniform float soak : hint_range(0.0, 1.0) = 0.6;
// How shiny the soaked (not pooled) surface gets. Wood drinks water in, so it
// stays fairly rough; only standing water is glossy.
uniform float soaked_roughness : hint_range(0.0, 1.0) = 0.62;
// Whether water pools on its top: 1 for decks, 0 for rails and posts.
uniform float puddles : hint_range(0.0, 1.0) = 1.0;
// How much of the top is under water when soaked.
uniform float puddle_cover : hint_range(0.0, 1.0) = 0.3;
uniform sampler2D puddle_noise : hint_default_black, repeat_enable, filter_linear;
// Puddle blobs are about 1 / this many metres across.
uniform float puddle_scale = 0.15;
// Rain rings: one ring at a time in each cell this many metres across.
uniform float ripple_cell = 0.3;
// Rings per second in each cell.
uniform float ripple_rate = 1.3;
uniform float ripple_strength = 0.6;
// Water running down the sides.
uniform sampler2D streak_noise : hint_default_black, repeat_enable, filter_linear;
uniform float streaks : hint_range(0.0, 1.0) = 1.0;

// World space to the space the pattern is fixed in (the ship's). Set every
// frame by SurfaceSpace; left alone, the pattern is fixed to the world.
uniform mat4 to_surface_space = mat4(1.0);

varying vec3 surface_pos;
varying vec3 surface_normal;


void vertex() {
	surface_pos = (to_surface_space * MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	surface_normal = normalize((to_surface_space * MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}


// Texture coordinates in the surface space, from the side the face looks out of.
vec2 surface_uv(vec3 p, vec3 n) {
	vec3 a = abs(n);
	if (a.y >= a.x && a.y >= a.z) {
		return p.xz;
	}
	if (a.x >= a.z) {
		return vec2(p.z, -p.y);
	}
	return vec2(p.x, -p.y);
}


vec3 hash3(vec2 cell) {
	vec3 q = vec3(dot(cell, vec2(127.1, 311.7)), dot(cell, vec2(269.5, 183.3)),
			dot(cell, vec2(419.2, 371.9)));
	return fract(sin(q) * 43758.5453);
}


// Which board [param x] metres across the boards is on, for boards about
// [param width] wide: (its number, how far across it from 0 to 1, its width
// in metres). With width_variety, some boards are split into two narrower
// ones near their middle.
vec3 board_across(float x, float width) {
	float stripe = floor(x / width);
	float f = fract(x / width);
	if (hash3(vec2(stripe, 7.0)).x < width_variety * 0.6) {
		float split = 0.38 + 0.24 * hash3(vec2(stripe, 9.0)).y;
		if (f < split) {
			return vec3(stripe * 2.0, f / split, width * split);
		}
		return vec3(stripe * 2.0 + 1.0, (f - split) / (1.0 - split), width * (1.0 - split));
	}
	return vec3(stripe * 2.0, f, width);
}


// How dark a plank seam is at [param p] (across the boards, then along
// them) for boards [param width] wide: 1 in a seam, 0 on wood.
float seam(vec2 p, float width) {
	vec3 board = board_across(p.x, width);
	float plank = board.x;
	// Butt joints are staggered from plank to plank.
	float along = p.y / plank_length + hash3(vec2(plank, 0.0)).x;
	float to_side = min(board.y, 1.0 - board.y) * board.z;
	float side = 1.0 - smoothstep(0.0, 0.04 * width, to_side);
	float joint = 1.0 - smoothstep(0.0, 0.006, min(fract(along), 1.0 - fract(along)));
	// Some seams are packed tight and barely show; others are open and dark.
	float gap = 0.45 + 0.55 * hash3(vec2(plank, floor(along)) + 3.0).x;
	return max(side, joint) * gap;
}


// The slope (x, z) of the rain rings at [param p] (in cells) and [param t].
// Each cell has one drop at a time, landing at a random spot and moment;
// its ring spreads and fades. Neighbouring cells are checked too, so rings
// can cross cell edges.
vec2 ripples(vec2 p, float t) {
	vec2 cell = floor(p);
	vec2 slope = vec2(0.0);
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			vec2 c = cell + vec2(float(i), float(j));
			vec3 h = hash3(c);
			vec2 centre = c + 0.15 + 0.7 * h.xy;
			float life = fract(t * ripple_rate * (0.8 + 0.4 * h.z) + h.z);
			vec2 d = p - centre;
			float r = length(d);
			float ring = r - life * 0.8;
			float wave = sin(ring * 45.0) * smoothstep(0.1, 0.0, abs(ring));
			slope += d / max(r, 0.0001) * wave * (1.0 - life) * (1.0 - life);
		}
	}
	return slope;
}


// Which plank (x) and which length of it (y) [param p] is on.
vec2 plank_cell(vec2 p, float width) {
	float plank = board_across(p.x, width).x;
	float along = p.y / plank_length + hash3(vec2(plank, 0.0)).x;
	return vec2(plank, floor(along));
}


// The two directions a face's texture runs in, in surface space, matching
// surface_uv(): across (u) and down (v).
mat3 texture_frame(vec3 n) {
	vec3 a = abs(n);
	if (a.y >= a.x && a.y >= a.z) {
		return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), n);
	}
	if (a.x >= a.z) {
		return mat3(vec3(0.0, 0.0, 1.0), vec3(0.0, -1.0, 0.0), n);
	}
	return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, -1.0, 0.0), n);
}


float brightness(vec3 c) {
	return dot(c, vec3(0.3, 0.59, 0.11));
}


void fragment() {
	vec3 n = normalize(surface_normal);
	float wet = clamp(wetness, 0.0, 1.0) * exposure;
	// Rain lands on faces that look up; undersides (the galley ceiling) stay dry.
	float up = clamp(n.y, 0.0, 1.0);
	float exposed = smoothstep(-0.4, 0.1, n.y);
	float side = 1.0 - abs(n.y);
	// Boards: on floors and ceilings they run along the ship; on walls they
	// run level. Work out where this point is in board terms (across, along)
	// and which way "across" and "along" point.
	float width = 0.0;
	vec2 board = vec2(0.0);
	vec3 across_axis = vec3(1.0, 0.0, 0.0);
	vec3 along_axis = vec3(0.0, 0.0, 1.0);
	if (abs(n.y) > 0.9 && plank_width > 0.0) {
		width = plank_width;
		board = surface_pos.xz;
	} else if (abs(n.y) < 0.1 && wall_plank_width > 0.0) {
		width = wall_plank_width;
		along_axis = abs(n.x) > abs(n.z) ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
		across_axis = vec3(0.0, 1.0, 0.0);
		board = vec2(surface_pos.y, dot(surface_pos, along_axis));
	}
	bool planked = width > 0.0;

	// Each plank: its own shade, its grain shifted so neighbours don't match,
	// and a slight tip so it catches the light differently.
	vec2 uv = surface_uv(surface_pos, n);
	float shade = 1.0;
	vec2 lean = vec2(0.0);
	if (planked) {
		vec3 h = hash3(plank_cell(board, width) + 17.0);
		shade = 1.0 + plank_tint * (h.x * 2.0 - 1.0);
		// The grain runs along the board (the texture's grain runs across
		// the image, so turn it), stretched like a long board's, and each
		// board shows its own stretch of the texture.
		uv = vec2(board.y * 0.45, board.x) + h.yz * 7.0;
		lean = (h.zy - 0.5) * plank_warp;
		// Rounded edges: near a long edge the board curves down to the seam.
		vec3 this_board = board_across(board.x, width);
		float across = this_board.y;
		float to_edge = min(across, 1.0 - across) * this_board.z;
		float round_off = 1.0 - smoothstep(0.0, bevel, to_edge);
		// Lived in: each board darkens or lightens along its length, and its
		// long edges are worn lighter.
		float along_board = fract(board.y / plank_length + hash3(vec2(this_board.x, 0.0)).x);
		shade *= 1.0 + plank_tint * 0.8 * (along_board - 0.5) * (h.y > 0.5 ? 1.0 : -1.0);
		shade *= 1.0 + wear * (1.0 - smoothstep(0.0, bevel * 2.5, to_edge));
		lean.x += (across < 0.5 ? -1.0 : 1.0) * round_off * 0.7;
	}

	// The grain, and its relief: brighter texels read as raised.
	vec2 tex_uv = uv / texture_metres;
	vec2 texel = 1.0 / vec2(textureSize(albedo_texture, 0));
	vec3 grain = texture(albedo_texture, tex_uv).rgb;
	float height_here = brightness(grain);
	float height_u = brightness(texture(albedo_texture, tex_uv + vec2(texel.x, 0.0)).rgb);
	float height_v = brightness(texture(albedo_texture, tex_uv + vec2(0.0, texel.y)).rgb);
	vec2 grain_slope = vec2(height_u - height_here, height_v - height_here) * grain_bump;

	vec3 base = albedo.rgb * grain * shade;
	float in_seam = planked ? seam(board, width) : 0.0;
	base *= 1.0 - seam_darkness * in_seam;
	// Nail heads: little dark iron squares, snapped to the texture's pixels so
	// they're as blocky as the grain, a pair across each board over each beam.
	float nail = 0.0;
	if (planked && nails > 0.0) {
		float px = texture_metres / float(textureSize(albedo_texture, 0).x);
		vec2 snapped = (floor(board / px) + 0.5) * px;
		vec3 nail_board = board_across(snapped.x, width);
		float in_from_side = nail_board.y * nail_board.z;
		float from_edge = min(in_from_side, nail_board.z - in_from_side);
		float off_row = abs(from_edge - nail_board.z * 0.22);
		float off_beam = abs(fract(snapped.y / beam_spacing + 0.5) - 0.5) * beam_spacing;
		nail = nails * step(off_row, px * 0.9) * step(off_beam, px * 0.9);
		base = mix(base, vec3(0.08, 0.075, 0.07), 0.85 * nail);
	}

	// Soaked: darker and richer (a power darkens the darks most), and a little
	// glossier, unevenly: some patches drink more water and stay dull.
	float soaked = wet * exposed;
	vec3 colour = pow(base, vec3(1.0 + 0.8 * soak * soaked)) * (1.0 - 0.35 * soak * soaked);
	float patchy = texture(puddle_noise, surface_pos.xz * puddle_scale * 3.7 + 0.31).r;
	float sheen = soaked * smoothstep(0.3, 0.75, patchy);
	// The grain's dark lines (end grain, cracks) hold water and stay rougher.
	float rough = mix(dry_roughness, soaked_roughness, sheen);
	rough = clamp(rough + (0.5 - height_here) * 0.25, 0.0, 1.0);
	rough = mix(rough, 0.35, nail);

	// Standing water: on flat tops, in the noise's low spots, and along seams.
	float low = texture(puddle_noise, surface_pos.xz * puddle_scale).r;
	float pooled = smoothstep(1.0 - puddle_cover, 1.0 - puddle_cover + 0.12, low);
	pooled = max(pooled, in_seam * 0.45);
	float puddle = puddles * pooled * step(0.9, up) * smoothstep(0.35, 0.8, wet);
	// A film of water hides the wood under it: what you see is mostly the
	// reflection, so the colour goes towards a dark, neutral water.
	colour = mix(colour, vec3(0.035, 0.04, 0.045), 0.7 * puddle);
	rough = mix(rough, 0.03, puddle);

	// Water running down the sides in thin, slowly sliding streaks.
	vec2 run = vec2((surface_pos.x + surface_pos.z) * 2.5, surface_pos.y * 0.3 + TIME * 0.18);
	float stream = smoothstep(0.58, 0.72, texture(streak_noise, run).r);
	float streak = streaks * stream * side * wet;
	rough = mix(rough, 0.12, streak);
	colour *= 1.0 - 0.12 * streak;

	// The surface's shape: grain relief and plank lean, flattened where water
	// stands over them, plus rain rings (faint on wood, strong in puddles).
	mat3 frame = texture_frame(n);
	float flatten = 1.0 - puddle;
	vec3 bent = n - (frame[0] * grain_slope.x + frame[1] * grain_slope.y) * flatten;
	bent += (across_axis * lean.x + along_axis * lean.y) * flatten;
	vec2 slope = ripples(surface_pos.xz / ripple_cell, TIME);
	slope *= ripple_strength * up * wet * mix(0.25, 1.0, puddle);
	bent = normalize(bent + vec3(slope.x, 0.0, slope.y));

	ALBEDO = colour;
	ROUGHNESS = rough;
	SPECULAR = 0.4;
	// Back from the surface's space to the world (the inverse of a turn is its
	// transpose), then to the camera's view.
	vec3 bent_world = transpose(mat3(to_surface_space)) * bent;
	NORMAL = normalize((VIEW_MATRIX * vec4(bent_world, 0.0)).xyz);
}
