// Laid over the whole screen when the player is hurt. It reads the picture
// already drawn (the 3D world) and changes it in three ways:
// - drain: the colour drains to grey (while they're on their last heart);
// - fog: grey fog closes in from the edges of the screen, stirring;
// - flash: the whole picture flashes towards white.
// The HUD draws after it, so the hearts and toolbar stay untouched.
shader_type canvas_item;

// What's on screen behind this rectangle.
uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float fog : hint_range(0.0, 1.0) = 0.0;
uniform float drain : hint_range(0.0, 1.0) = 0.0;
uniform vec3 fog_colour : source_color = vec3(0.62, 0.64, 0.68);


// A cheap, blocky noise: the same for every pixel in a cell, so the fog's
// edge is chunky like the rest of the look.
float cell_noise(vec2 cell) {
	return fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
}


void fragment() {
	vec3 colour = texture(screen, SCREEN_UV).rgb;
	float grey = dot(colour, vec3(0.299, 0.587, 0.114));
	colour = mix(colour, vec3(grey), drain);
	// How near the edge this pixel is: 0 in the middle, 1 at the corners.
	vec2 from_middle = (UV - 0.5) * 2.0;
	float edge = length(from_middle * vec2(1.0, 0.8));
	float stir = cell_noise(floor(UV * vec2(40.0, 24.0) + floor(TIME * 6.0))) * 0.18;
	float fogged = smoothstep(1.15 - fog * 0.55, 1.45 - fog * 0.5, edge + stir) * fog;
	colour = mix(colour, fog_colour, fogged);
	colour = mix(colour, vec3(1.0), flash * 0.8);
	COLOR = vec4(colour, 1.0);
}
