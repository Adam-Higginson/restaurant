// A bubble under water: almost nothing in the middle, bright at the rim,
// and it takes its colour from whatever light is near it. So the bubbles
// streaming off the lantern glow amber beside him and fade to the sea's
// own dim blue as they rise away. It's lit like any solid thing (it isn't
// "unshaded"), which is what lets the lantern's light reach it.
shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_never, specular_schlick_ggx;

// The bubble's own colour, before any light falls on it.
uniform vec4 tint : source_color = vec4(0.75, 0.88, 0.95, 1.0);
// How see-through the middle is (0 clear) and how solid the rim.
uniform float middle = 0.08;
uniform float rim = 0.85;

void fragment() {
	// 0 looking straight at the bubble's middle, 1 at its very edge.
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	ALBEDO = tint.rgb;
	ROUGHNESS = 0.08;
	SPECULAR = 0.9;
	ALPHA = mix(middle, rim, edge) * tint.a * COLOR.a;
}
