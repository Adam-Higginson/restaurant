// The body of the thing that passes beneath the dead lanterns. It's never
// lit: it's drawn in one flat colour, the colour of the deep, so all you
// ever see of it is its outline against whatever light is behind it.
//
// The outline is what makes it a body. The mesh is a plain tube; here each
// ring of it is squeezed or swollen to give a blunt head, a thick middle
// and a long thinning tail, flattened top to bottom, and the whole length
// bends slowly from side to side, the tail most.
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;

// The one colour it's drawn in.
uniform vec4 colour : source_color = vec4(0.0015, 0.006, 0.011, 1.0);
// How long the tube is, in metres, so we know how far along each ring is.
uniform float length_metres = 70.0;
// How thick it is top to bottom against side to side.
uniform float flatness = 0.5;
// How far the tail swings from side to side, in metres, how many bends
// there are along it, and how fast they travel.
uniform float sway = 5.0;
uniform float bends = 1.3;
uniform float sway_speed = 0.45;

void vertex() {
	// How far along this ring is: 0 at the tail's tip, 1 at the nose.
	float along = clamp(VERTEX.y / length_metres + 0.5, 0.0, 1.0);
	// Thin at the tail, thickest past the middle, blunt at the head.
	float girth = pow(sin(PI * pow(along, 0.75)), 0.55);
	VERTEX.x *= girth * flatness;
	VERTEX.z *= girth;
	// The bend travels from head to tail, and the tail swings widest.
	float swing = sin(along * bends * TAU - TIME * sway_speed) * sway * pow(1.0 - along, 1.2);
	VERTEX.z += swing;
}

void fragment() {
	ALBEDO = colour.rgb;
}
