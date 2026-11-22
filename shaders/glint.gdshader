// A glint of light on a dead lantern's glass: a small soft star that always
// faces the camera, added on top of the picture, so a lantern's glow reads
// from any side (from straight above, its cap hides most of its glass).
// It has the same per-lantern glow as shaders/dead_glass.gdshader, set by
// LanternField (scripts/intro/lantern_field.gd).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;

uniform vec4 colour : source_color = vec4(1.0, 0.66, 0.26, 1.0);
// How bright it is for a glow of 1.
uniform float energy = 1.1;

// How strongly this lantern glows right now: 0 dead, about 3 at its glint.
instance uniform float glow = 0.0;

void vertex() {
	// Turn the sheet to face the camera, keeping its size.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
			INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 from_middle = UV * 2.0 - 1.0;
	float out_here = length(from_middle);
	// A soft dot, and four thin points that only show when it's bright.
	float dot_part = pow(max(1.0 - out_here, 0.0), 3.0);
	float points = max(1.0 - abs(from_middle.x) * 14.0, 0.0) + max(1.0 - abs(from_middle.y) * 14.0, 0.0);
	points *= pow(max(1.0 - out_here, 0.0), 2.0) * clamp(glow - 0.5, 0.0, 1.0);
	ALBEDO = colour.rgb * glow * energy * (dot_part + points * 0.8);
}
