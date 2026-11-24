// A lantern's glass with a flame burning inside it (#199). It goes on a box
// that fills the lantern's glass. For every pixel of glass, the shader
// follows your line of sight in through the pane and looks for the flame
// along it ("raymarching": stepping along the ray, here only through the
// thin cylinder the flame can be in). The flame is a 3D teardrop standing
// on a wick, licked by rising noise, so it stays in the middle of the
// lantern and slides behind the panes as you walk round it. It's painted
// in soft nested bands, white-gold at its heart to red at its tips.
//
// Over it, the glass is clear with a faint warm tint, brighter edge-on (as
// glass reflects more at a slant), with painted shine streaks, a glow where
// the flame lights it from inside and a little soot at the top. Looking out
// through the top or bottom you see the lantern's own roof and floor plate.
//
// The ship's lanterns (lantern.tscn, see Lantern) set their own [burning]
// and [own_seed] per lantern. The lantern spirit (LanternFace) also drives
// [strength], [lean] and [swell], and his glass's [fog], [streaks] and
// [crack].
shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_never;

// Half the glass box's size, in its own space: it must match the mesh.
uniform vec3 box_half = vec3(0.085, 0.12, 0.085);
// Where the flame stands (the top of its wick), in the box's own space.
uniform vec3 wick = vec3(0.0, -0.08, 0.0);
// How tall the flame stands and how wide it is at its widest (a radius).
uniform float flame_height = 0.12;
uniform float flame_width = 0.028;

// The fire's colours, from its heart to its tips, when he's strong...
uniform vec4 core : source_color = vec4(1.0, 0.97, 0.84, 1.0);
uniform vec4 gold : source_color = vec4(1.0, 0.8, 0.32, 1.0);
uniform vec4 orange : source_color = vec4(1.0, 0.47, 0.12, 1.0);
uniform vec4 tips : source_color = vec4(0.78, 0.16, 0.06, 1.0);
// ...and when he's nearly out (only the spirit's strength ever falls).
uniform vec4 cold_core : source_color = vec4(0.86, 0.95, 1.0, 1.0);
uniform vec4 cold_gold : source_color = vec4(0.55, 0.78, 1.0, 1.0);
uniform vec4 cold_orange : source_color = vec4(0.3, 0.52, 1.0, 1.0);
uniform vec4 cold_tips : source_color = vec4(0.1, 0.18, 0.5, 1.0);
// How bright the flame glows: above 1 it blooms.
uniform float glow = 1.6;
// How fast the flame licks upwards.
uniform float speed = 1.0;
// Each flame flickers its own way: the spirit sets this on his own
// material; ship's lanterns share one material and set [own_seed].
uniform float seed = 0.0;
instance uniform float own_seed = 0.0;
// Whether the lantern is lit, 0 to 1: unlit, the glass shows an empty
// lantern and a dark wick.
instance uniform float burning = 1.0;

// How strong the flame is, 0 to 1: its height, steadiness and colour.
uniform float strength = 1.0;
// How tall it stands against its usual height for its strength: above 1 it
// bristles, below 1 it draws in.
uniform float swell = 1.0;
// The way it tips, in the box's own space (x and z matter), up to 1.
uniform vec3 lean = vec3(0.0);

// The glass: its tint, and how much it shows face-on (alpha)...
uniform vec4 glass_tint : source_color = vec4(0.9, 0.78, 0.55, 0.05);
// ...how much brighter it gets edge-on...
uniform float sheen : hint_range(0.0, 1.0) = 0.35;
// ...its painted shine streaks...
uniform float shine : hint_range(0.0, 2.0) = 0.7;
// ...how much the flame lights the glass from inside...
uniform float inner_glow : hint_range(0.0, 2.0) = 0.5;
// ...the soft glow hanging in the air round the flame...
uniform float halo : hint_range(0.0, 2.0) = 0.6;
// ...and how much soot darkens the top of the glass.
uniform float soot : hint_range(0.0, 1.0) = 0.35;
// A glow the glass always has while lit, however far from the flame, so
// the spirit's eyes never get lost against it.
uniform float backing : hint_range(0.0, 2.0) = 0.0;
// An iron grille across the side panes, in diamonds: how much of it shows
// (0 for none), how far apart its bars are and half their width, in metres.
uniform float lattice : hint_range(0.0, 1.0) = 0.0;
uniform float lattice_spacing = 0.075;
uniform float lattice_width = 0.0035;
uniform vec4 iron : source_color = vec4(0.13, 0.1, 0.08, 1.0);
// The lantern's floor plate and roof, seen through the glass.
uniform vec4 floor_colour : source_color = vec4(0.16, 0.11, 0.07, 1.0);
uniform vec4 roof_colour : source_color = vec4(0.05, 0.04, 0.035, 1.0);

// How clouded the glass is, 0 to 1.
uniform float fog = 0.0;
// How much rain is running down it, 0 to 1.
uniform float streaks = 0.0;
// How far a crack has grown down the front (the -z pane), 0 to 1.
uniform float crack = 0.0;

const int STEPS = 20;

varying vec3 local_spot;
varying vec3 local_normal;
varying vec3 camera_local;


float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}


float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}


float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}


float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float low = mix(mix(hash3(i), hash3(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(hash3(i + vec3(0.0, 1.0, 0.0)), hash3(i + vec3(1.0, 1.0, 0.0)), f.x), f.y);
	float high = mix(mix(hash3(i + vec3(0.0, 0.0, 1.0)), hash3(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(hash3(i + vec3(0.0, 1.0, 1.0)), hash3(i + vec3(1.0, 1.0, 1.0)), f.x), f.y);
	return mix(low, high, f.z);
}


// Where along [dir] from [from] it passes within [radius] of an upright line
// through [centre] (x and z), as the distances in and out; x > y if never.
vec2 through_upright(vec3 from, vec3 dir, vec2 centre, float radius) {
	vec2 o = from.xz - centre;
	float a = dot(dir.xz, dir.xz);
	float b = dot(o, dir.xz);
	float c = dot(o, o) - radius * radius;
	float inside = b * b - a * c;
	if (a < 1e-8 || inside < 0.0) {
		return vec2(1.0, -1.0);
	}
	float half_span = sqrt(inside);
	return vec2(-b - half_span, -b + half_span) / a;
}


// How deep inside the flame [p] is, from 0 at its edge to 1 at its heart
// (negative outside), and how far up the flame it is (0 to 1) in [up].
float flame_at(vec3 p, float t, float height, out float up) {
	vec3 q = p - wick;
	up = q.y / height;
	float h = clamp(up, 0.0, 1.0);
	// It tips the way it leans, and sways, more the higher up.
	q.xz -= lean.xz * h * height * 0.5;
	float sway = h * h * flame_width * 1.1;
	q.x -= (noise(vec2(t * 0.7, seed * 13.0)) - 0.5) * sway;
	q.z -= (noise(vec2(t * 0.6 + 5.0, seed * 7.0)) - 0.5) * sway;
	// A teardrop: round at the root, widest a third of the way up, drawn to
	// a point at the tip.
	float rounded = clamp(up + 0.06, 0.0, 1.0);
	float radius = flame_width * 2.8 * sqrt(rounded) * pow(1.0 - h, 1.2);
	float across = length(q.xz) / max(radius, 1e-4);
	// Tongues licking upwards: rising noise, wilder near the tip.
	vec3 rising = vec3(q.x, q.y - t * 0.05, q.z) / flame_width;
	float lick = noise3(rising * 0.9) * 0.65 + noise3(rising * 2.1 + 7.0) * 0.35;
	across -= (lick - 0.5) * (0.25 + 1.1 * h);
	float inside = 1.0 - across;
	// It fades out a little below the root and above the tip.
	inside = min(inside, (up + 0.04) * 6.0);
	inside = min(inside, (1.0 - up) * 3.0);
	return inside;
}


// The fire's colour for how deep in the flame and how far up it a point
// is, in soft painted bands.
vec3 flame_colour(float heat, float up, float cool) {
	vec3 core_now = mix(core.rgb, cold_core.rgb, cool);
	vec3 gold_now = mix(gold.rgb, cold_gold.rgb, cool);
	vec3 orange_now = mix(orange.rgb, cold_orange.rgb, cool);
	vec3 tips_now = mix(tips.rgb, cold_tips.rgb, cool);
	// Hotter low down: the heart sits in the lower half.
	float hot = heat * (1.25 - 0.75 * clamp(up, 0.0, 1.0));
	vec3 colour = mix(tips_now, orange_now, smoothstep(0.1, 0.17, hot));
	colour = mix(colour, gold_now, smoothstep(0.32, 0.39, hot));
	return mix(colour, core_now, smoothstep(0.66, 0.74, hot));
}


// How much of the grille covers the point [pane] (across and up a side
// pane, in metres), its bars' edges softened over a pixel.
float lattice_at(vec2 pane) {
	float rising = (pane.x + pane.y) / lattice_spacing + 0.5;
	float falling = (pane.x - pane.y) / lattice_spacing + 0.5;
	// How far from the nearest bar of each slant, in metres.
	float off_rising = abs(fract(rising + 0.5) - 0.5) * lattice_spacing * 0.7071;
	float off_falling = abs(fract(falling + 0.5) - 0.5) * lattice_spacing * 0.7071;
	float off = min(off_rising, off_falling);
	float pixel = max(fwidth(off), 1e-5);
	return (1.0 - smoothstep(lattice_width - pixel, lattice_width + pixel, off)) * lattice;
}


void vertex() {
	local_spot = VERTEX;
	local_normal = NORMAL;
	camera_local = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
}


void fragment() {
	vec3 ray = normalize(local_spot - camera_local);
	float lit = clamp(burning, 0.0, 1.0);
	float cool = 1.0 - smoothstep(0.08, 0.55, strength);
	float t = TIME * speed * mix(2.4, 1.0, strength) + (seed + own_seed) * 17.0;
	float height = flame_height * mix(0.3, 1.0, strength) * max(swell, 0.05)
			* (0.92 + 0.16 * noise(vec2(t * 2.3, seed + own_seed)));
	float flicker = 0.88 + 0.12 * noise(vec2(t * 3.0, own_seed + 3.0));
	float bright = glow * mix(0.45, 1.0, strength) * flicker
			* (1.0 + 0.3 * clamp(swell - 1.0, -1.0, 1.0)) * lit;
	vec3 warm_now = mix(orange.rgb, cold_orange.rgb, cool);
	vec3 flame_middle = wick + vec3(0.0, height * 0.35, 0.0);

	// Where the ray leaves the box, and through which face.
	vec3 safe_ray = sign(ray) * max(abs(ray), vec3(1e-5));
	vec3 leaving = max((box_half - local_spot) / safe_ray, (-box_half - local_spot) / safe_ray);
	float exit = min(min(leaving.x, leaving.y), leaving.z);
	vec3 exit_spot = local_spot + ray * exit;
	bool out_the_top_or_bottom = leaving.y <= min(leaving.x, leaving.z);
	bool in_the_top_or_bottom = abs(local_normal.y) > 0.5;
	// The grille on the near pane and on the far one, seen from inside.
	// Worked out here, outside any branch, so its edges can be softened.
	bool side_pane = abs(local_normal.x) > 0.5;
	float near_bars = lattice_at(vec2(side_pane ? local_spot.z : local_spot.x, local_spot.y));
	float far_bars = lattice_at(vec2(leaving.x < leaving.z ? exit_spot.z : exit_spot.x,
			exit_spot.y));

	// The flame: the hottest point the ray passes through.
	float heat = -1.0;
	float heat_up = 0.0;
	float reach = flame_width * 1.8 + length(lean.xz) * height * 0.5;
	vec2 span = through_upright(local_spot, ray, wick.xz, reach);
	span.x = max(span.x, 0.0);
	span.y = min(span.y, exit);
	if (lit > 0.0 && span.y > span.x && !in_the_top_or_bottom) {
		// Each pixel starts its steps a little apart, so no bands show.
		float jitter = hash(FRAGCOORD.xy);
		float step_length = (span.y - span.x) / float(STEPS);
		for (int i = 0; i < STEPS; i++) {
			vec3 p = local_spot + ray * (span.x + (float(i) + jitter) * step_length);
			float up;
			float inside = flame_at(p, t, height, up);
			if (inside > heat) {
				heat = inside;
				heat_up = up;
			}
		}
	}
	float flame_alpha = smoothstep(0.0, 0.1, heat) * lit;
	vec3 flame_light = flame_colour(heat, heat_up, cool) * bright;

	// The wick and its burner, a little dark post under the flame.
	vec3 behind = vec3(0.0);
	float behind_alpha = 0.0;
	vec2 at_wick = through_upright(local_spot, ray, wick.xz, 0.0035);
	vec2 at_burner = through_upright(local_spot, ray, wick.xz, flame_width * 0.45);
	float wick_y = local_spot.y + ray.y * at_wick.x;
	float burner_y = local_spot.y + ray.y * at_burner.x;
	if (at_burner.x > 0.0 && at_burner.x < exit
			&& burner_y < wick.y - 0.014 && burner_y > -box_half.y) {
		behind = floor_colour.rgb * (0.2 + 0.25 * bright);
		behind_alpha = 1.0;
	} else if (at_wick.x > 0.0 && at_wick.x < exit
			&& wick_y < wick.y + 0.004 && wick_y > wick.y - 0.016) {
		float ember = smoothstep(wick.y - 0.008, wick.y + 0.004, wick_y) * lit;
		behind = mix(vec3(0.02), vec3(1.0, 0.35, 0.08) * 1.5, ember);
		behind_alpha = 1.0;
	} else if (out_the_top_or_bottom || in_the_top_or_bottom) {
		// The floor plate or the roof, lit by the flame.
		vec3 plate_spot = in_the_top_or_bottom ? local_spot : exit_spot;
		bool is_floor = plate_spot.y < 0.0;
		float spread = flame_width * (is_floor ? 3.0 : 4.0);
		float lit_by = exp(-dot(plate_spot.xz - wick.xz, plate_spot.xz - wick.xz)
				/ (spread * spread));
		vec3 plate = is_floor ? floor_colour.rgb : roof_colour.rgb;
		behind = plate * (0.3 + 0.9 * lit_by * bright) + warm_now * 0.03 * bright;
		behind_alpha = 1.0;
	} else {
		// Out through the far pane: it glows a little where the flame is near.
		vec3 apart = exit_spot - flame_middle;
		float near = flame_width * 3.5;
		float lit_by = 1.0 / (1.0 + dot(apart, apart) / (near * near));
		behind = warm_now * inner_glow * 0.6 * bright * lit_by;
		behind_alpha = glass_tint.a;
		// Its grille, the inner sides of the bars lit by the flame.
		vec3 lit_iron = iron.rgb * (0.5 + 2.5 * bright * lit_by) + warm_now * 0.04 * bright;
		behind = mix(behind, lit_iron, far_bars);
		behind_alpha = mix(behind_alpha, 1.0, far_bars);
	}

	// The glow in the air round the flame: how near the ray passes its middle.
	vec3 to_middle = flame_middle - local_spot;
	float along = clamp(dot(to_middle, ray), 0.0, exit);
	vec3 closest = to_middle - ray * along;
	float halo_reach = flame_width * 2.2;
	vec3 air = warm_now * halo * 0.35 * bright
			* exp(-dot(closest, closest) / (halo_reach * halo_reach));

	// Everything inside the glass, the flame in front of what's behind it.
	vec3 inside_light = flame_light * flame_alpha + behind * (1.0 - flame_alpha) + air;
	float inside_alpha = flame_alpha + behind_alpha * (1.0 - flame_alpha);

	// The near pane: where across it and how far up this pixel is, 0 to 1.
	float across = (side_pane ? local_spot.z * sign(local_normal.x)
			: -local_spot.x * sign(local_normal.z)) / box_half.x * 0.5 + 0.5;
	float up_pane = local_spot.y / box_half.y * 0.5 + 0.5;
	float edge_on = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 apart = local_spot - flame_middle;
	float near = flame_width * 3.0;
	vec3 pane_glow = warm_now * bright
			* (inner_glow / (1.0 + dot(apart, apart) / (near * near)) * 0.5);
	pane_glow = max(pane_glow, warm_now * backing * mix(0.5, 1.0, strength) * lit);
	// Painted shine: two slanting streaks that slide a little as you move.
	float slant = across + up_pane * 0.55 + dot(VIEW, vec3(1.0, 0.0, 0.0)) * 0.15;
	float streak_a = 1.0 - smoothstep(0.0, 0.035, abs(slant - 0.42));
	float streak_b = 1.0 - smoothstep(0.0, 0.015, abs(slant - 0.53));
	float shine_here = (streak_a + streak_b * 0.8) * smoothstep(0.25, 0.6, up_pane)
			* (1.0 - smoothstep(0.85, 1.0, up_pane)) * shine;
	if (in_the_top_or_bottom) {
		shine_here = 0.0;
	}
	float soot_here = smoothstep(0.62, 1.0, up_pane) * soot;
	float glass_alpha = clamp(glass_tint.a + edge_on * sheen + shine_here * 0.5, 0.0, 1.0);
	vec3 glass_light = pane_glow + vec3(1.0, 0.97, 0.9) * shine_here * 1.4
			+ glass_tint.rgb * edge_on * sheen * 0.4;

	// The near pane over everything inside.
	vec3 light = glass_light + inside_light * (1.0 - glass_alpha);
	float alpha = glass_alpha + inside_alpha * (1.0 - glass_alpha);

	// The near grille: iron, lit by the room (ALBEDO below), its edges
	// catching a little of the firelight behind it.
	float bars = in_the_top_or_bottom ? 0.0 : near_bars;
	light = mix(light, warm_now * 0.05 * bright, bars);
	alpha = mix(alpha, 1.0, bars);

	// Soot: a dark smudge that holds back what's behind it.
	light *= 1.0 - soot_here * 0.7;
	alpha = mix(alpha, 1.0, soot_here * 0.55);

	// Fog: milky glass that the flame lights from behind.
	vec3 misted = mix(warm_now, vec3(1.0), 0.7)
			* (0.25 + 0.35 * flame_alpha + 0.2 * lit) * max(bright, 0.6);
	light = mix(light, misted, fog * 0.85);
	alpha = mix(alpha, 1.0, fog * 0.85);

	// Streaks: a few lanes, each with a bright drop sliding down.
	float lane = floor(across * 6.0);
	float lane_middle = (lane + 0.5) / 6.0;
	float wander = (hash(vec2(lane, 1.0)) - 0.5) * 0.06;
	float in_lane = 1.0 - smoothstep(0.0, 0.035, abs(across - lane_middle + wander));
	float fall = TIME * (0.35 + hash(vec2(lane, 7.0)) * 0.4) + hash(vec2(lane, 3.0));
	float tail = smoothstep(0.55, 1.0, fract(up_pane + fall)) * in_lane * streaks;
	light = mix(light, vec3(0.9, 0.96, 1.0) * 1.6, tail * 0.8);
	alpha = mix(alpha, 1.0, tail * 0.6);

	// The crack: a jagged dark line down the front pane, from the top.
	if (local_normal.z < -0.5 && crack > 0.0) {
		float line = 0.5 + 0.13 * sin(up_pane * 9.0) + 0.05 * sin(up_pane * 23.0 + 1.3);
		float on_line = 1.0 - smoothstep(0.012, 0.03, abs(across - line));
		float grown = step(1.0 - crack, up_pane);
		light = mix(light, vec3(0.03, 0.02, 0.02), on_line * grown);
		alpha = mix(alpha, 1.0, on_line * grown);
	}

	// Blending multiplies what we give off by the alpha, so give it divided
	// by the alpha: the flame and its glow then add their full light while
	// the clear glass still lets the room show through.
	alpha = clamp(alpha, 0.02, 1.0);
	ALBEDO = mix(glass_tint.rgb * 0.08, iron.rgb, bars);
	ROUGHNESS = mix(0.1, 0.7, bars);
	SPECULAR = mix(0.5 * glass_alpha / alpha, 0.3, bars);
	EMISSION = light / alpha;
	ALPHA = alpha;
}
