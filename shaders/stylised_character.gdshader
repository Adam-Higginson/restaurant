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
// Marks the stencil buffer wherever a stylised character is seen, so the
// painted filter can treat characters differently from the room.
stencil_mode write, compare_always, 1;
render_mode cull_back, depth_draw_opaque;

// The character's own painted texture and colour (from its imported material).
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, hint_default_white;
uniform vec4 albedo_color : source_color = vec4(1.0);
// Multiplies every character's colours: the shared base colour of the look.
uniform vec4 base_tint : source_color = vec4(1.0);
// The skin colour shut eyes are painted in.
uniform vec4 eyelid_color : source_color = vec4(0.9, 0.6, 0.4, 1.0);
// Shut eyes drawn closed (ClosedEyes, scripts/art/closed_eyes.gd; #172), in
// the head bone's own space: each eye's oval (middle x, y, half width and
// height; [lid_right] at -x, [lid_left] at +x), how far each is turned
// ([lid_tilt], radians), and only in front of [lid_front]. While shut, the
// oval is covered in [eyelid_color] and a lash line drawn through its
// corners, [lash_sag] of its half height lower in the middle. A zero-wide
// [lid_left] falls back to painting over whatever is eye-coloured.
uniform vec4 lid_right = vec4(0.0);
uniform vec4 lid_left = vec4(0.0);
uniform vec2 lid_tilt = vec2(0.0);
uniform float lid_front = 0.0;
uniform vec4 lash_color : source_color = vec4(0.2, 0.12, 0.07, 1.0);
uniform float lash_thickness = 0.14;
uniform float lash_sag = 0.3;

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
// PROTOTYPE: how far the surface is lit as if it were a smooth round column
// about the model's upright axis, 0 to 1. Lumps and folds in the mesh stop
// breaking the light/shadow edge into patches, leaving one clean shape.
instance uniform float round_form = 0.0;
// The column's line: a point on it and which way it runs, in the mesh's own
// space. Upright through the middle by default; a character that lies down
// or bends passes its hips and which way its body runs, or the rounding
// (made for a body standing up) shades it in dark patches.
instance uniform vec3 round_origin = vec3(0.0);
instance uniform vec3 round_axis = vec3(0.0, 1.0, 0.0);
// PROTOTYPE: the brightest any one light may be on this mesh (0 is no cap).
// A low sun hits an upright character far harder than the floor; capped, the
// lit side stays the character's own colour, warmed, and doesn't burn out.
instance uniform float light_cap = 0.0;
// How far this mesh's eyes are shut, 0 to 1 (#172). A Meshy face is one
// painted texture with no eyelids, so shut eyes are painted: whatever is
// eye-coloured (the whites, a blue iris) is painted over in [eyelid_color],
// which leaves the dark lash line the texture already has as a closed eye.
instance uniform float eyes_shut = 0.0;
// Where the head bone is now, for drawn closed eyes (set every frame): a
// point less [head_origin], measured along each head_ axis (each divided
// by its length squared), is that point in the head's own space.
instance uniform vec3 head_origin = vec3(0.0);
instance uniform vec3 head_x = vec3(1.0, 0.0, 0.0);
instance uniform vec3 head_y = vec3(0.0, 1.0, 0.0);
instance uniform vec3 head_z = vec3(0.0, 0.0, 1.0);
// PROTOTYPE: creatures with a shell (the crab). [ball_form] lights the mesh
// as a smooth dome about [ball_centre] (in the mesh's own space, [ball_radius]
// across), so a low-poly shell shades as one clean curve and not as facets.
// [shell] paints it like a shell: deeper and mottled with pale speckles on
// top, lighter and warmer underneath.
instance uniform float ball_form = 0.0;
instance uniform vec3 ball_centre = vec3(0.0);
instance uniform float ball_radius = 1.0;
instance uniform float shell = 0.0;

// How high this point is above the model's feet, in metres.
varying float height;
// How much of this point is under clothing, 0 to 1.
varying float covered;
// The surface's real facing, in view space, kept for the rim when the
// shading uses a rounded one.
varying vec3 true_normal;
// The facing the shading uses (in view space): the surface's own, or the
// rounded one. The mesh's real NORMAL is left alone, because Godot also
// uses it to place shadows, and a rounded one there makes the mesh shadow
// itself in dark patches.
varying vec3 shade_normal;
// Where this point is in the head bone's space, for drawn closed eyes.
varying vec3 face_at;
// Where this point is on the shell, about -1 to 1 each way, and which way
// its surface faces in the mesh's own space.
varying vec3 shell_point;
varying vec3 shell_facing;

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


// One drawn closed eye at [param at] (head space): how far it's covered
// (x) and how far it's on the lash line (y).
vec2 closed_eye(vec3 at, vec4 eye, float tilt) {
	vec2 from = at.xy - eye.xy;
	// Along and across the eye, as it's turned.
	vec2 d = vec2(cos(tilt) * from.x + sin(tilt) * from.y, -sin(tilt) * from.x + cos(tilt) * from.y);
	vec2 n = d / max(eye.zw, vec2(0.0001));
	float cover = 1.0 - smoothstep(0.9, 1.15, length(n));
	float line_y = -lash_sag * eye.w * (1.0 - n.x * n.x);
	float lash = (1.0 - smoothstep(lash_thickness * 0.5, lash_thickness, abs(d.y - line_y)))
			* (1.0 - smoothstep(0.8, 1.0, abs(n.x)));
	return vec2(cover, lash);
}


void vertex() {
	height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y - MODEL_MATRIX[3].y;
	covered = hidden_bones == 0 ? 0.0 : under_cloth(BONE_INDICES, BONE_WEIGHTS);
	true_normal = MODELVIEW_NORMAL_MATRIX * NORMAL;
	face_at = vec3(0.0);
	if (eyes_shut > 0.0 && lid_left.z > 0.0) {
		vec3 from_head = VERTEX - head_origin;
		face_at = vec3(dot(from_head, head_x), dot(from_head, head_y), dot(from_head, head_z));
	}
	shell_point = (VERTEX - ball_centre) / max(ball_radius, 0.0001);
	shell_facing = NORMAL;
	vec3 shaded = NORMAL;
	if (ball_form > 0.0) {
		// A dome: squashed a little, so the top faces up more than a ball's.
		vec3 dome = normalize(shell_point * vec3(1.0, 1.6, 1.0) + vec3(0.0, 0.25, 0.0));
		shaded = normalize(mix(shaded, dome, ball_form));
	}
	if (round_form > 0.0) {
		vec3 from_line = VERTEX - round_origin;
		from_line -= round_axis * dot(from_line, round_axis);
		vec3 outward = normalize(from_line + vec3(0.0, 0.0, 0.0001));
		shaded = normalize(mix(shaded, outward, round_form));
	}
	shade_normal = MODELVIEW_NORMAL_MATRIX * shaded;
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
	if (eyes_shut > 0.0 && lid_left.z > 0.0) {
		// Drawn closed: lids over both eyes, and a lash line across each.
		float in_front = smoothstep(lid_front - 0.3, lid_front + 0.3, face_at.z);
		vec2 eye = max(closed_eye(face_at, lid_right, lid_tilt.x),
				closed_eye(face_at, lid_left, lid_tilt.y)) * in_front * eyes_shut;
		paint = mix(paint, eyelid_color.rgb, eye.x);
		paint = mix(paint, lash_color.rgb, eye.y);
	} else if (eyes_shut > 0.0) {
		// Judged as it looks (sRGB): near white, or bluer than it is red or green.
		vec3 looks = pow(clamp(paint, 0.0, 1.0), vec3(1.0 / 2.2));
		float white = smoothstep(0.6, 0.75, min(looks.r, min(looks.g, looks.b)));
		float blue = smoothstep(0.0, 0.05, looks.b - max(looks.r, looks.g));
		paint = mix(paint, eyelid_color.rgb, clamp(white + blue, 0.0, 1.0) * eyes_shut);
	}
	if (shell > 0.0) {
		float top = smoothstep(-0.25, 0.6, normalize(shell_facing).y);
		vec3 at = shell_point * 4.2;
		// Soft blotches, and small pale speckles among them.
		float blotch = sin(at.x * 1.7 + sin(at.z * 2.3)) * sin(at.z * 1.9 + sin(at.x * 1.3));
		float speckle = sin(at.x * 5.3 + sin(at.z * 4.1) * 2.0) * sin(at.z * 6.1 + sin(at.x * 3.7) * 2.0);
		vec3 under = paint * vec3(1.3, 1.08, 0.92);
		vec3 over = paint * vec3(0.82, 0.52, 0.5);
		over = mix(over, paint * vec3(0.62, 0.36, 0.4), smoothstep(0.1, 0.7, blotch) * 0.7);
		over = mix(over, paint * vec3(1.45, 1.05, 0.85), smoothstep(0.72, 0.9, speckle) * 0.8);
		paint = mix(paint, mix(under, over, top), shell);
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
	vec3 shading = normalize(shade_normal);
	float facing = dot(shading, LIGHT);
	float lit = steps(facing);
	// Cast shadows cut cleanly too. Sun and moon shadows come in ATTENUATION
	// alone; lamps also fade with distance there, which should stay smooth.
	float reach = 1.0;
	if (LIGHT_IS_DIRECTIONAL) {
		lit *= smoothstep(0.5 - shadow_softness - 0.05, 0.5 + shadow_softness + 0.05, ATTENUATION);
	} else {
		reach = ATTENUATION;
	}
	vec3 light = LIGHT_COLOR / PI;
	if (light_cap > 0.0) {
		light /= max(1.0, max(light.r, max(light.g, light.b)) / light_cap);
	}
	light *= reach;
	float form = 1.0 - lit_falloff * (1.0 - clamp(facing, 0.0, 1.0));
	DIFFUSE_LIGHT += light * mix(shadow_color.rgb, vec3(form), lit);

	// A small hard highlight, only where lit.
	vec3 half_way = normalize(VIEW + LIGHT);
	float shine = smoothstep(1.0 - specular_size - specular_softness,
			1.0 - specular_size + specular_softness, dot(shading, half_way));
	SPECULAR_LIGHT += light * shine * specular_strength * lit;

	// The rim: the edge seen side-on, on the side the light reaches.
	float edge_on = 1.0 - clamp(dot(normalize(true_normal), VIEW), 0.0, 1.0);
	float rim = smoothstep(1.0 - rim_width - 0.03, 1.0 - rim_width + 0.03, edge_on);
	SPECULAR_LIGHT += light * rim_color.rgb * rim * rim_strength * lit;
}
