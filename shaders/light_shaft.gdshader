// A shaft of lightning coming down through the water: brightest where it
// enters, at the top, and fading to nothing long before it finds a bottom.
// It's drawn on a tall widening tube, added on top of the picture, with
// soft sides so it looks like light and not a solid thing. Anything dark in
// front of it shows as a shape against it; anything solid hides what's
// behind. LightningShafts (scripts/intro/lightning_shafts.gd) sets flash.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;

uniform vec4 colour : source_color = vec4(0.6, 0.78, 1.0, 1.0);
// How bright a shaft is at the top, at the height of a flash.
uniform float energy = 0.22;
// How quickly it fades on the way down: higher fades sooner.
uniform float fade = 1.3;
// How bright the lightning is right now, 0 to 1.
uniform float flash = 0.0;

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
	// Soft at the sides: full where the tube faces you, nothing at its edge.
	float facing = pow(abs(dot(NORMAL, VIEW)), 2.4);
	// UV.y runs from the top of the tube (0) to the bottom (1).
	// And nothing at all at either end, so the tube's rims never show.
	float down = pow(max(1.0 - UV.y, 0.0), fade) * smoothstep(0.0, 0.06, UV.y);
	// Faint streaks running down it, drifting.
	float streaks = 0.55 + 0.45 * noise(vec2(UV.x * 14.0, UV.y * 1.5 - TIME * 0.04));
	// A shaft right in front of the camera (or one it's passing through)
	// would white the picture out, so it thins to nothing close up.
	float close_up = smoothstep(2.5, 10.0, -VERTEX.z);
	ALBEDO = colour.rgb * flash * energy * facing * down * streaks * close_up;
}
