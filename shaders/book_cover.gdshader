shader_type spatial;
// One Meshy book (#196), its cover any colour: the tan leather of its covers
// and spine is painted in [cover], keeping the paint's light and shade. The
// gilt (the most saturated paint) and the page edges (on the top, the bottom
// and the fore-edge, by which way they face) keep their own colours.

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
// Each book's own cover colour (set per book, sharing one material).
instance uniform vec4 cover : source_color = vec4(0.55, 0.14, 0.12, 1.0);
// The brightness of Meshy's tan leather, so the new colour keeps its shading.
uniform float leather_brightness = 0.74;
// Paint more saturated than this is gilt (the leather has strong orange
// brush strokes too, nearly as saturated).
uniform float gilt_saturation = 0.95;

varying vec3 model_normal;


void vertex() {
	model_normal = NORMAL;
}


void fragment() {
	vec3 paint = texture(albedo_texture, UV).rgb;
	float high = max(paint.r, max(paint.g, paint.b));
	float low = min(paint.r, min(paint.g, paint.b));
	float saturation = high > 0.0 ? (high - low) / high : 0.0;
	vec3 normal = normalize(model_normal);
	// The covers face along z, the spine towards -x: the rest is pages.
	bool binding = abs(normal.z) > 0.5 || normal.x < -0.5;
	float brightness = dot(paint, vec3(0.2126, 0.7152, 0.0722)) / leather_brightness;
	bool recolour = binding && saturation < gilt_saturation;
	ALBEDO = recolour ? cover.rgb * brightness : paint;
	ROUGHNESS = 0.8;
}
