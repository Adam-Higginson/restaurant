// Something far off through the fog, drawn as a flat, hazy silhouette: an
// island and its lighthouse on the horizon. It's too far for the fog to let
// through, so it ignores the fog and fades itself instead: `reveal` is how
// much of it you see (barely anything at night, a ghostly shape at dawn), and
// it's paler towards the top, as if the mist were thicker there.
shader_type spatial;
render_mode unshaded, fog_disabled, blend_mix, depth_draw_always, cull_back, shadows_disabled;

uniform vec4 colour : source_color = vec4(0.24, 0.25, 0.3, 1.0);
// The mist it fades into near its top.
uniform vec4 mist : source_color = vec4(0.6, 0.55, 0.58, 1.0);
// How much of it shows: 0 hidden, 1 solid.
uniform float reveal : hint_range(0.0, 1.0) = 0.0;
// World heights over which it pales into the mist.
uniform float mist_from = 4.0;
uniform float mist_to = 40.0;

varying float height;


void vertex() {
	height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}


void fragment() {
	float pale = smoothstep(mist_from, mist_to, height);
	ALBEDO = mix(colour.rgb, mist.rgb, pale * 0.6);
	ALPHA = reveal * (1.0 - pale * 0.35);
}
