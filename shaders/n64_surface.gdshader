// How models fired in the Kiln are drawn: their small baked texture with
// chunky, unsmoothed pixels, matte, lit by our modern lights. The Kiln has
// already painted the colours and the shading in the creases, so this only
// draws them.
//
// Animated (skinned) models work too: Godot bends the mesh by its bones
// before this runs.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// The fired texture, read one whole pixel at a time.
uniform sampler2D albedo_texture : source_color, filter_nearest, hint_default_white;
// Multiplies the texture: above 1 in a channel makes it stronger.
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float specular : hint_range(0.0, 1.0) = 0.2;
// Light each face as one flat colour, like N64 props; off shades smoothly
// across faces, like N64 characters.
uniform bool faceted = true;


void fragment() {
	ALBEDO = albedo_color.rgb * texture(albedo_texture, UV).rgb;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	if (faceted) {
		// The face's own direction, from how its position changes across
		// neighbouring pixels: the same for the whole face, so it's flat.
		NORMAL = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
	}
}
