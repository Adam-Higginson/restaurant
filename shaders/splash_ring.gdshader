// The ring of foam that spreads across the water where something has
// gone in. It's drawn on a flat sheet lying on the surface: a band of
// white that starts tight round the middle and widens as it travels out,
// ragged at its edges, thinning and fading as it goes. SplashRing
// (scripts/intro/splash_ring.gd) sets spread.
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 colour : source_color = vec4(0.82, 0.9, 0.95, 1.0);
// How far the ring has spread: 0 just begun, 1 spent.
uniform float spread = 0.0;
// How solid the foam is at its strongest.
uniform float strength = 0.85;

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

void fragment() {
	vec2 from_middle = UV * 2.0 - 1.0;
	float out_here = length(from_middle);
	// The band's middle travels out, and it gets wider as it goes.
	float middle = mix(0.06, 0.86, spread);
	float width = mix(0.05, 0.13, spread);
	// Ragged: the edge is pushed in and out by a little noise.
	vec2 way = from_middle / max(out_here, 0.0001);
	float ragged = (noise(way * 9.0 + TIME * 0.6) - 0.5) * 0.08;
	float band = 1.0 - smoothstep(width * 0.4, width, abs(out_here - middle + ragged));
	// Churned water inside the ring, soon gone.
	float churn = (1.0 - smoothstep(0.0, middle, out_here)) * noise(from_middle * 14.0 + TIME)
			* max(1.0 - spread * 2.2, 0.0) * 0.7;
	float fading = pow(max(1.0 - spread, 0.0), 1.3) * step(0.001, spread);
	ALBEDO = colour.rgb;
	ALPHA = clamp(band + churn, 0.0, 1.0) * strength * fading;
}
