// The sea's surface seen from underneath, for the underwater set: not real
// water, just a sheet of dim, shifting light a long way overhead that
// flares when lightning strikes above it, fading to nothing at its edges.
// SurfaceGlow (scripts/intro/surface_glow.gd) sets glow and flash.
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

// Soft cloudy noise, tiling, for the patches of light.
uniform sampler2D ripples : repeat_enable, filter_linear_mipmap;
// The colour of the light coming down through the water.
uniform vec3 tint : source_color = vec3(0.16, 0.34, 0.46);
// How bright the sheet is: 1 near the surface, less as you sink.
uniform float glow = 1.0;
// How bright a lightning flash is right now, 0 to 1.
uniform float flash = 0.0;
// How big the patches of light are, in metres.
uniform float patch_size = 18.0;
// How fast they drift, in patches a second.
uniform float drift = 0.02;
// How far from the middle the light reaches before it fades to nothing.
uniform float reach = 24.0;

varying vec3 world_spot;

void vertex() {
	world_spot = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 spot = world_spot.xz / patch_size;
	// Two layers sliding over each other, like swell and chop.
	float light = texture(ripples, spot + vec2(TIME * drift, TIME * drift * 0.6)).r;
	light *= texture(ripples, spot * 2.3 - vec2(TIME * drift * 1.4, 0.0)).r;
	light = smoothstep(0.12, 0.55, light);
	float fade = 1.0 - smoothstep(reach * 0.25, reach, length(world_spot.xz));
	ALBEDO = tint * light * glow + vec3(0.75, 0.85, 1.0) * flash * (0.3 + light);
	ALPHA = fade * clamp(light * glow + flash, 0.0, 1.0);
}
