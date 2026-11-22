// The sea's surface seen from underneath, for the underwater set.
//
// Looking up from under water you don't see the whole sky. Light bends as
// it leaves the water, and past a certain slant (about 49 degrees from
// straight up) it can't get out at all: it bounces back down instead. So
// the sky shows only through a bright round window overhead, and everything
// outside that window is a mirror of the dark water below. Waves bend the
// edge of the window, so it wobbles. We work that out for every pixel from
// the slant between the camera and that bit of the surface.
//
// Through the window: the storm's dim, shifting light, flaring white when
// lightning strikes, pocked by rain. Outside it: a dark silver mirror with
// a few glints. SurfaceGlow (scripts/intro/surface_glow.gd) sets glow and
// flash.
shader_type spatial;
render_mode unshaded, cull_disabled;

// Soft cloudy noise, tiling, for the waves and the patches of light.
uniform sampler2D ripples : repeat_enable, filter_linear_mipmap;
// The colour of the light coming down through the window.
uniform vec3 tint : source_color = vec3(0.16, 0.34, 0.46);
// The colour of the deep water the mirror shows.
uniform vec3 mirror_tint : source_color = vec3(0.012, 0.045, 0.065);
// How bright the surface is: 1 near it, less as you sink.
uniform float glow = 1.0;
// How bright a lightning flash is right now, 0 to 1.
uniform float flash = 0.0;
// How big the patches of light are, in metres.
uniform float patch_size = 18.0;
// How fast they drift, in patches a second.
uniform float drift = 0.02;
// How far from the middle the surface reaches before it's lost in the deep.
uniform float reach = 24.0;
// The colour of the deep, which its far edge fades into.
uniform vec3 deep : source_color = vec3(0.004, 0.018, 0.03);
// How steep the waves are: how much they bend the window's edge.
uniform float chop = 0.16;
// How hard it's raining on the surface, 0 to 1.
uniform float rain = 1.0;

varying vec3 world_spot;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Rings spreading where raindrops land: one drop at a time in each square
// of a grid, each starting at its own moment.
float rain_rings(vec2 at, float size) {
	vec2 cell = floor(at / size);
	vec2 within = fract(at / size) - 0.5;
	float age = fract(TIME * (0.7 + hash(cell) * 0.6) + hash(cell + 3.7));
	vec2 centre = (vec2(hash(cell + 1.3), hash(cell + 2.1)) - 0.5) * 0.5;
	float ring = abs(length(within - centre) - age * 0.42);
	return (1.0 - smoothstep(0.0, 0.05, ring)) * (1.0 - age);
}

void vertex() {
	world_spot = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 spot = world_spot.xz / patch_size;
	// Two layers sliding over each other, like swell and chop.
	float swell = texture(ripples, spot + vec2(TIME * drift, TIME * drift * 0.6)).r;
	float small = texture(ripples, spot * 2.3 - vec2(TIME * drift * 1.4, 0.0)).r;
	float fine = texture(ripples, spot * 6.1 + vec2(0.0, TIME * drift * 2.2)).r;

	// Which way this bit of the surface faces, tipped by the waves.
	vec2 slope = vec2(small - 0.5, fine - 0.5) * chop + vec2(swell - 0.5) * chop * 0.6;
	vec3 facing = normalize(vec3(slope.x, -1.0, slope.y));
	// The line of sight from the camera up to here, and how squarely it
	// meets the surface. Less than 0 for "window": the light can't get out.
	vec3 sight = normalize(world_spot - CAMERA_POSITION_WORLD);
	float square_on = dot(facing, -sight);
	float window = 1.0 - 1.33 * 1.33 * (1.0 - square_on * square_on);
	float through = smoothstep(-0.04, 0.16, window);

	// Through the window: the storm's light, in patches, brightest at the
	// rim where the whole horizon is squeezed into a thin ring.
	float cloud = smoothstep(0.1, 0.6, swell * small * 2.2);
	float rim = through * (1.0 - smoothstep(0.0, 0.35, window));
	float drops = (rain_rings(world_spot.xz, 0.9) + rain_rings(world_spot.xz + 4.3, 1.4)) * rain;
	vec3 sky = tint * (0.25 + cloud + rim * 0.9 + drops * 0.5) * glow;
	sky += vec3(0.75, 0.85, 1.0) * flash * (0.5 + cloud + rim);

	// Outside it: the dark water mirrored, with glints where a wave tips
	// just right, and a ghost of the lightning.
	float glint = pow(fine * small * 2.0, 7.0);
	vec3 mirror = mirror_tint * (0.8 + glow * 1.2) + tint * glint * 0.35 * glow;
	mirror += vec3(0.6, 0.75, 1.0) * flash * (0.06 + glint * 0.6);

	float fade = 1.0 - smoothstep(reach * 0.4, reach, length(world_spot.xz));
	ALBEDO = mix(deep, mix(mirror, sky, through), fade);
}
