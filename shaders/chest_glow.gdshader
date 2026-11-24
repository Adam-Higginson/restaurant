// The inside of an opened treasure chest, full of light (#152): a floor of
// warm gold that glows brighter than white (so it blooms) with slow ripples
// of brighter light moving over it, like light on water, and dimmer at the
// corners so it looks deep. TreasureChest (scripts/props/treasure_chest.gd)
// sets brightness with the lid.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec4 colour : source_color = vec4(0.62, 1.0, 0.68, 1.0);
// The dark of a shut, empty chest's floor.
uniform vec4 dark : source_color = vec4(0.06, 0.04, 0.03, 1.0);
// How bright the light is at full strength: above 1 it blooms.
uniform float energy = 1.0;
// How bright it is right now, 0 (dark) to 1.
uniform float brightness = 0.0;

void fragment() {
	vec2 centred = UV - 0.5;
	// Brightest in the middle, falling off towards the corners.
	float middle = 1.0 - smoothstep(0.1, 0.75, length(centred * vec2(1.0, 1.3)));
	// Two slow ripples crossing, for a shimmer.
	float ripple = 0.5 + 0.25 * sin(UV.x * 17.0 + TIME * 1.3)
			+ 0.25 * sin(UV.y * 13.0 - TIME * 1.1 + UV.x * 5.0);
	float light = brightness * energy * (0.55 + 0.45 * middle) * (0.8 + 0.4 * ripple);
	ALBEDO = mix(dark.rgb, colour.rgb * light, clamp(brightness * 4.0, 0.0, 1.0));
}
