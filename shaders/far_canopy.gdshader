// The treetops on the far hills (see IslandBackdrop): thousands of lumpy
// green crowns, each lit as a real one would be (bright where it faces the
// sun, dark underneath), then faded towards the colour of the sky by how
// far it is from the camera.
//
// It does its own simple lighting rather than Godot's, so the haze can be
// mixed in after the light: COLOR.r is extra mist for a crown low on its
// hill, COLOR.g a number of its own to vary its colour by.
shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled;

// The direction from the hills towards the sun (set by IslandBackdrop).
uniform vec3 to_sun = vec3(0.5, 0.35, -0.79);
uniform vec4 shade_color : source_color = vec4(0.02, 0.07, 0.03, 1.0);
uniform vec4 leaf_color : source_color = vec4(0.09, 0.2, 0.07, 1.0);
uniform vec4 sunlit_color : source_color = vec4(0.62, 0.66, 0.22, 1.0);
uniform vec4 haze_color : source_color = vec4(0.86, 0.87, 0.84, 1.0);
// How quickly things pale with distance: higher is hazier air.
uniform float haze_density = 0.0026;
// How lumpy a crown is, as a part of its size.
uniform float lumps = 0.22;

varying vec3 v_normal;
varying float v_haze;
varying float v_own;

void vertex() {
	// Push each point in or out so no two crowns are the same ball.
	float own = COLOR.g * 40.0;
	float lump = sin(VERTEX.x * 4.1 + own) * sin(VERTEX.y * 3.7 + own * 1.3) * sin(VERTEX.z * 4.4 - own);
	VERTEX += NORMAL * lump * lumps;
	v_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float distance_away = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	v_haze = 1.0 - exp(-distance_away * haze_density) + COLOR.r;
	v_own = COLOR.g;
}

void fragment() {
	vec3 normal = normalize(v_normal);
	// Dark underneath, leaf-green on top...
	vec3 crown = mix(shade_color.rgb, leaf_color.rgb, smoothstep(-0.5, 0.4, normal.y));
	// ...and bright where it faces the sun.
	float facing = dot(normal, normalize(to_sun));
	crown = mix(crown, sunlit_color.rgb, smoothstep(0.15, 0.95, facing) * 0.85);
	// No two trees quite the same green.
	crown *= 0.75 + 0.5 * v_own;
	ALBEDO = mix(crown, haze_color.rgb, clamp(v_haze, 0.0, 1.0));
}
