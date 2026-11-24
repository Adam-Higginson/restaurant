// The surface of a liquid in a pot, pan or bowl (#207): water, stock or soup.
// Its colour (and, for water, how see-through it is) comes from the item.
// Glossy, so it catches the galley's lamps, with small ripples running
// across it so it reads as liquid rather than a painted disc.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// The liquid's colour; alpha below 1 lets the pot's floor show through.
uniform vec4 colour : source_color = vec4(0.55, 0.7, 0.82, 0.85);
// How fast the ripples run, and how many fit across the surface.
uniform float ripple_speed = 0.8;
uniform float ripple_scale = 14.0;
// How much the ripples bend the light.
uniform float ripple_strength = 0.35;

void fragment() {
	vec2 p = UV * ripple_scale;
	float t = TIME * ripple_speed;
	// Two crossing sets of waves; their slopes tilt the surface's normal.
	float dx = cos(p.x * 1.3 + t * 2.1) * 0.6 + cos((p.x + p.y) * 0.9 - t * 1.4) * 0.4;
	float dy = cos(p.y * 1.1 - t * 1.8) * 0.6 + cos((p.x - p.y) * 0.8 + t * 1.6) * 0.4;
	NORMAL_MAP = normalize(vec3(0.5 + dx * ripple_strength * 0.5,
			0.5 + dy * ripple_strength * 0.5, 1.0));
	ALBEDO = colour.rgb;
	ALPHA = colour.a;
	ROUGHNESS = 0.08;
	SPECULAR = 0.7;
	METALLIC = 0.0;
}
