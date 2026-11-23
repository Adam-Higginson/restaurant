// Canvas in the wind: a sail that bellies out and breathes.
//
// The sail is a flat, subdivided quad hung from its yard along its top edge
// (UV.y = 0) and held at its bottom corners by the sheets. Each vertex is
// pushed out along the quad's normal by a belly shape: nothing at the yard
// and the corners, most in the middle of the foot. The belly swells and
// eases slowly (gusts), and the loose foot flutters a little faster.
//
// `billow` is an instance uniform, so one material serves every piece of
// canvas aboard: the set sail has billow > 0, the furled bundles on the
// yards leave it at 0 and stay still.
//
// Like the deck, the canvas darkens as it soaks (the global `wetness`), and
// light comes through it from behind (backlight), so a lantern behind the
// sail glows through the cloth.
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// 0 dry, 1 soaked. Shared by every wet material; the Weather sets it.
global uniform float wetness;

uniform vec4 albedo : source_color = vec4(0.78, 0.71, 0.58, 1.0);
uniform sampler2D canvas_texture : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
// One copy of the texture covers this many metres.
uniform float texture_metres = 1.0;
// The sail's size in metres (x across, y down), to keep the texture's pixels
// square on a stretched quad.
uniform vec2 size = vec2(1.0, 1.0);
// How much light comes through the cloth from behind.
uniform vec3 backlight_colour : source_color = vec3(0.28, 0.22, 0.15);
// How much soaking darkens the canvas.
uniform float soak : hint_range(0.0, 1.0) = 0.35;

// How far the middle of the sail bellies out, in metres. 0 for furled canvas.
instance uniform float billow = 0.0;
// How fast the gusts come: the belly swells and eases about this many times a
// minute.
uniform float gusts_per_minute = 9.0;
// How much the loose foot flutters, in metres.
uniform float flutter = 0.05;


// How far the sail bellies out at (u, v), 0 to 1 across and down.
float belly(vec2 uv, float t) {
	// Held at both sides by the sheets, so nothing at u = 0 or 1; hung from
	// the yard, so nothing at the top, most towards the foot.
	float across = sin(PI * uv.x);
	float down = smoothstep(0.0, 0.85, uv.y);
	float gust = 1.0 + 0.12 * sin(t * TAU * gusts_per_minute / 60.0 + uv.x * 1.3)
			+ 0.05 * sin(t * 2.3 + uv.y * 4.0);
	float shape = billow * across * down * gust;
	// The foot is loose between the corners, so it flutters.
	float loose = uv.y * uv.y * uv.y * across;
	return shape + flutter * step(0.001, billow) * loose * sin(t * 7.0 + uv.x * 18.0);
}


void vertex() {
	float t = TIME;
	float here = belly(UV, t);
	// The surface's slope across and down, to bend the normal with the cloth.
	vec2 step_uv = vec2(0.02);
	float du = (belly(UV + vec2(step_uv.x, 0.0), t) - here) / (step_uv.x * size.x);
	float dv = (belly(UV + vec2(0.0, step_uv.y), t) - here) / (step_uv.y * size.y);
	VERTEX += NORMAL * here;
	// UV.y runs down the sail, which is -y in the quad's own space.
	NORMAL = normalize(NORMAL - TANGENT * du + BINORMAL * dv);
}


void fragment() {
	vec2 tex_uv = UV * size / texture_metres;
	vec3 canvas = albedo.rgb * texture(canvas_texture, tex_uv).rgb;
	float wet = clamp(wetness, 0.0, 1.0);
	ALBEDO = canvas * (1.0 - soak * wet);
	ROUGHNESS = mix(0.92, 0.75, wet);
	SPECULAR = 0.2;
	BACKLIGHT = backlight_colour;
}
