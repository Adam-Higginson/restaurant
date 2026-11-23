// Far-off hills (see IslandBackdrop): jungle-green ridges that pale towards
// the colour of the sky the further back they stand, with mist lying in
// the valleys between them. This is how distance is painted: far things
// lose their colour and contrast to the air in between.
//
// COLOR.r is how hazy the ridge is (0 clear, 1 lost in the sky); UV.y runs
// from a ridge's foot (0) to its skyline (1).
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 jungle_color : source_color = vec4(0.1, 0.2, 0.09, 1.0);
uniform vec4 sunlit_color : source_color = vec4(0.42, 0.5, 0.2, 1.0);
uniform vec4 haze_color : source_color = vec4(0.86, 0.87, 0.84, 1.0);
// A soft tiled noise for the lumps of the treetops.
uniform sampler2D treetops : filter_linear_mipmap, repeat_enable;

void fragment() {
	float lumps = texture(treetops, UV * vec2(1.0, 2.0)).r;
	float fine = texture(treetops, UV * vec2(5.0, 9.0)).r;
	// Dark jungle, its canopy catching the sun in patches and along the top.
	vec3 hill = mix(jungle_color.rgb, sunlit_color.rgb,
			smoothstep(0.4, 0.75, lumps * 0.6 + fine * 0.4) * (0.35 + 0.65 * UV.y));
	// Mist lies thicker towards a ridge's foot.
	float hazy = clamp(COLOR.r + (1.0 - UV.y) * 0.35, 0.0, 1.0);
	ALBEDO = mix(hill, haze_color.rgb, hazy);
}
