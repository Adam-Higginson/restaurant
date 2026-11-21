// Falling raindrops. A particles shader: it runs on the GPU once per drop,
// placing each one (start) and moving it every frame (process).
//
// Drops start somewhere in a box around the emitter, fall fast with a little
// wind, and stretch along the way they move. When a drop hits something a
// particle collider covers (the ship's RainCatcher heightfield), it starts
// one splash in the sub-emitter, flat on the surface, and vanishes.
shader_type particles;

// Half the size of the box drops start in, in metres.
uniform vec3 box_extents = vec3(14.0, 0.5, 14.0);
uniform float speed_min = 15.0;
uniform float speed_max = 19.0;
// Wind pushing the drops sideways, in metres per second squared.
uniform vec3 wind = vec3(1.5, 0.0, 0.8);

float rand_from_seed(inout uint seed) {
	// A small, fast hash: good enough to scatter raindrops.
	seed = seed * 747796405u + 2891336453u;
	uint word = ((seed >> ((seed >> 28u) + 4u)) ^ seed) * 277803737u;
	return float((word >> 22u) ^ word) / 4294967295.0;
}

// Turns the drop to point along [param dir], keeping its size.
mat3 aligned_to(vec3 dir) {
	vec3 y = normalize(dir);
	vec3 side = abs(y.x) < 0.9 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0);
	vec3 z = normalize(cross(side, y));
	vec3 x = cross(y, z);
	return mat3(x, y, z);
}

void start() {
	uint seed = NUMBER * 1931u + RANDOM_SEED * 7919u + uint(INDEX) * 131u;
	if (RESTART_POSITION) {
		vec3 spot = (vec3(rand_from_seed(seed), rand_from_seed(seed), rand_from_seed(seed))
				* 2.0 - 1.0) * box_extents;
		TRANSFORM = mat4(1.0);
		TRANSFORM[3].xyz = (EMISSION_TRANSFORM * vec4(spot, 1.0)).xyz;
	}
	if (RESTART_VELOCITY) {
		VELOCITY = vec3(0.0, -mix(speed_min, speed_max, rand_from_seed(seed)), 0.0);
	}
	mat3 turned = aligned_to(VELOCITY);
	TRANSFORM[0].xyz = turned[0];
	TRANSFORM[1].xyz = turned[1];
	TRANSFORM[2].xyz = turned[2];
}

void process() {
	if (COLLIDED) {
		// A splash lying flat on whatever was hit, where it was hit.
		mat4 splash = mat4(1.0);
		splash[3].xyz = TRANSFORM[3].xyz;
		emit_subparticle(splash, vec3(0.0), vec4(1.0), vec4(0.0),
				FLAG_EMIT_POSITION | FLAG_EMIT_ROT_SCALE);
		ACTIVE = false;
	} else {
		VELOCITY += wind * DELTA;
		mat3 turned = aligned_to(VELOCITY);
		TRANSFORM[0].xyz = turned[0];
		TRANSFORM[1].xyz = turned[1];
		TRANSFORM[2].xyz = turned[2];
	}
}
