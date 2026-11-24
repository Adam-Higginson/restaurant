// A Meshy lantern with its painted glass cut away (#199). Its texture paints
// the glass, and the flame in it, as flat yellow. Every part of the model
// inside the lantern's glass box isn't drawn at all, so the real glass, with
// a flame burning in it (shaders/lantern_flame.gdshader), shows instead. The
// frame round the glass stays, lit like any surface. PaintedGlow
// (scripts/art/painted_glow.gd) puts it on a model when its see_through is
// on, and works out [to_glass] for each of the model's meshes.
shader_type spatial;
// Both sides drawn, so through the glass you see the inside of the frame.
render_mode cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, hint_default_white;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
// From this mesh's own space to the glass box's...
uniform mat4 to_glass = mat4(1.0);
// ...half the size of the box cut away there, centred on the glass...
uniform vec3 cut_half = vec3(0.0);
// ...except its corners, where the posts stand: anything further out than
// this on both x and z stays (0 keeps no corners).
uniform float corner = 0.0;
// The most light any one lamp can give the frame. The lantern's own light
// sits a few centimetres from the inside of its frame and would burn it
// white; capped, it glows warm instead.
uniform float light_cap = 1.0;

varying vec3 glass_spot;


void vertex() {
	glass_spot = (to_glass * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	vec3 off = abs(glass_spot);
	bool in_a_corner = corner > 0.0 && min(off.x, off.z) > corner;
	if (all(lessThan(off, cut_half)) && !in_a_corner) {
		discard;
	}
	ALBEDO = texture(albedo_texture, UV).rgb * albedo_color.rgb;
	ROUGHNESS = roughness;
}


// Lit like Godot's usual diffuse light, each lamp's share capped.
void light() {
	float facing = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	DIFFUSE_LIGHT += min(LIGHT_COLOR * ATTENUATION * facing / PI, vec3(light_cap));
}
