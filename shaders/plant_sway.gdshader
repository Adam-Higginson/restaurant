// A plant that moves in the wind and lets the sun through its leaves. Used
// on Meshy plants in place of their own material (see PlantSway), keeping
// their painted texture.
//
// The sway is done in the vertex function: each point of the model is
// pushed sideways, more the higher up the plant it is, so the foot stays
// put and the crown swings. Each plant swings to its own beat, from where
// it stands.
shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
// How far the top swings and the leaves flutter, as a part of the plant's height.
uniform float sway = 0.035;
uniform float flutter = 0.012;
// The part of the plant's height below which nothing moves.
uniform float still_below = 0.1;
// How much sunlight comes through the leaves from behind.
uniform float glow_through = 0.6;
// The way the wind blows (x, z).
uniform vec2 wind = vec2(0.8, 0.6);
// How much harder the swell pushes than the steady breeze.
uniform float gustiness = 0.35;
// Multiplies the painted colours: below 1 darkens the plant.
uniform vec4 tint : source_color = vec4(1.0);

void vertex() {
	// With world_vertex_coords, VERTEX is already in the world. The model's
	// origin is its middle, and its height is how much MODEL_MATRIX scales Y
	// (Meshy models are about one unit tall before scaling).
	vec3 origin = MODEL_MATRIX[3].xyz;
	float tall = length(MODEL_MATRIX[1].xyz);
	float up = clamp((VERTEX.y - origin.y) / tall + 0.5, 0.0, 1.0);
	float moves = smoothstep(still_below, 1.0, up);
	float beat = origin.x * 0.37 + origin.z * 0.51;
	// A slow sway, a few seconds there and back, with a slower drift under it
	// so it never quite repeats.
	float swing = sin(TIME * 0.55 + beat) * 0.7 + sin(TIME * 0.23 + beat * 1.7) * 0.3;
	// A long, gentle swell of breeze crosses the island: each plant leans a
	// little more as it passes.
	vec2 blowing = normalize(wind);
	float gust = sin(dot(origin.xz, blowing) * 0.05 - TIME * 0.25) * 0.5 + 0.5;
	// Leaning with the breeze a little all the time, and swaying about that.
	vec2 push = blowing * (0.3 + gust * gustiness + swing * 0.55)
			* sway * tall * moves * moves;
	// The leaves stir slowly.
	float shiver = sin(TIME * 1.1 + VERTEX.x * 0.9 + VERTEX.z * 1.1 + beat) * 0.5;
	VERTEX.xz += push;
	VERTEX.y += shiver * flutter * tall * moves * moves;
	VERTEX.xz += vec2(shiver) * flutter * 0.5 * tall * moves * moves;
}

void fragment() {
	vec3 colour = texture(albedo_texture, UV).rgb;
	ALBEDO = colour * tint.rgb;
	ROUGHNESS = 0.8;
	SPECULAR = 0.2;
	// Leaves let light through; bark doesn't. A leaf is whatever is painted
	// green.
	float leaf = smoothstep(0.02, 0.12, colour.g - max(colour.r, colour.b) * 0.9);
	BACKLIGHT = vec3(0.55, 0.75, 0.2) * leaf * glow_through;
}
