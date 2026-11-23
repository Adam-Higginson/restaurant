// A small fish (see FishShoal): dark along the back, silver underneath,
// wagging its tail as it swims. UV.x runs from its nose (0) to its tail (1).
shader_type spatial;
render_mode cull_disabled;

uniform vec4 back_color : source_color = vec4(0.1, 0.17, 0.22, 1.0);
uniform vec4 belly_color : source_color = vec4(0.62, 0.72, 0.74, 1.0);
// How far the tail swings, as a part of the fish's length, and how fast.
uniform float wag = 0.12;
uniform float wag_speed = 11.0;

varying float v_up;

void vertex() {
	// Each fish wags to its own beat.
	float beat = float(INSTANCE_ID) * 1.7;
	VERTEX.x += sin(TIME * wag_speed + beat - UV.x * 3.0) * wag * UV.x * UV.x;
	v_up = NORMAL.y;
}

void fragment() {
	ALBEDO = mix(belly_color.rgb, back_color.rgb, smoothstep(-0.3, 0.4, v_up));
	ROUGHNESS = 0.35;
	SPECULAR = 0.6;
}
