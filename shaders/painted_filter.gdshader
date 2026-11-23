shader_type spatial;
// PROTOTYPE (#168): a painted, cartoon finish over the whole picture, drawn
// on a quad that covers the screen.
// - A Kuwahara filter: each pixel takes the average of whichever nearby patch
//   is the most even. Fine texture noise melts into flat dabs of colour, and
//   edges stay crisp, like brush strokes.
// - Painted edges, the way an illustrator draws them and not an edge
//   detector: the line is a darker, warmer shade of the colour it's drawn on
//   (never black); outlines of things are firmer than the folds inside them;
//   and an edge that sticks out towards you (a table's rim, a beam's corner)
//   catches the light as a thin highlight, not a dark line.
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled,
		shadows_disabled;
// The scene makes two copies of this shader: one drawn only over characters
// (who mark the stencil buffer), one only over everything else.
// STENCIL

uniform sampler2D screen_texture : hint_screen_texture, filter_linear, repeat_disable;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D normal_texture : hint_normal_roughness_texture, filter_nearest, repeat_disable;

// How wide the brush is, in pixels at 1080p. 0 turns the filter off.
uniform float brush_size : hint_range(0.0, 8.0) = 3.5;
// Width of the line, in pixels at 1080p.
uniform float line_width : hint_range(0.0, 4.0) = 1.0;
// How dark the outline of a thing is against what's behind it (0 to 1).
uniform float line_strength : hint_range(0.0, 1.0) = 0.6;
// How dark a fold or inside corner is, as a share of the outline.
uniform float crease_strength : hint_range(0.0, 1.0) = 0.45;
// How bright an edge that sticks out is drawn.
uniform float highlight_strength : hint_range(0.0, 2.0) = 0.5;
// What the colour under a line is multiplied by: a darker, warmer shade.
uniform vec4 line_color : source_color = vec4(0.42, 0.26, 0.24, 1.0);
uniform vec4 highlight_color : source_color = vec4(1.0, 0.86, 0.62, 1.0);
// How big a step in depth (as a share of the distance) counts as an outline.
uniform float depth_edge : hint_range(0.0, 0.2) = 0.03;
// How sharp a turn of the surface counts as an edge (0 to 1).
uniform float normal_edge : hint_range(0.0, 1.0) = 0.45;
// Lines fade out beyond this distance in metres, so far detail doesn't clog.
uniform float line_fade_distance = 14.0;

const int TAPS = 4;


void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}


// Where the surface at this pixel is, in view space.
vec3 view_position(vec2 uv, mat4 inv_projection) {
	float depth = texture(depth_texture, uv).r;
	vec4 view = inv_projection * vec4(uv * 2.0 - 1.0, depth, 1.0);
	return view.xyz / view.w;
}


vec3 view_normal(vec2 uv) {
	return normalize(texture(normal_texture, uv).xyz * 2.0 - 1.0);
}


vec3 painted(vec2 uv, vec2 step_size) {
	vec3 best = vec3(0.0);
	float best_spread = 1e9;
	for (int quadrant = 0; quadrant < 4; quadrant++) {
		vec2 side = vec2(quadrant % 2 == 0 ? -1.0 : 1.0, quadrant < 2 ? -1.0 : 1.0);
		vec3 sum = vec3(0.0);
		float tone_sum = 0.0;
		float tone_squares = 0.0;
		for (int y = 0; y <= TAPS; y++) {
			for (int x = 0; x <= TAPS; x++) {
				vec3 colour = texture(screen_texture, uv + vec2(float(x), float(y)) * side * step_size).rgb;
				sum += colour;
				// Judge evenness on a squashed brightness, so a bright window
				// doesn't drown everything else.
				float tone = dot(colour / (1.0 + colour), vec3(0.3, 0.5, 0.2));
				tone_sum += tone;
				tone_squares += tone * tone;
			}
		}
		float count = float((TAPS + 1) * (TAPS + 1));
		float spread = tone_squares / count - (tone_sum / count) * (tone_sum / count);
		if (spread < best_spread) {
			best_spread = spread;
			best = sum / count;
		}
	}
	return best;
}


void fragment() {
	vec2 pixel = 1.0 / VIEWPORT_SIZE;
	float scale = VIEWPORT_SIZE.y / 1080.0;
	vec3 colour = texture(screen_texture, SCREEN_UV).rgb;
	if (brush_size > 0.0) {
		colour = painted(SCREEN_UV, pixel * scale * brush_size / float(TAPS));
	}

	if (line_width > 0.0) {
		vec2 reach = pixel * scale * line_width;
		vec3 here = view_position(SCREEN_UV, INV_PROJECTION_MATRIX);
		float distance_here = -here.z;
		vec3 facing = view_normal(SCREEN_UV);
		float depth_step = 0.0;
		float turn = 0.0;
		// Above zero where the surface bends away on every side (an edge
		// that sticks out), below where it folds in (an inside corner).
		float bulge = 0.0;
		float nearest = distance_here;
		vec2 around[4] = { vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0) };
		for (int i = 0; i < 4; i++) {
			vec2 uv = SCREEN_UV + around[i] * reach;
			vec3 there = view_position(uv, INV_PROJECTION_MATRIX);
			vec3 there_facing = view_normal(uv);
			depth_step += -there.z - distance_here;
			nearest = min(nearest, -there.z);
			turn = max(turn, 1.0 - dot(facing, there_facing));
			bulge += dot(there_facing - facing, normalize(there - here + vec3(0.0, 0.0, 1e-6)));
		}
		float fade = 1.0 - smoothstep(line_fade_distance * 0.5, line_fade_distance, nearest);
		// The sum of the four differences is near zero on a flat surface
		// however steeply it's seen, and large at a real step.
		float outline = smoothstep(depth_edge, depth_edge * 2.0, abs(depth_step) / distance_here);
		float crease = smoothstep(normal_edge, normal_edge + 0.2, turn) * (1.0 - outline);
		float sticks_out = smoothstep(0.0, 0.3, bulge);
		float dark = max(outline, crease * (1.0 - sticks_out) * crease_strength) * line_strength * fade;
		colour = mix(colour, colour * line_color.rgb, dark);
		// The highlight only shows where there's light to catch.
		float lit = smoothstep(0.03, 0.35, dot(colour, vec3(0.3, 0.5, 0.2)));
		colour += colour * highlight_color.rgb * crease * sticks_out * highlight_strength * lit * fade;
	}
	ALBEDO = colour;
}
