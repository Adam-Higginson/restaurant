shader_type spatial;
// The Meshy hull drawn as made (#196), with round holes left undrawn where a
// HullOpening marks a porthole. The holes are cut in the shadow pass too, so
// a room's lamplight shines out through them and nowhere else.
//
// Its inside (the bulwarks you see from the deck) is drawn with planks of our
// own instead: Meshy painted the hull to be seen from outside, and up close
// its inner faces are smeared. The planks take their colour from a blurred
// read of Meshy's paint there, so they match the outside.

render_mode cull_disabled;

// How many openings there are, and each one as a transform from this mesh's
// space into the opening's own, where the hole is x² + y² < 1, -1 < z < 1.
const int MAX_OPENINGS = 32;
uniform int opening_count = 0;
uniform mat4 openings[MAX_OPENINGS];

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
// Painted wood isn't glossy: the roughness never goes below this.
uniform float least_roughness : hint_range(0.0, 1.0) = 0.7;

group_uniforms inside;
// Draw the inside with our planks (off: Meshy's paint everywhere).
uniform bool plank_inside = true;
// Plank height and how long each plank runs before a joint, in metres.
uniform float plank_height = 0.24;
uniform float plank_length = 2.6;
uniform float seam_darkness : hint_range(0.0, 1.0) = 0.5;
// How much the planks' shade varies from one to the next.
uniform float plank_tint : hint_range(0.0, 0.5) = 0.12;
// How much lighter or darker than Meshy's paint the planks are.
uniform float plank_shade : hint_range(0.3, 1.5) = 0.85;
// Debug: paint the skin marks (white outside, red inside).
uniform bool show_skin = false;

varying vec3 model_position;
// 1 on the hull's outside skin, 0 inside it (marked by HullShell when fitting).
varying float skin;


void vertex() {
	model_position = VERTEX;
	skin = COLOR.r;
}


float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}


void fragment() {
	for (int i = 0; i < opening_count; i++) {
		vec3 inside = (openings[i] * vec4(model_position, 1.0)).xyz;
		if (dot(inside.xy, inside.xy) < 1.0 && abs(inside.z) < 1.0) {
			discard;
		}
	}
	// Our planks go on the inside: the inner skin seen from its front, and the
	// outer skin seen from behind (through holes in Meshy's inner skin). The
	// inner skin seen from behind, through holes in the outer one, keeps
	// Meshy's paint so it passes for the outside.
	bool is_inside = plank_inside && ((skin < 0.5) == FRONT_FACING);
	if (is_inside) {
		float row = floor(model_position.y / plank_height);
		float across = fract(model_position.y / plank_height);
		float along = model_position.z / plank_length + hash(row) * 3.0;
		float plank = floor(along);
		float seam = smoothstep(0.0, 0.06, across) * smoothstep(0.0, 0.06, 1.0 - across);
		float joint = smoothstep(0.0, 0.012, fract(along)) * smoothstep(0.0, 0.012, 1.0 - fract(along));
		float grain = 0.94 + 0.06 * sin(model_position.z * 9.0 + hash(row + plank) * 6.0
				+ sin(model_position.z * 2.3 + row) * 2.0);
		vec3 paint = textureLod(albedo_texture, UV, 7.0).rgb * plank_shade;
		float shade = 1.0 + (hash(row * 7.0 + plank) - 0.5) * 2.0 * plank_tint;
		ALBEDO = paint * shade * grain * mix(1.0 - seam_darkness, 1.0, seam * joint);
		ROUGHNESS = 0.85;
	} else {
		ALBEDO = texture(albedo_texture, UV).rgb;
		NORMAL_MAP = texture(normal_texture, UV).rgb;
		NORMAL_MAP_DEPTH = normal_strength;
		ROUGHNESS = max(texture(roughness_texture, UV).g, least_roughness);
	}
	if (show_skin) {
		ALBEDO = is_inside ? vec3(0.8, 0.1, 0.1) : vec3(0.9);
	}
	METALLIC = 0.0;
}
