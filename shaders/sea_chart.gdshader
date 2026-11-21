// A sea chart pinned to the wall: parchment with a few islands, a grid and a
// dotted course, all drawn in chunky texels. The islands come from noise, so
// it's a made-up sea (the fog-wrapped one the crew sails).
shader_type spatial;

uniform vec4 paper : source_color = vec4(0.86, 0.76, 0.56, 1.0);
uniform vec4 ink : source_color = vec4(0.32, 0.22, 0.14, 1.0);
uniform vec4 land : source_color = vec4(0.62, 0.66, 0.42, 1.0);
uniform float texels = 40.0;


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
	vec2 uv = (floor(UV * vec2(texels, texels * 0.67)) + 0.5) / vec2(texels, texels * 0.67);
	vec3 colour = paper.rgb * (0.85 + 0.15 * noise(uv * 9.0));
	// Islands: high spots of noise, outlined in ink.
	float height = noise(uv * 4.0 + 2.3) * 0.7 + noise(uv * 9.0) * 0.3;
	if (height > 0.62) {
		colour = land.rgb;
	} else if (height > 0.58) {
		colour = ink.rgb;
	}
	// A faint grid.
	vec2 grid = abs(fract(uv * 4.0) - 0.5);
	colour = mix(colour, ink.rgb, step(0.47, max(grid.x, grid.y)) * 0.35);
	// A dotted course across it.
	float course = abs(uv.y - (0.3 + 0.35 * uv.x + 0.08 * sin(uv.x * 9.0)));
	colour = mix(colour, vec3(0.6, 0.15, 0.1), step(course, 0.02) * step(0.5, fract(uv.x * 12.0)));
	// Darker, worn edges.
	vec2 edge = min(UV, 1.0 - UV);
	colour *= 0.7 + 0.3 * smoothstep(0.0, 0.08, min(edge.x, edge.y));
	ALBEDO = colour;
	ROUGHNESS = 0.9;
}
