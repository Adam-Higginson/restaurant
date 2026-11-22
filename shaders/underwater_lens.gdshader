// What being under water does to the picture, for the underwater set. It's
// drawn on a sheet that covers the whole screen, right in front of the
// camera, and it reads the picture already drawn behind it and changes it:
//
// - The sea takes colour. Water soaks up red light first, then green, and
//   blue last, so the further away a thing is, the bluer and darker it
//   looks. For every pixel we look up how far away it is and take out that
//   much of each colour.
// - Heat shimmer. Near the lantern the water is warm and bends the light,
//   so the picture behind him wobbles and rises.
//
// UnderwaterLens (scripts/intro/underwater_lens.gd) says where the lantern
// is on screen and how hot he is.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, fog_disabled,
		shadows_disabled;

// The picture so far, and how far away each pixel of it is.
uniform sampler2D picture : hint_screen_texture, filter_linear, repeat_disable;
uniform sampler2D distances : hint_depth_texture, filter_nearest, repeat_disable;
// How much of red, green and blue the water soaks up in each metre.
uniform vec3 soak = vec3(0.045, 0.02, 0.012);
// The colour of deep water, which far-off things fade into.
uniform vec3 deep : source_color = vec3(0.004, 0.022, 0.036);
// The furthest it counts: beyond this everything is the deep's colour.
uniform float furthest = 22.0;
// Where the heat is on screen (0 to 1 across and down), how wide it
// spreads as a share of the screen's height, and how strong it is (0 none).
uniform vec2 heat_spot = vec2(0.5, 0.5);
uniform float heat_reach = 0.15;
uniform float heat = 0.0;
// The whole picture's brightness: above 1 for a moment of glare.
uniform float exposure = 1.0;
// How much the corners darken.
uniform float vignette = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	// Cover the screen whatever the camera is doing.
	POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float tall = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;

	// Shimmer: in the water round the lantern and above him, where it
	// rises warm, dying away with distance. Not over the lantern himself:
	// he stays sharp.
	vec2 from_heat = (uv - heat_spot) * vec2(tall, 1.0);
	from_heat.y = from_heat.y * (from_heat.y < 0.0 ? 0.5 : 1.4);
	float away = length(from_heat) / max(heat_reach, 0.0001);
	float warmth = heat * smoothstep(0.3, 0.55, away) * (1.0 - smoothstep(0.55, 1.0, away));
	vec2 wobble = vec2(noise(vec2(uv.x * 38.0, uv.y * 30.0 + TIME * 2.4)),
			noise(vec2(uv.x * 34.0 + 9.0, uv.y * 26.0 + TIME * 2.0))) - 0.5;
	uv += wobble * warmth * 0.014;

	vec3 colour = texture(picture, uv).rgb;
	// How far away this pixel is, in metres.
	float depth = texture(distances, uv).r;
	vec4 place = INV_PROJECTION_MATRIX * vec4(uv * 2.0 - 1.0, depth, 1.0);
	float far = min(length(place.xyz / place.w), furthest);
	// What's left of each colour after that much water, and the deep
	// showing through in its place.
	vec3 left = exp(-soak * far);
	colour = colour * left + deep * (1.0 - left);

	float corner = length((SCREEN_UV - 0.5) * vec2(1.0, 1.0 / tall) * 1.6);
	colour *= 1.0 - vignette * smoothstep(0.35, 1.0, corner);
	ALBEDO = colour * exposure;
}
