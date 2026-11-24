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
uniform vec4 outline_color : source_color = vec4(0.14, 0.1, 0.09, 1.0);
// How wide, in pixels at 1080 lines tall.
uniform float thickness : hint_range(0.0, 8.0) = 2.0;
// The widest it can be, in metres, however close the camera.
uniform float max_width : hint_range(0.0, 0.05) = 0.008;
// How far back (away from the camera) the line is drawn, in metres. It
// never wins against a surface at its own depth (a garment's lining, cloth
// close over the body), only where there's nothing in front: the silhouette.
uniform float depth_push : hint_range(0.0, 0.05) = 0.01;

// Which of this mesh's skin bones are under clothing, one bit per bone (set
// per mesh by ThirdPartyModel from its outfit). A point mostly weighted to
// hidden bones isn't drawn, so the body never pokes through the cloth.
instance uniform int hidden_bones = 0;

// Off (0) for a mesh that mustn't be outlined: a piece of clothing. Meshy
// makes a garment as a thick shell with a lining, and the outline round the
// lining shows through the cloth as dark patches (#172).
instance uniform float outline_amount = 1.0;

// How much of this point is under clothing, 0 to 1.
varying float covered;

// How much of a point hangs off hidden bones, 0 to 1.
float under_cloth(uvec4 bones, vec4 weights) {
	float share = 0.0;
	for (int i = 0; i < 4; i++) {
		if (bones[i] < 32u && ((uint(hidden_bones) >> bones[i]) & 1u) == 1u) {
			share += weights[i];
		}
	}
	return share;
}


void vertex() {
	covered = hidden_bones == 0 ? 0.0 : under_cloth(BONE_INDICES, BONE_WEIGHTS);
	vec3 spot = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 out_way = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	// How many metres one pixel covers at this depth, scaled to 1080p so the
	// width doesn't change with the window's size.
	float pixel = 2.0 * max(-spot.z, 0.01) / (PROJECTION_MATRIX[1][1] * 1080.0);
	spot += out_way * min(thickness * pixel, max_width);
	spot.z -= depth_push;
	POSITION = PROJECTION_MATRIX * vec4(spot, 1.0);
}


void fragment() {
	if (covered > 0.5 || outline_amount <= 0.0) {
		discard;
	}
	ALBEDO = outline_color.rgb;
}
