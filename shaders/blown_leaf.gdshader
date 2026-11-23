// A leaf blowing through the air: a flat card cut to a pointed leaf shape,
// green or going brown, bright whichever side faces you. Each particle is
// one leaf; its own colour (COLOR, from the particle system) tints it.
shader_type spatial;
render_mode cull_disabled, shadows_disabled, unshaded;

uniform vec4 green : source_color = vec4(0.36, 0.5, 0.14, 1.0);
uniform vec4 dry : source_color = vec4(0.55, 0.42, 0.16, 1.0);

varying float v_own;

void vertex() {
	// Some leaves are green, some dry, by which particle this is.
	v_own = fract(float(INSTANCE_ID) * 0.618);
}

void fragment() {
	// A leaf: widest in the middle, pointed at both ends. UV.x runs along
	// it and UV.y across.
	float half_width = sin(UV.x * PI) * 0.5;
	if (abs(UV.y - 0.5) > half_width) {
		discard;
	}
	vec3 leaf = mix(green.rgb, dry.rgb, step(0.6, v_own));
	// A darker midrib.
	leaf *= 0.8 + 0.2 * smoothstep(0.0, 0.08, abs(UV.y - 0.5));
	ALBEDO = leaf * COLOR.rgb;
}
