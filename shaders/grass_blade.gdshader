// Blades of grass (see GrassPatch): coloured from root to tip, swaying in
// the wind, with the sun glowing through. UV.y is 0 at a blade's root and 1
// at its tip.
shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

uniform vec4 root_color : source_color = vec4(0.06, 0.13, 0.03, 1.0);
uniform vec4 tip_color : source_color = vec4(0.27, 0.42, 0.1, 1.0);
// How far a tip swings, in metres.
uniform float sway = 0.12;
// The way the wind blows (x, z).
uniform vec2 wind = vec2(0.8, 0.6);
uniform float glow_through = 0.35;

varying float v_shade;

void vertex() {
	float up = UV.y;
	// Gusts cross the patch as waves, so the grass moves in sweeps.
	float gust = sin(TIME * 1.3 + VERTEX.x * 0.35 + VERTEX.z * 0.27);
	float shiver = sin(TIME * 5.1 + VERTEX.x * 3.3 + VERTEX.z * 2.9);
	VERTEX.xz += normalize(wind) * (0.3 + gust * 0.7 + shiver * 0.15) * sway * up * up;
	// Tufts differ a little in colour, by where they stand.
	vec3 origin = MODEL_MATRIX[3].xyz;
	v_shade = 0.85 + 0.3 * fract(sin(origin.x * 12.9898 + origin.z * 78.233) * 43758.5453);
}

void fragment() {
	vec3 colour = mix(root_color.rgb, tip_color.rgb, UV.y) * v_shade;
	ALBEDO = colour;
	ROUGHNESS = 0.85;
	SPECULAR = 0.1;
	BACKLIGHT = vec3(0.5, 0.65, 0.15) * glow_through * UV.y;
}
