// A light far off in the fog: a lighthouse, or another ship. Too far away
// for the fog to let it through, so it ignores the fog and draws itself as a
// soft glow that's always faint, swelling every so often as its beam sweeps
// past. It always faces the camera.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

uniform vec3 colour : source_color = vec3(1.0, 0.82, 0.55);
// How bright it is between sweeps, and at the height of one.
uniform float resting = 0.12;
uniform float peak = 0.9;
// Seconds for the beam to come round once.
uniform float period = 9.0;
// The glow's soft edge: higher is a smaller, tighter point.
uniform float tightness = 3.0;


void vertex() {
	// Face the camera: keep the quad's position, take the camera's turn.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
			INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}


void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float glow = pow(clamp(1.0 - r, 0.0, 1.0), tightness);
	// The sweep: a quick swell, then a long wait.
	float phase = fract(TIME / period);
	float sweep = exp(-pow((phase - 0.5) * 9.0, 2.0));
	ALBEDO = colour * glow * mix(resting, peak, sweep);
}
