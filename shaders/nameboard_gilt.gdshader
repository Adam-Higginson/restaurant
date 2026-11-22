// The gilt of the ship's name, carved on her stern. Worn gold doesn't show
// in the dark: it only catches light. So each letter glows by how near the
// lantern on the hook is to it, and the whole name flashes when lightning
// strikes. With no lamp near and no storm, it's a dark shape on dark wood.
// NameGilt (scripts/intro/name_gilt.gd) sets lamp, lamp_glow and flash.
shader_type spatial;
render_mode unshaded;

// The gold where the light catches it, and the tarnish where it doesn't.
uniform vec3 gold : source_color = vec3(1.0, 0.74, 0.32);
uniform vec3 tarnish : source_color = vec3(0.07, 0.05, 0.035);
// Where the lamp is, in the world.
uniform vec3 lamp = vec3(0.0, -1000.0, 0.0);
// How bright the lamp is: 0 with no lamp, 1 at full strength.
uniform float lamp_glow = 0.0;
// How far the lamp's light reaches along the letters, in metres.
uniform float reach = 1.15;
// How bright a lightning flash is right now, 0 to 1.
uniform float flash = 0.0;
// How brightly the gold shines at its brightest: above 1 it blooms a little.
uniform float shine = 1.5;

varying vec3 world_spot;

void vertex() {
	world_spot = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float near = 1.0 - smoothstep(reach * 0.2, reach, distance(world_spot, lamp));
	float lit = clamp(near * lamp_glow + flash * 0.9, 0.0, 1.0);
	ALBEDO = mix(tarnish, gold * shine, lit);
}
