// A glowing mote of light, always facing the camera: a soft round spot,
// bright enough to bloom, fading with the particle's own colour (its
// colour ramp fades the alpha out as it rises). Used by the treasure
// chest's sparkles (#152).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 colour : source_color = vec4(1.0, 0.86, 0.5, 1.0);
// How bright a mote is at its middle: above 1 it blooms.
uniform float energy = 3.0;

void vertex() {
	// Face the camera, keeping the particle's own size.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
			INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	float spot = 1.0 - smoothstep(0.0, 0.5, length(UV - 0.5));
	ALBEDO = colour.rgb * energy * spot * spot * COLOR.a;
}
