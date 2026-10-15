shader_type particles;
//render_mode disable_velocity;

#define randsigned(seed) ((rand_from_seed(seed) - 0.5) * 2.0)

// set by script dont touch
uniform vec2 camera_diff;
uniform float node_delta;

uniform vec2 emission_shape_offset;
uniform vec2 emission_box_extents;
uniform float min_depth;
uniform float max_depth;
uniform float depth_sign: hint_range(-1.0, 1.0, 2.0) = 1.0;
uniform float scale: hint_range(0.0, 2.0, 0.001) = 1.0;
uniform float depth_scale_affect: hint_range(0.0, 0.05, 0.0001) = 0.02;
uniform float depth_sat_affect: hint_range(0.0, 0.025, 0.0001) = 0.003;
uniform float depth_val_affect: hint_range(0.0, 0.025, 0.0001) = 0.0025;
uniform float hue_center: hint_range(0.0, 1.0, 0.001) = 1.0;
uniform float hue_variance: hint_range(0.0, 1.0, 0.001) = 0.0;
uniform float sat_center: hint_range(0.0, 1.0, 0.001) = 1.0;
uniform float sat_variance: hint_range(0.0, 1.0, 0.001) = 0.0;
uniform float val_center: hint_range(0.0, 1.0, 0.001) = 1.0;
uniform float val_variance: hint_range(0.0, 1.0, 0.001) = 0.0;
uniform uint seed_offset;

// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
// from https://stackoverflow.com/a/17479300
uint hash( uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}

// from https://stackoverflow.com/a/17479300
float floatConstruct( uint m ) {
    const uint ieeeMantissa = 0x007FFFFFu; // binary32 mantissa bitmask
    const uint ieeeOne      = 0x3F800000u; // 1.0 in IEEE binary32

    m &= ieeeMantissa;                     // Keep only mantissa bits (fractional part)
    m |= ieeeOne;                          // Add fractional part to 1.0

    float  f = uintBitsToFloat( m );       // Range [1:2]
    return f - 1.0;                        // Range [0:1]
}

float rand(uint seed) {
	return floatConstruct(seed);
}

float rand(vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

float rand_from_seed(inout uint seed) {
	// from ParticleProcessMaterial -> Convert to ShaderMaterial
	int k;
	int s = int(seed);
	if (s == 0) {
		s = 305420679;
	}
	k = s / 127773;
	s = 16807 * (s - k * 127773) - 2836 * k;
	if (s < 0) {
		s += 2147483647;
	}
	seed = uint(s);
	return float(seed % uint(65536)) / 65535.0;
}

//vec4 rotate_hue(vec4 current_color, float hue_rot_angle) {
	//float hue_rot_c = cos(hue_rot_angle);
	//float hue_rot_s = sin(hue_rot_angle);
	//mat4 hue_rot_mat =
			//mat4(vec4(0.299, 0.587, 0.114, 0.0),
					//vec4(0.299, 0.587, 0.114, 0.0),
					//vec4(0.299, 0.587, 0.114, 0.0),
					//vec4(0.000, 0.000, 0.000, 1.0)) +
			//mat4(vec4(0.701, -0.587, -0.114, 0.0),
					//vec4(-0.299, 0.413, -0.114, 0.0),
					//vec4(-0.300, -0.588, 0.886, 0.0),
					//vec4(0.000, 0.000, 0.000, 0.0)) *
					//hue_rot_c +
			//mat4(vec4(0.168, 0.330, -0.497, 0.0),
					//vec4(-0.328, 0.035, 0.292, 0.0),
					//vec4(1.250, -1.050, -0.203, 0.0),
					//vec4(0.000, 0.000, 0.000, 0.0)) *
					//hue_rot_s;
	//return hue_rot_mat * current_color;
//}

// Source - https://stackoverflow.com/a/17897228
// Posted by sam hocevar, modified by community. See post 'Timeline' for change history
// Retrieved 2026-04-22, License - CC BY-SA 4.0
// All components are in the range [0…1], including hue.
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


vec2 calculate_initial_position(uint alt_seed) {
	//// from ParticleProcessMater -> Convert to ShaderMaterial
	float pi = 3.141592653;
	vec2 pos = vec2(0.0);
	{ // Emission shape.
		pos = vec2(rand_from_seed(alt_seed) * 2.0 - 1.0, rand_from_seed(alt_seed) * 2.0 - 1.0) * emission_box_extents;
	}
	return pos + emission_shape_offset;
}

void start() {
	// Called when a particle is spawned.
	uint seed = hash(NUMBER + 1u + INDEX + seed_offset);
	float depthrange = max_depth - min_depth;
	float depth = rand_from_seed(seed) * depthrange;
	CUSTOM.x = 0.0; // fraction of lifetime
	CUSTOM.y = depth;
	depth -= min_depth;
	TRANSFORM[0].xy = vec2(scale, 0.0) * (1.0 + (depth)*depth_scale_affect*depth_sign);
	TRANSFORM[1].xy = vec2(0.0, scale) * (1.0 + (depth)*depth_scale_affect*depth_sign);
	TRANSFORM[3].xy = calculate_initial_position(seed);
	/* # colour logic that's not needed for this
	COLOR.rgb = vec3(1.0, 0.0, 0.0);
	vec3 hsvcol = rgb2hsv(COLOR.rgb);
	uint tmpseed = seed + 42u; // to avoid other error 🤪
	hsvcol.x = hsvcol.x + hue_center + randsigned(tmpseed) * hue_variance;
	tmpseed = seed + 44u; // to avoid other error 🤪
	hsvcol.y = sat_center + randsigned(tmpseed) * sat_variance;
	hsvcol.y += depth_sat_affect * depth * depth_sign;
	tmpseed = seed + 48u; // to avoid other error 🤪
	hsvcol.z = val_center + randsigned(tmpseed) * val_variance;
	hsvcol.z += depth_val_affect * depth * depth_sign;
	hsvcol.x = fract(hsvcol.x);
	hsvcol.y = clamp(hsvcol.y, 0.0, 1.0);
	hsvcol.z = clamp(hsvcol.z, 0.0, 1.0);
	COLOR.rgb = hsv2rgb(hsvcol);
	*/
	//COLOR.rgb = CUSTOM.xyz;
	COLOR.rgb = vec3(1.0);
}

void process() {
	CUSTOM.x += DELTA / LIFETIME;
	//TRANSFORM[3].xy += camera_diff * (CUSTOM.y - min_depth);
	VELOCITY.xy = camera_diff * (CUSTOM.y - min_depth) * depth_sign;
	float alive = CUSTOM.x;
	COLOR.a = (pow(alive, 2) - pow(alive, 3)) * 3.0;
}
