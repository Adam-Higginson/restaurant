// The stylised look for characters (#168): soft anime cel shading. Light and
// shadow meet at a clear edge (or a few, with bands), the shadow side is
// tinted warm rather than just darkened, highlights are small hard shapes,
// and a thin rim of light catches the lit edge. The character's own texture
// and colour are kept.
//
// Every number here is set from a CharacterStyle (scripts/art/
// character_style.gd, data/art/styles/character.tres), so all characters
// share one look and one place to tune it. docs/look.md says what each does.
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

// The character's own painted texture and colour (from its imported material).
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, hint_default_white;
uniform vec4 albedo_color : source_color = vec4(1.0);
// Multiplies every character's colours: the shared base colour of the look.
uniform vec4 base_tint : source_color = vec4(1.0);

// Where light turns to shadow, as the cosine between the surface and the
// light: 0 is side-on, above 0 pushes more of the body into shadow.
uniform float shadow_threshold : hint_range(-1.0, 1.0) = 0.05;
// How soft each light/shadow edge is: 0 is a hard cut.
uniform float shadow_softness : hint_range(0.0, 0.5) = 0.04;
// How much the lit side still dims as it turns from the light, 0 to 1: 0 is
// flat cel colour, higher keeps some roundness inside the light.
uniform float lit_falloff : hint_range(0.0, 1.0) = 0.35;
// How many steps from shadow to full light: 1 is two-tone.
uniform int bands : hint_range(1, 4) = 1;
// What colour the shadow side is lit with, as a share of the light: warm
// and a little purple rather than grey.
uniform vec4 shadow_color : source_color = vec4(0.46, 0.44, 0.58, 1.0);
// How much of the world's ambient light the character takes, 0 to 1.
uniform float ambient_strength : hint_range(0.0, 1.0) = 0.75;

// The highlight: how strong, how big (0 to 1) and how soft its edge is.
uniform float specular_strength : hint_range(0.0, 2.0) = 0.25;
uniform float specular_size : hint_range(0.0, 0.5) = 0.05;
uniform float specular_softness : hint_range(0.0, 0.2) = 0.02;

// The rim of light on the lit edge: strength (0 turns it off), how far in
// from the outline it reaches (0 to 1), and its colour.
uniform float rim_strength : hint_range(0.0, 2.0) = 0.3;
uniform float rim_width : hint_range(0.0, 1.0) = 0.28;
uniform vec4 rim_color : source_color = vec4(1.0, 0.86, 0.66, 1.0);

// Near-white cloth repainted (ClothRecolour, scripts/art/cloth_recolour.gd):
// 0 leaves the paint alone. Above [recolour_split] metres from the model's
// feet it becomes [recolour_upper], below it [recolour_lower]. Only paint
// at least [recolour_min_brightness] bright and at most
// [recolour_max_saturation] coloured counts as cloth.
uniform float recolour_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 recolour_upper : source_color = vec4(0.46, 0.6, 0.74, 1.0);
uniform vec4 recolour_lower : source_color = vec4(0.5, 0.38, 0.28, 1.0);
uniform float recolour_split = 0.93;
uniform float recolour_min_brightness : hint_range(0.0, 1.0) = 0.62;
uniform float recolour_max_saturation : hint_range(0.0, 1.0) = 0.2;

// Which of this mesh's skin bones are under clothing, one bit per bone (set
// per mesh by ThirdPartyModel from its outfit). A point mostly weighted to
// hidden bones isn't drawn, so the body never pokes through the cloth.
instance uniform int hidden_bones = 0;

// How high this point is above the model's feet, in metres.
varying float height;
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
	height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y - MODEL_MATRIX[3].y;
	covered = hidden_bones == 0 ? 0.0 : under_cloth(BONE_INDICES, BONE_WEIGHTS);
}


void fragment() {
	if (covered > 0.5) {
		discard;
	}
	vec4 painted = texture(albedo_texture, UV) * albedo_color;
	vec3 paint = painted.rgb;
	if (recolour_strength > 0.0) {
		// Judge the paint as it looks (sRGB), not in the linear light the
		// texture arrives in, where pale cream reads dark and coloured.
		vec3 seen = pow(paint, vec3(1.0 / 2.2));
		float brightest = max(seen.r, max(seen.g, seen.b));
		float darkest = min(seen.r, min(seen.g, seen.b));
		float saturation = (brightest - darkest) / max(brightest, 0.001);
		float cloth = smoothstep(recolour_min_brightness - 0.08, recolour_min_brightness, brightest)
				* (1.0 - smoothstep(recolour_max_saturation, recolour_max_saturation + 0.06, saturation));
		vec3 dye = height > recolour_split ? recolour_upper.rgb : recolour_lower.rgb;
		// Keep the cloth's own folds and shading: dye it, scaled by its brightness.
		vec3 dyed = dye * clamp(brightest / 0.85, 0.0, 1.2);
		paint = mix(paint, dyed, cloth * recolour_strength);
	}
	ALBEDO = paint * base_tint.rgb;
	// No metal and no glossy reflections: the look's highlight is our own.
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	// AO only scales the ambient and reflected light, never the lamps.
	AO = ambient_strength;
	AO_LIGHT_AFFECT = 0.0;
}


// How lit a point is, 0 to 1, from the cosine between surface and light: a
// staircase of [bands] soft-edged steps starting at the threshold.
float steps(float facing) {
	float lit = 0.0;
	float count = float(max(bands, 1));
	for (int i = 0; i < max(bands, 1); i++) {
		float edge = mix(shadow_threshold, 1.0, float(i) / count);
		lit += smoothstep(edge - shadow_softness, edge + shadow_softness, facing);
	}
	return lit / count;
}


void light() {
	float facing = dot(NORMAL, LIGHT);
	float lit = steps(facing);
	// Cast shadows cut cleanly too. Sun and moon shadows come in ATTENUATION
	// alone; lamps also fade with distance there, which should stay smooth.
	float reach = 1.0;
	if (LIGHT_IS_DIRECTIONAL) {
		lit *= smoothstep(0.5 - shadow_softness - 0.05, 0.5 + shadow_softness + 0.05, ATTENUATION);
	} else {
		reach = ATTENUATION;
	}
	vec3 light = LIGHT_COLOR / PI * reach;
	float form = 1.0 - lit_falloff * (1.0 - clamp(facing, 0.0, 1.0));
	DIFFUSE_LIGHT += light * mix(shadow_color.rgb, vec3(form), lit);

	// A small hard highlight, only where lit.
	vec3 half_way = normalize(VIEW + LIGHT);
	float shine = smoothstep(1.0 - specular_size - specular_softness,
			1.0 - specular_size + specular_softness, dot(NORMAL, half_way));
	SPECULAR_LIGHT += light * shine * specular_strength * lit;

	// The rim: the edge seen side-on, on the side the light reaches.
	float edge_on = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = smoothstep(1.0 - rim_width - 0.03, 1.0 - rim_width + 0.03, edge_on);
	SPECULAR_LIGHT += light * rim_color.rgb * rim * rim_strength * lit;
}
