shader_type spatial;
// A hanging curtain as cloth (#168), shaped here and not by physics: a sheet
// pinned along its rail that hangs in pleats, flares towards the hem, swings
// from the rail as the ship rolls and ripples as it moves. [CurtainCloth]
// (scripts/props/curtain_cloth.gd) says each frame how far it has swung and
// how fast it's moving; this file turns that into the cloth's shape.
//
// The mesh's own corners are ignored: every point is placed from its UV
// (u across the rail, v from the rail at 0 down to the hem at 1), so any
// finely divided flat mesh will do.
render_mode cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform vec4 albedo : source_color = vec4(1.0);
// How deep its folds are, in metres.
uniform float pleat_depth = 0.035;
// How much wider the hem is than the gathered top, as a share.
uniform float flare = 0.18;
// How far the hem swings at a full roll, in metres.
uniform float sway_metres = 0.14;
// How deep the ripples running down it are, in metres.
uniform float ripple = 0.022;

// Width along the rail and the drop, in metres, and how many folds it hangs
// in (set per curtain: a drawn curtain is wider than one bunched open).
instance uniform vec2 size = vec2(0.3, 0.98);
instance uniform float pleats = 3.5;
// Which way and how far it has swung, in the cloth's own space (set per
// curtain, each frame).
instance uniform vec3 sway = vec3(0.0);
// How fast it's moving, about 0 to 1: the ripples grow with it.
instance uniform float gust = 0.0;
// Makes each curtain's folds and ripples its own.
instance uniform float seed = 0.0;


vec3 cloth(vec2 uv) {
	// 0 at the rail, where it's pinned, to 1 at the hem.
	float hang = uv.y;
	float across = (uv.x - 0.5) * size.x * (1.0 + flare * hang);
	float fold = sin(uv.x * pleats * TAU + seed) * pleat_depth * (0.35 + 0.65 * hang);
	// Ripples run from the rail to the hem, and a slower one across.
	float wave = sin(uv.y * 9.0 - TIME * 3.4 + uv.x * 2.5 + seed) * (0.25 + gust)
			+ sin(uv.y * 4.0 - TIME * 1.7 + seed * 2.0) * 0.5 * gust;
	vec3 point = vec3(across, -uv.y * size.y, fold + wave * ripple * hang);
	// The swing: nothing at the rail, most at the hem, and the hem lifts a
	// little as it goes, as cloth of a fixed length must.
	float reach = hang * hang * sway_metres;
	point += sway * reach;
	point.y += length(sway) * reach * 0.25;
	return point;
}


void vertex() {
	vec3 here = cloth(UV);
	// The surface's facing, from how the cloth runs across and down here.
	vec3 run_across = cloth(UV + vec2(0.01, 0.0)) - here;
	vec3 run_down = cloth(UV + vec2(0.0, 0.01)) - here;
	VERTEX = here;
	NORMAL = normalize(cross(run_across, -run_down));
}


void fragment() {
	ALBEDO = texture(albedo_texture, UV).rgb * albedo.rgb;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
