// The light that pours up out of an opened treasure chest, as in Ocarina of
// Time (#152). Drawn on a tall open tube that widens as it rises, added on
// top of the picture: brightest where it leaves the chest, fading to nothing
// well before its top, with soft sides so it reads as light, never a solid
// cone. Through it, a few brighter spokes turn slowly round and faint
// streaks drift upwards, so it shimmers rather than sitting still. Bright
// enough to bloom (the scene's glow catches anything over white).
// TreasureChest (scripts/props/treasure_chest.gd) sets brightness as the lid
// opens and fades it when the treasure's been taken.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;

uniform vec4 colour : source_color = vec4(1.0, 0.68, 0.28, 1.0);
// How bright the beam is where it leaves the chest, at full strength.
uniform float energy = 2.0;
// How bright it is right now, 0 (none) to 1.
uniform float brightness = 0.0;
// How quickly it fades on the way up: higher fades sooner.
uniform float fade = 1.6;
// How many spokes of brighter light, and how fast they turn.
uniform float spokes = 5.0;
uniform float spin = 0.12;

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
	float facing = pow(abs(dot(NORMAL, VIEW)), 2.0);
	// UV.y runs from the top of the tube (0) down to the chest (1). Bright at
	// the chest, fading as it rises, and nothing at either rim.
	float up = 1.0 - UV.y;
	float rise = pow(max(1.0 - up, 0.0), fade) * smoothstep(0.0, 0.08, UV.y)
			* smoothstep(1.0, 0.94, UV.y);
	// Spokes: brighter bands round the tube, turning slowly and wavering.
	float around = UV.x * spokes + TIME * spin + 0.4 * sin(up * 3.0 + TIME * 0.7);
	float spoke = 0.55 + 0.45 * pow(0.5 + 0.5 * sin(around * 6.2832), 3.0);
	// Streaks drifting upwards through it.
	float streaks = 0.6 + 0.4 * noise(vec2(UV.x * 18.0, up * 2.5 - TIME * 0.35));
	// A gentle breath, so it's alive.
	float breath = 0.92 + 0.08 * sin(TIME * 1.7);
	// Thins to nothing right in front of the camera, so it never whites out.
	float close_up = smoothstep(0.3, 1.2, -VERTEX.z);
	ALBEDO = colour.rgb * energy * brightness * facing * rise * spoke * streaks * breath
			* close_up;
}
