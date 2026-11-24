// A tongue of flame in the galley hearth (#207): a quad that always turns to
// face the camera about its upright axis, drawn as a flame with no texture.
// Its outline is a teardrop narrowing to a point, torn and licked by noise
// that scrolls up through it; its colour runs from a white-yellow core
// through orange to red at the edges. Added to what's behind it, so it glows.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// How fast the fire licks upward, and a number to set each tongue apart.
uniform float speed = 1.6;
uniform float seed = 0.0;
uniform vec4 core : source_color = vec4(1.0, 0.92, 0.62, 1.0);
uniform vec4 body : source_color = vec4(1.0, 0.52, 0.1, 1.0);
uniform vec4 edge : source_color = vec4(0.75, 0.16, 0.02, 1.0);
// How bright it burns.
uniform float intensity = 1.3;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float total = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		total += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return total;
}

void vertex() {
	// Turn to face the camera, staying upright (a Y billboard).
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);
}

void fragment() {
	// 0 at the logs, 1 at the tip.
	float up = 1.0 - UV.y;
	float t = TIME * speed + seed * 7.3;
	float n = fbm(vec2(UV.x * 3.0 + seed, up * 2.2 - t));
	// Bent side to side by the noise, more towards the tip.
	float across = (UV.x - 0.5) * 2.0 + (n - 0.5) * 0.7 * up;
	float width = mix(0.95, 0.04, pow(up, 0.8));
	float shape = 1.0 - smoothstep(width * 0.55, width, abs(across));
	shape *= smoothstep(0.0, 0.1, up);
	// Torn at the top: the noise eats into it as it rises.
	shape *= smoothstep(up * 0.85, up * 0.85 + 0.25, n + 0.35);
	float heat = clamp(shape * (1.15 - up * 0.8), 0.0, 1.0);
	vec3 colour = mix(edge.rgb, body.rgb, smoothstep(0.1, 0.5, heat));
	colour = mix(colour, core.rgb, smoothstep(0.6, 0.95, heat));
	ALBEDO = colour * intensity * heat;
	ALPHA = 1.0;
}
