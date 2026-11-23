// A character's outline (#168), the "inverted hull" way: the character's
// mesh is drawn a second time (as its material's next pass), pushed out
// along its normals and showing only its back faces, in one dark colour.
// Only the rim that sticks out past the body shows, as a line round the
// silhouette and its big folds.
//
// It's the same mesh, so the skeleton bends it exactly as it bends the
// character: animations need nothing extra.
//
// The line is the same width on screen near and far, up to a cap in metres,
// so a face close up doesn't get a thick line on every small detail, and far
// away the line thins out instead of swallowing the character.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, fog_disabled;

// Dark brown, not black: it reads as a painted line, not a cut-out.
uniform vec4 outline_color : source_color = vec4(0.17, 0.11, 0.08, 1.0);
// How wide, in pixels at 1080 lines tall.
uniform float thickness : hint_range(0.0, 8.0) = 1.6;
// The widest it can be, in metres, however close the camera.
uniform float max_width : hint_range(0.0, 0.05) = 0.008;


void vertex() {
	vec3 spot = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 out_way = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	// How many metres one pixel covers at this depth, scaled to 1080p so the
	// width doesn't change with the window's size.
	float pixel = 2.0 * max(-spot.z, 0.01) / (PROJECTION_MATRIX[1][1] * 1080.0);
	spot += out_way * min(thickness * pixel, max_width);
	POSITION = PROJECTION_MATRIX * vec4(spot, 1.0);
}


void fragment() {
	ALBEDO = outline_color.rgb;
}
