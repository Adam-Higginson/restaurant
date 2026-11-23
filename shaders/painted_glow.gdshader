// A model whose painted texture has glowing parts, like a lantern's glass
// (#168). It's lit like any surface, and wherever the paint is bright enough
// it also gives off its own light, which blooms. PaintedGlow
// (scripts/art/painted_glow.gd) puts it on a model and sets these.
shader_type spatial;
render_mode cull_back;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, hint_default_white;
uniform vec4 albedo_color : source_color = vec4(1.0);
// How bright the paint must be (0 to 1) before it glows...
uniform float threshold : hint_range(0.0, 1.0) = 0.6;
// ...and how strongly it glows there: above 1 it blooms.
uniform float energy : hint_range(0.0, 16.0) = 3.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;


void fragment() {
	vec3 paint = texture(albedo_texture, UV).rgb * albedo_color.rgb;
	ALBEDO = paint;
	ROUGHNESS = roughness;
	float brightness = dot(paint, vec3(0.299, 0.587, 0.114));
	EMISSION = paint * smoothstep(threshold, threshold + 0.15, brightness) * energy;
}
