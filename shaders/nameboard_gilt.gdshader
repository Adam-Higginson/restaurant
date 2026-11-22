// The ship's name, carved on her stern and gilded long ago. It's drawn to
// look like part of the timber, not lettering laid over it:
//  - in chunky texels, like the ship's other blocky textures;
//  - with the wood's grain running through the gold, the way the planks run;
//  - worn: the gold has flaked off in patches, leaving dark carved wood, and
//    small chips are missing altogether;
//  - with its cut edges dark, except where one faces the lamp.
// And worn gold doesn't show in the dark, it only catches light: each
// letter glows by how near the lantern on the hook is, a few flecks
// glinting as it passes, and the whole name flashes with lightning.
// NameGilt (scripts/intro/name_gilt.gd) sets lamp, lamp_glow, reach and flash.
shader_type spatial;
render_mode unshaded, cull_disabled;

// The gold where the light catches it, and the carved wood under it.
uniform vec3 gold : source_color = vec3(1.0, 0.72, 0.3);
uniform vec3 wood : source_color = vec3(0.1, 0.065, 0.04);
// Where the lamp is, in the world.
uniform vec3 lamp = vec3(0.0, -1000.0, 0.0);
// How bright the lamp is: 0 with no lamp, 1 at full strength.
uniform float lamp_glow = 0.0;
// How far the lamp's light reaches along the letters, in metres.
uniform float reach = 1.15;
// How bright a lightning flash is right now, 0 to 1.
uniform float flash = 0.0;
// How brightly the gold shines at its brightest: above 1 it blooms a little.
uniform float shine = 1.45;
// How many texels to a metre: lower is chunkier.
uniform float texels_per_metre = 120.0;
// How much of the gold has worn away, 0 (new) to 1 (nearly all gone).
uniform float wear : hint_range(0.0, 1.0) = 0.2;
// How much of the lettering has chipped off altogether, 0 to 1.
uniform float chips : hint_range(0.0, 1.0) = 0.025;
// How strongly the wood's grain shows through the gold.
uniform float grain : hint_range(0.0, 1.0) = 0.5;

// Where this bit of a letter is on the board itself (so the wear stays put
// as the ship sails), and in the world (to measure to the lamp).
varying vec3 board_spot;
varying vec3 world_spot;
varying vec3 world_normal;

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

void vertex() {
	board_spot = VERTEX;
	world_spot = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Snap to a grid of texels, so it's drawn in the same chunky squares
	// as the planks around it.
	vec2 texel = floor(board_spot.xy * texels_per_metre);
	vec2 face = (texel + 0.5) / texels_per_metre;
	// The same texel's place in the world, for the light.
	vec3 spot = world_spot + vec3(face - board_spot.xy, 0.0);

	// Grain: long streaks along the plank, a little wavy.
	float streak = noise(vec2(face.x * 2.5, face.y * 46.0 + noise(face * 3.0) * 2.0));
	// Wear: patches smaller than a letter, broken up by smaller ones still,
	// so every letter keeps most of its gold. Worst low down, where the
	// spray reaches.
	float patches = noise(face * 9.0) * 0.6 + noise(face * 24.0 + 17.0) * 0.4;
	float low = 1.0 - smoothstep(-0.03, 0.13, board_spot.y);
	float gilded = smoothstep(wear - 0.07, wear + 0.07, patches - streak * 0.12 - low * 0.1);
	// Chips: single texels of the carving gone, showing the board behind.
	float chip = hash(texel);
	if (chip < chips * (1.0 - gilded * 0.6)) {
		discard;
	}

	// How much light reaches this spot: the lamp, and lightning.
	float near = 1.0 - smoothstep(reach * 0.2, reach, distance(spot, lamp));
	float lit = clamp(near * lamp_glow + flash * 0.9, 0.0, 1.0);
	// The cut edges of the letters are in shadow unless they face the lamp.
	bool edge = abs(world_normal.z) < 0.5;
	float facing = max(dot(world_normal, normalize(lamp - spot)), 0.0);

	// Bare carved wood: nearly lost in the dark, a dull brown in the light.
	vec3 bare = wood * (0.6 + streak * 0.8) * (0.5 + lit * 2.2);
	// Gold leaf: tarnished and almost black with no light on it.
	float flecks = step(0.9, hash(texel + 3.0));
	vec3 leaf = gold * shine * (1.0 - grain * 0.55 * (1.0 - streak)) * (1.0 + flecks * 0.6);
	vec3 gilt = mix(wood * 0.9, leaf, lit);

	vec3 colour = mix(bare, gilt, gilded);
	if (edge) {
		// Raised letters: the cut edge that faces up catches the light like
		// a bright rim, and the one that faces down is in its own shadow.
		// That's what makes them read as embossed.
		float up = clamp(world_normal.y, 0.0, 1.0);
		vec3 rim = mix(wood * 0.3, gold * shine * 1.1, lit * gilded);
		colour = mix(bare * 0.3, rim, up);
		colour += gold * facing * near * lamp_glow * 0.3;
	}
	ALBEDO = colour;
}
