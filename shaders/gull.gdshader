// A gull in the air (see GullFlock): white, with grey wingtips, gliding
// with its wings held a little up, and flapping a few beats every so often.
// UV.x is how far out along a wing a point is (0 at the body, 1 at a tip).
shader_type spatial;
render_mode cull_disabled, shadows_disabled;

uniform vec4 body_color : source_color = vec4(0.95, 0.95, 0.93, 1.0);
uniform vec4 tip_color : source_color = vec4(0.3, 0.32, 0.36, 1.0);
// How far a wingtip swings up and down in a flap, as a part of the wingspan.
uniform float flap = 0.16;
// Beats a second while it's flapping, and how many seconds from one burst
// of flapping to the next.
uniform float flap_speed = 3.2;
uniform float glide_seconds = 6.0;

varying float v_out;

void vertex() {
	// Each gull flaps to its own time.
	float own = float(INSTANCE_ID) * 2.3;
	// Flapping for part of each stretch, gliding for the rest.
	float burst = smoothstep(0.55, 0.7, sin((TIME + own) * TAU / glide_seconds));
	float beat = sin(TIME * TAU * flap_speed + own);
	// Wings held up in a shallow V; the flap swings the outer wing most.
	VERTEX.y += UV.x * 0.05 + beat * burst * flap * UV.x * UV.x;
	v_out = UV.x;
}

void fragment() {
	ALBEDO = mix(body_color.rgb, tip_color.rgb, smoothstep(0.7, 0.95, v_out));
	ROUGHNESS = 0.9;
	// Lit from above and below alike: a bird against the sky is bright.
	BACKLIGHT = vec3(0.6);
}
