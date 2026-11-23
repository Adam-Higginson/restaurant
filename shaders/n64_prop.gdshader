// The N64 look for third-party props the Kiln has not fired yet (pots, crocks,
// bread). The packs paint their models in smooth flat colour, which reads as a
// modern toy. This keeps each model's own colour and lays a soft, mottled
// low-resolution grain over it, softly filtered as N64 textures were.
//
// The grain is placed in the object's own space (scaled to metres), so it
// sits still on the prop wherever the prop moves, on a sailing ship too.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// The model's own colour: its texture (the packs use a small palette) and tint.
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, hint_default_white;
uniform vec4 albedo_color : source_color = vec4(1.0);
// The chunky grain laid over it: light and dark pixels around mid grey.
uniform sampler2D grain : filter_linear, repeat_enable, hint_default_white;
// One copy of the grain covers this many metres.
uniform float grain_metres = 0.2;
// How strongly the grain shows.
uniform float grain_strength : hint_range(0.0, 1.0) = 0.12;
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
// Light each face as one flat colour, so the model's facets show like N64
// models' did, instead of smooth modern shading.
uniform bool faceted = true;
// How many shades of each colour channel: fewer is more like a small palette.
uniform float colour_levels = 10.0;

varying vec3 object_pos;
varying vec3 object_normal;


void vertex() {
	// Turned and scaled like the object, but measured from its own origin, so
	// it moves with it.
	object_pos = mat3(MODEL_MATRIX) * VERTEX;
	object_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
}


void fragment() {
	vec3 a = abs(object_normal);
	vec2 spot = a.y >= a.x && a.y >= a.z ? object_pos.xz
			: (a.x >= a.z ? object_pos.zy : object_pos.xy);
	float speck = texture(grain, spot / grain_metres).r;
	vec3 base = albedo_color.rgb * texture(albedo_texture, UV).rgb;
	vec3 colour = base * (1.0 + (speck - 0.5) * 2.0 * grain_strength);
	ALBEDO = floor(colour * colour_levels + 0.5) / colour_levels;
	if (faceted) {
		// The face's own direction, from how its position changes across
		// neighbouring pixels: the same for the whole face, so it's flat.
		NORMAL = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
	}
	ROUGHNESS = roughness;
}
