// The fog wall standing out at sea: a tall soft curtain, solid at the
// water and billowing away to nothing at its top. Real (volumetric) fog
// only reaches so far from the camera, so the wall beyond the cove is
// painted: a long upright sheet with this on it.
//
// UV.x runs along the sheet and UV.y from its top (0) to the water (1).
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 colour : source_color = vec4(0.83, 0.85, 0.87, 1.0);
// The colour its thicker lumps take from the sun.
uniform vec4 sunlit : source_color = vec4(1.0, 0.93, 0.8, 1.0);
// How solid the wall is at the water.
uniform float thickness : hint_range(0.0, 1.0) = 1.0;
// A soft tiled noise the billows are cut from.
uniform sampler2D billows : filter_linear_mipmap, repeat_enable;
// How many times the noise repeats along the sheet.
uniform float repeats = 6.0;
// How fast the billows drift along it.
uniform float drift = 0.004;

void fragment() {
	float lump = texture(billows, vec2(UV.x * repeats + TIME * drift, UV.y * 0.6)).r;
	float wisp = texture(billows, vec2(UV.x * repeats * 2.3 - TIME * drift * 1.7, UV.y * 1.4 + 0.3)).r;
	// The top edge rises and falls with the billows.
	float edge = UV.y + (lump - 0.5) * 0.5 + (wisp - 0.5) * 0.15;
	float solid = smoothstep(0.15, 0.75, edge);
	// The sheet's own ends fade out, so it never shows a corner.
	solid *= smoothstep(0.0, 0.08, UV.x) * smoothstep(1.0, 0.92, UV.x);
	// Its lumps catch a little of the sun's colour.
	ALBEDO = mix(colour.rgb, sunlit.rgb, lump * 0.25);
	ALPHA = solid * thickness;
}
