// The lantern spirit's hand: the same soft fire as his flame
// (shaders/lantern_glass.gdshader), poured into the outline of an arm and a
// hand. The outline is worked out with distances rather than drawn: for
// every texel we ask how far it is from the nearest part of the hand (the
// arm, the palm, each finger), and fill it with fire if it's inside. Moving
// those parts moves the hand, so it can reach out (reach), pull itself
// together from a shapeless wisp (form) and close round yours (grip).
// FlameHand (scripts/intro/flame_hand.gd) sets the uniforms.
//
// It's drawn on a flat sheet that runs from his door (the wrist end, where
// UV.x is 1) out to the fingertips (UV.x 0).
shader_type spatial;
render_mode unshaded, cull_disabled;

// How many texels along the arm and across it.
uniform vec2 texels = vec2(48.0, 30.0);
// The fire's colours when he's strong...
uniform vec4 hot : source_color = vec4(1.0, 0.92, 0.55, 1.0);
uniform vec4 warm : source_color = vec4(1.0, 0.55, 0.15, 1.0);
uniform vec4 ember : source_color = vec4(0.5, 0.16, 0.04, 1.0);
// ...and when he's nearly out.
uniform vec4 cold_hot : source_color = vec4(0.82, 0.93, 1.0, 1.0);
uniform vec4 cold_warm : source_color = vec4(0.3, 0.55, 1.0, 1.0);
uniform vec4 cold_ember : source_color = vec4(0.05, 0.12, 0.32, 1.0);
// How bright it glows: above 1 it blooms.
uniform float glow = 2.6;
// How fast the flames run along it.
uniform float speed = 1.5;
// Each hand flickers its own way.
uniform float seed = 0.0;
// How strong he is, 0 to 1: the fire's colour and brightness.
uniform float strength = 1.0;
// How far the arm reaches, 0 (nothing) to 1 (all the way out).
uniform float reach = 1.0;
// How well it holds the shape of a hand: 0 a shapeless wisp, 1 a hand.
uniform float form = 1.0;
// How far the fingers have closed: 0 an open hand, 1 closed round yours.
uniform float grip = 0.0;
// How long the sheet is against how wide it is (FlameHand sets it from the
// sheet, so the fingertips stay on it).
uniform float aspect = 1.6;
// Draw the hand smoothly; off snaps it to chunky
// texel squares.
uniform bool soft = true;

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

// How far p is from the line from a to b, less the line's thickness, which
// goes from r_a at one end to r_b at the other. Negative is inside.
float limb(vec2 p, vec2 a, vec2 b, float r_a, float r_b) {
	vec2 along = b - a;
	float h = clamp(dot(p - a, along) / max(dot(along, along), 0.0001), 0.0, 1.0);
	return length(p - a - along * h) - mix(r_a, r_b, h);
}

// The nearer of two distances, with the join between them rounded off.
float melt(float a, float b, float k) {
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h * (1.0 - h);
}

void fragment() {
	// Soft, the hand is drawn smoothly; otherwise
	// snapped to the texel grid, in chunky squares.
	vec2 uv = soft ? UV : (floor(UV * texels) + 0.5) / texels;
	// Along the arm from the wrist (0) and up across it (0 to 1).
	vec2 p = vec2((1.0 - uv.x) * aspect, 1.0 - uv.y);
	float t = TIME * speed + seed * 17.0;

	// The palm rides out along the arm as it reaches.
	float out_now = clamp(reach, 0.0, 1.0);
	vec2 palm = vec2(mix(0.08, 1.12, out_now), 0.5);
	// The arm is a wisp: it wavers, more the less it's holding together.
	float waver = sin(p.x * 7.0 - t * 2.6) * mix(0.07, 0.022, form);
	waver *= smoothstep(0.0, 0.3, p.x) * (1.0 - smoothstep(palm.x - 0.1, palm.x + 0.1, p.x));
	vec2 q = p - vec2(0.0, waver);

	float shaped = smoothstep(0.3, 1.0, form);
	float open = 1.0 - grip;
	float shape = limb(q, vec2(0.0, 0.5), palm, 0.035, mix(0.05, 0.075, shaped));
	float palm_size = mix(0.1, 0.19, shaped) * mix(0.3, 1.0, smoothstep(0.0, 0.2, out_now));
	shape = melt(shape, length(q - palm) - palm_size, 0.07);
	// Four fingers fanned out ahead of the palm, and a thumb above it.
	// Closing, they shorten and draw together.
	float finger_length = 0.36 * shaped * mix(0.35, 1.0, open);
	for (int i = 0; i < 4; i++) {
		float fan = (float(i) - 1.5) * mix(0.12, 0.34, open) - 0.05;
		vec2 way = vec2(cos(fan), sin(fan));
		vec2 root = palm + way * palm_size * 0.75;
		// Each finger sags a little by its own amount when it can't hold.
		float sag = (1.0 - form) * 0.12 * (0.4 + hash(vec2(float(i), seed)));
		vec2 tip = root + way * finger_length - vec2(0.0, sag);
		shape = melt(shape, limb(q, root, tip, 0.062, 0.048) + (1.0 - shaped) * 0.05, 0.03);
	}
	float thumb_way = mix(1.25, 0.7, grip);
	vec2 thumb_root = palm + vec2(-0.03, palm_size * 0.6);
	vec2 thumb_tip = thumb_root + vec2(cos(thumb_way), sin(thumb_way)) * 0.24 * shaped;
	shape = melt(shape, limb(q, thumb_root, thumb_tip, 0.062, 0.05) + (1.0 - shaped) * 0.05, 0.03);

	// Fire eats at the edge: a little when it holds, a lot when it doesn't.
	float lick = noise(vec2(p.x * 6.0 - t * 2.0, p.y * 8.0 + t * 0.5)) * 0.6
			+ noise(vec2(p.x * 13.0 - t * 3.1, p.y * 15.0 - t * 0.8)) * 0.4;
	shape += (lick - 0.45) * mix(0.16, 0.04, form);
	// But never through the arm: a thin core down its middle always holds,
	// so the flicker ruffles its edge without breaking it into pieces.
	float core = limb(q, vec2(0.0, 0.5), palm, 0.0, 0.0) - mix(0.016, 0.028, shaped);
	shape = min(shape, core);
	// Nothing past where it has reached, and nothing at all with no reach.
	if (shape > 0.0 || out_now <= 0.001) {
		discard;
	}

	// Hottest in the middle, in a few bands, like a small palette.
	float heat = clamp(clamp(-shape / 0.1, 0.0, 1.0) * 0.75 + lick * 0.45, 0.0, 1.0);
	float banded = heat * 5.0;
	// Soft, the bands' edges blend; otherwise they're hard steps.
	heat = soft ? (floor(banded) + smoothstep(0.25, 0.75, fract(banded))) / 5.0
			: floor(banded) / 5.0;
	float cool = 1.0 - smoothstep(0.08, 0.55, strength);
	vec3 hot_now = mix(hot.rgb, cold_hot.rgb, cool);
	vec3 warm_now = mix(warm.rgb, cold_warm.rgb, cool);
	vec3 ember_now = mix(ember.rgb, cold_ember.rgb, cool);
	vec3 colour = mix(ember_now, warm_now, smoothstep(0.1, 0.5, heat));
	colour = mix(colour, hot_now, smoothstep(0.5, 0.9, heat));
	float flicker = 0.85 + 0.15 * noise(vec2(t * 3.0, seed));
	ALBEDO = colour * (0.45 + heat) * glow * mix(0.5, 1.0, strength) * flicker;
}
