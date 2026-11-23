// The body of the N64 surface shaders (n64_surface and n64_surface_vertex),
// shared so the two only differ in how they're lit.
//
// Draws a fired model's small baked texture, matte, lit by our modern lights.
// The Kiln has already painted the colours and the shading in the creases.
// Animated (skinned) models work too: Godot bends the mesh by its bones
// before this runs.

// The fired texture, read one whole pixel at a time.
uniform sampler2D albedo_texture : source_color, filter_nearest, hint_default_white;
// Multiplies the texture: above 1 in a channel makes it stronger.
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float specular : hint_range(0.0, 1.0) = 0.2;
// Light each face as one flat colour, like N64 props; off shades smoothly
// across faces, like N64 characters.
uniform bool faceted = true;
// Blend each pixel into its neighbours the N64's way: three pixels, not
// four, so the blend has its own slightly diagonal softness.
uniform bool three_point = false;


// The N64's three-point filter: the texture at [uv], blended from the pixel
// it's in and the two neighbours of the triangle (half of that pixel's
// square) it falls in.
vec4 three_point_sample(sampler2D tex, vec2 uv) {
	vec2 size = vec2(textureSize(tex, 0));
	vec2 across = vec2(1.0 / size.x, 0.0);
	vec2 down = vec2(0.0, 1.0 / size.y);
	vec2 centred = uv - (across + down) * 0.5;
	vec4 here = texture(tex, centred);
	vec4 right = texture(tex, centred + across);
	vec4 below = texture(tex, centred + down);
	vec4 diagonal = texture(tex, centred + across + down);
	vec2 part = fract(centred * size);
	if (part.x + part.y < 1.0) {
		return here + part.x * (right - here) + part.y * (below - here);
	}
	return diagonal + (1.0 - part.x) * (below - diagonal) + (1.0 - part.y) * (right - diagonal);
}


void fragment() {
	vec4 texel = three_point ? three_point_sample(albedo_texture, UV) : texture(albedo_texture, UV);
	ALBEDO = albedo_color.rgb * texel.rgb;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	if (faceted) {
		// The face's own direction, from how its position changes across
		// neighbouring pixels: the same for the whole face, so it's flat.
		NORMAL = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
	}
}
