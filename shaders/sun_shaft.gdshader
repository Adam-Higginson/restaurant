// A shaft of sunlight coming down through the palms: a long soft-edged
// strip, added on top of the picture so it brightens whatever is behind it
// and never darkens. SunShafts lays many of these along the sun's rays.
//
// UV.x runs across the strip and UV.y along it, from the ground end (0) to
// the canopy end (1).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 colour : source_color = vec4(1.0, 0.86, 0.6, 1.0);
// How bright a shaft is at its brightest.
uniform float energy = 0.17;
// Within this many metres of something solid a shaft fades, so it never
// shows a hard line where it meets the ground or a trunk.
uniform float soft_metres = 1.5;
// A shaft fades as you come within this many metres of it, so you never
// walk through a bright sheet.
uniform float near_metres = 6.0;
// Shafts fade out with distance, between these two distances in metres: from
// far off they'd pile up into a bright smear over the trees.
uniform float far_from = 35.0;
uniform float far_to = 70.0;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear, repeat_disable;

varying float v_beat;

void vertex() {
	// Each shaft breathes to its own slow beat, from where it stands.
	vec3 origin = MODEL_MATRIX[3].xyz;
	v_beat = origin.x * 0.73 + origin.z * 1.31;
}

void fragment() {
	// Soft across, with a few brighter streaks inside; fading at both ends.
	float across = sin(UV.x * PI);
	across *= across;
	float streaks = 0.7 + 0.3 * sin(UV.x * 23.0 + v_beat * 5.0);
	float along = smoothstep(0.0, 0.25, UV.y) * (1.0 - smoothstep(0.55, 1.0, UV.y));
	float breathe = 0.8 + 0.2 * sin(TIME * 0.5 + v_beat);

	// How far behind this strip the nearest solid thing is.
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec4 behind = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float gap = -behind.z / behind.w + VERTEX.z;
	float soft = clamp(gap / soft_metres, 0.0, 1.0);
	float close_by = clamp(-VERTEX.z / near_metres - 0.3, 0.0, 1.0);

	float far_off = 1.0 - smoothstep(far_from, far_to, -VERTEX.z);

	ALBEDO = colour.rgb * energy * across * streaks * along * breathe * soft * close_by * far_off;
}
