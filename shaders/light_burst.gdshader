// A burst of light spreading through the water: a ball that's brightest
// at its edge, like the front of a wave, and added on top of the picture
// rather than covering it. LightBurst (scripts/intro/light_burst.gd) grows
// it and fades it.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;

uniform vec4 colour : source_color = vec4(1.0, 0.72, 0.36, 1.0);
// How bright it is right now: 0 gone.
uniform float brightness = 0.0;
// How much brighter the edge is than the middle.
uniform float front = 3.0;

void fragment() {
	float edge = 1.0 - abs(dot(NORMAL, VIEW));
	ALBEDO = colour.rgb * brightness * (0.025 + front * pow(edge, 6.0));
}
